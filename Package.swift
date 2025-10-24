// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ModernPDFScanner",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ModernPDFScanner",
            targets: ["ModernPDFScanner"]),
    ],
    dependencies: [
        // No external dependencies needed for VisionKit and PDFKit
        // They are built-in iOS frameworks
    ],
    targets: [
        .target(
            name: "ModernPDFScanner",
            dependencies: [],
            path: "pdf"
        ),
        .testTarget(
            name: "ModernPDFScannerTests",
            dependencies: ["ModernPDFScanner"],
            path: "pdfTests"
        ),
    ]
)
