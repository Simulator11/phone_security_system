import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/detection_mode.dart';
import '../modules/lock_screen_camera/camera_controller_service.dart';

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

    _subscription = accelerometerEventStream().listen((event) {
      if (_initialX == null) {
        _initialX = event.x;
        _initialY = event.y;
        _initialZ = event.z;

        // Delay 5 seconds to calibrate
        _calibrationTimer = Timer(Duration(seconds: 5), () {
          _subscription?.cancel(); // Cancel the initial subscription

          // Start real monitoring
          _subscription = accelerometerEventStream().listen((newEvent) {
            double dx = (_initialX! - newEvent.x).abs();
            double dy = (_initialY! - newEvent.y).abs();
            double dz = (_initialZ! - newEvent.z).abs();

            double threshold = (mode == DetectionMode.rest)
                ? restThreshold
                : pocketThreshold;

            if (dx > threshold || dy > threshold || dz > threshold) {
              onMotionDetected();
              CameraControllerService.capturePhoto(); // 📸 Capture photo on motion
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
