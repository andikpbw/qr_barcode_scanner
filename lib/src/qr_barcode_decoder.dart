import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'qr_barcode_codec.dart';
import 'qr_enums.dart';
import 'qr_scan_result.dart';

/// High-speed, zero-dependency real-time pixel decoder for 2D QR Codes and 1D Barcodes.
class QrBarcodeDecoder {
  const QrBarcodeDecoder._();

  /// Decodes all detectable QR codes and 1D barcodes from [frame].
  ///
  /// - [allowedFormats]: optional filter restricting which symbologies are tested.
  /// - [scanWindow]: optional normalized (`0.0..1.0`) region of interest.
  /// - [tryInverted]: whether to also attempt decoding white-on-black codes.
  static List<QrScanResult> decodeFrame(
    QrScanFrame frame, {
    Set<QrBarcodeFormat>? allowedFormats,
    Rect? scanWindow,
    bool tryInverted = true,
  }) {
    final stopwatch = Stopwatch()..start();
    if (frame.width < 16 || frame.height < 16 || frame.bytes.isEmpty) {
      return const <QrScanResult>[];
    }

    final gray = frame.toGrayscale();
    if (gray.isEmpty) {
      return const <QrScanResult>[];
    }

    final roi = _resolvePixelRoi(frame.width, frame.height, scanWindow);
    final threshold = _computeAdaptiveThreshold(gray, frame.width, roi);

    final results = <QrScanResult>[];

    // Pass 1: Normal polarity (dark modules on light background)
    _decodePass(
      gray: gray,
      width: frame.width,
      height: frame.height,
      roi: roi,
      threshold: threshold,
      inverted: false,
      allowedFormats: allowedFormats,
      stopwatch: stopwatch,
      results: results,
    );

    // Pass 2: Inverted polarity (light modules on dark background)
    if (results.isEmpty && tryInverted) {
      _decodePass(
        gray: gray,
        width: frame.width,
        height: frame.height,
        roi: roi,
        threshold: threshold,
        inverted: true,
        allowedFormats: allowedFormats,
        stopwatch: stopwatch,
        results: results,
      );
    }

    return results;
  }

  /// Convenience method to decode the single highest-confidence result from [frame].
  static QrScanResult? decodeSingle(
    QrScanFrame frame, {
    Set<QrBarcodeFormat>? allowedFormats,
    Rect? scanWindow,
    bool tryInverted = true,
  }) {
    final all = decodeFrame(
      frame,
      allowedFormats: allowedFormats,
      scanWindow: scanWindow,
      tryInverted: tryInverted,
    );
    return all.isEmpty ? null : all.first;
  }

  static void _decodePass({
    required Uint8List gray,
    required int width,
    required int height,
    required _PixelRoi roi,
    required int threshold,
    required bool inverted,
    required Set<QrBarcodeFormat>? allowedFormats,
    required Stopwatch stopwatch,
    required List<QrScanResult> results,
  }) {
    final allowQr =
        allowedFormats == null ||
        allowedFormats.isEmpty ||
        allowedFormats.contains(QrBarcodeFormat.qrCode);

    if (allowQr) {
      final qrResult = _tryDecode2DQr(
        gray: gray,
        width: width,
        height: height,
        roi: roi,
        threshold: threshold,
        inverted: inverted,
        stopwatch: stopwatch,
      );
      if (qrResult != null) {
        results.add(qrResult);
      }
    }

    final allow1D =
        allowedFormats == null ||
        allowedFormats.isEmpty ||
        allowedFormats.any((f) => f.is1D);
    if (allow1D) {
      final linearResults = _tryDecode1DScanlines(
        gray: gray,
        width: width,
        height: height,
        roi: roi,
        threshold: threshold,
        inverted: inverted,
        allowedFormats: allowedFormats,
        stopwatch: stopwatch,
      );
      for (final item in linearResults) {
        if (!results.any(
          (r) => r.rawValue == item.rawValue && r.format == item.format,
        )) {
          results.add(item);
        }
      }
    }
  }

