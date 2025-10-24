//
//  LibraryView.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI
import PDFKit
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct LibraryView: View {
    // Bindings for TabBar integration (defaults provided via init)
    @Binding var isSelectionModeExternal: Bool
    @Binding var selectedPDFCountExternal: Int
    @Binding var selectedFolderCountExternal: Int
    @Binding var onDeleteActionExternal: (() -> Void)?
    @Binding var onShareActionExternal: (() -> Void)?
    @Binding var onTagActionExternal: (() -> Void)?
    @Binding var onMergeActionExternal: (() -> Void)?
    @ObservedObject var libraryService: PDFLibraryService
    @State private var selectedPDF: PDFFile?
    @State private var showingDeleteAlert = false
    @State private var pdfToDelete: PDFFile?
    @State private var sortOrder = "By Date".localized
    @State private var showingScanner = false
    @State private var showingPhotoPicker = false
    @State private var showingFilePicker = false
    @State private var showingDocumentSourcePicker = false
    @State private var showingSearch = false
    @State private var searchText = ""
    @State private var showingCreateFolder = false
    @State private var newFolderName = ""
    @State private var isGridView = true // true = grid, false = list
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var scannedImages: [UIImage] = []
    @State private var isSelectionMode = false
    @State private var selectedPDFs: Set<UUID> = []
    @State private var selectedFolders: Set<UUID> = []
    @State private var jiggleAnimation = false
    @State private var showingTagsView = false
    @State private var showingMergeView = false
    
    let sortOptions = ["By Date".localized, "By Name".localized, "By Size".localized]

    init(
        libraryService: PDFLibraryService,
        isSelectionMode: Binding<Bool> = .constant(false),
        selectedPDFCount: Binding<Int> = .constant(0),
        selectedFolderCount: Binding<Int> = .constant(0),
        onDeleteAction: Binding<(() -> Void)?> = .constant(nil),
        onShareAction: Binding<(() -> Void)?> = .constant(nil),
        onTagAction: Binding<(() -> Void)?> = .constant(nil),
        onMergeAction: Binding<(() -> Void)?> = .constant(nil)
    ) {
        self.libraryService = libraryService
        self._isSelectionModeExternal = isSelectionMode
        self._selectedPDFCountExternal = selectedPDFCount
        self._selectedFolderCountExternal = selectedFolderCount
        self._onDeleteActionExternal = onDeleteAction
        self._onShareActionExternal = onShareAction
        self._onTagActionExternal = onTagAction
        self._onMergeActionExternal = onMergeAction
    }
    
    var sortedFolders: [Folder] {
        switch sortOrder {
        case "By Name".localized:
            return libraryService.folders.sorted { $0.name < $1.name }
        case "By Size".localized:
            return libraryService.folders.sorted { $0.documentCount > $1.documentCount }
        default: // By Date
            return libraryService.folders.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    var sortedPDFs: [PDFFile] {
        print("sortedPDFs called - libraryService.pdfFiles.count: \(libraryService.pdfFiles.count)")
        let sorted: [PDFFile]
        switch sortOrder {
        case "By Name".localized:
            sorted = libraryService.pdfFiles.sorted { $0.name < $1.name }
        case "By Size".localized:
            sorted = libraryService.pdfFiles.sorted { $0.fileSize > $1.fileSize }
        default: // By Date
            sorted = libraryService.pdfFiles.sorted { $0.createdAt > $1.createdAt }
        }
        
        print("sortedPDFs result count: \(sorted.count)")
        
        // Apply search filter
        if searchText.isEmpty {
            return sorted
        } else {
            return sorted.filter { pdf in
                pdf.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                mainContent
                    .navigationTitle("Library".localized)
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        toolbarContent
                    }
                    .onAppear {
                        print("LibraryView onAppear - PDF count: \(libraryService.pdfFiles.count)")
                        libraryService.loadPDFFiles()
                        print("After loadPDFFiles - PDF count: \(libraryService.pdfFiles.count)")
                        exportSelectionState()
                    }
            }
            .tint(.primaryBlue)
            
            sheets
        }
        .onChange(of: isSelectionMode) { _, _ in
            exportSelectionState()
        }
        .onChange(of: selectedPDFs) { _, _ in
            exportSelectionState()
        }
        .onChange(of: selectedFolders) { _, _ in
            exportSelectionState()
        }
    }
    
    // MARK: - Main Content
    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if !isSelectionMode {
                        addSourceSection
                    }
                    
                    LibraryToolbar(
                        sortOrder: $sortOrder,
                        sortOptions: sortOptions,
                        showingSearch: $showingSearch,
                        showingCreateFolder: $showingCreateFolder,
                        isGridView: $isGridView,
                        pdfCount: libraryService.pdfFiles.count,
                        isSelectionMode: $isSelectionMode
                    )
                        
                    
                    if showingSearch && !isSelectionMode {
                        searchBar
                    }
                    
                    if !sortedFolders.isEmpty {
                        foldersSection
                    }
                    
                    if !sortedPDFs.isEmpty {
                        pdfsSection
                    }
                    
                    if sortedPDFs.isEmpty && sortedFolders.isEmpty {
                        EmptyLibraryView()
                            .padding(.top, 100)
                    }
                }
                .padding(.top, Spacing.md)
            }
        }
    }
    
    // MARK: - Add Source Section
    @ViewBuilder
    private var addSourceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Add from:".localized)
                .font(Typography.subheadline)
                .foregroundColor(.textSecondary)
                .padding(.horizontal, Spacing.lg)
            
            HStack(spacing: Spacing.md) {
                AddSourceButton(
                    icon: "iphone.gen3",
                    title: "iPhone".localized,
                    action: { showingDocumentSourcePicker = true }
                )
                
                AddSourceButton(
                    icon: "photo.stack",
                    title: "Photos".localized,
                    action: { showingPhotoPicker = true }
                )
                
                AddSourceButton(
                    icon: "folder.fill",
                    title: "Files".localized,
                    action: { showingFilePicker = true }
                )
            }
            .padding(.horizontal, Spacing.lg)
        }
    }
    
    // MARK: - Search Bar
    @ViewBuilder
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)
            
            TextField("Search PDFs...".localized, text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textSecondary)
                }
            }
            
            Button(action: {
                withAnimation(AnimationStyle.smooth) {
                    showingSearch = false
                    searchText = ""
                }
            }) {
                Text("Cancel".localized)
                    .foregroundColor(.primaryBlue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.backgroundSecondary)
        .cornerRadius(10)
        .padding(.horizontal, Spacing.lg)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // MARK: - Folders Section
    @ViewBuilder
    private var foldersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Folders".localized)
                    .font(Typography.subheadline)
                    .foregroundColor(.textSecondary)
                Text("(\(sortedFolders.count))")
                    .font(Typography.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, Spacing.lg)
            
            if isGridView {
                foldersGridView
            } else {
                foldersListView
            }
        }
    }
    
    @ViewBuilder
    private var foldersGridView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Spacing.md) {
            ForEach(sortedFolders) { folder in
                FolderCard(
                    folder: folder,
                    libraryService: libraryService,
                    isSelectionMode: $isSelectionMode,
                    selectedFolders: $selectedFolders,
                    jiggleAnimation: $jiggleAnimation
                )
            }
        }
        .padding(.horizontal, Spacing.lg)
        .transition(.opacity)
    }
    
    @ViewBuilder
    private var foldersListView: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(sortedFolders) { folder in
                FolderListRow(
                    folder: folder,
                    libraryService: libraryService,
                    isSelectionMode: $isSelectionMode,
                    selectedFolders: $selectedFolders,
                    jiggleAnimation: $jiggleAnimation
                )
            }
        }
        .padding(.horizontal, Spacing.lg)
        .transition(.opacity)
    }
    
    // MARK: - PDFs Section
    @ViewBuilder
    private var pdfsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Other scanned".localized)
                    .font(Typography.subheadline)
                    .foregroundColor(.textSecondary)
                Text("(\(sortedPDFs.count))")
                    .font(Typography.caption)
                    .foregroundColor(.textSecondary)
                Spacer()
                Text(isGridView ? "Grid" : "List")
                    .font(Typography.caption)
                    .foregroundColor(.accentBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentBlue.opacity(0.1))
                    .cornerRadius(6)
            }
            .padding(.horizontal, Spacing.lg)
            
            if isGridView {
                pdfsGridView
            } else {
                pdfsListView
            }
        }
    }
    
    @ViewBuilder
    private var pdfsGridView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Spacing.md) {
            ForEach(sortedPDFs) { pdf in
                PDFThumbnailCard(
                    pdf: pdf,
                    libraryService: libraryService,
                    onTap: {
                        print("🔵 LibraryView (Grid): PDF tapped - \(pdf.name)")
                        // Verify file exists before opening
                        if FileManager.default.fileExists(atPath: pdf.url.path) {
                            print("   File exists, opening viewer")
                            selectedPDF = pdf
                        } else {
                            print("   File doesn't exist!")
                            HapticManager.error()
                            // Reload to remove missing file
                            libraryService.loadPDFFiles()
                        }
                    },
                    onDelete: {
                        pdfToDelete = pdf
                        showingDeleteAlert = true
                    },
                    isSelectionMode: $isSelectionMode,
                    selectedPDFs: $selectedPDFs,
                    jiggleAnimation: $jiggleAnimation
                )
            }
        }
        .padding(.horizontal, Spacing.lg)
        .transition(.opacity)
    }
    
    @ViewBuilder
    private var pdfsListView: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(sortedPDFs) { pdf in
                PDFListRowView(
                    pdf: pdf,
                    libraryService: libraryService,
                    onTap: {
                        print("🔵 LibraryView (List): PDF tapped - \(pdf.name)")
                        // Verify file exists before opening
                        if FileManager.default.fileExists(atPath: pdf.url.path) {
                            print("   File exists, opening viewer")
                            selectedPDF = pdf
                        } else {
                            print("   File doesn't exist!")
                            HapticManager.error()
                            // Reload to remove missing file
                            libraryService.loadPDFFiles()
                        }
                    },
                    onDelete: {
                        pdfToDelete = pdf
                        showingDeleteAlert = true
                    },
                    isSelectionMode: $isSelectionMode,
                    selectedPDFs: $selectedPDFs,
                    jiggleAnimation: $jiggleAnimation
                )
            }
        }
        .padding(.horizontal, Spacing.lg)
        .transition(.opacity)
    }
    
    // MARK: - Toolbar Content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                HapticManager.light()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isSelectionMode.toggle()
                    if !isSelectionMode {
                        selectedPDFs.removeAll()
                        selectedFolders.removeAll()
                        jiggleAnimation = false
                    } else {
                        jiggleAnimation = true
                        // Close search when entering selection mode
                        showingSearch = false
                        searchText = ""
                    }
                    exportSelectionState()
                }
            }) {
                Text(isSelectionMode ? "Cancel".localized : "Select".localized)
                    .foregroundColor(.primaryBlue)
            }
        }
    }
    
    // MARK: - Sheets
    @ViewBuilder
    private var sheets: some View {
        Color.clear
            .fullScreenCover(item: $selectedPDF) { pdf in
                PDFDocumentEditorContainer(
                    pdf: pdf,
                    initialIndex: 0
                ) {
                    if selectedPDF?.id == pdf.id {
                        selectedPDF = nil
                    }
                }
            }
            .fullScreenCover(isPresented: $showingScanner) {
                DocumentScannerView(
                    scannedImages: $scannedImages,
                    onClose: {
                        showingScanner = false
                    }
                )
            }
            .sheet(isPresented: $showingDocumentSourcePicker) {
                DocumentSourcePickerView(onImport: { images in
                    Task {
                        await createPDFFromImages(images)
                    }
                })
            }
            .photosPicker(
                isPresented: $showingPhotoPicker,
                selection: $selectedPhotos,
                maxSelectionCount: 20,
                matching: .images
            )
            .sheet(isPresented: $showingFilePicker) {
                DocumentPicker(onDocumentsPicked: { urls in
                    handlePickedDocuments(urls)
                })
            }
            .onChange(of: selectedPhotos) { oldValue, newValue in
                Task {
                    selectedImages.removeAll()
                    for item in newValue {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImages.append(image)
                        }
                    }
                    if !selectedImages.isEmpty {
                        await createPDFFromImages(selectedImages)
                    }
                    selectedPhotos.removeAll()
                }
            }
            .onChange(of: scannedImages) { oldValue, newValue in
                print("🔄 scannedImages changed: \(oldValue.count) -> \(newValue.count)")
                guard !newValue.isEmpty else { return }
                print("📸 Processing \(newValue.count) scanned images...")
                Task {
                    await createPDFFromImages(newValue)
                    scannedImages.removeAll()
                }
            }
            .alert("Delete PDF".localized, isPresented: $showingDeleteAlert) {
                Button("Cancel".localized, role: .cancel) { }
                Button("Delete".localized, role: .destructive) {
                    if let pdf = pdfToDelete {
                        libraryService.deletePDF(pdf)
                    }
                }
        } message: {
            Text("Are you sure you want to delete this PDF? This action cannot be undone.".localized)
        }
            .alert("New Folder".localized, isPresented: $showingCreateFolder) {
                TextField("Folder name".localized, text: $newFolderName)
                Button("Cancel".localized, role: .cancel) {
                    newFolderName = ""
                }
                Button("Create".localized) {
                    if !newFolderName.trimmingCharacters(in: .whitespaces).isEmpty {
                        HapticManager.success()
                        libraryService.createFolder(name: newFolderName)
                        newFolderName = ""
                    }
                }
            } message: {
                Text("Create a new folder".localized)
            }
            .sheet(isPresented: $showingTagsView) {
                TagsView(selectedPDFs: selectedPDFs, selectedFolders: selectedFolders)
            }
            .sheet(isPresented: $showingMergeView) {
                MergeView(selectedPDFs: selectedPDFs)
            }
    }
    
    // MARK: - Helper Functions
    private func exportSelectionState() {
        // propagate selection mode and counts
        isSelectionModeExternal = isSelectionMode
        selectedPDFCountExternal = selectedPDFs.count
        selectedFolderCountExternal = selectedFolders.count
        // wire actions
        onDeleteActionExternal = {
            for pdfId in selectedPDFs {
                if let pdf = libraryService.pdfFiles.first(where: { $0.id == pdfId }) {
                    libraryService.deletePDF(pdf)
                }
            }
            for folderId in selectedFolders {
                if let folder = libraryService.folders.first(where: { $0.id == folderId }) {
                    libraryService.deleteFolder(folder)
                }
            }
            selectedPDFs.removeAll()
            selectedFolders.removeAll()
            withAnimation {
                isSelectionMode = false
                jiggleAnimation = false
            }
        }
        onShareActionExternal = {
            // share to be implemented later
        }
        onTagActionExternal = {
            showTagsView()
        }
        onMergeActionExternal = {
            showMergeView()
        }
    }
    private func createPDFFromImages(_ images: [UIImage]) async {
        guard !images.isEmpty else { return }
        
        let pdfGenerator = PDFGeneratorService()
        do {
            let pdfURL = try await pdfGenerator.generatePDF(from: images)
            
            // Copy to library
            await MainActor.run {
                libraryService.importPDF(from: pdfURL)
                HapticManager.success()
            }
        } catch {
            print("Failed to create PDF from images: \(error)")
            HapticManager.error()
        }
    }
    
    private func handlePickedDocuments(_ urls: [URL]) {
        for url in urls {
            // Check if it's a PDF
            if url.pathExtension.lowercased() == "pdf" {
                libraryService.importPDF(from: url)
            }
        }
        if !urls.isEmpty {
            HapticManager.success()
        }
    }
    
    private func showTagsView() {
        HapticManager.light()
        showingTagsView = true
    }
    
    private func showMergeView() {
        HapticManager.light()
        showingMergeView = true
    }
}

