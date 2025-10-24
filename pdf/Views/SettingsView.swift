//
//  SettingsView.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI
import Combine

struct SettingsView: View {
    @AppStorage("selectedTheme") private var selectedTheme: String = "system"
    @AppStorage("selectedOCRLanguage") private var selectedOCRLanguage: String = "auto"
    @AppStorage("scanQuality") private var scanQuality: String = "high"
    @AppStorage("autoEnhance") private var autoEnhance: Bool = true
    @AppStorage("autoSave") private var autoSave: Bool = true
    @AppStorage("hapticFeedback") private var hapticFeedback: Bool = true
    @AppStorage("showTutorial") private var showTutorial: Bool = true
    @AppStorage("storageUsed") private var storageUsed: Double = 0.0
    @AppStorage("selectedAppLanguage") private var selectedAppLanguage: String = "tr"
    
    // PDF-specific settings
    @AppStorage("pdfCompression") private var pdfCompression: String = "medium"
    @AppStorage("autoOCR") private var autoOCR: Bool = true
    @AppStorage("scanMode") private var scanMode: String = "auto"
    @AppStorage("documentFormat") private var documentFormat: String = "pdf"
    @AppStorage("autoRotate") private var autoRotate: Bool = true
    @AppStorage("edgeDetection") private var edgeDetection: Bool = true
    @AppStorage("batchScanning") private var batchScanning: Bool = false
    @AppStorage("cloudSync") private var cloudSync: Bool = false
    
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var showingAbout = false
    @State private var showingPrivacy = false
    @State private var showingTerms = false
    @State private var showingStorageDetails = false
    @State private var showingLanguagePicker = false
    @State private var showingAppLanguagePicker = false
    @State private var showingPaywall = false
    
