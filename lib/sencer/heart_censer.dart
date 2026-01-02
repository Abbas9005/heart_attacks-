// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:heart_risk_/sencer/stateselected.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

class HeartRateScreen extends StatefulWidget {
  const HeartRateScreen({super.key});

  @override
  State<HeartRateScreen> createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isMeasuring = false;
  int _heartRate = 0;
  final List<double> _redValues = [];
  final List<DateTime> _timestamps = [];
  Timer? _measurementTimer;
  int _measurementDuration = 0;
  String _statusMessage = 'Place your finger on the camera lens';
  String _detectionMode = 'finger';
  int _missingCoverFrames = 0;
  final int _maxMissingCoverFrames = 15;
  int _coverReadyFrames = 0;
  final int _requiredCoverFrames = 15;
  late final AudioPlayer _audioPlayer;
  double _baselineRedValue = 0.0;
  double _maxProgressReached = 0.0;
  bool _isFlashSupported = true;
  bool _isProcessingFrame = false;

  // Enhanced
  bool _isWarmingUp = true;
  int _warmupFrames = 0;
  final int _warmupFrameCount = 30;
  int _lastPeakCount = 0;
  int frameCount = 0;
  DateTime _lastFpsTime = DateTime.now();

  // 🔥 NEW: Prevent processing after finalization
  bool _isFinalizing = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    _initializeCamera();
  }

  void _safeStopImageStream() {
    try {
      _cameraController?.stopImageStream();
    } catch (e) {
      // ignore
    }
  }

  Future<void> _initializeCamera() async {
    final cameraStatus = await Permission.camera.request();
    if (cameraStatus != PermissionStatus.granted) {
      _showPermissionDialog();
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        setState(() {
          _statusMessage = 'No cameras found';
        });
        return;
      }

      final targetCamera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras![0],
      );

      _cameraController = CameraController(
        targetCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      try {
        await _cameraController!.setFlashMode(FlashMode.torch);
      } catch (e) {
        _isFlashSupported = false;
        _statusMessage = 'Flash unavailable. Use in bright light.';
      }

      setState(() {
        _isCameraInitialized = true;
      });

      _startImageStream();
    } catch (e) {
      setState(() {
        _statusMessage = 'Camera init failed. Try restarting.';
      });
    }
  }

  void _startImageStream() {
    if (!_isCameraInitialized || _cameraController == null || _isFinalizing) return;

    _cameraController!.startImageStream((CameraImage image) {
      if (_isFinalizing) return; // 🔥 Critical: skip if finalizing

      frameCount++;
      final now = DateTime.now();
      if (now.difference(_lastFpsTime).inSeconds >= 1) {
        frameCount = 0;
        _lastFpsTime = now;
      }

      if (_isProcessingFrame) return;
      _isProcessingFrame = true;

      try {
        if (!_isMeasuring) {
          _processCameraFrameForFingerDetection(image);
        } else {
          _processCameraFrame(image);
        }
      } catch (e) {
        // ignore
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  Future<void> _processCameraFrameForFingerDetection(CameraImage image) async {
    final redValue = _calculateAverageRedFromYPlane(image);

    if (_isWarmingUp) {
      _baselineRedValue = (_baselineRedValue * _warmupFrames + redValue) / (_warmupFrames + 1);
      _warmupFrames++;
      if (_warmupFrames >= _warmupFrameCount) {
        _isWarmingUp = false;
      }
      return;
    }

    // ✅ CORRECT: Finger = DARK → lower Y
    final threshold = max(_baselineRedValue * 0.6, 30.0);
    if (redValue < threshold) {
      _coverReadyFrames++;
      if (_coverReadyFrames >= _requiredCoverFrames) {
        _startMeasurement();
      }
    } else {
      _coverReadyFrames = 0;
      if (redValue > _baselineRedValue * 1.1) {
        _baselineRedValue = (_baselineRedValue * 0.98) + (redValue * 0.02);
      }
    }
  }

  void _showPermissionDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text('This app needs camera permission to measure heart rate. Please grant permission in settings.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _startMeasurement() async {
    if (!_isCameraInitialized || _cameraController == null || _isMeasuring || _isFinalizing) {
      return;
    }

    _measurementTimer?.cancel();
    _safeStopImageStream();

    setState(() {
      _isMeasuring = true;
      _heartRate = 0;
      _redValues.clear();
      _timestamps.clear();
      _measurementDuration = 0;
      _missingCoverFrames = 0;
      _coverReadyFrames = 0;
      _maxProgressReached = 0.0;
      _statusMessage = 'Measuring... keep finger still';
      _isWarmingUp = true;
      _warmupFrames = 0;
      _lastPeakCount = 0;
    });

    _playBeepSequence();
    _startImageStream();

    _measurementTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isMeasuring || _isFinalizing) {
        _measurementTimer?.cancel();
        return;
      }
      setState(() {
        _measurementDuration++;
        _maxProgressReached = (_measurementDuration * (100 / 15)).clamp(0.0, 100.0);
        if (_measurementDuration >= 15) {
          _stopMeasurement();
        }
      });
    });
  }

  Future<void> _processCameraFrame(CameraImage image) async {
    if (!_isMeasuring || _isFinalizing) return;

    final redValue = _calculateAverageRedFromYPlane(image);
    final threshold = max(_baselineRedValue * 0.6, 30.0);

    if (redValue >= threshold) {
      _missingCoverFrames++;
      if (_missingCoverFrames >= _maxMissingCoverFrames) {
        _stopForCoverageLoss();
        return;
      }
    } else {
      _missingCoverFrames = 0;
    }

    _redValues.add(redValue);
    _timestamps.add(DateTime.now());

    if (_redValues.length > 300) {
      _redValues.removeRange(0, _redValues.length - 300);
      _timestamps.removeRange(0, _timestamps.length - 300);
    }

    if (_timestamps.length > 10 && _redValues.length % 4 == 0) {
      _updateRealTimeBPM();
    }
  }

  void _updateRealTimeBPM() {
    if (!_isMeasuring || _redValues.length < 15 || _isFinalizing) return;

    final peaks = _findPeaks(_redValues);
    if (peaks.length < 2) return;

    if (peaks.length > _lastPeakCount) {
      Vibration.vibrate(duration: 20);
      _lastPeakCount = peaks.length;
    }

    double totalInterval = 0;
    for (int i = 1; i < peaks.length; i++) {
      totalInterval += _timestamps[peaks[i]].difference(_timestamps[peaks[i - 1]]).inMilliseconds;
    }

    if (peaks.length > 1) {
      final averageInterval = totalInterval / (peaks.length - 1);
      final heartRate = (60000 / averageInterval).round();
      setState(() {
        _heartRate = heartRate.clamp(60, 200);
      });
    }
  }

  void _stopForCoverageLoss() {
    if (_isFinalizing) return;
    _isFinalizing = true;

    _measurementTimer?.cancel();
    _safeStopImageStream();
    setState(() {
      _statusMessage = 'Finger moved away. Please cover fully.';
    });

    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _maxProgressReached = (_maxProgressReached - 3).clamp(0.0, 100.0);
        if (_maxProgressReached <= 0) {
          timer.cancel();
          _resetForRetry();
        }
      });
    });
  }

  void _stopMeasurement() {
    if (_isFinalizing) return;
    _isFinalizing = true;

    _measurementTimer?.cancel();
    _safeStopImageStream();

    if (_redValues.length < 15) {
      setState(() {
        _statusMessage = 'Not enough data. Try again.';
        _heartRate = 0;
      });
      _resetForRetry();
      return;
    }

    _calculateHeartRate();
  }

  void _calculateHeartRate() {
    final peaks = _findPeaks(_redValues);
    if (peaks.length < 2) {
      setState(() {
        _statusMessage = 'Heartbeat not detected. Try again.';
        _heartRate = 0;
      });
      _resetForRetry();
      return;
    }

    double totalInterval = 0;
    for (int i = 1; i < peaks.length; i++) {
      totalInterval += _timestamps[peaks[i]].difference(_timestamps[peaks[i - 1]]).inMilliseconds;
    }

    final averageInterval = totalInterval / (peaks.length - 1);
    final heartRate = (60000 / averageInterval).round();

    setState(() {
      _heartRate = heartRate.clamp(60, 200);
      _statusMessage = 'Measurement complete!';
    });

    // 🔥 Stop audio and flash
    _audioPlayer.stop();
    try {
      _cameraController?.setFlashMode(FlashMode.off);
    } catch (_) {}

    // Navigate after delay — DO NOT restart stream!
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _showStateSelectionScreen();
      }
    });
  }

  void _resetForRetry() {
    _isFinalizing = false;
    _isMeasuring = false;
    _measurementDuration = 0;
    _maxProgressReached = 0.0;
    _baselineRedValue = 0.0;
    _coverReadyFrames = 0;
    _missingCoverFrames = 0;
    _redValues.clear();
    _timestamps.clear();
    _startImageStream();
  }

  void _showStateSelectionScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StateSelectionScreen(heartRate: _heartRate),
      ),
    );
  }

  List<int> _findPeaks(List<double> values) {
    if (values.length < 20) return [];
    final detrended = _detrend(values, 15);
    final smoothed = _movingAverage(detrended, 5);
    final threshold = _calculateThreshold(smoothed);
    final peaks = <int>[];
    for (int i = 5; i < smoothed.length - 5; i++) {
      if (smoothed[i] > threshold &&
          smoothed[i] > smoothed[i - 1] &&
          smoothed[i] > smoothed[i + 1] &&
          smoothed[i] > smoothed[i - 2] * 1.05 &&
          smoothed[i] > smoothed[i + 2] * 1.05) {
        if (peaks.isEmpty || i - peaks.last > 10) {
          peaks.add(i);
        }
      }
    }
    return peaks;
  }

  List<double> _detrend(List<double> data, int window) {
    final trend = List<double>.filled(data.length, 0.0);
    for (int i = 0; i < data.length; i++) {
      int start = max(0, i - window);
      int end = min(data.length, i + window);
      double sum = 0;
      for (int j = start; j < end; j++) sum += data[j];
      trend[i] = sum / (end - start);
    }
    return List.generate(data.length, (i) => data[i] - trend[i]);
  }

  List<double> _movingAverage(List<double> data, int window) {
    final result = <double>[];
    for (int i = 0; i < data.length; i++) {
      int start = max(0, i - window ~/ 2);
      int end = min(data.length, i + window ~/ 2 + 1);
      double sum = 0;
      for (int j = start; j < end; j++) sum += data[j];
      result.add(sum / (end - start));
    }
    return result;
  }

  double _calculateThreshold(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = List<double>.from(values)..sort();
    final median = sorted[sorted.length ~/ 2];
    return median * 1.15;
  }

  Future<void> _playBeepSequence() async {
    try {
      await _audioPlayer.stop(); // Ensure clean state
      await Future.delayed(const Duration(milliseconds: 50));
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
      await Future.delayed(const Duration(milliseconds: 200));
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
    } catch (e) {
      // ignore
    }
  }

  double _calculateAverageRedFromYPlane(CameraImage image) {
    if (image.format.group != ImageFormatGroup.yuv420) return 0.0;
    final yPlane = image.planes[0].bytes;
    final width = image.width;
    final height = image.height;
    final bytesPerRow = image.planes[0].bytesPerRow;
    final region = (min(width, height) * 0.3).round();
    final startX = (width ~/ 2) - (region ~/ 2);
    final startY = (height ~/ 2) - (region ~/ 2);
    int sum = 0, count = 0;
    for (int dy = 0; dy < region; dy++) {
      for (int dx = 0; dx < region; dx++) {
        final x = startX + dx;
        final y = startY + dy;
        if (x < 0 || x >= width || y < 0 || y >= height) continue;
        final index = y * bytesPerRow + x;
        if (index >= yPlane.length) continue;
        sum += yPlane[index];
        count++;
      }
    }
    return count > 0 ? sum / count : 0.0;
  }

  @override
  void dispose() {
    _isFinalizing = true;
    _measurementTimer?.cancel();
    _safeStopImageStream();
    try {
      _cameraController?.setFlashMode(FlashMode.off);
    } catch (_) {}
    _cameraController?.dispose();
    _audioPlayer.stop();
    _audioPlayer.release();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_isMeasuring) {
              _stopMeasurement();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: const Text('Heart Rate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isMeasuring ? _stopMeasurement : () => Navigator.of(context).maybePop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad),
          child: ListView(
            children: [
              const SizedBox(height: 12),
              _buildHeartPreview(),
              const SizedBox(height: 18),
              const Text('Place your finger on camera lens', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              if (!_isFlashSupported && !_isMeasuring) ...[
                const SizedBox(height: 6),
                const Text('⚠️ Flash not available — ensure good lighting', textAlign: TextAlign.center, style: TextStyle(color: Colors.orange, fontSize: 12)),
              ],
              const SizedBox(height: 10),
              _buildModeSelector(),
              const SizedBox(height: 12),
              if (_isMeasuring) ...[
                LinearProgressIndicator(
                  value: _maxProgressReached / 100,
                  minHeight: 6,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
                ),
                const SizedBox(height: 8),
                Text('Measuring... $_measurementDuration s', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                if (_redValues.isNotEmpty)
                  SizedBox(height: 60, child: CustomPaint(painter: _WaveformPainter(_redValues, _maxProgressReached))),
              ] else ...[
                Text(_statusMessage, textAlign: TextAlign.center, style: TextStyle(color: _statusMessage.contains('error') || _statusMessage.contains('failed') || _statusMessage.contains('not') ? Colors.redAccent : Colors.white70)),
                const SizedBox(height: 16),
                if (_statusMessage.contains('try again') || _statusMessage.contains('failed') || _statusMessage.contains('not detected'))
                  ElevatedButton.icon(
                    onPressed: _startMeasurement,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  ),
              ],
              const SizedBox(height: 16),
              if (_heartRate > 0)
                Column(
                  children: [
                    Text('$_heartRate', style: const TextStyle(color: Colors.redAccent, fontSize: 56, fontWeight: FontWeight.bold)),
                    const Text('bpm', style: TextStyle(color: Colors.white70, fontSize: 18)),
                  ],
                ),
              const SizedBox(height: 12),
              _buildHowToCard(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeartPreview() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipPath(
            clipper: HeartClipper(),
            child: Container(
              width: 240,
              height: 210,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: _isCameraInitialized
                  ? CameraPreview(_cameraController!)
                  : const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent))),
            ),
          ),
          Positioned(
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_detectionMode == 'wrist' ? Icons.watch : Icons.touch_app, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(_detectionMode == 'wrist' ? 'Wrist mode' : 'Finger mode', style: const TextStyle(color: Colors.white, fontSize: 13)),
                  if (_isMeasuring) ...[
                    const SizedBox(width: 10),
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ModeChip(
          label: 'Finger',
          icon: Icons.touch_app,
          selected: _detectionMode == 'finger',
          onTap: _isMeasuring ? null : () => setState(() => _detectionMode = 'finger'),
        ),
        const SizedBox(width: 10),
        _ModeChip(
          label: 'Wrist',
          icon: Icons.watch,
          selected: _detectionMode == 'wrist',
          onTap: _isMeasuring ? null : () => setState(() => _detectionMode = 'wrist'),
        ),
      ],
    );
  }

  Widget _buildHowToCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF101014),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Text('How to measure?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InstructionTile(icon: Icons.favorite, title: 'Stay still', subtitle: 'Keep your finger steady\non the lens.'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _InstructionTile(icon: Icons.flash_on, title: 'Cover flash', subtitle: 'Cover camera & flash\ncompletely.'),
              ),
            ],
          ),
          SizedBox(height: 14),
          Text('Tips:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 14)),
          SizedBox(height: 6),
          Text(
            '• Relax your hand and avoid moving.\n'
            '• Apply gentle pressure—do not press too hard.\n'
            '• Warm fingers work best.\n'
            '• Measurement takes ~15 seconds.',
            style: TextStyle(color: Colors.white60, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ================ Supporting Widgets (No changes needed) ================

class _WaveformPainter extends CustomPainter {
  final List<double> data;
  final double progress;
  _WaveformPainter(this.data, this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()..color = Colors.redAccent.withOpacity(0.8)..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final visibleCount = (data.length * (progress / 100)).toInt().clamp(10, data.length);
    if (visibleCount <= 1) return;
    final points = <Offset>[];
    for (int i = 0; i < visibleCount; i++) {
      final x = i / (visibleCount - 1) * size.width;
      final normalizedY = (data[i] - 40) / 60;
      final y = size.height - (normalizedY * size.height * 0.7 + size.height * 0.15);
      points.add(Offset(x, y.clamp(0.0, size.height)));
    }
    if (points.length > 1) canvas.drawPoints(PointMode.polygon, points, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    final path = Path();
    path.moveTo(w / 2, h);
    path.cubicTo(-w * 0.1, h * 0.65, w * 0.05, h * 0.2, w * 0.35, h * 0.2);
    path.cubicTo(w * 0.5, h * 0.2, w * 0.5, h * 0.45, w / 2, h * 0.55);
    path.cubicTo(w * 0.5, h * 0.45, w * 0.5, h * 0.2, w * 0.65, h * 0.2);
    path.cubicTo(w * 0.95, h * 0.2, w * 1.1, h * 0.65, w / 2, h);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, required this.icon, required this.selected, this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.redAccent.withOpacity(0.2) : Colors.white12,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? Colors.redAccent : Colors.white24, width: selected ? 1.4 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _InstructionTile extends StatelessWidget {
  const _InstructionTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: Colors.redAccent),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.white70, height: 1.3)),
      ]),
    );
  }
}