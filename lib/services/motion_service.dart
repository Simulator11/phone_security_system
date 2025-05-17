import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/detection_mode.dart';
import '../modules/lock_screen_camera/camera_controller_service.dart';
import 'flashlight_service.dart';
import 'alarm_service.dart';

class MotionService {
  static StreamSubscription<AccelerometerEvent>? _subscription;
  static double? _initialX, _initialY, _initialZ;
  static Timer? _calibrationTimer;
  static bool _isCapturing = false;

  static const restThreshold = 1.5;
  static const pocketThreshold = 2.5;

  static void startDetection(
      DetectionMode mode, {
        required Function onMotionDetected,
        required Function onMotionStopped,
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

        // ⏳ **Calibration for 5 seconds**
        _calibrationTimer = Timer(Duration(seconds: 5), () {
          _subscription?.cancel(); // Cancel the initial subscription

          // ✅ **Start real monitoring**
          _subscription = accelerometerEventStream().listen((newEvent) {
            double dx = (_initialX! - newEvent.x).abs();
            double dy = (_initialY! - newEvent.y).abs();
            double dz = (_initialZ! - newEvent.z).abs();

            double threshold = (mode == DetectionMode.rest)
                ? restThreshold
                : pocketThreshold;

            // 🚀 **Motion Detected**
            if (dx > threshold || dy > threshold || dz > threshold) {
              if (!_isCapturing) {
                _isCapturing = true;
                onMotionDetected();

                // Activate all security mechanisms
                CameraControllerService.startContinuousCapture();
                FlashlightService.toggleFlashlight(true);
                AlarmService.triggerAlarm();
              }
            } else {
              // 🛑 **Motion Stopped**
              if (_isCapturing) {
                _isCapturing = false;
                onMotionStopped();

                // Deactivate all security mechanisms
                CameraControllerService.stopContinuousCapture();
                FlashlightService.toggleFlashlight(false);
                AlarmService.stopAlarm();
              }
            }
          });
        });
      }
    });
  }

  static void stopDetection() {
    _subscription?.cancel();
    _calibrationTimer?.cancel();
    CameraControllerService.stopContinuousCapture();
    FlashlightService.toggleFlashlight(false);
    AlarmService.stopAlarm();
    _subscription = null;
    _initialX = _initialY = _initialZ = null;
  }
}
