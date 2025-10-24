//
//  ImageEditViewModel.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import Foundation
import SwiftUI
import Combine
import CoreImage
import CoreImage.CIFilterBuiltins

@MainActor
class ImageEditViewModel: ObservableObject {
    @Published var originalImage: UIImage
    @Published var editedImage: UIImage
    @Published var isProcessing = false
    
    // Filter parameters
    @Published var brightness: Double = 0.0
    @Published var contrast: Double = 1.0
    @Published var saturation: Double = 1.0
    @Published var isGrayscale: Bool = false
    @Published var selectedFilter: ImageFilter = .none
    
    private let filterService = ImageFilterService()
    
    init(image: UIImage) {
        self.originalImage = image
        self.editedImage = image
    }
    
    func applyFilters() {
        isProcessing = true
        
        Task {
            do {
                let processedImage = try await filterService.applyFilters(
                    to: originalImage,
                    brightness: brightness,
                    contrast: contrast,
                    saturation: saturation,
                    isGrayscale: isGrayscale,
                    filter: selectedFilter
                )
                
                await MainActor.run {
                    self.editedImage = processedImage
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    print("Error applying filters: \(error)")
                    self.isProcessing = false
                }
            }
        }
    }
    
    func resetFilters() {
        brightness = 0.0
        contrast = 1.0
        saturation = 1.0
        isGrayscale = false
        selectedFilter = .none
        editedImage = originalImage
    }
    
    func saveEditedImage() -> UIImage {
        return editedImage
    }
}

enum ImageFilter: String, CaseIterable {
    case none = "None"
    case sepia = "Sepia"
    case vintage = "Vintage"
    case cool = "Cool"
    case warm = "Warm"
    case dramatic = "Dramatic"
    
    var displayName: String {
        return self.rawValue
    }
}
