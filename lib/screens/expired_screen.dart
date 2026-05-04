import 'package:flutter/material.dart';
import '../services/license_service.dart';
import '../theme.dart';
import '../widgets/mv_widgets.dart';
import 'home_screen.dart';

class ExpiredScreen extends StatefulWidget {
  const ExpiredScreen({super.key});

  @override
  State<ExpiredScreen> createState() => _ExpiredScreenState();
}

class _ExpiredScreenState extends State<ExpiredScreen> {
  final _controller = TextEditingController();
  bool _error = false;
  bool _loading = false;
  bool _showInput = false;

  Future<void> _tryUnlock() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final ok = await LicenseService.tryUnlock(_controller.text.trim());
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.redDim,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.red.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.red,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Prueba vencida',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tu periodo de prueba ha terminado.\nContacta al administrador para continuar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.white40,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 28),

              if (_showInput) ...[
                TextField(
                  controller: _controller,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  style: const TextStyle(
                    letterSpacing: 4,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Código de administrador',
                    errorText: _error ? 'Código incorrecto' : null,
                  ),
                  onSubmitted: (_) => _tryUnlock(),
                ),
                const SizedBox(height: 12),
                PrimaryBtn(
                  label: 'Desbloquear',
                  onPressed: _loading ? null : _tryUnlock,
                  loading: _loading,
                ),
              ] else
                PrimaryBtn(
                  label: 'Ingresar código',
                  onPressed: () => setState(() => _showInput = true),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
