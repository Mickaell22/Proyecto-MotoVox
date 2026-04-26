import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/audio_relay_service.dart';
import '../services/room_discovery_service.dart';
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
  bool _navigatedToConnected = false;

  AudioRelayService? _audioService;
  final _discovery = RoomDiscoveryService();
  String? _roomId;

  @override
  void initState() {
    super.initState();
    if (widget.isHost) _startHost();
  }

  Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      String? fallback;
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (ip.startsWith('192.168.43.')) return ip;
          if (ip.startsWith('192.168.') || ip.startsWith('10.')) fallback = ip;
        }
      }
      return fallback;
    } catch (_) {
      return null;
    }
  }

  Future<void> _startHost() async {
    try {
      setState(() => _statusMsg = 'Buscando red...');

      final ip = await _getLocalIp();
      if (ip == null) {
        setState(() => _statusMsg = 'Sin red WiFi o hotspot.\nActiva el hotspot e intenta de nuevo.');
        return;
      }

      setState(() => _statusMsg = 'Iniciando micrófono...');
      _audioService = AudioRelayService();
      await _audioService!.init().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout al iniciar micrófono'),
      );

      await _audioService!.startHost();
      final audioPort = _audioService!.actualPort;

      _roomId = RoomDiscoveryService.generateId();
      await _discovery.startAdvertising(
        id: _roomId!,
        name: 'MotoVox',
        ip: ip,
        port: audioPort,
      );

      if (!mounted) return;
      setState(() {
        _qrData = jsonEncode({'ip': ip, 'port': audioPort});
        _statusMsg = 'Sala activa — esperando al copiloto';
      });

      _audioService!.connectionState.firstWhere((c) => c).then((_) {
        if (mounted && !_navigatedToConnected) _goToConnected();
      });
    } catch (e) {
      if (mounted) setState(() => _statusMsg = 'Error: $e\n\nVuelve e intenta de nuevo.');
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

    try {
      _audioService = AudioRelayService();
      await _audioService!.init();
      final ok = await _audioService!.connectToHost(ip, port: port);

      if (!mounted) return;
      if (ok) {
        _goToConnected();
      } else {
        setState(() {
          _scanned = false;
          _connecting = false;
          _statusMsg = 'No se pudo conectar. Intenta de nuevo.';
        });
        await _audioService?.dispose();
        _audioService = null;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanned = false;
        _connecting = false;
        _statusMsg = 'Error: $e';
      });
    }
  }

  void _goToConnected() {
    _discovery.stopAdvertising();
    _navigatedToConnected = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ConnectedScreen(audio: _audioService!),
      ),
    );
  }

  @override
  void dispose() {
    if (!_navigatedToConnected) {
      _audioService?.dispose();
      _discovery.stopAdvertising();
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
            if (_statusMsg != null && _statusMsg!.startsWith('Error'))
              Text(_statusMsg!, textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.redAccent))
            else ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(_statusMsg ?? '', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge),
            ],
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
        Text(
          'Esperando al copiloto...',
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
          _statusMsg ?? 'Apunta la cámara al QR del piloto',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: MobileScanner(onDetect: _onQrDetected),
          ),
        ),
        if (_statusMsg != null && !_connecting) ...[
          const SizedBox(height: 16),
          Text(
            _statusMsg!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ],
    );
  }
}
