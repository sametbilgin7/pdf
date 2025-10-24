//
//  PDFLibraryService.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import Foundation
import UIKit
import PDFKit
import Combine

// MARK: - Scanned Collection Model
class ScannedCollection: NSObject, Identifiable, Codable, NSCoding {
    let id: UUID
    let name: String
    let size: String
    let thumbnail: String
    let dateCreated: Date
    var images: [UIImage]
    
    init(id: UUID = UUID(), name: String, size: String, thumbnail: String, dateCreated: Date, images: [UIImage]) {
        self.id = id
        self.name = name
        self.size = size
        self.thumbnail = thumbnail
        self.dateCreated = dateCreated
        self.images = images
        super.init()
    }
    
    // Custom coding keys for UIImage handling
    enum CodingKeys: String, CodingKey {
        case id, name, size, thumbnail, dateCreated, imageData
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        size = try container.decode(String.self, forKey: .size)
        thumbnail = try container.decode(String.self, forKey: .thumbnail)
        dateCreated = try container.decode(Date.self, forKey: .dateCreated)
        
        if let imageDataArray = try container.decodeIfPresent([Data].self, forKey: .imageData) {
            images = imageDataArray.compactMap { UIImage(data: $0) }
        } else {
            images = []
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(size, forKey: .size)
        try container.encode(thumbnail, forKey: .thumbnail)
        try container.encode(dateCreated, forKey: .dateCreated)
        
        let imageDataArray = images.compactMap { $0.jpegData(compressionQuality: 0.8) }
        try container.encode(imageDataArray, forKey: .imageData)
    }
    
    // MARK: - NSCoding
    func encode(with coder: NSCoder) {
        coder.encode(id.uuidString, forKey: "id")
        coder.encode(name, forKey: "name")
        coder.encode(size, forKey: "size")
        coder.encode(thumbnail, forKey: "thumbnail")
        coder.encode(dateCreated, forKey: "dateCreated")
        
        let imageDataArray = images.compactMap { $0.jpegData(compressionQuality: 0.8) }
        coder.encode(imageDataArray, forKey: "imageData")
    }
    
    required init?(coder: NSCoder) {
        guard let idString = coder.decodeObject(forKey: "id") as? String,
              let id = UUID(uuidString: idString),
              let name = coder.decodeObject(forKey: "name") as? String,
              let size = coder.decodeObject(forKey: "size") as? String,
              let thumbnail = coder.decodeObject(forKey: "thumbnail") as? String,
              let dateCreated = coder.decodeObject(forKey: "dateCreated") as? Date else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.size = size
        self.thumbnail = thumbnail
        self.dateCreated = dateCreated
        
        if let imageDataArray = coder.decodeObject(forKey: "imageData") as? [Data] {
            self.images = imageDataArray.compactMap { UIImage(data: $0) }
        } else {
            self.images = []
        }
        
        super.init()
    }
}

class PDFLibraryService: ObservableObject {
    @Published var pdfFiles: [PDFFile] = []
    @Published var folders: [Folder] = []
    @Published var scannedImages: [UIImage] = []
    @Published var scannedCollections: [ScannedCollection] = []
    
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let foldersKey = "SavedFolders"
    private let scannedCollectionsKey = "ScannedCollections"
    
    init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        loadFolders()
        loadPDFFiles()
        loadScannedCollections()
    }
    
    func loadPDFFiles() {
        print("loadPDFFiles called - documentsDirectory: \(documentsDirectory.path)")
        
        // Get all URLs that are in folders
        let urlsInFolders = Set(folders.flatMap { $0.pdfFileURLs })
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: documentsDirectory,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )
            print("Found \(fileURLs.count) files in documents directory")
            
