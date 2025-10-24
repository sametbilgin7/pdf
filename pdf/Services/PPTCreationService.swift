//
//  PPTCreationService.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import Foundation
import UIKit
import Vision
import Combine
import PDFKit

struct PPTSlide: Codable {
    let id: UUID
    let image: UIImage
    let slideNumber: Int
    let title: String?
    let content: String?
    let scanDate: Date
    let isProcessed: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, slideNumber, title, content, scanDate, isProcessed, slideType
        case imageData
    }
    
    init(id: UUID, image: UIImage, slideNumber: Int, title: String?, content: String?, scanDate: Date, isProcessed: Bool, slideType: SlideType = .content) {
        self.id = id
        self.image = image
        self.slideNumber = slideNumber
        self.title = title
        self.content = content
        self.scanDate = scanDate
        self.isProcessed = isProcessed
        self.slideType = slideType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        slideNumber = try container.decode(Int.self, forKey: .slideNumber)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        scanDate = try container.decode(Date.self, forKey: .scanDate)
        isProcessed = try container.decode(Bool.self, forKey: .isProcessed)
        let slideTypeRawValue = try container.decodeIfPresent(String.self, forKey: .slideType) ?? "content"
        slideType = SlideType(rawValue: slideTypeRawValue) ?? .content
        
        let imageData = try container.decode(Data.self, forKey: .imageData)
        guard let image = UIImage(data: imageData) else {
            throw DecodingError.dataCorruptedError(forKey: .imageData, in: container, debugDescription: "Invalid image data")
        }
        self.image = image
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(slideNumber, forKey: .slideNumber)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(content, forKey: .content)
        try container.encode(scanDate, forKey: .scanDate)
        try container.encode(isProcessed, forKey: .isProcessed)
        try container.encode(slideType.rawValue, forKey: .slideType)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw EncodingError.invalidValue(image, EncodingError.Context(codingPath: [CodingKeys.imageData], debugDescription: "Cannot encode image"))
        }
        try container.encode(imageData, forKey: .imageData)
    }
    let slideType: SlideType
    
    init(image: UIImage, slideNumber: Int, title: String? = nil, slideType: SlideType = .content) {
        self.id = UUID()
        self.image = image
        self.slideNumber = slideNumber
        self.title = title
        self.content = nil
        self.scanDate = Date()
        self.isProcessed = false
        self.slideType = slideType
    }
}

enum SlideType: String, CaseIterable, Identifiable, Codable {
    case title = "title"
    case content = "content"
    case image = "image"
    case chart = "chart"
    case conclusion = "conclusion"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .title:
            return "Başlık Slaytı"
        case .content:
            return "İçerik Slaytı"
        case .image:
            return "Görsel Slaytı"
        case .chart:
            return "Grafik Slaytı"
        case .conclusion:
            return "Sonuç Slaytı"
        }
    }
    
    var icon: String {
        switch self {
        case .title:
            return "textformat"
        case .content:
            return "doc.text"
        case .image:
            return "photo"
        case .chart:
            return "chart.bar"
        case .conclusion:
            return "checkmark.circle"
        }
    }
}

struct PPTProject: Codable {
    let id: UUID
    let title: String
    let author: String?
    let slides: [PPTSlide]
    let createdAt: Date
    let lastModified: Date
    let theme: PPTTheme
    
    var slideCount: Int {
        return slides.count
    }
    
    var isComplete: Bool {
        return !slides.isEmpty && slides.allSatisfy { $0.isProcessed }
    }
}

enum PPTTheme: String, CaseIterable, Identifiable, Codable {
    case modern = "modern"
    case classic = "classic"
    case colorful = "colorful"
    case minimal = "minimal"
    case professional = "professional"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .modern:
            return "Modern"
        case .classic:
            return "Klasik"
        case .colorful:
            return "Renkli"
        case .minimal:
            return "Minimal"
        case .professional:
            return "Profesyonel"
        }
    }
    
    var primaryColor: UIColor {
        switch self {
        case .modern:
            return .systemBlue
        case .classic:
            return .systemGray
        case .colorful:
            return .systemPurple
        case .minimal:
            return .systemGray2
        case .professional:
            return .systemIndigo
        }
    }
}

enum PPTCreationError: Error, LocalizedError {
    case imageProcessingFailed
    case slideDetectionFailed
    case textExtractionFailed(String)
    case pptGenerationFailed(String)
    case invalidSlideOrder
    case missingSlides
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Slayt işleme başarısız."
        case .slideDetectionFailed:
            return "Slayt algılanamadı."
        case .textExtractionFailed(let reason):
            return "Metin çıkarma başarısız: \(reason)"
        case .pptGenerationFailed(let reason):
            return "PPT oluşturma başarısız: \(reason)"
        case .invalidSlideOrder:
            return "Geçersiz slayt sırası."
        case .missingSlides:
            return "Eksik slaytlar var."
        }
    }
}

