//
//  ShareService.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI
import UIKit
import Combine

class ShareService: ObservableObject {
    @Published var isSharing = false
    @Published var shareError: String?
    
    // MARK: - Share PDF
    func sharePDF(_ pdfURL: URL, from viewController: UIViewController) {
        guard FileManager.default.fileExists(atPath: pdfURL.path) else {
            shareError = "PDF file not found"
            return
        }
        
        isSharing = true
        shareError = nil
        
        let activityViewController = UIActivityViewController(
            activityItems: [pdfURL],
            applicationActivities: nil
        )
        
        // Configure for iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Exclude certain activities if needed
        activityViewController.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList
        ]
        
        // Present the share sheet
        viewController.present(activityViewController, animated: true) {
            self.isSharing = false
        }
    }
    
    // MARK: - Share Text
    func shareText(_ text: String, from viewController: UIViewController) {
        isSharing = true
        shareError = nil
        
        let activityViewController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        // Configure for iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Present the share sheet
        viewController.present(activityViewController, animated: true) {
            self.isSharing = false
        }
    }
    
    // MARK: - Share Multiple Items
    func shareMultiple(_ items: [Any], from viewController: UIViewController) {
        isSharing = true
        shareError = nil
        
        let activityViewController = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // Configure for iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Present the share sheet
        viewController.present(activityViewController, animated: true) {
            self.isSharing = false
        }
    }
}

// MARK: - SwiftUI Share Sheet
struct ModernShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?
    let onComplete: (() -> Void)?
    
    init(activityItems: [Any], applicationActivities: [UIActivity]? = nil, onComplete: (() -> Void)? = nil) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
        self.onComplete = onComplete
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        
        // Configure for iPad
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        controller.completionWithItemsHandler = { _, _, _, _ in
            onComplete?()
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Share Button Component
struct ShareButton: View {
    let items: [Any]
    let title: String
    let icon: String
    let onComplete: (() -> Void)?
    
    @State private var showingShareSheet = false
    
    init(items: [Any], title: String = "Share", icon: String = "square.and.arrow.up", onComplete: (() -> Void)? = nil) {
        self.items = items
        self.title = title
        self.icon = icon
        self.onComplete = onComplete
    }
    
    var body: some View {
        Button(action: {
            HapticManager.light()
            showingShareSheet = true
        }) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                Text(title)
            }
            .font(Typography.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .fill(Color.primaryBlue)
            )
            .shadow(
                color: .primaryBlue.opacity(0.3),
                radius: 4,
                x: 0,
                y: 2
            )
        }
        .sheet(isPresented: $showingShareSheet) {
            ModernShareSheet(activityItems: items, onComplete: onComplete)
        }
    }
}

// MARK: - Share Menu Component
struct ShareMenu: View {
    let items: [Any]
    let title: String
    let icon: String
    
    init(items: [Any], title: String = "Share", icon: String = "square.and.arrow.up") {
        self.items = items
        self.title = title
        self.icon = icon
    }
    
    var body: some View {
        Menu {
            Button(action: {
                // Share action will be handled by parent
            }) {
                Label(title, systemImage: icon)
            }
        } label: {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.primaryBlue)
        }
    }
}