  static QrScanResult? _tryDecode2DQr({
    required Uint8List gray,
    required int width,
    required int height,
    required _PixelRoi roi,
    required int threshold,
    required bool inverted,
    required Stopwatch stopwatch,
  }) {
    bool isDark(int x, int y) {
      final val = gray[y * width + x];
      return inverted ? val > threshold : val < threshold;
    }

    // Locate candidate bounding boxes (first via 1:1:3:1:1 finder centers, then tight dark bounds)
    final candidateBoxes = <_PixelRoi>[];

    final finderBox = _locateFinderBoundingBox(
      width: width,
      height: height,
      roi: roi,
      isDark: isDark,
    );
    if (finderBox != null) {
      candidateBoxes.add(finderBox);
    }

    final tightBox = _computeTightDarkBox(roi: roi, isDark: isDark);
    if (tightBox != null) {
      candidateBoxes.add(tightBox);
    }

    const candidateSizes = <int>[21, 25, 29, 33, 37];

    for (final box in candidateBoxes) {
      final boxW = box.right - box.left + 1;
      final boxH = box.bottom - box.top + 1;
      if (boxW < 21 || boxH < 21) {
        continue;
      }

      for (final n in candidateSizes) {
        final matrix = List<List<bool>>.generate(n, (r) {
          final py = (box.top + ((r + 0.5) * boxH) / n).floor().clamp(
            0,
            height - 1,
          );
          return List<bool>.generate(n, (c) {
            final px = (box.left + ((c + 0.5) * boxW) / n).floor().clamp(
              0,
              width - 1,
            );
            return isDark(px, py);
          });
        });

        final decoded = QrBarcodeCodec.decodeQrMatrix(matrix);
        if (decoded != null) {
          final normLeft = (box.left / width).clamp(0.0, 1.0);
          final normTop = (box.top / height).clamp(0.0, 1.0);
          final normRight = ((box.right + 1) / width).clamp(0.0, 1.0);
          final normBottom = ((box.bottom + 1) / height).clamp(0.0, 1.0);

          return QrScanResult(
            rawValue: decoded,
            format: QrBarcodeFormat.qrCode,
            corners: <Offset>[
              Offset(normLeft, normTop),
              Offset(normRight, normTop),
              Offset(normRight, normBottom),
              Offset(normLeft, normBottom),
            ],
            confidence: 0.99,
            isInverted: inverted,
            scanDurationMicroseconds: stopwatch.elapsedMicroseconds,
          );
        }
      }
    }

    return null;
  }

  static _PixelRoi? _locateFinderBoundingBox({
    required int width,
    required int height,
    required _PixelRoi roi,
    required bool Function(int x, int y) isDark,
  }) {
    final centers = <Offset>[];
    final stepY = math.max(1, (roi.bottom - roi.top) ~/ 48);

    for (var y = roi.top; y <= roi.bottom; y += stepY) {
      final runs = <int>[];
      final runStarts = <int>[];
      var currentDark = isDark(roi.left, y);
      var count = 0;
      var runStart = roi.left;

      for (var x = roi.left; x <= roi.right; x++) {
        final d = isDark(x, y);
        if (d == currentDark) {
          count++;
        } else {
          runs.add(count);
          runStarts.add(runStart);
          currentDark = d;
          count = 1;
          runStart = x;
        }
      }
      runs.add(count);
      runStarts.add(runStart);

      // Look for dark-light-dark-light-dark with 1:1:3:1:1 ratio
      final firstDarkIdx = isDark(roi.left, y) ? 0 : 1;
      for (var i = firstDarkIdx; i + 4 < runs.length; i += 2) {
        final r0 = runs[i];
        final r1 = runs[i + 1];
        final r2 = runs[i + 2];
        final r3 = runs[i + 3];
        final r4 = runs[i + 4];
        if (_isFinderRatio(r0, r1, r2, r3, r4)) {
          final totalW = r0 + r1 + r2 + r3 + r4;
          final centerX = runStarts[i] + totalW / 2.0;
          centers.add(Offset(centerX, y.toDouble()));
        }
      }
    }

    if (centers.length < 3) {
      return null;
    }

    // Refine outer limits from detected finder lines
    return _computeTightDarkBox(roi: roi, isDark: isDark);
  }

  static bool _isFinderRatio(int r0, int r1, int r2, int r3, int r4) {
    final total = r0 + r1 + r2 + r3 + r4;
    if (total < 7) {
      return false;
    }
    final module = total / 7.0;
    final tol = module * 0.75;
    return (r0 - module).abs() <= tol &&
        (r1 - module).abs() <= tol &&
        (r2 - 3.0 * module).abs() <= 1.6 * tol &&
        (r3 - module).abs() <= tol &&
        (r4 - module).abs() <= tol;
  }

