import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'qr_enums.dart';
import 'qr_scan_result.dart';
import 'qr_scanner_controller.dart';
import 'qr_scanner_style.dart';
import 'qr_vector_icon.dart';
import 'qr_viewfinder_painter.dart';

/// Preset target item used by the built-in interactive camera simulation stage
/// when no external [QrBarcodeScannerView.cameraPreview] widget is supplied.
@immutable
class QrSimulationTarget {
  /// Creates a [QrSimulationTarget].
  const QrSimulationTarget({
    required this.label,
    required this.rawValue,
    required this.format,
    this.cardTitle = 'Smart Pass',
    this.cardSubtitle = 'Verified Payload',
  });

  /// Short chip label for switching targets.
  final String label;

  /// Raw string encoded into the live barcode/QR graphic and decoded by the engine.
  final String rawValue;

  /// Barcode or QR symbology format.
  final QrBarcodeFormat format;

  /// Header text rendered on the simulated physical card in the camera scene.
  final String cardTitle;

  /// Subheader text rendered on the simulated physical card in the camera scene.
  final String cardSubtitle;

  /// Default showcase targets covering URL QR, Wi-Fi QR, EAN-13, Code-128, and Code-39.
  static const List<QrSimulationTarget> defaults = <QrSimulationTarget>[
    QrSimulationTarget(
      label: 'HTTPS QR',
      rawValue: 'https://humanize.id/qr-studio',
      format: QrBarcodeFormat.qrCode,
      cardTitle: 'Humanize AI Pass',
      cardSubtitle: 'TLS 1.3 Verified Deep Link',
    ),
    QrSimulationTarget(
      label: 'Wi-Fi QR',
      rawValue: 'WIFI:S:Humanize_5G_Lab;T:WPA2;P:Flutter2026!;;',
      format: QrBarcodeFormat.qrCode,
      cardTitle: 'Studio 5GHz Mesh',
      cardSubtitle: 'Instant WPA2 Network Provision',
    ),
    QrSimulationTarget(
      label: 'EAN-13',
      rawValue: '8997012345675',
      format: QrBarcodeFormat.ean13,
      cardTitle: 'GS1 Retail GTIN-13',
      cardSubtitle: 'Indonesia Prefix 899 • Verified',
    ),
    QrSimulationTarget(
      label: 'Code-128',
      rawValue: 'HMZ-2026-99A',
      format: QrBarcodeFormat.code128,
      cardTitle: 'Express Air Waybill',
      cardSubtitle: 'Logistics Batch #HMZ-2026',
    ),
    QrSimulationTarget(
      label: 'Code-39',
      rawValue: 'SKU-8840',
      format: QrBarcodeFormat.code39,
      cardTitle: 'Industrial Asset Tag',
      cardSubtitle: 'Warehouse Zone A-14',
    ),
  ];
}

/// Modern, lightweight, zero-dependency real-time QR & Barcode Scanner widget
/// with 5 animated viewfinder layouts, polygon target lock, pinch-to-zoom,
/// and semantic payload cards.
class QrBarcodeScannerView extends StatefulWidget {
  /// Creates a [QrBarcodeScannerView].
  const QrBarcodeScannerView({
    super.key,
    this.controller,
    this.layout = QrScannerLayout.cyberNeon,
    this.style,
    this.motion = const QrScannerMotionConfig(),
    this.allowedFormats,
    this.onDetect,
    this.onCopyPayload,
    this.cameraPreview,
    this.overlayBuilder,
    this.resultCardBuilder,
    this.simulationTargets = QrSimulationTarget.defaults,
    this.initialSimulationIndex = 0,
  });

  /// Optional external controller for programmatic scanning, torch, zoom, and frame feeding.
  final QrScannerController? controller;

  /// Animated viewfinder layout preset.
  final QrScannerLayout layout;

  /// Optional custom styling (defaults to [QrScannerStyle.forLayout]).
  final QrScannerStyle? style;

  /// Motion timing and curve configuration.
  final QrScannerMotionConfig motion;

