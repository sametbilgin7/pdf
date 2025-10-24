//
//  pdfApp.swift
//  pdf
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI

@main
struct pdfApp: App {
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    
    var body: some Scene {
        WindowGroup {
            if onboardingViewModel.isOnboardingCompleted {
                MainTabView()
            } else {
                OnboardingView()
                    .environmentObject(onboardingViewModel)
            }
        }
    }
}
