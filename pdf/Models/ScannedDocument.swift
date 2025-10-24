//
//  ScannedDocument.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import Foundation
import UIKit

struct ScannedDocument: Identifiable, Codable {
    let id: UUID
    let name: String
    let createdAt: Date
    let pageCount: Int
    let thumbnailData: Data?
    
    init(name: String, pageCount: Int, thumbnail: UIImage?) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.pageCount = pageCount
        self.thumbnailData = thumbnail?.jpegData(compressionQuality: 0.3)
    }
    
    var thumbnail: UIImage? {
        guard let data = thumbnailData else { return nil }
        return UIImage(data: data)
    }
}
