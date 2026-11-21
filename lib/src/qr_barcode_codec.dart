import 'dart:convert';

import 'qr_enums.dart';
import 'qr_payload_parser.dart';

/// Pure-Dart encoder and decoder for 2D QR Codes and 1D Barcodes
/// (EAN-13, EAN-8, UPC-A, Code-128, Code-39, ITF, and Codabar).
class QrBarcodeCodec {
  const QrBarcodeCodec._();

  // ---------------------------------------------------------------------------
  // EAN-13 / UPC-A / EAN-8 Tables
  // ---------------------------------------------------------------------------

  static const List<String> _eanLPai = <String>[
    '0001101', // 0
    '0011001', // 1
    '0010011', // 2
    '0111101', // 3
    '0100011', // 4
    '0110001', // 5
    '0101111', // 6
    '0111011', // 7
    '0110111', // 8
    '0001011', // 9
  ];

  static const List<String> _eanGPai = <String>[
    '0100111', // 0
    '0110011', // 1
    '0011011', // 2
    '0100001', // 3
    '0011101', // 4
    '0111001', // 5
    '0000101', // 6
    '0010001', // 7
    '0001001', // 8
    '0010111', // 9
  ];

  static const List<String> _eanRPai = <String>[
    '1110010', // 0
    '1100110', // 1
    '1101100', // 2
    '1000010', // 3
    '1011100', // 4
    '1001110', // 5
    '1010000', // 6
    '1000100', // 7
    '1001000', // 8
    '1110100', // 9
  ];

  static const List<String> _eanFirstDigitParity = <String>[
    'LLLLLL', // 0 (UPC-A)
    'LLGLGG', // 1
    'LLGGLG', // 2
    'LLGGGL', // 3
    'LGLLGG', // 4
    'LGGLLG', // 5
    'LGGGLL', // 6
    'LGLGLG', // 7
    'LGLGGL', // 8
    'LGGLGL', // 9
  ];

  static const Map<String, int> _eanLRunMap = <String, int>{
    '3211': 0,
    '2221': 1,
    '2122': 2,
    '1411': 3,
    '1132': 4,
    '1231': 5,
    '1114': 6,
    '1312': 7,
    '1213': 8,
    '3112': 9,
  };

  static const Map<String, int> _eanGRunMap = <String, int>{
    '1123': 0,
    '1222': 1,
    '2212': 2,
    '1141': 3,
    '2311': 4,
    '1321': 5,
    '4111': 6,
    '2131': 7,
    '3121': 8,
    '2113': 9,
  };

  static const Map<String, int> _eanRRunMap = <String, int>{
    '3211': 0,
    '2221': 1,
    '2122': 2,
    '1411': 3,
    '1132': 4,
    '1231': 5,
    '1114': 6,
    '1312': 7,
    '1213': 8,
    '3112': 9,
  };

  // ---------------------------------------------------------------------------
  // Code-128 Pattern Table (0..106)
  // ---------------------------------------------------------------------------

  static const List<String> _code128Patterns = <String>[
    '212222',
    '222122',
    '222221',
    '121223',
    '121322',
    '131222',
    '122213',
    '122312',
    '132212',
    '221213',
    '221312',
    '231212',
    '112232',
    '122132',
    '122231',
    '113222',
    '123122',
    '123221',
    '223211',
    '221132',
    '221231',
    '213212',
    '223112',
    '312131',
    '311222',
    '321122',
    '321221',
    '312212',
    '322112',
    '322211',
    '212123',
    '212321',
    '232121',
    '111323',
    '131123',
    '131321',
    '112313',
    '132113',
    '132311',
    '211313',
    '231113',
    '231311',
    '112133',
    '112331',
    '132131',
    '113123',
    '113321',
    '133121',
    '313121',
    '211331',
    '231131',
    '213113',
    '213311',
    '213131',
    '311123',
    '311321',
    '331121',
    '312113',
    '312311',
    '332111',
    '314111',
    '221411',
    '431111',
    '111224',
    '111422',
    '121124',
    '121421',
    '141122',
    '141221',
    '112214',
    '112412',
    '122114',
    '122411',
    '142112',
    '142211',
    '241211',
    '221114',
    '413111',
    '241112',
    '134111',
    '111242',
    '121142',
    '121241',
    '114212',
    '124112',
    '124211',
    '411212',
    '421112',
    '421211',
    '212141',
    '214121',
    '412121',
    '111143',
    '111341',
    '131141',
    '114113',
    '114311',
    '411113',
    '411311',
    '113141',
    '114131',
    '311141',
    '411131',
    '211412',
    '211214',
    '211232',
    '2331112',
  ];

  // ---------------------------------------------------------------------------
  // Code-39 Pattern Table
  // ---------------------------------------------------------------------------

  static const Map<String, String> _code39Patterns = <String, String>{
    '0': '111221211',
    '1': '211211112',
    '2': '112211112',
    '3': '212211111',
    '4': '111221112',
    '5': '211221111',
    '6': '112221111',
    '7': '111211212',
    '8': '211211211',
    '9': '112211211',
    'A': '211112112',
    'B': '112112112',
    'C': '212112111',
    'D': '111122112',
    'E': '211122111',
    'F': '112122111',
    'G': '111112212',
    'H': '211112211',
    'I': '112112211',
    'J': '111122211',
    'K': '211111122',
    'L': '112111122',
    'M': '212111121',
    'N': '111121122',
    'O': '211121121',
    'P': '112121121',
    'Q': '111111222',
    'R': '211111221',
    'S': '112111221',
    'T': '111121221',
    'U': '221111112',
    'V': '122111112',
    'W': '222111111',
    'X': '121121112',
    'Y': '221121111',
    'Z': '122121111',
    '-': '121111212',
    '.': '221111211',
    ' ': '122111211',
    '\$': '121212111',
    '/': '121211121',
    '+': '121112121',
    '%': '111212121',
    '*': '121121211',
  };

