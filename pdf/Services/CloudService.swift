//
//  CloudService.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import Foundation
import UIKit
import Combine
import SwiftUI

class CloudService: NSObject, ObservableObject {
    @Published var isCloudAvailable = false
    @Published var isSyncing = false
    @Published var syncError: String?
    @Published var cloudDocuments: [CloudDocument] = []
    
    private let fileManager = FileManager.default
    private var ubiquityContainerURL: URL?
    private var documentsDirectory: URL?
    private var metadataQuery: NSMetadataQuery?
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupCloudAccess()
    }
    
    // MARK: - Cloud Setup
    private func setupCloudAccess() {
        // Check if iCloud is available
        if let ubiquityURL = fileManager.url(forUbiquityContainerIdentifier: nil) {
            ubiquityContainerURL = ubiquityURL
            documentsDirectory = ubiquityURL.appendingPathComponent("Documents")
            isCloudAvailable = true
            
            // Create Documents directory if it doesn't exist
            createDocumentsDirectoryIfNeeded()
            
            // Start monitoring for changes
            startMetadataQuery()
        } else {
            isCloudAvailable = false
            syncError = "iCloud is not available"
        }
    }
    
    private func createDocumentsDirectoryIfNeeded() {
        guard let documentsDir = documentsDirectory else { return }
        
        do {
            try fileManager.createDirectory(at: documentsDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            syncError = "Failed to create iCloud Documents directory: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Metadata Query
    private func startMetadataQuery() {
        guard isCloudAvailable else { return }
        
        metadataQuery = NSMetadataQuery()
        metadataQuery?.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        metadataQuery?.predicate = NSPredicate(format: "%K LIKE '*.pdf'", NSMetadataItemFSNameKey)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(metadataQueryDidFinishGathering),
            name: .NSMetadataQueryDidFinishGathering,
            object: metadataQuery
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(metadataQueryDidUpdate),
            name: .NSMetadataQueryDidUpdate,
            object: metadataQuery
        )
        
        metadataQuery?.start()
    }
    
    @objc private func metadataQueryDidFinishGathering() {
        updateCloudDocuments()
    }
    
    @objc private func metadataQueryDidUpdate() {
        updateCloudDocuments()
    }
    
    private func updateCloudDocuments() {
        guard let query = metadataQuery else { return }
        
        var documents: [CloudDocument] = []
        
        for i in 0..<query.resultCount {
            if let item = query.result(at: i) as? NSMetadataItem,
               let url = item.value(forAttribute: NSMetadataItemURLKey) as? URL {
                
                let document = CloudDocument(
                    url: url,
                    name: url.lastPathComponent,
                    isDownloaded: (item.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as? String) == NSMetadataUbiquitousItemDownloadingStatusCurrent,
                    hasUnresolvedConflicts: item.value(forAttribute: NSMetadataUbiquitousItemHasUnresolvedConflictsKey) as? Bool ?? false,
                    isUploaded: item.value(forAttribute: NSMetadataUbiquitousItemIsUploadedKey) as? Bool ?? false,
                    percentDownloaded: item.value(forAttribute: NSMetadataUbiquitousItemPercentDownloadedKey) as? Double ?? 0.0,
                    percentUploaded: item.value(forAttribute: NSMetadataUbiquitousItemPercentUploadedKey) as? Double ?? 0.0
                )
                
                documents.append(document)
            }
        }
        
        DispatchQueue.main.async {
            self.cloudDocuments = documents.sorted { $0.name < $1.name }
        }
    }
    
    // MARK: - Cloud Operations
    func uploadToCloud(_ localURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        guard isCloudAvailable, let documentsDir = documentsDirectory else {
            completion(.failure(CloudError.iCloudNotAvailable))
            return
        }
        
        isSyncing = true
        syncError = nil
        
        let cloudURL = documentsDir.appendingPathComponent(localURL.lastPathComponent)
        
        do {
            // Copy file to iCloud Documents
            try fileManager.copyItem(at: localURL, to: cloudURL)
            
            // Mark file for upload
            try fileManager.setUbiquitous(true, itemAt: cloudURL, destinationURL: cloudURL)
            
            DispatchQueue.main.async {
                self.isSyncing = false
                completion(.success(cloudURL))
            }
        } catch {
            DispatchQueue.main.async {
                self.isSyncing = false
                self.syncError = error.localizedDescription
                completion(.failure(error))
            }
        }
    }
    
    func downloadFromCloud(_ cloudURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        guard isCloudAvailable else {
            completion(.failure(CloudError.iCloudNotAvailable))
            return
        }
        
        isSyncing = true
        syncError = nil
        
        do {
            // Start downloading
            try fileManager.startDownloadingUbiquitousItem(at: cloudURL)
            
            // Wait for download to complete
            var isDownloaded = false
            var attempts = 0
            let maxAttempts = 30 // 30 seconds timeout
            
            while !isDownloaded && attempts < maxAttempts {
                Thread.sleep(forTimeInterval: 1.0)
                
                if let resourceValues = try? cloudURL.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey]) {
                    isDownloaded = resourceValues.ubiquitousItemDownloadingStatus == .current
                }
                
                attempts += 1
            }
            
            if isDownloaded {
                DispatchQueue.main.async {
                    self.isSyncing = false
                    completion(.success(cloudURL))
                }
            } else {
                DispatchQueue.main.async {
                    self.isSyncing = false
                    self.syncError = "Download timeout"
                    completion(.failure(CloudError.downloadTimeout))
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isSyncing = false
                self.syncError = error.localizedDescription
                completion(.failure(error))
            }
        }
    }
    
    func deleteFromCloud(_ cloudURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        guard isCloudAvailable else {
            completion(.failure(CloudError.iCloudNotAvailable))
            return
        }
        
        isSyncing = true
        syncError = nil
        
        do {
            try fileManager.removeItem(at: cloudURL)
            
            DispatchQueue.main.async {
                self.isSyncing = false
                completion(.success(()))
            }
        } catch {
            DispatchQueue.main.async {
                self.isSyncing = false
                self.syncError = error.localizedDescription
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Sync Status
    func getSyncStatus(for url: URL) -> CloudSyncStatus {
        guard isCloudAvailable else { return .notAvailable }
        
        do {
            let resourceValues = try url.resourceValues(forKeys: [
                .ubiquitousItemDownloadingStatusKey,
                .ubiquitousItemHasUnresolvedConflictsKey,
                .ubiquitousItemIsUploadedKey
            ])
            
            let isDownloaded = resourceValues.ubiquitousItemDownloadingStatus == .current
            let hasConflicts = resourceValues.ubiquitousItemHasUnresolvedConflicts ?? false
            let isUploaded = resourceValues.ubiquitousItemIsUploaded ?? false
            
            if hasConflicts {
                return .conflict
            } else if !isDownloaded {
                return .downloading
            } else if !isUploaded {
                return .uploading
            } else {
                return .synced
            }
        } catch {
            return .error
        }
    }
    
    // MARK: - Cleanup
    deinit {
        metadataQuery?.stop()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Cloud Document Model
struct CloudDocument: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let isDownloaded: Bool
    let hasUnresolvedConflicts: Bool
    let isUploaded: Bool
    let percentDownloaded: Double
    let percentUploaded: Double
    
    var displayName: String {
        return name.replacingOccurrences(of: ".pdf", with: "")
    }
    
    var syncStatus: CloudSyncStatus {
        if hasUnresolvedConflicts {
            return .conflict
        } else if !isDownloaded {
            return .downloading
        } else if !isUploaded {
            return .uploading
        } else {
            return .synced
        }
    }
}

// MARK: - Cloud Sync Status
enum CloudSyncStatus: String, CaseIterable {
    case synced = "synced"
    case downloading = "downloading"
    case uploading = "uploading"
    case conflict = "conflict"
    case error = "error"
    case notAvailable = "notAvailable"
    
    var displayName: String {
        switch self {
        case .synced: return "Synced"
        case .downloading: return "Downloading"
        case .uploading: return "Uploading"
        case .conflict: return "Conflict"
        case .error: return "Error"
        case .notAvailable: return "Not Available"
        }
    }
    
    var icon: String {
        switch self {
        case .synced: return "checkmark.icloud"
        case .downloading: return "arrow.down.icloud"
        case .uploading: return "arrow.up.icloud"
        case .conflict: return "exclamationmark.icloud"
        case .error: return "xmark.icloud"
        case .notAvailable: return "icloud.slash"
        }
    }
    
    var color: Color {
        switch self {
        case .synced: return .green
        case .downloading: return .blue
        case .uploading: return .orange
        case .conflict: return .red
        case .error: return .red
        case .notAvailable: return .gray
        }
    }
}

// MARK: - Cloud Errors
enum CloudError: Error, LocalizedError {
    case iCloudNotAvailable
    case downloadTimeout
    case uploadFailed
    case syncConflict
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud is not available"
        case .downloadTimeout:
            return "Download timeout"
        case .uploadFailed:
            return "Upload failed"
        case .syncConflict:
            return "Sync conflict detected"
        case .fileNotFound:
            return "File not found"
        }
    }
}
