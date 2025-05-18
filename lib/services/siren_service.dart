import 'package:audioplayers/audioplayers.dart';

class SirenService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playSiren() async {
    await _player.play(AssetSource('audio/siren.mp3'), volume: 1.0);
  }

  static Future<void> stopSiren() async {
    await _player.stop();
  }
}