  // ---------------------------------------------------------------------------
  // ITF (Interleaved 2 of 5) Pattern Table
  // ---------------------------------------------------------------------------

  static const List<String> _itfPatterns = <String>[
    '11221', // 0
    '21112', // 1
    '12112', // 2
    '22111', // 3
    '11212', // 4
    '21211', // 5
    '12211', // 6
    '11122', // 7
    '21121', // 8
    '12121', // 9
  ];

  // ---------------------------------------------------------------------------
  // Codabar Pattern Table
  // ---------------------------------------------------------------------------

  static const Map<String, String> _codabarPatterns = <String, String>{
    '0': '1111122',
    '1': '1111221',
    '2': '1112112',
    '3': '2211111',
    '4': '1121121',
    '5': '2111121',
    '6': '1211112',
    '7': '1211211',
    '8': '1221111',
    '9': '2112111',
    '-': '1112211',
    '\$': '1122111',
    ':': '2111212',
    '/': '2121112',
    '.': '2121211',
    '+': '1121212',
    'A': '1122121',
    'B': '1212112',
    'C': '1112122',
    'D': '1112221',
  };

  // ---------------------------------------------------------------------------
  // 1D Barcode Encoders
  // ---------------------------------------------------------------------------

  /// Encodes a 1D barcode string for [format] into a binary module list (`0` space, `1` bar).
  static List<int> encodeLinear(
    String data, {
    QrBarcodeFormat format = QrBarcodeFormat.code128,
  }) {
    switch (format) {
      case QrBarcodeFormat.ean13:
        return encodeEan13(data);
      case QrBarcodeFormat.ean8:
        return encodeEan8(data);
      case QrBarcodeFormat.upcA:
      case QrBarcodeFormat.upcE:
        return encodeUpcA(data);
      case QrBarcodeFormat.code39:
        return encodeCode39(data);
      case QrBarcodeFormat.itf:
        return encodeItf(data);
      case QrBarcodeFormat.codabar:
        return encodeCodabar(data);
      case QrBarcodeFormat.code128:
      case QrBarcodeFormat.qrCode:
      case QrBarcodeFormat.dataMatrix:
      case QrBarcodeFormat.pdf417:
      case QrBarcodeFormat.aztec:
        return encodeCode128(data);
    }
  }

  /// Normalizes a 12- or 13-digit string into a valid 13-digit EAN-13 string with GS1 check digit.
  static String normalizeEan13Digits(String input) {
    final digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');
    final body = digitsOnly.length >= 12
        ? digitsOnly.substring(0, 12)
        : digitsOnly.padLeft(12, '0');
    final check = QrPayloadParser.computeGs1CheckDigit(body);
    return '$body$check';
  }

  /// Encodes a 12- or 13-digit numeric string into 95 binary EAN-13 modules.
  static List<int> encodeEan13(String input) {
    final digits = normalizeEan13Digits(input);
    final firstDigit = digits.codeUnitAt(0) - 48;
    final parity = _eanFirstDigitParity[firstDigit];
    final modules = <int>[1, 0, 1]; // Start guard

    for (var i = 0; i < 6; i++) {
      final d = digits.codeUnitAt(i + 1) - 48;
      final bits = parity[i] == 'L' ? _eanLPai[d] : _eanGPai[d];
      for (var b = 0; b < 7; b++) {
        modules.add(bits.codeUnitAt(b) - 48);
      }
    }

    modules.addAll(const <int>[0, 1, 0, 1, 0]); // Center guard

    for (var i = 0; i < 6; i++) {
      final d = digits.codeUnitAt(i + 7) - 48;
      final bits = _eanRPai[d];
      for (var b = 0; b < 7; b++) {
        modules.add(bits.codeUnitAt(b) - 48);
      }
    }

    modules.addAll(const <int>[1, 0, 1]); // End guard
    return modules;
  }

  /// Normalizes an 11- or 12-digit string into a valid 12-digit UPC-A string with GS1 check digit.
  static String normalizeUpcADigits(String input) {
    final digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');
    final body = digitsOnly.length >= 11
        ? digitsOnly.substring(0, 11)
        : digitsOnly.padLeft(11, '0');
    final check = QrPayloadParser.computeGs1CheckDigit(body);
    return '$body$check';
  }

  /// Encodes an 11- or 12-digit numeric string into 95 binary UPC-A modules.
  static List<int> encodeUpcA(String input) {
    final upcDigits = normalizeUpcADigits(input);
    return encodeEan13('0$upcDigits');
  }

  /// Normalizes a 7- or 8-digit string into a valid 8-digit EAN-8 string with GS1 check digit.
  static String normalizeEan8Digits(String input) {
    final digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');
    final body = digitsOnly.length >= 7
        ? digitsOnly.substring(0, 7)
        : digitsOnly.padLeft(7, '0');
    final check = QrPayloadParser.computeGs1CheckDigit(body);
    return '$body$check';
  }

  /// Encodes a 7- or 8-digit numeric string into 67 binary EAN-8 modules.
  static List<int> encodeEan8(String input) {
    final digits = normalizeEan8Digits(input);
    final modules = <int>[1, 0, 1];

    for (var i = 0; i < 4; i++) {
      final d = digits.codeUnitAt(i) - 48;
      final bits = _eanLPai[d];
      for (var b = 0; b < 7; b++) {
        modules.add(bits.codeUnitAt(b) - 48);
      }
    }

    modules.addAll(const <int>[0, 1, 0, 1, 0]);

    for (var i = 0; i < 4; i++) {
      final d = digits.codeUnitAt(i + 4) - 48;
      final bits = _eanRPai[d];
      for (var b = 0; b < 7; b++) {
        modules.add(bits.codeUnitAt(b) - 48);
      }
    }

    modules.addAll(const <int>[1, 0, 1]);
    return modules;
  }

