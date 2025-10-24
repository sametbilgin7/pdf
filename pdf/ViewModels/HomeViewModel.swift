//
//  HomeViewModel.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var scannedDocuments: [ScannedDocument] = []
    @Published var pdfDocuments: [PDFDocument] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let documentService = DocumentService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadDocuments()
    }
    
    func loadDocuments() {
        isLoading = true
        
        Task {
            do {
                let documents = try await documentService.loadScannedDocuments()
                let pdfs = try await documentService.loadPDFDocuments()
                
                await MainActor.run {
                    self.scannedDocuments = documents
                    self.pdfDocuments = pdfs
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func saveScannedDocument(name: String, images: [UIImage]) async throws {
        let document = ScannedDocument(
            name: name,
            pageCount: images.count,
            thumbnail: images.first
        )
        
        try await documentService.saveScannedDocument(document, images: images)
        loadDocuments()
    }
    
    func createPDF(from images: [UIImage], name: String) async throws {
        let pdfURL = try await documentService.createPDF(from: images, name: name)
        let pdfDocument = PDFDocument(
            name: name,
            url: pdfURL,
            pageCount: images.count
        )
        
        try await documentService.savePDFDocument(pdfDocument)
        loadDocuments()
    }
    
    func deleteScannedDocument(_ document: ScannedDocument) async throws {
        try await documentService.deleteScannedDocument(document)
        loadDocuments()
    }
    
    func deletePDFDocument(_ document: PDFDocument) async throws {
        try await documentService.deletePDFDocument(document)
        loadDocuments()
    }
}
