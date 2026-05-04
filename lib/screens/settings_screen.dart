import 'package:flutter/material.dart';
import '../services/license_service.dart';
import 'audio_test_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _unlocked = false;
  int _daysRemaining = 0;
  bool _loading = true;

  final _codeController = TextEditingController();
  bool _codeError = false;
  bool _unlocking = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final unlocked = await LicenseService.isUnlocked();
    final days = await LicenseService.daysRemaining();
    if (mounted) {
      setState(() {
        _unlocked = unlocked;
        _daysRemaining = days;
        _loading = false;
      });
    }
  }

  Future<void> _tryUnlock() async {
    setState(() {
      _unlocking = true;
      _codeError = false;
    });
    final ok = await LicenseService.tryUnlock(_codeController.text.trim());
    if (!mounted) return;
    if (ok) {
      setState(() {
        _unlocked = true;
        _unlocking = false;
      });
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App desbloqueada correctamente')),
      );
    } else {
      setState(() {
        _codeError = true;
        _unlocking = false;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CONFIGURACION')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _SectionTitle('Licencia'),
                _InfoTile(
                  icon: _unlocked ? Icons.lock_open : Icons.lock_outline,
                  label: 'Estado',
                  value: _unlocked
                      ? 'Desbloqueado'
                      : _daysRemaining > 0
                          ? '$_daysRemaining dias de prueba restantes'
                          : 'Prueba vencida',
                  valueColor: _unlocked
                      ? Colors.greenAccent
                      : _daysRemaining > 3
                          ? null
                          : Colors.redAccent,
                ),
                if (!_unlocked) ...[
                  const SizedBox(height: 24),
                  _SectionTitle('Desbloquear'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(letterSpacing: 4, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'Codigo de administrador',
                      errorText: _codeError ? 'Codigo incorrecto' : null,
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
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _unlocking ? null : _tryUnlock,
                    child: _unlocking
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('DESBLOQUEAR'),
                  ),
                ],
                const SizedBox(height: 32),
                _SectionTitle('Audio'),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.mic_none,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Test de micrófono'),
                  subtitle: const Text('Graba 5 segundos y escucha cómo suenan'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AudioTestScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _SectionTitle('Acerca de'),
                _InfoTile(
                  icon: Icons.info_outline,
                  label: 'Version',
                  value: '1.0.0',
                ),
                _InfoTile(
                  icon: Icons.headset,
                  label: 'MotoVox',
                  value: 'Intercomunicador para moto',
                ),
              ],
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      trailing: Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }
}
