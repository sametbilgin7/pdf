//
//  TextExtractionView.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI

struct TextExtractionView: View {
    @StateObject private var ocrService = OCRService()
    @State private var capturedImage: UIImage?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isProcessing = false
    @State private var selectedLanguage: OCRLanguage = .auto
    @State private var extractedText = ""
    @State private var showingTextEditor = false
    @State private var showingCamera = false
    @State private var showingPhotoPreview = false
    @State private var tempImage: UIImage?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "text.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Metin Çıkarıcı")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Fotoğraftan metin çıkarın ve düzenleyin")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 32)
                    
                    // Content
                    if let ocrResult = ocrService.lastResult {
                        // Show extracted text
                        ExtractedTextView(
                            ocrResult: ocrResult,
                            onEdit: {
                                showingTextEditor = true
                            },
                            onCopy: {
                                copyToClipboard(ocrResult.text)
                            },
                            onSave: {
                                saveExtractedText(ocrResult.text)
                            }
                        )
                    } else if isProcessing {
                        // Processing state
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.blue)
                            
                            Text("Processing text...".localized)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Lütfen bekleyin")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 60)
                    } else {
                        // Initial state - show camera options
                        VStack(spacing: 24) {
                            // Language selector
                            VStack(spacing: 12) {
                                Text("Dil Seçimi")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Picker("Dil", selection: $selectedLanguage) {
                                    ForEach(OCRLanguage.allCases) { language in
                                        Text(language.displayName).tag(language)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.horizontal, 32)
                            }
                            
                            // Camera button
                            Button(action: {
                                showingCamera = true
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                    
                                    Text("Kamerayı Aç")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            
                            // Gallery button
                            Button(action: {
                                // Gallery functionality removed
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 40))
                                        .foregroundColor(.blue)
                                    
                                    Text("Galeriden Seç")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.blue, lineWidth: 2)
                                        .background(Color.blue.opacity(0.1))
                                )
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Metin Çıkar")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingCamera) {
            CameraCaptureView { image in
                tempImage = image
                showingPhotoPreview = true
                showingCamera = false
            }
        }
        .sheet(isPresented: $showingPhotoPreview) {
            if let image = tempImage {
                PhotoPreviewView(
                    image: image,
                    onRetake: {
                        showingPhotoPreview = false
                        showingCamera = true
                    },
                    onUse: { finalImage in
                        processImage(finalImage)
                        showingPhotoPreview = false
                        tempImage = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showingTextEditor) {
            TextEditorView(
                initialText: extractedText,
                onSave: { newText in
                    extractedText = newText
                    showingTextEditor = false
                }
            )
        }
        .alert("Text Extraction".localized, isPresented: $showingAlert) {
            Button("Tamam") { }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: ocrService.errorMessage) { errorMessage in
            if let error = errorMessage {
                alertMessage = error
                showingAlert = true
            }
        }
    }
    
    private func processImage(_ image: UIImage) {
        isProcessing = true
        capturedImage = image
        
        Task {
            do {
                let result = try await ocrService.recognizeText(from: image, language: selectedLanguage)
                
                await MainActor.run {
                    isProcessing = false
                    extractedText = result.formattedText
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        alertMessage = "Metin panoya kopyalandı"
        showingAlert = true
    }
    
    private func saveExtractedText(_ text: String) {
        // Save to user defaults or core data
        let savedTexts = UserDefaults.standard.stringArray(forKey: "savedExtractedTexts") ?? []
        let newTexts = savedTexts + [text]
        UserDefaults.standard.set(newTexts, forKey: "savedExtractedTexts")
        
        alertMessage = "Metin kaydedildi"
        showingAlert = true
    }
}

// MARK: - Extracted Text View
struct ExtractedTextView: View {
    let ocrResult: OCRResult
    let onEdit: () -> Void
    let onCopy: () -> Void
    let onSave: () -> Void
    
    @State private var showingShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Success indicator
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Metin Başarıyla Çıkarıldı")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Güvenilirlik: %\(ocrResult.confidencePercentage)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if ocrResult.language != "unknown" {
                        Text("Algılanan Dil: \(ocrResult.language)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 20)
                
                // Extracted text
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Çıkarılan Metin")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(ocrResult.formattedText.count) karakter")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(ocrResult.formattedText)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: onCopy) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Panoya Kopyala")
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: onEdit) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Düzenle")
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 2)
                                    .background(Color.blue.opacity(0.1))
                            )
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showingShareSheet = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Paylaş")
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue, lineWidth: 2)
                                    .background(Color.blue.opacity(0.1))
                            )
                            .cornerRadius(12)
                        }
                    }
                    
                    Button(action: onSave) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Kaydet")
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.purple, .purple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 32)
            }
            .padding()
        }
        .sheet(isPresented: $showingShareSheet) {
            TextShareSheet(activityItems: [ocrResult.formattedText])
        }
    }
}

// MARK: - Text Editor View
struct TextEditorView: View {
    @State private var text: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    init(initialText: String, onSave: @escaping (String) -> Void) {
        self._text = State(initialValue: initialText)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $text)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Metin Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        onSave(text)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Camera Capture View
struct CameraCaptureView: View {
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingDocumentScanner = false
    @State private var scannedImages: [UIImage] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Metin Çıkarıcı")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Apple Document Scanner kullanarak metin içeren belgeleri tarayın")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Kamerayı Aç") {
                showingDocumentScanner = true
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(Color.blue)
            .cornerRadius(12)
            
            Button("İptal") {
                dismiss()
            }
            .font(.headline)
            .foregroundColor(.blue)
        }
        .padding()
        .fullScreenCover(isPresented: $showingDocumentScanner) {
            DocumentScannerView(
                scannedImages: $scannedImages,
                onClose: {
                    showingDocumentScanner = false
                }
            )
        }
        .onChange(of: scannedImages) { _, newValue in
            if let image = newValue.first {
                onImageCaptured(image)
            }
        }
    }
}

// MARK: - Photo Preview View
struct PhotoPreviewView: View {
    let image: UIImage
    let onRetake: () -> Void
    let onUse: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Image preview
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // Instructions
                Text("Bu fotoğrafı kullanmak istiyor musunuz?")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                // Action buttons
                HStack(spacing: 16) {
                    Button("Yeniden Çek") {
                        onRetake()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange)
                    .cornerRadius(12)
                    
                    Button("Kullan") {
                        onUse(image)
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Fotoğraf Önizleme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Share Sheet
struct TextShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    TextExtractionView()
}
