import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'signaling_service.dart';

enum WebRtcRole { host, client }

class WebRtcService {
  final WebRtcRole role;
  final SignalingServer? server;
  final SignalingClient? client;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  bool _muted = false;

  bool get isMuted => _muted;

  final _connectionStateController = StreamController<RTCPeerConnectionState>.broadcast();
  Stream<RTCPeerConnectionState> get connectionState => _connectionStateController.stream;

  void setMuted(bool mute) {
    _muted = mute;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !mute;
    });
  }

  WebRtcService.host({required SignalingServer signalingServer})
      : role = WebRtcRole.host,
        server = signalingServer,
        client = null;

  WebRtcService.client({required SignalingClient signalingClient})
      : role = WebRtcRole.client,
        server = null,
        client = signalingClient;

  // Sin STUN externo — la app funciona sobre hotspot local sin internet.
  // WebRTC usa host candidates (IPs locales) que son suficientes en la misma red.
  static const _iceServers = {
    'iceServers': <Map<String, dynamic>>[],
  };

  static const _constraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  Future<void> init() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    });

    _pc = await createPeerConnection(_iceServers, _constraints);

    for (final track in _localStream!.getAudioTracks()) {
      await _pc!.addTrack(track, _localStream!);
    }

    _pc!.onConnectionState = (state) {
      _connectionStateController.add(state);
    };
  }

  // Llamar solo si role == host
  Future<String> createOffer() async {
    assert(role == WebRtcRole.host);

    final offer = await _pc!.createOffer({'offerToReceiveAudio': true});
    await _pc!.setLocalDescription(offer);

    // Esperar a que ICE gathering termine para mandar oferta completa
    await _waitForIceGathering();

    final localDesc = await _pc!.getLocalDescription();
    final offerJson = jsonEncode({
      'type': localDesc!.type,
      'sdp': localDesc.sdp,
    });

    server!.setOffer(offerJson);
    return offerJson;
  }

  // Espera que el cliente envie su respuesta (polling)
  Future<bool> waitForAnswer({Duration timeout = const Duration(seconds: 30)}) async {
    assert(role == WebRtcRole.host);
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      final answer = server!.getAnswer();
      if (answer != null) {
        final map = jsonDecode(answer) as Map<String, dynamic>;
        await _pc!.setRemoteDescription(
          RTCSessionDescription(map['sdp'] as String, map['type'] as String),
        );
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  // Llamar solo si role == client
  Future<bool> connectToHost() async {
    assert(role == WebRtcRole.client);

    // Reintentar fetch de oferta hasta 10 segundos
    String? offerJson;
    for (int i = 0; i < 20; i++) {
      offerJson = await client!.fetchOffer();
      if (offerJson != null) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (offerJson == null) return false;

    final map = jsonDecode(offerJson) as Map<String, dynamic>;
    await _pc!.setRemoteDescription(
      RTCSessionDescription(map['sdp'] as String, map['type'] as String),
    );

    final answer = await _pc!.createAnswer({'offerToReceiveAudio': true});
    await _pc!.setLocalDescription(answer);
    await _waitForIceGathering();

    final localDesc = await _pc!.getLocalDescription();
    final answerJson = jsonEncode({
      'type': localDesc!.type,
      'sdp': localDesc.sdp,
    });

    return client!.sendAnswer(answerJson);
  }

  Future<void> _waitForIceGathering() async {
    if (_pc!.iceGatheringState == RTCIceGatheringState.RTCIceGatheringStateComplete) {
      return;
    }
    final completer = Completer<void>();
    _pc!.onIceGatheringState = (state) {
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        if (!completer.isCompleted) completer.complete();
      }
    };
    await completer.future.timeout(const Duration(seconds: 10), onTimeout: () {});
  }

  Future<void> dispose() async {
    await _localStream?.dispose();
    await _pc?.close();
    await _connectionStateController.close();
  }
}
