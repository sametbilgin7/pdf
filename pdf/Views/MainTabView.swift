//
//  MainTabView.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI

enum TabSelection {
    case home
    case files
    case scan
    case tools
    case settings
}

struct MainTabView: View {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var localizationManager = LocalizationManager()
    @StateObject private var libraryService = PDFLibraryService() // Merkezi service
    @AppStorage("selectedTheme") private var selectedTheme: String = "system"
    @AppStorage("selectedOCRLanguage") private var selectedOCRLanguage: String = "auto"
    @State private var selectedTab: TabSelection = .home
    // Selection mode wiring from LibraryView
    @State private var isSelectionMode: Bool = false
    @State private var selectedPDFCount: Int = 0
    @State private var selectedFolderCount: Int = 0
    @State private var onDeleteAction: (() -> Void)? = nil
    @State private var onShareAction: (() -> Void)? = nil
    @State private var onTagAction: (() -> Void)? = nil
    @State private var onMergeAction: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Home Tab
                LibraryView(
                    libraryService: libraryService,
                    isSelectionMode: $isSelectionMode,
                    selectedPDFCount: $selectedPDFCount,
                    selectedFolderCount: $selectedFolderCount,
                    onDeleteAction: $onDeleteAction,
                    onShareAction: $onShareAction,
                    onTagAction: $onTagAction,
                    onMergeAction: $onMergeAction
                )
                .tabItem {
                    Image(systemName: "house")
                    Text("Home".localized)
                }
                    .tag(TabSelection.home)
                
                // Files Tab
                FilesView()
                    .tabItem {
                        Image(systemName: "folder")
                        Text("Files".localized)
                    }
                    .tag(TabSelection.files)
                
                // Scan Tab
                NavigationView {
                    ScannerView(
                        selectedTab: $selectedTab,
                        libraryService: libraryService
                    )
                }
                .tabItem {
                    Image(systemName: "camera.viewfinder")
                    Text("Scan".localized)
                }
                .tag(TabSelection.scan)
                
                // Tools Tab
                ToolsView()
                    .tabItem {
                        Image(systemName: "wrench.and.screwdriver")
                        Text("Tools".localized)
                    }
                    .tag(TabSelection.tools)
                
                // Settings Tab
                NavigationView {
                    SettingsView()
                }
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings".localized)
                }
                .tag(TabSelection.settings)
            }
            
            // Custom Action Bar when in selection mode
            if isSelectionMode {
                VStack {
                    Spacer()
                    SelectionActionBar(
                        selectedPDFCount: selectedPDFCount,
                        selectedFolderCount: selectedFolderCount,
                        onShare: onShareAction,
                        onTag: onTagAction,
                        onMerge: onMergeAction,
                        onDelete: onDeleteAction
                    )
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
        .environmentObject(themeManager)
        .environmentObject(localizationManager)
        .onAppear {
            updateThemeManager()
        }
        .onChange(of: selectedTheme) { _, newValue in
            updateThemeManager()
        }
        .onChange(of: isSelectionMode) { _, newValue in
            // Force hide/show TabBar using UIKit
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    if let tabBarController = window.rootViewController as? UITabBarController {
                        tabBarController.tabBar.isHidden = newValue
                    } else {
                        // Find TabBarController in the view hierarchy
                        findAndHideTabBar(in: window.rootViewController, hide: newValue)
                    }
                }
            }
        }
    }
    
    private func updateThemeManager() {
        let theme = AppTheme(rawValue: selectedTheme) ?? .system
        themeManager.setTheme(theme)
    }
    
    private func findAndHideTabBar(in viewController: UIViewController?, hide: Bool) {
        guard let viewController = viewController else { return }
        
        if let tabBarController = viewController as? UITabBarController {
            tabBarController.tabBar.isHidden = hide
            return
        }
        
        // Search in child view controllers
        for child in viewController.children {
            findAndHideTabBar(in: child, hide: hide)
        }
        
        // Search in presented view controller
        if let presented = viewController.presentedViewController {
            findAndHideTabBar(in: presented, hide: hide)
        }
    }
}

#Preview {
    MainTabView()
}

// MARK: - Selection Action Bar
struct SelectionActionBar: View {
    let selectedPDFCount: Int
    let selectedFolderCount: Int
    let onShare: (() -> Void)?
    let onTag: (() -> Void)?
    let onMerge: (() -> Void)?
    let onDelete: (() -> Void)?
    
    private var hasSelection: Bool {
        selectedPDFCount > 0 || selectedFolderCount > 0
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Paylaş (Share)
            ActionButton(
                icon: "square.and.arrow.up",
                title: "Share".localized,
                isEnabled: hasSelection,
                action: { onShare?() }
            )
            
            Divider()
                .frame(height: 20)
                .background(Color.gray.opacity(0.15))
            
            // Etiketler (Tags)
            ActionButton(
                icon: "tag",
                title: "Tags".localized,
                isEnabled: hasSelection,
                action: { onTag?() }
            )
            
            Divider()
                .frame(height: 20)
                .background(Color.gray.opacity(0.15))
            
            // Birleştir (Merge)
            ActionButton(
                icon: "arrow.up.arrow.down",
                title: "Merge".localized,
                isEnabled: selectedPDFCount > 1,
                action: { onMerge?() }
            )
            
            Divider()
                .frame(height: 20)
                .background(Color.gray.opacity(0.15))
            
            // Sil (Delete)
            ActionButton(
                icon: "trash",
                title: "Delete".localized,
                isEnabled: hasSelection,
                action: { onDelete?() }
            )
        }
        .frame(height: 49)
        .background(
            Color.backgroundPrimary
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.2))
                .offset(y: -24.5),
            alignment: .top
        )
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            if isEnabled {
                HapticManager.light()
                action()
            }
        }) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(isEnabled ? .textPrimary : .textSecondary)
                
                Text(title)
                    .font(Typography.caption)
                    .foregroundColor(isEnabled ? .textPrimary : .textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 49)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
