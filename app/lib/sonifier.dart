import 'song.dart';

class Sonifier {
  final Song song = Song();
  double risk = 0;

  Future<void> init() async {
    await song.init();
    _play();
  }

  void _play() async {
    song.play();
    while (true) {
      song.risk = risk;
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
