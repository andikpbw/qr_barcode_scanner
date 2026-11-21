import 'package:flutter/widgets.dart';

import 'qr_enums.dart';

/// Visual styling configuration for [QrBarcodeScannerView].
@immutable
class QrScannerStyle {
  /// Creates a [QrScannerStyle].
  const QrScannerStyle({
    this.accentColor = const Color(0xFF00F5D4),
    this.secondaryColor = const Color(0xFF6366F1),
    this.successColor = const Color(0xFF10B981),
    this.frameColor = const Color(0xFFFFFFFF),
    this.overlayColor = const Color(0xB8060B19),
    this.cutoutSizeFactor = 0.68,
    this.cutoutBorderRadius = 24.0,
    this.cornerLength = 30.0,
    this.cornerStrokeWidth = 3.6,
    this.laserThickness = 2.6,
    this.laserGlowBlur = 14.0,
    this.frostedBlurSigma = 12.0,
    this.showGrid = true,
    this.showTelemetry = true,
    this.showPolygonOverlay = true,
    this.showResultSheet = true,
    this.showTopBar = true,
    this.showBottomControls = true,
    this.title = 'AI Smart Scanner',
    this.subtitle = 'Align QR code or 1D barcode inside viewfinder',
  });

  /// Creates the signature **Cyber Neon** style preset.
  factory QrScannerStyle.cyberNeon() {
    return const QrScannerStyle(
      accentColor: Color(0xFF00F5D4),
      secondaryColor: Color(0xFF7C3AED),
      successColor: Color(0xFF10B981),
      overlayColor: Color(0xBA050914),
      cutoutBorderRadius: 24.0,
      cornerLength: 32.0,
      cornerStrokeWidth: 3.8,
      title: 'Cyber Neon Viewfinder',
      subtitle: 'Dual-gradient laser beam & polygon target lock',
    );
  }

  /// Creates the signature **Morphing Pulse** style preset.
  factory QrScannerStyle.morphingPulse() {
    return const QrScannerStyle(
      accentColor: Color(0xFF818CF8),
      secondaryColor: Color(0xFFEC4899),
      successColor: Color(0xFF34D399),
      overlayColor: Color(0xB5080A1A),
      cutoutBorderRadius: 28.0,
      cornerLength: 28.0,
      cornerStrokeWidth: 3.4,
      title: 'Morphing Pulse Reticle',
      subtitle: 'Auto-morphs between 2D QR & 1D Barcode geometry',
    );
  }

  /// Creates the signature **Holographic Grid** style preset.
  factory QrScannerStyle.holographicGrid() {
    return const QrScannerStyle(
      accentColor: Color(0xFF38BDF8),
      secondaryColor: Color(0xFF06B6D4),
      successColor: Color(0xFF22C55E),
      overlayColor: Color(0xBD040B16),
      cutoutBorderRadius: 18.0,
      cornerLength: 34.0,
      cornerStrokeWidth: 3.2,
      title: 'Holographic Matrix Grid',
      subtitle: '360° radar sweep & real-time telemetry ticks',
    );
  }

  /// Creates the signature **Minimal Glass** style preset.
  factory QrScannerStyle.minimalGlass() {
    return const QrScannerStyle(
      accentColor: Color(0xFFF8FAFC),
      secondaryColor: Color(0xFF94A3B8),
      successColor: Color(0xFF34D399),
      overlayColor: Color(0xA6090D16),
      cutoutBorderRadius: 30.0,
      cornerLength: 26.0,
      cornerStrokeWidth: 3.0,
      frostedBlurSigma: 16.0,
      title: 'Minimal Frosted Glass',
      subtitle: 'Spring-physics micro-brackets & glass result dock',
    );
  }

  /// Creates the signature **Industrial HUD** style preset.
  factory QrScannerStyle.industrialHud() {
    return const QrScannerStyle(
      accentColor: Color(0xFFF59E0B),
      secondaryColor: Color(0xFFEF4444),
      successColor: Color(0xFF10B981),
      overlayColor: Color(0xBE0A0D12),
      cutoutBorderRadius: 12.0,
      cornerLength: 24.0,
      cornerStrokeWidth: 3.2,
      title: 'Industrial Batch HUD',
      subtitle: 'High-speed multi-barcode rangefinder & counter',
    );
  }

