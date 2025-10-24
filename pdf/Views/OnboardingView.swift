//
//  OnboardingView.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    viewModel.currentPage.primaryColor.opacity(0.1),
                    viewModel.currentPage.secondaryColor.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.8), value: viewModel.currentPageIndex)
            
            VStack(spacing: 0) {
                // Skip button
                if viewModel.showSkipButton && !viewModel.isLastPage {
                    HStack {
                        Spacer()
                        Button("Skip".localized) {
                            viewModel.skipOnboarding()
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                }
                
                // Main content
                TabView(selection: $viewModel.currentPageIndex) {
                    ForEach(OnboardingData.pages, id: \.id) { page in
                        OnboardingPageView(page: page)
                            .tag(page.id)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.5), value: viewModel.currentPageIndex)
                .offset(x: viewModel.animationOffset)
                .opacity(viewModel.animationOpacity)
                
                // Bottom section
                VStack(spacing: 24) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<OnboardingData.pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == viewModel.currentPageIndex ? 
                                      viewModel.currentPage.primaryColor : 
                                      Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == viewModel.currentPageIndex ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: viewModel.currentPageIndex)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        // Previous button
                        if !viewModel.isFirstPage {
                            Button(action: {
                                HapticManager.light()
                                viewModel.previousPage()
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Previous".localized)
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(25)
                            }
                        }
                        
                        Spacer()
                        
                        // Next/Get Started button
                        Button(action: {
                            HapticManager.light()
                            viewModel.nextPage()
                        }) {
                            HStack {
                                Text(viewModel.isLastPage ? "Get Started".localized : "Next".localized)
                                if !viewModel.isLastPage {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [
                                        viewModel.currentPage.primaryColor,
                                        viewModel.currentPage.secondaryColor
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: viewModel.currentPage.primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 50)
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                    }
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    isDragging = false
                    let threshold: CGFloat = 50
                    
                    if value.translation.width > threshold {
                        viewModel.previousPage()
                    } else if value.translation.width < -threshold {
                        viewModel.nextPage()
                    }
                    
                    withAnimation(.spring()) {
                        dragOffset = 0
                    }
                }
        )
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var iconScale: CGFloat = 0.8
    @State private var iconRotation: Double = 0
    @State private var textOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon/Image
            ZStack {
                // Background circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                page.primaryColor.opacity(0.2),
                                page.secondaryColor.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(iconScale)
                
                // Main icon
                Image(systemName: page.imageName)
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [page.primaryColor, page.secondaryColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(iconScale)
                    .rotationEffect(.degrees(iconRotation))
            }
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    iconScale = 1.0
                }
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    iconRotation = 5
                }
            }
            
            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)
                
                Text(page.subtitle)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(page.primaryColor)
                    .multilineTextAlignment(.center)
                    .opacity(textOpacity)
                
                Text(page.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .opacity(textOpacity)
            }
            .padding(.horizontal, 32)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                    textOpacity = 1.0
                }
            }
            
            Spacer()
        }
    }
}


#Preview {
    OnboardingView()
}
