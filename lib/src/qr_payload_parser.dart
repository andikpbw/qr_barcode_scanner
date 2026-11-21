import 'package:flutter/foundation.dart';

import 'qr_enums.dart';

/// Structured semantic data extracted from a raw QR code or barcode payload.
@immutable
class QrParsedPayload {
  /// Creates an immutable [QrParsedPayload].
  const QrParsedPayload({
    required this.type,
    required this.rawValue,
    required this.displayTitle,
    required this.displaySubtitle,
    required this.suggestedGlyph,
    this.fields = const <String, String>{},
  });

  /// Semantic category of the parsed payload.
  final QrPayloadType type;

  /// Unmodified raw string decoded from the barcode or QR code.
  final String rawValue;

  /// Concise primary headline suitable for UI result cards.
  final String displayTitle;

  /// Descriptive secondary subtitle summarizing key metadata.
  final String displaySubtitle;

  /// Recommended vector icon glyph for representing this payload.
  final QrGlyph suggestedGlyph;

  /// Structured key-value fields extracted from the payload.
  ///
  /// For example:
  /// - [QrPayloadType.wifi]: `ssid`, `password`, `encryption`, `hidden`
  /// - [QrPayloadType.url]: `scheme`, `host`, `path`, `isSecure`
  /// - [QrPayloadType.vCard]: `name`, `phone`, `email`, `org`, `url`
  /// - [QrPayloadType.product]: `gtin`, `country`, `validChecksum`
  /// - [QrPayloadType.geo]: `latitude`, `longitude`
  final Map<String, String> fields;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is QrParsedPayload &&
        other.type == type &&
        other.rawValue == rawValue &&
        other.displayTitle == displayTitle &&
        other.displaySubtitle == displaySubtitle &&
        other.suggestedGlyph == suggestedGlyph &&
        mapEquals(other.fields, fields);
  }

  @override
  int get hashCode => Object.hash(
    type,
    rawValue,
    displayTitle,
    displaySubtitle,
    suggestedGlyph,
    Object.hashAll(fields.entries.map((e) => Object.hash(e.key, e.value))),
  );

  @override
  String toString() =>
      'QrParsedPayload(type: $type, title: $displayTitle, subtitle: $displaySubtitle)';
}

/// Semantic parser for QR code and 1D barcode strings.
class QrPayloadParser {
  const QrPayloadParser._();