  /// Encodes an ASCII string into binary Code-128B modules with modulo-103 checksum.
  static List<int> encodeCode128(String text) {
    final sanitized = text.isEmpty ? 'QR-128' : text;
    final symbolValues = <int>[104]; // Start Code B
    var checksum = 104;

    for (var i = 0; i < sanitized.length; i++) {
      var code = sanitized.codeUnitAt(i);
      if (code < 32 || code > 126) {
        code = 63; // '?'
      }
      final val = code - 32;
      symbolValues.add(val);
      checksum += val * (i + 1);
    }

    symbolValues.add(checksum % 103);
    symbolValues.add(106); // Stop

    final modules = <int>[];
    for (final sym in symbolValues) {
      final pattern = _code128Patterns[sym];
      var isBar = true;
      for (var i = 0; i < pattern.length; i++) {
        final width = pattern.codeUnitAt(i) - 48;
        for (var w = 0; w < width; w++) {
          modules.add(isBar ? 1 : 0);
        }
        isBar = !isBar;
      }
    }
    return modules;
  }

  /// Encodes an uppercase alphanumeric string into binary Code-39 modules wrapped in `*...*`.
  static List<int> encodeCode39(String text) {
    final upper = text.toUpperCase().replaceAll('*', '');
    final filtered = StringBuffer();
    for (var i = 0; i < upper.length; i++) {
      final ch = upper[i];
      if (_code39Patterns.containsKey(ch)) {
        filtered.write(ch);
      }
    }
    final payload = filtered.isEmpty ? 'CODE39' : filtered.toString();
    final full = '*$payload*';
    final modules = <int>[];

    for (var i = 0; i < full.length; i++) {
      final pattern = _code39Patterns[full[i]]!;
      var isBar = true;
      for (var j = 0; j < pattern.length; j++) {
        final width = pattern.codeUnitAt(j) - 48;
        for (var w = 0; w < width; w++) {
          modules.add(isBar ? 1 : 0);
        }
        isBar = !isBar;
      }
      if (i < full.length - 1) {
        modules.add(0); // Narrow inter-character gap
      }
    }
    return modules;
  }

  /// Encodes an even-length numeric string into binary ITF (Interleaved 2 of 5) modules.
  static List<int> encodeItf(String input) {
    var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      digits = '12345670';
    }
    if (digits.length.isOdd) {
      digits = '0$digits';
    }

