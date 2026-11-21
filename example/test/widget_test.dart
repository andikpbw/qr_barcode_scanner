import 'package:flutter_qr_barcode_scanner/flutter_qr_barcode_scanner.dart';
import 'package:flutter_qr_barcode_scanner_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('QrScannerStudioApp renders and switches layouts cleanly', (
    tester,
  ) async {
    await tester.pumpWidget(const QrScannerStudioApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('QR & Barcode Scanner Studio'), findsOneWidget);
    expect(find.byType(QrBarcodeScannerView), findsOneWidget);

    await tester.tap(find.text('Morphing Pulse'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Morphing Pulse'), findsWidgets);
  });
}