  static _PixelRoi? _computeTightDarkBox({
    required _PixelRoi roi,
    required bool Function(int x, int y) isDark,
  }) {
    var minX = roi.right + 1;
    var maxX = roi.left - 1;
    var minY = roi.bottom + 1;
    var maxY = roi.top - 1;

    for (var y = roi.top; y <= roi.bottom; y++) {
      for (var x = roi.left; x <= roi.right; x++) {
        if (isDark(x, y)) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (minX > maxX || minY > maxY) {
      return null;
    }
    return _PixelRoi(left: minX, top: minY, right: maxX, bottom: maxY);
  }

  static List<QrScanResult> _tryDecode1DScanlines({
    required Uint8List gray,
    required int width,
    required int height,
    required _PixelRoi roi,
    required int threshold,
    required bool inverted,
    required Set<QrBarcodeFormat>? allowedFormats,
    required Stopwatch stopwatch,
  }) {
    bool isAllowed(QrBarcodeFormat fmt) =>
        allowedFormats == null ||
        allowedFormats.isEmpty ||
        allowedFormats.contains(fmt);

    final roiHeight = roi.bottom - roi.top + 1;
    final roiWidth = roi.right - roi.left + 1;

    // Sample 11 horizontal scanlines and 7 vertical scanlines across ROI
    final ySamples = <int>{
      roi.top + roiHeight ~/ 2,
      for (var i = 1; i <= 9; i++) roi.top + (roiHeight * i) ~/ 10,
    };

    final hits = <String, _LinearHitAccumulator>{};

    for (final y in ySamples) {
      if (y < roi.top || y > roi.bottom) {
        continue;
      }
      final line = List<bool>.generate(roiWidth, (i) {
        final val = gray[y * width + (roi.left + i)];
        return inverted ? val > threshold : val < threshold;
      });

      _evaluateBinaryScanline(
        line: line,
        isHorizontal: true,
        fixedCoord: y,
        roi: roi,
        isAllowed: isAllowed,
        hits: hits,
      );
    }

    // If no horizontal hits, also check vertical scanlines (for 90-degree rotated barcodes)
    if (hits.isEmpty) {
      final xSamples = <int>{
        roi.left + roiWidth ~/ 2,
        for (var i = 2; i <= 8; i += 2) roi.left + (roiWidth * i) ~/ 10,
      };
      for (final x in xSamples) {
        if (x < roi.left || x > roi.right) {
          continue;
        }
        final line = List<bool>.generate(roiHeight, (i) {
          final val = gray[(roi.top + i) * width + x];
          return inverted ? val > threshold : val < threshold;
        });
        _evaluateBinaryScanline(
          line: line,
          isHorizontal: false,
          fixedCoord: x,
          roi: roi,
          isAllowed: isAllowed,
          hits: hits,
        );
      }
    }

    if (hits.isEmpty) {
      return const <QrScanResult>[];
    }

    final output = <QrScanResult>[];
    for (final acc in hits.values) {
      final normLeft = (acc.minX / width).clamp(0.0, 1.0);
      final normRight = ((acc.maxX + 1) / width).clamp(0.0, 1.0);
      final normTop = (math.max(0, acc.minY - 12) / height).clamp(0.0, 1.0);
      final normBottom = (math.min(height, acc.maxY + 12) / height).clamp(
        0.0,
        1.0,
      );
      final confidence = (0.90 + math.min(0.09, acc.count * 0.015)).clamp(
        0.0,
        0.99,
      );

      output.add(
        QrScanResult(
          rawValue: acc.rawValue,
          format: acc.format,
          corners: <Offset>[
            Offset(normLeft, normTop),
            Offset(normRight, normTop),
            Offset(normRight, normBottom),
            Offset(normLeft, normBottom),
          ],
          confidence: confidence,
          isInverted: inverted,
          scanDurationMicroseconds: stopwatch.elapsedMicroseconds,
        ),
      );
    }

    return output;
  }

  static void _evaluateBinaryScanline({
    required List<bool> line,
    required bool isHorizontal,
    required int fixedCoord,
    required _PixelRoi roi,
    required bool Function(QrBarcodeFormat) isAllowed,
    required Map<String, _LinearHitAccumulator> hits,
  }) {
    var firstBar = -1;
    var lastBar = -1;
    for (var i = 0; i < line.length; i++) {
      if (line[i]) {
        if (firstBar == -1) firstBar = i;
        lastBar = i;
      }
    }
    if (firstBar == -1 || lastBar <= firstBar) {
      return;
    }

    final runs = QrBarcodeCodec.extractBarSpaceRuns(line);
    if (runs.length < 23) {
      return;
    }

    String? decoded;
    QrBarcodeFormat? matchedFormat;

    if (isAllowed(QrBarcodeFormat.code128)) {
      decoded = QrBarcodeCodec.decodeCode128Runs(runs);
      if (decoded != null) {
        matchedFormat = QrBarcodeFormat.code128;
      }
    }

    if (decoded == null &&
        (isAllowed(QrBarcodeFormat.ean13) || isAllowed(QrBarcodeFormat.upcA))) {
      final ean = QrBarcodeCodec.decodeEan13Runs(runs);
      if (ean != null) {
        if (ean.startsWith('0') &&
            isAllowed(QrBarcodeFormat.upcA) &&
            !isAllowed(QrBarcodeFormat.ean13)) {
          decoded = ean.substring(1);
          matchedFormat = QrBarcodeFormat.upcA;
        } else {
          decoded = ean;
          matchedFormat = QrBarcodeFormat.ean13;
        }
      }
    }

    if (decoded == null && isAllowed(QrBarcodeFormat.ean8)) {
      decoded = QrBarcodeCodec.decodeEan8Runs(runs);
      if (decoded != null) {
        matchedFormat = QrBarcodeFormat.ean8;
      }
    }

    if (decoded == null && isAllowed(QrBarcodeFormat.code39)) {
      decoded = QrBarcodeCodec.decodeCode39Runs(runs);
      if (decoded != null) {
        matchedFormat = QrBarcodeFormat.code39;
      }
    }

    if (decoded == null && isAllowed(QrBarcodeFormat.itf)) {
      decoded = QrBarcodeCodec.decodeItfRuns(runs);
      if (decoded != null) {
        matchedFormat = QrBarcodeFormat.itf;
      }
    }

    if (decoded == null && isAllowed(QrBarcodeFormat.codabar)) {
      decoded = QrBarcodeCodec.decodeCodabarRuns(runs);
      if (decoded != null) {
        matchedFormat = QrBarcodeFormat.codabar;
      }
    }

    if (decoded != null && matchedFormat != null) {
      final key = '${matchedFormat.name}:$decoded';
      final minX = isHorizontal ? roi.left + firstBar : fixedCoord;
      final maxX = isHorizontal ? roi.left + lastBar : fixedCoord;
      final minY = isHorizontal ? fixedCoord : roi.top + firstBar;
      final maxY = isHorizontal ? fixedCoord : roi.top + lastBar;

      final existing = hits[key];
      if (existing == null) {
        hits[key] = _LinearHitAccumulator(
          rawValue: decoded,
          format: matchedFormat,
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
        );
      } else {
        existing.record(minX: minX, maxX: maxX, minY: minY, maxY: maxY);
      }
    }
  }

  static _PixelRoi _resolvePixelRoi(int width, int height, Rect? window) {
    if (window == null) {
      return _PixelRoi(left: 0, top: 0, right: width - 1, bottom: height - 1);
    }
    final left = (window.left * width).floor().clamp(0, width - 1);
    final top = (window.top * height).floor().clamp(0, height - 1);
    final right = (window.right * width).ceil().clamp(left, width - 1);
    final bottom = (window.bottom * height).ceil().clamp(top, height - 1);
    return _PixelRoi(left: left, top: top, right: right, bottom: bottom);
  }

  static int _computeAdaptiveThreshold(
    Uint8List gray,
    int width,
    _PixelRoi roi,
  ) {
    var minLuma = 255;
    var maxLuma = 0;
    var sum = 0;
    var count = 0;
    final stepY = math.max(1, (roi.bottom - roi.top) ~/ 32);
    final stepX = math.max(1, (roi.right - roi.left) ~/ 32);

    for (var y = roi.top; y <= roi.bottom; y += stepY) {
      final rowOffset = y * width;
      for (var x = roi.left; x <= roi.right; x += stepX) {
        final v = gray[rowOffset + x];
        if (v < minLuma) minLuma = v;
        if (v > maxLuma) maxLuma = v;
        sum += v;
        count++;
      }
    }
    if (count == 0) {
      return 128;
    }
    final mean = sum ~/ count;
    final midRange = (minLuma + maxLuma) ~/ 2;
    return (mean + midRange) ~/ 2;
  }
}

class _PixelRoi {
  const _PixelRoi({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final int left;
  final int top;
  final int right;
  final int bottom;
}

class _LinearHitAccumulator {
  _LinearHitAccumulator({
    required this.rawValue,
    required this.format,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final String rawValue;
  final QrBarcodeFormat format;
  int minX;
  int maxX;
  int minY;
  int maxY;
  int count = 1;

  void record({
    required int minX,
    required int maxX,
    required int minY,
    required int maxY,
  }) {
    this.minX = math.min(this.minX, minX);
    this.maxX = math.max(this.maxX, maxX);
    this.minY = math.min(this.minY, minY);
    this.maxY = math.max(this.maxY, maxY);
    count++;
  }
}
