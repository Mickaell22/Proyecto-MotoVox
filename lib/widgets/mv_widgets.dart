import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

// ─── AppBar con borde inferior ────────────────────────────────────────────────

class MvAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? rightIcon;
  final VoidCallback? onRight;

  const MvAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.rightIcon,
    this.onRight,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: onBack,
            )
          : null,
      automaticallyImplyLeading: false,
      actions: onRight != null && rightIcon != null
          ? [
              IconButton(
                icon: rightIcon!,
                onPressed: onRight,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ]
          : null,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }
}

// ─── Status Pill ─────────────────────────────────────────────────────────────

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const StatusPill({
    super.key,
    required this.label,
    this.color = AppColors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white12,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color, blurRadius: 8, spreadRadius: 1)],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Botón primario ───────────────────────────────────────────────────────────

class PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool danger;
  final Widget? icon;
  final bool loading;

  const PrimaryBtn({
    super.key,
    required this.label,
    this.onPressed,
    this.danger = false,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = danger ? AppColors.red : AppColors.orange;
    final fg = danger ? Colors.white : Colors.black;

    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: const Color(0xFF2A2A2A),
        disabledForegroundColor: AppColors.white40,
        minimumSize: const Size(double.infinity, 56),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.8,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      child: loading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[icon!, const SizedBox(width: 8)],
                Text(label.toUpperCase()),
              ],
            ),
    );
  }
}

// ─── Botón outline ────────────────────────────────────────────────────────────

class OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool danger;
  final Widget? icon;

  const OutlineBtn({
    super.key,
    required this.label,
    this.onPressed,
    this.danger = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.red : AppColors.orange;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 2),
        minimumSize: const Size(double.infinity, 56),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.8,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 8)],
          Text(label.toUpperCase()),
        ],
      ),
    );
  }
}

// ─── Barras de señal ─────────────────────────────────────────────────────────

class SignalBars extends StatelessWidget {
  final int level; // 0–3

  const SignalBars({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          width: 4,
          height: 5.0 + i * 3.5,
          margin: const EdgeInsets.only(left: 2.5),
          decoration: BoxDecoration(
            color: i < level ? AppColors.orange : AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

// ─── Casco animado ────────────────────────────────────────────────────────────

class HelmetWidget extends StatefulWidget {
  final double size;
  final bool animated;

  const HelmetWidget({super.key, this.size = 80, this.animated = false});

  @override
  State<HelmetWidget> createState() => _HelmetWidgetState();
}

class _HelmetWidgetState extends State<HelmetWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _wave;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _wave = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.animated) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(HelmetWidget old) {
    super.didUpdateWidget(old);
    if (widget.animated && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.animated && _ctrl.isAnimating) {
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
    return AnimatedBuilder(
      animation: _wave,
      builder: (_, _) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _HelmetPainter(
          waveOpacity: widget.animated ? _wave.value : 1.0,
        ),
      ),
    );
  }
}

class _HelmetPainter extends CustomPainter {
  final double waveOpacity;
  const _HelmetPainter({this.waveOpacity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 1024;

    // Fondo redondeado
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(180 * s),
      ),
      Paint()..color = AppColors.darkBg,
    );

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Onda izquierda interna
    wavePaint
      ..color = AppColors.orange.withValues(alpha: waveOpacity)
      ..strokeWidth = 36 * s;
    canvas.drawPath(
      Path()
        ..moveTo(180 * s, 420 * s)
        ..quadraticBezierTo(140 * s, 512 * s, 180 * s, 604 * s),
      wavePaint,
    );

    // Onda izquierda externa
    wavePaint
      ..color = AppColors.orange.withValues(alpha: waveOpacity * 0.45)
      ..strokeWidth = 28 * s;
    canvas.drawPath(
      Path()
        ..moveTo(120 * s, 360 * s)
        ..quadraticBezierTo(60 * s, 512 * s, 120 * s, 664 * s),
      wavePaint,
    );

    // Onda derecha interna
    wavePaint
      ..color = AppColors.orange.withValues(alpha: waveOpacity)
      ..strokeWidth = 36 * s;
    canvas.drawPath(
      Path()
        ..moveTo(844 * s, 420 * s)
        ..quadraticBezierTo(884 * s, 512 * s, 844 * s, 604 * s),
      wavePaint,
    );

    // Onda derecha externa
    wavePaint
      ..color = AppColors.orange.withValues(alpha: waveOpacity * 0.45)
      ..strokeWidth = 28 * s;
    canvas.drawPath(
      Path()
        ..moveTo(904 * s, 360 * s)
        ..quadraticBezierTo(964 * s, 512 * s, 904 * s, 664 * s),
      wavePaint,
    );

    // Cuerpo del casco (blanco)
    final helmetPath = Path()
      ..moveTo(512 * s, 220 * s)
      ..cubicTo(340 * s, 220 * s, 220 * s, 340 * s, 220 * s, 490 * s)
      ..lineTo(220 * s, 580 * s)
      ..cubicTo(220 * s, 610 * s, 244 * s, 634 * s, 274 * s, 634 * s)
      ..lineTo(360 * s, 634 * s)
      ..cubicTo(370 * s, 660 * s, 394 * s, 678 * s, 422 * s, 678 * s)
      ..lineTo(602 * s, 678 * s)
      ..cubicTo(630 * s, 678 * s, 654 * s, 660 * s, 664 * s, 634 * s)
      ..lineTo(750 * s, 634 * s)
      ..cubicTo(780 * s, 634 * s, 804 * s, 610 * s, 804 * s, 580 * s)
      ..lineTo(804 * s, 490 * s)
      ..cubicTo(804 * s, 340 * s, 684 * s, 220 * s, 512 * s, 220 * s)
      ..close();
    canvas.drawPath(helmetPath, Paint()..color = Colors.white);

    // Visor (naranja)
    final visorPath = Path()
      ..moveTo(320 * s, 460 * s)
      ..cubicTo(320 * s, 440 * s, 336 * s, 424 * s, 356 * s, 424 * s)
      ..lineTo(668 * s, 424 * s)
      ..cubicTo(688 * s, 424 * s, 704 * s, 440 * s, 704 * s, 460 * s)
      ..lineTo(704 * s, 530 * s)
      ..cubicTo(704 * s, 550 * s, 688 * s, 566 * s, 668 * s, 566 * s)
      ..lineTo(356 * s, 566 * s)
      ..cubicTo(336 * s, 566 * s, 320 * s, 550 * s, 320 * s, 530 * s)
      ..close();
    canvas.drawPath(visorPath, Paint()..color = AppColors.orange);

    // Reflejo del visor
    final highlightPath = Path()
      ..moveTo(340 * s, 440 * s)
      ..lineTo(440 * s, 440 * s)
      ..lineTo(420 * s, 546 * s)
      ..lineTo(340 * s, 546 * s)
      ..close();
    canvas.drawPath(
      highlightPath,
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );
  }

  @override
  bool shouldRepaint(_HelmetPainter old) => old.waveOpacity != waveOpacity;
}

// ─── Anillos de pulso ─────────────────────────────────────────────────────────

class PulseRings extends StatefulWidget {
  final bool active;
  final double size;
  final double baseOpacity;
  final Duration duration;

