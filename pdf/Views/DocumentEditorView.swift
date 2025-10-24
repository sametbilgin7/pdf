//
//  DocumentEditorView.swift
//  ModernPDFScanner
//
//  Created by Codex on 26.10.2025.
//

import SwiftUI
import UIKit

struct DocumentEditorView: View {
    @Binding var images: [UIImage]
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var showingImageEditor = false
    @State private var showingOCR = false
    @State private var infoMessage: String?
    
    private let title: String
    
    init(images: Binding<[UIImage]>, initialIndex: Int = 0, title: String = "Editor".localized) {
        self._images = images
        let boundedIndex = max(0, min(initialIndex, (images.wrappedValue.count - 1)))
        self._currentIndex = State(initialValue: boundedIndex)
        self.title = title
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.white,
                    Color(white: 0.97),
                    Color(red: 0.94, green: 0.97, blue: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                topBar
                    .padding(.top, 12)
                    .padding(.horizontal, 20)
                
                Spacer()
                
                imagePreview
                    .padding(.horizontal, 24)
                
                Spacer()
                
                pageIndicator
                    .padding(.top, 24)
                
                bottomToolbar
                    .padding(.top, 24)
            }
        }
        .sheet(isPresented: $showingImageEditor) {
            if let image = currentImage {
                ImageEditView(image: image) { editedImage in
                    updateCurrentImage(with: editedImage)
                }
            }
        }
        .sheet(isPresented: $showingOCR) {
            if let image = currentImage {
                OCRView(image: image)
            }
        }
        .alert(
            "Coming Soon".localized,
            isPresented: Binding<Bool>(
                get: { infoMessage != nil },
                set: { newValue in
                    if !newValue {
                        infoMessage = nil
                    }
                }
            )
        ) {
            Button("OK".localized, role: .cancel) { infoMessage = nil }
        } message: {
            Text(infoMessage ?? "")
        }
    }
    
    private var topBar: some View {
        HStack(spacing: 16) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(title)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.black)
            
            Spacer()
            
            Menu {
                Button(action: shareCurrentImage) {
                    Label("Share".localized, systemImage: "square.and.arrow.up")
                }
                
                Button(role: .destructive, action: deleteCurrentPage) {
                    Label("Delete Page".localized, systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color(red: 0.91, green: 0.94, blue: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var imagePreview: some View {
        Group {
            if let image = currentImage {
                GeometryReader { geometry in
                    let maxHeight = min(geometry.size.height, geometry.size.width * 1.4)
                    
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: geometry.size.width,
                            height: maxHeight
                        )
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 16)
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    let threshold: CGFloat = 50
                                    if value.translation.width > threshold {
                                        // Swipe right - previous page
                                        if currentIndex > 0 {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                currentIndex -= 1
                                            }
                                        }
                                    } else if value.translation.width < -threshold {
                                        // Swipe left - next page
                                        if currentIndex < images.count - 1 {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                currentIndex += 1
                                            }
                                        }
                                    }
                                }
                        )
                }
                .frame(height: 420)
            } else {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.6))
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(.gray.opacity(0.6))
                            Text("No image available".localized)
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                    )
                    .frame(height: 420)
            }
        }
    }
    
    private var pageIndicator: some View {
        Text("Page \(currentIndex + 1) of \(max(images.count, 1))")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.gray)
    }
    
    private var bottomToolbar: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.black.opacity(0.08))
                .frame(width: 40, height: 4)
            
            HStack(spacing: 0) {
                ForEach(editorActions) { action in
                    Button(action: action.perform) {
                        VStack(spacing: 8) {
                            Image(systemName: action.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.black)
                            
                            Text(action.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 28)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: -4)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
    
    private var currentImage: UIImage? {
        guard images.indices.contains(currentIndex) else { return nil }
        return images[currentIndex]
    }
    
    private var editorActions: [DocumentEditorAction] {
        [
            DocumentEditorAction(
                id: "edit",
                title: "Edit".localized,
                icon: "pencil",
                perform: {
                    guard currentImage != nil else { return }
                    showingImageEditor = true
                }
            ),
            DocumentEditorAction(
                id: "annotation",
                title: "Annotation".localized,
                icon: "highlighter",
                perform: { infoMessage = "Annotation tools will be available soon.".localized }
            ),
            DocumentEditorAction(
                id: "smudge",
                title: "Smudge".localized,
                icon: "hand.draw",
                perform: { infoMessage = "Smudge tool will be available soon.".localized }
            ),
            DocumentEditorAction(
                id: "ocr",
                title: "OCR".localized,
                icon: "text.viewfinder",
                perform: {
                    guard currentImage != nil else { return }
                    showingOCR = true
                }
            ),
            DocumentEditorAction(
                id: "signature",
                title: "Signature".localized,
                icon: "signature",
                perform: { infoMessage = "Signature tool will be available soon.".localized }
            )
        ]
    }
    
    private func updateCurrentImage(with image: UIImage) {
        guard images.indices.contains(currentIndex) else { return }
        images[currentIndex] = image
    }
    
    private func deleteCurrentPage() {
        guard images.indices.contains(currentIndex) else { return }
        
        withAnimation {
            images.remove(at: currentIndex)
            if images.isEmpty {
                dismiss()
            } else {
                currentIndex = min(currentIndex, images.count - 1)
            }
        }
    }
    
    private func shareCurrentImage() {
        guard let image = currentImage else { return }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
}

private struct DocumentEditorAction: Identifiable {
    let id: String
    let title: String
    let icon: String
    let perform: () -> Void
}

#Preview {
    DocumentEditorView(
        images: .constant([UIImage(systemName: "photo") ?? UIImage()]),
        initialIndex: 0
    )
}
