//
//  ImageEditView.swift
//  ModernPDFScanner
//
//  Created by samet bilgin on 15.10.2025.
//

import SwiftUI

struct ImageEditView: View {
    @StateObject private var viewModel: ImageEditViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingSaveAlert = false
    @State private var savedImage: UIImage?
    @State private var showingOCRView = false
    
    let onSave: (UIImage) -> Void
    
    init(image: UIImage, onSave: @escaping (UIImage) -> Void) {
        self._viewModel = StateObject(wrappedValue: ImageEditViewModel(image: image))
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Image Preview
                ZStack {
                    Color.black.opacity(0.1)
                    
                    if viewModel.isProcessing {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Processing...".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Image(uiImage: viewModel.editedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 400)
                            .cornerRadius(12)
                            .shadow(radius: 8)
                    }
                }
                .frame(maxHeight: 400)
                .padding()
                
                // Edit Controls
                ScrollView {
                    VStack(spacing: 24) {
                        // Basic Adjustments
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Basic Adjustments".localized)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            // Brightness
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Brightness".localized)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(Int(viewModel.brightness * 100))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Slider(value: $viewModel.brightness, in: -1...1, step: 0.1)
                                    .accentColor(.blue)
                                    .onChange(of: viewModel.brightness) { _ in
                                        viewModel.applyFilters()
                                    }
                            }
                            
                            // Contrast
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Contrast".localized)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(Int(viewModel.contrast * 100))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Slider(value: $viewModel.contrast, in: 0.1...3, step: 0.1)
                                    .accentColor(.blue)
                                    .onChange(of: viewModel.contrast) { _ in
                                        viewModel.applyFilters()
                                    }
                            }
                            
                            // Saturation
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Saturation".localized)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(Int(viewModel.saturation * 100))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Slider(value: $viewModel.saturation, in: 0...2, step: 0.1)
                                    .accentColor(.blue)
                                    .onChange(of: viewModel.saturation) { _ in
                                        viewModel.applyFilters()
                                    }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Grayscale Toggle
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Effects".localized)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Toggle("Grayscale".localized, isOn: $viewModel.isGrayscale)
                                .font(.subheadline)
                                .onChange(of: viewModel.isGrayscale) { _ in
                                    viewModel.applyFilters()
                                }
                        }
                        .padding(.horizontal)
                        
                        // Color Filters
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Color Filters".localized)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(ImageFilter.allCases, id: \.self) { filter in
                                        FilterButton(
                                            filter: filter,
                                            isSelected: viewModel.selectedFilter == filter
                                        ) {
                                            viewModel.selectedFilter = filter
                                            viewModel.applyFilters()
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            // OCR Button
                            Button(action: {
                                showingOCRView = true
                            }) {
                                HStack {
                                    Image(systemName: "text.viewfinder")
                                    Text("Recognize Text".localized)
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.purple)
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                viewModel.resetFilters()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Reset")
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                let editedImage = viewModel.saveEditedImage()
                                onSave(editedImage)
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "checkmark")
                                    Text("Save Changes")
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Edit Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingOCRView) {
            OCRView(image: viewModel.editedImage)
        }
    }
}

struct FilterButton: View {
    let filter: ImageFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
                
                Text(filter.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ImageEditView(image: UIImage(systemName: "photo")!) { _ in }
}
