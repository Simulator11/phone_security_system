import 'package:torch_light/torch_light.dart';

class FlashlightService {
  static bool _isOn = false;

  static Future<void> toggleFlashlight(bool state) async {
    try {
      if (state && !_isOn) {
        await TorchLight.enableTorch();
        _isOn = true;
      } else if (!state && _isOn) {
        await TorchLight.disableTorch();
        _isOn = false;
      }
    } catch (e) {
      print("❌ Flashlight Error: $e");
    }
  }

  static bool get isOn => _isOn;
}
