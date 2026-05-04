import 'dart:async';
import 'package:flutter/material.dart';
import '../services/audio_test_service.dart';
import '../theme.dart';

class AudioTestScreen extends StatefulWidget {
  const AudioTestScreen({super.key});

  @override
  State<AudioTestScreen> createState() => _AudioTestScreenState();
}

class _AudioTestScreenState extends State<AudioTestScreen>
    with SingleTickerProviderStateMixin {
  final _service = AudioTestService();
  AudioTestState _state = AudioTestState.idle;
  int _countdown = 5;
  Timer? _timer;
  StreamSubscription? _sub;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _sub = _service.onStateChanged.listen((s) {
      if (!mounted) return;
      setState(() => _state = s);
      if (s == AudioTestState.recording) {
        _pulseCtrl.repeat(reverse: true);
      } else {
        _pulseCtrl.stop();
        _pulseCtrl.value = 0;
      }
    });
    _service.init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    _pulseCtrl.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _startTest() async {
    setState(() => _countdown = 5);
    await _service.startRecording();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) { t.cancel(); return; }
      final next = _countdown - 1;
      if (next <= 0) {
        t.cancel();
        await _service.stopRecordingAndPlay();
      } else {
        setState(() => _countdown = next);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TEST DE AUDIO')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildIcon(),
              const SizedBox(height: 40),
              _buildMessage(),
              const SizedBox(height: 12),
              _buildSubtitle(),
              const SizedBox(height: 48),
              _buildButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (ctx, _) {
          final scale = 1.0 + _pulseCtrl.value * 0.15;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _iconColor().withValues(alpha: 0.15),
                border: Border.all(color: _iconColor(), width: 2),
              ),
              child: Icon(_iconData(), size: 56, color: _iconColor()),
            ),
          );
        },
      ),
    );
  }

  IconData _iconData() => switch (_state) {
    AudioTestState.idle => Icons.mic_none,
    AudioTestState.recording => Icons.mic,
    AudioTestState.playing => Icons.headphones,
    AudioTestState.done => Icons.check_circle_outline,
  };

  Color _iconColor() => switch (_state) {
    AudioTestState.idle => AppColors.orange,
    AudioTestState.recording => Colors.redAccent,
    AudioTestState.playing => Colors.blueAccent,
    AudioTestState.done => Colors.greenAccent,
  };

  Widget _buildMessage() {
    final text = switch (_state) {
      AudioTestState.idle => 'Probar tu micrófono',
      AudioTestState.recording => 'Grabando... $_countdown',
      AudioTestState.playing => 'Reproduciendo...',
      AudioTestState.done => '¿Se escuchó bien?',
    };
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSubtitle() {
    final text = switch (_state) {
      AudioTestState.idle =>
        'Habla durante 5 segundos y escucha\ncómo te va a oír el copiloto.',
      AudioTestState.recording =>
        'Habla normalmente, como si hablaras\na tu copiloto en la moto.',
      AudioTestState.playing =>
        'Escucha cómo se oyó tu voz\ncon el filtro activo.',
      AudioTestState.done =>
        'Si no te escuchaste claro,\npuedes volver a intentarlo.',
    };
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
    );
  }

  Widget _buildButton() {
    return switch (_state) {
      AudioTestState.idle => ElevatedButton.icon(
          onPressed: _startTest,
          icon: const Icon(Icons.mic),
          label: const Text('COMENZAR TEST'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      AudioTestState.recording => OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.redAccent, width: 2),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'GRABANDO...',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      AudioTestState.playing => OutlinedButton(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.blueAccent, width: 2),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'REPRODUCIENDO...',
            style: TextStyle(color: Colors.blueAccent),
          ),
        ),
      AudioTestState.done => Column(
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                await _service.reset();
                _startTest();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('REPETIR TEST'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.orange,
                side: const BorderSide(color: AppColors.orange, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('LISTO'),
            ),
          ],
        ),
    };
  }
}
