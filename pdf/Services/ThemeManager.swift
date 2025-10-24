//
//  ThemeManager.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .system
    @Published var colorScheme: ColorScheme? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupThemeObserver()
    }
    
    private func setupThemeObserver() {
        $currentTheme
            .sink { [weak self] theme in
                self?.updateColorScheme(for: theme)
            }
            .store(in: &cancellables)
    }
    
    private func updateColorScheme(for theme: AppTheme) {
        switch theme {
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        case .system:
            colorScheme = nil
        }
    }
    
    func setTheme(_ theme: AppTheme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .system: return "gearshape"
        }
    }
}

// MARK: - Shadow Styles
struct ShadowStyle {
    static let soft = Shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    static let medium = Shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
    static let strong = Shadow(color: .black.opacity(0.16), radius: 16, x: 0, y: 8)
    static let card = Shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Corner Radius Styles
struct CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 20
    static let card: CGFloat = 16
    static let button: CGFloat = 12
}

// MARK: - Spacing Styles
struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Typography Styles
struct Typography {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title.weight(.semibold)
    static let title2 = Font.title2.weight(.semibold)
    static let title3 = Font.title3.weight(.medium)
    static let headline = Font.headline.weight(.semibold)
    static let body = Font.body
    static let bodyBold = Font.body.weight(.semibold)
    static let callout = Font.callout
    static let subheadline = Font.subheadline
    static let footnote = Font.footnote
    static let caption = Font.caption
    static let caption2 = Font.caption2
}

// MARK: - Animation Styles
struct AnimationStyle {
    static let quick = Animation.easeInOut(duration: 0.2)
    static let smooth = Animation.easeInOut(duration: 0.3)
    static let gentle = Animation.easeInOut(duration: 0.4)
    static let bouncy = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let snappy = Animation.spring(response: 0.4, dampingFraction: 0.9)
}

// MARK: - Haptic Feedback
struct HapticManager {
    static func light() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    static func medium() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    static func heavy() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    static func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    static func warning() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    static func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    static func selection() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
}
