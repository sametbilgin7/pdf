//
//  BookScanningService.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import Foundation
import UIKit
import Vision
import Combine
import PDFKit
import CoreGraphics

struct BookPage {
    let id: UUID
    let image: UIImage
    let pageNumber: Int
    let scanDate: Date
    let isProcessed: Bool
    let cornerPoints: [CGPoint]?
    let textContent: String?
    
    init(image: UIImage, pageNumber: Int, cornerPoints: [CGPoint]? = nil) {
        self.id = UUID()
        self.image = image
        self.pageNumber = pageNumber
        self.scanDate = Date()
        self.isProcessed = false
        self.cornerPoints = cornerPoints
        self.textContent = nil
    }
}

// MARK: - Codable Support
extension BookPage: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, imageData, pageNumber, scanDate, isProcessed, cornerPoints, textContent
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        let data = try container.decode(Data.self, forKey: .imageData)
        guard let uiImage = UIImage(data: data) else { throw BookScanningError.imageProcessingFailed }
        self.image = uiImage
        self.pageNumber = try container.decode(Int.self, forKey: .pageNumber)
        self.scanDate = try container.decode(Date.self, forKey: .scanDate)
        self.isProcessed = try container.decode(Bool.self, forKey: .isProcessed)
        self.cornerPoints = try container.decodeIfPresent([CGPoint].self, forKey: .cornerPoints)
        self.textContent = try container.decodeIfPresent(String.self, forKey: .textContent)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        let data = image.pngData() ?? Data()
        try container.encode(data, forKey: .imageData)
        try container.encode(pageNumber, forKey: .pageNumber)
        try container.encode(scanDate, forKey: .scanDate)
        try container.encode(isProcessed, forKey: .isProcessed)
        try container.encodeIfPresent(cornerPoints, forKey: .cornerPoints)
        try container.encodeIfPresent(textContent, forKey: .textContent)
    }
}

struct BookProject {
    let id: UUID
    let title: String
    let author: String?
    let pages: [BookPage]
    let createdAt: Date
    let lastModified: Date
    let coverImage: UIImage?
    
    var pageCount: Int {
        return pages.count
    }
    
    var isComplete: Bool {
        return !pages.isEmpty && pages.allSatisfy { $0.isProcessed }
    }
}

extension BookProject: Codable {
    private enum CodingKeys: String, CodingKey { case id, title, author, pages, createdAt, lastModified, coverImageData }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.author = try container.decodeIfPresent(String.self, forKey: .author)
        self.pages = try container.decode([BookPage].self, forKey: .pages)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.lastModified = try container.decode(Date.self, forKey: .lastModified)
        if let data = try container.decodeIfPresent(Data.self, forKey: .coverImageData) {
            self.coverImage = UIImage(data: data)
        } else {
            self.coverImage = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encode(pages, forKey: .pages)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastModified, forKey: .lastModified)
        if let coverImage = coverImage, let data = coverImage.pngData() {
            try container.encode(data, forKey: .coverImageData)
        }
    }
}

enum BookScanningError: Error, LocalizedError {
    case imageProcessingFailed
    case pageDetectionFailed
    case textExtractionFailed(String)
    case pdfGenerationFailed(String)
    case invalidPageOrder
    case missingPages
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Sayfa işleme başarısız."
        case .pageDetectionFailed:
            return "Sayfa algılanamadı."
        case .textExtractionFailed(let reason):
            return "Metin çıkarma başarısız: \(reason)"
        case .pdfGenerationFailed(let reason):
            return "PDF oluşturma başarısız: \(reason)"
        case .invalidPageOrder:
            return "Geçersiz sayfa sırası."
        case .missingPages:
            return "Eksik sayfalar var."
        }
    }
}

class BookScanningService: ObservableObject {
    @Published var isProcessing = false
    @Published var currentProject: BookProject?
    @Published var errorMessage: String?
    @Published var processingProgress: Double = 0.0
    
    private let visionQueue = DispatchQueue(label: "com.modernpdfscanner.book", qos: .userInitiated)
    private var projects: [BookProject] = []
    
    func createNewProject(title: String, author: String? = nil) -> BookProject {
        let project = BookProject(
            id: UUID(),
            title: title,
            author: author,
            pages: [],
            createdAt: Date(),
            lastModified: Date(),
            coverImage: nil
        )
        
        currentProject = project
        return project
    }
    
