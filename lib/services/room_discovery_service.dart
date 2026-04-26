import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

class RoomInfo {
  final String id;
  final String name;
  final String ip;
  final int port;
  final DateTime lastSeen;

  const RoomInfo({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
    required this.lastSeen,
  });

  RoomInfo refreshed() => RoomInfo(
        id: id,
        name: name,
        ip: ip,
        port: port,
        lastSeen: DateTime.now(),
      );
}

class RoomDiscoveryService {
  static const int discoveryPort = 8767;
  static const _broadcastInterval = Duration(seconds: 2);
  static const _roomExpiry = Duration(seconds: 7);

  RawDatagramSocket? _advSocket;
  RawDatagramSocket? _discSocket;
  Timer? _broadcastTimer;
  Timer? _expiryTimer;
  StreamController<List<RoomInfo>>? _controller;
  final _rooms = <String, RoomInfo>{};

  static String generateId() =>
      Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');

  Future<void> startAdvertising({
    required String id,
    required String name,
    required String ip,
    required int port,
  }) async {
    _advSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _advSocket!.broadcastEnabled = true;

    final data = utf8.encode(
      jsonEncode({'id': id, 'name': name, 'ip': ip, 'port': port}),
    );

    void send() {
      try {
        _advSocket?.send(
            data, InternetAddress('255.255.255.255'), discoveryPort);
      } catch (_) {}
    }

    send();
    _broadcastTimer = Timer.periodic(_broadcastInterval, (_) => send());
  }

  Stream<List<RoomInfo>> startDiscovery() {
    _rooms.clear();
    _controller = StreamController<List<RoomInfo>>.broadcast();

    RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort)
        .then((socket) {
      _discSocket = socket;
      socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final dg = socket.receive();
        if (dg == null) return;
        try {
          final payload =
              jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
          final room = RoomInfo(
            id: payload['id'] as String,
            name: payload['name'] as String,
            ip: payload['ip'] as String,
            port: payload['port'] as int,
            lastSeen: DateTime.now(),
          );
          _rooms[room.id] = room;
          _emit();
        } catch (_) {}
      });
    }).catchError((_) {});

    _expiryTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final before = _rooms.length;
      _rooms.removeWhere((_, r) =>
          DateTime.now().difference(r.lastSeen) > _roomExpiry);
      if (_rooms.length != before) _emit();
    });

    return _controller!.stream;
  }

  void _emit() {
    if (!(_controller?.isClosed ?? true)) {
      _controller!.add(List.unmodifiable(_rooms.values.toList()));
    }
  }

  void stopAdvertising() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _advSocket?.close();
    _advSocket = null;
  }

  void stopDiscovery() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _discSocket?.close();
    _discSocket = null;
    _controller?.close();
    _controller = null;
    _rooms.clear();
  }

  void dispose() {
    stopAdvertising();
    stopDiscovery();
  }
}
