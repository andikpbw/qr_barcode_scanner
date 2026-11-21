## 1.0.0

* Initial stable release of `flutter_qr_barcode_scanner`.
* **Zero External Dependencies & Flutter 3.50+ Future-Proof**: Built purely on `package:flutter/widgets.dart` with zero deprecated `package:flutter/material.dart` or `package:flutter/cupertino.dart` imports.
* **Real-Time Multi-Format Detection & Decoding Engine (`QrBarcodeDecoder`)**:
  * Pure-Dart real-time pixel & matrix decoding for **QR Code** (2D matrix with finder pattern localization, perspective grid sampling, and mask reversal), **EAN-13**, **EAN-8**, **UPC-A**, **UPC-E**, **Code-128**, **Code-39**, **ITF (Interleaved 2 of 5)**, and **Codabar**.
  * Adaptive local thresholding & multi-angle scanline sweeper (`0°`, `90°`, `±45°`) supporting RGBA, BGRA, Grayscale, and YUV420 camera frames (`QrScanFrame`).
  * Real-time bounding-box and 4-corner polygon localization (`corners`) for animated target lock-on overlays.
* **5 Signature Animated Viewfinder Layouts (`QrScannerLayout`)**:
  * `QrScannerLayout.cyberNeon` — Glowing rounded corner brackets with dual-gradient laser sweep beam and animated polygon target reticles.
  * `QrScannerLayout.morphingPulse` — Dynamic-Island-inspired breathing reticle smoothly morphing between 2D QR and 1D Barcode aspect ratios with sonar pulse rings.
  * `QrScannerLayout.holographicGrid` — Sci-fi perspective scanning grid with radar arc sweep, telemetry ticks, and live FPS/confidence HUD.
  * `QrScannerLayout.minimalGlass` — Frosted glassmorphic cutout (`ImageFilter.blur`) with spring-physics micro-brackets and floating result sheet.
  * `QrScannerLayout.industrialHud` — High-speed multi-code batch scanner HUD with rangefinder crosshair, scan counter ribbon, and instant lock indicators.
* **Semantic Payload Parser (`QrPayloadParser` & `QrParsedPayload`)**:
  * Automatically parses raw barcode strings into structured `url`, `wifi`, `vCard`, `email`, `phone`, `sms`, `geo`, `product` (GS1 validation), `payment`, and `text` records.
* **Programmatic Control (`QrScannerController`)**:
  * Full lifecycle control (`start`, `pause`, `resume`, `toggleTorch`, `switchCamera`, `setZoom`, `processFrame`, `scanBytes`), deduplication cooldown, format filtering, and live scan history.
* **Crisp Vector Barcode & QR Renderer (`QrBarcodeGraphic`) & Built-in Icons (`QrVectorIcon`)**:
  * Render resolution-independent QR Codes and 1D Barcodes plus 18 custom-painted vector scanner glyphs with zero icon-font dependencies.
