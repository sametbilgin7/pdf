//
//  BookView.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI

struct BookView: View {
    @StateObject private var bookService = BookScanningService()
    @State private var showingNewProject = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingPDFPreview = false
    @State private var generatedPDFURL: URL?
    @State private var showingPageEditor = false
    @State private var selectedPage: BookPage?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if let project = bookService.currentProject {
                    // Show current project
                    CurrentProjectView(
                        project: project,
                        bookService: bookService,
                        onAddPage: {
                            // Add page functionality will be handled by camera
                        },
                        onEditPage: { page in
                            selectedPage = page
                            showingPageEditor = true
                        },
                        onGeneratePDF: {
                            generatePDF(from: project)
                        },
                        onNewProject: {
                            bookService.clearCurrentProject()
                        }
                    )
                } else {
                    // Show project selection
                    ProjectSelectionView(
                        onNewProject: {
                            showingNewProject = true
                        },
                        onLoadProject: { project in
                            bookService.currentProject = project
                        }
                    )
                }
            }
            .navigationTitle("Kitap Tarayıcı")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingNewProject) {
            NewProjectView { title, author in
                let project = bookService.createNewProject(title: title, author: author)
                bookService.currentProject = project
                showingNewProject = false
            }
        }
        .sheet(isPresented: $showingPageEditor) {
            if let page = selectedPage {
                PageEditorView(
                    page: page,
                    onSave: { updatedPage in
                        // Update page in project
                        showingPageEditor = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let pdfURL = generatedPDFURL {
                PDFPreviewView(pdfURL: pdfURL, fileName: "Kitap")
            }
        }
        .alert("Book Scanner".localized, isPresented: $showingAlert) {
            Button("Tamam") { }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: bookService.errorMessage) { errorMessage in
            if let error = errorMessage {
                alertMessage = error
                showingAlert = true
            }
        }
    }
    
    private func generatePDF(from project: BookProject) {
        Task {
            do {
                let pdfURL = try await bookService.generatePDF(from: project)
                
                await MainActor.run {
                    generatedPDFURL = pdfURL
                    showingPDFPreview = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Project Selection View
struct ProjectSelectionView: View {
    let onNewProject: () -> Void
    let onLoadProject: (BookProject) -> Void
    
    @State private var savedProjects: [BookProject] = []
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "book.closed")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Kitap Tarayıcı")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Kitap sayfalarını tarayın ve PDF oluşturun")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)
            
            // New project button
            Button(action: onNewProject) {
                VStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    
                    Text("Yeni Proje")
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
            .padding(.horizontal, 32)
            
            // Saved projects
            if !savedProjects.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Kayıtlı Projeler")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 32)
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(savedProjects, id: \.id) { project in
                                ProjectCardView(project: project) {
                                    onLoadProject(project)
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Current Project View
struct CurrentProjectView: View {
    let project: BookProject
    let bookService: BookScanningService
    let onAddPage: () -> Void
    let onEditPage: (BookPage) -> Void
    let onGeneratePDF: () -> Void
    let onNewProject: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Project info
                VStack(alignment: .leading, spacing: 12) {
                    Text(project.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let author = project.author {
                        Text("Yazar: \(author)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Sayfa Sayısı: \(project.pageCount)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Oluşturulma: \(project.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                
                // Pages grid
                if !project.pages.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sayfalar")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                            ForEach(project.pages.sorted { $0.pageNumber < $1.pageNumber }, id: \.id) { page in
                                PageThumbnailView(page: page) {
                                    onEditPage(page)
                                }
                            }
                        }
                    }
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    if project.pages.isEmpty {
                        Button("İlk Sayfayı Ekle") {
                            onAddPage()
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                    } else {
                        HStack(spacing: 12) {
                            Button("Sayfa Ekle") {
                                onAddPage()
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
                            
                            Button("PDF Oluştur") {
                                onGeneratePDF()
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                    }
                    
                    Button("Yeni Proje") {
                        onNewProject()
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange, lineWidth: 2)
                            .background(Color.orange.opacity(0.1))
                    )
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }
}

// MARK: - Project Card View
struct ProjectCardView: View {
    let project: BookProject
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(project.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    if let author = project.author {
                        Text("Yazar: \(author)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(project.pageCount) sayfa")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
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
}

// MARK: - Page Thumbnail View
struct PageThumbnailView: View {
    let page: BookPage
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(uiImage: page.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 140)
                    .clipped()
                    .cornerRadius(8)
                
                Text("Sayfa \(page.pageNumber)")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - New Project View
struct NewProjectView: View {
    let onSave: (String, String?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var author = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Proje Başlığı")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Kitap adını girin", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Yazar (İsteğe Bağlı)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Yazar adını girin", text: $author)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Yeni Proje")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Oluştur") {
                        onSave(title, author.isEmpty ? nil : author)
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Page Editor View
struct PageEditorView: View {
    let page: BookPage
    let onSave: (BookPage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Image(uiImage: page.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Sayfa Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        onSave(page)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    BookView()
}
