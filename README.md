# ModernPDFScanner

Modern PDF Scanner uygulaması SwiftUI ve MVVM mimarisi kullanılarak geliştirilmiştir.

## Proje Yapısı

```
pdf/
├── Views/
│   ├── HomeView.swift              # Ana ekran - "Scan Document" butonu
│   └── DocumentScannerView.swift   # VisionKit entegrasyonu
├── ViewModels/
│   └── HomeViewModel.swift         # Ana ekran view model
├── Models/
│   ├── ScannedDocument.swift       # Taranan belge modeli
│   └── PDFDocument.swift          # PDF belge modeli
├── Services/
│   └── DocumentService.swift       # Belge işlemleri servisi
├── Assets.xcassets/               # Uygulama varlıkları
├── Info.plist                     # Uygulama izinleri
└── ModernPDFScannerApp.swift      # Ana uygulama dosyası
```

## Özellikler

- **MVVM Mimarisi**: Temiz ve sürdürülebilir kod yapısı
- **VisionKit Entegrasyonu**: Apple'ın yerleşik belge tarama API'si
- **PDFKit Desteği**: PDF oluşturma ve yönetimi
- **Modern SwiftUI**: iOS 17+ için optimize edilmiş arayüz

## Gerekli İzinler

Info.plist dosyasında tanımlanan izinler:
- `NSCameraUsageDescription`: Kamera erişimi için
- `NSPhotoLibraryAddUsageDescription`: Fotoğraf kütüphanesine kaydetme için
- `NSPhotoLibraryUsageDescription`: Fotoğraf kütüphanesinden okuma için

## Kullanılan Framework'ler

- **VisionKit**: Belge tarama işlemleri
- **PDFKit**: PDF oluşturma ve yönetimi
- **SwiftUI**: Kullanıcı arayüzü
- **Combine**: Reactive programming

## Kurulum

1. Xcode'da projeyi açın
2. iOS 17+ simülatör veya cihaz seçin
3. Build ve Run (⌘+R)

## Geliştirme Notları

- Minimum iOS sürümü: 17.0
- Swift sürümü: 5.9
- Xcode sürümü: 15.0+
