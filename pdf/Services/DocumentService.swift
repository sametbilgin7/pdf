//
//  DocumentService.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import Foundation
import UIKit
import PDFKit

class DocumentService {
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    
    init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    // MARK: - Scanned Documents
    
    func saveScannedDocument(_ document: ScannedDocument, images: [UIImage]) async throws {
        let documentFolder = documentsDirectory.appendingPathComponent("ScannedDocuments/\(document.id.uuidString)")
        try fileManager.createDirectory(at: documentFolder, withIntermediateDirectories: true)
        
        // Save document metadata
        let metadataURL = documentFolder.appendingPathComponent("metadata.json")
        let metadataData = try JSONEncoder().encode(document)
        try metadataData.write(to: metadataURL)
        
        // Save images
        for (index, image) in images.enumerated() {
            let imageURL = documentFolder.appendingPathComponent("page_\(index).jpg")
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                try imageData.write(to: imageURL)
            }
        }
    }
    
    func loadScannedDocuments() async throws -> [ScannedDocument] {
        let scannedDocumentsFolder = documentsDirectory.appendingPathComponent("ScannedDocuments")
        
        guard fileManager.fileExists(atPath: scannedDocumentsFolder.path) else {
            return []
        }
        
        let folderContents = try fileManager.contentsOfDirectory(at: scannedDocumentsFolder, includingPropertiesForKeys: nil)
        var documents: [ScannedDocument] = []
        
        for folder in folderContents {
            let metadataURL = folder.appendingPathComponent("metadata.json")
            if fileManager.fileExists(atPath: metadataURL.path) {
                let metadataData = try Data(contentsOf: metadataURL)
                let document = try JSONDecoder().decode(ScannedDocument.self, from: metadataData)
                documents.append(document)
            }
        }
        
        return documents.sorted { $0.createdAt > $1.createdAt }
    }
    
    func deleteScannedDocument(_ document: ScannedDocument) async throws {
        let documentFolder = documentsDirectory.appendingPathComponent("ScannedDocuments/\(document.id.uuidString)")
        try fileManager.removeItem(at: documentFolder)
    }
    
    // MARK: - PDF Documents
    
    func createPDF(from images: [UIImage], name: String) async throws -> URL {
        let pdfDocument = PDFKit.PDFDocument()
        
        for image in images {
            let pdfPage = PDFPage(image: image)
            pdfDocument.insert(pdfPage!, at: pdfDocument.pageCount)
        }
        
        let pdfURL = documentsDirectory.appendingPathComponent("PDFs/\(name).pdf")
        try fileManager.createDirectory(at: pdfURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        pdfDocument.write(to: pdfURL)
        return pdfURL
    }
    
    func savePDFDocument(_ document: PDFDocument) async throws {
        let pdfsFolder = documentsDirectory.appendingPathComponent("PDFs")
        try fileManager.createDirectory(at: pdfsFolder, withIntermediateDirectories: true)
        
        let metadataURL = pdfsFolder.appendingPathComponent("\(document.id.uuidString).json")
        let metadataData = try JSONEncoder().encode(document)
        try metadataData.write(to: metadataURL)
    }
    
    func loadPDFDocuments() async throws -> [PDFDocument] {
        let pdfsFolder = documentsDirectory.appendingPathComponent("PDFs")
        
        guard fileManager.fileExists(atPath: pdfsFolder.path) else {
            return []
        }
        
        let folderContents = try fileManager.contentsOfDirectory(at: pdfsFolder, includingPropertiesForKeys: nil)
        var documents: [PDFDocument] = []
        
        for file in folderContents where file.pathExtension == "json" {
            let metadataData = try Data(contentsOf: file)
            let document = try JSONDecoder().decode(PDFDocument.self, from: metadataData)
            documents.append(document)
        }
        
        return documents.sorted { $0.createdAt > $1.createdAt }
    }
    
    func deletePDFDocument(_ document: PDFDocument) async throws {
        // Delete PDF file
        try fileManager.removeItem(at: document.url)
        
        // Delete metadata
        let pdfsFolder = documentsDirectory.appendingPathComponent("PDFs")
        let metadataURL = pdfsFolder.appendingPathComponent("\(document.id.uuidString).json")
        try fileManager.removeItem(at: metadataURL)
    }
}
