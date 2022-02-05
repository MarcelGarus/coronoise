// ignore_for_file: annotate_overrides

import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

final cache = AudioCache(prefix: 'assets/');

typedef Beat = int;

class Song {
  final parts = [
    ConstantPianoBlimp(),
    PianoMelody(),
    DuDuDuDuDuDuDuDuBass(),
    // MediumMelody(),
    DissonantPiano(),
    OrganBass(),
    WindBass(),
    PianoChordAccent(),
    SubwooferBass(),
    GuqinImprovisation(),
    HorrorEffects(),
  ];

  Beat now = 0;
  double risk = 0.0;

  Future<void> init() async {
    await Future.wait([for (final part in parts) part.init()]);
  }

  void play() async {
    Timer.periodic(const Duration(milliseconds: 937, microseconds: 500), (_) {
      print('Beat: $now');
      for (final part in parts) {
        part.tick(this);
      }
      now++;
    });
  }
}

abstract class SongPart {
  Future<void> init();
  void tick(Song song);
}

class LoopingAudioPlayer {
  LoopingAudioPlayer(this.file);

  final String file;
  AudioPlayer? _player;
  var lastRestart = -1000;
  double _volume = 0;
  double get volume => _volume;
  set volume(double value) {
    _volume = value;
    _player?.setVolume(_volume);
  }

  void tick(Song song) {
    if (song.now.beatsSince(lastRestart) >= 32) {
      lastRestart = song.now;
      cache.play(file, volume: volume).then((player) {
        final previousPlayer = _player;
        Future<void>.delayed(const Duration(seconds: 1), () {
          previousPlayer?.stop();
        });
        _player = player;
      });
    }
  }
}

class ConstantPianoBlimp implements SongPart {
  static const file = 'light-accent-loop.mp3';
  final player = LoopingAudioPlayer(file);

  @override
  Future<void> init() => cache.fetchToMemory(file);

  @override
  void tick(Song song) {
    player.tick(song);
    player.volume = (song.risk / 20).clamp(0, 1);
  }
}

class PianoMelody implements SongPart {
  static const file = 'light-beat-loop.mp3';
  final player = LoopingAudioPlayer(file);

  @override
  Future<void> init() => cache.fetchToMemory(file);

  @override
  void tick(Song song) {
    player.tick(song);
    if (song.risk >= 20 && song.now.beatsSince(player.lastRestart) % 8 == 0) {
      if (player.volume == 0) print('Starting piano melody.');
      player.volume = 1;
    }
    if (song.risk < 20 && song.now.beatsSince(player.lastRestart) % 8 == 1) {
      if (player.volume == 1) print('Stopping piano melody.');
      player.volume = 0;
    }
  }
}

class DuDuDuDuDuDuDuDuBass implements SongPart {
  static const file = 'light-bass.mp3';
  final player = LoopingAudioPlayer(file);

  @override
  Future<void> init() => cache.fetchToMemory(file);

  @override
  void tick(Song song) {
    player.tick(song);
    if (song.now.beatsSince(player.lastRestart) % 8 == 0) {
      final newVolume = song.risk >= 25 ? 1.0 : 0.0;
      if (player.volume != newVolume) {
        print(
            '${newVolume == 1 ? 'Starting' : 'Stopping'} the du du du du du du du du bass.');
      }
      player.volume = newVolume;
    }
  }
}

class DissonantPiano implements SongPart {
  static const file = 'medium-accent.mp3';
  final player = LoopingAudioPlayer(file);

  @override
  Future<void> init() => cache.fetchToMemory(file);

  @override
  void tick(Song song) {
    player.tick(song);
    if (song.now.beatsSince(player.lastRestart) % 4 == 0) {
      final newVolume = song.risk >= 40 ? 1.0 : 0.0;
      if (player.volume != newVolume) {
        print(
            '${newVolume == 1 ? 'Starting' : 'Stopping'} the dissonant piano.');
      }
      player.volume = newVolume;
    }
  }
}

