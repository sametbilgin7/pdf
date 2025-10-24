//
//  PDFDocument.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import Foundation
import PDFKit

struct PDFDocument: Identifiable, Codable {
    let id: UUID
    let name: String
    let url: URL
    let createdAt: Date
    let pageCount: Int
    
    init(name: String, url: URL, pageCount: Int) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.createdAt = Date()
        self.pageCount = pageCount
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, url, createdAt, pageCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        url = try container.decode(URL.self, forKey: .url)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        pageCount = try container.decode(Int.self, forKey: .pageCount)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(url, forKey: .url)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(pageCount, forKey: .pageCount)
    }
}

// MARK: - Folder Model
struct Folder: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var createdAt: Date
    var pdfFileURLs: [URL] // PDF file URLs in this folder
    
    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), pdfFileURLs: [URL] = []) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.pdfFileURLs = pdfFileURLs
    }
    
    var documentCount: Int {
        return pdfFileURLs.count
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, name, createdAt, pdfFileNames
    }
    
    // Custom encoding to save only filenames (not full paths)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(createdAt, forKey: .createdAt)
        
        // Only save the filenames, not full URLs
        let filenames = pdfFileURLs.map { $0.lastPathComponent }
        try container.encode(filenames, forKey: .pdfFileNames)
    }
    
    // Custom decoding to reconstruct URLs from filenames
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Try new format first (filenames only)
        if let filenames = try? container.decode([String].self, forKey: .pdfFileNames) {
            pdfFileURLs = filenames.map { documentsDirectory.appendingPathComponent($0) }
            print("📂 Decoded folder '\(name)' with \(filenames.count) files (new format):")
            for filename in filenames {
                print("  - \(filename)")
            }
        } else {
            // Fallback to old format (full URLs) and migrate
            print("⚠️ Old format detected for folder '\(name)', migrating...")
            
            // Try to decode old format with "pdfFileURLs" key using a separate container
            enum OldCodingKeys: String, CodingKey {
                case id, name, createdAt, pdfFileURLs
            }
            
            let oldContainer = try decoder.container(keyedBy: OldCodingKeys.self)
            if let oldURLs = try? oldContainer.decode([URL].self, forKey: .pdfFileURLs) {
                // Extract filenames from old URLs and reconstruct with current documents directory
                let filenames = oldURLs.map { $0.lastPathComponent }
                pdfFileURLs = filenames.map { documentsDirectory.appendingPathComponent($0) }
                print("✅ Migrated \(filenames.count) files to new format")
            } else {
                // If all else fails, start with empty array
                pdfFileURLs = []
                print("⚠️ Could not decode folder URLs, starting with empty array")
            }
        }
    }
}
