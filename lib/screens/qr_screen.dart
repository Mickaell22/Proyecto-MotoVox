import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/signaling_service.dart';
import '../services/webrtc_service.dart';
import 'connected_screen.dart';

class QrScreen extends StatefulWidget {
  final bool isHost;
  const QrScreen({super.key, required this.isHost});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  String? _qrData;
  String? _statusMsg;
  bool _connecting = false;
  bool _scanned = false;

  final _signalingServer = SignalingServer();
  WebRtcService? _webrtc;

  @override
  void initState() {
    super.initState();
    if (widget.isHost) _startHost();
  }

  Future<void> _startHost() async {
    setState(() => _statusMsg = 'Iniciando...');

    await _signalingServer.start();

    final ip = await NetworkInfo().getWifiIP();
    if (ip == null) {
      setState(() => _statusMsg = 'No se pudo obtener IP WiFi.\nActiva el hotspot e intenta de nuevo.');
      return;
    }

    final service = WebRtcService.host(signalingServer: _signalingServer);
    _webrtc = service;
    await service.init();
    await service.createOffer();

    final payload = jsonEncode({'ip': ip, 'port': SignalingServer.port});
    setState(() {
      _qrData = payload;
      _statusMsg = 'Muestra este QR al copiloto';
    });

    _waitForClient();
  }

  Future<void> _waitForClient() async {
    setState(() => _statusMsg = 'Esperando que el copiloto escanee...');
    final ok = await _webrtc!.waitForAnswer();
    if (!mounted) return;
    if (ok) {
      _goToConnected();
    } else {
      setState(() => _statusMsg = 'Tiempo agotado. Vuelve a intentar.');
    }
  }

  Future<void> _onQrDetected(BarcodeCapture capture) async {
    if (_scanned || _connecting) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final ip = payload['ip'] as String?;
    final port = payload['port'] as int?;
    if (ip == null || port == null) return;

    setState(() {
      _scanned = true;
      _connecting = true;
      _statusMsg = 'Conectando con $ip...';
    });

    final sigClient = SignalingClient(hostIp: ip, hostPort: port);
    final service = WebRtcService.client(signalingClient: sigClient);
    _webrtc = service;

    await service.init();
    final ok = await service.connectToHost();

    if (!mounted) return;
    if (ok) {
      _goToConnected();
    } else {
      setState(() {
        _scanned = false;
        _connecting = false;
        _statusMsg = 'No se pudo conectar. Intenta de nuevo.';
      });
    }
  }

  void _goToConnected() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ConnectedScreen(webrtc: _webrtc!),
      ),
    );
  }

  @override
  void dispose() {
    if (_webrtc == null) {
      _signalingServer.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isHost ? 'CREAR SALA' : 'UNIRSE'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: widget.isHost ? _buildHost() : _buildClient(),
        ),
      ),
    );
  }

  Widget _buildHost() {
    if (_qrData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_statusMsg ?? '', textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _statusMsg ?? '',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const Spacer(),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: _qrData!,
              size: 260,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const Spacer(),
        if (_connecting)
          const Center(child: CircularProgressIndicator())
        else
          Text(
            _statusMsg ?? '',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
      ],
    );
  }

  Widget _buildClient() {
    if (_connecting) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_statusMsg ?? '', textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _statusMsg ?? 'Apunta la camara al QR del piloto',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: MobileScanner(
              onDetect: _onQrDetected,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_statusMsg != null && !_connecting)
          Text(
            _statusMsg!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
      ],
    );
  }
}
