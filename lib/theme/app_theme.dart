import 'package:flutter/cupertino.dart';

/// Colores del sistema de iOS. Se usan como referencia para toda la app.
class AppColors {
  const AppColors._();

  static const Color blue = Color(0xFF007AFF);
  static const Color green = Color(0xFF34C759);
  static const Color red = Color(0xFFFF3B30);
  static const Color orange = Color(0xFFFF9500);
  static const Color yellow = Color(0xFFFFCC00);
  static const Color purple = Color(0xFFAF52DE);
  static const Color teal = Color(0xFF30B0C7);
  static const Color gray = Color(0xFF8E8E93);
}

/// Paleta dependiente del modo claro/oscuro.
class AppPalette {
  final Brightness brightness;

  const AppPalette(this.brightness);

  bool get isDark => brightness == Brightness.dark;

  Color get background =>
      isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
  Color get card =>
      isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
  Color get cardAlt =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE9E9EE);
  Color get label =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  Color get secondaryLabel => const Color(0xFF8E8E93);
  Color get tertiaryLabel =>
      isDark ? const Color(0xFF48484A) : const Color(0xFFC7C7CC);
  Color get separator =>
      isDark ? const Color(0xFF2C2C2E) : const Color(0x1F000000);
  Color get fill =>
      isDark ? const Color(0xFF1C1C1E) : const Color(0x1F787880);
  Color get blue => AppColors.blue;

  Color forType(int index) {
    switch (index) {
      case 0:
        return AppColors.blue;
      case 1:
        return AppColors.orange;
      case 2:
        return AppColors.purple;
      default:
        return AppColors.blue;
    }
  }

  static AppPalette of(BuildContext context) =>
      AppPalette(CupertinoTheme.brightnessOf(context));
}

/// Tema global con la tipografía del sistema (San Francisco en iOS).
class AppTheme {
  const AppTheme._();

  static CupertinoThemeData theme(Brightness brightness) {
    final p = AppPalette(brightness);
    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: p.blue,
      primaryContrastingColor: CupertinoColors.white,
      scaffoldBackgroundColor: p.background,
      barBackgroundColor: p.background.withValues(alpha: 0.82),
      textTheme: CupertinoTextThemeData(
        textStyle: TextStyle(
          fontSize: 17,
          letterSpacing: -0.4,
          color: p.label,
          fontWeight: FontWeight.w400,
          decoration: TextDecoration.none,
        ),
        navTitleTextStyle: TextStyle(
          fontSize: 17,
          letterSpacing: -0.4,
          color: p.label,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontSize: 34,
          letterSpacing: 0.37,
          color: p.label,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.none,
        ),
        actionTextStyle: TextStyle(
          fontSize: 17,
          letterSpacing: -0.4,
          color: p.blue,
          fontWeight: FontWeight.w400,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
