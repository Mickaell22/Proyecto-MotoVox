import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';

// Second-order IIR biquad filter (Audio EQ Cookbook, Butterworth Q=0.7071).
class _BiquadFilter {
  final double b0, b1, b2, a1, a2;
  double _x1 = 0, _x2 = 0, _y1 = 0, _y2 = 0;

  _BiquadFilter({
    required this.b0, required this.b1, required this.b2,
    required this.a1, required this.a2,
  });

  // High-pass at 300 Hz, fs=16000 Hz — removes low-frequency motor rumble.
  factory _BiquadFilter.hpf300() => _BiquadFilter(
    b0: 0.920038, b1: -1.840076, b2: 0.920038,
    a1: -1.834267, a2: 0.846570,
  );

  // Low-pass at 3400 Hz, fs=16000 Hz — removes high-frequency wind/hiss.
  factory _BiquadFilter.lpf3400() => _BiquadFilter(
    b0: 0.226818, b1: 0.453636, b2: 0.226818,
    a1: -0.278024, a2: 0.185356,
  );

  double process(double x) {
    final y = b0 * x + b1 * _x1 + b2 * _x2 - a1 * _y1 - a2 * _y2;
    _x2 = _x1; _x1 = x;
    _y2 = _y1; _y1 = y;
    return y;
  }
}

class AudioRelayService {
  static const int _sampleRate = 16000;
  static const int _numChannels = 1;
  static const int _bufferSize = 4096;

  // Bandpass 300 Hz–3400 Hz: keeps only the human voice band.
  final _hpf = _BiquadFilter.hpf300();
  final _lpf = _BiquadFilter.lpf3400();

  final _recorder = FlutterSoundRecorder();
  final _player = FlutterSoundPlayer();

  ServerSocket? _serverSocket;
  Socket? _socket;
  StreamController<Uint8List>? _recorderStream;
  bool _muted = false;

  int _actualPort = 0;
  int get actualPort => _actualPort;

  final _stateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionState => _stateController.stream;

  Future<void> init() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
  }

  Future<void> startHost() async {
    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    _actualPort = _serverSocket!.port;
    _serverSocket!.listen(
      (socket) async {
        socket.setOption(SocketOption.tcpNoDelay, true);
        _socket = socket;
        await _startAudio(socket);
      },
      onError: (_) {},
    );
  }

  Future<bool> connectToHost(String hostIp, {int port = 8766}) async {
    try {
      final socket = await Socket.connect(
        hostIp, port,
        timeout: const Duration(seconds: 15),
      );
      socket.setOption(SocketOption.tcpNoDelay, true);
      _socket = socket;
      await _startAudio(socket);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _startAudio(Socket socket) async {
    await _player.startPlayerFromStream(
      codec: Codec.pcm16,
      interleaved: false,
      numChannels: _numChannels,
      sampleRate: _sampleRate,
      bufferSize: _bufferSize,
    );

    socket.listen(
      (data) {
        try { _player.uint8ListSink?.add(data); } catch (_) {}
      },
      onDone: _onDisconnected,
      onError: (_) => _onDisconnected(),
      cancelOnError: true,
    );

    _recorderStream = StreamController<Uint8List>();
    _recorderStream!.stream.listen((data) {
      if (!_muted) {
        try { socket.add(_applyVoiceFilter(data)); } catch (_) {}
      }
    });

    await _recorder.startRecorder(
      toStream: _recorderStream!.sink,
      codec: Codec.pcm16,
      numChannels: _numChannels,
      sampleRate: _sampleRate,
      bufferSize: _bufferSize,
      audioSource: AudioSource.voice_communication,
      enableVoiceProcessing: true,
      enableNoiseSuppression: true,
      enableEchoCancellation: true,
    );

    if (!_stateController.isClosed) _stateController.add(true);
  }

  // Applies bandpass (300 Hz–3400 Hz) to a PCM16 LE buffer.
  Uint8List _applyVoiceFilter(Uint8List data) {
    final samples = data.length ~/ 2;
    final input = ByteData.sublistView(data);
    final out = Uint8List(samples * 2);
    final output = ByteData.sublistView(out);
    for (int i = 0; i < samples; i++) {
      final x = input.getInt16(i * 2, Endian.little).toDouble();
      final y = _lpf.process(_hpf.process(x));
      output.setInt16(i * 2, y.clamp(-32768.0, 32767.0).round(), Endian.little);
    }
    return out;
  }

  void _onDisconnected() {
    if (!_stateController.isClosed) _stateController.add(false);
  }

  void setMuted(bool mute) {
    _muted = mute;
    if (mute) {
      _recorder.pauseRecorder();
    } else {
      _recorder.resumeRecorder();
    }
  }

  Future<void> dispose() async {
    try { await _recorder.stopRecorder(); } catch (_) {}
    try { await _recorder.closeRecorder(); } catch (_) {}
    try { await _player.stopPlayer(); } catch (_) {}
    try { await _player.closePlayer(); } catch (_) {}
    try { await _recorderStream?.close(); } catch (_) {}
    try { await _serverSocket?.close(); } catch (_) {}
    try { await _socket?.close(); } catch (_) {}
    if (!_stateController.isClosed) await _stateController.close();
  }
}
