//
//  PDFGeneratorService.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import Foundation
import UIKit
import PDFKit

class PDFGeneratorService {
    
    func generatePDF(from images: [UIImage], fileName: String = "ScannedDocument") async throws -> URL {
        guard !images.isEmpty else {
            throw PDFGenerationError.noImages
        }
        
        // Create PDF document
        let pdfDocument = PDFKit.PDFDocument()
        
        // Add each image as a page
        for (index, image) in images.enumerated() {
            // Create PDF page from image
            let pdfPage = createPDFPage(from: image)
            pdfDocument.insert(pdfPage, at: index)
        }
        
        // Generate unique filename
        let timestamp = DateFormatter.timestamp.string(from: Date())
        let finalFileName = "\(fileName)_\(timestamp).pdf"
        
        // Get documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pdfURL = documentsDirectory.appendingPathComponent(finalFileName)
        
        // Save PDF to file
        guard pdfDocument.write(to: pdfURL) else {
            throw PDFGenerationError.saveFailed
        }
        
        return pdfURL
    }
    
    private func createPDFPage(from image: UIImage) -> PDFPage {
        // Get image size
        let imageSize = image.size
        
        // Limit maximum page size to smaller dimensions for mobile viewing
        let maxWidth: CGFloat = 300  // Even smaller for mobile
        let maxHeight: CGFloat = 400  // Even smaller for mobile
        
        var finalSize = imageSize
        
        // Scale down if image is too large
        if imageSize.width > maxWidth || imageSize.height > maxHeight {
            let scaleX = maxWidth / imageSize.width
            let scaleY = maxHeight / imageSize.height
            let scale = min(scaleX, scaleY)
            
            finalSize = CGSize(
                width: imageSize.width * scale,
                height: imageSize.height * scale
            )
        }
        
        // Create PDF page directly from image (simpler approach)
        let pdfPage = PDFPage(image: image)
        
        return pdfPage!
    }
    
    // Alternative method using CoreGraphics for better control
    func generatePDFWithCoreGraphics(from images: [UIImage], fileName: String = "ScannedDocument") async throws -> URL {
        guard !images.isEmpty else {
            throw PDFGenerationError.noImages
        }
        
        // Generate unique filename
        let timestamp = DateFormatter.timestamp.string(from: Date())
        let finalFileName = "\(fileName)_\(timestamp).pdf"
        
        // Get documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pdfURL = documentsDirectory.appendingPathComponent(finalFileName)
        
        // Create PDF context
        guard let pdfContext = CGContext(pdfURL as CFURL, mediaBox: nil, nil) else {
            throw PDFGenerationError.contextCreationFailed
        }
        
        // Add each image as a page
        for image in images {
            // Get image size
            let imageSize = image.size
            var pageRect = CGRect(origin: .zero, size: imageSize)
            
            // Begin new page
            pdfContext.beginPage(mediaBox: &pageRect)
            
            // Draw image
            if let cgImage = image.cgImage {
                pdfContext.draw(cgImage, in: pageRect)
            }
            
            // End page
            pdfContext.endPage()
        }
        
        // Close PDF context
        pdfContext.closePDF()
        
        return pdfURL
    }
    
    // Method to get PDF thumbnail
    func generatePDFThumbnail(from url: URL, size: CGSize = CGSize(width: 200, height: 280)) -> UIImage? {
        guard let pdfDocument = PDFKit.PDFDocument(url: url),
              let firstPage = pdfDocument.page(at: 0) else {
            return nil
        }
        
        let thumbnail = firstPage.thumbnail(of: size, for: .mediaBox)
        return thumbnail
    }
    
    // Method to get PDF page count
    func getPDFPageCount(from url: URL) -> Int {
        guard let pdfDocument = PDFKit.PDFDocument(url: url) else {
            return 0
        }
        return pdfDocument.pageCount
    }
}

// MARK: - Error Handling
enum PDFGenerationError: Error, LocalizedError {
    case noImages
    case saveFailed
    case contextCreationFailed
    case invalidImage
    
    var errorDescription: String? {
        switch self {
        case .noImages:
            return "No images provided for PDF generation"
        case .saveFailed:
            return "Failed to save PDF to file"
        case .contextCreationFailed:
            return "Failed to create PDF context"
        case .invalidImage:
            return "Invalid image provided"
        }
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let timestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()
}
