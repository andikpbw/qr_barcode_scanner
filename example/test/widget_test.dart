import 'package:flutter_test/flutter_test.dart';
import 'package:qr_barcode_scanner/qr_barcode_scanner.dart';
import 'package:qr_barcode_scanner_example/main.dart';

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
