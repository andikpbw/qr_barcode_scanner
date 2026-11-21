import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_barcode_scanner/qr_barcode_scanner.dart';

void main() {
  group(
    'QrBarcodeCodec & QrBarcodeDecoder — 2D QR Code Real Pixel Pipeline',
    () {
      test('encodes and decodes Version 1..3 QR codes from pixel frames', () {
        const payloads = <String>[
          'https://humanize.id',
          'WIFI:S:Humanize_5G;T:WPA2;P:Secret2026!;;',
          'BEGIN:VCARD\nFN:Andik Putra\nTEL:+62812345678\nEND:VCARD',
        ];

        for (final text in payloads) {
          final matrix = QrBarcodeCodec.encodeQrMatrix(text);
          final frame = QrScanFrame.fromBinaryMatrix(
            matrix,
            quietZoneModules: 4,
            moduleScale: 4,
          );

          final result = QrBarcodeDecoder.decodeSingle(frame);
          expect(result, isNotNull, reason: 'Failed to decode QR for: $text');
          expect(result!.format, QrBarcodeFormat.qrCode);
          expect(result.rawValue, text);
          expect(result.confidence, greaterThan(0.95));
          expect(result.corners.length, 4);
        }
      });

      test('decodes inverted (white-on-black) QR code pixel frames', () {
        const payload = 'https://humanize.id/dark-mode';
        final matrix = QrBarcodeCodec.encodeQrMatrix(payload);
        final invertedFrame = QrScanFrame.fromBinaryMatrix(
          matrix,
          inverted: true,
          moduleScale: 4,
        );

        final result = QrBarcodeDecoder.decodeSingle(invertedFrame);
        expect(result, isNotNull);
        expect(result!.rawValue, payload);
        expect(result.isInverted, isTrue);
      });

      test('decodes rotated 90°, 180°, and 270° QR matrices', () {
        const payload = 'ROTATED-QR-2026';
        var matrix = QrBarcodeCodec.encodeQrMatrix(payload);

        List<List<bool>> rotate90(List<List<bool>> src) {
          final n = src.length;
          return List<List<bool>>.generate(
            n,
            (r) => List<bool>.generate(n, (c) => src[n - 1 - c][r]),
          );
        }

        for (var rot = 0; rot < 3; rot++) {
          matrix = rotate90(matrix);
          final decoded = QrBarcodeCodec.decodeQrMatrix(matrix);
          expect(decoded, payload);
        }
      });

      test('decodes QR code from 32-bit RGBA and BGRA pixel buffers', () {
        const payload = 'RGBA-PIXEL-TEST';
        final matrix = QrBarcodeCodec.encodeQrMatrix(payload);
        final grayFrame = QrScanFrame.fromBinaryMatrix(matrix, moduleScale: 3);

        final rgba = Uint8List(grayFrame.width * grayFrame.height * 4);
        final bgra = Uint8List(grayFrame.width * grayFrame.height * 4);
        for (var i = 0; i < grayFrame.bytes.length; i++) {
          final v = grayFrame.bytes[i];
          rgba[i * 4] = v;
          rgba[i * 4 + 1] = v;
          rgba[i * 4 + 2] = v;
          rgba[i * 4 + 3] = 255;

          bgra[i * 4] = v;
          bgra[i * 4 + 1] = v;
          bgra[i * 4 + 2] = v;
          bgra[i * 4 + 3] = 255;
        }

        final rgbaResult = QrBarcodeDecoder.decodeSingle(
          QrScanFrame.fromRgba(
            bytes: rgba,
            width: grayFrame.width,
            height: grayFrame.height,
          ),
        );
        final bgraResult = QrBarcodeDecoder.decodeSingle(
          QrScanFrame.fromBgra(
            bytes: bgra,
            width: grayFrame.width,
            height: grayFrame.height,
          ),
        );

        expect(rgbaResult?.rawValue, payload);
        expect(bgraResult?.rawValue, payload);
      });
    },
  );

  group('QrBarcodeCodec & QrBarcodeDecoder — 1D Linear Barcodes', () {
    test('encodes and decodes EAN-13 from grayscale pixel frame', () {
      const ean13 = '8997012345675';
      final modules = QrBarcodeCodec.encodeEan13(ean13);
      expect(modules.length, 95);

      final frame = QrScanFrame.fromLinearModules(modules, moduleScale: 3);
      final result = QrBarcodeDecoder.decodeSingle(
        frame,
        allowedFormats: const <QrBarcodeFormat>{QrBarcodeFormat.ean13},
      );

      expect(result, isNotNull);
      expect(result!.format, QrBarcodeFormat.ean13);
      expect(result.rawValue, ean13);
      expect(result.payload.type, QrPayloadType.product);
      expect(result.payload.fields['country'], 'Indonesia');
      expect(result.payload.fields['validChecksum'], 'true');
    });

    test('encodes and decodes EAN-8 from grayscale pixel frame', () {
      const ean8 = '96385074';
      final modules = QrBarcodeCodec.encodeEan8(ean8);
      expect(modules.length, 67);

      final frame = QrScanFrame.fromLinearModules(modules, moduleScale: 3);
      final result = QrBarcodeDecoder.decodeSingle(
        frame,
        allowedFormats: const <QrBarcodeFormat>{QrBarcodeFormat.ean8},
      );

      expect(result, isNotNull);
      expect(result!.format, QrBarcodeFormat.ean8);
      expect(result.rawValue, ean8);
    });

    test('encodes and decodes UPC-A from grayscale pixel frame', () {
      const upcA = '036000291452';
      final modules = QrBarcodeCodec.encodeUpcA(upcA);
      expect(modules.length, 95);

      final frame = QrScanFrame.fromLinearModules(modules, moduleScale: 3);
      final result = QrBarcodeDecoder.decodeSingle(
        frame,
        allowedFormats: const <QrBarcodeFormat>{QrBarcodeFormat.upcA},
      );

      expect(result, isNotNull);
      expect(result!.format, QrBarcodeFormat.upcA);
      expect(result.rawValue, upcA);
    });

    test('encodes and decodes Code-128 from grayscale pixel frame', () {
      const code128 = 'HMZ-2026-99A';
      final modules = QrBarcodeCodec.encodeCode128(code128);
      final frame = QrScanFrame.fromLinearModules(modules, moduleScale: 3);

      final result = QrBarcodeDecoder.decodeSingle(
        frame,
        allowedFormats: const <QrBarcodeFormat>{QrBarcodeFormat.code128},
      );

      expect(result, isNotNull);
      expect(result!.format, QrBarcodeFormat.code128);
      expect(result.rawValue, code128);
    });

    test('encodes and decodes Code-39 from grayscale pixel frame', () {
      const code39 = 'SKU-8840';
      final modules = QrBarcodeCodec.encodeCode39(code39);
      final frame = QrScanFrame.fromLinearModules(modules, moduleScale: 3);

      final result = QrBarcodeDecoder.decodeSingle(
        frame,
        allowedFormats: const <QrBarcodeFormat>{QrBarcodeFormat.code39},
      );

      expect(result, isNotNull);
      expect(result!.format, QrBarcodeFormat.code39);
      expect(result.rawValue, code39);
    });

    test('encodes and decodes ITF (Interleaved 2 of 5) from pixel frame', () {
      const itf = '12345670';
      final modules = QrBarcodeCodec.encodeItf(itf);
      final frame = QrScanFrame.fromLinearModules(modules, moduleScale: 3);

      final result = QrBarcodeDecoder.decodeSingle(
        frame,
        allowedFormats: const <QrBarcodeFormat>{QrBarcodeFormat.itf},
      );

      expect(result, isNotNull);
      expect(result!.format, QrBarcodeFormat.itf);
      expect(result.rawValue, itf);
    });

    test('encodes and decodes Codabar from pixel frame', () {
      const codabar = '40156';
      final modules = QrBarcodeCodec.encodeCodabar(codabar);
      final frame = QrScanFrame.fromLinearModules(modules, moduleScale: 3);

      final result = QrBarcodeDecoder.decodeSingle(
        frame,
        allowedFormats: const <QrBarcodeFormat>{QrBarcodeFormat.codabar},
      );

      expect(result, isNotNull);
      expect(result!.format, QrBarcodeFormat.codabar);
      expect(result.rawValue, codabar);
    });
  });

  group('QrPayloadParser — Semantic Classification', () {
    test(
      'parses HTTPS URL, Wi-Fi, vCard, MECARD, Email, SMS, Phone, Geo, Payment',
      () {
        final url = QrPayloadParser.parse('https://humanize.id/docs');
        expect(url.type, QrPayloadType.url);
        expect(url.fields['host'], 'humanize.id');
        expect(url.fields['isSecure'], 'true');

        final wifi = QrPayloadParser.parse(
          'WIFI:S:Office_Mesh;T:WPA3;P:Pass123!;;',
        );
        expect(wifi.type, QrPayloadType.wifi);
        expect(wifi.fields['ssid'], 'Office_Mesh');
        expect(wifi.fields['encryption'], 'WPA3');
        expect(wifi.fields['password'], 'Pass123!');

        final vcard = QrPayloadParser.parse(
          'BEGIN:VCARD\nFN:Jane Doe\nORG:Humanize AI\nTEL:+628111\nEMAIL:jane@humanize.id\nEND:VCARD',
        );
        expect(vcard.type, QrPayloadType.vCard);
        expect(vcard.displayTitle, 'Jane Doe');
        expect(vcard.fields['org'], 'Humanize AI');

        final mecard = QrPayloadParser.parse(
          'MECARD:N:John;TEL:12345;EMAIL:john@example.com;;',
        );
        expect(mecard.type, QrPayloadType.vCard);
        expect(mecard.displayTitle, 'John');

        final mailto = QrPayloadParser.parse(
          'mailto:support@humanize.id?subject=Hello',
        );
        expect(mailto.type, QrPayloadType.email);
        expect(mailto.fields['subject'], 'Hello');

        final matmsg = QrPayloadParser.parse(
          'MATMSG:TO:team@humanize.id;SUB:SDK;BODY:Great;;',
        );
        expect(matmsg.type, QrPayloadType.email);
        expect(matmsg.fields['email'], 'team@humanize.id');

        final sms = QrPayloadParser.parse('smsto:+628123:Verify 9910');
        expect(sms.type, QrPayloadType.sms);
        expect(sms.fields['phone'], '+628123');
        expect(sms.fields['message'], 'Verify 9910');

        final phone = QrPayloadParser.parse('tel:+6281234567');
        expect(phone.type, QrPayloadType.phone);
        expect(phone.fields['phone'], '+6281234567');

        final geo = QrPayloadParser.parse('geo:-6.2088,106.8456');
        expect(geo.type, QrPayloadType.geo);
        expect(geo.fields['latitude'], '-6.2088');
        expect(geo.fields['longitude'], '106.8456');

        final upi = QrPayloadParser.parse(
          'upi://pay?pa=store@upi&pn=Humanize%20Store&am=250&cu=IDR',
        );
        expect(upi.type, QrPayloadType.payment);
        expect(upi.fields['amount'], '250');

        final qris = QrPayloadParser.parse('00020101021126580014ID.CO.QRIS');
        expect(qris.type, QrPayloadType.payment);
        expect(qris.fields['protocol'], 'EMVCo');
      },
    );
  });

  group('QrScannerController — State & Frame Lifecycle', () {
    test(
      'manages torch, camera, zoom, pause, and live frame processing',
      () async {
        final controller = QrScannerController(
          scanCooldown: const Duration(milliseconds: 500),
          enableHaptics: false,
        );
        addTearDown(controller.dispose);

        expect(controller.isScanning, isTrue);
        expect(controller.isTorchOn, isFalse);
        expect(controller.cameraFacing, QrCameraFacing.back);
        expect(controller.zoomLevel, 1.0);

        controller.toggleTorch();
        expect(controller.isTorchOn, isTrue);
        controller.setTorch(false);
        expect(controller.isTorchOn, isFalse);

        controller.switchCamera();
        expect(controller.cameraFacing, QrCameraFacing.front);
        controller.setCameraFacing(QrCameraFacing.external);
        expect(controller.cameraFacing, QrCameraFacing.external);

        controller.zoomIn(0.8);
        expect(controller.zoomLevel, closeTo(1.8, 0.01));
        controller.zoomOut(0.3);
        expect(controller.zoomLevel, closeTo(1.5, 0.01));

        final emitted = <QrScanResult>[];
        final sub = controller.resultsStream.listen(emitted.add);
        addTearDown(sub.cancel);

        final result = controller.simulateLiveDetection(
          'https://humanize.id',
          format: QrBarcodeFormat.qrCode,
        );
        await Future<void>.delayed(Duration.zero);

        expect(result, isNotNull);
        expect(controller.latestResult?.rawValue, 'https://humanize.id');
        expect(controller.scanHistory.length, 1);
        expect(emitted.length, 1);

        // Pause blocks frame decoding unless ignorePause is true
        controller.pause();
        expect(controller.isPaused, isTrue);
        final matrix = QrBarcodeCodec.encodeQrMatrix('PAUSED');
        final blocked = controller.processFrame(
          QrScanFrame.fromBinaryMatrix(matrix),
        );
        expect(blocked, isEmpty);

        controller.resume();
        expect(controller.isScanning, isTrue);

        controller.resetLock();
        expect(controller.latestResult, isNull);
        controller.clearHistory();
        expect(controller.scanHistory, isEmpty);
      },
    );
  });

  group(
    'QrBarcodeScannerView, QrBarcodeGraphic & QrVectorIcon — Widget Suite',
    () {
      testWidgets(
        'renders all 5 QrScannerLayout presets and handles interactions',
        (tester) async {
          final controller = QrScannerController(enableHaptics: false);
          addTearDown(controller.dispose);

          for (final layout in QrScannerLayout.values) {
            await tester.pumpWidget(
              SizedBox(
                width: 380,
                height: 680,
                child: QrBarcodeScannerView(
                  controller: controller,
                  layout: layout,
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 250));
            expect(find.byType(QrBarcodeScannerView), findsOneWidget);
          }

          // Tap target chip 'EAN-13'
          await tester.tap(find.text('EAN-13'));
          await tester.pump(const Duration(milliseconds: 200));
          expect(controller.latestResult?.format, QrBarcodeFormat.ean13);
          expect(controller.latestResult?.rawValue, '8997012345675');

          // Tap torch button
          await tester.tap(find.bySemanticsLabel('Toggle Torch'));
          await tester.pump();
          expect(controller.isTorchOn, isTrue);

          // Tap camera switch button
          await tester.tap(find.bySemanticsLabel('Switch Camera'));
          await tester.pump();
          expect(controller.cameraFacing, QrCameraFacing.front);
        },
      );

      testWidgets(
        'renders QrBarcodeGraphic across 2D eye styles and 1D formats',
        (tester) async {
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                children: <Widget>[
                  for (final eye in QrFinderEyeStyle.values)
                    QrBarcodeGraphic(
                      data: 'https://humanize.id',
                      finderEyeStyle: eye,
                      width: 80,
                      height: 80,
                    ),
                  const QrBarcodeGraphic(
                    data: '8997012345675',
                    format: QrBarcodeFormat.ean13,
                    width: 140,
                    height: 60,
                  ),
                  const QrBarcodeGraphic(
                    data: 'HMZ-128',
                    format: QrBarcodeFormat.code128,
                    width: 140,
                    height: 60,
                  ),
                  Wrap(
                    children: <Widget>[
                      for (final glyph in QrGlyph.values)
                        QrVectorIcon(glyph, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          );
          await tester.pump();

          expect(find.byType(QrBarcodeGraphic), findsNWidgets(6));
          expect(
            find.byType(QrVectorIcon),
            findsNWidgets(QrGlyph.values.length),
          );
        },
      );
    },
  );
}