  /// Parses [rawValue] (and optional [format]) into a structured [QrParsedPayload].
  static QrParsedPayload parse(String rawValue, {QrBarcodeFormat? format}) {
    final trimmed = rawValue.trim();

    if (trimmed.toUpperCase().startsWith('WIFI:')) {
      return _parseWifi(trimmed);
    }

    if (trimmed.toUpperCase().startsWith('BEGIN:VCARD') ||
        trimmed.toUpperCase().startsWith('MECARD:')) {
      return _parseVCard(trimmed);
    }

    if (trimmed.toLowerCase().startsWith('mailto:') ||
        trimmed.toUpperCase().startsWith('MATMSG:')) {
      return _parseEmail(trimmed);
    }

    if (trimmed.toLowerCase().startsWith('tel:')) {
      final phone = trimmed.substring(4).trim();
      return QrParsedPayload(
        type: QrPayloadType.phone,
        rawValue: rawValue,
        displayTitle: phone.isEmpty ? 'Phone Number' : phone,
        displaySubtitle: 'Voice Call Action',
        suggestedGlyph: QrGlyph.checkCircle,
        fields: <String, String>{'phone': phone},
      );
    }

    if (trimmed.toLowerCase().startsWith('smsto:') ||
        trimmed.toLowerCase().startsWith('sms:')) {
      return _parseSms(trimmed);
    }

    if (trimmed.toLowerCase().startsWith('geo:')) {
      return _parseGeo(trimmed);
    }

    if (trimmed.toLowerCase().startsWith('upi://') ||
        trimmed.startsWith('000201')) {
      return _parsePayment(trimmed);
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null &&
        (uri.scheme == 'https' ||
            uri.scheme == 'http' ||
            (uri.hasScheme && uri.host.isNotEmpty))) {
      final isSecure = uri.scheme.toLowerCase() == 'https';
      return QrParsedPayload(
        type: QrPayloadType.url,
        rawValue: rawValue,
        displayTitle: uri.host.isNotEmpty ? uri.host : trimmed,
        displaySubtitle: isSecure
            ? 'Verified HTTPS Link • ${uri.path.isEmpty || uri.path == '/' ? 'Root' : uri.path}'
            : '${uri.scheme.toUpperCase()} Deep Link',
        suggestedGlyph: isSecure ? QrGlyph.shieldCheck : QrGlyph.link,
        fields: <String, String>{
          'scheme': uri.scheme,
          'host': uri.host,
          'path': uri.path,
          'isSecure': isSecure.toString(),
        },
      );
    }

    final isRetailFormat =
        format == QrBarcodeFormat.ean13 ||
        format == QrBarcodeFormat.ean8 ||
        format == QrBarcodeFormat.upcA ||
        format == QrBarcodeFormat.upcE;
    final digitsOnly = RegExp(r'^\d{8,14}$').hasMatch(trimmed);
    if (isRetailFormat ||
        (digitsOnly &&
            (trimmed.length == 8 ||
                trimmed.length == 12 ||
                trimmed.length == 13 ||
                trimmed.length == 14))) {
      final validChecksum = validateGs1Checksum(trimmed);
      final country = resolveGs1Country(trimmed);
      return QrParsedPayload(
        type: QrPayloadType.product,
        rawValue: rawValue,
        displayTitle: 'GTIN $trimmed',
        displaySubtitle:
            '$country • ${validChecksum ? 'GS1 Checksum Valid' : 'Unverified Checksum'}',
        suggestedGlyph: QrGlyph.barcode,
        fields: <String, String>{
          'gtin': trimmed,
          'country': country,
          'validChecksum': validChecksum.toString(),
        },
      );
    }

    return QrParsedPayload(
      type: QrPayloadType.text,
      rawValue: rawValue,
      displayTitle: trimmed.isEmpty ? 'Empty Code' : trimmed,
      displaySubtitle: format != null
          ? '${format.displayName} • ${trimmed.length} chars'
          : 'Plain Text Payload • ${trimmed.length} chars',
      suggestedGlyph: (format?.is1D ?? false)
          ? QrGlyph.barcode
          : QrGlyph.qrCode,
      fields: <String, String>{'length': trimmed.length.toString()},
    );
  }

  /// Validates the standard GS1 modulo-10 check digit for EAN-8, UPC-A, EAN-13, or ITF-14.
  static bool validateGs1Checksum(String digits) {
    if (!RegExp(r'^\d{8,14}$').hasMatch(digits)) {
      return false;
    }
    final expectedCheck = computeGs1CheckDigit(
      digits.substring(0, digits.length - 1),
    );
    final actualCheck = digits.codeUnitAt(digits.length - 1) - 48;
    return expectedCheck == actualCheck;
  }

  /// Computes the GS1 modulo-10 check digit for a numeric body without its check digit.
  static int computeGs1CheckDigit(String bodyDigits) {
    var sum = 0;
    for (var i = 0; i < bodyDigits.length; i++) {
      final digit = bodyDigits.codeUnitAt(bodyDigits.length - 1 - i) - 48;
      if (digit < 0 || digit > 9) {
        return -1;
      }
      sum += i.isEven ? digit * 3 : digit;
    }
    return (10 - (sum % 10)) % 10;
  }