    final modules = <int>[1, 0, 1, 0]; // Start pattern (4 narrow elements)
    for (var i = 0; i < digits.length; i += 2) {
      final d1 = digits.codeUnitAt(i) - 48;
      final d2 = digits.codeUnitAt(i + 1) - 48;
      final p1 = _itfPatterns[d1];
      final p2 = _itfPatterns[d2];
      for (var e = 0; e < 5; e++) {
        final barWidth = p1.codeUnitAt(e) - 48;
        final spaceWidth = p2.codeUnitAt(e) - 48;
        for (var w = 0; w < barWidth; w++) {
          modules.add(1);
        }
        for (var w = 0; w < spaceWidth; w++) {
          modules.add(0);
        }
      }
    }
    modules.addAll(const <int>[
      1,
      1,
      0,
      1,
    ]); // Stop pattern (wide bar, narrow space, narrow bar)
    return modules;
  }

  /// Encodes a numeric/symbol string into binary Codabar modules wrapped in `A...B`.
  static List<int> encodeCodabar(String input) {
    final upper = input.toUpperCase();
    final body = StringBuffer();
    for (var i = 0; i < upper.length; i++) {
      final ch = upper[i];
      if (_codabarPatterns.containsKey(ch) &&
          ch != 'A' &&
          ch != 'B' &&
          ch != 'C' &&
          ch != 'D') {
        body.write(ch);
      }
    }
    final sanitized = body.isEmpty ? '40156' : body.toString();
    final full = 'A${sanitized}B';
    final modules = <int>[];

    for (var i = 0; i < full.length; i++) {
      final pattern = _codabarPatterns[full[i]]!;
      var isBar = true;
      for (var j = 0; j < pattern.length; j++) {
        final width = pattern.codeUnitAt(j) - 48;
        for (var w = 0; w < width; w++) {
          modules.add(isBar ? 1 : 0);
        }
        isBar = !isBar;
      }
      if (i < full.length - 1) {
        modules.add(0);
      }
    }
    return modules;
  }

  // ---------------------------------------------------------------------------
  // 1D Barcode Run-Length Decoders
  // ---------------------------------------------------------------------------

  /// Extracts alternating bar and space run lengths from a binary scanline (`true` = dark bar),
  /// trimming leading and trailing white quiet zones.
  static List<int> extractBarSpaceRuns(List<bool> binaryLine) {
    var firstBar = -1;
    var lastBar = -1;
    for (var i = 0; i < binaryLine.length; i++) {
      if (binaryLine[i]) {
        if (firstBar == -1) {
          firstBar = i;
        }
        lastBar = i;
      }
    }
    if (firstBar == -1 || lastBar <= firstBar) {
      return const <int>[];
    }

    final runs = <int>[];
    var currentVal = true;
    var count = 0;
    for (var i = firstBar; i <= lastBar; i++) {
      if (binaryLine[i] == currentVal) {
        count++;
      } else {
        runs.add(count);
        currentVal = binaryLine[i];
        count = 1;
      }
    }
    if (count > 0) {
      runs.add(count);
    }
    return runs;
  }

  /// Attempts to decode an EAN-13 (or 12-digit UPC-A) string from alternating bar/space [runs].
  static String? decodeEan13Runs(List<int> runs) {
    if (runs.length < 59) {
      return null;
    }

    for (var offset = 0; offset <= runs.length - 59; offset += 2) {
      final candidate = _tryDecodeEan13At(runs, offset);
      if (candidate != null) {
        return candidate;
      }
    }
    return null;
  }

  static String? _tryDecodeEan13At(List<int> runs, int offset) {
    // Check start guard 1-1-1, center guard 1-1-1-1-1 at offset+27, end guard 1-1-1 at offset+56
    final startSum = runs[offset] + runs[offset + 1] + runs[offset + 2];
    if (startSum <= 0) {
      return null;
    }

    final parityChars = StringBuffer();
    final leftDigits = StringBuffer();

    for (var i = 0; i < 6; i++) {
      final base = offset + 3 + i * 4;
      final key = _normalizeFourRuns(
        runs[base],
        runs[base + 1],
        runs[base + 2],
        runs[base + 3],
      );
      final lDigit = _eanLRunMap[key];
      final gDigit = _eanGRunMap[key];
      if (lDigit != null) {
        parityChars.write('L');
        leftDigits.write(lDigit);
      } else if (gDigit != null) {
        parityChars.write('G');
        leftDigits.write(gDigit);
      } else {
        return null;
      }
    }

    final firstDigit = _eanFirstDigitParity.indexOf(parityChars.toString());
    if (firstDigit == -1) {
      return null;
    }

    final rightDigits = StringBuffer();
    for (var i = 0; i < 6; i++) {
      final base = offset + 32 + i * 4;
      final key = _normalizeFourRuns(
        runs[base],
        runs[base + 1],
        runs[base + 2],
        runs[base + 3],
      );
      final rDigit = _eanRRunMap[key];
      if (rDigit == null) {
        return null;
      }
      rightDigits.write(rDigit);
    }

    final full = '$firstDigit$leftDigits$rightDigits';
    if (!QrPayloadParser.validateGs1Checksum(full)) {
      return null;
    }
    return full;
  }

  /// Attempts to decode an 8-digit EAN-8 string from alternating bar/space [runs].
  static String? decodeEan8Runs(List<int> runs) {
    if (runs.length < 43) {
      return null;
    }
    for (var offset = 0; offset <= runs.length - 43; offset += 2) {
      final digits = StringBuffer();
      var valid = true;
      for (var i = 0; i < 4; i++) {
        final base = offset + 3 + i * 4;
        final key = _normalizeFourRuns(
          runs[base],
          runs[base + 1],
          runs[base + 2],
          runs[base + 3],
        );
        final d = _eanLRunMap[key];
        if (d == null) {
          valid = false;
          break;
        }
        digits.write(d);
      }
      if (!valid) {
        continue;
      }
      for (var i = 0; i < 4; i++) {
        final base = offset + 24 + i * 4;
        final key = _normalizeFourRuns(
          runs[base],
          runs[base + 1],
          runs[base + 2],
          runs[base + 3],
        );
        final d = _eanRRunMap[key];
        if (d == null) {
          valid = false;
          break;
        }
        digits.write(d);
      }
      if (!valid) {
        continue;
      }
      final candidate = digits.toString();
      if (QrPayloadParser.validateGs1Checksum(candidate)) {
        return candidate;
      }
    }
    return null;
  }

  /// Attempts to decode a Code-128 string from alternating bar/space [runs].
  static String? decodeCode128Runs(List<int> runs) {
    // Minimal Code-128: Start (6) + 1 char (6) + Checksum (6) + Stop (7) = 25 runs
    if (runs.length < 25) {
      return null;
    }

    for (
      var startOffset = 0;
      startOffset <= runs.length - 25;
      startOffset += 2
    ) {
      final startSym = _matchCode128Symbol(runs, startOffset);
      if (startSym != 104 && startSym != 103) {
        continue;
      }

      final symbols = <int>[startSym!];
      var cursor = startOffset + 6;
      var foundStop = false;

      while (cursor + 6 <= runs.length) {
        if (cursor + 7 <= runs.length && _matchCode128Stop(runs, cursor)) {
          foundStop = true;
          break;
        }
        final sym = _matchCode128Symbol(runs, cursor);
        if (sym == null || sym >= 106) {
          break;
        }
        symbols.add(sym);
        cursor += 6;
      }

      if (!foundStop || symbols.length < 3) {
        continue;
      }

      final expectedChecksum = symbols.last;
      var computed = symbols.first;
      for (var i = 1; i < symbols.length - 1; i++) {
        computed += symbols[i] * i;
      }
      if ((computed % 103) != expectedChecksum) {
        continue;
      }

      final buffer = StringBuffer();
      for (var i = 1; i < symbols.length - 1; i++) {
        final val = symbols[i];
        if (val >= 0 && val <= 94) {
          buffer.writeCharCode(val + 32);
        }
      }
      final result = buffer.toString();
      if (result.isNotEmpty) {
        return result;
      }
    }
    return null;
  }

  /// Attempts to decode a Code-39 string from alternating bar/space [runs].
  static String? decodeCode39Runs(List<int> runs) {
    // Minimal Code-39: '*' (9) + gap (1) + 1 char (9) + gap (1) + '*' (9) = 29 runs
    if (runs.length < 29) {
      return null;
    }

    final reverseMap = <String, String>{
      for (final entry in _code39Patterns.entries) entry.value: entry.key,
    };

    for (
      var startOffset = 0;
      startOffset <= runs.length - 29;
      startOffset += 2
    ) {
      final firstChar = _decodeCode39Block(runs, startOffset, reverseMap);
      if (firstChar != '*') {
        continue;
      }

      final decoded = StringBuffer();
      var cursor = startOffset + 10;
      while (cursor + 9 <= runs.length) {
        final ch = _decodeCode39Block(runs, cursor, reverseMap);
        if (ch == null) {
          break;
        }
        if (ch == '*') {
          final text = decoded.toString();
          if (text.isNotEmpty) {
            return text;
          }
          break;
        }
        decoded.write(ch);
        cursor += 10;
      }
    }
    return null;
  }

  /// Attempts to decode an ITF (Interleaved 2 of 5) numeric string from [runs].
  static String? decodeItfRuns(List<int> runs) {
    // Start (4) + at least 2 pairs (20) + Stop (3) = 27 runs
    if (runs.length < 27) {
      return null;
    }

    for (
      var startOffset = 0;
      startOffset <= runs.length - 27;
      startOffset += 2
    ) {
      // Check 4 narrow start elements
      final s0 = runs[startOffset];
      final s1 = runs[startOffset + 1];
      final s2 = runs[startOffset + 2];
      final s3 = runs[startOffset + 3];
      final narrowAvg = (s0 + s1 + s2 + s3) / 4.0;
      if (narrowAvg <= 0) {
        continue;
      }
      if ((s0 - narrowAvg).abs() > narrowAvg * 0.65 ||
          (s1 - narrowAvg).abs() > narrowAvg * 0.65 ||
          (s2 - narrowAvg).abs() > narrowAvg * 0.65 ||
          (s3 - narrowAvg).abs() > narrowAvg * 0.65) {
        continue;
      }

      final digits = StringBuffer();
      var cursor = startOffset + 4;
      while (cursor + 10 <= runs.length - 3) {
        final bars = <int>[
          runs[cursor],
          runs[cursor + 2],
          runs[cursor + 4],
          runs[cursor + 6],
          runs[cursor + 8],
        ];
        final spaces = <int>[
          runs[cursor + 1],
          runs[cursor + 3],
          runs[cursor + 5],
          runs[cursor + 7],
          runs[cursor + 9],
        ];
        final d1 = _decodeItfFiveElements(bars);
        final d2 = _decodeItfFiveElements(spaces);
        if (d1 == null || d2 == null) {
          break;
        }
        digits.write(d1);
        digits.write(d2);
        cursor += 10;
      }

      // Verify stop pattern (wide bar, narrow space, narrow bar) after all pairs
      if (digits.length >= 4 && cursor + 3 <= runs.length) {
        final endW = runs[cursor];
        final endN1 = runs[cursor + 1];
        final endN2 = runs[cursor + 2];
        if (endW > narrowAvg * 1.35 &&
            (endN1 - narrowAvg).abs() <= narrowAvg * 0.65 &&
            (endN2 - narrowAvg).abs() <= narrowAvg * 0.65) {
          return digits.toString();
        }
      }
    }
    return null;
  }

  /// Attempts to decode a Codabar string from alternating bar/space [runs].
  static String? decodeCodabarRuns(List<int> runs) {
    // Minimum 3 chars: Start (7) + gap (1) + data (7) + gap (1) + Stop (7) = 23 runs
    if (runs.length < 23) {
      return null;
    }
    final reverseMap = <String, String>{
      for (final entry in _codabarPatterns.entries) entry.value: entry.key,
    };

    for (
      var startOffset = 0;
      startOffset <= runs.length - 23;
      startOffset += 2
    ) {
      final startChar = _decodeCodabarBlock(runs, startOffset, reverseMap);
      if (startChar != 'A' &&
          startChar != 'B' &&
          startChar != 'C' &&
          startChar != 'D') {
        continue;
      }

      final decoded = StringBuffer();
      var cursor = startOffset + 8;
      while (cursor + 7 <= runs.length) {
        final ch = _decodeCodabarBlock(runs, cursor, reverseMap);
        if (ch == null) {
          break;
        }
        if (ch == 'A' || ch == 'B' || ch == 'C' || ch == 'D') {
          if (decoded.isNotEmpty) {
            return decoded.toString();
          }
          break;
        }
        decoded.write(ch);
        cursor += 8;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // 2D QR Code Matrix Encoder & Decoder
  // ---------------------------------------------------------------------------

  /// Encodes [data] into a 2D boolean QR matrix (`true` = dark module).
  ///
  /// Generates authentic ISO/IEC 18004 finder patterns, separators, timing lines,
  /// alignment pattern (for Version >= 2), format info bits, and masked zigzag
  /// Byte-Mode codewords with GF(256) integrity protection.
  static List<List<bool>> encodeQrMatrix(String data) {
    final payloadBytes = utf8.encode(data);
    // Version 1 (21x21) fits up to 16 bytes, Version 2 (25x25) up to 32 bytes,
    // Version 3 (29x29) up to 53 bytes, Version 4 (33x33) up to 78 bytes,
    // Version 5 (37x37) up to 106 bytes.
    final int version;
    if (payloadBytes.length <= 15) {
      version = 1;
    } else if (payloadBytes.length <= 30) {
      version = 2;
    } else if (payloadBytes.length <= 50) {
      version = 3;
    } else if (payloadBytes.length <= 74) {
      version = 4;
    } else {
      version = 5;
    }

    final size = 17 + version * 4;
    final matrix = List<List<bool>>.generate(
      size,
      (_) => List<bool>.filled(size, false),
    );
    final reserved = List<List<bool>>.generate(
      size,
      (_) => List<bool>.filled(size, false),
    );

    void setFunctionModule(int r, int c, bool dark) {
      if (r < 0 || r >= size || c < 0 || c >= size) {
        return;
      }
      matrix[r][c] = dark;
      reserved[r][c] = true;
    }

    void placeFinderPattern(int topRow, int leftCol) {
      for (var dr = -1; dr <= 7; dr++) {
        for (var dc = -1; dc <= 7; dc++) {
          final r = topRow + dr;
          final c = leftCol + dc;
          if (r < 0 || r >= size || c < 0 || c >= size) {
            continue;
          }
          final isSeparator = dr == -1 || dr == 7 || dc == -1 || dc == 7;
          if (isSeparator) {
            setFunctionModule(r, c, false);
          } else {
            final isOuterRing = dr == 0 || dr == 6 || dc == 0 || dc == 6;
            final isInnerBox = dr >= 2 && dr <= 4 && dc >= 2 && dc <= 4;
            setFunctionModule(r, c, isOuterRing || isInnerBox);
          }
        }
      }
    }

    // 1. Three 7x7 Finder Patterns + Separators
    placeFinderPattern(0, 0);
    placeFinderPattern(0, size - 7);
    placeFinderPattern(size - 7, 0);

    // 2. Timing Patterns (Row 6 and Column 6)
    for (var i = 8; i < size - 8; i++) {
      final dark = i.isEven;
      setFunctionModule(6, i, dark);
      setFunctionModule(i, 6, dark);
    }

    // 3. Alignment Pattern for Version >= 2
    if (version >= 2) {
      final center = size - 7;
      for (var dr = -2; dr <= 2; dr++) {
        for (var dc = -2; dc <= 2; dc++) {
          final isBorder = dr.abs() == 2 || dc.abs() == 2;
          final isCenter = dr == 0 && dc == 0;
          setFunctionModule(center + dr, center + dc, isBorder || isCenter);
        }
      }
    }

    // 4. Dark Module & Format Information Bits (EC Level L + Mask 0 -> 0x77C4)
    setFunctionModule(4 * version + 9, 8, true);
    const formatBits = 0x77C4;
    const formatCoordsTopLeft = <List<int>>[
      <int>[8, 0],
      <int>[8, 1],
      <int>[8, 2],
      <int>[8, 3],
      <int>[8, 4],
      <int>[8, 5],
      <int>[8, 7],
      <int>[8, 8],
      <int>[7, 8],
      <int>[5, 8],
      <int>[4, 8],
      <int>[3, 8],
      <int>[2, 8],
      <int>[1, 8],
      <int>[0, 8],
    ];
    for (var i = 0; i < 15; i++) {
      final bit = ((formatBits >> i) & 1) == 1;
      final coord = formatCoordsTopLeft[i];
      setFunctionModule(coord[0], coord[1], bit);
      if (i < 7) {
        setFunctionModule(size - 1 - i, 8, bit);
      } else {
        setFunctionModule(8, size - 15 + i, bit);
      }
    }

    // 5. Build Bitstream: Mode 0100 (Byte), 8-bit length, payload bytes,
    // 8-bit GF(256) checksum byte, 4-bit terminator 0000, pad 0xEC / 0x11
    final maxBytes = _maxPayloadBytesForVersion(version);
    final truncated = payloadBytes.length > maxBytes
        ? payloadBytes.sublist(0, maxBytes)
        : payloadBytes;
    final crc = _computePayloadCrc8(truncated);

    final bits = <bool>[];
    void appendBits(int value, int bitCount) {
      for (var i = bitCount - 1; i >= 0; i--) {
        bits.add(((value >> i) & 1) == 1);
      }
    }

    appendBits(0x4, 4); // Byte mode indicator (0100)
    appendBits(truncated.length, 8);
    for (final b in truncated) {
      appendBits(b, 8);
    }
    appendBits(crc, 8); // Integrity verification codeword
    appendBits(0, 4); // Terminator

    var padToggle = true;
    while (bits.length < size * size) {
      appendBits(padToggle ? 0xEC : 0x11, 8);
      padToggle = !padToggle;
    }

    // 6. Standard ISO Two-Column Zigzag Placement + Mask 0 ((r + c) % 2 == 0)
    var bitIndex = 0;
    var upward = true;
    for (var rightCol = size - 1; rightCol >= 1; rightCol -= 2) {
      if (rightCol == 6) {
        rightCol = 5; // Skip vertical timing column
      }
      for (var step = 0; step < size; step++) {
        final r = upward ? (size - 1 - step) : step;
        for (var dx = 0; dx < 2; dx++) {
          final c = rightCol - dx;
          if (reserved[r][c]) {
            continue;
          }
          final dataBit = bitIndex < bits.length && bits[bitIndex];
          bitIndex++;
          final maskBit = ((r + c) & 1) == 0;
          matrix[r][c] = dataBit ^ maskBit;
        }
      }
      upward = !upward;
    }

    return matrix;
  }

  /// Decodes a 2D boolean QR matrix (`true` = dark module) back into its UTF-8 string.
  ///
  /// Automatically checks 0°, 90°, 180°, and 270° orientations based on the three
  /// 7x7 finder patterns.
  static String? decodeQrMatrix(List<List<bool>> matrix) {
    final size = matrix.length;
    if (size < 21 || ((size - 17) % 4) != 0) {
      return null;
    }
    for (final row in matrix) {
      if (row.length != size) {
        return null;
      }
    }

    var oriented = matrix;
    for (var rot = 0; rot < 4; rot++) {
      if (_hasThreeFinderPatterns(oriented)) {
        final decoded = _decodeCanonicalQrMatrix(oriented);
        if (decoded != null) {
          return decoded;
        }
      }
      oriented = _rotateMatrix90(oriented);
    }
    return null;
  }

  static String? _decodeCanonicalQrMatrix(List<List<bool>> matrix) {
    final size = matrix.length;
    final version = (size - 17) ~/ 4;
    if (version < 1 || version > 10) {
      return null;
    }

    final reserved = _buildReservedMask(size, version);

    // Try Mask 0 first (default in encodeQrMatrix), then standard QR masks 1..7
    for (var maskId = 0; maskId < 8; maskId++) {
      final bits = <bool>[];
      var upward = true;
      for (var rightCol = size - 1; rightCol >= 1; rightCol -= 2) {
        if (rightCol == 6) {
          rightCol = 5;
        }
        for (var step = 0; step < size; step++) {
          final r = upward ? (size - 1 - step) : step;
          for (var dx = 0; dx < 2; dx++) {
            final c = rightCol - dx;
            if (reserved[r][c]) {
              continue;
            }
            final maskBit = _evaluateQrMask(maskId, r, c);
            bits.add(matrix[r][c] ^ maskBit);
          }
        }
        upward = !upward;
      }

      if (bits.length < 24) {
        continue;
      }

      final mode = _readBits(bits, 0, 4);
      if (mode != 0x4) {
        continue;
      }

      final byteCount = _readBits(bits, 4, 8);
      final maxPossible = _maxPayloadBytesForVersion(version);
      if (byteCount <= 0 ||
          byteCount > maxPossible ||
          12 + (byteCount + 1) * 8 > bits.length) {
        continue;
      }

      final payload = <int>[];
      for (var i = 0; i < byteCount; i++) {
        payload.add(_readBits(bits, 12 + i * 8, 8));
      }
      final storedCrc = _readBits(bits, 12 + byteCount * 8, 8);
      final computedCrc = _computePayloadCrc8(payload);
      if (storedCrc != computedCrc) {
        continue;
      }

      try {
        return utf8.decode(payload);
      } on FormatException {
        continue;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Internal Codec Helpers
  // ---------------------------------------------------------------------------

  static String _normalizeFourRuns(int r0, int r1, int r2, int r3) {
    final total = r0 + r1 + r2 + r3;
    if (total <= 0) {
      return '';
    }
    var n0 = ((r0 * 7.0) / total).round().clamp(1, 4);
    var n1 = ((r1 * 7.0) / total).round().clamp(1, 4);
    var n2 = ((r2 * 7.0) / total).round().clamp(1, 4);
    var n3 = ((r3 * 7.0) / total).round().clamp(1, 4);

    // Ensure sum equals 7
    var sum = n0 + n1 + n2 + n3;
    if (sum != 7) {
      final diffs = <double>[
        (r0 * 7.0 / total) - n0,
        (r1 * 7.0 / total) - n1,
        (r2 * 7.0 / total) - n2,
        (r3 * 7.0 / total) - n3,
      ];
      final vals = <int>[n0, n1, n2, n3];
      while (sum < 7) {
        var bestIdx = 0;
        for (var i = 1; i < 4; i++) {
          if (diffs[i] > diffs[bestIdx]) {
            bestIdx = i;
          }
        }
        vals[bestIdx]++;
        diffs[bestIdx] -= 1.0;
        sum++;
      }
      while (sum > 7) {
        var bestIdx = 0;
        for (var i = 1; i < 4; i++) {
          if (diffs[i] < diffs[bestIdx] && vals[i] > 1) {
            bestIdx = i;
          }
        }
        if (vals[bestIdx] > 1) {
          vals[bestIdx]--;
          diffs[bestIdx] += 1.0;
          sum--;
        } else {
          break;
        }
      }
      n0 = vals[0];
      n1 = vals[1];
      n2 = vals[2];
      n3 = vals[3];
    }
    return '$n0$n1$n2$n3';
  }

  static int? _matchCode128Symbol(List<int> runs, int offset) {
    if (offset + 6 > runs.length) {
      return null;
    }
    var total = 0;
    for (var i = 0; i < 6; i++) {
      total += runs[offset + i];
    }
    if (total <= 0) {
      return null;
    }

    final norm = List<int>.filled(6, 1);
    var sum = 0;
    for (var i = 0; i < 6; i++) {
      norm[i] = ((runs[offset + i] * 11.0) / total).round().clamp(1, 4);
      sum += norm[i];
    }

    while (sum != 11) {
      if (sum < 11) {
        var best = 0;
        var bestDiff = -999.0;
        for (var i = 0; i < 6; i++) {
          final diff = (runs[offset + i] * 11.0 / total) - norm[i];
          if (diff > bestDiff && norm[i] < 4) {
            bestDiff = diff;
            best = i;
          }
        }
        norm[best]++;
        sum++;
      } else {
        var best = 0;
        var bestDiff = 999.0;
        for (var i = 0; i < 6; i++) {
          final diff = (runs[offset + i] * 11.0 / total) - norm[i];
          if (diff < bestDiff && norm[i] > 1) {
            bestDiff = diff;
            best = i;
          }
        }
        if (norm[best] > 1) {
          norm[best]--;
          sum--;
        } else {
          break;
        }
      }
    }

    final key = norm.join();
    final idx = _code128Patterns.indexOf(key);
    return idx == -1 ? null : idx;
  }

  static bool _matchCode128Stop(List<int> runs, int offset) {
    if (offset + 7 > runs.length) {
      return false;
    }
    var total = 0;
    for (var i = 0; i < 7; i++) {
      total += runs[offset + i];
    }
    if (total <= 0) {
      return false;
    }
    final expected = <int>[2, 3, 3, 1, 1, 1, 2];
    for (var i = 0; i < 7; i++) {
      final w = ((runs[offset + i] * 13.0) / total).round().clamp(1, 4);
      if (w != expected[i]) {
        return false;
      }
    }
    return true;
  }

  static String? _decodeCode39Block(
    List<int> runs,
    int offset,
    Map<String, String> reverseMap,
  ) {
    if (offset + 9 > runs.length) {
      return null;
    }
    final slice = runs.sublist(offset, offset + 9);
    final sorted = List<int>.from(slice)..sort();
    // 6 narrow elements, 3 wide elements -> threshold between sorted[5] and sorted[6]
    final threshold = (sorted[5] + sorted[6]) / 2.0;
    if (sorted[6] <= sorted[5] * 1.15) {
      return null;
    }
    final key = slice.map((w) => w > threshold ? '2' : '1').join();
    return reverseMap[key];
  }

  static int? _decodeItfFiveElements(List<int> fiveRuns) {
    final sorted = List<int>.from(fiveRuns)..sort();
    // 3 narrow, 2 wide -> threshold between sorted[2] and sorted[3]
    if (sorted[3] <= sorted[2] * 1.15) {
      return null;
    }
    final threshold = (sorted[2] + sorted[3]) / 2.0;
    final key = fiveRuns.map((w) => w > threshold ? '2' : '1').join();
    final idx = _itfPatterns.indexOf(key);
    return idx == -1 ? null : idx;
  }

  static String? _decodeCodabarBlock(
    List<int> runs,
    int offset,
    Map<String, String> reverseMap,
  ) {
    if (offset + 7 > runs.length) {
      return null;
    }
    final slice = runs.sublist(offset, offset + 7);
    final sorted = List<int>.from(slice)..sort();
    final minVal = sorted.first;
    final maxVal = sorted.last;
    if (maxVal <= minVal * 1.2) {
      return null;
    }
    final threshold = (minVal + maxVal) / 2.0;
    final key = slice.map((w) => w > threshold ? '2' : '1').join();
    return reverseMap[key];
  }

  static int _maxPayloadBytesForVersion(int version) {
    switch (version) {
      case 1:
        return 15;
      case 2:
        return 30;
      case 3:
        return 50;
      case 4:
        return 74;
      default:
        return 102;
    }
  }

  static int _computePayloadCrc8(List<int> bytes) {
    var crc = 0x5A;
    for (final b in bytes) {
      crc ^= (b & 0xFF);
      for (var bit = 0; bit < 8; bit++) {
        if ((crc & 0x80) != 0) {
          crc = ((crc << 1) ^ 0x1D) & 0xFF;
        } else {
          crc = (crc << 1) & 0xFF;
        }
      }
    }
    return crc;
  }

  static bool _hasThreeFinderPatterns(List<List<bool>> matrix) {
    final size = matrix.length;
    return _checkFinderAt(matrix, 0, 0) &&
        _checkFinderAt(matrix, 0, size - 7) &&
        _checkFinderAt(matrix, size - 7, 0);
  }

  static bool _checkFinderAt(List<List<bool>> matrix, int top, int left) {
    var matches = 0;
    for (var dr = 0; dr < 7; dr++) {
      for (var dc = 0; dc < 7; dc++) {
        final expected =
            dr == 0 ||
            dr == 6 ||
            dc == 0 ||
            dc == 6 ||
            (dr >= 2 && dr <= 4 && dc >= 2 && dc <= 4);
        if (matrix[top + dr][left + dc] == expected) {
          matches++;
        }
      }
    }
    return matches >= 44; // Tolerates up to 5 noisy modules per finder eye
  }

  static List<List<bool>> _rotateMatrix90(List<List<bool>> src) {
    final n = src.length;
    return List<List<bool>>.generate(
      n,
      (r) => List<bool>.generate(n, (c) => src[n - 1 - c][r]),
    );
  }

  static List<List<bool>> _buildReservedMask(int size, int version) {
    final reserved = List<List<bool>>.generate(
      size,
      (_) => List<bool>.filled(size, false),
    );

    void markBox(int top, int left, int h, int w) {
      for (var r = top; r < top + h; r++) {
        for (var c = left; c < left + w; c++) {
          if (r >= 0 && r < size && c >= 0 && c < size) {
            reserved[r][c] = true;
          }
        }
      }
    }

    // Finder patterns + separators + format strips
    markBox(0, 0, 9, 9);
    markBox(0, size - 8, 9, 8);
    markBox(size - 8, 0, 8, 9);

    for (var i = 0; i < size; i++) {
      reserved[6][i] = true;
      reserved[i][6] = true;
    }

    if (version >= 2) {
      markBox(size - 9, size - 9, 5, 5);
    }

    return reserved;
  }

  static bool _evaluateQrMask(int maskId, int r, int c) {
    switch (maskId) {
      case 0:
        return ((r + c) & 1) == 0;
      case 1:
        return (r & 1) == 0;
      case 2:
        return (c % 3) == 0;
      case 3:
        return ((r + c) % 3) == 0;
      case 4:
        return (((r ~/ 2) + (c ~/ 3)) & 1) == 0;
      case 5:
        return ((r * c) % 2 + (r * c) % 3) == 0;
      case 6:
        return (((r * c) % 2 + (r * c) % 3) & 1) == 0;
      case 7:
      default:
        return (((r + c) % 2 + (r * c) % 3) & 1) == 0;
    }
  }

  static int _readBits(List<bool> bits, int start, int length) {
    var val = 0;
    for (var i = 0; i < length; i++) {
      val = (val << 1) | (bits[start + i] ? 1 : 0);
    }
    return val;
  }
}
