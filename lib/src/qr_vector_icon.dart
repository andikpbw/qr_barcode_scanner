import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'qr_barcode_codec.dart';
import 'qr_enums.dart';

/// Pure-Flutter custom-painted vector icon widget requiring zero icon font dependencies.
class QrVectorIcon extends StatelessWidget {
  /// Creates a [QrVectorIcon].
  const QrVectorIcon(
    this.glyph, {
    super.key,
    this.size = 20.0,
    this.color = const Color(0xFFFFFFFF),
    this.strokeWidth = 1.9,
  });

  /// Vector glyph shape to paint.
  final QrGlyph glyph;

  /// Width and height of the icon box in logical pixels.
  final double size;

  /// Foreground stroke and fill color.
  final Color color;

  /// Base stroke thickness in logical pixels.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _QrVectorIconPainter(
        glyph: glyph,
        color: color,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _QrVectorIconPainter extends CustomPainter {
  const _QrVectorIconPainter({
    required this.glyph,
    required this.color,
    required this.strokeWidth,
  });

  final QrGlyph glyph;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (glyph) {
      case QrGlyph.qrCode:
        final s = w * 0.30;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.14, h * 0.14, s, s),
            Radius.circular(w * 0.06),
          ),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.56, h * 0.14, s, s),
            Radius.circular(w * 0.06),
          ),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.14, h * 0.56, s, s),
            Radius.circular(w * 0.06),
          ),
          stroke,
        );
        canvas.drawRect(
          Rect.fromLTWH(w * 0.56, h * 0.56, w * 0.12, h * 0.12),
          fill,
        );
        canvas.drawRect(
          Rect.fromLTWH(w * 0.74, h * 0.56, w * 0.12, h * 0.12),
          fill,
        );
        canvas.drawRect(
          Rect.fromLTWH(w * 0.56, h * 0.74, w * 0.30, h * 0.12),
          fill,
        );

      case QrGlyph.barcode:
        final xs = <double>[0.14, 0.27, 0.38, 0.52, 0.65, 0.76, 0.86];
        final widths = <double>[1.2, 0.8, 1.5, 0.9, 1.4, 0.8, 1.2];
        for (var i = 0; i < xs.length; i++) {
          final p = Paint()
            ..color = color
            ..strokeWidth = strokeWidth * widths[i]
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(
            Offset(w * xs[i], h * 0.20),
            Offset(w * xs[i], h * 0.80),
            p,
          );
        }

      case QrGlyph.flashOn:
        final path = Path()
          ..moveTo(w * 0.56, h * 0.12)
          ..lineTo(w * 0.24, h * 0.54)
          ..lineTo(w * 0.48, h * 0.54)
          ..lineTo(w * 0.42, h * 0.88)
          ..lineTo(w * 0.76, h * 0.44)
          ..lineTo(w * 0.52, h * 0.44)
          ..close();
        canvas.drawPath(path, fill);

      case QrGlyph.flashOff:
        final path = Path()
          ..moveTo(w * 0.56, h * 0.14)
          ..lineTo(w * 0.26, h * 0.52)
          ..lineTo(w * 0.48, h * 0.52)
          ..lineTo(w * 0.43, h * 0.86)
          ..lineTo(w * 0.74, h * 0.46)
          ..lineTo(w * 0.52, h * 0.46)
          ..close();
        canvas.drawPath(path, stroke);
        canvas.drawLine(
          Offset(w * 0.18, h * 0.18),
          Offset(w * 0.82, h * 0.82),
          stroke,
        );

      case QrGlyph.cameraSwitch:
        canvas.drawArc(
          Rect.fromCircle(center: Offset(w * 0.5, h * 0.5), radius: w * 0.32),
          -math.pi * 0.85,
          math.pi * 0.7,
          false,
          stroke,
        );
        canvas.drawArc(
          Rect.fromCircle(center: Offset(w * 0.5, h * 0.5), radius: w * 0.32),
          math.pi * 0.15,
          math.pi * 0.7,
          false,
          stroke,
        );
        final topArrow = Path()
          ..moveTo(w * 0.72, h * 0.22)
          ..lineTo(w * 0.82, h * 0.38)
          ..lineTo(w * 0.64, h * 0.38);
        canvas.drawPath(topArrow, stroke);
        final botArrow = Path()
          ..moveTo(w * 0.28, h * 0.78)
          ..lineTo(w * 0.18, h * 0.62)
          ..lineTo(w * 0.36, h * 0.62);
        canvas.drawPath(botArrow, stroke);

      case QrGlyph.gallery:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.14, h * 0.18, w * 0.72, h * 0.64),
            Radius.circular(w * 0.12),
          ),
          stroke,
        );
        canvas.drawCircle(Offset(w * 0.34, h * 0.38), w * 0.07, fill);
        final mtn = Path()
          ..moveTo(w * 0.18, h * 0.74)
          ..lineTo(w * 0.42, h * 0.50)
          ..lineTo(w * 0.58, h * 0.64)
          ..lineTo(w * 0.70, h * 0.52)
          ..lineTo(w * 0.82, h * 0.74);
        canvas.drawPath(mtn, stroke);

      case QrGlyph.zoomIn:
      case QrGlyph.zoomOut:
        final center = Offset(w * 0.44, h * 0.44);
        canvas.drawCircle(center, w * 0.26, stroke);
        canvas.drawLine(
          Offset(w * 0.63, h * 0.63),
          Offset(w * 0.84, h * 0.84),
          stroke,
        );
        canvas.drawLine(
          Offset(w * 0.33, h * 0.44),
          Offset(w * 0.55, h * 0.44),
          stroke,
        );
        if (glyph == QrGlyph.zoomIn) {
          canvas.drawLine(
            Offset(w * 0.44, h * 0.33),
            Offset(w * 0.44, h * 0.55),
            stroke,
          );
        }

      case QrGlyph.checkCircle:
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.36, stroke);
        final check = Path()
          ..moveTo(w * 0.33, h * 0.52)
          ..lineTo(w * 0.45, h * 0.64)
          ..lineTo(w * 0.68, h * 0.38);
        canvas.drawPath(check, stroke);

      case QrGlyph.copy:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.30, h * 0.30, w * 0.52, h * 0.54),
            Radius.circular(w * 0.10),
          ),
          stroke,
        );
        final back = Path()
          ..moveTo(w * 0.24, h * 0.66)
          ..lineTo(w * 0.18, h * 0.66)
          ..lineTo(w * 0.18, h * 0.18)
          ..lineTo(w * 0.66, h * 0.18)
          ..lineTo(w * 0.66, h * 0.24);
        canvas.drawPath(back, stroke);

      case QrGlyph.link:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.16, h * 0.36, w * 0.36, h * 0.28),
            Radius.circular(w * 0.14),
          ),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.48, h * 0.36, w * 0.36, h * 0.28),
            Radius.circular(w * 0.14),
          ),
          stroke,
        );
        canvas.drawLine(
          Offset(w * 0.38, h * 0.50),
          Offset(w * 0.62, h * 0.50),
          stroke,
        );

      case QrGlyph.wifi:
        for (final r in <double>[0.38, 0.25]) {
          canvas.drawArc(
            Rect.fromCircle(
              center: Offset(w * 0.5, h * 0.72),
              radius: w * r * 1.3,
            ),
            -math.pi * 0.78,
            math.pi * 0.56,
            false,
            stroke,
          );
        }
        canvas.drawCircle(Offset(w * 0.5, h * 0.74), w * 0.06, fill);

      case QrGlyph.sparkle:
        final path = Path()
          ..moveTo(w * 0.50, h * 0.12)
          ..quadraticBezierTo(w * 0.53, h * 0.47, w * 0.88, h * 0.50)
          ..quadraticBezierTo(w * 0.53, h * 0.53, w * 0.50, h * 0.88)
          ..quadraticBezierTo(w * 0.47, h * 0.53, w * 0.12, h * 0.50)
          ..quadraticBezierTo(w * 0.47, h * 0.47, w * 0.50, h * 0.12)
          ..close();
        canvas.drawPath(path, fill);

      case QrGlyph.history:
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.35, stroke);
        final hand = Path()
          ..moveTo(w * 0.50, h * 0.30)
          ..lineTo(w * 0.50, h * 0.52)
          ..lineTo(w * 0.66, h * 0.60);
        canvas.drawPath(hand, stroke);

      case QrGlyph.layers:
        final top = Path()
          ..moveTo(w * 0.50, h * 0.16)
          ..lineTo(w * 0.84, h * 0.34)
          ..lineTo(w * 0.50, h * 0.52)
          ..lineTo(w * 0.16, h * 0.34)
          ..close();
        canvas.drawPath(top, stroke);
        final mid = Path()
          ..moveTo(w * 0.16, h * 0.50)
          ..lineTo(w * 0.50, h * 0.68)
          ..lineTo(w * 0.84, h * 0.50);
        canvas.drawPath(mid, stroke);
        final bot = Path()
          ..moveTo(w * 0.16, h * 0.66)
          ..lineTo(w * 0.50, h * 0.84)
          ..lineTo(w * 0.84, h * 0.66);
        canvas.drawPath(bot, stroke);

      case QrGlyph.focus:
        const b = 0.18;
        const len = 0.18;
        final corners = Path()
          ..moveTo(w * b, h * (b + len))
          ..lineTo(w * b, h * b)
          ..lineTo(w * (b + len), h * b)
          ..moveTo(w * (1 - b - len), h * b)
          ..lineTo(w * (1 - b), h * b)
          ..lineTo(w * (1 - b), h * (b + len))
          ..moveTo(w * (1 - b), h * (1 - b - len))
          ..lineTo(w * (1 - b), h * (1 - b))
          ..lineTo(w * (1 - b - len), h * (1 - b))
          ..moveTo(w * (b + len), h * (1 - b))
          ..lineTo(w * b, h * (1 - b))
          ..lineTo(w * b, h * (1 - b - len));
        canvas.drawPath(corners, stroke);
        canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.10, fill);

      case QrGlyph.close:
        canvas.drawLine(
          Offset(w * 0.24, h * 0.24),
          Offset(w * 0.76, h * 0.76),
          stroke,
        );
        canvas.drawLine(
          Offset(w * 0.76, h * 0.24),
          Offset(w * 0.24, h * 0.76),
          stroke,
        );

      case QrGlyph.shieldCheck:
        final shield = Path()
          ..moveTo(w * 0.50, h * 0.14)
          ..lineTo(w * 0.82, h * 0.26)
          ..lineTo(w * 0.82, h * 0.52)
          ..quadraticBezierTo(w * 0.82, h * 0.78, w * 0.50, h * 0.88)
          ..quadraticBezierTo(w * 0.18, h * 0.78, w * 0.18, h * 0.52)
          ..lineTo(w * 0.18, h * 0.26)
          ..close();
        canvas.drawPath(shield, stroke);
        final check = Path()
          ..moveTo(w * 0.36, h * 0.52)
          ..lineTo(w * 0.46, h * 0.62)
          ..lineTo(w * 0.66, h * 0.40);
        canvas.drawPath(check, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _QrVectorIconPainter oldDelegate) {
    return oldDelegate.glyph != glyph ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Resolution-independent vector widget that renders scannable 2D QR Codes
/// and 1D Barcodes (`EAN-13`, `EAN-8`, `UPC-A`, `Code-128`, `Code-39`, `ITF`, `Codabar`).
class QrBarcodeGraphic extends StatelessWidget {
  /// Creates a [QrBarcodeGraphic].
  const QrBarcodeGraphic({
    super.key,
    required this.data,
    this.format = QrBarcodeFormat.qrCode,
    this.width = 140.0,
    this.height = 140.0,
    this.foregroundColor = const Color(0xFF0F172A),
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.gradient,
    this.finderEyeStyle = QrFinderEyeStyle.rounded,
    this.roundedModules = true,
    this.showLabel = true,
    this.padding = const EdgeInsets.all(10),
    this.borderRadius = 14.0,
  });

  /// String content to encode and render.
  final String data;

  /// Symbology format to render ([QrBarcodeFormat.qrCode] or any 1D format).
  final QrBarcodeFormat format;

  /// Outer width of the rendered card in logical pixels.
  final double width;

  /// Outer height of the rendered card in logical pixels.
  final double height;

  /// Dark module / bar color (overridden if [gradient] is provided).
  final Color foregroundColor;

  /// Quiet-zone background card color.
  final Color backgroundColor;

  /// Optional gradient shader applied to the QR modules or barcode bars.
  final Gradient? gradient;

  /// Visual shape of the three corner finder eyes for 2D QR codes.
  final QrFinderEyeStyle finderEyeStyle;

  /// Whether 2D data modules are drawn with softly rounded corners.
  final bool roundedModules;

  /// Whether to render the human-readable text below 1D barcode bars.
  final bool showLabel;

  /// Quiet-zone padding around the code.
  final EdgeInsets padding;

  /// Corner radius of the background container.
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: format.is2D ? _build2DCanvas() : _build1DColumn(),
    );
  }

  Widget _build2DCanvas() {
    final matrix = QrBarcodeCodec.encodeQrMatrix(data);
    return CustomPaint(
      size: Size.infinite,
      painter: _QrMatrixGraphicPainter(
        matrix: matrix,
        foregroundColor: foregroundColor,
        gradient: gradient,
        finderEyeStyle: finderEyeStyle,
        roundedModules: roundedModules,
      ),
    );
  }

  Widget _build1DColumn() {
    final modules = QrBarcodeCodec.encodeLinear(data, format: format);
    final labelText = _displayDigitsForFormat();
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: CustomPaint(
            painter: _LinearBarcodeGraphicPainter(
              modules: modules,
              foregroundColor: foregroundColor,
              gradient: gradient,
            ),
          ),
        ),
        if (showLabel) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            labelText,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  String _displayDigitsForFormat() {
    switch (format) {
      case QrBarcodeFormat.ean13:
        return QrBarcodeCodec.normalizeEan13Digits(data);
      case QrBarcodeFormat.ean8:
        return QrBarcodeCodec.normalizeEan8Digits(data);
      case QrBarcodeFormat.upcA:
      case QrBarcodeFormat.upcE:
        return QrBarcodeCodec.normalizeUpcADigits(data);
      default:
        return data;
    }
  }
}

