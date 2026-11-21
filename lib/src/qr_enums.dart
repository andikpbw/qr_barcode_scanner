/// Visual layout presets for the [QrBarcodeScannerView] animated viewfinder.
enum QrScannerLayout {
  /// Glowing rounded corner brackets with a dual-gradient laser sweep beam,
  /// trailing neon aura, and animated polygon lock-on reticles.
  cyberNeon,

  /// Dynamic-Island-inspired breathing reticle that smoothly morphs between
  /// square 2D QR and wide 1D Barcode aspect ratios with sonar pulse rings.
  morphingPulse,

  /// Sci-fi perspective holographic matrix grid with radar sweep arc,
  /// corner telemetry ticks, and live FPS/confidence HUD.
  holographicGrid,

  /// Frosted glassmorphic cutout with spring-physics micro-brackets,
  /// subtle shimmer line, and floating glass semantic result sheet.
  minimalGlass,

  /// High-speed warehouse and retail multi-code batch scanner HUD with
  /// rangefinder crosshair, scan history ribbon, and bounding boxes.
  industrialHud,
}

/// Supported 1D and 2D barcode symbologies.
enum QrBarcodeFormat {
  /// 2D ISO/IEC 18004 Quick Response (QR) matrix code.
  qrCode,

  /// 1D European Article Number (13 digits) retail barcode.
  ean13,

  /// 1D European Article Number (8 digits) compact retail barcode.
  ean8,

  /// 1D Universal Product Code (12 digits) North American retail barcode.
  upcA,

  /// 1D Universal Product Code (8 digits) zero-suppressed retail barcode.
  upcE,

  /// 1D high-density alphanumeric Code-128 logistics and shipping barcode.
  code128,

  /// 1D alphanumeric Code-39 industrial and automotive barcode.
  code39,

  /// 1D Interleaved 2 of 5 (ITF) carton and packaging numeric barcode.
  itf,

  /// 1D Codabar library, blood bank, and airbill barcode.
  codabar,

  /// 2D ISO/IEC 16022 Data Matrix high-density industrial code.
  dataMatrix,

  /// 2D stacked linear PDF417 boarding pass and ID document code.
  pdf417,

  /// 2D Aztec concentric bullseye transit and ticketing code.
  aztec;

  /// Human-readable display name for UI badges and telemetry labels.
  String get displayName {
    switch (this) {
      case QrBarcodeFormat.qrCode:
        return 'QR Code';
      case QrBarcodeFormat.ean13:
        return 'EAN-13';
      case QrBarcodeFormat.ean8:
        return 'EAN-8';
      case QrBarcodeFormat.upcA:
        return 'UPC-A';
      case QrBarcodeFormat.upcE:
        return 'UPC-E';
      case QrBarcodeFormat.code128:
        return 'Code-128';
      case QrBarcodeFormat.code39:
        return 'Code-39';
      case QrBarcodeFormat.itf:
        return 'ITF-14';
      case QrBarcodeFormat.codabar:
        return 'Codabar';
      case QrBarcodeFormat.dataMatrix:
        return 'DataMatrix';
      case QrBarcodeFormat.pdf417:
        return 'PDF417';
      case QrBarcodeFormat.aztec:
        return 'Aztec';
    }
  }

  /// Compact uppercase badge label for HUD chips.
  String get shortTag {
    switch (this) {
      case QrBarcodeFormat.qrCode:
        return 'QR';
      case QrBarcodeFormat.ean13:
        return 'EAN13';
      case QrBarcodeFormat.ean8:
        return 'EAN8';
      case QrBarcodeFormat.upcA:
        return 'UPCA';
      case QrBarcodeFormat.upcE:
        return 'UPCE';
      case QrBarcodeFormat.code128:
        return 'C128';
      case QrBarcodeFormat.code39:
        return 'C39';
      case QrBarcodeFormat.itf:
        return 'ITF';
      case QrBarcodeFormat.codabar:
        return 'CBAR';
      case QrBarcodeFormat.dataMatrix:
        return 'DMX';
      case QrBarcodeFormat.pdf417:
        return 'PDF';
      case QrBarcodeFormat.aztec:
        return 'AZT';
    }
  }

