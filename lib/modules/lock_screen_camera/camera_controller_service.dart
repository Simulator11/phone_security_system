import 'package:camera/camera.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CameraControllerService {
  static CameraController? _controller;

  static Future<void> initializeCamera() async {
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

  // ✅ New helper function for MotionService
  static Future<void> capturePhoto() async {
    try {
      final picture = await takePicture();
      if (picture != null) {
        final dir = await getApplicationDocumentsDirectory();
        final savedPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedFile = await File(picture.path).copy(savedPath);
        print("📸 Photo saved to: ${savedFile.path}");
      }
    } catch (e) {
      print("❌ Failed to capture photo: $e");
    }
  }

  static void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