// MARK: - Document Editor Container
private struct PDFDocumentEditorContainer: View {
    let pdf: PDFFile
    let initialIndex: Int
    let onClose: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var images: [UIImage] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var didNotifyClose = false
    
    var body: some View {
        ZStack {
            Color.backgroundSecondary
                .ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Preparing document...".localized)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            } else if let errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button("Close".localized) {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                DocumentEditorView(
                    images: $images,
                    initialIndex: min(initialIndex, max(images.count - 1, 0)),
                    title: "Editör"
                )
            }
        }
        .onAppear {
            guard images.isEmpty && errorMessage == nil else { return }
            prepareImages()
        }
        .onDisappear {
            if !didNotifyClose {
                didNotifyClose = true
                onClose()
            }
        }
    }
    
    private func prepareImages() {
        guard FileManager.default.fileExists(atPath: pdf.url.path) else {
            errorMessage = "File Not Found".localized
            isLoading = false
            return
        }
        
        isLoading = true
        
        Task.detached(priority: .userInitiated) {
            do {
                let rendered = try renderImages(from: pdf.url)
                await MainActor.run {
                    self.images = rendered
                    self.isLoading = false
                    if rendered.isEmpty {
                        self.errorMessage = "This document has no pages.".localized
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func renderImages(from url: URL) throws -> [UIImage] {
        guard let document = PDFKit.PDFDocument(url: url) else {
            throw NSError(
                domain: "PDFDocumentEditor",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to open PDF.".localized]
            )
        }
        
        var rendered: [UIImage] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index),
                  let image = render(page: page) else { continue }
            rendered.append(image)
        }
        return rendered
    }
    
    private func render(page: PDFKit.PDFPage) -> UIImage? {
        let mediaBox = page.bounds(for: .mediaBox)
        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.scale = UIScreen.main.scale
        rendererFormat.opaque = true
        
        let renderer = UIGraphicsImageRenderer(size: mediaBox.size, format: rendererFormat)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: mediaBox.size))
            context.cgContext.translateBy(x: 0, y: mediaBox.size.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            page.draw(with: .mediaBox, to: context.cgContext)
        }
    }
}