  /// Resolves the recommended style preset for [layout].
  factory QrScannerStyle.forLayout(QrScannerLayout layout) {
    switch (layout) {
      case QrScannerLayout.cyberNeon:
        return QrScannerStyle.cyberNeon();
      case QrScannerLayout.morphingPulse:
        return QrScannerStyle.morphingPulse();
      case QrScannerLayout.holographicGrid:
        return QrScannerStyle.holographicGrid();
      case QrScannerLayout.minimalGlass:
        return QrScannerStyle.minimalGlass();
      case QrScannerLayout.industrialHud:
        return QrScannerStyle.industrialHud();
    }
  }

  /// Primary active accent color used for corner brackets, laser line, and badges.
  final Color accentColor;

  /// Secondary gradient companion color for trails, sonar rings, and glows.
  final Color secondaryColor;

  /// Color displayed when a QR code or barcode is locked on and verified.
  final Color successColor;

  /// Passive frame border color around the viewfinder cutout.
  final Color frameColor;

  /// Scrim backdrop color outside the viewfinder cutout.
  final Color overlayColor;

  /// Fraction of the shortest viewport dimension occupied by the cutout (`0.35..0.90`).
  final double cutoutSizeFactor;

  /// Corner radius of the viewfinder cutout in logical pixels.
  final double cutoutBorderRadius;

  /// Length of each corner bracket arm in logical pixels.
  final double cornerLength;

  /// Stroke width of corner brackets in logical pixels.
  final double cornerStrokeWidth;

  /// Thickness of the animated laser scan beam.
  final double laserThickness;

  /// Blur radius of the laser and corner neon aura.
  final double laserGlowBlur;

  /// Backdrop blur sigma for frosted glass HUD cards.
  final double frostedBlurSigma;

  /// Whether to render interior alignment/matrix grid lines.
  final bool showGrid;

  /// Whether to render live FPS, symbology, and latency telemetry pills.
  final bool showTelemetry;

  /// Whether to render animated 4-corner tracking polygons on detected codes.
  final bool showPolygonOverlay;

  /// Whether to display the bottom semantic result sheet when a code is scanned.
  final bool showResultSheet;

  /// Whether to display the top header bar with torch and camera switch buttons.
  final bool showTopBar;

  /// Whether to display the bottom zoom and format control bar.
  final bool showBottomControls;

  /// Primary title displayed in the top scanner HUD.
  final String title;

  /// Helper prompt displayed beneath the viewfinder cutout.
  final String subtitle;

  /// Creates a copy of this [QrScannerStyle] with selected fields replaced.
  QrScannerStyle copyWith({
    Color? accentColor,
    Color? secondaryColor,
    Color? successColor,
    Color? frameColor,
    Color? overlayColor,
    double? cutoutSizeFactor,
    double? cutoutBorderRadius,
    double? cornerLength,
    double? cornerStrokeWidth,
    double? laserThickness,
    double? laserGlowBlur,
    double? frostedBlurSigma,
    bool? showGrid,
    bool? showTelemetry,
    bool? showPolygonOverlay,
    bool? showResultSheet,
    bool? showTopBar,
    bool? showBottomControls,
    String? title,
    String? subtitle,
  }) {
    return QrScannerStyle(
      accentColor: accentColor ?? this.accentColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      successColor: successColor ?? this.successColor,
      frameColor: frameColor ?? this.frameColor,
      overlayColor: overlayColor ?? this.overlayColor,
      cutoutSizeFactor: cutoutSizeFactor ?? this.cutoutSizeFactor,
      cutoutBorderRadius: cutoutBorderRadius ?? this.cutoutBorderRadius,
      cornerLength: cornerLength ?? this.cornerLength,
      cornerStrokeWidth: cornerStrokeWidth ?? this.cornerStrokeWidth,
      laserThickness: laserThickness ?? this.laserThickness,
      laserGlowBlur: laserGlowBlur ?? this.laserGlowBlur,
      frostedBlurSigma: frostedBlurSigma ?? this.frostedBlurSigma,
      showGrid: showGrid ?? this.showGrid,
      showTelemetry: showTelemetry ?? this.showTelemetry,
      showPolygonOverlay: showPolygonOverlay ?? this.showPolygonOverlay,
      showResultSheet: showResultSheet ?? this.showResultSheet,
      showTopBar: showTopBar ?? this.showTopBar,
      showBottomControls: showBottomControls ?? this.showBottomControls,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is QrScannerStyle &&
        other.accentColor == accentColor &&
        other.secondaryColor == secondaryColor &&
        other.successColor == successColor &&
        other.frameColor == frameColor &&
        other.overlayColor == overlayColor &&
        other.cutoutSizeFactor == cutoutSizeFactor &&
        other.cutoutBorderRadius == cutoutBorderRadius &&
        other.cornerLength == cornerLength &&
        other.cornerStrokeWidth == cornerStrokeWidth &&
        other.laserThickness == laserThickness &&
        other.laserGlowBlur == laserGlowBlur &&
        other.frostedBlurSigma == frostedBlurSigma &&
        other.showGrid == showGrid &&
        other.showTelemetry == showTelemetry &&
        other.showPolygonOverlay == showPolygonOverlay &&
        other.showResultSheet == showResultSheet &&
        other.showTopBar == showTopBar &&
        other.showBottomControls == showBottomControls &&
        other.title == title &&
        other.subtitle == subtitle;
  }

  @override
  int get hashCode => Object.hash(
    accentColor,
    secondaryColor,
    successColor,
    frameColor,
    overlayColor,
    cutoutSizeFactor,
    cutoutBorderRadius,
    cornerLength,
    cornerStrokeWidth,
    laserThickness,
    laserGlowBlur,
    frostedBlurSigma,
    showGrid,
    showTelemetry,
    showPolygonOverlay,
    showResultSheet,
    showTopBar,
    showBottomControls,
    title,
    subtitle,
  );
}

/// Animation timing, curve, and deduplication configuration for [QrBarcodeScannerView].
@immutable
class QrScannerMotionConfig {
  /// Creates a [QrScannerMotionConfig].
  const QrScannerMotionConfig({
    this.laserSweepDuration = const Duration(milliseconds: 2200),
    this.lockOnDuration = const Duration(milliseconds: 380),
    this.morphDuration = const Duration(milliseconds: 460),
    this.scanCooldown = const Duration(milliseconds: 900),
    this.sweepCurve = Curves.easeInOutSine,
    this.lockCurve = Curves.easeOutBack,
    this.morphCurve = Curves.easeOutCubic,
    this.enableHaptics = true,
    this.autoSimulateInPreview = true,
  });

