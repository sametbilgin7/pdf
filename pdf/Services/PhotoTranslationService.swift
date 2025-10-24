//
//  PhotoTranslationService.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import Foundation
import UIKit
import Vision
import Combine

struct TranslationResult {
    let originalText: String
    let detectedLanguage: String
    let translatedText: String
    let targetLanguage: String
    let confidence: Float
    let processingTime: TimeInterval
    
    var formattedOriginalText: String {
        return originalText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var formattedTranslatedText: String {
        return translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var confidencePercentage: Int {
        return Int(confidence * 100)
    }
}

enum SupportedLanguage: String, CaseIterable, Identifiable {
    case turkish = "tr"
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case russian = "ru"
    case chinese = "zh"
    case japanese = "ja"
    case korean = "ko"
    case arabic = "ar"
    case auto = "auto"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .turkish:
            return "Türkçe"
        case .english:
            return "English"
        case .spanish:
            return "Español"
        case .french:
            return "Français"
        case .german:
            return "Deutsch"
        case .italian:
            return "Italiano"
        case .portuguese:
            return "Português"
        case .russian:
            return "Русский"
        case .chinese:
            return "中文"
        case .japanese:
            return "日本語"
        case .korean:
            return "한국어"
        case .arabic:
            return "العربية"
        case .auto:
            return "Otomatik Algılama"
        }
    }
    
    var nativeName: String {
        switch self {
        case .turkish:
            return "Türkçe"
        case .english:
            return "English"
        case .spanish:
            return "Español"
        case .french:
            return "Français"
        case .german:
            return "Deutsch"
        case .italian:
            return "Italiano"
        case .portuguese:
            return "Português"
        case .russian:
            return "Русский"
        case .chinese:
            return "中文"
        case .japanese:
            return "日本語"
        case .korean:
            return "한국어"
        case .arabic:
            return "العربية"
        case .auto:
            return "Otomatik"
        }
    }
}

enum TranslationError: Error, LocalizedError {
    case imageConversionFailed
    case noTextDetected
    case textRecognitionFailed(String)
    case translationFailed(String)
    case unsupportedLanguage
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Görüntü işleme için dönüştürülemedi."
        case .noTextDetected:
            return "Fotoğrafta metin algılanamadı."
        case .textRecognitionFailed(let reason):
            return "Metin tanıma başarısız: \(reason)"
        case .translationFailed(let reason):
            return "Çeviri başarısız: \(reason)"
        case .unsupportedLanguage:
            return "Desteklenmeyen dil."
        }
    }
}

class PhotoTranslationService: ObservableObject {
    @Published var isProcessing = false
    @Published var lastResult: TranslationResult?
    @Published var errorMessage: String?
    
    private let visionQueue = DispatchQueue(label: "com.modernpdfscanner.translation", qos: .userInitiated)
    