class _QrMatrixGraphicPainter extends CustomPainter {
  const _QrMatrixGraphicPainter({
    required this.matrix,
    required this.foregroundColor,
    required this.gradient,
    required this.finderEyeStyle,
    required this.roundedModules,
  });

  final List<List<bool>> matrix;
  final Color foregroundColor;
  final Gradient? gradient;
  final QrFinderEyeStyle finderEyeStyle;
  final bool roundedModules;

  @override
  void paint(Canvas canvas, Size size) {
    final n = matrix.length;
    if (n == 0) {
      return;
    }
    final side = math.min(size.width, size.height);
    final offsetX = (size.width - side) / 2;
    final offsetY = (size.height - side) / 2;
    final cell = side / n;

    final paint = Paint()..color = foregroundColor;
    if (gradient != null) {
      paint.shader = gradient!.createShader(
        Rect.fromLTWH(offsetX, offsetY, side, side),
      );
    }

    bool isInFinderEye(int r, int c) {
      final topLeft = r < 7 && c < 7;
      final topRight = r < 7 && c >= n - 7;
      final bottomLeft = r >= n - 7 && c < 7;
      return topLeft || topRight || bottomLeft;
    }

    // Paint stylized finder eyes
    _paintFinderEye(canvas, offsetX, offsetY, cell, paint);
    _paintFinderEye(canvas, offsetX + (n - 7) * cell, offsetY, cell, paint);
    _paintFinderEye(canvas, offsetX, offsetY + (n - 7) * cell, cell, paint);

    // Paint data modules
    final radius = Radius.circular(roundedModules ? cell * 0.34 : 0);
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (!matrix[r][c] || isInFinderEye(r, c)) {
          continue;
        }
        final rect = Rect.fromLTWH(
          offsetX + c * cell + cell * 0.04,
          offsetY + r * cell + cell * 0.04,
          cell * 0.92,
          cell * 0.92,
        );
        if (roundedModules) {
          canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
        } else {
          canvas.drawRect(rect, paint);
        }
      }
    }
  }

  void _paintFinderEye(
    Canvas canvas,
    double left,
    double top,
    double cell,
    Paint fillPaint,
  ) {
    final outerSize = 7 * cell;
    final outerRect = Rect.fromLTWH(
      left + cell * 0.5,
      top + cell * 0.5,
      outerSize - cell,
      outerSize - cell,
    );
    final innerRect = Rect.fromLTWH(
      left + 2 * cell,
      top + 2 * cell,
      3 * cell,
      3 * cell,
    );

    final ringPaint = Paint()
      ..color = fillPaint.color
      ..shader = fillPaint.shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = cell;

    switch (finderEyeStyle) {
      case QrFinderEyeStyle.circle:
        canvas.drawOval(outerRect, ringPaint);
        canvas.drawOval(innerRect, fillPaint);
      case QrFinderEyeStyle.diamond:
        canvas.drawRRect(
          RRect.fromRectAndRadius(outerRect, Radius.circular(cell * 0.6)),
          ringPaint,
        );
        final cx = innerRect.center.dx;
        final cy = innerRect.center.dy;
        final hw = innerRect.width / 2;
        final diamond = Path()
          ..moveTo(cx, cy - hw)
          ..lineTo(cx + hw, cy)
          ..lineTo(cx, cy + hw)
          ..lineTo(cx - hw, cy)
          ..close();
        canvas.drawPath(diamond, fillPaint);
      case QrFinderEyeStyle.rounded:
        canvas.drawRRect(
          RRect.fromRectAndRadius(outerRect, Radius.circular(cell * 1.6)),
          ringPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(innerRect, Radius.circular(cell * 0.85)),
          fillPaint,
        );
      case QrFinderEyeStyle.sharp:
        canvas.drawRect(outerRect, ringPaint);
        canvas.drawRect(innerRect, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _QrMatrixGraphicPainter oldDelegate) {
    return oldDelegate.matrix != matrix ||
        oldDelegate.foregroundColor != foregroundColor ||
        oldDelegate.finderEyeStyle != finderEyeStyle ||
        oldDelegate.roundedModules != roundedModules;
  }
}

class _LinearBarcodeGraphicPainter extends CustomPainter {
  const _LinearBarcodeGraphicPainter({
    required this.modules,
    required this.foregroundColor,
    required this.gradient,
  });

  final List<int> modules;
  final Color foregroundColor;
  final Gradient? gradient;

  @override
  void paint(Canvas canvas, Size size) {
    if (modules.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    final barWidth = size.width / modules.length;
    final paint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.fill;
    if (gradient != null) {
      paint.shader = gradient!.createShader(Offset.zero & size);
    }

    var i = 0;
    while (i < modules.length) {
      if (modules[i] == 0) {
        i++;
        continue;
      }
      var runEnd = i + 1;
      while (runEnd < modules.length && modules[runEnd] == 1) {
        runEnd++;
      }
      final rect = Rect.fromLTWH(
        i * barWidth,
        0,
        (runEnd - i) * barWidth,
        size.height,
      );
      canvas.drawRect(rect, paint);
      i = runEnd;
    }
  }

  @override
  bool shouldRepaint(covariant _LinearBarcodeGraphicPainter oldDelegate) {
    return oldDelegate.modules != modules ||
        oldDelegate.foregroundColor != foregroundColor;
  }
}
