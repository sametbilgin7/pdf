//
//  ImageCropView.swift
//  ModernPDFScanner
//
//  A lightweight image cropper with draggable resizable rectangle
//

import SwiftUI

struct ImageCropView: View {
    let image: UIImage
    let onCancel: () -> Void
    let onCropped: (UIImage) -> Void
    
    @State private var cropRect: CGRect = .zero
    @State private var imageSize: CGSize = .zero
    @State private var isReady: Bool = false
    @State private var dragStartRect: CGRect = .zero
    @State private var handleStartRect: CGRect = .zero
    @State private var isDraggingOverlay = false
    @State private var isDraggingHandle = false
    
    private let handleSize: CGFloat = 18
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                GeometryReader { geo in
                    let container = geo.size
                    let imgAspect = image.size.width / max(1, image.size.height)
                    let containerAspect = container.width / max(1, container.height)
                    let displaySize: CGSize = {
                        if imgAspect > containerAspect {
                            let w = container.width
                            let h = w / imgAspect
                            return CGSize(width: w, height: h)
                        } else {
                            let h = container.height
                            let w = h * imgAspect
                            return CGSize(width: w, height: h)
                        }
                    }()
                    let xOffset = (container.width - displaySize.width) / 2
                    let yOffset = (container.height - displaySize.height) / 2

                    VStack {
                        Spacer(minLength: yOffset)
                        HStack {
                            Spacer(minLength: xOffset)
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: displaySize.width, height: displaySize.height)
                                .background(
                                    Color.clear.onAppear {
                                        if !isReady {
                                            imageSize = displaySize
                                            let inset: CGFloat = 24
                                            cropRect = CGRect(x: inset,
                                                              y: inset,
                                                              width: max(40, displaySize.width - inset * 2),
                                                              height: max(40, displaySize.height - inset * 2))
                                            isReady = true
                                        }
                                    }
                                )
                                .overlay(cropOverlay.frame(width: displaySize.width, height: displaySize.height))
                            Spacer(minLength: xOffset)
                        }
                        Spacer(minLength: yOffset)
                    }
                }
            }
            .navigationTitle("Kırp")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { onCancel() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Uygula") {
                        if let cropped = cropImage() { onCropped(cropped) }
                    }
                }
            }
        }
    }
    
    private var cropOverlay: some View {
        ZStack(alignment: .topLeading) {
            // Dim outside
            Path { path in
                let rect = CGRect(origin: .zero, size: imageSize)
                path.addRect(rect)
                path.addRect(cropRect)
            }
            .fill(Color.black.opacity(0.55), style: FillStyle(eoFill: true))
            
            // Border
            Rectangle()
                .path(in: cropRect)
                .stroke(Color.green, lineWidth: 2)
            
            // Handles
            ForEach(HandlePosition.allCases, id: \.self) { pos in
                handle(at: pos)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isDraggingOverlay { isDraggingOverlay = true; dragStartRect = cropRect }
                    var newRect = dragStartRect
                    newRect.origin.x += value.translation.width
                    newRect.origin.y += value.translation.height
                    cropRect = normalized(rect: newRect)
                }
                .onEnded { _ in
                    isDraggingOverlay = false
                }
        )
    }
    
    private func handle(at position: HandlePosition) -> some View {
        let point = position.point(for: cropRect)
        return Circle()
            .fill(Color.green)
            .frame(width: handleSize, height: handleSize)
            .position(point)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isDraggingHandle { isDraggingHandle = true; handleStartRect = cropRect }
                        var rect = handleStartRect
                        position.update(rect: &rect, with: value.translation)
                        cropRect = normalized(rect: rect)
                    }
                    .onEnded { _ in
                        isDraggingHandle = false
                    }
            )
    }
    
    private func normalized(rect: CGRect) -> CGRect {
        var r = rect.standardized
        r.origin.x = max(0, min(r.origin.x, imageSize.width - 1))
        r.origin.y = max(0, min(r.origin.y, imageSize.height - 1))
        r.size.width = max(40, min(r.size.width, imageSize.width - r.origin.x))
        r.size.height = max(40, min(r.size.height, imageSize.height - r.origin.y))
        return r
    }
    
    private func cropImage() -> UIImage? {
        // Map cropRect (in displayed image space) to actual image pixel space
        guard imageSize.width > 0, imageSize.height > 0 else { return nil }
        let scaleX = image.size.width / imageSize.width
        let scaleY = image.size.height / imageSize.height
        let rectInPixels = CGRect(x: cropRect.origin.x * scaleX,
                                  y: cropRect.origin.y * scaleY,
                                  width: cropRect.size.width * scaleX,
                                  height: cropRect.size.height * scaleY)
        guard let cg = image.cgImage?.cropping(to: rectInPixels.integral) else { return nil }
        return UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
    }
}

private enum HandlePosition: CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight
    
    func point(for rect: CGRect) -> CGPoint {
        switch self {
        case .topLeft: return CGPoint(x: rect.minX, y: rect.minY)
        case .topRight: return CGPoint(x: rect.maxX, y: rect.minY)
        case .bottomLeft: return CGPoint(x: rect.minX, y: rect.maxY)
        case .bottomRight: return CGPoint(x: rect.maxX, y: rect.maxY)
        }
    }
    
    func update(rect: inout CGRect, with translation: CGSize) {
        switch self {
        case .topLeft:
            rect.origin.x += translation.width
            rect.origin.y += translation.height
            rect.size.width -= translation.width
            rect.size.height -= translation.height
        case .topRight:
            rect.origin.y += translation.height
            rect.size.width += translation.width
            rect.size.height -= translation.height
        case .bottomLeft:
            rect.origin.x += translation.width
            rect.size.width -= translation.width
            rect.size.height += translation.height
        case .bottomRight:
            rect.size.width += translation.width
            rect.size.height += translation.height
        }
    }
}

private struct ZoomableImage: View {
    let image: UIImage
    
    var body: some View {
        GeometryReader { geo in
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}