class OrganBass implements SongPart {
  static const file = 'medium-bass.mp3';
  final player = LoopingAudioPlayer(file);

  @override
  Future<void> init() => cache.fetchToMemory(file);

  @override
  void tick(Song song) {
    player.tick(song);
    if (song.risk >= 50 && song.now.beatsSince(player.lastRestart) % 8 == 0) {
      if (player.volume == 0) print('Starting the organ bass.');
      player.volume = 1;
    }
    if (song.risk < 50) {
      if (player.volume < 0.01) {
        player.volume = 0;
      } else {
        print('Fading out the organ bass.');
        player.volume = player.volume * 0.9;
      }
    }
  }
}

class WindBass implements SongPart {
  static const file = 'medium-bass-windy.mp3';
  final player = LoopingAudioPlayer(file);

  @override
  Future<void> init() => cache.fetchToMemory(file);

  @override
  void tick(Song song) {
    player.tick(song);
    if (song.risk >= 60 && song.now.beatsSince(player.lastRestart) % 8 == 0) {
      if (player.volume == 0) print('Starting the wind bass.');
      player.volume = 1;
    }
    if (song.risk < 60) {
      if (player.volume < 0.01) {
        player.volume = 0;
      } else {
        print('Fading out the wind bass.');
        player.volume = player.volume * 0.9;
      }
    }
  }
}

class PianoChordAccent implements SongPart {
  static const file = 'heavy-accent.mp3';
  final player = LoopingAudioPlayer(file);

  @override
  Future<void> init() => cache.fetchToMemory(file);

  @override
  void tick(Song song) {
    player.tick(song);
    if (song.risk >= 70 && song.now.beatsSince(player.lastRestart) % 8 == 0) {
      if (player.volume == 0) print('Starting the piano chord accents.');
      player.volume = 1;
    }
    if (song.risk < 70) {
      if (player.volume < 0.01) {
        player.volume = 0;
      } else {
        print('Fading out the piano chord accents.');
        player.volume = player.volume * 0.9;
      }
    }
  }
}

class SubwooferBass implements SongPart {
  static const file = 'heavy-bass-loop.mp3';
  final player = LoopingAudioPlayer(file);

  @override
  Future<void> init() => cache.fetchToMemory(file);

  @override
  void tick(Song song) {
    player.tick(song);
    if (song.risk >= 80 && song.now.beatsSince(player.lastRestart) % 8 == 0) {
      if (player.volume == 0) print('Starting the subwoofer bass.');
      player.volume = 1;
    }
    if (song.risk < 80 && song.now.beatsSince(player.lastRestart) % 8 == 1) {
      if (player.volume == 1) print('Stopping the subwoofer bass.');
      player.volume = 0;
    }
  }
}

class GuqinImprovisation implements SongPart {
  static const file = 'heavy-noise.mp3';
  final player = LoopingAudioPlayer(file);

  @override
  Future<void> init() => cache.fetchToMemory(file);

  @override
  void tick(Song song) {
    player.tick(song);
    if (song.now.beatsSince(player.lastRestart) % 4 == 0) {
      final newVolume = song.risk >= 90 ? 1.0 : 0.0;
      if (player.volume != newVolume) {
        print('${newVolume == 1 ? 'Starting' : 'Stopping'} the guqin.');
      }
      player.volume = newVolume;
    }
  }
}

class HorrorEffects implements SongPart {
  static final files = [for (var i = 1; i <= 3; i++) 'horror-$i.mp3'];
  Beat lastPlayed = -1000;

  @override
  Future<void> init() {
    return Future.wait([
      for (final file in files) cache.fetchToMemory(file),
    ]);
  }

  @override
  void tick(Song song) {
    if (song.risk >= 100 && song.now.beatsSince(lastPlayed) > 10) {
      if (Random().nextDouble() < 0.1) {
        print('Adding a horror effect.');
        lastPlayed = song.now;
        cache.play(files[Random().nextInt(files.length)]);
      }
    }
  }
}

extension on Beat {
  Beat beatsSince(Beat other) => this - other;
}