// MARK: - Folder Card
struct FolderCard: View {
    let folder: Folder
    let libraryService: PDFLibraryService
    @Binding var isSelectionMode: Bool
    @Binding var selectedFolders: Set<UUID>
    @Binding var jiggleAnimation: Bool
    @State private var showingDeleteAlert = false
    @State private var showingFolderDetail = false
    
    var isSelected: Bool {
        selectedFolders.contains(folder.id)
    }
    
    var body: some View {
        ZStack {
            // Background card with shadow
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .aspectRatio(1.0, contentMode: .fit)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.primaryBlue : Color.clear, lineWidth: 3)
                )
            
            // Content
            VStack(spacing: 0) {
                // Folder icon at top
                Spacer()
                
                HStack {
                    Spacer()
                    Image(systemName: "folder.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.accentBlue)
                    Spacer()
                }
                
                Spacer()
                
                // Folder name and document count at bottom
                VStack(alignment: .center, spacing: 2) {
                    Text(folder.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                    
                    Text("\(folder.documentCount) documents".localized)
                        .font(.system(size: 11))
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            }
            
            // More button or selection indicator in top-right corner
            VStack {
                HStack(spacing: 0) {
                    Spacer()
                    if isSelectionMode {
                        // Selection checkmark
                        ZStack {
                            Circle()
                                .fill(isSelected ? Color.primaryBlue : Color.white)
                                .frame(width: 24, height: 24)
                            
                            Circle()
                                .stroke(isSelected ? Color.primaryBlue : Color.gray.opacity(0.3), lineWidth: 2)
                                .frame(width: 24, height: 24)
                            
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 12, weight: .bold))
                            }
                        }
                        .allowsHitTesting(false)
                    } else {
                        Menu {
                            Button(action: {
                                // Open folder
                            }) {
                                Label("Open".localized, systemImage: "folder")
                            }
                            
                            Button(action: {
                                // Rename folder
                            }) {
                                Label("Rename".localized, systemImage: "pencil")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: {
                                showingDeleteAlert = true
                            }) {
                                Label("Delete".localized, systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.textSecondary)
                                .font(.system(size: 16, weight: .semibold))
                                .rotationEffect(.degrees(90))
                                .frame(width: 32, height: 32)
                                .contentShape(Circle())
                        }
                    }
                }
                .padding(.trailing, 4)
                Spacer()
            }
            .padding(.top, 6)
            .zIndex(10)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            HapticManager.light()
            if isSelectionMode {
                if isSelected {
                    selectedFolders.remove(folder.id)
                } else {
                    selectedFolders.insert(folder.id)
                }
            } else {
                showingFolderDetail = true
            }
        }
        .modifier(JiggleEffect(isJiggling: jiggleAnimation))
        .alert("Delete Folder".localized, isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                libraryService.deleteFolder(folder)
            }
        } message: {
            Text("Are you sure you want to delete this folder?".localized)
        }
        .fullScreenCover(isPresented: $showingFolderDetail) {
            FolderDetailView(folder: folder, libraryService: libraryService)
        }
    }
}

