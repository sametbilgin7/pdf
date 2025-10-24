//
//  FilesView.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI

struct FilesView: View {
    @State private var selectedCategory: FileCategory = .all
    @State private var showingSearch = false
    @State private var searchText = ""
    @State private var showingCreationSheet = false
    @State private var isListView = false
    @State private var sortAscending = true
    @State private var isSelectionMode = false
    @State private var selectedFileIDs: Set<UUID> = []
    @State private var files: [FileItem] = FileItem.sampleData
    
    private var filteredFiles: [FileItem] {
        files.filter { file in
            let matchesCategory: Bool = {
                switch selectedCategory {
                case .all: return true
                case .recent: return file.isRecent
                case .favorite: return file.isFavorite
                default:
                    return file.type == selectedCategory.associatedType
                }
            }()
            
            let matchesSearch = searchText.isEmpty ||
                file.name.localizedCaseInsensitiveContains(searchText)
            
            return matchesCategory && matchesSearch
        }
    }
    
    private var menuButtonLabel: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.white)
            .frame(width: 40, height: 40)
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
            .overlay(
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
            )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gray.opacity(0.08).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerSection
                    
                    if showingSearch {
                        searchBar
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)
                    }
                    
                    categoryChips
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    
                    filesList
                }
                
                floatingButton
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingCreationSheet) {
            FileCreationSheet()
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.visible)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Files".localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Spacer()
                
                HStack(spacing: 12) {
                    headerButton(
                        systemIcon: "magnifyingglass",
                        action: { withAnimation(.spring()) { showingSearch.toggle() } }
                    )
                    
                    Menu {
                        Button(action: { toggleSortOrder() }) {
                            Label("Sort".localized, systemImage: "arrow.up.arrow.down")
                        }
                        
                        Button(action: { toggleSelectionMode() }) {
                            Label("Select".localized, systemImage: "checkmark.circle")
                        }
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isListView.toggle()
                            }
                        }) {
                            Label(isListView ? "Grid".localized : "List".localized,
                                  systemImage: isListView ? "square.grid.2x2" : "list.bullet")
                        }
                    } label: {
                        menuButtonLabel
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
    }
    
    private func headerButton(systemIcon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemIcon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                )
        }
        .buttonStyle(.plain)
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search".localized, text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }
    
    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(FileCategory.allCases, id: \.self) { category in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selectedCategory = category
                        }
                    } label: {
                        Text(category.localized)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(selectedCategory == category ? .white : .black)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(selectedCategory == category ? Color.purple : Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.black.opacity(0.05), lineWidth: selectedCategory == category ? 0 : 1)
                                    )
                                    .shadow(color: Color.black.opacity(selectedCategory == category ? 0.15 : 0), radius: 8, x: 0, y: 4)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private let gridColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    
    private var filesList: some View {
        ScrollView {
            if isListView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredFiles) { file in
                        FileRowCard(
                            file: file,
                            isSelectionMode: isSelectionMode,
                            isSelected: selectedFileIDs.contains(file.id),
                            onTap: { handleFileTap(file) },
                            onOptionsTap: { /* TODO: file-specific actions */ }
                        )
                    }
                }
                .padding(.horizontal, 20)
            } else {
                LazyVGrid(columns: gridColumns, spacing: 20) {
                    ForEach(filteredFiles) { file in
                        FileGridCard(
                            file: file,
                            isSelectionMode: isSelectionMode,
                            isSelected: selectedFileIDs.contains(file.id),
                            onTap: { handleFileTap(file) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 40)
    }
    
    private var floatingButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { showingCreationSheet = true }) {
                    FloatingPlusButtonLabel()
                }
                .buttonStyle(.plain)
                .padding(.trailing, 24)
                .padding(.bottom, 32)
            }
        }
    }
    
    private func handleFileTap(_ file: FileItem) {
        if isSelectionMode {
            if selectedFileIDs.contains(file.id) {
                selectedFileIDs.remove(file.id)
            } else {
                selectedFileIDs.insert(file.id)
            }
        } else {
            // Placeholder for opening file preview
        }
    }
    
    private func toggleSortOrder() {
        sortAscending.toggle()
        withAnimation(.easeInOut(duration: 0.2)) {
            files.sort {
                if sortAscending {
                    return $0.name.localizedCompare($1.name) == .orderedAscending
                } else {
                    return $0.name.localizedCompare($1.name) == .orderedDescending
                }
            }
        }
    }
    
    private func toggleSelectionMode() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isSelectionMode.toggle()
            if !isSelectionMode {
                selectedFileIDs.removeAll()
            }
        }
    }
    
}