  /// Resolves the GS1 prefix country or region for an EAN-13 or UPC-A code.
  static String resolveGs1Country(String digits) {
    if (digits.length == 12) {
      return 'USA & Canada (UPC)';
    }
    if (digits.length < 3) {
      return 'GS1 Global';
    }
    final prefix = int.tryParse(digits.substring(0, 3)) ?? -1;
    if (prefix >= 0 && prefix <= 139) {
      return 'USA & Canada';
    }
    if (prefix >= 300 && prefix <= 379) {
      return 'France';
    }
    if (prefix >= 400 && prefix <= 440) {
      return 'Germany';
    }
    if ((prefix >= 450 && prefix <= 459) || (prefix >= 490 && prefix <= 499)) {
      return 'Japan';
    }
    if (prefix >= 500 && prefix <= 509) {
      return 'United Kingdom';
    }
    if (prefix >= 690 && prefix <= 699) {
      return 'China';
    }
    if (prefix == 880) {
      return 'South Korea';
    }
    if (prefix == 888) {
      return 'Singapore';
    }
    if (prefix == 899) {
      return 'Indonesia';
    }
    if (prefix >= 930 && prefix <= 939) {
      return 'Australia';
    }
    if (prefix == 978 || prefix == 979) {
      return 'Bookland (ISBN)';
    }
    return 'GS1 International';
  }

  static QrParsedPayload _parseWifi(String raw) {
    final body = raw.substring(5);
    final ssid = _extractDelimitedField(body, 'S') ?? 'Wi-Fi Network';
    final encryption = _extractDelimitedField(body, 'T') ?? 'WPA2';
    final password = _extractDelimitedField(body, 'P') ?? '';
    final hidden = _extractDelimitedField(body, 'H') ?? 'false';

    return QrParsedPayload(
      type: QrPayloadType.wifi,
      rawValue: raw,
      displayTitle: ssid,
      displaySubtitle:
          'Wi-Fi ($encryption) • ${password.isEmpty ? 'Open Network' : 'Password Ready'}',
      suggestedGlyph: QrGlyph.wifi,
      fields: <String, String>{
        'ssid': ssid,
        'encryption': encryption,
        'password': password,
        'hidden': hidden,
      },
    );
  }

  static QrParsedPayload _parseVCard(String raw) {
    var name = '';
    var phone = '';
    var email = '';
    var org = '';
    var url = '';

    if (raw.toUpperCase().startsWith('MECARD:')) {
      final body = raw.substring(7);
      name = _extractDelimitedField(body, 'N') ?? '';
      phone = _extractDelimitedField(body, 'TEL') ?? '';
      email = _extractDelimitedField(body, 'EMAIL') ?? '';
      org = _extractDelimitedField(body, 'ORG') ?? '';
      url = _extractDelimitedField(body, 'URL') ?? '';
    } else {
      final lines = raw.split(RegExp(r'\r?\n'));
      for (final line in lines) {
        final upper = line.toUpperCase();
        final colonIndex = line.indexOf(':');
        if (colonIndex == -1) {
          continue;
        }
        final value = line.substring(colonIndex + 1).trim();
        if (upper.startsWith('FN:')) {
          name = value;
        } else if (name.isEmpty && upper.startsWith('N:')) {
          name = value.replaceAll(';', ' ').trim();
        } else if (upper.startsWith('TEL')) {
          phone = value;
        } else if (upper.startsWith('EMAIL')) {
          email = value;
        } else if (upper.startsWith('ORG')) {
          org = value;
        } else if (upper.startsWith('URL')) {
          url = value;
        }
      }
    }

    final title = name.isNotEmpty ? name : 'Contact Card';
    final subtitleParts = <String>[
      if (org.isNotEmpty) org,
      if (phone.isNotEmpty) phone,
      if (email.isNotEmpty) email,
    ];
    return QrParsedPayload(
      type: QrPayloadType.vCard,
      rawValue: raw,
      displayTitle: title,
      displaySubtitle: subtitleParts.isEmpty
          ? 'vCard Contact'
          : subtitleParts.join(' • '),
      suggestedGlyph: QrGlyph.checkCircle,
      fields: <String, String>{
        if (name.isNotEmpty) 'name': name,
        if (phone.isNotEmpty) 'phone': phone,
        if (email.isNotEmpty) 'email': email,
        if (org.isNotEmpty) 'org': org,
        if (url.isNotEmpty) 'url': url,
      },
    );
  }