// MARK: - Folder List Row
struct FolderListRow: View {
    let folder: Folder
    let libraryService: PDFLibraryService
    @Binding var isSelectionMode: Bool
    @Binding var selectedFolders: Set<UUID>
    @Binding var jiggleAnimation: Bool
    @State private var showingDeleteAlert = false
    @State private var showingFolderDetail = false
    
    var isSelected: Bool {
        selectedFolders.contains(folder.id)
    }
    
    var body: some View {
        Button(action: {
            HapticManager.light()
            if isSelectionMode {
                if isSelected {
                    selectedFolders.remove(folder.id)
                } else {
                    selectedFolders.insert(folder.id)
                }
            } else {
                showingFolderDetail = true
            }
        }) {
            HStack(spacing: Spacing.md) {
                // Folder icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentBlue.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "folder.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.accentBlue)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(folder.name)
                        .font(Typography.subheadline)
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    
                    Text("\(folder.documentCount) documents".localized)
                        .font(Typography.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // More button or selection indicator
                if isSelectionMode {
                    // Selection checkmark
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.primaryBlue : Color.white)
                            .frame(width: 24, height: 24)
                        
                        Circle()
                            .stroke(isSelected ? Color.primaryBlue : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if isSelected {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                } else {
                    Menu {
                        Button(action: {
                            // Open folder
                        }) {
                            Label("Open".localized, systemImage: "folder")
                        }
                        
                        Button(action: {
                            // Rename folder
                        }) {
                            Label("Rename".localized, systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            showingDeleteAlert = true
                        }) {
                            Label("Delete".localized, systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.textSecondary)
                            .rotationEffect(.degrees(90))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Spacing.sm)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.primaryBlue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .modifier(JiggleEffect(isJiggling: jiggleAnimation))
        .alert("Delete Folder".localized, isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                libraryService.deleteFolder(folder)
            }
        } message: {
            Text("Are you sure you want to delete this folder?".localized)
        }
        .fullScreenCover(isPresented: $showingFolderDetail) {
            FolderDetailView(folder: folder, libraryService: libraryService)
        }
    }
}

// MARK: - Folder Detail View
struct FolderDetailView: View {
    let folder: Folder
    @ObservedObject var libraryService: PDFLibraryService
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPDF: PDFFile?
    @State private var showingDeleteAlert = false
    @State private var pdfToDelete: PDFFile?
    @State private var sortOrder = "Tarihe göre"
    @State private var showingScanner = false
    @State private var showingPhotoPicker = false
    @State private var showingFilePicker = false
    @State private var showingDocumentSourcePicker = false
    @State private var isGridView = true
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    
    let sortOptions = ["By Date".localized, "By Name".localized, "By Size".localized]
    
    // Get the current folder from libraryService to get real-time updates
    var currentFolder: Folder? {
        libraryService.folders.first(where: { $0.id == folder.id })
    }
    
    var folderPDFs: [PDFFile] {
        // Get all PDFs that are in this folder (using current folder from service)
        guard let currentFolder = currentFolder else {
            print("⚠️ FolderDetailView: currentFolder is nil for folder '\(folder.name)'")
            return []
        }
        
        print("\n📁 FolderDetailView: Loading PDFs for folder '\(currentFolder.name)'")
        print("   Folder ID: \(currentFolder.id)")
        print("   PDF URLs count: \(currentFolder.pdfFileURLs.count)")
        
        // Print Documents directory path
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        print("   Documents Directory: \(documentsDir.path)")
        
        let pdfs = currentFolder.pdfFileURLs.compactMap { url -> PDFFile? in
            print("\n   🔍 Checking: \(url.lastPathComponent)")
            print("      Full path: \(url.path)")
            
            // Check if file exists
            let fileExists = FileManager.default.fileExists(atPath: url.path)
            print("      File exists: \(fileExists)")
            
            guard fileExists else {
                print("      ❌ File doesn't exist!")
                
                // Try to find the file in documents directory
                let expectedURL = documentsDir.appendingPathComponent(url.lastPathComponent)
                let existsInDocs = FileManager.default.fileExists(atPath: expectedURL.path)
                print("      Checking in docs dir: \(existsInDocs)")
                if existsInDocs {
                    print("      ⚠️ Found at: \(expectedURL.path)")
                }
                return nil
            }
            
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let creationDate = attributes[.creationDate] as? Date,
                  let fileSize = attributes[FileAttributeKey.size] as? Int64 else {
                print("      ❌ Can't read attributes!")
                return nil
            }
            
            print("      ✅ Valid PDF - Size: \(fileSize) bytes, Created: \(creationDate)")
            return PDFFile(
                url: url,
                name: url.lastPathComponent,
                createdAt: creationDate,
                fileSize: fileSize
            )
        }
        
        print("\n📊 FolderDetailView: Returning \(pdfs.count) valid PDFs out of \(currentFolder.pdfFileURLs.count) URLs\n")
        return pdfs
    }
    
    var sortedPDFs: [PDFFile] {
        switch sortOrder {
        case "By Name".localized:
            return folderPDFs.sorted { $0.name < $1.name }
        case "By Size".localized:
            return folderPDFs.sorted { $0.fileSize > $1.fileSize }
        default: // By Date
            return folderPDFs.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    var body: some View {
        mainNavigationView
            .fullScreenCover(item: $selectedPDF) { pdf in
                PDFDocumentEditorContainer(
                    pdf: pdf,
                    initialIndex: 0
                ) {
                    if selectedPDF?.id == pdf.id {
                        selectedPDF = nil
                    }
                }
            }
            .fullScreenCover(isPresented: $showingScanner) {
                scannerContent
            }
            .sheet(isPresented: $showingDocumentSourcePicker) {
                sourcePickerContent
            }
            .photosPicker(
                isPresented: $showingPhotoPicker,
                selection: $selectedPhotos,
                maxSelectionCount: 20,
                matching: .images
            )
            .sheet(isPresented: $showingFilePicker) {
                filePickerContent
            }
            .onChange(of: selectedPhotos, photosChangeHandler)
            .alert("Delete PDF".localized, isPresented: $showingDeleteAlert) {
                deleteAlertButtons
            } message: {
                deleteAlertMessage
            }
    }
    
    @ViewBuilder
    private var mainNavigationView: some View {
        NavigationView {
            contentView
                .navigationTitle(currentFolder?.name ?? folder.name)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    toolbarContent
                }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        ZStack {
            Color.backgroundPrimary
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    addSourceSection
                    sortAndViewToolbar
                    pdfContentSection
                }
                .padding(.top, Spacing.md)
            }
        }
    }
    
    @ViewBuilder
    private var sortAndViewToolbar: some View {
        HStack(spacing: Spacing.md) {
            sortMenu
            Spacer()
            viewToggleButton
        }
        .padding(.horizontal, Spacing.lg)
    }
    
    @ViewBuilder
    private var sortMenu: some View {
        Menu {
            ForEach(sortOptions, id: \.self) { option in
                Button(action: {
                    HapticManager.light()
                    sortOrder = option
                }) {
                    HStack {
                        Text(option)
                        if sortOrder == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(sortOrder)
                    .font(Typography.subheadline)
                    .foregroundColor(.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.backgroundSecondary)
            .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private var viewToggleButton: some View {
        Button(action: {
            HapticManager.light()
            withAnimation(.easeInOut(duration: 0.3)) {
                isGridView.toggle()
            }
        }) {
            Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                .foregroundColor(.textPrimary)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var pdfContentSection: some View {
        if !sortedPDFs.isEmpty {
            if isGridView {
                pdfsGridView
            } else {
                pdfsListView
            }
        } else {
            emptyFolderView
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primaryBlue)
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Select".localized) {
                // Selection mode will be implemented later
            }
            .foregroundColor(.primaryBlue)
        }
    }
    
    // MARK: - Add Source Section
    @ViewBuilder
    private var addSourceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Add from:".localized)
                .font(Typography.subheadline)
                .foregroundColor(.textSecondary)
                .padding(.horizontal, Spacing.lg)
            
            HStack(spacing: Spacing.md) {
                AddSourceButton(
                    icon: "iphone.gen3",
                    title: "iPhone".localized,
                    action: { showingDocumentSourcePicker = true }
                )
                
                AddSourceButton(
                    icon: "photo.stack",
                    title: "Photos".localized,
                    action: { showingPhotoPicker = true }
                )
                
                AddSourceButton(
                    icon: "folder.fill",
                    title: "Files".localized,
                    action: { showingFilePicker = true }
                )
            }
            .padding(.horizontal, Spacing.lg)
        }
    }
    
    // MARK: - PDFs Grid View
    @ViewBuilder
    private var pdfsGridView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Spacing.md) {
            ForEach(sortedPDFs) { pdf in
                PDFThumbnailCard(
                    pdf: pdf,
                    libraryService: libraryService,
                    onTap: {
                        print("🔵 FolderDetailView: PDF tapped - \(pdf.name)")
                        print("   File exists: \(FileManager.default.fileExists(atPath: pdf.url.path))")
                        print("   Setting selectedPDF")
                        selectedPDF = pdf
                    },
                    onDelete: {
                        pdfToDelete = pdf
                        showingDeleteAlert = true
                    },
                    isSelectionMode: .constant(false),
                    selectedPDFs: .constant([]),
                    jiggleAnimation: .constant(false)
                )
            }
        }
        .padding(.horizontal, Spacing.lg)
        .transition(.opacity)
    }
    
    // MARK: - PDFs List View
    @ViewBuilder
    private var pdfsListView: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(sortedPDFs) { pdf in
                PDFListRowView(
                    pdf: pdf,
                    libraryService: libraryService,
                    onTap: {
                        print("🔵 FolderDetailView: PDF tapped (list) - \(pdf.name)")
                        print("   File exists: \(FileManager.default.fileExists(atPath: pdf.url.path))")
                        print("   Setting selectedPDF")
                        selectedPDF = pdf
                    },
                    onDelete: {
                        pdfToDelete = pdf
                        showingDeleteAlert = true
                    },
                    isSelectionMode: .constant(false),
                    selectedPDFs: .constant([]),
                    jiggleAnimation: .constant(false)
                )
            }
        }
        .padding(.horizontal, Spacing.lg)
        .transition(.opacity)
    }
    
    // MARK: - Empty Folder View
    @ViewBuilder
    private var emptyFolderView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "folder")
                .font(.system(size: 70))
                .foregroundColor(.textSecondary)
            
            VStack(spacing: Spacing.sm) {
                Text("Empty Folder".localized)
                    .font(Typography.title)
                    .foregroundColor(.textPrimary)
                
                Text("Use the buttons above to add documents".localized)
                    .font(Typography.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Helper Functions
    private func createPDFFromImages(_ images: [UIImage]) async {
        guard !images.isEmpty else { return }
        
        let pdfGenerator = PDFGeneratorService()
        do {
            let pdfURL = try await pdfGenerator.generatePDF(from: images)
            
            await MainActor.run {
                print("📥 Created PDF at: \(pdfURL.path)")
                
                // Import PDF
                libraryService.importPDF(from: pdfURL)
                
                // Wait a bit for the file system to sync
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Get the imported URL from documents directory
                    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let importedURL = documentsDir.appendingPathComponent(pdfURL.lastPathComponent)
                    
                    print("📝 Imported PDF URL: \(importedURL.path)")
                    
                    // Add to current folder if available, otherwise it goes to main library
                    if let currentFolder = self.currentFolder {
                        print("📁 Adding to folder: \(currentFolder.name)")
                        if let folderIndex = self.libraryService.folders.firstIndex(where: { $0.id == currentFolder.id }) {
                            if !self.libraryService.folders[folderIndex].pdfFileURLs.contains(importedURL) {
                                self.libraryService.folders[folderIndex].pdfFileURLs.append(importedURL)
                                self.libraryService.saveFolders()
                                print("✅ PDF added to folder successfully!")
                            }
                        }
                    } else {
                        print("📁 PDF added to main library")
                    }
                    
                    HapticManager.success()
                }
            }
        } catch {
            print("Failed to create PDF from images: \(error)")
            HapticManager.error()
        }
    }
    
    private func handlePickedDocuments(_ urls: [URL]) {
        guard let currentFolder = currentFolder else { return }
        
        for url in urls {
            if url.pathExtension.lowercased() == "pdf" {
                print("📥 Importing PDF: \(url.lastPathComponent)")
                
                libraryService.importPDF(from: url)
                
                // Wait a bit for the file system to sync
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Get the imported URL from documents directory
                    let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let importedURL = documentsDir.appendingPathComponent(url.lastPathComponent)
                    
                    print("📝 Imported PDF URL: \(importedURL.path)")
                    print("📁 Adding to folder: \(currentFolder.name)")
                    
                    // Add the URL directly to the folder
                    if let folderIndex = self.libraryService.folders.firstIndex(where: { $0.id == currentFolder.id }) {
                        if !self.libraryService.folders[folderIndex].pdfFileURLs.contains(importedURL) {
                            self.libraryService.folders[folderIndex].pdfFileURLs.append(importedURL)
                            self.libraryService.saveFolders()
                            print("✅ PDF added to folder successfully!")
                        }
                    }
                }
            }
        }
        
        if !urls.isEmpty {
            // Delay haptic feedback slightly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                HapticManager.success()
            }
        }
    }
    
    @ViewBuilder
    private var scannerContent: some View {
        DocumentScannerView(
            scannedImages: $selectedImages,
            onClose: {
                showingScanner = false
            }
        )
    }
    
    @ViewBuilder
    private var sourcePickerContent: some View {
        DocumentSourcePickerView(onImport: { images in
            Task {
                await createPDFFromImages(images)
            }
        })
    }
    
    @ViewBuilder
    private var filePickerContent: some View {
        DocumentPicker(onDocumentsPicked: { urls in
            handlePickedDocuments(urls)
        })
    }
    
    @ViewBuilder
    private var deleteAlertButtons: some View {
        Button("Cancel".localized, role: .cancel) { }
        Button("Delete".localized, role: .destructive) {
            if let pdf = pdfToDelete, let currentFolder = currentFolder {
                libraryService.removePDFFromFolder(pdf, folder: currentFolder)
            }
        }
    }
    
    private var deleteAlertMessage: some View {
        Text("Are you sure you want to remove this PDF from the folder?".localized)
    }
    
    private func photosChangeHandler(_ oldValue: [PhotosPickerItem], _ newValue: [PhotosPickerItem]) {
        Task {
            selectedImages.removeAll()
            for item in newValue {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImages.append(image)
                }
            }
            if !selectedImages.isEmpty {
                await createPDFFromImages(selectedImages)
            }
            selectedPhotos.removeAll()
        }
    }
}

// MARK: - Add Source Button
struct AddSourceButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            ZStack {
                // Background card with shadow
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .frame(height: 110)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                
                // Content
                VStack(spacing: 8) {
                    Spacer()
                    
                    // Main icon
                    Image(systemName: icon)
                        .font(.system(size: 38))
                        .foregroundColor(.accentBlue)
                    
                    // Title
                    Text(title)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                }
                
