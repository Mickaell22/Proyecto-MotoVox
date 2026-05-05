import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/apk_share_service.dart';
import '../theme.dart';
import '../widgets/mv_widgets.dart';

class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final _service = ApkShareService();
  String? _url;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final ok = await _service.start();
    if (!mounted) return;
    if (ok) {
      setState(() => _url = _service.shareUrl);
    } else {
      setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _service.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MvAppBar(
        title: 'Compartir app',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: _error
              ? _buildError()
              : _url == null
                  ? _buildLoading()
                  : _buildQr(_url!),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.orange,
              backgroundColor: AppColors.border,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Iniciando servidor...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Buscando red WiFi',
            style: TextStyle(color: AppColors.white40, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 56,
            height: 56,
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
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Activa el hotspot e intenta de nuevo',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.white40, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        OutlineBtn(
          label: 'Cerrar',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildQr(String url) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Conectate al hotspot y abre este QR en el navegador',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.white40,
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.orangeGlow,
                  blurRadius: 48,
                ),
              ],
            ),
            child: QrImageView(
              data: url,
              size: 200,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          url,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.white40,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 28),
        OutlineBtn(
          label: 'Cerrar',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
