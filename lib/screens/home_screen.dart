import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/license_service.dart';
import '../services/apk_share_service.dart';
import 'qr_screen.dart';
import 'rooms_screen.dart';
import 'expired_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _daysRemaining = LicenseService.trialDays;
  bool _unlocked = false;
  int _logoTapCount = 0;

  @override
  void initState() {
    super.initState();
    _checkLicense();
    _requestPermissions();
  }

  Future<void> _checkLicense() async {
    final expired = await LicenseService.isExpired();
    if (expired && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ExpiredScreen()),
      );
      return;
    }
    final days = await LicenseService.daysRemaining();
    final unlocked = await LicenseService.isUnlocked();
    if (mounted) {
      setState(() {
        _daysRemaining = days;
        _unlocked = unlocked;
      });
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.camera,
    ].request();
  }

  void _goToCreate() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QrScreen(isHost: true)),
    );
  }

  void _goToJoin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RoomsScreen()),
    );
  }

  final _apkShare = ApkShareService();

  Future<void> _shareApp() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Iniciando servidor...'),
        ]),
      ),
    );

    final ok = await _apkShare.start();
    if (!mounted) return;
    Navigator.of(context).pop();

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activa el hotspot e intenta de nuevo')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => _ApkShareDialog(url: _apkShare.shareUrl!),
    );

    await _apkShare.stop();
  }

  void _onLogoTap() {
    _logoTapCount++;
    if (_logoTapCount >= 10) {
      _logoTapCount = 0;
      _goToSettings();
    }
  }

  void _goToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    ).then((_) => _checkLicense());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MOTOVOX'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _goToSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              GestureDetector(
                onTap: _onLogoTap,
                child: _HelmetIcon(),
              ),
              const SizedBox(height: 12),
              Text(
                'Intercomunicador para moto',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _goToCreate,
                child: const Text('CREAR SALA'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _goToJoin,
                child: const Text('UNIRSE'),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => _shareApp(),
                child: const Text('Compartir app'),
              ),
              const SizedBox(height: 16),
              if (!_unlocked)
                Text(
                  _daysRemaining > 0
                      ? 'Prueba: $_daysRemaining dias restantes'
                      : 'Prueba vencida',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelmetIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Center(
      child: SizedBox(
        width: 120,
        height: 120,
        child: CustomPaint(
          painter: _HelmetPainter(color: color),
        ),
      ),
    );
  }
}

class _HelmetPainter extends CustomPainter {
  final Color color;
  const _HelmetPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final helmetPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final accentPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final wavePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Casco
    final helmetPath = Path()
      ..moveTo(w * 0.5, h * 0.08)
      ..cubicTo(w * 0.15, h * 0.08, w * 0.05, h * 0.35, w * 0.05, h * 0.55)
      ..lineTo(w * 0.05, h * 0.72)
      ..cubicTo(w * 0.05, h * 0.78, w * 0.1, h * 0.83, w * 0.17, h * 0.83)
      ..lineTo(w * 0.83, h * 0.83)
      ..cubicTo(w * 0.9, h * 0.83, w * 0.95, h * 0.78, w * 0.95, h * 0.72)
      ..lineTo(w * 0.95, h * 0.55)
      ..cubicTo(w * 0.95, h * 0.35, w * 0.85, h * 0.08, w * 0.5, h * 0.08)
      ..close();
    canvas.drawPath(helmetPath, helmetPaint);

    // Visor
    final visorPath = Path()
      ..addRRect(RRect.fromLTRBR(
        w * 0.18, h * 0.42,
        w * 0.82, h * 0.68,
        const Radius.circular(8),
      ));
    canvas.drawPath(visorPath, accentPaint);

    // Ondas izquierda
    for (int i = 0; i < 2; i++) {
      final offset = i * 10.0;
      final path = Path()
        ..moveTo(-offset, h * 0.35)
        ..quadraticBezierTo(-offset - 10, h * 0.55, -offset, h * 0.75);
      wavePaint.color = color.withValues(alpha:i == 0 ? 1.0 : 0.4);
      canvas.drawPath(path, wavePaint);
    }

    // Ondas derecha
    for (int i = 0; i < 2; i++) {
      final offset = i * 10.0;
      final path = Path()
        ..moveTo(w + offset, h * 0.35)
        ..quadraticBezierTo(w + offset + 10, h * 0.55, w + offset, h * 0.75);
      wavePaint.color = color.withValues(alpha:i == 0 ? 1.0 : 0.4);
      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(_HelmetPainter old) => old.color != color;
}

class _ApkShareDialog extends StatelessWidget {
  final String url;
  const _ApkShareDialog({required this.url});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Descargar MotoVox'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Conectate al hotspot y abre este QR en el navegador',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: url,
              size: 220,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            url,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CERRAR'),
        ),
      ],
    );
  }
}
