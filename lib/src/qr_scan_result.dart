import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'qr_enums.dart';
import 'qr_payload_parser.dart';

/// Immutable detection result emitted when a QR code or 1D barcode is decoded.
@immutable
class QrScanResult {
  /// Creates a [QrScanResult].
  ///
  /// If [payload] is omitted, it is automatically parsed from [rawValue] and
  /// [format] via [QrPayloadParser.parse].
  QrScanResult({
    required this.rawValue,
    required this.format,
    QrParsedPayload? payload,
    List<Offset>? corners,
    this.confidence = 0.98,
    DateTime? timestamp,
    this.rawBytes,
    this.isInverted = false,
    this.scanDurationMicroseconds = 420,
  }) : payload = payload ?? QrPayloadParser.parse(rawValue, format: format),
       corners = List<Offset>.unmodifiable(
         corners ?? _defaultCornersForFormat(format),
       ),
       timestamp = timestamp ?? DateTime.now();

  /// Decoded string content of the barcode or QR code.
  final String rawValue;

  /// Symbology format of the detected code.
  final QrBarcodeFormat format;

  /// Semantic structured payload parsed from [rawValue].
  final QrParsedPayload payload;

  /// Four normalized (`0.0..1.0`) corner points `[topLeft, topRight, bottomRight, bottomLeft]`
  /// localizing the code within the scan frame.
  final List<Offset> corners;

  /// Detection confidence score in the range `0.0..1.0`.
  final double confidence;

  /// Timestamp when the detection completed.
  final DateTime timestamp;

  /// Optional raw payload bytes.
  final Uint8List? rawBytes;

  /// Whether the code was decoded from an inverted (light-on-dark) region.
  final bool isInverted;

  /// Processing time of the frame decode in microseconds.
  final int scanDurationMicroseconds;

