//
//  ScannerView.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI
import VisionKit
import UIKit

struct ScannerView: View {
    @Binding var selectedTab: TabSelection
    @ObservedObject var libraryService: PDFLibraryService
    @State private var showingScanner = false
    @State private var showingCreateModal = false
    @State private var selectedCollection: ScannedCollection?
    @State private var showingCollectionOptions = false
    @State private var showingImportModal = false
    @State private var showingImagePicker = false
    @State private var isGridView = true
    @State private var showingDocumentEditor = false
    @State private var activeCollectionIndex: Int?
    @State private var activePageIndex: Int = 0
    @State private var pendingScanImages: [UIImage] = []
    @State private var importedImages: [UIImage] = []
    
    var body: some View {
        ZStack {
            // Background
            Color.gray.opacity(0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Scanner".localized)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Add button
                        Menu {
                            Button(action: {
                                showingScanner = true
                            }) {
                                Label("Scan".localized, systemImage: "doc.viewfinder.fill")
                            }
                            
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                Label("Photos".localized, systemImage: "photo.fill")
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.purple)
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        // More options button
                        Menu {
                            Button(action: {
                                // Sort functionality
                            }) {
                                Label("Sort".localized, systemImage: "arrow.up.arrow.down")
                            }
                            
                            Button(action: {
                                // Select functionality
                            }) {
                                Label("Select".localized, systemImage: "checkmark.circle")
                            }
                            
                            Button(action: {
                                isGridView.toggle()
                            }) {
                                Label(isGridView ? "List".localized : "Grid".localized, 
                                      systemImage: isGridView ? "list.bullet" : "grid")
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                // Collections list
                ScrollView {
                    if libraryService.scannedCollections.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 48))
                                .foregroundColor(.textSecondary)
                            
                            Text("No Scanned Documents".localized)
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            
                            Text("Start scanning documents to see them here".localized)
                                .font(.body)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 100)
                    } else if isGridView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(libraryService.scannedCollections) { collection in
                                ScannedCollectionCard(
                                    collection: collection,
                                    onTap: {
                                        openEditor(for: collection)
                                    },
                                    onOptionsTap: {
                                        selectedCollection = collection
                                        showingCollectionOptions = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(libraryService.scannedCollections) { collection in
                                ScannedCollectionListCard(
                                    collection: collection,
                                    onTap: {
                                        openEditor(for: collection)
                                    },
                                    onOptionsTap: {
                                        selectedCollection = collection
                                        showingCollectionOptions = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer()
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Menu {
                        Button(action: {
                            showingScanner = true
                        }) {
                            Label("Scan".localized, systemImage: "doc.viewfinder.fill")
                        }
                        
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            Label("Photos".localized, systemImage: "photo.fill")
                        }
                    } label: {
                        FloatingPlusButtonLabel()
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .fullScreenCover(isPresented: $showingScanner) {
            DocumentScannerView(scannedImages: $pendingScanImages) {
                showingScanner = false
            }
        }
        .fullScreenCover(isPresented: $showingDocumentEditor) {
            if let index = activeCollectionIndex,
               libraryService.scannedCollections.indices.contains(index) {
                DocumentEditorView(
                    images: Binding(
                        get: { libraryService.scannedCollections[index].images },
                        set: { libraryService.scannedCollections[index].images = $0 }
                    ),
                    initialIndex: activePageIndex,
                    title: libraryService.scannedCollections[index].name
                )
                .onDisappear {
                    if libraryService.scannedCollections.indices.contains(index),
                       libraryService.scannedCollections[index].images.isEmpty {
                        libraryService.removeScannedCollection(at: index)
                    }
                    activeCollectionIndex = nil
                    activePageIndex = 0
                }
            }
        }
        .sheet(isPresented: $showingCreateModal) {
            CreateScannerModalView()
                .presentationDetents([.height(300), .medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingImportModal) {
            ImportModalView()
                .presentationDetents([.height(200), .medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView { image in
                importedImages = [image]
            }
        }
        .onAppear {
            // Sample data removed
        }
        .onChange(of: pendingScanImages) { newValue in
            guard !newValue.isEmpty else { return }
            addCollection(with: newValue, source: .scan)
            pendingScanImages.removeAll()
        }
        .onChange(of: importedImages) { newValue in
            guard !newValue.isEmpty else { return }
            addCollection(with: newValue, source: .photoLibrary)
            importedImages.removeAll()
        }
    }
    
    private func openEditor(for collection: ScannedCollection, pageIndex: Int = 0) {
        guard let index = libraryService.scannedCollections.firstIndex(where: { $0.id == collection.id }) else { return }
        let pages = libraryService.scannedCollections[index].images
        guard !pages.isEmpty else { return }
        
        activeCollectionIndex = index
        activePageIndex = max(0, min(pageIndex, pages.count - 1))
        showingDocumentEditor = true
    }
    
    
    private func addCollection(with images: [UIImage], source: CollectionSource) {
        let validImages = images.filter { $0.size.width > 1 && $0.size.height > 1 }
        guard !validImages.isEmpty else { return }
        
        // Add to library service for HomeView
        libraryService.addScannedImages(validImages)
        
        let newCollection = ScannedCollection(
            id: UUID(),
            name: generateCollectionName(for: source),
            size: formatSize(for: validImages),
            thumbnail: "photo.fill",
            dateCreated: Date(),
            images: validImages
        )
        
        libraryService.addScannedCollection(newCollection)
        openEditor(for: newCollection)
    }
    
    private func generateCollectionName(for source: CollectionSource) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        
        switch source {
        case .scan:
            return timestamp
        case .photoLibrary:
            return "Photos-\(timestamp)"
        }
    }
    
    private func formatSize(for images: [UIImage]) -> String {
        let totalBytes = images.compactMap { $0.jpegData(compressionQuality: 0.85)?.count }.reduce(0, +)
        guard totalBytes > 0 else { return "0 KB" }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(totalBytes))
    }
    
    private enum CollectionSource {
        case scan
        case photoLibrary
    }
}


// MARK: - Scanned Collection Card (Grid View)
struct ScannedCollectionCard: View {
    let collection: ScannedCollection
    let onTap: () -> Void
    let onOptionsTap: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.cardBackground)
                    .frame(height: 120)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                
                if let preview = collection.images.first {
                    Image(uiImage: preview)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 96, maxHeight: 64)
                        .clipped()
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
                } else {
                    Image(systemName: collection.thumbnail)
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                }
                
                // Options button - top right corner
                VStack {
                    HStack(spacing: 0) {
                        Spacer()
                        Menu {
                            Button("Convert To PDF".localized) {
                                // Convert to PDF
                            }
                            Button("Rename".localized) {
                                // Rename collection
                            }
                            Button("Group".localized) {
                                // Group collection
                            }
                            Button("Share".localized) {
                                // Share collection
                            }
                            Button("Delete".localized, role: .destructive) {
                                // Delete collection
                                onOptionsTap()
                            }
                        } label: {
                            Text("⋮")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 32, height: 32)
                                .contentShape(Circle())
                        }
                    }
                    .padding(.trailing, -4)
                    Spacer()
                }
                .padding(.top, 2)
                .zIndex(100)
            }
            
            Text(collection.name)
                .font(.caption2)
                .foregroundColor(.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 30)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Scanned Collection List Card (List View)
struct ScannedCollectionListCard: View {
    let collection: ScannedCollection
    let onTap: () -> Void
    let onOptionsTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                Group {
                    if let preview = collection.images.first {
                        Image(uiImage: preview)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .clipped()
                            .cornerRadius(6)
                    } else {
                        Image(systemName: collection.thumbnail)
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                }
                .padding(8)
            }
            
            // Collection info
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Text("Collection - \(collection.size)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Options button
            Menu {
                Button("Convert To PDF".localized) {
                    // Convert to PDF
                }
                Button("Rename".localized) {
                    // Rename collection
                }
                Button("Group".localized) {
                    // Group collection
                }
                Button("Share".localized) {
                    // Share collection
                }
                Button("Delete".localized, role: .destructive) {
                    // Delete collection
                    onOptionsTap()
                }
            } label: {
                Text("⋮")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                    .padding(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Create Scanner Modal View
struct CreateScannerModalView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 20)
            
            VStack(alignment: .leading, spacing: 24) {
                // Create New Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Create New".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ScannerCreateButton(
                            title: "Scan Document".localized,
                            icon: "doc.viewfinder.fill",
                            color: .blue,
                            action: {
                                dismiss()
                            }
                        )
                        
                        
                        ScannerCreateButton(
                            title: "Scan Receipt".localized,
                            icon: "receipt.fill",
                            color: .orange,
                            action: {
                                dismiss()
                            }
                        )
                        
                        ScannerCreateButton(
                            title: "Scan Business Card".localized,
                            icon: "person.crop.rectangle.fill",
                            color: .purple,
                            action: {
                                dismiss()
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.white)
    }
}

// MARK: - Scanner Create Button
struct ScannerCreateButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Import Modal View
struct ImportModalView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 20)
            
            VStack(spacing: 20) {
                Text("Please choose option to import more documents".localized)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 0) {
                    ImportOptionButton(
                        title: "İçe Aktar".localized,
                        icon: "square.and.arrow.down",
                        color: .blue,
                        action: {
                            dismiss()
                        }
                    )
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 0.5)
                        .padding(.horizontal, 16)
                    
                    ImportOptionButton(
                        title: "Yeni Oluştur".localized,
                        icon: "plus",
                        color: .green,
                        action: {
                            dismiss()
                        }
                    )
                }
                .background(Color.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.white)
    }
}

// MARK: - Image Picker View
struct ImagePickerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, onImagePicked: onImagePicked)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        let onImagePicked: (UIImage) -> Void
        
        init(parent: ImagePickerView, onImagePicked: @escaping (UIImage) -> Void) {
            self.parent = parent
            self.onImagePicked = onImagePicked
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Import Option Button
struct ImportOptionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.black)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ScannerView(
        selectedTab: .constant(.scan),
        libraryService: PDFLibraryService()
    )
}

// MARK: - Scanned Images Overlay
struct ScannedImagesOverlay: View {
    @Binding var scannedImages: [UIImage]
    let onEdit: (UIImage) -> Void
    let onCreatePDF: () -> Void
    @Binding var isGeneratingPDF: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Images Preview
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(0..<scannedImages.count, id: \.self) { index in
                        ZStack {
                            Image(uiImage: scannedImages[index])
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 100)
                                .cornerRadius(CornerRadius.small)
                                .shadow(
                                    color: ShadowStyle.soft.color,
                                    radius: ShadowStyle.soft.radius,
                                    x: ShadowStyle.soft.x,
                                    y: ShadowStyle.soft.y
                                )
                                .onTapGesture {
                                    HapticManager.light()
                                    onEdit(scannedImages[index])
                                }
                            
                            // Page number
                            VStack {
                                HStack {
                                    Spacer()
                                    Text("\(index + 1)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(
                                            Circle()
                                                .fill(Color.black.opacity(0.7))
                                        )
                                }
                                Spacer()
                            }
                            .padding(4)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
            .frame(height: 120)
            
            // Action Buttons
            HStack(spacing: Spacing.md) {
                Button(action: {
                    HapticManager.warning()
                    withAnimation(AnimationStyle.smooth) {
                        scannedImages.removeAll()
                    }
                }) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "trash")
                        Text("Delete".localized)
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        Capsule()
                            .fill(Color.red)
                    )
                }
                
                Spacer()
                
                Text("\(scannedImages.count) \(scannedImages.count == 1 ? "page".localized : "pages".localized)")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.5))
                    )
                
                Spacer()
                
                Button(action: {
                    HapticManager.medium()
                    onCreatePDF()
                }) {
                    HStack(spacing: Spacing.xs) {
                        if isGeneratingPDF {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "doc.fill")
                        }
                        Text(isGeneratingPDF ? "Creating PDF...".localized : "Create PDF".localized)
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        Capsule()
                            .fill(isGeneratingPDF ? Color.gray : Color.green)
                    )
                }
                .disabled(isGeneratingPDF)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(Color.black.opacity(0.8))
                .blur(radius: 20)
        )
        .cornerRadius(CornerRadius.large)
        .padding(Spacing.md)
    }
}

#Preview {
    ScannerView(
        selectedTab: .constant(.scan),
        libraryService: PDFLibraryService()
    )
}
