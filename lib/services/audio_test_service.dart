import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'rnnoise_processor.dart';

enum AudioTestState { idle, recording, playing, done }

class AudioTestService {
  final _recorder = FlutterSoundRecorder();
  final _player = FlutterSoundPlayer();

  AudioTestState _state = AudioTestState.idle;
  AudioTestState get state => _state;

  final _stateController = StreamController<AudioTestState>.broadcast();
  Stream<AudioTestState> get onStateChanged => _stateController.stream;

  Future<void> init() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
  }

  Future<void> startRecording() async {
    _state = AudioTestState.recording;
    _stateController.add(_state);
    await _recorder.startRecorder(
      toFile: 'motovox_test_raw.wav',
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
    final rawPath = await _recorder.stopRecorder();
    if (rawPath == null) return;

    _state = AudioTestState.playing;
    _stateController.add(_state);

    // Process the recorded WAV through RNNoise and play the clean version.
    String playPath = rawPath;
    try {
      final rawBytes = await File(rawPath).readAsBytes();
      const headerSize = 44;
      if (rawBytes.length > headerSize) {
        final pcm = Uint8List.sublistView(rawBytes, headerSize);
        final rnnoise = RnnoiseProcessor()..init();
        final processed = rnnoise.process(pcm);
        rnnoise.dispose();

        final processedPath = rawPath.replaceFirst('_raw.wav', '_clean.wav');
        await File(processedPath).writeAsBytes(_buildWav(processed));
        playPath = processedPath;
      }
    } catch (_) {}

    await _player.startPlayer(
      fromURI: playPath,
      codec: Codec.pcm16WAV,
      whenFinished: () {
        _state = AudioTestState.done;
        if (!_stateController.isClosed) _stateController.add(_state);
      },
    );
  }

  // Builds a minimal PCM WAV file from raw PCM16 LE mono 16 kHz bytes.
  Uint8List _buildWav(Uint8List pcm) {
    const sampleRate = 16000;
    const channels = 1;
    const bitsPerSample = 16;
    final dataLen = pcm.length;
    final header = ByteData(44);

    void setStr(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        header.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    setStr(0, 'RIFF');
    header.setUint32(4, 36 + dataLen, Endian.little);
    setStr(8, 'WAVE');
    setStr(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * channels * bitsPerSample ~/ 8, Endian.little);
    header.setUint16(32, channels * bitsPerSample ~/ 8, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    setStr(36, 'data');
    header.setUint32(40, dataLen, Endian.little);

    final result = Uint8List(44 + dataLen);
    result.setRange(0, 44, header.buffer.asUint8List());
    result.setRange(44, 44 + dataLen, pcm);
    return result;
  }

  Future<void> reset() async {
    try { await _recorder.stopRecorder(); } catch (_) {}
    try { await _player.stopPlayer(); } catch (_) {}
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
