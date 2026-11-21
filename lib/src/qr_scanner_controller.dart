import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'qr_barcode_codec.dart';
import 'qr_barcode_decoder.dart';
import 'qr_enums.dart';
import 'qr_scan_result.dart';

/// Controller for managing [QrBarcodeScannerView] state, real-time frame decoding,
/// torch, camera lens, zoom, format filters, and detection history.
class QrScannerController extends ChangeNotifier {
  /// Creates a [QrScannerController].
  QrScannerController({
    bool autoStart = true,
    QrCameraFacing initialFacing = QrCameraFacing.back,
    double initialZoom = 1.0,
    Set<QrBarcodeFormat>? allowedFormats,
    Rect? scanWindow,
    this.scanCooldown = const Duration(milliseconds: 850),
    this.enableHaptics = true,
    this.maxHistoryLength = 50,
  }) : _isScanning = autoStart,
       _cameraFacing = initialFacing,
       _zoomLevel = initialZoom.clamp(1.0, 5.0),
       _allowedFormats = allowedFormats != null
           ? Set<QrBarcodeFormat>.unmodifiable(allowedFormats)
           : null,
       _scanWindow = scanWindow;

  /// Cooldown duration preventing duplicate emissions of the exact same code.
  final Duration scanCooldown;

  /// Whether light haptic feedback is triggered when a new code is locked on.
  final bool enableHaptics;

  /// Maximum number of recent [QrScanResult] items retained in [scanHistory].
  final int maxHistoryLength;

  final StreamController<QrScanResult> _resultsStreamController =
      StreamController<QrScanResult>.broadcast();
  final ValueNotifier<double> _lockProgressNotifier = ValueNotifier<double>(
    0.0,
  );
  final List<QrScanResult> _scanHistory = <QrScanResult>[];

  bool _isScanning;
  bool _isTorchOn = false;
  bool _preferWide1DCutout = false;
  QrCameraFacing _cameraFacing;
  double _zoomLevel;
  Set<QrBarcodeFormat>? _allowedFormats;
  Rect? _scanWindow;
  QrScanResult? _latestResult;
  List<QrScanResult> _activeDetections = const <QrScanResult>[];
  int _framesProcessed = 0;
  double _fps = 60.0;
  DateTime? _lastFrameTimestamp;
  DateTime? _lastEmitTimestamp;
  String? _lastEmittedKey;
  bool _isDisposed = false;

  /// Broadcast stream of verified [QrScanResult] detections.
  Stream<QrScanResult> get resultsStream => _resultsStreamController.stream;

  /// Listenable tracking the normalized target lock-on progress (`0.0..1.0`).
  ValueListenable<double> get lockProgressListenable => _lockProgressNotifier;

  /// Whether the scanner is actively processing incoming frames.
  bool get isScanning => _isScanning;

  /// Whether scanning is currently paused.
  bool get isPaused => !_isScanning;

  /// Whether the torch / flash illumination is active.
  bool get isTorchOn => _isTorchOn;

  /// Whether the viewfinder prefers a wide 1D barcode cutout aspect ratio.
  bool get preferWide1DCutout => _preferWide1DCutout;

  /// Active camera lens direction.
  QrCameraFacing get cameraFacing => _cameraFacing;

  /// Current optical/digital zoom factor (`1.0..5.0`).
  double get zoomLevel => _zoomLevel;

  /// Optional set of allowed barcode symbologies (`null` allows all formats).
  Set<QrBarcodeFormat>? get allowedFormats => _allowedFormats;

  /// Optional normalized (`0.0..1.0`) scan window region of interest.
  Rect? get scanWindow => _scanWindow;

  /// Most recently decoded [QrScanResult], or `null` if none or cleared.
  QrScanResult? get latestResult => _latestResult;

  /// All codes detected in the most recent frame (for multi-barcode HUD overlays).
  List<QrScanResult> get activeDetections => _activeDetections;

  /// Chronological history of unique/recent detections (newest first).
  List<QrScanResult> get scanHistory =>
      List<QrScanResult>.unmodifiable(_scanHistory);

  /// Total number of frames decoded by this controller.
  int get framesProcessed => _framesProcessed;

  /// Smoothed frames-per-second throughput estimate.
  double get fps => _fps;

  /// Starts or resumes real-time frame scanning.
  void start() {
    if (_isDisposed || _isScanning) {
      return;
    }
    _isScanning = true;
    notifyListeners();
  }

