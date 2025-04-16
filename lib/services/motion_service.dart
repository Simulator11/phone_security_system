import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/detection_mode.dart';

class MotionService {
  static StreamSubscription<AccelerometerEvent>? _subscription;
  static double? _initialX, _initialY, _initialZ;
  static Timer? _calibrationTimer;

  static const restThreshold = 1.5;
  static const pocketThreshold = 2.5;

  static void startDetection(
      DetectionMode mode, {
        required Function onMotionDetected,
      }) {
    _subscription?.cancel();
    _initialX = null;
    _initialY = null;
    _initialZ = null;

    _subscription = accelerometerEvents.listen((event) {
      if (_initialX == null) {
        // First read – set initial position
        _initialX = event.x;
        _initialY = event.y;
        _initialZ = event.z;

        // After 5 seconds, start comparing
        _calibrationTimer = Timer(Duration(seconds: 5), () {
          _subscription?.cancel();
          _subscription = accelerometerEvents.listen((newEvent) {
            double dx = (_initialX! - newEvent.x).abs();
            double dy = (_initialY! - newEvent.y).abs();
            double dz = (_initialZ! - newEvent.z).abs();

            double threshold = (mode == DetectionMode.rest)
                ? restThreshold
                : pocketThreshold;

            if (dx > threshold || dy > threshold || dz > threshold) {
              onMotionDetected();
            }
          });
        });
      }
    });
  }

  static void stopDetection() {
    _subscription?.cancel();
    _calibrationTimer?.cancel();
    _subscription = null;
    _initialX = _initialY = _initialZ = null;
  }
}