            let pdfFiles = fileURLs
                .filter { $0.pathExtension.lowercased() == "pdf" }
                .filter { url in
                    // Only include files that actually exist
                    let exists = fileManager.fileExists(atPath: url.path)
                    if !exists {
                        print("⚠️ Skipping missing file: \(url.lastPathComponent)")
                    }
                    return exists
                }
                .filter { url in
                    // Exclude PDFs that are already in folders
                    let isInFolder = urlsInFolders.contains(url)
                    if isInFolder {
                        print("⚠️ Skipping file in folder: \(url.lastPathComponent)")
                    }
                    return !isInFolder
                }
                .compactMap { url -> PDFFile? in
                    print("Processing PDF file: \(url.lastPathComponent)")
                    do {
                        let attributes = try fileManager.attributesOfItem(atPath: url.path)
                        let creationDate = attributes[.creationDate] as? Date ?? Date()
                        let fileSize = attributes[FileAttributeKey.size] as? Int64 ?? 0
                        
                        // Verify this is a valid PDF by trying to open it
                        guard let _ = PDFKit.PDFDocument(url: url) else {
                            print("⚠️ Invalid PDF file: \(url.lastPathComponent)")
                            return nil
                        }
                        
                        return PDFFile(
                            url: url,
                            name: url.lastPathComponent,
                            createdAt: creationDate,
                            fileSize: fileSize
                        )
                    } catch {
                        print("Error reading file attributes: \(error)")
                        return nil
                    }
                }
                .sorted { $0.createdAt > $1.createdAt } // Most recent first
            
            print("Successfully loaded \(pdfFiles.count) PDF files")
            DispatchQueue.main.async {
                self.pdfFiles = pdfFiles
                print("PDF files updated on main thread: \(self.pdfFiles.count)")
            }
        } catch {
            print("Error loading PDF files: \(error)")
        }
    }
    
    func deletePDF(_ pdfFile: PDFFile) {
        do {
            try fileManager.removeItem(at: pdfFile.url)
            DispatchQueue.main.async {
                self.pdfFiles.removeAll { $0.id == pdfFile.id }
            }
        } catch {
            print("Error deleting PDF file: \(error)")
        }
    }
    
    func renamePDF(_ pdfFile: PDFFile, newName: String) {
        // Ensure the new name has .pdf extension
        let newNameWithExtension = newName.hasSuffix(".pdf") ? newName : "\(newName).pdf"
        
        // Create new URL with the new name
        let newURL = pdfFile.url.deletingLastPathComponent().appendingPathComponent(newNameWithExtension)
        
        // Check if a file with the new name already exists
        if fileManager.fileExists(atPath: newURL.path) {
            print("Error: A file with the name '\(newNameWithExtension)' already exists")
            return
        }
        
        do {
            try fileManager.moveItem(at: pdfFile.url, to: newURL)
            
            // Reload PDF files to reflect the change
            loadPDFFiles()
            
            HapticManager.success()
        } catch {
            print("Error renaming PDF file: \(error)")
            HapticManager.error()
        }
    }
    
    func generateThumbnail(for pdfFile: PDFFile, size: CGSize = CGSize(width: 120, height: 160)) -> UIImage? {
        guard let pdfDocument = PDFKit.PDFDocument(url: pdfFile.url),
              let firstPage = pdfDocument.page(at: 0) else {
            return nil
        }
        
        let thumbnail = firstPage.thumbnail(of: size, for: .mediaBox)
        return thumbnail
    }
    
    func getPageCount(for pdfFile: PDFFile) -> Int {
        guard let pdfDocument = PDFKit.PDFDocument(url: pdfFile.url) else {
            return 0
        }
        return pdfDocument.pageCount
    }
    
    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Import PDF
    
    func importPDF(from sourceURL: URL) {
        do {
            // Generate a unique filename if needed
            var destinationURL = documentsDirectory.appendingPathComponent(sourceURL.lastPathComponent)
            var counter = 1
            
            // Check if file exists and generate unique name
            while fileManager.fileExists(atPath: destinationURL.path) {
                let fileNameWithoutExtension = sourceURL.deletingPathExtension().lastPathComponent
                let fileExtension = sourceURL.pathExtension
                let newFileName = "\(fileNameWithoutExtension)_\(counter).\(fileExtension)"
                destinationURL = documentsDirectory.appendingPathComponent(newFileName)
                counter += 1
            }
            
            // Copy the file
            if sourceURL.startAccessingSecurityScopedResource() {
                defer { sourceURL.stopAccessingSecurityScopedResource() }
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
            } else {
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
            }
            
            // Remove the original file to avoid duplicates
            try fileManager.removeItem(at: sourceURL)
            
            // Reload PDF files
            loadPDFFiles()
        } catch {
            print("Error importing PDF: \(error)")
        }
    }
    
    // MARK: - Folder Management
    
    func loadFolders() {
        if let data = UserDefaults.standard.data(forKey: foldersKey),
           let folders = try? JSONDecoder().decode([Folder].self, from: data) {
            print("📁 Loaded \(folders.count) folders from UserDefaults")
            DispatchQueue.main.async {
                self.folders = folders
                // Save folders immediately after loading to persist any migration
                self.saveFolders()
                print("💾 Folders saved after migration check")
            }
        } else {
            print("📁 No folders found in UserDefaults")
        }
    }
    
    func saveFolders() {
        if let data = try? JSONEncoder().encode(folders) {
            UserDefaults.standard.set(data, forKey: foldersKey)
        }
    }
    
    func createFolder(name: String) {
        let newFolder = Folder(name: name)
        DispatchQueue.main.async {
            self.folders.append(newFolder)
            self.saveFolders()
        }
    }
    
    func deleteFolder(_ folder: Folder) {
        DispatchQueue.main.async {
            self.folders.removeAll { $0.id == folder.id }
            self.saveFolders()
            
            // Reload PDF files to add PDFs from deleted folder back to the main library
            self.loadPDFFiles()
        }
    }
    
    func renameFolder(_ folder: Folder, newName: String) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            DispatchQueue.main.async {
                self.folders[index].name = newName
                self.saveFolders()
            }
        }
    }
    
    func addPDFToFolder(_ pdfFile: PDFFile, folder: Folder) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            DispatchQueue.main.async {
                if !self.folders[index].pdfFileURLs.contains(pdfFile.url) {
                    self.folders[index].pdfFileURLs.append(pdfFile.url)
                    self.saveFolders()
                    
                    // Remove PDF from the main library list
                    self.pdfFiles.removeAll { $0.id == pdfFile.id }
                }
            }
        }
    }
    
    func removePDFFromFolder(_ pdfFile: PDFFile, folder: Folder) {
        if let index = folders.firstIndex(where: { $0.id == folder.id }) {
            DispatchQueue.main.async {
                self.folders[index].pdfFileURLs.removeAll { $0 == pdfFile.url }
                self.saveFolders()
                
                // Reload PDF files to add it back to the main library list
                self.loadPDFFiles()
            }
        }
    }
}

