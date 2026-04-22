import 'dart:io';
import 'package:flutter/services.dart';

class ApkShareService {
  static const _channel = MethodChannel('com.motovox.motovox/app');
  static const int port = 9876;

  HttpServer? _server;
  String? _apkPath;
  String? _shareUrl;

  String? get shareUrl => _shareUrl;

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

  Future<bool> start() async {
    try {
      _apkPath = await _channel.invokeMethod<String>('getApkPath');
      if (_apkPath == null) return false;

      final ip = await _getLocalIp();
      if (ip == null) return false;

      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _shareUrl = 'http://$ip:$port/motovox.apk';

      _server!.listen(_handleRequest);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _handleRequest(HttpRequest req) async {
    if (req.method == 'GET' && req.uri.path == '/motovox.apk') {
      final file = File(_apkPath!);
      if (!await file.exists()) {
        req.response.statusCode = 404;
        await req.response.close();
        return;
      }
      req.response.headers.contentType =
          ContentType('application', 'vnd.android.package-archive');
      req.response.headers.set(
          'Content-Disposition', 'attachment; filename="motovox.apk"');
      req.response.headers.set('Content-Length', await file.length());
      await req.response.addStream(file.openRead());
    } else {
      req.response.statusCode = 404;
    }
    await req.response.close();
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _shareUrl = null;
  }
}
