import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import 'qr_enums.dart';
import 'qr_scan_result.dart';
import 'qr_scanner_style.dart';

/// Custom painter that renders the animated viewfinder cutout, laser beam,
/// radar grid, sonar pulse rings, and real-time polygon target lock overlays.
class QrViewfinderPainter extends CustomPainter {
  /// Creates a [QrViewfinderPainter].
  const QrViewfinderPainter({
    required this.layout,
    required this.style,
    required this.sweepProgress,
    required this.pulseProgress,
    required this.lockProgress,
    required this.aspectMorph,
    this.activeDetections = const <QrScanResult>[],
    this.focusPoint,
    this.focusProgress = 0.0,
    this.isPaused = false,
  });

  /// Active viewfinder layout preset.
  final QrScannerLayout layout;

  /// Styling parameters for colors, corner lengths, and stroke widths.
  final QrScannerStyle style;

  /// Normalized laser/radar sweep animation progress (`0.0..1.0`).
  final double sweepProgress;

  /// Normalized breathing/sonar pulse progress (`0.0..1.0`).
  final double pulseProgress;

  /// Normalized target lock-on animation progress (`0.0..1.0`).
  final double lockProgress;

  /// Morph factor between 2D square cutout (`0.0`) and 1D wide cutout (`1.0`).
  final double aspectMorph;

  /// Currently detected QR codes or barcodes for polygon lock rendering.
  final List<QrScanResult> activeDetections;

  /// Optional tap-to-focus coordinate in viewport logical pixels.
  final Offset? focusPoint;

  /// Normalized tap-to-focus ring progress (`0.0..1.0`).
  final double focusProgress;

  /// Whether scanning is currently paused.
  final bool isPaused;

  /// Computes the active viewfinder cutout [Rect] for a given [size].
  Rect computeCutoutRect(Size size) {
    final shortest = math.min(size.width, size.height);
    final baseSide = (shortest * style.cutoutSizeFactor).clamp(130.0, 340.0);
    final width = lerpDouble(
      baseSide,
      math.min(size.width * 0.84, baseSide * 1.18),
      aspectMorph,
    )!;
    final height = lerpDouble(baseSide, baseSide * 0.62, aspectMorph)!;
    final center = Offset(size.width / 2, size.height * 0.45);
    return Rect.fromCenter(center: center, width: width, height: height);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final cutout = computeCutoutRect(size);
    final radius = Radius.circular(style.cutoutBorderRadius);
    final cutoutRRect = RRect.fromRectAndRadius(cutout, radius);

    // 1. Darkened outer scrim with smooth rounded cutout
    final outerPath = Path()..addRect(Offset.zero & size);
    final holePath = Path()..addRRect(cutoutRRect);
    final scrimPath = Path.combine(
      PathOperation.difference,
      outerPath,
      holePath,
    );
    canvas.drawPath(scrimPath, Paint()..color = style.overlayColor);

    final activeColor = Color.lerp(
      style.accentColor,
      style.successColor,
      lockProgress,
    )!;

    // 2. Layout-specific ambient effects & interior grid
    switch (layout) {
      case QrScannerLayout.cyberNeon:
        _paintCyberNeonInterior(canvas, cutout, cutoutRRect, activeColor);
      case QrScannerLayout.morphingPulse:
        _paintMorphingPulseInterior(canvas, cutout, cutoutRRect, activeColor);
      case QrScannerLayout.holographicGrid:
        _paintHolographicGridInterior(canvas, cutout, cutoutRRect, activeColor);
      case QrScannerLayout.minimalGlass:
        _paintMinimalGlassInterior(canvas, cutout, cutoutRRect, activeColor);
      case QrScannerLayout.industrialHud:
        _paintIndustrialHudInterior(canvas, cutout, cutoutRRect, activeColor);
    }

    // 3. Subtle passive border around cutout
    canvas.drawRRect(
      cutoutRRect,
      Paint()
        ..color = style.frameColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    // 4. Corner brackets
    _paintCornerBrackets(canvas, cutout, activeColor);

    // 5. Real-time detected polygon overlays
    if (style.showPolygonOverlay &&
        activeDetections.isNotEmpty &&
        lockProgress > 0.02) {
      _paintDetectedPolygons(canvas, cutout, activeColor);
    }

    // 6. Tap-to-focus ring indicator
    if (focusPoint != null && focusProgress > 0.0 && focusProgress < 1.0) {
      _paintFocusReticle(canvas, focusPoint!, activeColor);
    }
  }

  void _paintCyberNeonInterior(
    Canvas canvas,
    Rect cutout,
    RRect cutoutRRect,
    Color activeColor,
  ) {
    canvas.save();
    canvas.clipRRect(cutoutRRect);

    if (style.showGrid) {
      final gridPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.08)
        ..strokeWidth = 0.8;
      const divisions = 6;
      for (var i = 1; i < divisions; i++) {
        final x = cutout.left + (cutout.width * i) / divisions;
        final y = cutout.top + (cutout.height * i) / divisions;
        canvas.drawLine(
          Offset(x, cutout.top),
          Offset(x, cutout.bottom),
          gridPaint,
        );
        canvas.drawLine(
          Offset(cutout.left, y),
          Offset(cutout.right, y),
          gridPaint,
        );
      }
    }

    if (!isPaused) {
      final pingPong = sweepProgress < 0.5
          ? sweepProgress * 2.0
          : (1.0 - sweepProgress) * 2.0;
      final beamY = cutout.top + 10 + (cutout.height - 20) * pingPong;

      // Trailing neon gradient mesh above beam
      const trailHeight = 44.0;
      final trailRect = Rect.fromLTRB(
        cutout.left + 6,
        beamY - trailHeight,
        cutout.right - 6,
        beamY,
      );
      final trailPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            style.secondaryColor.withValues(alpha: 0.0),
            activeColor.withValues(alpha: 0.28),
          ],
        ).createShader(trailRect);
      canvas.drawRect(trailRect, trailPaint);

