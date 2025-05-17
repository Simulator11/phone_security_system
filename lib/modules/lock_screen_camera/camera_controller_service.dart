import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class CameraControllerService {
  static CameraController? _controller;
  static Timer? _captureTimer;
  static bool _isCapturing = false;

  static Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller?.initialize();
    } catch (e) {
      print("❌ Camera Initialization Failed: $e");
    }
  }

  static Future<XFile?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      await initializeCamera();
    }
    if (_controller!.value.isTakingPicture) return null;

    try {
      return await _controller!.takePicture();
    } catch (e) {
      print("❌ Error taking picture: $e");
      return null;
    }
  }

  static void startContinuousCapture() {
    stopContinuousCapture();

    _captureTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _capturePhotoOnce();
    });
  }

  static Future<void> _capturePhotoOnce() async {
    if (_isCapturing) return;
    _isCapturing = true;

    try {
      final picture = await takePicture();
      if (picture != null) {
        final bytes = await File(picture.path).readAsBytes();
        final result = await ImageGallerySaverPlus.saveImage(
          Uint8List.fromList(bytes),
          quality: 80,
          name: "Security_${DateTime.now().millisecondsSinceEpoch}",
        );

        if (result.isSuccess) {
          print("✅ Image successfully saved to gallery.");
        } else {
          print("❌ Failed to save image to gallery.");
        }
      }
    } catch (e) {
      print("❌ Failed to capture photo in background: $e");
    } finally {
      _isCapturing = false;
    }
  }

  static void stopContinuousCapture() {
    _captureTimer?.cancel();
    _captureTimer = null;
  }

  static void dispose() {
    stopContinuousCapture();
    _controller?.dispose();
    _controller = null;
  }
}
