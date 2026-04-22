import 'dart:async';
import 'package:flutter/material.dart';
import '../services/audio_relay_service.dart';
import '../theme.dart';

class ConnectedScreen extends StatefulWidget {
  final AudioRelayService audio;
  const ConnectedScreen({super.key, required this.audio});

  @override
  State<ConnectedScreen> createState() => _ConnectedScreenState();
}

class _ConnectedScreenState extends State<ConnectedScreen> {
  bool _connected = true;
  StreamSubscription? _sub;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _sub = widget.audio.connectionState.listen((state) {
      if (mounted) setState(() => _connected = state);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    widget.audio.dispose();
    super.dispose();
  }

  void _disconnect() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    widget.audio.setMuted(_muted);
  }

  String get _statusLabel => _connected ? 'Conectado' : 'Desconectado';
  Color _statusColor(BuildContext ctx) =>
      _connected ? Colors.greenAccent : Colors.redAccent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MOTOVOX'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(child: _AudioIndicator(active: _connected && !_muted)),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _statusColor(context),
                  ),
                ),
              ),
              if (_connected) ...[
                const SizedBox(height: 8),
                Text(
                  _muted ? 'Micrófono silenciado' : 'Audio activo — sin push-to-talk',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _toggleMute,
                icon: Icon(_muted ? Icons.mic_off : Icons.mic),
                label: Text(_muted ? 'ACTIVAR MICRÓFONO' : 'SILENCIAR'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _muted ? Colors.redAccent : AppColors.orange,
                  side: BorderSide(
                    color: _muted ? Colors.redAccent : AppColors.orange,
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _disconnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('DESCONECTAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioIndicator extends StatefulWidget {
  final bool active;
  const _AudioIndicator({required this.active});

  @override
  State<_AudioIndicator> createState() => _AudioIndicatorState();
}

class _AudioIndicatorState extends State<_AudioIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(_AudioIndicator old) {
    super.didUpdateWidget(old);
    if (widget.active && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.active) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(140, 140),
          painter: _WavePainter(
            progress: widget.active ? _anim.value : 0,
            color: color,
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final Color color;
  const _WavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final micPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromLTRBR(cx - 10, cy - 22, cx + 10, cy + 8, const Radius.circular(10)),
      micPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy + 8), width: 28, height: 20),
      0, 3.14159, false, paint..style = PaintingStyle.stroke,
    );
    canvas.drawLine(Offset(cx, cy + 18), Offset(cx, cy + 26), paint);

    if (progress == 0) return;

    for (int i = 1; i <= 3; i++) {
      final radius = 30.0 + i * 14 + progress * 6;
      paint
        ..color = color.withValues(alpha: (1.0 - (i * 0.25)) * progress)
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress || old.color != color;
}
