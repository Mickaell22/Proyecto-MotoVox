import 'dart:async';
import 'package:flutter/material.dart';
import '../services/audio_relay_service.dart';
import '../services/room_discovery_service.dart';
import 'connected_screen.dart';
import 'qr_screen.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final _discovery = RoomDiscoveryService();
  List<RoomInfo> _rooms = [];
  StreamSubscription<List<RoomInfo>>? _sub;
  String? _connectingId;

  @override
  void initState() {
    super.initState();
    _sub = _discovery.startDiscovery().listen((rooms) {
      if (mounted) setState(() => _rooms = rooms);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _discovery.stopDiscovery();
    super.dispose();
  }

  Future<void> _connectTo(RoomInfo room) async {
    if (_connectingId != null) return;
    setState(() => _connectingId = room.id);

    final audio = AudioRelayService();
    await audio.init();
    final ok = await audio.connectToHost(room.ip, port: room.port);

    if (!mounted) return;

    if (ok) {
      _sub?.cancel();
      _discovery.stopDiscovery();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ConnectedScreen(audio: audio)),
      );
    } else {
      await audio.dispose();
      if (!mounted) return;
      setState(() => _connectingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo conectar a ${room.name}')),
      );
    }
  }

  void _goToQrScan() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QrScreen(isHost: false)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SALAS DISPONIBLES')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _rooms.isEmpty
                    ? const _SearchingPlaceholder()
                    : _RoomsList(
                        rooms: _rooms,
                        connectingId: _connectingId,
                        onTap: _connectTo,
                      ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _goToQrScan,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('ESCANEAR QR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchingPlaceholder extends StatelessWidget {
  const _SearchingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        Text(
          'Buscando salas...',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Asegúrate de estar en la misma red que el piloto',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _RoomsList extends StatelessWidget {
  final List<RoomInfo> rooms;
  final String? connectingId;
  final void Function(RoomInfo) onTap;

  const _RoomsList({
    required this.rooms,
    required this.connectingId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${rooms.length} sala${rooms.length > 1 ? 's' : ''} encontrada${rooms.length > 1 ? 's' : ''}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final room = rooms[i];
              final isConnecting = connectingId == room.id;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.headset_mic),
                  title: Text(room.name),
                  subtitle: Text(room.ip),
                  trailing: isConnecting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: connectingId == null ? () => onTap(room) : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