  /// Pauses real-time frame scanning while keeping the last preview visible.
  void pause() {
    if (_isDisposed || !_isScanning) {
      return;
    }
    _isScanning = false;
    notifyListeners();
  }

  /// Resumes real-time frame scanning after a [pause].
  void resume() => start();

  /// Stops scanning and clears the active target lock.
  void stop() {
    if (_isDisposed) {
      return;
    }
    _isScanning = false;
    _activeDetections = const <QrScanResult>[];
    _lockProgressNotifier.value = 0.0;
    notifyListeners();
  }

  /// Toggles between active scanning and paused states.
  void togglePause() {
    if (_isScanning) {
      pause();
    } else {
      start();
    }
  }

  /// Toggles the torch / flashlight state.
  void toggleTorch() {
    if (_isDisposed) {
      return;
    }
    _isTorchOn = !_isTorchOn;
    notifyListeners();
  }

  /// Explicitly sets the torch / flashlight state.
  void setTorch(bool enabled) {
    if (_isDisposed || _isTorchOn == enabled) {
      return;
    }
    _isTorchOn = enabled;
    notifyListeners();
  }

  /// Cycles between rear and front camera lenses.
  void switchCamera() {
    if (_isDisposed) {
      return;
    }
    _cameraFacing = _cameraFacing == QrCameraFacing.back
        ? QrCameraFacing.front
        : QrCameraFacing.back;
    notifyListeners();
  }

  /// Sets the active camera lens direction.
  void setCameraFacing(QrCameraFacing facing) {
    if (_isDisposed || _cameraFacing == facing) {
      return;
    }
    _cameraFacing = facing;
    notifyListeners();
  }

  /// Sets the zoom factor, clamped between `1.0` and `5.0`.
  void setZoom(double zoom) {
    if (_isDisposed) {
      return;
    }
    final clamped = zoom.clamp(1.0, 5.0);
    if ((_zoomLevel - clamped).abs() < 0.005) {
      return;
    }
    _zoomLevel = clamped;
    notifyListeners();
  }

  /// Increments the zoom level by [step] (default `0.5`).
  void zoomIn([double step = 0.5]) => setZoom(_zoomLevel + step);

  /// Decrements the zoom level by [step] (default `0.5`).
  void zoomOut([double step = 0.5]) => setZoom(_zoomLevel - step);

  /// Toggles the preferred viewfinder cutout geometry between 2D square and 1D wide modes.
  void toggleCutoutAspectMode() {
    if (_isDisposed) {
      return;
    }
    _preferWide1DCutout = !_preferWide1DCutout;
    notifyListeners();
  }

  /// Sets whether the viewfinder cutout should prefer a wide 1D barcode aspect ratio.
  void setPreferWide1DCutout(bool preferWide) {
    if (_isDisposed || _preferWide1DCutout == preferWide) {
      return;
    }
    _preferWide1DCutout = preferWide;
    notifyListeners();
  }

  /// Updates the set of allowed [QrBarcodeFormat]s (`null` allows all formats).
  void setAllowedFormats(Set<QrBarcodeFormat>? formats) {
    if (_isDisposed) {
      return;
    }
    _allowedFormats = formats != null
        ? Set<QrBarcodeFormat>.unmodifiable(formats)
        : null;
    if (formats != null && formats.isNotEmpty && formats.every((f) => f.is1D)) {
      _preferWide1DCutout = true;
    } else if (formats != null &&
        formats.isNotEmpty &&
        formats.every((f) => f.is2D)) {
      _preferWide1DCutout = false;
    }
    notifyListeners();
  }

  /// Updates the normalized (`0.0..1.0`) region of interest for decoding.
  void setScanWindow(Rect? window) {
    if (_isDisposed || _scanWindow == window) {
      return;
    }
    _scanWindow = window;
    notifyListeners();
  }

  /// Updates the internal target lock-on animation progress (`0.0..1.0`).
  void updateLockProgress(double value) {
    if (_isDisposed) {
      return;
    }
    _lockProgressNotifier.value = value.clamp(0.0, 1.0);
  }

  /// Clears the currently locked result and resets the target reticle.
  void resetLock() {
    if (_isDisposed) {
      return;
    }
    _latestResult = null;
    _activeDetections = const <QrScanResult>[];
    _lastEmittedKey = null;
    _lockProgressNotifier.value = 0.0;
    notifyListeners();
  }

  /// Clears the accumulated [scanHistory].
  void clearHistory() {
    if (_isDisposed) {
      return;
    }
    _scanHistory.clear();
    notifyListeners();
  }