  /// Normalized axis-aligned bounding box derived from [corners].
  Rect get boundingBox {
    if (corners.isEmpty) {
      return const Rect.fromLTWH(0.2, 0.2, 0.6, 0.6);
    }
    var minX = corners.first.dx;
    var maxX = corners.first.dx;
    var minY = corners.first.dy;
    var maxY = corners.first.dy;
    for (final pt in corners) {
      minX = math.min(minX, pt.dx);
      maxX = math.max(maxX, pt.dx);
      minY = math.min(minY, pt.dy);
      maxY = math.max(maxY, pt.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Center point of [boundingBox] in normalized frame coordinates.
  Offset get center => boundingBox.center;

  /// Creates a modified copy of this [QrScanResult].
  QrScanResult copyWith({
    String? rawValue,
    QrBarcodeFormat? format,
    QrParsedPayload? payload,
    List<Offset>? corners,
    double? confidence,
    DateTime? timestamp,
    Uint8List? rawBytes,
    bool? isInverted,
    int? scanDurationMicroseconds,
  }) {
    return QrScanResult(
      rawValue: rawValue ?? this.rawValue,
      format: format ?? this.format,
      payload:
          payload ?? (rawValue != null || format != null ? null : this.payload),
      corners: corners ?? this.corners,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
      rawBytes: rawBytes ?? this.rawBytes,
      isInverted: isInverted ?? this.isInverted,
      scanDurationMicroseconds:
          scanDurationMicroseconds ?? this.scanDurationMicroseconds,
    );
  }

  static List<Offset> _defaultCornersForFormat(QrBarcodeFormat format) {
    if (format.is2D) {
      return const <Offset>[
        Offset(0.24, 0.24),
        Offset(0.76, 0.24),
        Offset(0.76, 0.76),
        Offset(0.24, 0.76),
      ];
    }
    return const <Offset>[
      Offset(0.16, 0.36),
      Offset(0.84, 0.36),
      Offset(0.84, 0.64),
      Offset(0.16, 0.64),
    ];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is QrScanResult &&
        other.rawValue == rawValue &&
        other.format == format &&
        other.isInverted == isInverted &&
        listEquals(other.corners, corners);
  }

  @override
  int get hashCode =>
      Object.hash(rawValue, format, isInverted, Object.hashAll(corners));

  @override
  String toString() =>
      'QrScanResult(format: ${format.displayName}, value: "$rawValue", confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
}

/// Raw image or camera frame buffer passed to `QrBarcodeDecoder` or `QrScannerController`.
@immutable
class QrScanFrame {
  /// Creates a [QrScanFrame].
  const QrScanFrame({
    required this.bytes,
    required this.width,
    required this.height,
    this.pixelFormat = QrPixelFormat.rgba8888,
    int? rowStride,
    this.rotationDegrees = 0,
  }) : rowStride =
           rowStride ??
           (pixelFormat == QrPixelFormat.rgba8888 ||
                   pixelFormat == QrPixelFormat.bgra8888
               ? width * 4
               : width);

  /// Creates a [QrScanFrame] from a 32-bit RGBA pixel buffer.
  factory QrScanFrame.fromRgba({
    required Uint8List bytes,
    required int width,
    required int height,
    int? rowStride,
    int rotationDegrees = 0,
  }) {
    return QrScanFrame(
      bytes: bytes,
      width: width,
      height: height,
      pixelFormat: QrPixelFormat.rgba8888,
      rowStride: rowStride,
      rotationDegrees: rotationDegrees,
    );
  }

  /// Creates a [QrScanFrame] from a 32-bit BGRA pixel buffer (common on iOS/macOS).
  factory QrScanFrame.fromBgra({
    required Uint8List bytes,
    required int width,
    required int height,
    int? rowStride,
    int rotationDegrees = 0,
  }) {
    return QrScanFrame(
      bytes: bytes,
      width: width,
      height: height,
      pixelFormat: QrPixelFormat.bgra8888,
      rowStride: rowStride,
      rotationDegrees: rotationDegrees,
    );
  }

  /// Creates a [QrScanFrame] from a single-channel 8-bit grayscale buffer.
  factory QrScanFrame.fromGrayscale({
    required Uint8List bytes,
    required int width,
    required int height,
    int? rowStride,
    int rotationDegrees = 0,
  }) {
    return QrScanFrame(
      bytes: bytes,
      width: width,
      height: height,
      pixelFormat: QrPixelFormat.grayscale8,
      rowStride: rowStride,
      rotationDegrees: rotationDegrees,
    );
  }

  /// Creates a [QrScanFrame] from a YUV420 luma (Y) plane buffer.
  factory QrScanFrame.fromYuv420({
    required Uint8List yPlane,
    required int width,
    required int height,
    int? rowStride,
    int rotationDegrees = 0,
  }) {
    return QrScanFrame(
      bytes: yPlane,
      width: width,
      height: height,
      pixelFormat: QrPixelFormat.yuv420,
      rowStride: rowStride,
      rotationDegrees: rotationDegrees,
    );
  }

  /// Rasterizes a 2D boolean QR matrix into an 8-bit grayscale [QrScanFrame].
  ///
  /// Useful for testing, synthetic camera feeds, and offline verification.
  factory QrScanFrame.fromBinaryMatrix(
    List<List<bool>> matrix, {
    int quietZoneModules = 4,
    int moduleScale = 4,
    bool inverted = false,
    int darkLuma = 16,
    int lightLuma = 244,
  }) {
    final rows = matrix.length;
    final cols = rows > 0 ? matrix.first.length : 0;
    final totalCols = (cols + quietZoneModules * 2) * moduleScale;
    final totalRows = (rows + quietZoneModules * 2) * moduleScale;
    final bg = inverted ? darkLuma : lightLuma;
    final fg = inverted ? lightLuma : darkLuma;
    final buffer = Uint8List(totalCols * totalRows)
      ..fillRange(0, totalCols * totalRows, bg);

    for (var r = 0; r < rows; r++) {
      final row = matrix[r];
      for (var c = 0; c < row.length; c++) {
        if (!row[c]) {
          continue;
        }
        final startY = (r + quietZoneModules) * moduleScale;
        final startX = (c + quietZoneModules) * moduleScale;
        for (var dy = 0; dy < moduleScale; dy++) {
          final rowOffset = (startY + dy) * totalCols + startX;
          for (var dx = 0; dx < moduleScale; dx++) {
            buffer[rowOffset + dx] = fg;
          }
        }
      }
    }

    return QrScanFrame.fromGrayscale(
      bytes: buffer,
      width: totalCols,
      height: totalRows,
    );
  }

  /// Rasterizes a 1D binary barcode module array (`0` for space, `1` for bar)
  /// into an 8-bit grayscale [QrScanFrame].
  factory QrScanFrame.fromLinearModules(
    List<int> modules, {
    int height = 64,
    int quietZoneModules = 10,
    int moduleScale = 3,
    int verticalMargin = 12,
    bool inverted = false,
    int darkLuma = 14,
    int lightLuma = 245,
  }) {
    final totalWidth = (modules.length + quietZoneModules * 2) * moduleScale;
    final totalHeight = height + verticalMargin * 2;
    final bg = inverted ? darkLuma : lightLuma;
    final fg = inverted ? lightLuma : darkLuma;
    final buffer = Uint8List(totalWidth * totalHeight)
      ..fillRange(0, totalWidth * totalHeight, bg);

    for (var i = 0; i < modules.length; i++) {
      if (modules[i] == 0) {
        continue;
      }
      final startX = (i + quietZoneModules) * moduleScale;
      for (var y = verticalMargin; y < totalHeight - verticalMargin; y++) {
        final rowOffset = y * totalWidth + startX;
        for (var dx = 0; dx < moduleScale; dx++) {
          buffer[rowOffset + dx] = fg;
        }
      }
    }

    return QrScanFrame.fromGrayscale(
      bytes: buffer,
      width: totalWidth,
      height: totalHeight,
    );
  }

  /// Raw pixel bytes of the frame.
  final Uint8List bytes;

  /// Frame width in pixels.
  final int width;

  /// Frame height in pixels.
  final int height;

  /// Encoding format of [bytes].
  final QrPixelFormat pixelFormat;

  /// Number of bytes per horizontal pixel row.
  final int rowStride;

  /// Clockwise sensor rotation in degrees (`0`, `90`, `180`, `270`).
  final int rotationDegrees;

  /// Converts this frame into a packed 8-bit grayscale luminance array (`width * height`).
  Uint8List toGrayscale() {
    if (width <= 0 || height <= 0) {
      return Uint8List(0);
    }

    if ((pixelFormat == QrPixelFormat.grayscale8 ||
            pixelFormat == QrPixelFormat.yuv420) &&
        rowStride == width &&
        bytes.length >= width * height) {
      return Uint8List.sublistView(bytes, 0, width * height);
    }

    final gray = Uint8List(width * height);
    switch (pixelFormat) {
      case QrPixelFormat.grayscale8:
      case QrPixelFormat.yuv420:
        for (var y = 0; y < height; y++) {
          final srcRow = y * rowStride;
          final dstRow = y * width;
          for (var x = 0; x < width; x++) {
            final idx = srcRow + x;
            gray[dstRow + x] = idx < bytes.length ? bytes[idx] : 255;
          }
        }
      case QrPixelFormat.rgba8888:
        for (var y = 0; y < height; y++) {
          final srcRow = y * rowStride;
          final dstRow = y * width;
          for (var x = 0; x < width; x++) {
            final idx = srcRow + x * 4;
            if (idx + 2 < bytes.length) {
              final r = bytes[idx];
              final g = bytes[idx + 1];
              final b = bytes[idx + 2];
              gray[dstRow + x] = (77 * r + 150 * g + 29 * b) >> 8;
            } else {
              gray[dstRow + x] = 255;
            }
          }
        }
      case QrPixelFormat.bgra8888:
        for (var y = 0; y < height; y++) {
          final srcRow = y * rowStride;
          final dstRow = y * width;
          for (var x = 0; x < width; x++) {
            final idx = srcRow + x * 4;
            if (idx + 2 < bytes.length) {
              final b = bytes[idx];
              final g = bytes[idx + 1];
              final r = bytes[idx + 2];
              gray[dstRow + x] = (77 * r + 150 * g + 29 * b) >> 8;
            } else {
              gray[dstRow + x] = 255;
            }
          }
        }
    }
    return gray;
  }
}
