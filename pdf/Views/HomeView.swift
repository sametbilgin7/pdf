//
//  HomeView.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI
import VisionKit

struct HomeView: View {
    @StateObject private var libraryService = PDFLibraryService()
    @State private var showingScanner = false
    @State private var showingDocumentEditor = false
    @State private var selectedImageIndex: Int?
    @State private var showingPDFPreview = false
    @State private var generatedPDFURL: URL?
    @State private var isGeneratingPDF = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let pdfGenerator = PDFGeneratorService()
    
    var body: some View {
        VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Modern PDF Scanner".localized)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Scan documents and convert them to PDF".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Scan Button
                Button(action: {
                    showingScanner = true
                }) {
                    HStack {
                        Image(systemName: "camera.viewfinder")
                        Text("Scan Document".localized)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                
                // Recent Scans (if any)
                if !libraryService.scannedImages.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Scanned Pages".localized)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(libraryService.scannedImages.count) \(libraryService.scannedImages.count == 1 ? "page".localized : "pages".localized)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 32)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(0..<libraryService.scannedImages.count, id: \.self) { index in
                                    VStack(spacing: 8) {
                                        ZStack {
                                            Image(uiImage: libraryService.scannedImages[index])
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 120, height: 160)
                                                .cornerRadius(12)
                                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                                .onTapGesture {
                                                    selectedImageIndex = index
                                                    showingDocumentEditor = true
                                                }
                                            
                                            // Page number overlay
                                            VStack {
                                                HStack {
                                                    Spacer()
                                                    Text("\(index + 1)")
                                                        .font(.caption2)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .background(Color.black.opacity(0.7))
                                                        .cornerRadius(8)
                                                }
                                                Spacer()
                                            }
                                            .padding(8)
                                            
                                            // Edit button overlay
                                            VStack {
                                                HStack {
                                                    Button(action: {
                                                        selectedImageIndex = index
                                                        showingDocumentEditor = true
                                                    }) {
                                                        Image(systemName: "pencil")
                                                            .font(.caption)
                                                            .foregroundColor(.white)
                                                            .padding(6)
                                                            .background(Color.blue.opacity(0.8))
                                                            .cornerRadius(6)
                                                    }
                                                    Spacer()
                                                }
                                                Spacer()
                                            }
                                            .padding(8)
                                        }
                                        
                                        Text("\(index + 1)".localized)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 32)
                        }
                        
                        // Action buttons for scanned images
                        HStack(spacing: 16) {
                            Button(action: {
                                // Clear all scanned images
                                libraryService.clearScannedImages()
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Clear All".localized)
                                }
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            Spacer()
                            
                                    Button(action: {
                                        generatePDF()
                                    }) {
                                        HStack {
                                            if isGeneratingPDF {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                                    .foregroundColor(.white)
                                            } else {
                                                Image(systemName: "doc.fill")
                                            }
                                            Text(isGeneratingPDF ? "Creating PDF...".localized : "Create PDF".localized)
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(isGeneratingPDF ? Color.gray : Color.blue)
                                        .cornerRadius(8)
                                    }
                                    .disabled(isGeneratingPDF)
                        }
                        .padding(.horizontal, 32)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        .sheet(isPresented: $showingScanner) {
            DocumentScannerView(
                scannedImages: $libraryService.scannedImages,
                onClose: {
                    showingScanner = false
                }
            )
        }
        .fullScreenCover(isPresented: $showingDocumentEditor) {
            if let index = selectedImageIndex {
                DocumentEditorView(
                    images: $libraryService.scannedImages,
                    initialIndex: index
                )
                .onDisappear {
                    selectedImageIndex = nil
                }
            }
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let pdfURL = generatedPDFURL {
                PDFPreviewView(pdfURL: pdfURL, fileName: "ScannedDocument")
            }
        }
        .alert("PDF Generation".localized, isPresented: $showingAlert) {
            Button("OK".localized) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - PDF Generation
    private func generatePDF() {
        guard !libraryService.scannedImages.isEmpty else {
            alertMessage = "No scanned images available to create PDF".localized
            showingAlert = true
            return
        }
        
        isGeneratingPDF = true
        
        Task {
            do {
                let pdfURL = try await pdfGenerator.generatePDF(from: libraryService.scannedImages)
                
                await MainActor.run {
                    self.generatedPDFURL = pdfURL
                    self.isGeneratingPDF = false
                    self.showingPDFPreview = true
                }
            } catch {
                await MainActor.run {
                    self.isGeneratingPDF = false
                    self.alertMessage = "Failed to generate PDF: \(error.localizedDescription)".localized
                    self.showingAlert = true
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