    var body: some View {
        List {
            // Premium Section
            Section {
                PremiumCardView(showPaywall: $showingPaywall)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            
            // App Settings
            Section("App Settings".localized) {
                HStack {
                    Image(systemName: "bell")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Notifications".localized)
                    
                    Spacer()
                    
                    Toggle("", isOn: .constant(true))
                        .tint(.blue)
                }
                
                HStack {
                    Image(systemName: "moon")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Dark Mode".localized)
                    
                    Spacer()
                    
                    Toggle("", isOn: .constant(false))
                        .tint(.blue)
                }
                
                Button {
                    showingAppLanguagePicker = true
                } label: {
                    HStack(alignment: .center) {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("Language".localized)
                        Spacer()
                        Text(selectedAppLanguage.uppercased())
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Image(systemName: "hand.tap")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Haptic Feedback".localized)
                    
                    Spacer()
                    
                    Toggle("", isOn: $hapticFeedback)
                        .tint(.blue)
                }
                
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Show Tutorial".localized)
                    
                    Spacer()
                    
                    Toggle("", isOn: $showTutorial)
                        .tint(.blue)
                }
                
                Button {
                    UserDefaults.standard.set(false, forKey: "onboarding_completed")
                    // Restart app to show onboarding
                    exit(0)
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("Reset Onboarding".localized)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // PDF Tarama Ayarları
            Section("PDF Scanning Settings".localized) {
                Button {
                    showingLanguagePicker = true
                } label: {
                    HStack {
                        Image(systemName: "text.viewfinder")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("OCR Language".localized)
                        
                        Spacer()
                        
                        Text(selectedOCRLanguage == "auto" ? "Automatic".localized : selectedOCRLanguage.uppercased())
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Image(systemName: "camera")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Scan Quality".localized)
                    
                    Spacer()
                    
                    Picker("", selection: $scanQuality) {
                        Text("Low".localized).tag("low")
                        Text("Medium".localized).tag("medium")
                        Text("High".localized).tag("high")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                HStack {
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Auto Enhancement".localized)
                    
                    Spacer()
                    
                    Toggle("", isOn: $autoEnhance)
                        .tint(.blue)
                }
                
                HStack {
                    Image(systemName: "text.viewfinder")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Auto OCR".localized)
                    
                    Spacer()
                    
                    Toggle("", isOn: $autoOCR)
                        .tint(.blue)
                }
                
                HStack {
                    Image(systemName: "crop")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Edge Detection".localized)
                    
                    Spacer()
                    
                    Toggle("", isOn: $edgeDetection)
                        .tint(.blue)
                }
                
                HStack {
                    Image(systemName: "rotate.right")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Auto Rotate".localized)
                    
                    Spacer()
                    
                    Toggle("", isOn: $autoRotate)
                        .tint(.blue)
                }
                
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Auto Save".localized)
                    
                    Spacer()
                    
                    Toggle("", isOn: $autoSave)
                        .tint(.blue)
                }
            }
            
            // PDF Ayarları
            Section("PDF Settings".localized) {
                HStack {
                    Image(systemName: "arrow.down.circle")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("PDF Compression".localized)
                    
                    Spacer()
                    
                    Picker("", selection: $pdfCompression) {
                        Text("Low".localized).tag("low")
                        Text("Medium".localized).tag("medium")
                        Text("High".localized).tag("high")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Document Format".localized)
                    
                    Spacer()
                    
                    Picker("", selection: $documentFormat) {
                        Text("PDF").tag("pdf")
                        Text("JPEG").tag("jpeg")
                        Text("PNG").tag("png")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                HStack {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Batch Scanning".localized)
                    
                    Spacer()
                    
                    Toggle("", isOn: $batchScanning)
                        .tint(.blue)
                }
            }
            
            // Bulut & Depolama
            Section("Cloud & Storage".localized) {
                HStack {
                    Image(systemName: "icloud.and.arrow.up")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Cloud Sync".localized)
                    
                    Spacer()
                    
                    Toggle("", isOn: $cloudSync)
                        .tint(.blue)
                }
                
                Button {
                    showingStorageDetails = true
                } label: {
                    HStack {
                        Image(systemName: "internaldrive")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("Storage Usage".localized)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.1f", storageUsed)) MB")
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // About Section
            Section("About".localized) {
                Button {
                    showingAbout = true
                } label: {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                        Text("About".localized)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button {
                    if let url = URL(string: "https://apps.apple.com/app/id123456789") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "star")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("Rate App".localized)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button {
                    if let url = URL(string: "mailto:support@example.com") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("Feedback".localized)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Legal Section
            Section("Legal".localized) {
                Button {
                    if let url = URL(string: "https://developing-comet-b87.notion.site/privacy-policy-pdf-scanner-2931f542e1a380eaa045cdb24aa511a2?source=copy_link") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "hand.raised")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("Privacy Policy".localized)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button {
                    if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("Terms of Use".localized)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Settings".localized)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyView()
        }
        .sheet(isPresented: $showingTerms) {
            TermsView()
        }
        .sheet(isPresented: $showingStorageDetails) {
            StorageDetailsView()
        }
        .sheet(isPresented: $showingLanguagePicker) {
            SettingsLanguagePickerView(selectedLanguageCode: $selectedOCRLanguage)
        }
        .sheet(isPresented: $showingAppLanguagePicker) {
            AppLanguagePickerView(selectedLanguage: $selectedAppLanguage)
        }
    }
}

// MARK: - Premium Card View
struct PremiumCardView: View {
    @Binding var showPaywall: Bool
    @State private var isShaking = false
    @State private var backgroundOffset: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var purchaseManager = PurchaseManager()
    
    var body: some View {
        Group {
            if purchaseManager.isPremium {
                // Premium User View
                HStack(spacing: 16) {
                    // Premium Badge Icon
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                        .background(
                            Circle()
                                .fill(Color.green)
                                .frame(width: 40, height: 40)
                        )
                    
                    // Text Content for Premium Users
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Premium Active".localized)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.35), radius: 2, x: 0, y: 1)
                            .multilineTextAlignment(.leading)
                        
                        Text("Premium Active Description".localized)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color.white.opacity(0.85))
                            .shadow(color: Color.black.opacity(0.3), radius: 1.5, x: 0, y: 1)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    // Premium Badge
                    Text("PREMIUM".localized)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                // Non-Premium User View (Original)
                Button(action: {
                    showPaywall = true
                    HapticManager.light()
                }) {
                    HStack(spacing: 16) {
                        // Crown Icon with Animation
                        ZStack {
                            // Background glow effect
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                                .blur(radius: 8)
                                .scaleEffect(isShaking ? 1.2 : 1.0)
                                .opacity(isShaking ? 0.8 : 0.6)
                            
                            // Crown icon
                            Image(systemName: "crown.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.yellow)
                                .rotationEffect(.degrees(isShaking ? 5 : 0))
                                .scaleEffect(isShaking ? 1.1 : 1.0)
                        }
                        .onAppear {
                            startShakeAnimation()
                        }
                        
                        // Text Content
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Go Premium".localized)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.35), radius: 2, x: 0, y: 1)
                                .multilineTextAlignment(.leading)
                            
                            Text("Premium Description".localized)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color.white.opacity(0.85))
                                .shadow(color: Color.black.opacity(0.3), radius: 1.5, x: 0, y: 1)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                        
                        // Arrow
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        ZStack {
                            // Base gradient
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            // Animated shimmer overlay
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .offset(x: backgroundOffset)
                            .animation(
                                Animation.linear(duration: 2.0)
                                    .repeatForever(autoreverses: false),
                                value: backgroundOffset
                            )
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
                .onAppear {
                    startShimmerAnimation()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func startShakeAnimation() {
        withAnimation(
            Animation.easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
        ) {
            isShaking = true
        }
    }
    
    private func startShimmerAnimation() {
        backgroundOffset = -200
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            backgroundOffset = 200
        }
    }
}

// MARK: - Purchase Manager
class PurchaseManager: ObservableObject {
    @Published var isPremium: Bool = false
    
    init() {
        // Simulate premium status check
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("Modern PDF Scanner".localized)
                        .font(.title)
                        .fontWeight(.medium)
                    
                    Text("Version 1.0.0".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("Professional document scanning and PDF creation app with advanced OCR capabilities.".localized)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 16) {
                    Text("© 2025 Modern PDF Scanner".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Made with ❤️ in Turkey".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationTitle("About".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Privacy View
struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "doc.text")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Privacy Policy".localized)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Privacy Description".localized)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    if let url = URL(string: "https://developing-comet-b87.notion.site/privacy-policy-pdf-scanner-2931f542e1a380eaa045cdb24aa511a2?source=copy_link") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "safari")
                        Text("View Privacy Policy".localized)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Privacy Policy".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Terms View
struct TermsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "doc.text")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Terms of Use".localized)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Terms Description".localized)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "safari")
                        Text("View Terms of Use".localized)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Terms of Use".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Storage Details View
struct StorageDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("storageUsed") private var storageUsed: Double = 0.0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "internaldrive")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Storage Usage".localized)
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("\(String(format: "%.1f", storageUsed)) MB used".localized)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("PDF Files".localized)
                        Spacer()
                        Text("\(String(format: "%.1f", storageUsed * 0.7)) MB")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Image Cache".localized)
                        Spacer()
                        Text("\(String(format: "%.1f", storageUsed * 0.3)) MB")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Storage Usage".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Language Picker with modern design matching the image
struct SettingsLanguagePickerView: View {
    @Binding var selectedLanguageCode: String
    @Environment(\.dismiss) private var dismiss
    
    // Flag emojis for each language
    private let flagEmojis: [String: String] = [
        "en": "🇬🇧",
        "de": "🇩🇪", 
        "fr": "🇫🇷",
        "es": "🇪🇸",
        "it": "🇮🇹",
        "ru": "🇷🇺",
        "tr": "🇹🇷",
        "uk": "🇺🇦",
        "zh": "🇨🇳",
        "ko": "🇰🇷",
        "ja": "🇯🇵",
        "ar": "🇸🇦",
        "hi": "🇮🇳",
        "pt": "🇵🇹",
        "nl": "🇳🇱",
        "sv": "🇸🇪",
        "no": "🇳🇴",
        "da": "🇩🇰",
        "fi": "🇫🇮",
        "pl": "🇵🇱",
        "cs": "🇨🇿",
        "sk": "🇸🇰",
        "hu": "🇭🇺",
        "ro": "🇷🇴",
        "bg": "🇧🇬",
        "hr": "🇭🇷",
        "sl": "🇸🇮",
        "et": "🇪🇪",
        "lv": "🇱🇻",
        "lt": "🇱🇹",
        "auto": "🤖"
    ]
    
    private let languages = [
        ("auto", "Otomatik", "🤖"),
        ("tr", "Türkçe", "🇹🇷"),
        ("en", "English", "🇬🇧"),
        ("de", "Deutsch", "🇩🇪"),
        ("fr", "Français", "🇫🇷"),
        ("es", "Español", "🇪🇸"),
        ("it", "Italiano", "🇮🇹"),
        ("ru", "Русский", "🇷🇺"),
        ("zh", "中文", "🇨🇳"),
        ("ja", "日本語", "🇯🇵"),
        ("ko", "한국어", "🇰🇷"),
        ("ar", "العربية", "🇸🇦"),
        ("hi", "हिन्दी", "🇮🇳"),
        ("pt", "Português", "🇵🇹"),
        ("nl", "Nederlands", "🇳🇱"),
        ("sv", "Svenska", "🇸🇪"),
        ("no", "Norsk", "🇳🇴"),
        ("da", "Dansk", "🇩🇰"),
        ("fi", "Suomi", "🇫🇮"),
        ("pl", "Polski", "🇵🇱"),
        ("cs", "Čeština", "🇨🇿"),
        ("sk", "Slovenčina", "🇸🇰"),
        ("hu", "Magyar", "🇭🇺"),
        ("ro", "Română", "🇷🇴"),
        ("bg", "Български", "🇧🇬"),
        ("hr", "Hrvatski", "🇭🇷"),
        ("sl", "Slovenščina", "🇸🇮"),
        ("et", "Eesti", "🇪🇪"),
        ("lv", "Latviešu", "🇱🇻"),
        ("lt", "Lietuvių", "🇱🇹")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(languages, id: \.0) { language in
                    HStack {
                        Text(language.2)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(language.1)
                                .font(.body)
                                .fontWeight(.medium)
                            Text(language.0 == "auto" ? "System Language".localized : "OCR for \(language.1)".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedLanguageCode == language.0 {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                                .fontWeight(.semibold)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedLanguageCode = language.0
                        dismiss()
                    }
                }
            }
            .navigationTitle("OCR Language".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - App Language Picker View
struct AppLanguagePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLanguage: String
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Language".localized)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 24, height: 24)
                        }
                    }
                    
                    Text("Language Description".localized)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Language Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(AppLanguage.allCases) { language in
                            LanguageCardView(
                                language: language,
                                isSelected: selectedLanguage == language.rawValue,
                                onTap: {
                                    selectedLanguage = language.rawValue
                                    localizationManager.setLanguage(language)
                                    dismiss()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
            .background(
                colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground)
            )
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Language Card View
struct LanguageCardView: View {
    let language: AppLanguage
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(language.flag)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(language.code)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.blue.opacity(0.1) : (colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
        SettingsView()
    }