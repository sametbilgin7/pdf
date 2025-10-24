//
//  ToolsView.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI

struct ToolsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var searchText = ""
    @State private var isGridView = true
    @State private var showingFilesView = false
    
    // All tools data
    private let allTools: [ToolSectionData] = [
        ToolSectionData(title: "Files Manager", tools: [
            ToolItem(icon: "doc.fill", iconColor: Color("AccentRed"), title: "PDF"),
            ToolItem(icon: "scanner", iconColor: Color("PrimaryGreen"), title: "Scanner"),
            ToolItem(icon: "folder.fill", iconColor: Color("AccentOrange"), title: "Files"),
            ToolItem(icon: "magnifyingglass", iconColor: Color("PrimaryBlue"), title: "Search")
        ]),
        ToolSectionData(title: "Convert To PDF", tools: [
            ToolItem(icon: "doc.text", iconColor: Color("PrimaryBlue"), title: "Word To PDF"),
            ToolItem(icon: "tablecells", iconColor: Color("PrimaryGreen"), title: "Excel To PDF"),
            ToolItem(icon: "book.fill", iconColor: Color("PrimaryBlue"), title: "ePub To PDF"),
            ToolItem(icon: "rectangle.on.rectangle.angled", iconColor: Color("PrimaryPurple"), title: "PPT To PDF"),
            ToolItem(icon: "doc.fill", iconColor: Color("PrimaryPurple"), title: "DJVU To PDF"),
            ToolItem(icon: "book.closed.fill", iconColor: Color("AccentOrange"), title: "MOBI To PDF"),
            ToolItem(icon: "doc.text.magnifyingglass", iconColor: Color("PrimaryPurple"), title: "Redact PDF"),
            ToolItem(icon: "photo.fill", iconColor: Color("PrimaryBlue"), title: "Photos To PDF"),
            ToolItem(icon: "person.crop.circle.fill", iconColor: Color("PrimaryGreen"), title: "Contact To PDF"),
            ToolItem(icon: "doc.on.clipboard.fill", iconColor: Color("PrimaryBlue"), title: "Clipboard To PDF")
        ]),
        ToolSectionData(title: "Convert From PDF", tools: [
            ToolItem(icon: "brain.head.profile", iconColor: Color("PrimaryPurple"), title: "AI Summary"),
            ToolItem(icon: "doc.text", iconColor: Color("PrimaryBlue"), title: "PDF To Word"),
            ToolItem(icon: "book.fill", iconColor: Color("PrimaryBlue"), title: "PDF To ePub"),
            ToolItem(icon: "photo.fill", iconColor: Color("PrimaryBlue"), title: "PDF To SVG"),
            ToolItem(icon: "tablecells", iconColor: Color("PrimaryGreen"), title: "PDF To Xlsx"),
            ToolItem(icon: "rectangle.on.rectangle.angled", iconColor: Color("PrimaryGreen"), title: "PDF To PPT"),
            ToolItem(icon: "photo", iconColor: Color("AccentOrange"), title: "PDF To JPG"),
            ToolItem(icon: "photo.fill", iconColor: Color("PrimaryGreen"), title: "PDF To PNG")
        ]),
        ToolSectionData(title: "Templates", tools: [
            ToolItem(icon: "person.crop.circle.fill", iconColor: Color("PrimaryGreen"), title: "CV Maker"),
            ToolItem(icon: "envelope.fill", iconColor: Color("PrimaryBlue"), title: "Cover Letter"),
            ToolItem(icon: "doc.text.fill", iconColor: Color("AccentRed"), title: "Invoice")
        ]),
        ToolSectionData(title: "PDF Security", tools: [
            ToolItem(icon: "lock.fill", iconColor: Color("AccentOrange"), title: "Lock"),
            ToolItem(icon: "lock.open.fill", iconColor: Color("PrimaryPurple"), title: "Unlock")
        ]),
        ToolSectionData(title: "Annotate PDF", tools: [
            ToolItem(icon: "link", iconColor: Color("PrimaryBlue"), title: "Link"),
            ToolItem(icon: "drop.fill", iconColor: Color("AccentRed"), title: "Watermark"),
            ToolItem(icon: "signature", iconColor: Color("PrimaryPurple"), title: "eSign")
        ]),
        ToolSectionData(title: "Optimize", tools: [
            ToolItem(icon: "doc.text.fill", iconColor: Color("PrimaryBlue"), title: "Fill Form"),
            ToolItem(icon: "speaker.wave.2.fill", iconColor: Color("AccentOrange"), title: "Reader"),
            ToolItem(icon: "person.fill", iconColor: Color("AccentOrange"), title: "Popular Forms"),
            ToolItem(icon: "number", iconColor: Color("PrimaryGreen"), title: "Page Number")
        ]),
        ToolSectionData(title: "Organize", tools: [
            ToolItem(icon: "doc.on.doc.fill", iconColor: Color("AccentRed"), title: "PDF Merge"),
            ToolItem(icon: "doc.badge.ellipsis", iconColor: Color("PrimaryPurple"), title: "Split"),
            ToolItem(icon: "arrow.down.circle.fill", iconColor: Color("PrimaryGreen"), title: "Compress"),
            ToolItem(icon: "rotate.right.fill", iconColor: Color("PrimaryPurple"), title: "Rotate"),
            ToolItem(icon: "trash.fill", iconColor: Color("AccentRed"), title: "Delete Pages"),
            ToolItem(icon: "doc.badge.plus", iconColor: Color("PrimaryGreen"), title: "Extract Pages")
        ])
    ]
    
    // Computed property for filtered tools
    private var filteredTools: [ToolSectionData] {
        if searchText.isEmpty {
            return allTools
        } else {
            return allTools.compactMap { section in
                let filteredSectionTools = section.tools.filter { tool in
                    tool.title.localizedCaseInsensitiveContains(searchText)
                }
                if !filteredSectionTools.isEmpty {
                    return ToolSectionData(title: section.title, tools: filteredSectionTools)
                }
                return nil
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with Tools title and Grid/List Toggle
                HStack {
                    Text("Tools".localized)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color("TextPrimary"))
                    
                    Spacer()
                    
                    // Grid/List Toggle Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isGridView.toggle()
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color("CardBackground"))
                                .frame(width: 44, height: 44)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            
                            // 2x4 Grid of squares
                            VStack(spacing: 2) {
                                HStack(spacing: 2) {
                                    Rectangle()
                                        .fill(Color("PrimaryBlue").opacity(0.3))
                                        .frame(width: 6, height: 6)
                                        .cornerRadius(1)
                                    Rectangle()
                                        .fill(Color("PrimaryBlue"))
                                        .frame(width: 6, height: 6)
                                        .cornerRadius(1)
                                    Rectangle()
                                        .fill(Color("PrimaryBlue").opacity(0.3))
                                        .frame(width: 6, height: 6)
                                        .cornerRadius(1)
                                    Rectangle()
                                        .fill(Color("PrimaryBlue"))
                                        .frame(width: 6, height: 6)
                                        .cornerRadius(1)
                                }
                                
                                HStack(spacing: 2) {
                                    Rectangle()
                                        .fill(Color("PrimaryBlue"))
                                        .frame(width: 6, height: 6)
                                        .cornerRadius(1)
                                    Rectangle()
                                        .fill(Color("PrimaryBlue").opacity(0.3))
                                        .frame(width: 6, height: 6)
                                        .cornerRadius(1)
                                    Rectangle()
                                        .fill(Color("PrimaryBlue"))
                                        .frame(width: 6, height: 6)
                                        .cornerRadius(1)
                                    Rectangle()
                                        .fill(Color("PrimaryBlue").opacity(0.3))
                                        .frame(width: 6, height: 6)
                                        .cornerRadius(1)
                                }
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)
                
                // Search Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                        
                        TextField("Search Tool".localized, text: $searchText)
                            .font(.system(size: 16))
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color("CardBackground"))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        ForEach(filteredTools, id: \.title) { section in
                            ToolSection(
                                title: section.title.localized,
                                tools: section.tools.map { tool in
                                    ToolItem(
                                        icon: tool.icon,
                                        iconColor: tool.iconColor,
                                        title: tool.title.localized
                                    )
                                },
                                isGridView: isGridView,
                                onToolTap: { tool in
                                    handleToolTap(tool)
                                }
                            )
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .background(Color("BackgroundPrimary").edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
            .sheet(isPresented: $showingFilesView) {
                FilesView()
            }
        }
    }
    
    // MARK: - Tool Tap Handler
    private func handleToolTap(_ tool: ToolItem) {
        switch tool.title {
        case "PDF".localized:
            showingFilesView = true
        case "Scanner".localized:
            // Handle scanner
            break
        case "Files".localized:
            // Handle files
            break
        case "Search".localized:
            // Handle search
            break
        default:
            // Handle other tools
            break
        }
    }
}

// MARK: - Tool Item Model
struct ToolItem: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    
    init(icon: String, iconColor: Color, title: String) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
    }
}

// MARK: - Tool Section
struct ToolSection: View {
    let title: String
    let tools: [ToolItem]
    let isGridView: Bool
    var onToolTap: ((ToolItem) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color("TextPrimary"))
                .padding(.horizontal, 20)
            
            if isGridView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
                ], spacing: 16) {
                ForEach(tools) { tool in
                    ToolButton(tool: tool, onTap: {
                        onToolTap?(tool)
                    })
                }
            }
            .padding(.horizontal, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(tools) { tool in
                        ToolButton(tool: tool, onTap: {
                            onToolTap?(tool)
                        })
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Tool Button
struct ToolButton: View {
    let tool: ToolItem
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            HapticManager.light()
            onTap?()
        }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(tool.iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: tool.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(tool.iconColor)
                }
                
                Text(tool.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color("TextPrimary"))
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color("CardBackground"))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }
}

// MARK: - Tool Section Data
struct ToolSectionData {
    let title: String
    let tools: [ToolItem]
}

#Preview {
    ToolsView()
        .environmentObject(ThemeManager())
}