class PPTCreationService: ObservableObject {
    @Published var isProcessing = false
    @Published var currentProject: PPTProject?
    @Published var errorMessage: String?
    @Published var processingProgress: Double = 0.0
    
    private let visionQueue = DispatchQueue(label: "com.modernpdfscanner.ppt", qos: .userInitiated)
    private var projects: [PPTProject] = []
    
    func createNewProject(title: String, author: String? = nil, theme: PPTTheme = .modern) -> PPTProject {
        let project = PPTProject(
            id: UUID(),
            title: title,
            author: author,
            slides: [],
            createdAt: Date(),
            lastModified: Date(),
            theme: theme
        )
        
        currentProject = project
        return project
    }
    
    func addSlideToProject(_ image: UIImage, slideNumber: Int, title: String? = nil, slideType: SlideType = .content) async throws -> PPTSlide {
        guard var project = currentProject else {
            throw PPTCreationError.missingSlides
        }
        
        await MainActor.run {
            self.isProcessing = true
            self.processingProgress = 0.0
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            visionQueue.async {
                do {
                    let processedSlide = try self.processPPTSlide(image, slideNumber: slideNumber, title: title, slideType: slideType)
                    
                    let updatedSlides = project.slides + [processedSlide]
                    let updatedProject = PPTProject(
                        id: project.id,
                        title: project.title,
                        author: project.author,
                        slides: updatedSlides,
                        createdAt: project.createdAt,
                        lastModified: Date(),
                        theme: project.theme
                    )
                    
                    Task { @MainActor in
                        self.currentProject = updatedProject
                        self.isProcessing = false
                        self.processingProgress = 1.0
                        continuation.resume(returning: processedSlide)
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
    
    private func processPPTSlide(_ image: UIImage, slideNumber: Int, title: String?, slideType: SlideType) throws -> PPTSlide {
        // Detect slide content and extract text if needed
        let content = try extractSlideContent(from: image)
        
        // Create PPT slide
        let pptSlide = PPTSlide(
            image: image,
            slideNumber: slideNumber,
            title: title,
            slideType: slideType
        )
        
        return pptSlide
    }
    
    private func extractSlideContent(from image: UIImage) throws -> String? {
        guard let cgImage = image.cgImage else {
            throw PPTCreationError.imageProcessingFailed
        }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Text Recognition Error: \(error.localizedDescription)")
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["tr-TR", "en-US"]
        request.minimumTextHeight = 0.01
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            throw PPTCreationError.textExtractionFailed(error.localizedDescription)
        }
        
        guard let observations = request.results, !observations.isEmpty else {
            return nil
        }
        
        var recognizedText = ""
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            recognizedText += topCandidate.string + "\n"
        }
        
        return recognizedText.isEmpty ? nil : recognizedText
    }
    
    func generatePPT(from project: PPTProject) async throws -> URL {
        await MainActor.run {
            self.isProcessing = true
            self.processingProgress = 0.0
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            visionQueue.async {
                do {
                    let pptURL = try self.createPPTDocument(project: project)
                    
                    Task { @MainActor in
                        self.isProcessing = false
                        self.processingProgress = 1.0
                        continuation.resume(returning: pptURL)
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
    
    private func createPPTDocument(project: PPTProject) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(project.title.replacingOccurrences(of: " ", with: "_"))_\(Date().timeIntervalSince1970).pdf"
        let pptURL = documentsPath.appendingPathComponent(fileName)
        
        // Create PDF document (as PPT alternative)
        let pdfDocument = PDFKit.PDFDocument()
        
        // Add title slide
        if let firstSlide = project.slides.first {
            let titlePage = createTitleSlide(slide: firstSlide, project: project)
            pdfDocument.insert(titlePage, at: 0)
        }
        
        // Add content slides
        let sortedSlides = project.slides.sorted { $0.slideNumber < $1.slideNumber }
        
        for (index, slide) in sortedSlides.enumerated() {
            let pdfPage = createSlidePage(from: slide, project: project)
            pdfDocument.insert(pdfPage, at: index + 1)
        }
        
        // Add metadata
        pdfDocument.documentAttributes = [
            PDFDocumentAttribute.titleAttribute: project.title,
            PDFDocumentAttribute.authorAttribute: project.author ?? "Unknown",
            PDFDocumentAttribute.creatorAttribute: "ModernPDFScanner PPT",
            PDFDocumentAttribute.creationDateAttribute: project.createdAt,
            PDFDocumentAttribute.modificationDateAttribute: project.lastModified
        ]
        
        // Save PDF
        guard pdfDocument.write(to: pptURL) else {
            throw PPTCreationError.pptGenerationFailed("PPT dosyası kaydedilemedi")
        }
        
        return pptURL
    }
    
    private func createTitleSlide(slide: PPTSlide, project: PPTProject) -> PDFPage {
        // Create a title slide with project information
        let pageSize = CGSize(width: 612, height: 792) // Standard page size
        let renderer = UIGraphicsImageRenderer(size: pageSize)
        
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // Set background color based on theme
            cgContext.setFillColor(project.theme.primaryColor.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: pageSize))
            
            // Add title
            let titleRect = CGRect(x: 50, y: 300, width: pageSize.width - 100, height: 100)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 36),
                .foregroundColor: UIColor.white
            ]
            project.title.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Add author if available
            if let author = project.author {
                let authorRect = CGRect(x: 50, y: 400, width: pageSize.width - 100, height: 50)
                let authorAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 24),
                    .foregroundColor: UIColor.white
                ]
                author.draw(in: authorRect, withAttributes: authorAttributes)
            }
            
            // Add date
            let dateRect = CGRect(x: 50, y: 500, width: pageSize.width - 100, height: 30)
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.white
            ]
            let dateString = DateFormatter.localizedString(from: project.createdAt, dateStyle: .long, timeStyle: .none)
            dateString.draw(in: dateRect, withAttributes: dateAttributes)
        }
        
        return PDFPage(image: image) ?? PDFPage()
    }
    