  const PulseRings({
    super.key,
    required this.active,
    this.size = 140,
    this.baseOpacity = 0.8,
    this.duration = const Duration(milliseconds: 1800),
  });

  @override
  State<PulseRings> createState() => _PulseRingsState();
}

class _PulseRingsState extends State<PulseRings>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    if (widget.active) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(PulseRings old) {
    super.didUpdateWidget(old);
    if (widget.active && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.active && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _PulseRingsPainter(
          progress: _ctrl.value,
          active: widget.active,
          baseOpacity: widget.baseOpacity,
        ),
      ),
    );
  }
}

class _PulseRingsPainter extends CustomPainter {
  final double progress;
  final bool active;
  final double baseOpacity;

  const _PulseRingsPainter({
    required this.progress,
    required this.active,
    required this.baseOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!active) return;
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 3; i++) {
      final t = (progress + i / 3.0) % 1.0;
      final r = maxR * (0.5 + t * 0.7);
      final opacity = baseOpacity * (1.0 - t);
      paint.color = AppColors.orange.withValues(alpha: opacity.clamp(0.0, 1.0));
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_PulseRingsPainter old) =>
      old.progress != progress || old.active != active;
}

// ─── Barras de audio ──────────────────────────────────────────────────────────

class AudioBarsWidget extends StatefulWidget {
  final bool active;

  const AudioBarsWidget({super.key, required this.active});

  @override
  State<AudioBarsWidget> createState() => _AudioBarsWidgetState();
}

class _AudioBarsWidgetState extends State<AudioBarsWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _phases = [
    0.0, 0.4, 0.2, 0.7, 0.1, 0.5, 0.3, 0.6, 0.15, 0.45, 0.25, 0.8,
  ];
  static const _baseH = [
    0.3, 0.7, 1.0, 0.5, 0.9, 0.6, 0.35, 0.8, 1.0, 0.55, 0.7, 0.25,
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.active) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(AudioBarsWidget old) {
    super.didUpdateWidget(old);
    if (widget.active && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.active && _ctrl.isAnimating) {
      _ctrl.animateTo(0.0, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        return SizedBox(
          height: 36,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(12, (i) {
              double height;
              if (widget.active) {
                final t = (_ctrl.value + _phases[i]) % 1.0;
                final factor = (math.sin(t * 2 * math.pi) + 1) / 2;
                height = (0.25 + factor * 0.75) * _baseH[i] * 32;
              } else {
                height = 4.0;
              }
              return Container(
                width: 4,
                height: height.clamp(3.0, 32.0),
                margin: const EdgeInsets.symmetric(horizontal: 1.75),
                decoration: BoxDecoration(
                  color: widget.active
                      ? AppColors.orange.withValues(alpha: 0.8)
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
