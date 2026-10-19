import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

/// Botón circular estilo Apple para dictar.
class MicButton extends StatefulWidget {
  final bool listening;
  final VoidCallback onTap;
  final double size;

  const MicButton({
    super.key,
    required this.listening,
    required this.onTap,
    this.size = 130,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    if (widget.listening) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listening && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.listening && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final size = widget.size;
    final canvas = size * 1.7;
    final accent = widget.listening ? AppColors.red : p.blue;

    return SizedBox(
      width: canvas,
      height: canvas,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (!widget.listening) return const SizedBox.shrink();
              return CustomPaint(
                size: Size(canvas, canvas),
                painter: _RingPainter(_controller.value, accent),
              );
            },
          ),
          GestureDetector(
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: widget.listening
                      ? const [Color(0xFFFF6B62), Color(0xFFFF3B30)]
                      : const [Color(0xFF4CAAFF), Color(0xFF007AFF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.32),
                    blurRadius: 28,
                    spreadRadius: 1,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  widget.listening
                      ? CupertinoIcons.stop_fill
                      : CupertinoIcons.mic_fill,
                  key: ValueKey<bool>(widget.listening),
                  color: CupertinoColors.white,
                  size: size * 0.34,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double t;
  final Color color;

  _RingPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final baseRadius = maxRadius * 0.42;

    for (var i = 0; i < 3; i++) {
      final progress = (t + i / 3) % 1.0;
      final radius = baseRadius + (maxRadius - baseRadius) * progress;
      final paint = Paint()
        ..color = color.withValues(alpha: (1 - progress) * 0.28)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}