// MARK: - Category Model
enum FileCategory: String, CaseIterable {
    case all = "All"
    case recent = "Recent"
    case favorite = "Favorite"
    case pdf = "PDF"
    case image = "Image"
    case xls = "XLS"
    case text = "Text"
    case doc = "DOC"
    case html = "HTML"
    case tiff = "TIFF"
    case ppt = "PPT"
    case gif = "GIF"
    case zip = "ZIP"
    case audio = "Audio"
    case other = "Other"
    
    var localized: String {
        rawValue.localized
    }
    
    var associatedType: FileType {
        switch self {
        case .pdf: return .pdf
        case .image: return .image
        case .xls: return .xls
        case .text: return .text
        case .doc: return .doc
        case .html: return .html
        case .tiff: return .tiff
        case .ppt: return .ppt
        case .gif: return .gif
        case .zip: return .zip
        case .audio: return .audio
        case .other, .all, .recent, .favorite:
            return .other
        }
    }
}

// MARK: - File Model
struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let type: FileType
    let size: String
    let date: Date
    let isFavorite: Bool
    let isRecent: Bool
    let preview: String?
}

extension FileItem {
    static let sampleData: [FileItem] = [
        FileItem(name: "FormFill", type: .pdf, size: "131.0 KB", date: Date(), isFavorite: true, isRecent: true, preview: "formfill_preview"),
        FileItem(name: "file", type: .pdf, size: "1.1 MB", date: Date().addingTimeInterval(-3600), isFavorite: false, isRecent: true, preview: "blackdoc_preview"),
        FileItem(name: "BrandAssets", type: .image, size: "8.4 MB", date: Date().addingTimeInterval(-7200), isFavorite: false, isRecent: false, preview: nil),
        FileItem(name: "Quarterly_Report", type: .xls, size: "2.5 MB", date: Date().addingTimeInterval(-5400), isFavorite: false, isRecent: true, preview: nil),
        FileItem(name: "MeetingNotes", type: .text, size: "24 KB", date: Date().addingTimeInterval(-9600), isFavorite: true, isRecent: false, preview: nil),
        FileItem(name: "PitchDeck", type: .ppt, size: "6.1 MB", date: Date().addingTimeInterval(-86000), isFavorite: false, isRecent: false, preview: nil),
        FileItem(name: "AudioDraft", type: .audio, size: "3.2 MB", date: Date().addingTimeInterval(-176000), isFavorite: false, isRecent: false, preview: nil)
    ]
}

enum FileType: String, CaseIterable {
    case pdf, image, xls, text, doc, html, tiff, ppt, gif, zip, audio, other
    
    var icon: String {
        switch self {
        case .pdf: return "doc.richtext"
        case .image: return "photo.fill"
        case .xls: return "tablecells"
        case .text: return "text.alignleft"
        case .doc: return "doc.text.fill"
        case .html: return "curlybraces"
        case .tiff: return "doc.on.doc"
        case .ppt: return "chart.bar.doc.horizontal"
        case .gif: return "sparkles.rectangle.stack"
        case .zip: return "archivebox.fill"
        case .audio: return "waveform.circle.fill"
        case .other: return "questionmark.folder.fill"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .pdf: return .red
        case .image: return .blue
        case .xls: return .green
        case .text: return .purple
        case .doc: return .indigo
        case .html: return .orange
        case .tiff: return .mint
        case .ppt: return .pink
        case .gif: return .yellow
        case .zip: return .gray
        case .audio: return .teal
        case .other: return .brown
        }
    }
}

// MARK: - File Row Card
struct FileRowCard: View {
    let file: FileItem
    let isSelectionMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onOptionsTap: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            thumbnail
            
            VStack(alignment: .leading, spacing: 6) {
                Text(file.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Text("\(file.type.rawValue.uppercased()) • \(file.size)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: onOptionsTap) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .rotationEffect(.degrees(90))
                    .foregroundColor(.black.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.purple.opacity(0.08), radius: 20, x: 0, y: 12)
        )
        .overlay(alignment: .topLeading) {
            if isSelectionMode {
                SelectionIndicator(isSelected: isSelected)
                    .offset(x: 10, y: 10)
            }
        }
        .onTapGesture {
            onTap()
        }
    }
    
    private var thumbnail: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .frame(width: 76, height: 104)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)
            
