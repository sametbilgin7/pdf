//
//  PaywallView.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI
import RevenueCat
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var revenueCatService = RevenueCatService.shared
    @State private var selectedPackage: Package?
    @State private var selectedFallbackPlan: String = "lifetime_fallback"
    @State private var crownScale: CGFloat = 1.0
    @State private var crownTilt: Bool = false
    @State private var glowPulse: Bool = false
    @State private var isProcessing = false
    @State private var dragOffsetY: CGFloat = 0
    @State private var buttonJiggle: Bool = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 24) {
                // Crown and title
                VStack(spacing: 20) {
                    ZStack {
                        // Glow effect behind crown (soft pulse)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 80, weight: .bold))
                            .foregroundColor(.yellow)
                            .opacity(glowPulse ? 0.28 : 0.16)
                            .blur(radius: glowPulse ? 12 : 8)
                            .scaleEffect(glowPulse ? 1.12 : 1.06)
                            .animation(
                                .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                                value: glowPulse
                            )
                        
                        // Main crown with subtle tilt + slight scale
                        Image(systemName: "crown.fill")
                            .font(.system(size: 80, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .yellow.opacity(0.55), radius: 10, x: 0, y: 0)
                            .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 4)
                            .rotationEffect(.degrees(crownTilt ? 4.5 : -4.5))
                            .scaleEffect(crownTilt ? 1.04 : 1.0)
                            .animation(
                                .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                                value: crownTilt
                            )
                    }
                    
                    Text("Open Premium".localized)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .allowsTightening(true)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 20)
                .onAppear {
                    crownScale = 1.02
                    crownTilt.toggle()
                    glowPulse.toggle()
                }
                
                // Benefits tailored to the app
                VStack(alignment: .leading, spacing: 18) {
                    benefitRow(icon: "doc.text.viewfinder", text: "Unlimited PDF Scanning".localized)
                    benefitRow(icon: "slider.horizontal.3", text: "Advanced OCR Technology".localized)
                    benefitRow(icon: "text.magnifyingglass", text: "Smart Text Recognition".localized)
                    benefitRow(icon: "star.fill", text: "Premium Features".localized)
                }
                .padding(.horizontal, 24)
                
                // Plans
                if let offerings = revenueCatService.offerings, let current = offerings.current {
                    VStack(spacing: 12) {
                        ForEach(current.availablePackages, id: \.identifier) { package in
                            planRow(
                                title: package.planType.localizedTitle,
                                subtitle: revenueCatService.getLocalizedPrice(for: package),
                                tag: package.identifier.contains("yearly") || package.identifier.contains("annual") ? "83% SAVING".localized : 
                                     package.identifier.contains("lifetime") ? "BEST VALUE".localized : nil,
                                isSelected: selectedPackage?.identifier == package.identifier
                            ) {
                                selectedPackage = package
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                } else if revenueCatService.isLoading {
                    ProgressView("Loading plans...".localized)
                        .padding()
                } else {
                    // Fallback plans if RevenueCat fails
                    VStack(spacing: 12) {
                        planRow(
                            title: "Weekly".localized, 
                            subtitle: "₺29,99/hafta", 
                            tag: nil, 
                            isSelected: selectedFallbackPlan == "weekly_fallback"
                        ) { 
                            selectedFallbackPlan = "weekly_fallback"
                        }
                        planRow(
                            title: "Yearly".localized, 
                            subtitle: "₺199,99/yıl", 
                            tag: "83% SAVING".localized, 
                            isSelected: selectedFallbackPlan == "yearly_fallback"
                        ) { 
                            selectedFallbackPlan = "yearly_fallback"
                        }
                        planRow(
                            title: "Lifetime".localized, 
                            subtitle: "₺499,99 tek seferlik", 
                            tag: "BEST VALUE".localized, 
                            isSelected: selectedFallbackPlan == "lifetime_fallback"
                        ) { 
                            selectedFallbackPlan = "lifetime_fallback"
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                
                // CTA Button
                Button(action: purchaseSelected) {
                    HStack {
                        Spacer()
                        Text("Open Now".localized)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .semibold))
                        Spacer()
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .rotationEffect(.degrees(buttonJiggle ? 2 : 0))
                .scaleEffect(buttonJiggle ? 1.05 : 1.0)
                .animation(
                    .easeInOut(duration: 0.3).repeatForever(autoreverses: true),
                    value: buttonJiggle
                )
                .onAppear {
                    startButtonJiggle()
                }
                
                // Footer links
                HStack(spacing: 28) {
                    Button("Restore".localized) {
                        restorePurchases()
                    }
                    Menu {
                        Button("Privacy Policy".localized) {
                            if let url = URL(string: "https://developing-comet-b87.notion.site/privacy-policy-pdf-scanner-2931f542e1a380eaa045cdb24aa511a2?source=copy_link") {
                                UIApplication.shared.open(url)
                            }
                        }
                        Divider()
                        Button("Terms of Use".localized) {
                            if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                                UIApplication.shared.open(url)
                            }
                        }
                    } label: {
                        Text("Terms & Privacy")
                    }
                }
                .font(.system(size: 13))
                .foregroundColor(.black.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                
                Spacer(minLength: 10)
            }
            .offset(y: dragOffsetY)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        if value.translation.height > 0 { dragOffsetY = value.translation.height }
                    }
                    .onEnded { value in
                        if value.translation.height > 120 { dismiss() }
                        dragOffsetY = 0
                    }
            )
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black.opacity(0.85))
                    .frame(width: 36, height: 36)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(Circle())
            }
            .contentShape(Rectangle())
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 20)
            .padding(.top, 10)
        }
        .interactiveDismissDisabled(false)
    }
    
    @ViewBuilder
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .foregroundColor(.black)
                .font(.system(size: 17))
        }
    }
    
    @ViewBuilder
    private func planRow(title: String, subtitle: String, tag: String?, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundColor(.black)
                        .font(.system(size: 17, weight: .semibold))
                    Text(subtitle)
                        .foregroundColor(.black.opacity(0.7))
                        .font(.system(size: 14))
                }
                Spacer()
                if let tag = tag {
                    Text(tag)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.system(size: 22))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? .blue : Color.black.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func purchaseSelected() {
        // RevenueCat paketleri varsa onları kullan
        if let selectedPackage = selectedPackage {
            isProcessing = true
            HapticManager.light()
            
            revenueCatService.purchasePackage(selectedPackage)
            
            // Listen for purchase completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if !revenueCatService.isLoading {
                    isProcessing = false
                    if revenueCatService.isPremiumActive {
                        HapticManager.success()
                        dismiss()
                    } else if let error = revenueCatService.errorMessage {
                        print("❌ Purchase failed: \(error)")
                    }
                }
            }
        } else {
            // Fallback planlar için uyarı göster
            print("⚠️ RevenueCat not available, using fallback plans")
            // Burada fallback planlar için özel işlem yapabilirsiniz
        }
    }
    
    private func restorePurchases() {
        isProcessing = true
        HapticManager.light()
        
        revenueCatService.restorePurchases()
        
        // Listen for restore completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if !revenueCatService.isLoading {
                isProcessing = false
                if revenueCatService.isPremiumActive {
                    HapticManager.success()
                    dismiss()
                } else if let error = revenueCatService.errorMessage {
                    print("❌ Restore failed: \(error)")
                }
            }
        }
    }
    
    private func startButtonJiggle() {
        withAnimation(
            .easeInOut(duration: 0.3)
                .repeatForever(autoreverses: true)
        ) {
            buttonJiggle = true
        }
    }
    
}


#Preview {
    PaywallView()
}