  /// Duration of one full vertical laser or radar sweep cycle.
  final Duration laserSweepDuration;

  /// Duration of the corner polygon lock-on transition when a code is detected.
  final Duration lockOnDuration;

  /// Duration of the viewfinder aspect-ratio morph transition between 2D and 1D modes.
  final Duration morphDuration;

  /// Minimum interval before the exact same barcode value triggers a duplicate callback.
  final Duration scanCooldown;

  /// Easing curve for the continuous laser sweep animation.
  final Curve sweepCurve;

  /// Easing curve for the polygon target lock-on animation.
  final Curve lockCurve;

  /// Easing curve for viewfinder layout and aspect-ratio morphing.
  final Curve morphCurve;

  /// Whether to trigger light haptic impact feedback upon detection.
  final bool enableHaptics;

  /// Whether the built-in interactive simulator automatically cycles through
  /// real decoded QR and 1D barcode targets when no external camera feed is provided.
  final bool autoSimulateInPreview;

  /// Creates a copy of this [QrScannerMotionConfig] with updated fields.
  QrScannerMotionConfig copyWith({
    Duration? laserSweepDuration,
    Duration? lockOnDuration,
    Duration? morphDuration,
    Duration? scanCooldown,
    Curve? sweepCurve,
    Curve? lockCurve,
    Curve? morphCurve,
    bool? enableHaptics,
    bool? autoSimulateInPreview,
  }) {
    return QrScannerMotionConfig(
      laserSweepDuration: laserSweepDuration ?? this.laserSweepDuration,
      lockOnDuration: lockOnDuration ?? this.lockOnDuration,
      morphDuration: morphDuration ?? this.morphDuration,
      scanCooldown: scanCooldown ?? this.scanCooldown,
      sweepCurve: sweepCurve ?? this.sweepCurve,
      lockCurve: lockCurve ?? this.lockCurve,
      morphCurve: morphCurve ?? this.morphCurve,
      enableHaptics: enableHaptics ?? this.enableHaptics,
      autoSimulateInPreview:
          autoSimulateInPreview ?? this.autoSimulateInPreview,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is QrScannerMotionConfig &&
        other.laserSweepDuration == laserSweepDuration &&
        other.lockOnDuration == lockOnDuration &&
        other.morphDuration == morphDuration &&
        other.scanCooldown == scanCooldown &&
        other.sweepCurve == sweepCurve &&
        other.lockCurve == lockCurve &&
        other.morphCurve == morphCurve &&
        other.enableHaptics == enableHaptics &&
        other.autoSimulateInPreview == autoSimulateInPreview;
  }

  @override
  int get hashCode => Object.hash(
    laserSweepDuration,
    lockOnDuration,
    morphDuration,
    scanCooldown,
    sweepCurve,
    lockCurve,
    morphCurve,
    enableHaptics,
    autoSimulateInPreview,
  );
}
