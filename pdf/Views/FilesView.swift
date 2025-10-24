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
            colors: [
                Color(red: 0.97, green: 0.97, blue: 1.0),
                Color(red: 0.94, green: 0.96, blue: 1.0),
                Color.white
            ],
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
                    .foregroundColor(.black.opacity(0.7))
                
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
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
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
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
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
                                    .fill(selectedCategory == category ? Color.purple : Color.white)
                                    .shadow(
                                        color: selectedCategory == category
                                        ? Color.purple.opacity(0.35)
                                        : Color.black.opacity(0.04),
                                        radius: selectedCategory == category ? 12 : 6,
                                        x: 0,
                                        y: selectedCategory == category ? 10 : 3
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
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: Color.purple.opacity(0.35), radius: 16, x: 0, y: 12)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 24)
        .padding(.bottom, 40)
    }
    
    // MARK: - Sample Data
    private var sampleFiles: [FileItem] {
        [
            FileItem(name: "FormFill", type: .pdf, size: "131.0 KB", date: Date(), isFavorite: true, isRecent: true),
            FileItem(name: "Invoice-2025", type: .pdf, size: "1.1 MB", date: Date().addingTimeInterval(-3600), isFavorite: false, isRecent: true),
            FileItem(name: "BrandAssets", type: .image, size: "8.4 MB", date: Date().addingTimeInterval(-7200), isFavorite: false, isRecent: false),
            FileItem(name: "Quarterly_Report", type: .xls, size: "2.5 MB", date: Date().addingTimeInterval(-5400), isFavorite: false, isRecent: true),
            FileItem(name: "MeetingNotes", type: .text, size: "24 KB", date: Date().addingTimeInterval(-9600), isFavorite: true, isRecent: false),
            FileItem(name: "PitchDeck", type: .ppt, size: "6.1 MB", date: Date().addingTimeInterval(-86000), isFavorite: false, isRecent: false),
            FileItem(name: "AudioDraft", type: .audio, size: "3.2 MB", date: Date().addingTimeInterval(-176000), isFavorite: false, isRecent: false)
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
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 70, height: 88)
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 8)
                
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: file.type.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(file.type.accentColor)
                    Spacer()
                }
                .frame(width: 70, height: 88)
                
                Text(file.type.rawValue.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(file.type.accentColor)
                    .clipShape(Capsule())
                    .offset(x: -8, y: -8)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(file.name)
                    .font(.system(size: 17, weight: .semibold))
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
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
        )
    }
}

// MARK: - Creation Sheet
struct FileCreationSheet: View {
    private struct CreationItem: Identifiable {
        enum Kind {
            case createNew, importFrom
        }
        
        let id = UUID()
        let title: String
        let subtitle: String
        let icon: String
        let tint: Color
        let kind: Kind
    }
    
    private let createItems: [CreationItem] = [
        CreationItem(title: "PDF", subtitle: "Create PDF".localized, icon: "doc.richtext", tint: .red.opacity(0.85), kind: .createNew),
        CreationItem(title: "Folder", subtitle: "New Folder".localized, icon: "folder.fill.badge.plus", tint: .blue.opacity(0.85), kind: .createNew),
        CreationItem(title: "Text File", subtitle: "Write Notes".localized, icon: "square.and.pencil", tint: .green.opacity(0.8), kind: .createNew),
        CreationItem(title: "Scan", subtitle: "Scan Document".localized, icon: "doc.viewfinder", tint: .mint.opacity(0.8), kind: .createNew)
    ]
    
    private let importItems: [CreationItem] = [
        CreationItem(title: "Files", subtitle: "Import Files".localized, icon: "folder", tint: .blue, kind: .importFrom),
        CreationItem(title: "Photos", subtitle: "Import Photos".localized, icon: "photo", tint: .pink, kind: .importFrom),
        CreationItem(title: "Cloud", subtitle: "Import from Cloud".localized, icon: "icloud.and.arrow.down", tint: .cyan, kind: .importFrom)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .frame(maxWidth: .infinity)
            
            section(title: "Create New".localized, items: createItems)
            
            section(title: "Import From".localized, items: importItems)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white)
        )
    }
    
    private func section(title: String, items: [CreationItem]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                ForEach(items) { item in
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(item.tint.opacity(0.15))
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
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    )
                }
            }
        }
    }
}

#Preview {
    FilesView()
}
