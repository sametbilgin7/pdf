//
//  OCRView.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI

struct OCRView: View {
    let image: UIImage
    @StateObject private var ocrService = OCRService()
    @State private var selectedLanguage: OCRLanguage = .auto
    @State private var showingLanguagePicker = false
    @State private var showingShareSheet = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with image preview
                VStack(spacing: 16) {
                    // Image preview
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    
                    // Language selection
                    HStack {
                        Text("Language:".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: {
                            showingLanguagePicker = true
                        }) {
                            HStack(spacing: 4) {
                                Text(selectedLanguage.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(Color(.systemGray6))
                
                Divider()
                
                // Content area
                if ocrService.isProcessing {
                    ProcessingView()
                } else if let result = ocrService.lastResult {
                    ResultView(result: result, onShare: {
                        showingShareSheet = true
                    })
                } else if let error = ocrService.errorMessage {
                    ErrorView(message: error, onRetry: {
                        performOCR()
                    })
                } else {
                    EmptyStateView(onStart: {
                        performOCR()
                    })
                }
            }
            .navigationTitle("Text Recognition".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if ocrService.lastResult != nil {
                        Button("Share".localized) {
                            showingShareSheet = true
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingLanguagePicker) {
            LanguagePickerView(selectedLanguage: $selectedLanguage)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let result = ocrService.lastResult {
                OCRShareSheet(activityItems: [result.formattedText])
            }
        }
        .alert("OCR Error".localized, isPresented: $showingAlert) {
            Button("OK".localized) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func performOCR() {
        Task {
            do {
                _ = try await ocrService.recognizeText(from: image, language: selectedLanguage)
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

struct ProcessingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
            
            VStack(spacing: 8) {
                Text("Recognizing Text...".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Analyzing image for text content".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct ResultView: View {
    let result: OCRResult
    let onShare: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Result header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recognition Results".localized)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 16) {
                        Label("\(result.confidencePercentage)%", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Label(result.language, systemImage: "globe")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Label("\(String(format: "%.2f", result.processingTime))s", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            Divider()
            
            // Text content
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recognized Text:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(result.formattedText)
                        .font(.body)
                        .lineSpacing(4)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
        }
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                Text("Recognition Failed")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue)
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct EmptyStateView: View {
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "text.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text("Ready to Recognize Text")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Tap the button below to start text recognition on this image")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onStart) {
                HStack {
                    Image(systemName: "text.viewfinder")
                    Text("Recognize Text")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct LanguagePickerView: View {
    @Binding var selectedLanguage: OCRLanguage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(OCRLanguage.allCases) { language in
                    Button(action: {
                        selectedLanguage = language
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(language.displayName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(language.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Select Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Share Sheet
struct OCRShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    OCRView(image: UIImage(systemName: "doc.text") ?? UIImage())
}
