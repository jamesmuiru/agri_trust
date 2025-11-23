import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  
  // Standard short notification sound
  static const String _soundUrl = "https://codeskulptor-demos.commondatastorage.googleapis.com/pang/pop.mp3";

  static Future<void> playNotification() async {
    try {
      await _player.play(UrlSource(_soundUrl));
    } catch (e) {
      print("Error playing sound: $e");
    }
  }
}