            if let preview = file.preview, let image = UIImage(named: preview) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 68, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                Image(systemName: file.type.icon)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(file.type.accentColor)
            }
            
            Text(file.type.rawValue.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(file.type.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .offset(x: -6, y: -6)
        }
    }
}

struct FileGridCard: View {
    let file: FileItem
    let isSelectionMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white)
                    .frame(height: 140)
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
                    .overlay(thumbnailContent)
                
                if isSelectionMode {
                    SelectionIndicator(isSelected: isSelected)
                        .offset(x: -10, y: 10)
                }
            }
            
            VStack(spacing: 4) {
                Text(file.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Text("\(file.type.rawValue.uppercased()) • \(file.size)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .onTapGesture {
            onTap()
        }
    }
    
    private var thumbnailContent: some View {
        Group {
            if let preview = file.preview, let image = UIImage(named: preview) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .overlay(badgeOverlay)
            } else {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: file.type.icon)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(file.type.accentColor)
                    Spacer()
                }
                .overlay(badgeOverlay)
            }
        }
    }
    
    private var badgeOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Text(file.type.rawValue.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(file.type.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Spacer()
            }
        }
        .padding(8)
    }
}

private struct SelectionIndicator: View {
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.purple : Color.white)
                .frame(width: 26, height: 26)
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 2)
            
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: isSelected ? 0 : 1)
                .frame(width: 26, height: 26)
            
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

struct FloatingPlusButtonLabel: View {
    var body: some View {
        Image(systemName: "plus")
            .font(.system(size: 26, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 56, height: 56)
            .background(Color.purple)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
    }
}

// MARK: - Creation Sheet
struct FileCreationSheet: View {
    private struct CreationItem: Identifiable {
        enum SectionType { case create, importFrom }
        let id = UUID()
        let title: String
        let icon: String
        let background: Color
        let tint: Color
        let section: SectionType
    }
    
    private let items: [CreationItem] = [
        CreationItem(title: "PDF", icon: "doc.richtext", background: Color(red: 1.0, green: 0.92, blue: 0.92), tint: Color(red: 0.95, green: 0.35, blue: 0.35), section: .create),
        CreationItem(title: "Folder", icon: "folder.fill.badge.plus", background: Color(red: 0.92, green: 0.96, blue: 1.0), tint: Color(red: 0.30, green: 0.56, blue: 0.95), section: .create),
        CreationItem(title: "Text File", icon: "text.alignleft", background: Color(red: 0.92, green: 0.98, blue: 0.92), tint: Color(red: 0.28, green: 0.72, blue: 0.38), section: .create),
        CreationItem(title: "Scan", icon: "doc.viewfinder", background: Color(red: 0.92, green: 0.99, blue: 0.95), tint: Color(red: 0.23, green: 0.74, blue: 0.47), section: .create),
        CreationItem(title: "Files", icon: "folder.fill", background: Color(red: 0.93, green: 0.96, blue: 1.0), tint: Color(red: 0.35, green: 0.55, blue: 0.99), section: .importFrom),
        CreationItem(title: "Photos", icon: "photo.fill.on.rectangle.fill", background: Color(red: 1.0, green: 0.94, blue: 0.95), tint: Color(red: 0.97, green: 0.53, blue: 0.59), section: .importFrom),
        CreationItem(title: "Cloud", icon: "icloud.and.arrow.down.fill", background: Color(red: 0.93, green: 0.97, blue: 1.0), tint: Color(red: 0.33, green: 0.63, blue: 0.98), section: .importFrom)
    ]
    
    private var createItems: [CreationItem] {
        items.filter { $0.section == .create }
    }
    
    private var importItems: [CreationItem] {
        items.filter { $0.section == .importFrom }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 44, height: 5)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
            
            section(title: "Create New".localized, items: createItems)
            
            section(title: "Import From".localized, items: importItems)
            
            Spacer()
        }
        .padding(.horizontal, 28)
        .padding(.top, 16)
        .padding(.bottom, 40)
        .background(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color.white)
        )
    }
    
    private func section(title: String, items: [CreationItem]) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
            
            HStack(spacing: 16) {
                ForEach(items) { item in
                    VStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(item.background)
                            .frame(width: 72, height: 72)
                            .overlay(
                                Image(systemName: item.icon)
                                    .font(.system(size: 30, weight: .semibold))
                                    .foregroundColor(item.tint)
                            )
                        
                        Text(item.title.localized)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                    }
                    .frame(width: 72)
                }
            }
        }
    }
}

#Preview {
    FilesView()
}