  /// Processes a raw [QrScanFrame] through [QrBarcodeDecoder] in real time.
  ///
  /// Returns all detected [QrScanResult] items in the frame. If scanning is
  /// paused via [pause], returns an empty list unless [ignorePause] is `true`.
  List<QrScanResult> processFrame(
    QrScanFrame frame, {
    bool ignorePause = false,
  }) {
    if (_isDisposed || (!_isScanning && !ignorePause)) {
      return const <QrScanResult>[];
    }

    final now = DateTime.now();
    if (_lastFrameTimestamp != null) {
      final elapsedMs = now.difference(_lastFrameTimestamp!).inMilliseconds;
      if (elapsedMs > 0) {
        final instantFps = (1000.0 / elapsedMs).clamp(1.0, 120.0);
        _fps = (_fps * 0.8) + (instantFps * 0.2);
      }
    }
    _lastFrameTimestamp = now;
    _framesProcessed++;

    final detected = QrBarcodeDecoder.decodeFrame(
      frame,
      allowedFormats: _allowedFormats,
      scanWindow: _scanWindow,
    );

    if (detected.isEmpty) {
      return const <QrScanResult>[];
    }

    _activeDetections = List<QrScanResult>.unmodifiable(detected);
    final primary = detected.first;
    _preferWide1DCutout = primary.format.is1D;

    final emitKey = '${primary.format.name}:${primary.rawValue}';
    final withinCooldown =
        _lastEmittedKey == emitKey &&
        _lastEmitTimestamp != null &&
        now.difference(_lastEmitTimestamp!) < scanCooldown;

    _latestResult = primary;
    _lockProgressNotifier.value = 1.0;

    if (!withinCooldown) {
      _lastEmittedKey = emitKey;
      _lastEmitTimestamp = now;
      _scanHistory.removeWhere(
        (item) =>
            item.rawValue == primary.rawValue && item.format == primary.format,
      );
      _scanHistory.insert(0, primary);
      if (_scanHistory.length > maxHistoryLength) {
        _scanHistory.removeLast();
      }
      if (!_resultsStreamController.isClosed) {
        _resultsStreamController.add(primary);
      }
      if (enableHaptics) {
        HapticFeedback.selectionClick();
      }
    }

    notifyListeners();
    return detected;
  }

  /// Decodes a one-shot pixel buffer and updates controller state if a code is found.
  List<QrScanResult> scanBytes(
    Uint8List bytes, {
    required int width,
    required int height,
    QrPixelFormat pixelFormat = QrPixelFormat.rgba8888,
  }) {
    final frame = QrScanFrame(
      bytes: bytes,
      width: width,
      height: height,
      pixelFormat: pixelFormat,
    );
    return processFrame(frame, ignorePause: true);
  }

  /// Synthesizes a real pixel buffer for [rawValue] in [format] using [QrBarcodeCodec]
  /// and runs it through the live [processFrame] pixel decoder pipeline.
  ///
  /// Optional [corners] can override the normalized polygon coordinates for UI preview positioning.
  QrScanResult? simulateLiveDetection(
    String rawValue, {
    QrBarcodeFormat format = QrBarcodeFormat.qrCode,
    List<Offset>? corners,
  }) {
    if (_isDisposed) {
      return null;
    }

    final QrScanFrame syntheticFrame;
    if (format.is2D) {
      final matrix = QrBarcodeCodec.encodeQrMatrix(rawValue);
      syntheticFrame = QrScanFrame.fromBinaryMatrix(
        matrix,
        quietZoneModules: 4,
        moduleScale: 4,
      );
    } else {
      final modules = QrBarcodeCodec.encodeLinear(rawValue, format: format);
      syntheticFrame = QrScanFrame.fromLinearModules(
        modules,
        height: 60,
        quietZoneModules: 10,
        moduleScale: 3,
      );
    }

    final decodedList = processFrame(syntheticFrame, ignorePause: true);
    if (decodedList.isEmpty) {
      return null;
    }

    var primary = decodedList.first;
    if (corners != null || primary.format != format) {
      primary = primary.copyWith(format: format, corners: corners);
      _latestResult = primary;
      _activeDetections = <QrScanResult>[primary];
      if (_scanHistory.isNotEmpty) {
        _scanHistory[0] = primary;
      }
      notifyListeners();
    }
    return primary;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _resultsStreamController.close();
    _lockProgressNotifier.dispose();
    super.dispose();
  }
}
