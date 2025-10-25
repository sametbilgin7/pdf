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
    private let pdfGenerator = PDFGeneratorService()
    @State private var showingScanner = false
    @State private var showingCreateModal = false
    @State private var selectedCollection: ScannedCollection?
    @State private var showingImportModal = false
    @State private var showingImagePicker = false
    @State private var isGridView = true
    @State private var activeEditor: EditorContext?
    @State private var pendingScanImages: [UIImage] = []
    @State private var importedImages: [UIImage] = []
    @State private var showingRenameAlert = false
    @State private var renameText: String = ""
    @State private var sharePayload: SharePayload?
    @State private var actionInfo: ActionInfo?
    @State private var isPerformingAction = false
    
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
                                    onMenuAction: { action in
                                        handleMenuAction(action, for: collection)
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
                                    onMenuAction: { action in
                                        handleMenuAction(action, for: collection)
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
            
            if isPerformingAction {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                ProgressView("Processing...".localized)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
                    )
            }
        }
        .fullScreenCover(isPresented: $showingScanner) {
            DocumentScannerView(scannedImages: $pendingScanImages) {
                showingScanner = false
            }
        }
        .fullScreenCover(item: $activeEditor) { editor in
            if let index = libraryService.scannedCollections.firstIndex(where: { $0.id == editor.id }) {
                let binding = Binding<[UIImage]>(
                    get: { libraryService.scannedCollections[index].images },
                    set: { newValue in
                        libraryService.scannedCollections[index].images = newValue
                    }
                )
                DocumentEditorView(
                    images: binding,
                    initialIndex: editor.pageIndex,
                    title: "Editor".localized
                )
                .onDisappear {
                    if let refreshedIndex = libraryService.scannedCollections.firstIndex(where: { $0.id == editor.id }) {
                        if libraryService.scannedCollections[refreshedIndex].images.isEmpty {
                            libraryService.removeScannedCollection(at: refreshedIndex)
                        } else {
                            libraryService.saveScannedCollections()
                        }
                    }
                    activeEditor = nil
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
        .sheet(item: $sharePayload) { payload in
            ModernShareSheet(activityItems: [payload.url]) {
                sharePayload = nil
            }
        }
        .alert("Rename".localized, isPresented: $showingRenameAlert) {
            TextField("Collection Name".localized, text: $renameText)
            Button("Cancel".localized, role: .cancel) {
                renameText = ""
                selectedCollection = nil
            }
            Button("Save".localized) {
                renameSelectedCollection()
            }
        } message: {
            Text("Enter a new name for this collection".localized)
        }
        .alert(item: $actionInfo) { info in
            Alert(
                title: Text(info.title),
                message: Text(info.message),
                dismissButton: .default(Text("OK".localized)) {
                    actionInfo = nil
                }
            )
        }
    }
    
    private func openEditor(for collection: ScannedCollection, pageIndex: Int = 0) {
        guard let index = libraryService.scannedCollections.firstIndex(where: { $0.id == collection.id }) else { return }
        libraryService.scannedCollections[index].ensureImagesLoaded()
        let pages = libraryService.scannedCollections[index].images
        guard !pages.isEmpty else { return }
        
        let targetIndex = max(0, min(pageIndex, pages.count - 1))
        activeEditor = EditorContext(id: collection.id, pageIndex: targetIndex)
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
        Task {
            await persistCollectionAsPDF(images: validImages, name: newCollection.name)
        }
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
    
    enum CollectionSource {
        case scan
        case photoLibrary
    }
    
    private func persistCollectionAsPDF(images: [UIImage], name: String) async {
        do {
            _ = try await pdfGenerator.generatePDF(from: images, fileName: name)
            await MainActor.run {
                libraryService.loadPDFFiles()
            }
        } catch {
            print("❌ Failed to persist scanned collection as PDF: \(error.localizedDescription)")
        }
    }
    
    private func handleMenuAction(_ action: CollectionMenuAction, for collection: ScannedCollection) {
        selectedCollection = collection
        switch action {
        case .convert:
            convertCollectionToPDF(collection)
        case .rename:
            renameText = collection.name
            showingRenameAlert = true
        case .group:
            presentGroupInfo()
        case .share:
            convertCollectionToPDF(collection, shouldShare: true)
        case .delete:
            deleteCollection(collection)
        }
    }
    
    private func convertCollectionToPDF(_ collection: ScannedCollection, shouldShare: Bool = false) {
        collection.ensureImagesLoaded()
        guard !collection.images.isEmpty else {
            actionInfo = ActionInfo(
                title: "No Pages".localized,
                message: "This collection does not contain any images.".localized
            )
            return
        }
        guard !isPerformingAction else { return }
        isPerformingAction = true
        Task {
            do {
                let url = try await pdfGenerator.generatePDF(from: collection.images, fileName: collection.name)
                await MainActor.run {
                    libraryService.loadPDFFiles()
                    if shouldShare {
                        sharePayload = SharePayload(url: url)
                    } else {
                        actionInfo = ActionInfo(
                            title: "Success".localized,
                            message: "PDF saved to your library".localized
                        )
                    }
                    isPerformingAction = false
                }
            } catch {
                await MainActor.run {
                    isPerformingAction = false
                    actionInfo = ActionInfo(
                        title: "Error".localized,
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
    
    private func renameSelectedCollection() {
        guard let collection = selectedCollection else { return }
        let trimmedName = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        libraryService.renameScannedCollection(collection, newName: trimmedName)
        selectedCollection?.name = trimmedName
        renameText = ""
        selectedCollection = nil
        showingRenameAlert = false
    }
    
    private func deleteCollection(_ collection: ScannedCollection) {
        guard let index = libraryService.scannedCollections.firstIndex(where: { $0.id == collection.id }) else { return }
        libraryService.removeScannedCollection(at: index)
    }
    
    private func presentGroupInfo() {
        actionInfo = ActionInfo(
            title: "Coming Soon".localized,
            message: "Grouping scanned collections will be available in a future update.".localized
        )
    }
}


// MARK: - Scanned Collection Card (Grid View)
struct ScannedCollectionCard: View {
    let collection: ScannedCollection
    let onTap: () -> Void
    let onMenuAction: (CollectionMenuAction) -> Void
    
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
                            Button {
                                onMenuAction(.convert)
                            } label: {
                                Label("Convert To PDF".localized, systemImage: "doc.text")
                            }
                            Button {
                                onMenuAction(.rename)
                            } label: {
                                Label("Rename".localized, systemImage: "pencil")
                            }
                            Button {
                                onMenuAction(.group)
                            } label: {
                                Label("Group".localized, systemImage: "rectangle.stack")
                            }
                            Button {
                                onMenuAction(.share)
                            } label: {
                                Label("Share".localized, systemImage: "square.and.arrow.up")
                            }
                            Button(role: .destructive) {
                                onMenuAction(.delete)
                            } label: {
                                Label("Delete".localized, systemImage: "trash")
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
    let onMenuAction: (CollectionMenuAction) -> Void
    
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
                Button {
                    onMenuAction(.convert)
                } label: {
                    Label("Convert To PDF".localized, systemImage: "doc.text")
                }
                Button {
                    onMenuAction(.rename)
                } label: {
                    Label("Rename".localized, systemImage: "pencil")
                }
                Button {
                    onMenuAction(.group)
                } label: {
                    Label("Group".localized, systemImage: "rectangle.stack")
                }
                Button {
                    onMenuAction(.share)
                } label: {
                    Label("Share".localized, systemImage: "square.and.arrow.up")
                }
                Button(role: .destructive) {
                    onMenuAction(.delete)
                } label: {
                    Label("Delete".localized, systemImage: "trash")
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

enum CollectionMenuAction {
    case convert
    case rename
    case group
    case share
    case delete
}

struct ActionInfo: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct SharePayload: Identifiable {
    let id = UUID()
    let url: URL
}

private struct EditorContext: Identifiable, Equatable {
    let id: UUID
    let pageIndex: Int
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
