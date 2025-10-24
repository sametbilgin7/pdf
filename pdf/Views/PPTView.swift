//
//  PPTView.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI

struct PPTView: View {
    @StateObject private var pptService = PPTCreationService()
    @State private var showingNewProject = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingPDFPreview = false
    @State private var generatedPDFURL: URL?
    @State private var showingSlideEditor = false
    @State private var selectedSlide: PPTSlide?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if let project = pptService.currentProject {
                    // Show current project
                    CurrentPPTProjectView(
                        project: project,
                        pptService: pptService,
                        onAddSlide: {
                            // Add slide functionality will be handled by camera
                        },
                        onEditSlide: { slide in
                            selectedSlide = slide
                            showingSlideEditor = true
                        },
                        onGeneratePPT: {
                            generatePPT(from: project)
                        },
                        onNewProject: {
                            pptService.clearCurrentProject()
                        }
                    )
                } else {
                    // Show project selection
                    PPTProjectSelectionView(
                        onNewProject: {
                            showingNewProject = true
                        },
                        onLoadProject: { project in
                            pptService.currentProject = project
                        }
                    )
                }
            }
            .navigationTitle("PPT Oluşturucu")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingNewProject) {
            NewPPTProjectView { title, author, theme in
                let project = pptService.createNewProject(title: title, author: author, theme: theme)
                pptService.currentProject = project
                showingNewProject = false
            }
        }
        .sheet(isPresented: $showingSlideEditor) {
            if let slide = selectedSlide {
                SlideEditorView(
                    slide: slide,
                    onSave: { updatedSlide in
                        // Update slide in project
                        showingSlideEditor = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingPDFPreview) {
            if let pdfURL = generatedPDFURL {
                PDFPreviewView(pdfURL: pdfURL, fileName: "Generated PPT")
            }
        }
        .alert("PPT Builder".localized, isPresented: $showingAlert) {
            Button("Tamam") { }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: pptService.errorMessage) { errorMessage in
            if let error = errorMessage {
                alertMessage = error
                showingAlert = true
            }
        }
    }
    
    private func generatePPT(from project: PPTProject) {
        Task {
            do {
                let pdfURL = try await pptService.generatePPT(from: project)
                
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

// MARK: - PPT Project Selection View
struct PPTProjectSelectionView: View {
    let onNewProject: () -> Void
    let onLoadProject: (PPTProject) -> Void
    
    @State private var savedProjects: [PPTProject] = []
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "rectangle.stack")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("PPT Oluşturucu")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Slaytları tarayın ve sunum oluşturun")
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
                    
                    Text("Yeni Sunum")
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
                    Text("Kayıtlı Sunumlar")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 32)
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(savedProjects, id: \.id) { project in
                                PPTProjectCardView(project: project) {
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

// MARK: - Current PPT Project View
struct CurrentPPTProjectView: View {
    let project: PPTProject
    let pptService: PPTCreationService
    let onAddSlide: () -> Void
    let onEditSlide: (PPTSlide) -> Void
    let onGeneratePPT: () -> Void
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
                    
                    Text("Slayt Sayısı: \(project.slideCount)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Tema: \(project.theme.displayName)")
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
                
                // Slides grid
                if !project.slides.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Slaytlar")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(project.slides.sorted { $0.slideNumber < $1.slideNumber }, id: \.id) { slide in
                                SlideThumbnailView(slide: slide) {
                                    onEditSlide(slide)
                                }
                            }
                        }
                    }
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    if project.slides.isEmpty {
                        Button("İlk Slaytı Ekle") {
                            onAddSlide()
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
                            Button("Slayt Ekle") {
                                onAddSlide()
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
                            
                            Button("PPT Oluştur") {
                                onGeneratePPT()
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
                    
                    Button("Yeni Sunum") {
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

// MARK: - PPT Project Card View
struct PPTProjectCardView: View {
    let project: PPTProject
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
                    
                    Text("\(project.slideCount) slayt • \(project.theme.displayName)")
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

// MARK: - Slide Thumbnail View
struct SlideThumbnailView: View {
    let slide: PPTSlide
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(uiImage: slide.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 100)
                    .clipped()
                    .cornerRadius(8)
                
                VStack(spacing: 4) {
                    Text("Slayt \(slide.slideNumber)")
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Text(slide.slideType.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - New PPT Project View
struct NewPPTProjectView: View {
    let onSave: (String, String?, PPTTheme) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var author = ""
    @State private var selectedTheme: PPTTheme = .modern
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sunum Başlığı")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Sunum adını girin", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Yazar (İsteğe Bağlı)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Yazar adını girin", text: $author)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tema")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Picker("Tema", selection: $selectedTheme) {
                        ForEach(PPTTheme.allCases) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Yeni Sunum")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Oluştur") {
                        onSave(title, author.isEmpty ? nil : author, selectedTheme)
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

// MARK: - Slide Editor View
struct SlideEditorView: View {
    let slide: PPTSlide
    let onSave: (PPTSlide) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Image(uiImage: slide.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Slayt Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        onSave(slide)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    PPTView()
}
