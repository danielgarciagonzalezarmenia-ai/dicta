import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';

/// Pantalla de carga minimalista.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 1750), _go);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _go() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    final scale = Tween<double>(begin: 0.94, end: 1).animate(fade);

    return CupertinoPageScaffold(
      backgroundColor: p.background,
      child: Center(
        child: FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF4CAAFF), Color(0xFF007AFF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.3),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.mic_fill,
                    color: CupertinoColors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  'Dicta',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                    color: p.label,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tu asistente de voz',
                  style: TextStyle(fontSize: 16, color: p.secondaryLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
