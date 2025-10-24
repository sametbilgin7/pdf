//
//  PhotoTranslationView.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI

struct PhotoTranslationView: View {
    @StateObject private var translationService = PhotoTranslationService()
    @State private var capturedImage: UIImage?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isProcessing = false
    @State private var selectedTargetLanguage: SupportedLanguage = .english
    @State private var showingCamera = false
    @State private var showingPhotoPreview = false
    @State private var tempImage: UIImage?
    @State private var showingLanguageSelector = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "globe")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Fotoğraf Çevirisi")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Fotoğraftaki metni çevirin")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 32)
                    
                    // Content
                    if let translationResult = translationService.lastResult {
                        // Show translation result
                        TranslationResultView(
                            result: translationResult,
                            onCopy: {
                                copyToClipboard(translationResult.formattedTranslatedText)
                            },
                            onSave: {
                                saveTranslation(translationResult)
                            }
                        )
                    } else if isProcessing {
                        // Processing state
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.blue)
                            
                            Text("Çeviri işleniyor...")
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
                                Text("Hedef Dil")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Button(action: {
                                    showingLanguageSelector = true
                                }) {
                                    HStack {
                                        Text(selectedTargetLanguage.displayName)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                    )
                                }
                            }
                            .padding(.horizontal, 32)
                            
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
            .navigationTitle("Fotoğraf Çevirisi")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingCamera) {
            TranslationCameraView { image in
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
        .sheet(isPresented: $showingLanguageSelector) {
            LanguageSelectorView(selectedLanguage: $selectedTargetLanguage)
        }
        .alert("Photo Translation".localized, isPresented: $showingAlert) {
            Button("Tamam") { }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: translationService.errorMessage) { errorMessage in
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
                let result = try await translationService.translatePhoto(from: image, targetLanguage: selectedTargetLanguage)
                
                await MainActor.run {
                    isProcessing = false
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
        alertMessage = "Çeviri panoya kopyalandı"
        showingAlert = true
    }
    
    private func saveTranslation(_ result: TranslationResult) {
        // Save to user defaults or core data
        let savedTranslations = UserDefaults.standard.stringArray(forKey: "savedTranslations") ?? []
        let newTranslations = savedTranslations + [result.formattedTranslatedText]
        UserDefaults.standard.set(newTranslations, forKey: "savedTranslations")
        
        alertMessage = "Çeviri kaydedildi"
        showingAlert = true
    }
}

// MARK: - Translation Result View
struct TranslationResultView: View {
    let result: TranslationResult
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
                    
                    Text("Çeviri Başarıyla Tamamlandı")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Güvenilirlik: %\(result.confidencePercentage)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
                
                // Translation information
                VStack(alignment: .leading, spacing: 16) {
                    // Original text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Orijinal Metin (\(result.detectedLanguage.uppercased()))")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(result.formattedOriginalText)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                    }
                    
                    // Translated text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Çeviri (\(result.targetLanguage.uppercased()))")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(result.formattedTranslatedText)
                            .font(.body)
                            .foregroundColor(.green)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.1))
                                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                    }
                    
                    // Processing info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("İşlem Bilgileri")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text("İşlem Süresi:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(String(format: "%.2f", result.processingTime))s")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                    }
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
                }
                .padding(.horizontal, 32)
            }
            .padding()
        }
        .sheet(isPresented: $showingShareSheet) {
            TranslationShareSheet(activityItems: [result.formattedTranslatedText])
        }
    }
}

// MARK: - Translation Camera View
struct TranslationCameraView: View {
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingDocumentScanner = false
    @State private var scannedImages: [UIImage] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "translate")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Fotoğraf Çevirisi")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Apple Document Scanner kullanarak çevrilecek metni tarayın")
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

// MARK: - Language Selector View
struct LanguageSelectorView: View {
    @Binding var selectedLanguage: SupportedLanguage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(SupportedLanguage.allCases) { language in
                    Button(action: {
                        selectedLanguage = language
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(language.displayName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(language.nativeName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Dil Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Share Sheet
struct TranslationShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    PhotoTranslationView()
}
