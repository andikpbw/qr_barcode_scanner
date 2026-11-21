import 'package:flutter/widgets.dart';
import 'package:flutter_qr_barcode_scanner/flutter_qr_barcode_scanner.dart';

void main() {
  runApp(const QrScannerStudioApp());
}

/// Interactive showcase app demonstrating all 5 animated viewfinder layouts of
/// `qr_barcode_scanner` using pure `package:flutter/widgets.dart`
/// (zero Material or Cupertino dependencies).
class QrScannerStudioApp extends StatelessWidget {
  /// Creates a [QrScannerStudioApp].
  const QrScannerStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'QR & Barcode Scanner Studio',
      color: const Color(0xFF00F5D4),
      debugShowCheckedModeBanner: false,
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        );
      },
      home: const QrScannerStudioHome(),
    );
  }
}

/// Primary home screen for the interactive QR & Barcode Scanner Studio.
class QrScannerStudioHome extends StatefulWidget {
  /// Creates a [QrScannerStudioHome].
  const QrScannerStudioHome({super.key});

  @override
  State<QrScannerStudioHome> createState() => _QrScannerStudioHomeState();
}

class _QrScannerStudioHomeState extends State<QrScannerStudioHome> {
  final QrScannerController _controller = QrScannerController();

  QrScannerLayout _layout = QrScannerLayout.cyberNeon;
  String _statusText = 'Real-time pixel decoder ready';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectLayout(QrScannerLayout layout) {
    setState(() {
      _layout = layout;
      _statusText = 'Active viewfinder: ${_layoutLabel(layout)}';
    });
  }

  String _layoutLabel(QrScannerLayout layout) {
    switch (layout) {
      case QrScannerLayout.cyberNeon:
        return 'Cyber Neon';
      case QrScannerLayout.morphingPulse:
        return 'Morphing Pulse';
      case QrScannerLayout.holographicGrid:
        return 'Holographic Grid';
      case QrScannerLayout.minimalGlass:
        return 'Minimal Glass';
      case QrScannerLayout.industrialHud:
        return 'Industrial HUD';
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = QrScannerStyle.forLayout(_layout);

    return ColoredBox(
      color: const Color(0xFF060913),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeader(style),
              const SizedBox(height: 12),
              _buildLayoutSelector(style),
              const SizedBox(height: 12),
              Expanded(
                child: QrBarcodeScannerView(
                  controller: _controller,
                  layout: _layout,
                  style: style,
                  onDetect: (result) {
                    setState(() {
                      _statusText =
                          'Decoded ${result.format.displayName}: ${result.payload.displayTitle}';
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              _buildFooterControls(style),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(QrScannerStyle style) {
    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: style.accentColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: style.accentColor.withValues(alpha: 0.45),
            ),
          ),
          child: QrVectorIcon(
            QrGlyph.qrCode,
            size: 20,
            color: style.accentColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'QR & Barcode Scanner Studio',
                style: TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _statusText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLayoutSelector(QrScannerStyle style) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: QrScannerLayout.values.map((layout) {
          final selected = layout == _layout;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _selectLayout(layout),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? style.accentColor.withValues(alpha: 0.22)
                      : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: selected
                        ? style.accentColor
                        : const Color(0xFF1E293B),
                  ),
                ),
                child: Text(
                  _layoutLabel(layout),
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooterControls(QrScannerStyle style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _buildActionChip(
            label: _controller.isScanning ? 'Pause' : 'Resume',
            glyph: QrGlyph.focus,
            color: style.accentColor,
            onTap: () {
              _controller.togglePause();
              setState(() {});
            },
          ),
          _buildActionChip(
            label: '2D / 1D Morph',
            glyph: _controller.preferWide1DCutout
                ? QrGlyph.barcode
                : QrGlyph.qrCode,
            color: style.secondaryColor,
            onTap: _controller.toggleCutoutAspectMode,
          ),
          _buildActionChip(
            label: 'Zoom ${_controller.zoomLevel.toStringAsFixed(1)}x',
            glyph: QrGlyph.zoomIn,
            color: style.successColor,
            onTap: () {
              final next = _controller.zoomLevel >= 2.5
                  ? 1.0
                  : _controller.zoomLevel + 0.5;
              _controller.setZoom(next);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required QrGlyph glyph,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.38)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            QrVectorIcon(glyph, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