    func addPageToProject(_ image: UIImage, pageNumber: Int) async throws -> BookPage {
        guard var project = currentProject else {
            throw BookScanningError.missingPages
        }
        
        await MainActor.run {
            self.isProcessing = true
            self.processingProgress = 0.0
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            visionQueue.async {
                do {
                    let processedPage = try self.processBookPage(image, pageNumber: pageNumber)
                    
                    let updatedPages = project.pages + [processedPage]
                    let updatedProject = BookProject(
                        id: project.id,
                        title: project.title,
                        author: project.author,
                        pages: updatedPages,
                        createdAt: project.createdAt,
                        lastModified: Date(),
                        coverImage: project.coverImage
                    )
                    
                    Task { @MainActor in
                        self.currentProject = updatedProject
                        self.isProcessing = false
                        self.processingProgress = 1.0
                        continuation.resume(returning: processedPage)
                    }
                } catch {
                    Task { @MainActor in
                        self.isProcessing = false
                        self.errorMessage = error.localizedDescription
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    private func processBookPage(_ image: UIImage, pageNumber: Int) throws -> BookPage {
        // Detect page corners for perspective correction
        let cornerPoints = try detectPageCorners(in: image)
        
        // Create book page
        let bookPage = BookPage(
            image: image,
            pageNumber: pageNumber,
            cornerPoints: cornerPoints
        )
        
        return bookPage
    }
    
    private func detectPageCorners(in image: UIImage) throws -> [CGPoint] {
        guard let cgImage = image.cgImage else {
            throw BookScanningError.imageProcessingFailed
        }
        
        let request = VNDetectRectanglesRequest { request, error in
            if let error = error {
                print("Rectangle Detection Error: \(error.localizedDescription)")
            }
        }
        
        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 1.0
        request.minimumSize = 0.1
        request.minimumConfidence = 0.5
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            throw BookScanningError.pageDetectionFailed
        }
        
        guard let observations = request.results, !observations.isEmpty else {
            // Return default corners if no rectangle detected
            return [
                CGPoint(x: 0, y: 0),
                CGPoint(x: image.size.width, y: 0),
                CGPoint(x: image.size.width, y: image.size.height),
                CGPoint(x: 0, y: image.size.height)
            ]
        }
        
        // Get the best rectangle detection
        let bestObservation = observations.max { $0.confidence < $1.confidence }
        
        guard let observation = bestObservation else {
            throw BookScanningError.pageDetectionFailed
        }
        
        // Convert normalized coordinates to image coordinates
        let imageSize = CGSize(width: image.size.width, height: image.size.height)
        let corners = (observation.topLeft, observation.topRight, observation.bottomRight, observation.bottomLeft)
        let imageCorners = [
            VNImagePointForNormalizedPoint(corners.0, Int(imageSize.width), Int(imageSize.height)),
            VNImagePointForNormalizedPoint(corners.1, Int(imageSize.width), Int(imageSize.height)),
            VNImagePointForNormalizedPoint(corners.2, Int(imageSize.width), Int(imageSize.height)),
            VNImagePointForNormalizedPoint(corners.3, Int(imageSize.width), Int(imageSize.height))
        ]
        
        return imageCorners
    }
    
    func generatePDF(from project: BookProject) async throws -> URL {
        await MainActor.run {
            self.isProcessing = true
            self.processingProgress = 0.0
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            visionQueue.async {
                do {
                    let pdfURL = try self.generatePDFDocument(bookProject: project)
                    
                    Task { @MainActor in
                        self.isProcessing = false
                        self.processingProgress = 1.0
                        continuation.resume(returning: pdfURL)
                    }
                } catch {
                    Task { @MainActor in
                        self.isProcessing = false
                        self.errorMessage = error.localizedDescription
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    private func generatePDFDocument(bookProject: BookProject) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(bookProject.title.replacingOccurrences(of: " ", with: "_"))_\(Date().timeIntervalSince1970).pdf"
        let pdfURL = documentsPath.appendingPathComponent(fileName)
        
        let pdfDoc = PDFKit.PDFDocument()
        
        // Add cover page if available
        if let coverImage = bookProject.coverImage {
            if let coverPage = PDFPage(image: coverImage) {
                pdfDoc.insert(coverPage, at: 0)
            }
        }
        
        // Add book pages in order
        let sortedPages = bookProject.pages.sorted { $0.pageNumber < $1.pageNumber }
        
        for (index, bookPage) in sortedPages.enumerated() {
            if let pdfPage = PDFPage(image: bookPage.image) {
                pdfDoc.insert(pdfPage, at: index + (bookProject.coverImage != nil ? 1 : 0))
            }
        }
        
        // Add metadata
        pdfDoc.documentAttributes = [
            PDFDocumentAttribute.titleAttribute: bookProject.title,
            PDFDocumentAttribute.authorAttribute: bookProject.author ?? "Unknown",
            PDFDocumentAttribute.creatorAttribute: "ModernPDFScanner",
            PDFDocumentAttribute.creationDateAttribute: bookProject.createdAt,
            PDFDocumentAttribute.modificationDateAttribute: bookProject.lastModified
        ]
        
        // Save PDF
        guard pdfDoc.write(to: pdfURL) else {
            throw BookScanningError.pdfGenerationFailed("PDF dosyası kaydedilemedi")
        }
        
        return pdfURL
    }
    
    func reorderPages(_ pages: [BookPage]) -> [BookPage] {
        return pages.sorted { $0.pageNumber < $1.pageNumber }
    }
    
    func deletePage(_ page: BookPage, from project: BookProject) -> BookProject {
        let updatedPages = project.pages.filter { $0.id != page.id }
        
        return BookProject(
            id: project.id,
            title: project.title,
            author: project.author,
            pages: updatedPages,
            createdAt: project.createdAt,
            lastModified: Date(),
            coverImage: project.coverImage
        )
    }
    
    func updatePageOrder(_ pages: [BookPage], in project: BookProject) -> BookProject {
        let reorderedPages = pages.enumerated().map { index, page in
            BookPage(
                image: page.image,
                pageNumber: index + 1,
                cornerPoints: page.cornerPoints
            )
        }
        
        return BookProject(
            id: project.id,
            title: project.title,
            author: project.author,
            pages: reorderedPages,
            createdAt: project.createdAt,
            lastModified: Date(),
            coverImage: project.coverImage
        )
    }
    
    func saveProject(_ project: BookProject) {
        // Save to user defaults or core data
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(project) {
            UserDefaults.standard.set(data, forKey: "savedBookProjects")
        }
    }
    
    func loadProjects() -> [BookProject] {
        guard let data = UserDefaults.standard.data(forKey: "savedBookProjects"),
              let projects = try? JSONDecoder().decode([BookProject].self, from: data) else {
            return []
        }
        return projects
    }
    
    func clearCurrentProject() {
        currentProject = nil
        errorMessage = nil
        processingProgress = 0.0
    }
}