                // Plus button in top-right corner
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textPrimary)
                            .frame(width: 24, height: 24)
                            .background(
                                Circle()
                                    .fill(Color.backgroundSecondary)
                            )
                    }
                    Spacer()
                }
                .padding(10)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - PDF List Row View
struct PDFListRowView: View {
    let pdf: PDFFile
    let libraryService: PDFLibraryService
    let onTap: () -> Void
    let onDelete: () -> Void
    @Binding var isSelectionMode: Bool
    @Binding var selectedPDFs: Set<UUID>
    @Binding var jiggleAnimation: Bool
    
    @State private var thumbnail: UIImage?
    @State private var isLoadingThumbnail = true
    @State private var showingActionSheet = false
    
    var isSelected: Bool {
        selectedPDFs.contains(pdf.id)
    }
    
    var body: some View {
        HStack(spacing: Spacing.md) {
                // Thumbnail and Info - Tappable area
                HStack(spacing: Spacing.md) {
                    // Thumbnail
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.backgroundSecondary)
                            .frame(width: 60, height: 80)
                        
                        if isLoadingThumbnail {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else if let thumbnail = thumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 60, height: 80)
                                .cornerRadius(8)
                                .clipped()
                        } else {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.accentBlue)
                        }
                    }
                    .frame(width: 60, height: 80)
                    
                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pdf.displayName)
                            .font(Typography.subheadline)
                            .foregroundColor(.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: Spacing.xs) {
                            Text(pdf.dateFormatted)
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                            
                            Text("•")
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                            
                            Text(pdf.fileSizeFormatted)
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                            
                            Text("•")
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                            
                            Text("\(libraryService.getPageCount(for: pdf)) pages".localized)
                                .font(Typography.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    print("🟡 PDFListRowView: onTapGesture triggered for \(pdf.name)")
                    print("   isSelectionMode: \(isSelectionMode)")
                    HapticManager.light()
                    if isSelectionMode {
                        if isSelected {
                            selectedPDFs.remove(pdf.id)
                        } else {
                            selectedPDFs.insert(pdf.id)
                        }
                    } else {
                        print("   Calling onTap()")
                        onTap()
                    }
                }
                
                // More button or selection indicator
                if isSelectionMode {
                    // Selection checkmark
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.primaryBlue : Color.white)
                            .frame(width: 24, height: 24)
                        
                        Circle()
                            .stroke(isSelected ? Color.primaryBlue : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if isSelected {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .allowsHitTesting(false)
                    .frame(width: 32, height: 32)
                } else {
                    Button(action: {
                        HapticManager.light()
                        showingActionSheet = true
                    }) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.textSecondary)
                            .rotationEffect(.degrees(90))
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(width: 32, height: 32)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.sm)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.primaryBlue : Color.clear, lineWidth: 2)
            )
        .modifier(JiggleEffect(isJiggling: jiggleAnimation))
        .onAppear {
            loadThumbnail()
        }
        .sheet(isPresented: $showingActionSheet) {
            PDFActionSheet(
                pdf: pdf,
                thumbnail: thumbnail,
                libraryService: libraryService,
                onOpen: {
                    showingActionSheet = false
                    onTap()
                },
                onDelete: {
                    showingActionSheet = false
                    onDelete()
                }
            )
        }
    }
    
    private func loadThumbnail() {
        isLoadingThumbnail = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let thumbnail = libraryService.generateThumbnail(for: pdf)
            
            DispatchQueue.main.async {
                self.thumbnail = thumbnail
                self.isLoadingThumbnail = false
            }
        }
    }
}

