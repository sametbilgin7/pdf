//
//  DocumentSourcePickerView.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI
import PhotosUI

enum DocumentSourceTab {
    case documents
    case handwritten
    case photos
    case allPhotos
    
    var title: String {
        switch self {
        case .documents: return "Belgeler"
        case .handwritten: return "Elle yazılmış notlar"
        case .photos: return "Fotoğraflar"
        case .allPhotos: return "Tüm fotoğraflar"
        }
    }
}

struct DocumentSourcePickerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: DocumentSourceTab = .documents
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showingPhotoPicker = false
    
    let onImport: ([UIImage]) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.md) {
                        ForEach([DocumentSourceTab.documents, .handwritten, .photos, .allPhotos], id: \.self) { tab in
                            TabButton(
                                title: tab.title,
                                isSelected: selectedTab == tab,
                                action: {
                                    withAnimation(AnimationStyle.smooth) {
                                        selectedTab = tab
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }
                .padding(.vertical, Spacing.sm)
                .background(Color.backgroundPrimary)
                
                Divider()
                
                // Content based on selected tab
                TabContentView(
                    tab: selectedTab,
                    selectedImages: $selectedImages,
                    showingPhotoPicker: $showingPhotoPicker
                )
            }
            .navigationTitle("Select files".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundColor(.primaryBlue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("İçe Aktar") {
                        if !selectedImages.isEmpty {
                            onImport(selectedImages)
                            dismiss()
                        }
                    }
                    .foregroundColor(.primaryBlue)
                    .disabled(selectedImages.isEmpty)
                }
            }
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedPhotos,
            maxSelectionCount: 50,
            matching: .images
        )
        .onChange(of: selectedPhotos) { oldValue, newValue in
            Task {
                for item in newValue {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            selectedImages.append(image)
                        }
                    }
                }
                selectedPhotos.removeAll()
            }
        }
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.light()
            action()
        }) {
            VStack(spacing: 4) {
                Text(title)
                    .font(Typography.subheadline)
                    .foregroundColor(isSelected ? .primaryBlue : .textSecondary)
                
                if isSelected {
                    Rectangle()
                        .fill(Color.primaryBlue)
                        .frame(height: 2)
                        .cornerRadius(1)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tab Content View
struct TabContentView: View {
    let tab: DocumentSourceTab
    @Binding var selectedImages: [UIImage]
    @Binding var showingPhotoPicker: Bool
    
    var body: some View {
        Group {
            switch tab {
            case .documents:
                DocumentsGridView(selectedImages: $selectedImages)
            case .handwritten:
                HandwrittenNotesView(selectedImages: $selectedImages)
            case .photos:
                PhotosGridView(selectedImages: $selectedImages, showingPhotoPicker: $showingPhotoPicker)
            case .allPhotos:
                AllPhotosGridView(selectedImages: $selectedImages, showingPhotoPicker: $showingPhotoPicker)
            }
        }
    }
}

// MARK: - Documents Grid View
struct DocumentsGridView: View {
    @Binding var selectedImages: [UIImage]
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Add document button
                Button(action: {
                    // Open document scanner or camera
                }) {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.primaryBlue)
                        
                        Text("Belge Ekle")
                            .font(Typography.subheadline)
                            .foregroundColor(.textPrimary)
                        
                        Text("Kameradan tarayın veya\ndosyalardan seçin")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
                .buttonStyle(.plain)
                
                // Selected images grid
                if !selectedImages.isEmpty {
                    SelectedImagesGrid(selectedImages: $selectedImages)
                }
            }
            .padding(Spacing.lg)
        }
        .background(Color.backgroundSecondary)
    }
}

// MARK: - Handwritten Notes View
struct HandwrittenNotesView: View {
    @Binding var selectedImages: [UIImage]
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                Image(systemName: "pencil.and.scribble")
                    .font(.system(size: 50))
                    .foregroundColor(.textSecondary)
                
                Text("Elle yazılmış notlar")
                    .font(Typography.subheadline)
                    .foregroundColor(.textPrimary)
                
                Text("Bu özellik yakında eklenecek")
                    .font(Typography.caption)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 100)
        }
        .background(Color.backgroundSecondary)
    }
}

// MARK: - Photos Grid View
struct PhotosGridView: View {
    @Binding var selectedImages: [UIImage]
    @Binding var showingPhotoPicker: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Add photos button
                Button(action: {
                    showingPhotoPicker = true
                }) {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.primaryBlue)
                        
                        Text("Fotoğraf Ekle")
                            .font(Typography.subheadline)
                            .foregroundColor(.textPrimary)
                        
                        Text("Galeriden fotoğraf seçin")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
                .buttonStyle(.plain)
                
                // Selected images grid
                if !selectedImages.isEmpty {
                    SelectedImagesGrid(selectedImages: $selectedImages)
                }
            }
            .padding(Spacing.lg)
        }
        .background(Color.backgroundSecondary)
    }
}

// MARK: - All Photos Grid View
struct AllPhotosGridView: View {
    @Binding var selectedImages: [UIImage]
    @Binding var showingPhotoPicker: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Add photos button
                Button(action: {
                    showingPhotoPicker = true
                }) {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "photo.stack")
                            .font(.system(size: 50))
                            .foregroundColor(.primaryBlue)
                        
                        Text("Tüm Fotoğrafları Görüntüle")
                            .font(Typography.subheadline)
                            .foregroundColor(.textPrimary)
                        
                        Text("Galerinizdeki tüm fotoğraflar")
                            .font(Typography.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
                .buttonStyle(.plain)
                
                // Selected images grid
                if !selectedImages.isEmpty {
                    SelectedImagesGrid(selectedImages: $selectedImages)
                }
            }
            .padding(Spacing.lg)
        }
        .background(Color.backgroundSecondary)
    }
}

// MARK: - Selected Images Grid
struct SelectedImagesGrid: View {
    @Binding var selectedImages: [UIImage]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Selected Photos".localized)
                    .font(Typography.subheadline)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Text("\(selectedImages.count) \(selectedImages.count == 1 ? ("photo".localized) : ("photos".localized))")
                    .font(Typography.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, Spacing.sm)
            
            LazyVGrid(columns: columns, spacing: Spacing.md) {
                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 120)
                            .clipped()
                            .cornerRadius(8)
                        
                        // Remove button
                        Button(action: {
                            HapticManager.light()
                            selectedImages.remove(at: index)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                        .frame(width: 28, height: 28)
                                )
                        }
                        .padding(6)
                        
                        // Image number
                        VStack {
                            Spacer()
                            HStack {
                                Text("\(index + 1)")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.black.opacity(0.7))
                                    )
                                Spacer()
                            }
                        }
                        .padding(6)
                    }
                }
            }
        }
    }
}

#Preview {
    DocumentSourcePickerView(onImport: { _ in })
}

