import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class AlarmService {
  static final _player = AudioPlayer();

  static Future<void> triggerAlarm() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop); // 🔁 Loop the alarm
      await _player.play(AssetSource('sounds/alarm.mp3'), volume: 1.0);

      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 3000);
      }
    } catch (e) {
      print("Error triggering alarm: $e");
    }
  }

  static Future<void> stopAlarm() async {
    try {
      await _player.stop(); // 🔇 Stops looping too
      Vibration.cancel();
    } catch (e) {
      print("Error stopping alarm: $e");
    }
  }
}