struct PDFFile: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let name: String
    let createdAt: Date
    let fileSize: Int64
    
    var displayName: String {
        return name.replacingOccurrences(of: ".pdf", with: "")
    }
    
    var fileSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

// MARK: - Scanned Images Management
extension PDFLibraryService {
    func addScannedImages(_ images: [UIImage]) {
        scannedImages.append(contentsOf: images)
    }
    
    func clearScannedImages() {
        scannedImages.removeAll()
    }
    
    func removeScannedImage(at index: Int) {
        guard index >= 0 && index < scannedImages.count else { return }
        scannedImages.remove(at: index)
    }
    
    
    func addScannedCollection(_ collection: ScannedCollection) {
        print("📁 Adding scanned collection: \(collection.name)")
        scannedCollections.insert(collection, at: 0)
        print("📁 Total collections: \(scannedCollections.count)")
        saveScannedCollections()
    }
    
    func removeScannedCollection(at index: Int) {
        guard index >= 0 && index < scannedCollections.count else { return }
        scannedCollections.remove(at: index)
        saveScannedCollections()
    }
    
    private func loadScannedCollections() {
        print("📁 Loading scanned collections...")
        let fileURL = documentsDirectory.appendingPathComponent("scanned_collections.data")
        guard let data = try? Data(contentsOf: fileURL) else {
            print("📁 No saved collections file found")
            return
        }
        
        do {
            let collections = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [ScannedCollection] ?? []
            scannedCollections = collections
            print("📁 Loaded \(collections.count) collections from file")
        } catch {
            print("📁 Failed to decode collections: \(error)")
        }
    }
    
    private func saveScannedCollections() {
        print("📁 Saving \(scannedCollections.count) collections...")
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: scannedCollections, requiringSecureCoding: false)
            let fileURL = documentsDirectory.appendingPathComponent("scanned_collections.data")
            try data.write(to: fileURL)
            print("📁 Successfully saved collections to file: \(fileURL.path)")
        } catch {
            print("📁 Failed to save scanned collections: \(error)")
        }
    }
}
