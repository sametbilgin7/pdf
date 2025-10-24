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
    
    private var filteredFiles: [FileItem] {
        sampleFiles.filter { file in
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
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                backgroundGradient
                
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    
                    if showingSearch {
                        searchBar
                    }
                    
                    categoryChips
                    
                    filesList
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120)
                
                floatingButton
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingCreationSheet) {
            FileCreationSheet()
                .presentationDetents([.height(360), .medium])
                .presentationDragIndicator(.visible)
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white,
                Color(red: 0.97, green: 0.98, blue: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(Date.now.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black.opacity(0.8))
                
                Spacer()
                
                HStack(spacing: 12) {
                    headerButton(
                        systemIcon: "magnifyingglass",
                        action: { withAnimation(.spring()) { showingSearch.toggle() } }
                    )
                    
                    headerButton(
                        systemIcon: "ellipsis",
                        action: { /* TODO: add actions */ }
                    )
                }
            }
            
            Text("Files".localized)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.black)
        }
    }
    
    private func headerButton(systemIcon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemIcon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
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
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
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
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(selectedCategory == category ? .white : Color.black.opacity(0.7))
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(selectedCategory == category ? Color(red: 0.45, green: 0.13, blue: 0.96) : Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(selectedCategory == category ? Color.clear : Color.black.opacity(0.08), lineWidth: 1)
                                    )
                                    .shadow(
                                        color: selectedCategory == category ? Color.purple.opacity(0.35) : Color.clear,
                                        radius: selectedCategory == category ? 12 : 0,
                                        x: 0,
                                        y: selectedCategory == category ? 10 : 0
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
    
    private var filesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredFiles) { file in
                    FileRowCard(file: file)
                }
            }
            .padding(.bottom, 40)
        }
    }
    
    private var floatingButton: some View {
        Button(action: { showingCreationSheet = true }) {
            Image(systemName: "plus")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(Color(red: 0.45, green: 0.13, blue: 0.96))
                .clipShape(Circle())
                .shadow(color: Color.purple.opacity(0.4), radius: 18, x: 0, y: 12)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 24)
        .padding(.bottom, 40)
    }
    
    // MARK: - Sample Data
    private var sampleFiles: [FileItem] {
        [
            FileItem(name: "FormFill", type: .pdf, size: "131.0 KB", date: Date(), isFavorite: true, isRecent: true, preview: "formfill_preview"),
            FileItem(name: "file", type: .pdf, size: "1.1 MB", date: Date().addingTimeInterval(-3600), isFavorite: false, isRecent: true, preview: "blackdoc_preview"),
            FileItem(name: "BrandAssets", type: .image, size: "8.4 MB", date: Date().addingTimeInterval(-7200), isFavorite: false, isRecent: false, preview: nil),
            FileItem(name: "Quarterly_Report", type: .xls, size: "2.5 MB", date: Date().addingTimeInterval(-5400), isFavorite: false, isRecent: true, preview: nil),
            FileItem(name: "MeetingNotes", type: .text, size: "24 KB", date: Date().addingTimeInterval(-9600), isFavorite: true, isRecent: false, preview: nil),
            FileItem(name: "PitchDeck", type: .ppt, size: "6.1 MB", date: Date().addingTimeInterval(-86000), isFavorite: false, isRecent: false, preview: nil),
            FileItem(name: "AudioDraft", type: .audio, size: "3.2 MB", date: Date().addingTimeInterval(-176000), isFavorite: false, isRecent: false, preview: nil)
        ]
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
    
    var body: some View {
        HStack(spacing: 16) {
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
            
            Button(action: { /* TODO: add per-file actions */ }) {
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
    }
}

// MARK: - Creation Sheet
struct FileCreationSheet: View {
    private let createItems: [CreationItem] = [
        CreationItem(title: "PDF", icon: "doc.richtext", tint: Color(red: 0.98, green: 0.38, blue: 0.38)),
        CreationItem(title: "Folder", icon: "folder.fill.badge.plus", tint: Color(red: 0.40, green: 0.64, blue: 0.99)),
        CreationItem(title: "Text File", icon: "square.and.pencil", tint: Color(red: 0.53, green: 0.79, blue: 0.53)),
        CreationItem(title: "Scan", icon: "doc.viewfinder", tint: Color(red: 0.39, green: 0.78, blue: 0.60))
    ]
    
    private let importItems: [CreationItem] = [
        CreationItem(title: "Files", icon: "folder", tint: Color(red: 0.27, green: 0.52, blue: 0.96)),
        CreationItem(title: "Photos", icon: "photo", tint: Color(red: 0.96, green: 0.54, blue: 0.66)),
        CreationItem(title: "Cloud", icon: "icloud.and.arrow.down", tint: Color(red: 0.48, green: 0.72, blue: 0.99))
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .frame(maxWidth: .infinity)
            
            section(title: "Create New".localized, gridItems: createItems, columns: 4)
            
            section(title: "Import From".localized, gridItems: importItems, columns: 3)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
        .background(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(Color.white)
        )
    }
    
    private func section(title: String, gridItems: [CreationItem], columns: Int) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: columns), spacing: 16) {
                ForEach(gridItems) { item in
                    VStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(item.tint.opacity(0.18))
                                .frame(width: 72, height: 72)
                            
                            Image(systemName: item.icon)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(item.tint)
                        }
                        
                        Text(item.title.localized)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private struct CreationItem: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let tint: Color
    }
}

#Preview {
    FilesView()
}
