//
//  OCRService.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import Foundation
import UIKit
import Vision
import Combine

enum OCRLanguage: String, CaseIterable, Identifiable {
    case english = "en-US"
    case turkish = "tr-TR"
    case auto = "auto"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .turkish:
            return "Türkçe"
        case .auto:
            return "Auto Detect"
        }
    }
}

enum OCRError: Error, LocalizedError {
    case imageConversionFailed
    case textRecognitionFailed(String)
    case noTextFound
    case unsupportedImageFormat
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image for OCR processing."
        case .textRecognitionFailed(let reason):
            return "Text recognition failed: \(reason)"
        case .noTextFound:
            return "No text found in the image."
        case .unsupportedImageFormat:
            return "Unsupported image format for OCR processing."
        }
    }
}

struct OCRResult {
    let text: String
    let confidence: Float
    let language: String
    let processingTime: TimeInterval
    let boundingBoxes: [CGRect]
    
    var formattedText: String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var confidencePercentage: Int {
        return Int(confidence * 100)
    }
}

class OCRService: ObservableObject {
    @Published var isProcessing = false
    @Published var lastResult: OCRResult?
    @Published var errorMessage: String?
    
    private let visionQueue = DispatchQueue(label: "com.modernpdfscanner.ocr", qos: .userInitiated)
    
    func recognizeText(from image: UIImage, language: OCRLanguage = .auto) async throws -> OCRResult {
        await MainActor.run {
            self.isProcessing = true
            self.errorMessage = nil
        }
        
        let startTime = Date()
        
        return try await withCheckedThrowingContinuation { continuation in
            visionQueue.async {
                do {
                    let result = try self.performTextRecognition(on: image, language: language)
                    let processingTime = Date().timeIntervalSince(startTime)
                    
                    let ocrResult = OCRResult(
                        text: result.text,
                        confidence: result.confidence,
                        language: result.language,
                        processingTime: processingTime,
                        boundingBoxes: result.boundingBoxes
                    )
                    
                    Task { @MainActor in
                        self.isProcessing = false
                        self.lastResult = ocrResult
                        continuation.resume(returning: ocrResult)
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
    
    private func performTextRecognition(on image: UIImage, language: OCRLanguage) throws -> (text: String, confidence: Float, language: String, boundingBoxes: [CGRect]) {
        guard let cgImage = image.cgImage else {
            throw OCRError.imageConversionFailed
        }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("OCR Error: \(error.localizedDescription)")
            }
        }
        
        // Configure recognition settings
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = (language == .auto)
        
        // Set specific language if not auto-detect
        if language != .auto {
            request.recognitionLanguages = [language.rawValue]
        } else {
            // For auto-detect, use both English and Turkish
            request.recognitionLanguages = [OCRLanguage.english.rawValue, OCRLanguage.turkish.rawValue]
        }
        
        // Set minimum text height for better accuracy
        request.minimumTextHeight = 0.01
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            throw OCRError.textRecognitionFailed(error.localizedDescription)
        }
        
        guard let observations = request.results, !observations.isEmpty else {
            throw OCRError.noTextFound
        }
        
        var recognizedText = ""
        var totalConfidence: Float = 0
        var boundingBoxes: [CGRect] = []
        var detectedLanguage = "unknown"
        
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            
            recognizedText += topCandidate.string + "\n"
            totalConfidence += topCandidate.confidence
            
            // Get bounding box
            let boundingBox = observation.boundingBox
            boundingBoxes.append(boundingBox)
        }
        
        let averageConfidence = totalConfidence / Float(observations.count)
        
        // Try to detect language from the text
        if language == .auto {
            detectedLanguage = detectLanguage(from: recognizedText)
        } else {
            detectedLanguage = language.rawValue
        }
        
        return (
            text: recognizedText,
            confidence: averageConfidence,
            language: detectedLanguage,
            boundingBoxes: boundingBoxes
        )
    }
    
    private func detectLanguage(from text: String) -> String {
        let text = text.lowercased()
        
        // Simple language detection based on common words
        let turkishWords = ["ve", "bir", "bu", "ile", "için", "olan", "olan", "gibi", "daha", "çok", "en", "da", "de", "ki", "mi", "mı", "mu", "mü"]
        let englishWords = ["the", "and", "is", "in", "to", "of", "a", "that", "it", "with", "for", "as", "was", "on", "are", "but", "not", "what", "all", "were"]
        
        let turkishCount = turkishWords.reduce(0) { count, word in
            count + (text.components(separatedBy: " ").filter { $0.contains(word) }.count)
        }
        
        let englishCount = englishWords.reduce(0) { count, word in
            count + (text.components(separatedBy: " ").filter { $0.contains(word) }.count)
        }
        
        return turkishCount > englishCount ? OCRLanguage.turkish.rawValue : OCRLanguage.english.rawValue
    }
    
    func clearResults() {
        lastResult = nil
        errorMessage = nil
    }
    
    func getSupportedLanguages() -> [OCRLanguage] {
        return OCRLanguage.allCases
    }
}
