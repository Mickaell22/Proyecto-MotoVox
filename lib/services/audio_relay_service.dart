import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';

class AudioRelayService {
  static const int _sampleRate = 16000;
  static const int _numChannels = 1;
  static const int _bufferSize = 4096;

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

    // AudioSource.voice_communication = VOICE_COMMUNICATION
    // Activa AEC + supresión de ruido por hardware (DSP del dispositivo Android).
    _recorderStream = StreamController<Uint8List>();
    _recorderStream!.stream.listen((data) {
      if (!_muted) {
        try { socket.add(data); } catch (_) {}
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