  /// Whether this symbology is a 2D matrix code.
  bool get is2D =>
      this == QrBarcodeFormat.qrCode ||
      this == QrBarcodeFormat.dataMatrix ||
      this == QrBarcodeFormat.pdf417 ||
      this == QrBarcodeFormat.aztec;

  /// Whether this symbology is a 1D linear barcode.
  bool get is1D => !is2D;

  /// Recommended width-to-height aspect ratio for viewfinder morphing.
  double get recommendedAspectRatio {
    if (this == QrBarcodeFormat.pdf417) {
      return 1.85;
    }
    return is2D ? 1.0 : 1.72;
  }
}

/// Semantic category parsed from a decoded QR or barcode string.
enum QrPayloadType {
  /// Web URL (`https://`, `http://`, or custom app deep links).
  url,

  /// Wi-Fi network credentials (`WIFI:S:...;T:WPA;P:...;;`).
  wifi,

  /// Contact card (`BEGIN:VCARD...END:VCARD` or `MECARD:`).
  vCard,

  /// Email message (`mailto:` or `MATMSG:`).
  email,

  /// Telephone number (`tel:` or E.164 phone format).
  phone,

  /// SMS text message (`smsto:` or `sms:`).
  sms,

  /// Geographic coordinates (`geo:lat,lng`).
  geo,

  /// Retail GS1 product identifier (EAN-13, EAN-8, UPC-A, UPC-E).
  product,

  /// Digital payment payload (`upi://pay`, EMVCo QR `000201`, or crypto URI).
  payment,

  /// Plain text, serial number, or custom inventory identifier.
  text,
}

/// Active camera lens direction.
enum QrCameraFacing {
  /// Rear world-facing camera lens.
  back,

  /// Front user-facing camera lens.
  front,

  /// External USB or desktop webcam feed.
  external,
}

/// Memory layout of an incoming [QrScanFrame] pixel buffer.
enum QrPixelFormat {
  /// 32-bit RGBA (4 bytes per pixel: R, G, B, A).
  rgba8888,

  /// 32-bit BGRA (4 bytes per pixel: B, G, R, A — common on iOS/macOS).
  bgra8888,

  /// 8-bit single-channel luminance / grayscale (1 byte per pixel).
  grayscale8,

  /// YUV420 planar luminance buffer (uses the Y luma plane).
  yuv420,
}

/// Corner finder eye style when rendering a 2D QR code with [QrBarcodeGraphic].
enum QrFinderEyeStyle {
  /// Smoothly rounded modern square finder eyes.
  rounded,

  /// Circular bullseye finder eyes.
  circle,

  /// Geometric diamond-chamfered finder eyes.
  diamond,

  /// Classic sharp 90-degree ISO QR finder eyes.
  sharp,
}

/// Built-in pure-Flutter vector icons available via [QrVectorIcon].
enum QrGlyph {
  /// 2D QR matrix icon.
  qrCode,

  /// 1D vertical barcode icon.
  barcode,

  /// Active lightning torch / flash icon.
  flashOn,

  /// Disabled lightning torch / flash icon.
  flashOff,

  /// Camera lens flip / switch arrows icon.
  cameraSwitch,

  /// Photo gallery / image import icon.
  gallery,

  /// Magnifying glass zoom-in icon.
  zoomIn,

  /// Magnifying glass zoom-out icon.
  zoomOut,

  /// Verified checkmark badge icon.
  checkCircle,

  /// Clipboard copy icon.
  copy,

  /// External URL link icon.
  link,

  /// Wireless Wi-Fi signal waves icon.
  wifi,

  /// AI / smart sparkle star icon.
  sparkle,

  /// Clock history log icon.
  history,

  /// Stacked layout layers icon.
  layers,

  /// Target crosshair focus reticle icon.
  focus,

  /// Dismiss X icon.
  close,

  /// Security verified shield icon.
  shieldCheck,
}
