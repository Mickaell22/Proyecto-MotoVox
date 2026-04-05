import 'dart:convert';
import 'dart:io';

// Corre en el telefono host — sirve la oferta WebRTC y recibe la respuesta
class SignalingServer {
  static const int port = 8765;

  HttpServer? _server;
  String? _offer;
  String? _answer;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.listen(_handleRequest);
  }

  void setOffer(String offer) {
    _offer = offer;
  }

  String? getAnswer() => _answer;

  void _handleRequest(HttpRequest req) async {
    req.response.headers.add('Access-Control-Allow-Origin', '*');
    req.response.headers.contentType = ContentType.json;

    if (req.method == 'GET' && req.uri.path == '/offer') {
      if (_offer == null) {
        req.response.statusCode = 503;
        req.response.write(jsonEncode({'error': 'offer not ready'}));
      } else {
        req.response.write(_offer);
      }
    } else if (req.method == 'POST' && req.uri.path == '/answer') {
      final body = await utf8.decoder.bind(req).join();
      _answer = body;
      req.response.write(jsonEncode({'ok': true}));
    } else {
      req.response.statusCode = 404;
      req.response.write(jsonEncode({'error': 'not found'}));
    }

    await req.response.close();
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _offer = null;
    _answer = null;
  }
}

// Corre en el telefono cliente — se conecta al host para intercambiar SDP
class SignalingClient {
  final String hostIp;
  final int hostPort;

  SignalingClient({required this.hostIp, required this.hostPort});

  String get _base => 'http://$hostIp:$hostPort';

  Future<String?> fetchOffer() async {
    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse('$_base/offer'));
      final res = await req.close();
      if (res.statusCode != 200) return null;
      return await utf8.decoder.bind(res).join();
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  Future<bool> sendAnswer(String answer) async {
    final client = HttpClient();
    try {
      final req = await client.postUrl(Uri.parse('$_base/answer'));
      req.headers.contentType = ContentType.json;
      req.write(answer);
      final res = await req.close();
      await res.drain();
      return res.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }
}
