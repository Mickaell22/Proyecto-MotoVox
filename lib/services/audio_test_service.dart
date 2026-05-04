import 'dart:async';
import 'package:flutter_sound/flutter_sound.dart';

enum AudioTestState { idle, recording, playing, done }

class AudioTestService {
  final _recorder = FlutterSoundRecorder();
  final _player = FlutterSoundPlayer();

  String? _filePath;
  AudioTestState _state = AudioTestState.idle;
  AudioTestState get state => _state;

  final _stateController = StreamController<AudioTestState>.broadcast();
  Stream<AudioTestState> get onStateChanged => _stateController.stream;

  Future<void> init() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
  }

  Future<void> startRecording() async {
    _filePath = null;
    _state = AudioTestState.recording;
    _stateController.add(_state);
    await _recorder.startRecorder(
      toFile: 'motovox_test.wav',
      codec: Codec.pcm16WAV,
      numChannels: 1,
      sampleRate: 16000,
      audioSource: AudioSource.voice_communication,
      enableVoiceProcessing: true,
      enableNoiseSuppression: true,
      enableEchoCancellation: true,
    );
  }

  Future<void> stopRecordingAndPlay() async {
    _filePath = await _recorder.stopRecorder();
    if (_filePath == null) return;

    _state = AudioTestState.playing;
    _stateController.add(_state);

    await _player.startPlayer(
      fromURI: _filePath,
      codec: Codec.pcm16WAV,
      whenFinished: () {
        _state = AudioTestState.done;
        if (!_stateController.isClosed) _stateController.add(_state);
      },
    );
  }

  Future<void> reset() async {
    try { await _recorder.stopRecorder(); } catch (_) {}
    try { await _player.stopPlayer(); } catch (_) {}
    _filePath = null;
    _state = AudioTestState.idle;
    if (!_stateController.isClosed) _stateController.add(_state);
  }

  Future<void> dispose() async {
    try { await _recorder.stopRecorder(); } catch (_) {}
    try { await _recorder.closeRecorder(); } catch (_) {}
    try { await _player.stopPlayer(); } catch (_) {}
    try { await _player.closePlayer(); } catch (_) {}
    if (!_stateController.isClosed) await _stateController.close();
  }
}
