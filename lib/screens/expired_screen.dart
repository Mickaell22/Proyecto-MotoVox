import 'package:flutter/material.dart';
import '../services/license_service.dart';
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
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.lock_outline,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Periodo de prueba vencido',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 22,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ingresa el codigo de administrador para desbloquear.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                obscureText: true,
                textAlign: TextAlign.center,
                style: const TextStyle(letterSpacing: 4, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Codigo',
                  errorText: _error ? 'Codigo incorrecto' : null,
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                onSubmitted: (_) => _tryUnlock(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _tryUnlock,
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('DESBLOQUEAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
