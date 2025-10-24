//
//  ImageFilterService.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

class ImageFilterService {
    private let context = CIContext()
    
    func applyFilters(
        to image: UIImage,
        brightness: Double,
        contrast: Double,
        saturation: Double,
        isGrayscale: Bool,
        filter: ImageFilter
    ) async throws -> UIImage {
        
        guard let ciImage = CIImage(image: image) else {
            throw ImageFilterError.invalidImage
        }
        
        var outputImage = ciImage
        
        // Apply basic adjustments
        outputImage = try applyBasicAdjustments(
            to: outputImage,
            brightness: brightness,
            contrast: contrast,
            saturation: saturation
        )
        
        // Apply grayscale if needed
        if isGrayscale {
            outputImage = try applyGrayscale(to: outputImage)
        }
        
        // Apply selected filter
        outputImage = try applyFilter(filter, to: outputImage)
        
        // Convert back to UIImage
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            throw ImageFilterError.renderingFailed
        }
        
        // Create UIImage with original orientation preserved
        let processedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
        return processedImage
    }
    
    private func applyBasicAdjustments(
        to image: CIImage,
        brightness: Double,
        contrast: Double,
        saturation: Double
    ) throws -> CIImage {
        
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = image
        colorControls.brightness = Float(brightness)
        colorControls.contrast = Float(contrast)
        colorControls.saturation = Float(saturation)
        
        guard let outputImage = colorControls.outputImage else {
            throw ImageFilterError.filterApplicationFailed
        }
        
        return outputImage
    }
    
    private func applyGrayscale(to image: CIImage) throws -> CIImage {
        let grayscale = CIFilter.colorMatrix()
        grayscale.inputImage = image
        grayscale.rVector = CIVector(x: 0.299, y: 0.587, z: 0.114, w: 0)
        grayscale.gVector = CIVector(x: 0.299, y: 0.587, z: 0.114, w: 0)
        grayscale.bVector = CIVector(x: 0.299, y: 0.587, z: 0.114, w: 0)
        grayscale.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        grayscale.biasVector = CIVector(x: 0, y: 0, z: 0, w: 0)
        
        guard let outputImage = grayscale.outputImage else {
            throw ImageFilterError.filterApplicationFailed
        }
        
        return outputImage
    }
    
    private func applyFilter(_ filter: ImageFilter, to image: CIImage) throws -> CIImage {
        switch filter {
        case .none:
            return image
            
        case .sepia:
            let sepiaFilter = CIFilter.sepiaTone()
            sepiaFilter.inputImage = image
            sepiaFilter.intensity = 0.8
            guard let outputImage = sepiaFilter.outputImage else {
                throw ImageFilterError.filterApplicationFailed
            }
            return outputImage
            
        case .vintage:
            let vintage = CIFilter.colorMatrix()
            vintage.inputImage = image
            vintage.rVector = CIVector(x: 0.9, y: 0.1, z: 0.0, w: 0)
            vintage.gVector = CIVector(x: 0.0, y: 0.8, z: 0.2, w: 0)
            vintage.bVector = CIVector(x: 0.0, y: 0.0, z: 0.7, w: 0)
            vintage.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
            vintage.biasVector = CIVector(x: 0.1, y: 0.1, z: 0.1, w: 0)
            guard let outputImage = vintage.outputImage else {
                throw ImageFilterError.filterApplicationFailed
            }
            return outputImage
            
        case .cool:
            let cool = CIFilter.colorMatrix()
            cool.inputImage = image
            cool.rVector = CIVector(x: 0.8, y: 0.0, z: 0.0, w: 0)
            cool.gVector = CIVector(x: 0.0, y: 0.9, z: 0.0, w: 0)
            cool.bVector = CIVector(x: 0.0, y: 0.0, z: 1.2, w: 0)
            cool.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
            cool.biasVector = CIVector(x: 0, y: 0, z: 0.1, w: 0)
            guard let outputImage = cool.outputImage else {
                throw ImageFilterError.filterApplicationFailed
            }
            return outputImage
            
        case .warm:
            let warm = CIFilter.colorMatrix()
            warm.inputImage = image
            warm.rVector = CIVector(x: 1.2, y: 0.0, z: 0.0, w: 0)
            warm.gVector = CIVector(x: 0.0, y: 1.0, z: 0.0, w: 0)
            warm.bVector = CIVector(x: 0.0, y: 0.0, z: 0.8, w: 0)
            warm.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
            warm.biasVector = CIVector(x: 0.1, y: 0.05, z: 0, w: 0)
            guard let outputImage = warm.outputImage else {
                throw ImageFilterError.filterApplicationFailed
            }
            return outputImage
            
        case .dramatic:
            let dramatic = CIFilter.colorMatrix()
            dramatic.inputImage = image
            dramatic.rVector = CIVector(x: 1.3, y: 0.0, z: 0.0, w: 0)
            dramatic.gVector = CIVector(x: 0.0, y: 1.1, z: 0.0, w: 0)
            dramatic.bVector = CIVector(x: 0.0, y: 0.0, z: 0.9, w: 0)
            dramatic.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
            dramatic.biasVector = CIVector(x: -0.1, y: -0.1, z: -0.1, w: 0)
            guard let outputImage = dramatic.outputImage else {
                throw ImageFilterError.filterApplicationFailed
            }
            return outputImage
        }
    }
}

enum ImageFilterError: Error, LocalizedError {
    case invalidImage
    case filterApplicationFailed
    case renderingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image provided"
        case .filterApplicationFailed:
            return "Failed to apply filter"
        case .renderingFailed:
            return "Failed to render processed image"
        }
    }
}
