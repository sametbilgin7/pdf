//
//  PDFPreviewView.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    let pdfURL: URL
    let fileName: String
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var pdfThumbnail: UIImage?
    @State private var pageCount: Int = 0
    @State private var isGeneratingThumbnail = false
    @State private var loadError = false
    
    private let pdfGenerator = PDFGeneratorService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // PDF Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 400)
                    
                    if loadError {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                            Text("PDF Load Failed".localized)
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("PDF file could not be opened".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if isGeneratingThumbnail {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading PDF...".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else if let thumbnail = pdfThumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 360)
                            .cornerRadius(12)
                            .shadow(radius: 8)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            Text("PDF Ready".localized)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                // PDF Information
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                        Text(fileName)
                            .font(.headline)
                            .lineLimit(1)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.secondary)
                        Text("\(pageCount) \(pageCount == 1 ? "page".localized : "pages".localized)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text("Created \(DateFormatter.preview.string(from: Date()))".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    // Export PDF Button
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export PDF".localized)
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
                    
                    // Open in PDF Viewer Button
                    Button(action: {
                        openPDFInViewer()
                    }) {
                        HStack {
                            Image(systemName: "eye")
                            Text("Open in PDF Viewer")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("PDF Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadPDFInfo()
        }
        .sheet(isPresented: $showingShareSheet) {
            PDFShareSheet(activityItems: [pdfURL])
        }
    }
    
    private func loadPDFInfo() {
        print("🔍 Loading PDF info for: \(pdfURL.path)")
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: pdfURL.path) else {
            print("❌ PDF file does not exist at: \(pdfURL.path)")
            DispatchQueue.main.async {
                self.loadError = true
                self.isGeneratingThumbnail = false
            }
            return
        }
        
        print("✅ PDF file exists, loading info...")
        isGeneratingThumbnail = true
        
        Task {
            do {
                // Get page count
                let count = pdfGenerator.getPDFPageCount(from: pdfURL)
                print("📄 PDF has \(count) pages")
                
                // Generate thumbnail
                let thumbnail = pdfGenerator.generatePDFThumbnail(from: pdfURL)
                print("🖼️ Thumbnail generated: \(thumbnail != nil ? "Success" : "Failed")")
                
                await MainActor.run {
                    self.pageCount = count
                    self.pdfThumbnail = thumbnail
                    self.isGeneratingThumbnail = false
                    print("✅ PDF info loaded successfully")
                }
            } catch {
                print("❌ Error loading PDF info: \(error)")
                await MainActor.run {
                    self.loadError = true
                    self.isGeneratingThumbnail = false
                }
            }
        }
    }
    
    private func openPDFInViewer() {
        // This would open the PDF in the system PDF viewer
        // For now, we'll just show the share sheet
        showingShareSheet = true
    }
}

// MARK: - PDFShareSheet
struct PDFShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let preview: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    PDFPreviewView(
        pdfURL: URL(fileURLWithPath: "/tmp/sample.pdf"),
        fileName: "Sample Document"
    )
}