  /// Optional set of allowed barcode symbologies.
  final Set<QrBarcodeFormat>? allowedFormats;

  /// Callback invoked whenever a QR code or barcode is decoded.
  final ValueChanged<QrScanResult>? onDetect;

  /// Optional callback invoked when the user taps the copy button on the result card.
  final ValueChanged<QrScanResult>? onCopyPayload;

  /// Optional live camera texture/preview widget.
  ///
  /// When omitted, [QrBarcodeScannerView] renders its built-in interactive
  /// camera simulation stage that encodes and decodes real pixel frames.
  final Widget? cameraPreview;

  /// Optional custom overlay builder rendered above the viewfinder painter.
  final Widget Function(BuildContext context, QrScanResult? latestResult)?
  overlayBuilder;

  /// Optional custom builder for the bottom detected result card.
  final Widget Function(BuildContext context, QrScanResult result)?
  resultCardBuilder;

  /// List of scannable targets displayed in the built-in interactive preview stage.
  final List<QrSimulationTarget> simulationTargets;

  /// Initial target index selected in the built-in interactive preview stage.
  final int initialSimulationIndex;

  @override
  State<QrBarcodeScannerView> createState() => _QrBarcodeScannerViewState();
}

class _QrBarcodeScannerViewState extends State<QrBarcodeScannerView>
    with TickerProviderStateMixin {
  QrScannerController? _internalController;
  QrScannerController get _controller =>
      widget.controller ?? _internalController!;

  late final AnimationController _sweepController;
  late final AnimationController _pulseController;
  late final AnimationController _lockController;
  late final AnimationController _morphController;
  late final AnimationController _focusController;

  StreamSubscription<QrScanResult>? _resultSubscription;
  Offset? _focusPoint;
  double _baseScaleZoom = 1.0;
  int _activeTargetIndex = 0;
  bool _copiedFeedback = false;

  QrScannerStyle get _effectiveStyle =>
      widget.style ?? QrScannerStyle.forLayout(widget.layout);

  @override
  void initState() {
    super.initState();
    _activeTargetIndex = widget.simulationTargets.isEmpty
        ? 0
        : widget.initialSimulationIndex.clamp(
            0,
            widget.simulationTargets.length - 1,
          );

    if (widget.controller == null) {
      _internalController = QrScannerController(
        allowedFormats: widget.allowedFormats,
        scanCooldown: widget.motion.scanCooldown,
        enableHaptics: widget.motion.enableHaptics,
      );
    } else if (widget.allowedFormats != null) {
      widget.controller!.setAllowedFormats(widget.allowedFormats);
    }

    if (widget.cameraPreview == null && widget.simulationTargets.isNotEmpty) {
      final initialTarget = widget.simulationTargets[_activeTargetIndex];
      _controller.setPreferWide1DCutout(initialTarget.format.is1D);
    }

    _sweepController = AnimationController(
      vsync: this,
      duration: widget.motion.laserSweepDuration,
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _lockController =
        AnimationController(vsync: this, duration: widget.motion.lockOnDuration)
          ..addListener(() {
            _controller.updateLockProgress(_lockController.value);
          });

    _morphController = AnimationController(
      vsync: this,
      duration: widget.motion.morphDuration,
      value: _controller.preferWide1DCutout ? 1.0 : 0.0,
    );

    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _bindController(_controller);

    if (widget.cameraPreview == null &&
        widget.motion.autoSimulateInPreview &&
        widget.simulationTargets.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.latestResult == null) {
          _triggerSimulatedTarget(_activeTargetIndex);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant QrBarcodeScannerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _unbindController(oldWidget.controller ?? _internalController);
      if (widget.controller == null) {
        _internalController ??= QrScannerController(
          allowedFormats: widget.allowedFormats,
          scanCooldown: widget.motion.scanCooldown,
          enableHaptics: widget.motion.enableHaptics,
        );
      }
      _bindController(_controller);
    }
    if (oldWidget.motion.laserSweepDuration !=
        widget.motion.laserSweepDuration) {
      _sweepController.duration = widget.motion.laserSweepDuration;
      if (_controller.isScanning) {
        _sweepController.repeat();
      }
    }
  }

  void _bindController(QrScannerController controller) {
    controller.addListener(_handleControllerChanged);
    _resultSubscription = controller.resultsStream.listen((result) {
      _lockController.forward(from: 0.0);
      widget.onDetect?.call(result);
    });
    if (controller.latestResult != null) {
      _lockController.value = 1.0;
    }
  }

  void _unbindController(QrScannerController? controller) {
    controller?.removeListener(_handleControllerChanged);
    _resultSubscription?.cancel();
    _resultSubscription = null;
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    final targetMorph = _controller.preferWide1DCutout ? 1.0 : 0.0;
    if ((_morphController.value - targetMorph).abs() > 0.01) {
      _morphController.animateTo(targetMorph, curve: widget.motion.morphCurve);
    }
    if (_controller.latestResult == null && _lockController.value > 0.0) {
      _lockController.reverse();
    } else if (_controller.latestResult != null &&
        _lockController.value == 0.0 &&
        !_lockController.isAnimating) {
      _lockController.forward();
    }
    setState(() {});
  }

  void _triggerSimulatedTarget(int index) {
    if (widget.simulationTargets.isEmpty) {
      return;
    }
    final safeIdx = index.clamp(0, widget.simulationTargets.length - 1);
    final target = widget.simulationTargets[safeIdx];
    setState(() {
      _activeTargetIndex = safeIdx;
      _copiedFeedback = false;
    });
    final corners = target.format.is2D
        ? const <Offset>[
            Offset(0.18, 0.18),
            Offset(0.82, 0.18),
            Offset(0.82, 0.82),
            Offset(0.18, 0.82),
          ]
        : const <Offset>[
            Offset(0.10, 0.24),
            Offset(0.90, 0.24),
            Offset(0.90, 0.76),
            Offset(0.10, 0.76),
          ];
    _controller.simulateLiveDetection(
      target.rawValue,
      format: target.format,
      corners: corners,
    );
    _lockController.forward(from: 0.0);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _focusPoint = details.localPosition;
    });
    _focusController.forward(from: 0.0);
  }

  Future<void> _handleCopyResult(QrScanResult result) async {
    await Clipboard.setData(ClipboardData(text: result.rawValue));
    widget.onCopyPayload?.call(result);
    if (!mounted) {
      return;
    }
    setState(() {
      _copiedFeedback = true;
    });
  }

  @override
  void dispose() {
    _unbindController(_controller);
    _internalController?.dispose();
    _sweepController.dispose();
    _pulseController.dispose();
    _lockController.dispose();
    _morphController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _effectiveStyle;
    final latest = _controller.latestResult;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: _handleTapUp,
          onScaleStart: (_) {
            _baseScaleZoom = _controller.zoomLevel;
          },
          onScaleUpdate: (details) {
            if ((details.scale - 1.0).abs() > 0.01) {
              _controller.setZoom(_baseScaleZoom * details.scale);
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // 1. Live Camera Feed or Built-in Interactive Simulation Stage
              Transform.scale(
                scale: 1.0 + (_controller.zoomLevel - 1.0) * 0.22,
                child:
                    widget.cameraPreview ?? _buildSimulatedCameraStage(style),
              ),

              // 2. Torch ambient illumination overlay
              if (_controller.isTorchOn)
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.1),
                        radius: 0.85,
                        colors: <Color>[
                          const Color(0xFFFFFBEB).withValues(alpha: 0.20),
                          const Color(0x00000000),
                        ],
                      ),
                    ),
                  ),
                ),

              // 3. Animated Viewfinder & Polygon Lock Painter
              AnimatedBuilder(
                animation: Listenable.merge(<Listenable>[
                  _sweepController,
                  _pulseController,
                  _lockController,
                  _morphController,
                  _focusController,
                ]),
                builder: (context, _) {
                  final sweepVal = widget.motion.sweepCurve.transform(
                    _sweepController.value,
                  );
                  final lockVal = widget.motion.lockCurve
                      .transform(_lockController.value)
                      .clamp(0.0, 1.0);
                  return CustomPaint(
                    painter: QrViewfinderPainter(
                      layout: widget.layout,
                      style: style,
                      sweepProgress: sweepVal,
                      pulseProgress: _pulseController.value,
                      lockProgress: lockVal,
                      aspectMorph: _morphController.value,
                      activeDetections: _controller.activeDetections,
                      focusPoint: _focusPoint,
                      focusProgress: _focusController.value,
                      isPaused: _controller.isPaused,
                    ),
                  );
                },
              ),

              // 4. Top Telemetry & Camera Control HUD
              if (style.showTopBar)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: _buildTopHudBar(style),
                ),

              // 5. Subtitle & Simulation Target Switcher below cutout
              Positioned(
                left: 14,
                right: 14,
                bottom: style.showResultSheet && latest != null ? 116 : 22,
                child: _buildMidControls(style),
              ),

              // 6. Custom overlay builder
              if (widget.overlayBuilder != null)
                widget.overlayBuilder!(context, latest),

              // 7. Bottom Semantic Result Sheet
              if (style.showResultSheet && latest != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: widget.resultCardBuilder != null
                      ? widget.resultCardBuilder!(context, latest)
                      : _buildSemanticResultCard(style, latest),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimulatedCameraStage(QrScannerStyle style) {
    final hasTargets = widget.simulationTargets.isNotEmpty;
    final target = hasTargets
        ? widget.simulationTargets[_activeTargetIndex.clamp(
            0,
            widget.simulationTargets.length - 1,
          )]
        : const QrSimulationTarget(
            label: 'QR Code',
            rawValue: 'https://humanize.id',
            format: QrBarcodeFormat.qrCode,
          );

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF0B1120),
            Color(0xFF131C31),
            Color(0xFF090D18),
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final dy = math.sin(_pulseController.value * math.pi * 2) * 3.0;
          return Align(
            alignment: const Alignment(0, -0.10),
            child: Transform.translate(offset: Offset(0, dy), child: child),
          );
        },
        child: _buildSimulatedPhysicalCard(style, target),
      ),
    );
  }

  Widget _buildSimulatedPhysicalCard(
    QrScannerStyle style,
    QrSimulationTarget target,
  ) {
    final is2D = target.format.is2D;
    return Container(
      width: is2D ? 156 : 214,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: style.accentColor.withValues(alpha: 0.26),
          width: 1.0,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: style.accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  target.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          QrBarcodeGraphic(
            data: target.rawValue,
            format: target.format,
            width: is2D ? 124 : 188,
            height: is2D ? 124 : 68,
            padding: EdgeInsets.all(is2D ? 8 : 7),
            borderRadius: 11,
            finderEyeStyle: widget.layout == QrScannerLayout.morphingPulse
                ? QrFinderEyeStyle.circle
                : widget.layout == QrScannerLayout.holographicGrid
                ? QrFinderEyeStyle.diamond
                : QrFinderEyeStyle.rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTopHudBar(QrScannerStyle style) {
    final latest = _controller.latestResult;
    return Row(
      children: <Widget>[
        // Active status & layout pill
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: style.accentColor.withValues(alpha: 0.32),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _controller.isScanning
                        ? style.successColor
                        : const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        style.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (style.showTelemetry)
                        Text(
                          latest != null
                              ? '${latest.format.displayName} • ${latest.scanDurationMicroseconds}µs • ${_controller.fps.round()} FPS'
                              : 'LIVE ${_controller.fps.round()} FPS • ${_controller.zoomLevel.toStringAsFixed(1)}x',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: style.accentColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        // 2D / 1D Aspect Ratio Morph Button
        _buildHudIconButton(
          glyph: _controller.preferWide1DCutout
              ? QrGlyph.barcode
              : QrGlyph.qrCode,
          active: _controller.preferWide1DCutout,
          accentColor: style.accentColor,
          semanticLabel: 'Toggle 2D/1D Cutout Aspect',
          onTap: _controller.toggleCutoutAspectMode,
        ),
        const SizedBox(width: 6),
        // Torch Button
        _buildHudIconButton(
          glyph: _controller.isTorchOn ? QrGlyph.flashOn : QrGlyph.flashOff,
          active: _controller.isTorchOn,
          accentColor: const Color(0xFFFBBF24),
          semanticLabel: 'Toggle Torch',
          onTap: _controller.toggleTorch,
        ),
        const SizedBox(width: 6),
        // Camera Switch Button
        _buildHudIconButton(
          glyph: QrGlyph.cameraSwitch,
          active: _controller.cameraFacing == QrCameraFacing.front,
          accentColor: style.accentColor,
          semanticLabel: 'Switch Camera',
          onTap: _controller.switchCamera,
        ),
      ],
    );
  }

  Widget _buildHudIconButton({
    required QrGlyph glyph,
    required bool active,
    required Color accentColor,
    required String semanticLabel,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? accentColor.withValues(alpha: 0.24)
                : const Color(0xFF0F172A).withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? accentColor
                  : const Color(0xFFFFFFFF).withValues(alpha: 0.16),
            ),
          ),
          child: QrVectorIcon(
            glyph,
            size: 14.5,
            color: active ? accentColor : const Color(0xFFE2E8F0),
          ),
        ),
      ),
    );
  }

  Widget _buildMidControls(QrScannerStyle style) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Helper subtitle & zoom indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            style.subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 10.2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (style.showBottomControls &&
            widget.cameraPreview == null &&
            widget.simulationTargets.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(widget.simulationTargets.length, (
                index,
              ) {
                final item = widget.simulationTargets[index];
                final selected = index == _activeTargetIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => _triggerSimulatedTarget(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? style.accentColor.withValues(alpha: 0.24)
                            : const Color(0xFF0F172A).withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected
                              ? style.accentColor
                              : const Color(0xFFFFFFFF).withValues(alpha: 0.14),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          QrVectorIcon(
                            item.format.is2D ? QrGlyph.qrCode : QrGlyph.barcode,
                            size: 11,
                            color: selected
                                ? style.accentColor
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFFCBD5E1),
                              fontSize: 10.0,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSemanticResultCard(QrScannerStyle style, QrScanResult result) {
    final payload = result.payload;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: style.frostedBlurSigma,
          sigmaY: style.frostedBlurSigma,
        ),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: style.successColor.withValues(alpha: 0.55),
              width: 1.2,
            ),
          ),
          child: Row(
            children: <Widget>[
              // Payload semantic glyph icon badge
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      style.successColor.withValues(alpha: 0.28),
                      style.accentColor.withValues(alpha: 0.18),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: style.successColor.withValues(alpha: 0.45),
                  ),
                ),
                child: QrVectorIcon(
                  payload.suggestedGlyph,
                  size: 19,
                  color: style.successColor,
                ),
              ),
              const SizedBox(width: 10),
              // Decoded title, subtitle & format badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: style.successColor.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            result.format.displayName.toUpperCase(),
                            maxLines: 1,
                            style: TextStyle(
                              color: style.successColor,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${(result.confidence * 100).round()}% VERIFIED',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      payload.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF8FAFC),
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      payload.displaySubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Copy Payload Action
              GestureDetector(
                onTap: () => _handleCopyResult(result),
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _copiedFeedback
                        ? style.successColor.withValues(alpha: 0.25)
                        : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrVectorIcon(
                    _copiedFeedback ? QrGlyph.checkCircle : QrGlyph.copy,
                    size: 13.5,
                    color: _copiedFeedback
                        ? style.successColor
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Dismiss / Rescan Lock Action
              GestureDetector(
                onTap: _controller.resetLock,
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const QrVectorIcon(
                    QrGlyph.close,
                    size: 13.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