    func translatePhoto(from image: UIImage, targetLanguage: SupportedLanguage) async throws -> TranslationResult {
        await MainActor.run {
            self.isProcessing = true
            self.errorMessage = nil
        }
        
        let startTime = Date()
        
        return try await withCheckedThrowingContinuation { continuation in
            visionQueue.async {
                do {
                    let result = try self.performPhotoTranslation(on: image, targetLanguage: targetLanguage)
                    let processingTime = Date().timeIntervalSince(startTime)
                    
                    let translationResult = TranslationResult(
                        originalText: result.originalText,
                        detectedLanguage: result.detectedLanguage,
                        translatedText: result.translatedText,
                        targetLanguage: targetLanguage.rawValue,
                        confidence: result.confidence,
                        processingTime: processingTime
                    )
                    
                    Task { @MainActor in
                        self.isProcessing = false
                        self.lastResult = translationResult
                        continuation.resume(returning: translationResult)
                    }
                } catch {
                    Task { @MainActor in
                        self.isProcessing = false
                        self.errorMessage = error.localizedDescription
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    private func performPhotoTranslation(on image: UIImage, targetLanguage: SupportedLanguage) throws -> (originalText: String, detectedLanguage: String, translatedText: String, confidence: Float) {
        guard let cgImage = image.cgImage else {
            throw TranslationError.imageConversionFailed
        }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("Translation Recognition Error: \(error.localizedDescription)")
            }
        }
        
        // Configure for text recognition
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["tr-TR", "en-US", "es-ES", "fr-FR", "de-DE", "it-IT", "pt-PT", "ru-RU", "zh-CN", "ja-JP", "ko-KR", "ar-SA"]
        request.minimumTextHeight = 0.01
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            throw TranslationError.textRecognitionFailed(error.localizedDescription)
        }
        
        guard let observations = request.results, !observations.isEmpty else {
            throw TranslationError.noTextDetected
        }
        
        var recognizedText = ""
        var totalConfidence: Float = 0
        
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            
            recognizedText += topCandidate.string + "\n"
            totalConfidence += topCandidate.confidence
        }
        
        let averageConfidence = totalConfidence / Float(observations.count)
        
        // Detect language
        let detectedLanguage = detectLanguage(from: recognizedText)
        
        // Translate text
        let translatedText = try translateText(recognizedText, from: detectedLanguage, to: targetLanguage)
        
        return (
            originalText: recognizedText,
            detectedLanguage: detectedLanguage,
            translatedText: translatedText,
            confidence: averageConfidence
        )
    }
    
    private func detectLanguage(from text: String) -> String {
        let text = text.lowercased()
        
        // Simple language detection based on common words
        let languagePatterns = [
            ("tr", ["ve", "bir", "bu", "ile", "için", "olan", "gibi", "daha", "çok", "en", "da", "de", "ki", "mi", "mı", "mu", "mü"]),
            ("en", ["the", "and", "is", "in", "to", "of", "a", "that", "it", "with", "for", "as", "was", "on", "are", "but", "not", "what", "all", "were"]),
            ("es", ["el", "la", "de", "que", "y", "a", "en", "un", "es", "se", "no", "te", "lo", "le", "da", "su", "por", "son", "con", "para", "al", "del", "los", "las"]),
            ("fr", ["le", "de", "et", "à", "un", "il", "être", "et", "en", "avoir", "que", "pour", "dans", "ce", "son", "une", "sur", "avec", "ne", "se", "pas", "tout", "plus", "par", "mais", "son", "les", "une", "du", "des"]),
            ("de", ["der", "die", "und", "in", "den", "von", "zu", "das", "mit", "sich", "des", "auf", "für", "ist", "im", "dem", "nicht", "ein", "eine", "als", "auch", "es", "an", "werden", "aus", "er", "hat", "daß", "sie", "nach", "wird", "bei", "einer", "um", "am", "sind", "noch", "wie", "einem", "über", "einen", "so", "zum", "war", "haben", "nur", "oder", "aber", "vor", "zur", "bis", "mehr", "durch", "man", "sein", "wurde", "sei", "in", "an", "er", "als", "auch", "es", "an", "werden", "aus", "er", "hat", "daß", "sie", "nach", "wird", "bei", "einer", "um", "am", "sind", "noch", "wie", "einem", "über", "einen", "so", "zum", "war", "haben", "nur", "oder", "aber", "vor", "zur", "bis", "mehr", "durch", "man", "sein", "wurde", "sei"]),
            ("it", ["il", "di", "che", "e", "la", "per", "in", "un", "è", "da", "con", "non", "si", "le", "i", "lo", "gli", "del", "della", "dei", "delle", "nel", "nella", "nei", "nelle", "sul", "sulla", "sui", "sulle", "al", "alla", "ai", "alle", "dal", "dalla", "dai", "dalle", "col", "colla", "coi", "collo", "dello", "degli", "delle", "nello", "negli", "nella", "nelle", "sullo", "sugli", "sulla", "sulle", "allo", "agli", "alla", "alle", "dallo", "dagli", "dalla", "dalle", "collo", "cogli", "colla", "collo", "dello", "degli", "delle", "nello", "negli", "nella", "nelle", "sullo", "sugli", "sulla", "sulle", "allo", "agli", "alla", "alle", "dallo", "dagli", "dalla", "dalle", "collo", "cogli", "colla", "collo"]),
            ("pt", ["o", "de", "e", "do", "da", "em", "um", "para", "com", "não", "uma", "os", "no", "se", "na", "por", "mais", "as", "dos", "como", "mas", "foi", "ao", "ele", "das", "tem", "à", "seu", "sua", "ou", "ser", "quando", "muito", "há", "nos", "já", "está", "eu", "também", "só", "pelo", "pela", "até", "isso", "ela", "entre", "era", "depois", "sem", "mesmo", "aos", "ter", "seus", "suas", "numa", "pelos", "pelas", "esse", "eles", "estava", "foram", "são", "esse", "eles", "estava", "foram", "são"]),
            ("ru", ["и", "в", "не", "на", "я", "быть", "с", "он", "а", "как", "по", "но", "они", "к", "у", "мы", "для", "что", "от", "за", "из", "это", "она", "так", "его", "до", "при", "об", "же", "вы", "бы", "что", "ли", "его", "до", "при", "об", "же", "вы", "бы", "что", "ли"]),
            ("zh", ["的", "了", "在", "是", "我", "有", "和", "就", "不", "人", "都", "一", "一个", "上", "也", "很", "到", "说", "要", "去", "你", "会", "着", "没有", "看", "好", "自己", "这", "那", "里", "来", "用", "她", "他", "它", "们", "我", "你", "他", "她", "它", "们", "我", "你", "他", "她", "它", "们"]),
            ("ja", ["の", "に", "は", "を", "た", "が", "で", "て", "と", "し", "れ", "さ", "ある", "いる", "も", "する", "から", "な", "こと", "として", "人", "今", "その", "ため", "これ", "それ", "あれ", "どれ", "いつ", "どこ", "なぜ", "どう", "どの", "どんな", "どちら", "どっち", "どれ", "いつ", "どこ", "なぜ", "どう", "どの", "どんな", "どちら", "どっち"]),
            ("ko", ["이", "가", "을", "를", "에", "에서", "와", "과", "의", "로", "으로", "도", "는", "은", "이", "가", "을", "를", "에", "에서", "와", "과", "의", "로", "으로", "도", "는", "은"]),
            ("ar", ["في", "من", "إلى", "على", "هذا", "هذه", "التي", "الذي", "التي", "الذي", "هذا", "هذه", "التي", "الذي", "التي", "الذي"])
        ]
        
        var maxScore = 0
        var detectedLang = "en"
        
        for (lang, patterns) in languagePatterns {
            let score = patterns.reduce(0) { count, pattern in
                count + (text.components(separatedBy: " ").filter { $0.contains(pattern) }.count)
            }
            
            if score > maxScore {
                maxScore = score
                detectedLang = lang
            }
        }
        
        return detectedLang
    }
    
    private func translateText(_ text: String, from sourceLanguage: String, to targetLanguage: SupportedLanguage) throws -> String {
        // Simple translation simulation
        // In a real app, you would use a translation API like Google Translate, Microsoft Translator, etc.
        
        if sourceLanguage == targetLanguage.rawValue {
            return text
        }
        
        // Simulate translation based on language pairs
        let translatedText = simulateTranslation(text, from: sourceLanguage, to: targetLanguage.rawValue)
        
        return translatedText
    }
    
    private func simulateTranslation(_ text: String, from sourceLanguage: String, to targetLanguage: String) -> String {
        // This is a simple simulation - in a real app you would use a proper translation service
        let translations = [
            "tr-en": "Translated to English: \(text)",
            "en-tr": "Türkçeye çevrildi: \(text)",
            "tr-es": "Traducido al español: \(text)",
            "es-tr": "Türkçeye çevrildi: \(text)",
            "tr-fr": "Traduit en français: \(text)",
            "fr-tr": "Türkçeye çevrildi: \(text)",
            "tr-de": "Ins Deutsche übersetzt: \(text)",
            "de-tr": "Türkçeye çevrildi: \(text)",
            "tr-it": "Tradotto in italiano: \(text)",
            "it-tr": "Türkçeye çevrildi: \(text)",
            "tr-pt": "Traduzido para português: \(text)",
            "pt-tr": "Türkçeye çevrildi: \(text)",
            "tr-ru": "Переведено на русский: \(text)",
            "ru-tr": "Türkçeye çevrildi: \(text)",
            "tr-zh": "翻译成中文: \(text)",
            "zh-tr": "Türkçeye çevrildi: \(text)",
            "tr-ja": "日本語に翻訳: \(text)",
            "ja-tr": "Türkçeye çevrildi: \(text)",
            "tr-ko": "한국어로 번역: \(text)",
            "ko-tr": "Türkçeye çevrildi: \(text)",
            "tr-ar": "ترجم إلى العربية: \(text)",
            "ar-tr": "Türkçeye çevrildi: \(text)"
        ]
        
        let key = "\(sourceLanguage)-\(targetLanguage)"
        return translations[key] ?? "Çeviri: \(text)"
    }
    
    func clearResults() {
        lastResult = nil
        errorMessage = nil
    }
    
    func getSupportedLanguages() -> [SupportedLanguage] {
        return SupportedLanguage.allCases
    }
}