// MARK: - PDF Thumbnail Card
struct PDFThumbnailCard: View {
    let pdf: PDFFile
    let libraryService: PDFLibraryService
    let onTap: () -> Void
    let onDelete: () -> Void
    @Binding var isSelectionMode: Bool
    @Binding var selectedPDFs: Set<UUID>
    @Binding var jiggleAnimation: Bool
    
    @State private var thumbnail: UIImage?
    @State private var isLoadingThumbnail = true
    @State private var showingActionSheet = false
    
    var isSelected: Bool {
        selectedPDFs.contains(pdf.id)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.cardBackground)
                    .frame(height: 140)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.primaryBlue : Color.clear, lineWidth: 3)
                    )
                
                if isLoadingThumbnail {
                    ProgressView()
                        .scaleEffect(0.7)
                } else if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 120)
                        .cornerRadius(8)
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.accentBlue)
                        Text("PDF")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                // Menu button or selection indicator - top right corner
                VStack {
                    HStack(spacing: 0) {
                        Spacer()
                        if isSelectionMode {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? Color.primaryBlue : Color.white)
                                    .frame(width: 24, height: 24)
                                
                                Circle()
                                    .stroke(isSelected ? Color.primaryBlue : Color.gray.opacity(0.3), lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .font(.system(size: 12, weight: .bold))
                                }
                            }
                            .allowsHitTesting(false)
                        } else {
                            Button(action: {
                                HapticManager.light()
                                showingActionSheet = true
                            }) {
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.textSecondary)
                                    .font(.system(size: 16, weight: .semibold))
                                    .rotationEffect(.degrees(90))
                                    .frame(width: 28, height: 28)
                                    .contentShape(Circle())
                            }
                        }
                    }
                    .padding(.trailing, -4)
                    Spacer()
                }
                .padding(.top, 2)
                .zIndex(100)
            }
            
            Text(pdf.displayName)
                .font(.caption2)
                .foregroundColor(.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 30)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            print("🟡 PDFThumbnailCard: onTapGesture triggered for \(pdf.name)")
            print("   isSelectionMode: \(isSelectionMode)")
            HapticManager.light()
            if isSelectionMode {
                if isSelected {
                    selectedPDFs.remove(pdf.id)
                } else {
                    selectedPDFs.insert(pdf.id)
                }
            } else {
                print("   Calling onTap()")
                onTap()
            }
        }
        .modifier(JiggleEffect(isJiggling: jiggleAnimation))
        .onAppear {
            loadThumbnail()
        }
        .sheet(isPresented: $showingActionSheet) {
            PDFActionSheet(
                pdf: pdf,
                thumbnail: thumbnail,
                libraryService: libraryService,
                onOpen: {
                    showingActionSheet = false
                    onTap()
                },
                onDelete: {
                    showingActionSheet = false
                    onDelete()
                }
            )
        }
    }
    
    private func loadThumbnail() {
        isLoadingThumbnail = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let thumbnail = libraryService.generateThumbnail(for: pdf)
            
            DispatchQueue.main.async {
                self.thumbnail = thumbnail
                self.isLoadingThumbnail = false
            }
        }
    }
}


