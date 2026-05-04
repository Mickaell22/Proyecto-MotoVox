import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/license_service.dart';
import '../theme.dart';
import '../widgets/mv_widgets.dart';
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
  String _appVersion = '';

  final _codeController = TextEditingController();
  bool _codeError = false;
  bool _unlocking = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final results = await Future.wait([
      LicenseService.isUnlocked(),
      LicenseService.daysRemaining(),
      PackageInfo.fromPlatform(),
    ]);
    if (mounted) {
      setState(() {
        _unlocked = results[0] as bool;
        _daysRemaining = results[1] as int;
        _appVersion = (results[2] as PackageInfo).version;
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
      appBar: MvAppBar(
        title: 'Configuración',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.orange))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                // ── Licencia ────────────────────────────────────────────────
                _SectionHeader('Licencia'),
                _SettingsCard(
                  children: [
                    _LicenseTile(
                      unlocked: _unlocked,
                      days: _daysRemaining,
                    ),
                  ],
                ),

                // ── Desbloquear ─────────────────────────────────────────────
                if (!_unlocked) ...[
                  const SizedBox(height: 20),
                  _SectionHeader('Desbloquear'),
                  _SettingsCard(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextField(
                        controller: _codeController,
                        obscureText: true,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          letterSpacing: 4,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Código de administrador',
                          errorText: _codeError ? 'Código incorrecto' : null,
                        ),
                        onSubmitted: (_) => _tryUnlock(),
                      ),
                      const SizedBox(height: 12),
                      PrimaryBtn(
                        label: 'Desbloquear',
                        onPressed: _unlocking ? null : _tryUnlock,
                        loading: _unlocking,
                      ),
                    ],
                  ),
                ],

                // ── Audio ───────────────────────────────────────────────────
                const SizedBox(height: 20),
                _SectionHeader('Audio'),
                _SettingsCard(
                  children: [
                    _ActionTile(
                      icon: Icons.mic_none,
                      title: 'Test de micrófono',
                      subtitle: 'Graba 5 s y escucha cómo suenan',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const AudioTestScreen()),
                      ),
                    ),
                  ],
                ),

                // ── Acerca de ───────────────────────────────────────────────
                const SizedBox(height: 20),
                _SectionHeader('Acerca de'),
                _SettingsCard(
                  children: [
                    _InfoRow(label: 'Versión', value: _appVersion),
                    _Divider(),
                    _InfoRow(
                        label: 'MotoVox', value: 'Intercomunicador para moto'),
                  ],
                ),
              ],
            ),
    );
  }
}

// ─── Componentes de configuración ────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          color: AppColors.orange,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;

  const _SettingsCard({required this.children, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: padding,
      child: Column(
        children: children,
      ),
    );
  }
}

class _LicenseTile extends StatelessWidget {
  final bool unlocked;
  final int days;

  const _LicenseTile({required this.unlocked, required this.days});

  @override
  Widget build(BuildContext context) {
    final statusText = unlocked
        ? 'Desbloqueado'
        : days > 0
            ? 'Versión de prueba'
            : 'Prueba vencida';

    final valueText = unlocked
        ? 'Activo'
        : days > 0
            ? '$days días'
            : 'Vencida';

    final valueColor = unlocked
        ? AppColors.green
        : days > 3
            ? AppColors.orange
            : AppColors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.orangeDim,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              unlocked ? Icons.lock_open_outlined : Icons.lock_outline,
              color: AppColors.orange,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estado',
                  style: TextStyle(
                    color: AppColors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: const TextStyle(
                    color: AppColors.white40,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            valueText,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.orangeDim,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.orange, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.white40,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.white40, size: 16),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white40,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.border,
    );
  }
}