  static QrParsedPayload _parseEmail(String raw) {
    if (raw.toUpperCase().startsWith('MATMSG:')) {
      final body = raw.substring(7);
      final to = _extractDelimitedField(body, 'TO') ?? '';
      final sub = _extractDelimitedField(body, 'SUB') ?? '';
      final msg = _extractDelimitedField(body, 'BODY') ?? '';
      return QrParsedPayload(
        type: QrPayloadType.email,
        rawValue: raw,
        displayTitle: to.isEmpty ? 'Email Draft' : to,
        displaySubtitle: sub.isEmpty ? 'Email Message' : 'Subject: $sub',
        suggestedGlyph: QrGlyph.link,
        fields: <String, String>{'email': to, 'subject': sub, 'body': msg},
      );
    }

    final uri = Uri.tryParse(raw);
    final email = uri?.path ?? raw.substring(7);
    final subject = uri?.queryParameters['subject'] ?? '';
    final body = uri?.queryParameters['body'] ?? '';
    return QrParsedPayload(
      type: QrPayloadType.email,
      rawValue: raw,
      displayTitle: email,
      displaySubtitle: subject.isEmpty ? 'Mailto Action' : 'Subject: $subject',
      suggestedGlyph: QrGlyph.link,
      fields: <String, String>{
        'email': email,
        'subject': subject,
        'body': body,
      },
    );
  }

  static QrParsedPayload _parseSms(String raw) {
    final stripped = raw.toLowerCase().startsWith('smsto:')
        ? raw.substring(6)
        : raw.substring(4);
    final colonIndex = stripped.indexOf(':');
    final phone = colonIndex == -1
        ? stripped.trim()
        : stripped.substring(0, colonIndex);
    final message = colonIndex == -1
        ? ''
        : stripped.substring(colonIndex + 1).trim();
    return QrParsedPayload(
      type: QrPayloadType.sms,
      rawValue: raw,
      displayTitle: phone.isEmpty ? 'SMS Message' : phone,
      displaySubtitle: message.isEmpty ? 'SMS Action' : message,
      suggestedGlyph: QrGlyph.sparkle,
      fields: <String, String>{'phone': phone, 'message': message},
    );
  }

  static QrParsedPayload _parseGeo(String raw) {
    final body = raw.substring(4).split('?').first;
    final parts = body.split(',');
    final lat = parts.isNotEmpty ? parts[0].trim() : '0.0';
    final lng = parts.length > 1 ? parts[1].trim() : '0.0';
    return QrParsedPayload(
      type: QrPayloadType.geo,
      rawValue: raw,
      displayTitle: '$lat, $lng',
      displaySubtitle: 'Geographic Coordinates',
      suggestedGlyph: QrGlyph.focus,
      fields: <String, String>{'latitude': lat, 'longitude': lng},
    );
  }

  static QrParsedPayload _parsePayment(String raw) {
    if (raw.toLowerCase().startsWith('upi://')) {
      final uri = Uri.tryParse(raw);
      final payee =
          uri?.queryParameters['pn'] ??
          uri?.queryParameters['pa'] ??
          'UPI Merchant';
      final amount = uri?.queryParameters['am'] ?? '';
      final currency = uri?.queryParameters['cu'] ?? 'INR';
      return QrParsedPayload(
        type: QrPayloadType.payment,
        rawValue: raw,
        displayTitle: payee,
        displaySubtitle: amount.isEmpty
            ? 'Instant UPI Payment'
            : 'UPI Payment • $currency $amount',
        suggestedGlyph: QrGlyph.shieldCheck,
        fields: <String, String>{
          'protocol': 'UPI',
          'merchant': payee,
          if (amount.isNotEmpty) 'amount': amount,
          'currency': currency,
        },
      );
    }

    return QrParsedPayload(
      type: QrPayloadType.payment,
      rawValue: raw,
      displayTitle: 'EMVCo / QRIS Payment',
      displaySubtitle: 'Verified Merchant Payment Payload',
      suggestedGlyph: QrGlyph.shieldCheck,
      fields: const <String, String>{'protocol': 'EMVCo'},
    );
  }

  static String? _extractDelimitedField(String input, String key) {
    final pattern = RegExp(
      '(?:^|;)${RegExp.escape(key)}:([^;]*)',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(input);
    return match?.group(1)?.trim();
  }
}