struct EmptyLibraryView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "doc.text")
                .font(.system(size: 70))
                .foregroundColor(.textSecondary)
            
            VStack(spacing: Spacing.sm) {
                Text("No PDFs Yet".localized)
                    .font(Typography.title)
                    .foregroundColor(.textPrimary)
                
                Text("Scan a document to create your first PDF".localized)
                    .font(Typography.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Library Toolbar
struct LibraryToolbar: View {
    @Binding var sortOrder: String
    let sortOptions: [String]
    @Binding var showingSearch: Bool
    @Binding var showingCreateFolder: Bool
    @Binding var isGridView: Bool
    let pdfCount: Int
    @Binding var isSelectionMode: Bool
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Sort menu
            Menu {
                ForEach(sortOptions, id: \.self) { option in
                    Button(action: {
                        HapticManager.light()
                        sortOrder = option
                    }) {
                        HStack {
                            Text(option)
                            if sortOrder == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(sortOrder)
                        .font(Typography.subheadline)
                        .foregroundColor(.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.backgroundSecondary)
                .cornerRadius(8)
            }
            
            Spacer()
            
            if !isSelectionMode {
                // Search button
                Button(action: {
                    HapticManager.light()
                    withAnimation(AnimationStyle.smooth) {
                        showingSearch.toggle()
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.textPrimary)
                        .font(.system(size: 20))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                
                // Create folder button
                Button(action: {
                    HapticManager.medium()
                    showingCreateFolder = true
                }) {
                    Image(systemName: "folder.badge.plus")
                        .foregroundColor(.textPrimary)
                        .font(.system(size: 20))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                
                // View toggle button (Grid/List)
                Button(action: {
                    HapticManager.light()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isGridView.toggle()
                    }
                }) {
                    Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                        .foregroundColor(.textPrimary)
                        .font(.system(size: 20))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentsPicked: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .image], asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentsPicked: onDocumentsPicked)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDocumentsPicked: ([URL]) -> Void
        
        init(onDocumentsPicked: @escaping ([URL]) -> Void) {
            self.onDocumentsPicked = onDocumentsPicked
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onDocumentsPicked(urls)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // User cancelled
        }
    }
}

// MARK: - Jiggle Effect (Apple Style)
struct JiggleEffect: ViewModifier {
    let isJiggling: Bool
    @State private var rotation: Double = 0
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation), anchor: .center)
            .animation(
                isJiggling
                    ? Animation.linear(duration: 0.13)
                        .repeatForever(autoreverses: true)
                    : .spring(response: 0.25, dampingFraction: 0.7),
                value: rotation
            )
            .onAppear {
                if isJiggling {
                    startJiggling()
                }
            }
            .onChange(of: isJiggling) { oldValue, newValue in
                if newValue {
                    startJiggling()
                } else {
                    stopJiggling()
                }
            }
    }
    
    private func startJiggling() {
        // Random rotation between -1.5 and 1.5 degrees (Apple-style - sadece yatay sallanma)
        rotation = Double.random(in: -1.5...1.5)
    }
    
    private func stopJiggling() {
        rotation = 0
    }
}

// MARK: - Tags View
struct TagsView: View {
    let selectedPDFs: Set<UUID>
    let selectedFolders: Set<UUID>
    @Environment(\.dismiss) private var dismiss
    @State private var availableTags = ["Work".localized, "Personal".localized, "Important".localized, "Archive".localized, "Invoice".localized, "Contract".localized]
    @State private var selectedTags: Set<String> = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.lg) {
                Text("Add tags to selected items".localized)
                    .font(Typography.title2)
                    .foregroundColor(.textPrimary)
                    .padding(.top, Spacing.lg)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Spacing.md) {
                    ForEach(availableTags, id: \.self) { tag in
                        TagButton(
                            tag: tag,
                            isSelected: selectedTags.contains(tag),
                            onTap: {
                                if selectedTags.contains(tag) {
                                    selectedTags.remove(tag)
                                } else {
                                    selectedTags.insert(tag)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, Spacing.lg)
                
                Spacer()
                
                Button(action: {
                    // TODO: Apply tags to selected items
                    HapticManager.success()
                    dismiss()
                }) {
                    Text("Apply Tags".localized)
                        .font(Typography.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.primaryBlue)
                        .cornerRadius(CornerRadius.button)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
            .navigationTitle("Tags".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Tag Button
struct TagButton: View {
    let tag: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(tag)
                .font(Typography.subheadline)
                .foregroundColor(isSelected ? .white : .textPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.button)
                        .fill(isSelected ? Color.primaryBlue : Color.backgroundSecondary)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Merge View
struct MergeView: View {
    let selectedPDFs: Set<UUID>
    @Environment(\.dismiss) private var dismiss
    @State private var mergedFileName = "Merged PDF".localized
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.lg) {
                Text("Merge selected PDFs".localized)
                    .font(Typography.title2)
                    .foregroundColor(.textPrimary)
                    .padding(.top, Spacing.lg)
                
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("File Name".localized)
                        .font(Typography.subheadline)
                        .foregroundColor(.textPrimary)
                    
                    TextField("Merged PDF".localized, text: $mergedFileName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal, Spacing.lg)
                
                Spacer()
                
                Button(action: {
                    // TODO: Merge selected PDFs
                    HapticManager.success()
                    dismiss()
                }) {
                    Text("Merge PDFs".localized)
                        .font(Typography.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.primaryBlue)
                        .cornerRadius(CornerRadius.button)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
            .navigationTitle("Merge".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - PDF Action Sheet
struct PDFActionSheet: View {
    let pdf: PDFFile
    let thumbnail: UIImage?
    let libraryService: PDFLibraryService
    let onOpen: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingRenameAlert = false
    @State private var newName = ""
    @State private var showingShareSheet = false
    @State private var showingMoveSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            // PDF Preview and Info
            HStack(spacing: 12) {
                // Thumbnail - Sol
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 100)
                        .cornerRadius(6)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.backgroundSecondary)
                            .frame(width: 80, height: 100)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.accentBlue)
                            Text("PDF")
                                .font(.caption2)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                
                // Info - Sağ
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(pdf.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    // Details
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pdf.dateFormatted)
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                        
                        Text(pdf.fileSizeFormatted)
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                        
                        Text("\(libraryService.getPageCount(for: pdf)) sayfalar")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Actions
            VStack(spacing: 0) {
                ActionSheetButton(
                    icon: "square.and.arrow.up",
                    title: "Share".localized,
                    action: {
                        showingShareSheet = true
                    }
                )
                
                Divider()
                    .padding(.leading, 60)
                
                ActionSheetButton(
                    icon: "pencil",
                    title: "Rename".localized,
                    action: {
                        newName = pdf.displayName
                        showingRenameAlert = true
                    }
                )
                
                Divider()
                    .padding(.leading, 60)
                
                ActionSheetButton(
                    icon: "slider.horizontal.3",
                    title: "Edit".localized,
                    action: {
                        dismiss()
                        onOpen()
                    }
                )
                
                Divider()
                    .padding(.leading, 60)
                
                ActionSheetButton(
                    icon: "printer",
                    title: "Print".localized,
                    action: {
                        printPDF()
                    }
                )
                
                Divider()
                    .padding(.leading, 60)
                
                ActionSheetButton(
                    icon: "arrow.up.doc",
                    title: "Move to".localized,
                    action: {
                        showingMoveSheet = true
                    }
                )
                
                Divider()
                    .padding(.leading, 60)
                
                ActionSheetButton(
                    icon: "trash",
                    title: "Delete".localized,
                    isDestructive: true,
                    action: {
                        dismiss()
                        onDelete()
                    }
                )
            }
            
            Spacer()
        }
        .presentationDetents([.fraction(0.5)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.regularMaterial)
        .interactiveDismissDisabled(false)
        .alert("Rename".localized, isPresented: $showingRenameAlert) {
            TextField("File name".localized, text: $newName)
            Button("Cancel".localized, role: .cancel) {
                newName = ""
            }
            Button("Save".localized) {
                if !newName.trimmingCharacters(in: .whitespaces).isEmpty {
                    libraryService.renamePDF(pdf, newName: newName)
                    dismiss()
                }
            }
        } message: {
            Text("Enter a new name for the PDF file".localized)
        }
        .sheet(isPresented: $showingShareSheet) {
            ModernShareSheet(activityItems: [pdf.url]) {
                dismiss()
            }
        }
        .sheet(isPresented: $showingMoveSheet) {
            MoveTOFolderView(pdf: pdf, libraryService: libraryService) {
                dismiss()
            }
        }
    }
    
    private func printPDF() {
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = pdf.name
        
        printController.printInfo = printInfo
        printController.printingItem = pdf.url
        
        printController.present(animated: true) { _, completed, error in
            if completed {
                HapticManager.success()
                dismiss()
            } else if let error = error {
                print("Print error: \(error)")
                HapticManager.error()
            }
        }
    }
}

// MARK: - Move To Folder View
struct MoveTOFolderView: View {
    let pdf: PDFFile
    let libraryService: PDFLibraryService
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFolder: Folder?
    
    var body: some View {
        NavigationView {
            List {
                if libraryService.folders.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.textSecondary)
                        
                        Text("No folders yet".localized)
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        Text("Create a folder first".localized)
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    ForEach(libraryService.folders) { folder in
                        Button(action: {
                            HapticManager.light()
                            selectedFolder = folder
                        }) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.accentBlue)
                                    .font(.system(size: 24))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(folder.name)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.textPrimary)
                                    
                                    Text("\(folder.documentCount) documents".localized)
                                        .font(.system(size: 13))
                                        .foregroundColor(.textSecondary)
                                }
                                
                                Spacer()
                                
                                // Checkmark if selected
                                if selectedFolder?.id == folder.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.primaryBlue)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(
                            selectedFolder?.id == folder.id
                                ? Color.primaryBlue.opacity(0.1)
                                : Color.clear
                        )
                    }
                }
            }
            .navigationTitle("Select Folder".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done".localized) {
                        if let selectedFolder = selectedFolder {
                            libraryService.addPDFToFolder(pdf, folder: selectedFolder)
                            HapticManager.success()
                            onComplete()
                        }
                    }
                    .disabled(selectedFolder == nil)
                    .foregroundColor(selectedFolder == nil ? .gray : .primaryBlue)
                }
            }
        }
    }
}

// MARK: - Action Sheet Button
struct ActionSheetButton: View {
    let icon: String
    let title: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isDestructive ? .red : .textPrimary)
                    .frame(width: 26)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(isDestructive ? .red : .textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }
}

