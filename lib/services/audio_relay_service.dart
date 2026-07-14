import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'rnnoise_processor.dart';

class AudioRelayService {
  static const int _sampleRate = 16000;
  static const int _numChannels = 1;
  static const int _bufferSize = 4096;

  final _rnnoise = RnnoiseProcessor();

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
    try {
      _rnnoise.init();
    } catch (_) {
      // La app sigue funcionando sin supresión de ruido si la .so no carga.
    }
  }

  Future<void> startHost() async {
    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    _actualPort = _serverSocket!.port;
    _serverSocket!.listen(
      (socket) async {
        // ponytail: scope 1-a-1 — se rechaza una segunda conexión mientras
        // hay una activa. Upgrade: multi-cliente para grupos de motos.
        if (_socket != null) {
          socket.destroy();
          return;
        }
        socket.setOption(SocketOption.tcpNoDelay, true);
        _socket = socket;
        await _startAudio(socket);
      },
      onError: (_) {},
    );
  }

  Future<bool> connectToHost(String hostIp, {required int port}) async {
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
        try { socket.add(_rnnoise.process(data)); } catch (_) {}
      }
    });

    await _recorder.startRecorder(
      toStream: _recorderStream!.sink,
      codec: Codec.pcm16,
      numChannels: _numChannels,
      sampleRate: _sampleRate,
      bufferSize: _bufferSize,
      audioSource: AudioSource.voice_communication,
      // enableVoiceProcessing y enableNoiseSuppression desactivados:
      // el hardware pre-procesa el audio y RNNoise no puede distinguir voz
      // de ruido → silencia todo después de ~5 segundos.
      // Sólo AEC se mantiene, es esencial para llamadas bidireccionales.
      enableVoiceProcessing: false,
      enableNoiseSuppression: false,
      enableEchoCancellation: true,
    );

    if (!_stateController.isClosed) _stateController.add(true);
  }

  void _onDisconnected() {
    if (!_stateController.isClosed) _stateController.add(false);
    _recorder.stopRecorder().catchError((_) => null);
    _player.stopPlayer().catchError((_) => null);
    _recorderStream?.close();
    _recorderStream = null;
    // Libera el slot para que el mismo copiloto pueda reconectarse al host.
    _socket = null;
  }

  void setMuted(bool mute) {
    _muted = mute;
    if (mute) {
      _recorder.pauseRecorder().catchError((_) => null);
    } else {
      _recorder.resumeRecorder().catchError((_) => null);
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
    _rnnoise.dispose();
    if (!_stateController.isClosed) await _stateController.close();
  }
}
