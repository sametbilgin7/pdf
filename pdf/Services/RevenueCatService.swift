//
//  RevenueCatService.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import Foundation
import RevenueCat
import SwiftUI
import Combine

class RevenueCatService: ObservableObject {
    @Published var offerings: Offerings?
    @Published var customerInfo: CustomerInfo?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    static let shared = RevenueCatService()
    
    private init() {
        configureRevenueCat()
    }
    
    private func configureRevenueCat() {
        // RevenueCat yapılandırması
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_jycAVuFUPQgtXCQOaTycMUHyAei")
        
        // Mevcut kullanıcı bilgilerini al
        loadCustomerInfo()
        loadOfferings()
    }
    
    func loadOfferings() {
        isLoading = true
        errorMessage = nil
        
        Purchases.shared.getOfferings { [weak self] offerings, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    print("❌ RevenueCat offerings error: \(error)")
                } else if let offerings = offerings {
                    self?.offerings = offerings
                    print("✅ RevenueCat offerings loaded: \(offerings.all.count) packages")
                }
            }
        }
    }
    
    func loadCustomerInfo() {
        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ RevenueCat customer info error: \(error)")
                } else if let customerInfo = customerInfo {
                    self?.customerInfo = customerInfo
                    print("✅ RevenueCat customer info loaded")
                }
            }
        }
    }
    
    func purchasePackage(_ package: Package) {
        isLoading = true
        errorMessage = nil
        
        Purchases.shared.purchase(package: package) { [weak self] transaction, customerInfo, error, userCancelled in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if userCancelled {
                    print("ℹ️ User cancelled purchase")
                    return
                }
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    print("❌ Purchase error: \(error)")
                } else if let customerInfo = customerInfo {
                    self?.customerInfo = customerInfo
                    print("✅ Purchase successful")
                }
            }
        }
    }
    
    func restorePurchases() {
        isLoading = true
        errorMessage = nil
        
        Purchases.shared.restorePurchases { [weak self] customerInfo, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    print("❌ Restore error: \(error)")
                } else if let customerInfo = customerInfo {
                    self?.customerInfo = customerInfo
                    print("✅ Purchases restored")
                }
            }
        }
    }
    
    var isPremiumActive: Bool {
        return customerInfo?.entitlements.all["premium"]?.isActive == true
    }
    
    func getLocalizedPrice(for package: Package) -> String {
        return package.storeProduct.localizedPriceString
    }
    
    func getLocalizedTitle(for package: Package) -> String {
        return package.storeProduct.localizedTitle
    }
    
    func getLocalizedDescription(for package: Package) -> String {
        return package.storeProduct.localizedDescription
    }
}

// MARK: - Package Extensions
extension Package {
    var planType: PlanType {
        switch packageType {
        case .weekly:
            return .weekly
        case .annual:
            return .yearly
        default:
            // Lifetime için özel kontrol
            if identifier.contains("lifetime") {
                return .lifetime
            }
            return .yearly
        }
    }
}

enum PlanType: String, CaseIterable, Identifiable {
    case weekly
    case yearly
    case lifetime
    
    var id: String { rawValue }
    
    var localizedTitle: String {
        switch self {
        case .weekly:
            return "Weekly".localized
        case .yearly:
            return "Yearly".localized
        case .lifetime:
            return "Lifetime".localized
        }
    }
}