    private func createSlidePage(from slide: PPTSlide, project: PPTProject) -> PDFPage {
        // Create a slide page with content
        let pageSize = CGSize(width: 612, height: 792)
        let renderer = UIGraphicsImageRenderer(size: pageSize)
        
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // Set background color
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: pageSize))
            
            // Add slide number
            let slideNumberRect = CGRect(x: 50, y: 50, width: 100, height: 30)
            let slideNumberAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: project.theme.primaryColor
            ]
            "Slayt \(slide.slideNumber)".draw(in: slideNumberRect, withAttributes: slideNumberAttributes)
            
            // Add slide title if available
            if let title = slide.title {
                let titleRect = CGRect(x: 50, y: 100, width: pageSize.width - 100, height: 50)
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 24),
                    .foregroundColor: UIColor.black
                ]
                title.draw(in: titleRect, withAttributes: titleAttributes)
            }
            
            // Add slide content
            if let content = slide.content {
                let contentRect = CGRect(x: 50, y: 170, width: pageSize.width - 100, height: 500)
                let contentAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16),
                    .foregroundColor: UIColor.black
                ]
                content.draw(in: contentRect, withAttributes: contentAttributes)
            }
        }
        
        return PDFPage(image: image) ?? PDFPage()
    }
    
    func reorderSlides(_ slides: [PPTSlide]) -> [PPTSlide] {
        return slides.sorted { $0.slideNumber < $1.slideNumber }
    }
    
    func deleteSlide(_ slide: PPTSlide, from project: PPTProject) -> PPTProject {
        let updatedSlides = project.slides.filter { $0.id != slide.id }
        
        return PPTProject(
            id: project.id,
            title: project.title,
            author: project.author,
            slides: updatedSlides,
            createdAt: project.createdAt,
            lastModified: Date(),
            theme: project.theme
        )
    }
    
    func updateSlideOrder(_ slides: [PPTSlide], in project: PPTProject) -> PPTProject {
        let reorderedSlides = slides.enumerated().map { index, slide in
            PPTSlide(
                image: slide.image,
                slideNumber: index + 1,
                title: slide.title,
                slideType: slide.slideType
            )
        }
        
        return PPTProject(
            id: project.id,
            title: project.title,
            author: project.author,
            slides: reorderedSlides,
            createdAt: project.createdAt,
            lastModified: Date(),
            theme: project.theme
        )
    }
    
    func saveProject(_ project: PPTProject) {
        // Save to user defaults or core data
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(project) {
            UserDefaults.standard.set(data, forKey: "savedPPTProjects")
        }
    }
    
    func loadProjects() -> [PPTProject] {
        guard let data = UserDefaults.standard.data(forKey: "savedPPTProjects"),
              let projects = try? JSONDecoder().decode([PPTProject].self, from: data) else {
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
