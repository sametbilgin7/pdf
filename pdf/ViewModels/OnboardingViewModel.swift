//
//  OnboardingViewModel.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI
import Combine

class OnboardingViewModel: ObservableObject {
    @Published var currentPageIndex: Int = 0
    @Published var isOnboardingCompleted: Bool = false
    @Published var showSkipButton: Bool = true
    @Published var animationOffset: CGFloat = 0
    @Published var animationOpacity: Double = 1.0
    
    private let totalPages = OnboardingData.pages.count
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Check if onboarding was already completed
        isOnboardingCompleted = UserDefaults.standard.bool(forKey: "onboarding_completed")
    }
    
    var currentPage: OnboardingPage {
        guard currentPageIndex >= 0 && currentPageIndex < OnboardingData.pages.count else {
            print("⚠️ Index out of range: \(currentPageIndex), pages count: \(OnboardingData.pages.count)")
            return OnboardingData.pages[0] // Fallback to first page
        }
        return OnboardingData.pages[currentPageIndex]
    }
    
    var isLastPage: Bool {
        currentPageIndex == totalPages - 1
    }
    
    var isFirstPage: Bool {
        currentPageIndex == 0
    }
    
    var progressPercentage: Double {
        Double(currentPageIndex + 1) / Double(totalPages)
    }
    
    func nextPage() {
        print("🔄 Next page called. Current: \(currentPageIndex), Total: \(totalPages)")
        
        // Güvenlik kontrolü
        guard currentPageIndex >= 0 && currentPageIndex < totalPages else {
            print("❌ Invalid page index: \(currentPageIndex)")
            return
        }
        
        guard currentPageIndex < totalPages - 1 else {
            print("✅ Last page reached, completing onboarding")
            completeOnboarding()
            return
        }
        
        print("➡️ Moving to next page")
        withAnimation(.easeInOut(duration: 0.5)) {
            animationOffset = -UIScreen.main.bounds.width
            animationOpacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.currentPageIndex += 1
            self.animationOffset = UIScreen.main.bounds.width
            self.animationOpacity = 0.0
            
            withAnimation(.easeInOut(duration: 0.5)) {
                self.animationOffset = 0
                self.animationOpacity = 1.0
            }
        }
    }
    
    func previousPage() {
        print("⬅️ Previous page called. Current: \(currentPageIndex)")
        
        // Güvenlik kontrolü
        guard currentPageIndex > 0 && currentPageIndex < totalPages else {
            print("❌ Cannot go to previous page. Current: \(currentPageIndex)")
            return
        }
        
        print("⬅️ Moving to previous page")
        withAnimation(.easeInOut(duration: 0.5)) {
            animationOffset = UIScreen.main.bounds.width
            animationOpacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.currentPageIndex -= 1
            self.animationOffset = -UIScreen.main.bounds.width
            self.animationOpacity = 0.0
            
            withAnimation(.easeInOut(duration: 0.5)) {
                self.animationOffset = 0
                self.animationOpacity = 1.0
            }
        }
    }
    
    func skipOnboarding() {
        print("⏭️ Skip onboarding called")
        completeOnboarding()
    }
    
    private func completeOnboarding() {
        print("🎉 Completing onboarding")
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
        withAnimation(.easeInOut(duration: 0.8)) {
            isOnboardingCompleted = true
        }
    }
    
    func resetOnboarding() {
        print("🔄 Resetting onboarding")
        UserDefaults.standard.set(false, forKey: "onboarding_completed")
        currentPageIndex = 0
        isOnboardingCompleted = false
        animationOffset = 0
        animationOpacity = 1.0
        print("✅ Onboarding reset complete. Current page: \(currentPageIndex)")
    }
}
