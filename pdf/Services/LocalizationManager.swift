//
//  LocalizationManager.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI
import Combine

class LocalizationManager: ObservableObject {
    @Published var currentLanguage: AppLanguage = .english
    @Published var locale: Locale = Locale(identifier: "en")
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSavedLanguage()
    }
    
    private func loadSavedLanguage() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "selectedAppLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            currentLanguage = language
            updateLocale(for: language)
        } else {
            // Sistem dilini algıla ve ona göre varsayılan dil seç
            let detectedLanguage = detectSystemLanguage()
            currentLanguage = detectedLanguage
            updateLocale(for: detectedLanguage)
            UserDefaults.standard.set(detectedLanguage.rawValue, forKey: "selectedAppLanguage")
        }
    }
    
    private func detectSystemLanguage() -> AppLanguage {
        // Sistem dilini al
        let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        
        // Sistem dili ile uygulama dillerini eşleştir
        switch systemLanguage {
        case "tr":
            return .turkish
        case "en":
            return .english
        case "de":
            return .german
        case "fr":
            return .french
        case "es":
            return .spanish
        case "it":
            return .italian
        case "ru":
            return .russian
        case "uk":
            return .ukrainian
        case "zh":
            return .chinese
        case "ja":
            return .japanese
        case "ko":
            return .korean
        case "pt":
            return .portuguese
        case "nl":
            return .dutch
        case "id":
            return .indonesian
        default:
            // Desteklenmeyen diller için İngilizce varsayılan
            return .english
        }
    }
    
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: "selectedAppLanguage")
        
        // Update locale for immediate UI refresh
        updateLocale(for: language)
        
        // Force UI refresh by updating published properties
        DispatchQueue.main.async {
            self.currentLanguage = language
            self.locale = Locale(identifier: language.rawValue)
        }
    }
    
    private func updateLocale(for language: AppLanguage) {
        switch language {
        case .turkish:
            locale = Locale(identifier: "tr")
        case .english:
            locale = Locale(identifier: "en")
        case .german:
            locale = Locale(identifier: "de")
        case .french:
            locale = Locale(identifier: "fr")
        case .spanish:
            locale = Locale(identifier: "es")
        case .italian:
            locale = Locale(identifier: "it")
        case .russian:
            locale = Locale(identifier: "ru")
        case .ukrainian:
            locale = Locale(identifier: "uk")
        case .chinese:
            locale = Locale(identifier: "zh")
        case .japanese:
            locale = Locale(identifier: "ja")
        case .korean:
            locale = Locale(identifier: "ko")
        case .portuguese:
            locale = Locale(identifier: "pt")
        case .dutch:
            locale = Locale(identifier: "nl")
        case .indonesian:
            locale = Locale(identifier: "id")
        }
    }
    
    func localizedString(for key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case turkish = "tr"
    case german = "de"
    case french = "fr"
    case spanish = "es"
    case italian = "it"
    case russian = "ru"
    case ukrainian = "uk"
    case chinese = "zh"
    case japanese = "ja"
    case korean = "ko"
    case portuguese = "pt"
    case dutch = "nl"
    case indonesian = "id"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .turkish: return "Türkçe"
        case .german: return "Deutsch"
        case .french: return "français"
        case .spanish: return "español"
        case .italian: return "italiano"
        case .russian: return "русский"
        case .ukrainian: return "українська"
        case .chinese: return "中文"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .portuguese: return "português"
        case .dutch: return "Nederlands"
        case .indonesian: return "Indonesia"
        }
    }
    
    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .turkish: return "🇹🇷"
        case .german: return "🇩🇪"
        case .french: return "🇫🇷"
        case .spanish: return "🇪🇸"
        case .italian: return "🇮🇹"
        case .russian: return "🇷🇺"
        case .ukrainian: return "🇺🇦"
        case .chinese: return "🇨🇳"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        case .portuguese: return "🇵🇹"
        case .dutch: return "🇳🇱"
        case .indonesian: return "🇮🇩"
        }
    }
    
    var code: String {
        return rawValue.uppercased()
    }
}

// MARK: - Bundle Extension for Language Switching
extension Bundle {
    private static var bundle: Bundle!
    
    public static func localizedBundle() -> Bundle! {
        if bundle == nil {
            bundle = Bundle.main
        }
        return bundle
    }
    
    public static func setLanguage(_ language: String) {
        defer {
            object_setClass(Bundle.main, Bundle.self)
        }
        
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj") else {
            bundle = Bundle.main
            return
        }
        
        bundle = Bundle(path: path)
    }
}

// MARK: - String Extension for Localization
extension String {
    var localized: String {
        // Try to get the current language from UserDefaults
        let currentLanguage = UserDefaults.standard.string(forKey: "selectedAppLanguage") ?? "en"
        
        // Get the appropriate bundle for the language
        guard let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // Fallback to English if language bundle not found
            guard let enPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
                  let enBundle = Bundle(path: enPath) else {
                return NSLocalizedString(self, comment: "")
            }
            return enBundle.localizedString(forKey: self, value: self, table: nil)
        }
        
        return bundle.localizedString(forKey: self, value: self, table: nil)
    }
}