      // Glowing laser core line
      final beamRect = Rect.fromLTWH(
        cutout.left + 8,
        beamY - style.laserThickness / 2,
        cutout.width - 16,
        style.laserThickness,
      );
      final glowPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.laserGlowBlur);
      canvas.drawRRect(
        RRect.fromRectAndRadius(beamRect.inflate(2), const Radius.circular(4)),
        glowPaint,
      );

      final corePaint = Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            activeColor.withValues(alpha: 0.1),
            activeColor,
            const Color(0xFFFFFFFF),
            activeColor,
            activeColor.withValues(alpha: 0.1),
          ],
          stops: const <double>[0.0, 0.2, 0.5, 0.8, 1.0],
        ).createShader(beamRect);
      canvas.drawRRect(
        RRect.fromRectAndRadius(beamRect, const Radius.circular(3)),
        corePaint,
      );
    }

    canvas.restore();
  }

  void _paintMorphingPulseInterior(
    Canvas canvas,
    Rect cutout,
    RRect cutoutRRect,
    Color activeColor,
  ) {
    // Concentric breathing sonar rings radiating from cutout
    for (var i = 0; i < 2; i++) {
      final phase = (pulseProgress + i * 0.5) % 1.0;
      final inflateAmount = 4.0 + phase * 18.0;
      final alpha = (1.0 - phase) * 0.32;
      final ringColor = Color.lerp(
        activeColor,
        style.secondaryColor,
        phase,
      )!.withValues(alpha: alpha);
      canvas.drawRRect(
        cutoutRRect.inflate(inflateAmount),
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }

    canvas.save();
    canvas.clipRRect(cutoutRRect);

    // Center breathing target capsule
    final breath = 1.0 + math.sin(pulseProgress * math.pi * 2) * 0.06;
    final capsuleW = (cutout.width * 0.26) * breath;
    final capsuleH = (cutout.height * 0.26) * breath;
    final centerRect = Rect.fromCenter(
      center: cutout.center,
      width: capsuleW,
      height: capsuleH,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(centerRect, const Radius.circular(14)),
      Paint()
        ..color = activeColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawCircle(
      cutout.center,
      3.5,
      Paint()..color = activeColor.withValues(alpha: 0.85),
    );

    if (!isPaused) {
      final scanY = cutout.top + 14 + (cutout.height - 28) * sweepProgress;
      final lineRect = Rect.fromLTWH(
        cutout.left + 14,
        scanY,
        cutout.width - 28,
        2.2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(lineRect, const Radius.circular(2)),
        Paint()
          ..shader = LinearGradient(
            colors: <Color>[
              style.secondaryColor.withValues(alpha: 0.05),
              activeColor,
              style.secondaryColor.withValues(alpha: 0.05),
            ],
          ).createShader(lineRect),
      );
    }

    canvas.restore();
  }

  void _paintHolographicGridInterior(
    Canvas canvas,
    Rect cutout,
    RRect cutoutRRect,
    Color activeColor,
  ) {
    canvas.save();
    canvas.clipRRect(cutoutRRect);

    // Holographic matrix grid + dot intersections
    final gridPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.14)
      ..strokeWidth = 0.8;
    final dotPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    const cols = 8;
    const rows = 8;
    for (var c = 1; c < cols; c++) {
      final x = cutout.left + (cutout.width * c) / cols;
      canvas.drawLine(
        Offset(x, cutout.top),
        Offset(x, cutout.bottom),
        gridPaint,
      );
      for (var r = 1; r < rows; r++) {
        final y = cutout.top + (cutout.height * r) / rows;
        if (c == 1) {
          canvas.drawLine(
            Offset(cutout.left, y),
            Offset(cutout.right, y),
            gridPaint,
          );
        }
        canvas.drawCircle(Offset(x, y), 1.3, dotPaint);
      }
    }

    // 360-degree radar sweep cone
    final center = cutout.center;
    final radius = math.max(cutout.width, cutout.height) * 0.56;
    final radarAngle = sweepProgress * math.pi * 2;
    final radarRect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      cutout.shortestSide * 0.34,
      Paint()
        ..color = activeColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    if (!isPaused) {
      final radarPaint = Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: 0.0,
          endAngle: math.pi * 0.45,
          colors: <Color>[
            activeColor.withValues(alpha: 0.0),
            activeColor.withValues(alpha: 0.26),
          ],
          transform: GradientRotation(radarAngle - math.pi * 0.45),
        ).createShader(radarRect);
      canvas.drawArc(
        radarRect,
        radarAngle - math.pi * 0.45,
        math.pi * 0.45,
        true,
        radarPaint,
      );
    }

    // Ruler telemetry ticks along edges
    final tickPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.45)
      ..strokeWidth = 1.2;
    for (var i = 1; i < 12; i++) {
      final tx = cutout.left + (cutout.width * i) / 12;
      final len = i % 3 == 0 ? 7.0 : 4.0;
      canvas.drawLine(
        Offset(tx, cutout.top),
        Offset(tx, cutout.top + len),
        tickPaint,
      );
      canvas.drawLine(
        Offset(tx, cutout.bottom),
        Offset(tx, cutout.bottom - len),
        tickPaint,
      );
    }

    canvas.restore();
  }

  void _paintMinimalGlassInterior(
    Canvas canvas,
    Rect cutout,
    RRect cutoutRRect,
    Color activeColor,
  ) {
    canvas.save();
    canvas.clipRRect(cutoutRRect);

    // Subtle glass sheen gradient
    final sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          const Color(0xFFFFFFFF).withValues(alpha: 0.07),
          const Color(0xFFFFFFFF).withValues(alpha: 0.01),
          activeColor.withValues(alpha: 0.05),
        ],
      ).createShader(cutout);
    canvas.drawRect(cutout, sheenPaint);

    if (!isPaused) {
      final pingPong = sweepProgress < 0.5
          ? sweepProgress * 2.0
          : (1.0 - sweepProgress) * 2.0;
      final y = cutout.top + 16 + (cutout.height - 32) * pingPong;
      final shimmerRect = Rect.fromLTWH(
        cutout.left + 16,
        y - 1.0,
        cutout.width - 32,
        2.0,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(shimmerRect, const Radius.circular(2)),
        Paint()
          ..shader = LinearGradient(
            colors: <Color>[
              activeColor.withValues(alpha: 0.0),
              activeColor.withValues(alpha: 0.75),
              activeColor.withValues(alpha: 0.0),
            ],
          ).createShader(shimmerRect),
      );
    }

    canvas.restore();
  }

  void _paintIndustrialHudInterior(
    Canvas canvas,
    Rect cutout,
    RRect cutoutRRect,
    Color activeColor,
  ) {
    canvas.save();
    canvas.clipRRect(cutoutRRect);

    // Rangefinder crosshair + horizontal barcode alignment guide
    final cx = cutout.center.dx;
    final cy = cutout.center.dy;
    final guidePaint = Paint()
      ..color = activeColor.withValues(alpha: 0.30)
      ..strokeWidth = 1.1;

    // Dashed horizontal guide line
    const dashW = 8.0;
    const gapW = 5.0;
    var x = cutout.left + 12;
    while (x < cutout.right - 12) {
      canvas.drawLine(
        Offset(x, cy),
        Offset(math.min(x + dashW, cutout.right - 12), cy),
        guidePaint,
      );
      x += dashW + gapW;
    }

    // Center rangefinder bracket
    const bSize = 18.0;
    canvas.drawLine(
      Offset(cx - bSize, cy - 10),
      Offset(cx - bSize, cy + 10),
      guidePaint,
    );
    canvas.drawLine(
      Offset(cx + bSize, cy - 10),
      Offset(cx + bSize, cy + 10),
      guidePaint,
    );
    canvas.drawLine(Offset(cx, cy - 14), Offset(cx, cy + 14), guidePaint);

    if (!isPaused) {
      final pingPong = sweepProgress < 0.5
          ? sweepProgress * 2.0
          : (1.0 - sweepProgress) * 2.0;
      final beamY = cutout.top + 10 + (cutout.height - 20) * pingPong;
      final laserPaint = Paint()
        ..color = style.secondaryColor.withValues(alpha: 0.90)
        ..strokeWidth = 2.2;
      canvas.drawLine(
        Offset(cutout.left + 8, beamY),
        Offset(cutout.right - 8, beamY),
        laserPaint,
      );
    }

    canvas.restore();
  }

  void _paintCornerBrackets(Canvas canvas, Rect cutout, Color activeColor) {
    final len = style.cornerLength;
    final r = style.cutoutBorderRadius;
    final stroke = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.cornerStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glow = Paint()
      ..color = activeColor.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.cornerStrokeWidth + 3.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.0);

    final path = Path()
      // Top-left
      ..moveTo(cutout.left, cutout.top + len)
      ..lineTo(cutout.left, cutout.top + r)
      ..arcToPoint(
        Offset(cutout.left + r, cutout.top),
        radius: Radius.circular(r),
      )
      ..lineTo(cutout.left + len, cutout.top)
      // Top-right
      ..moveTo(cutout.right - len, cutout.top)
      ..lineTo(cutout.right - r, cutout.top)
      ..arcToPoint(
        Offset(cutout.right, cutout.top + r),
        radius: Radius.circular(r),
      )
      ..lineTo(cutout.right, cutout.top + len)
      // Bottom-right
      ..moveTo(cutout.right, cutout.bottom - len)
      ..lineTo(cutout.right, cutout.bottom - r)
      ..arcToPoint(
        Offset(cutout.right - r, cutout.bottom),
        radius: Radius.circular(r),
      )
      ..lineTo(cutout.right - len, cutout.bottom)
      // Bottom-left
      ..moveTo(cutout.left + len, cutout.bottom)
      ..lineTo(cutout.left + r, cutout.bottom)
      ..arcToPoint(
        Offset(cutout.left, cutout.bottom - r),
        radius: Radius.circular(r),
      )
      ..lineTo(cutout.left, cutout.bottom - len);

    if (layout != QrScannerLayout.minimalGlass) {
      canvas.drawPath(path, glow);
    }
    canvas.drawPath(path, stroke);
  }

  void _paintDetectedPolygons(Canvas canvas, Rect cutout, Color activeColor) {
    final defaultCorners = <Offset>[
      cutout.topLeft,
      cutout.topRight,
      cutout.bottomRight,
      cutout.bottomLeft,
    ];

    for (final detection in activeDetections) {
      if (detection.corners.length < 4) {
        continue;
      }

      final mappedCorners = List<Offset>.generate(4, (i) {
        final norm = detection.corners[i];
        final target = Offset(
          cutout.left + norm.dx * cutout.width,
          cutout.top + norm.dy * cutout.height,
        );
        return Offset.lerp(defaultCorners[i], target, lockProgress)!;
      });

      final polyPath = Path()
        ..moveTo(mappedCorners[0].dx, mappedCorners[0].dy)
        ..lineTo(mappedCorners[1].dx, mappedCorners[1].dy)
        ..lineTo(mappedCorners[2].dx, mappedCorners[2].dy)
        ..lineTo(mappedCorners[3].dx, mappedCorners[3].dy)
        ..close();

      canvas.drawPath(
        polyPath,
        Paint()
          ..color = style.successColor.withValues(alpha: 0.16 * lockProgress)
          ..style = PaintingStyle.fill,
      );

      canvas.drawPath(
        polyPath,
        Paint()
          ..color = style.successColor.withValues(alpha: 0.92 * lockProgress)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeJoin = StrokeJoin.round,
      );

      for (final corner in mappedCorners) {
        canvas.drawCircle(
          corner,
          4.5 * lockProgress,
          Paint()..color = style.successColor,
        );
        canvas.drawCircle(
          corner,
          2.0 * lockProgress,
          Paint()..color = const Color(0xFFFFFFFF),
        );
      }
    }
  }

  void _paintFocusReticle(Canvas canvas, Offset center, Color activeColor) {
    final radius = lerpDouble(34.0, 18.0, focusProgress)!;
    final alpha = (1.0 - focusProgress).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = activeColor.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(
      center,
      3.0,
      Paint()..color = activeColor.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(covariant QrViewfinderPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.style != style ||
        oldDelegate.sweepProgress != sweepProgress ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.lockProgress != lockProgress ||
        oldDelegate.aspectMorph != aspectMorph ||
        oldDelegate.activeDetections != activeDetections ||
        oldDelegate.focusPoint != focusPoint ||
        oldDelegate.focusProgress != focusProgress ||
        oldDelegate.isPaused != isPaused;
  }
}
