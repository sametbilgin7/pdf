//
//  OnboardingData.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI

struct OnboardingPage {
    let id: Int
    let title: String
    let subtitle: String
    let imageName: String
    let description: String
    let primaryColor: Color
    let secondaryColor: Color
}

struct OnboardingData {
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            title: "Welcome to PDF Scanner".localized,
            subtitle: "Scan, Edit & Organize".localized,
            imageName: "doc.viewfinder",
            description: "Transform your documents into digital PDFs with professional quality scanning.".localized,
            primaryColor: .blue,
            secondaryColor: .purple
        ),
        OnboardingPage(
            id: 1,
            title: "Smart Document Scanner".localized,
            subtitle: "AI-Powered Recognition".localized,
            imageName: "camera.viewfinder",
            description: "Advanced OCR technology automatically detects and enhances your documents for crystal clear results.".localized,
            primaryColor: .green,
            secondaryColor: .mint
        ),
        OnboardingPage(
            id: 2,
            title: "Powerful Editing Tools".localized,
            subtitle: "Perfect Your Documents".localized,
            imageName: "slider.horizontal.3",
            description: "Crop, rotate, adjust brightness and contrast to make your documents look professional.".localized,
            primaryColor: .orange,
            secondaryColor: .yellow
        ),
        OnboardingPage(
            id: 3,
            title: "Organize & Share".localized,
            subtitle: "Keep Everything Tidy".localized,
            imageName: "folder.badge.plus",
            description: "Create folders, add tags, and easily share your PDFs with others or save to cloud storage.".localized,
            primaryColor: .purple,
            secondaryColor: .pink
        ),
        OnboardingPage(
            id: 4,
            title: "Ready to Start?".localized,
            subtitle: "Let's Begin Scanning".localized,
            imageName: "checkmark.circle.fill",
            description: "You're all set! Start scanning your first document and experience the power of modern PDF scanning.".localized,
            primaryColor: .blue,
            secondaryColor: .cyan
        )
    ]
}
