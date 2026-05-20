import 'package:flutter/material.dart';

import 'catudy_colors.dart';

class CatudyTheme {
  const CatudyTheme._();

  static const _headingFontFamily = 'Baloo 2';
  static const _buttonFontFamily = 'Fredoka';
  static const _bodyFontFamily = 'Nunito';
  static const _headingFontVariations = [FontVariation('wght', 600)];
  static const _buttonFontVariations = [FontVariation('wght', 500)];

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: CatudyColors.violet,
      brightness: brightness,
      primary: CatudyColors.violet,
      secondary: CatudyColors.teal,
      tertiary: CatudyColors.teal,
      surface: dark ? CatudyColors.darkSurface : CatudyColors.surface,
      onSurface: dark ? CatudyColors.darkInk : CatudyColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      splashFactory: InkSparkle.splashFactory,
      splashColor: CatudyColors.violet.withValues(alpha: dark ? 0.20 : 0.16),
      highlightColor: CatudyColors.violet.withValues(alpha: dark ? 0.16 : 0.10),
      hoverColor: CatudyColors.violet.withValues(alpha: dark ? 0.10 : 0.07),
      fontFamily: _bodyFontFamily,
      scaffoldBackgroundColor: dark
          ? CatudyColors.darkPaper
          : CatudyColors.paper,
      textTheme: _textTheme(dark),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: dark ? CatudyColors.darkInk : CatudyColors.blue,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: dark ? CatudyColors.darkInk : CatudyColors.blue,
          fontFamily: _headingFontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          fontVariations: _headingFontVariations,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            (dark ? CatudyColors.darkSurfaceStrong : CatudyColors.surface)
                .withValues(alpha: dark ? 0.72 : 0.88),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIconColor: dark ? CatudyColors.darkMuted : CatudyColors.muted,
        labelStyle: TextStyle(
          color: dark ? CatudyColors.darkMuted : CatudyColors.muted,
          fontWeight: FontWeight.w700,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: CatudyColors.violet.withValues(alpha: dark ? 0.26 : 0.18),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: CatudyColors.violet, width: 1.5),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
      cardTheme: CardThemeData(
        color: dark ? CatudyColors.darkSurface : CatudyColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: CatudyColors.violet.withValues(alpha: 0.16)),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: CatudyColors.violet,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
              animationDuration: _buttonAnimationDuration,
              enableFeedback: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: _buttonTextStyle,
            ).copyWith(
              overlayColor: _buttonOverlay(
                Colors.white,
                pressedAlpha: 0.24,
                hoveredAlpha: 0.12,
                focusedAlpha: 0.16,
              ),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: dark ? CatudyColors.darkInk : CatudyColors.blue,
              minimumSize: const Size(0, 48),
              animationDuration: _buttonAnimationDuration,
              enableFeedback: true,
              side: BorderSide(
                color: CatudyColors.violet.withValues(alpha: 0.24),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: _buttonTextStyle,
            ).copyWith(
              overlayColor: _buttonOverlay(
                CatudyColors.violet,
                pressedAlpha: dark ? 0.22 : 0.16,
                hoveredAlpha: dark ? 0.12 : 0.08,
                focusedAlpha: dark ? 0.16 : 0.10,
              ),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style:
            TextButton.styleFrom(
              animationDuration: _buttonAnimationDuration,
              enableFeedback: true,
              textStyle: _buttonTextStyle,
            ).copyWith(
              overlayColor: _buttonOverlay(
                CatudyColors.violet,
                pressedAlpha: dark ? 0.22 : 0.16,
                hoveredAlpha: dark ? 0.12 : 0.08,
                focusedAlpha: dark ? 0.16 : 0.10,
              ),
            ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style:
            IconButton.styleFrom(
              backgroundColor:
                  (dark ? CatudyColors.darkSurface : CatudyColors.surface)
                      .withValues(alpha: dark ? 0.88 : 0.96),
              foregroundColor: dark
                  ? CatudyColors.darkMuted
                  : CatudyColors.muted,
              minimumSize: const Size(44, 44),
              animationDuration: _buttonAnimationDuration,
              enableFeedback: true,
            ).copyWith(
              overlayColor: _buttonOverlay(
                CatudyColors.violet,
                pressedAlpha: dark ? 0.26 : 0.18,
                hoveredAlpha: dark ? 0.14 : 0.09,
                focusedAlpha: dark ? 0.18 : 0.12,
              ),
            ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              animationDuration: _buttonAnimationDuration,
              enableFeedback: true,
              textStyle: _buttonTextStyle,
            ).copyWith(
              overlayColor: _buttonOverlay(
                CatudyColors.violet,
                pressedAlpha: dark ? 0.22 : 0.16,
                hoveredAlpha: dark ? 0.12 : 0.08,
                focusedAlpha: dark ? 0.16 : 0.10,
              ),
              elevation: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return 0;
                }
                if (states.contains(WidgetState.pressed)) {
                  return 1;
                }
                if (states.contains(WidgetState.hovered)) {
                  return 4;
                }
                return 2;
              }),
            ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            (dark ? CatudyColors.darkSurface : CatudyColors.surface).withValues(
              alpha: 0.94,
            ),
        indicatorColor: dark
            ? CatudyColors.darkSurfaceStrong
            : CatudyColors.lavenderSoft,
        elevation: 0,
        height: 74,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected
                ? (dark ? CatudyColors.darkInk : CatudyColors.blue)
                : (dark ? CatudyColors.darkMuted : CatudyColors.muted),
            fontFamily: _buttonFontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontVariations: _buttonFontVariations,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? CatudyColors.teal
                : (dark ? CatudyColors.darkMuted : CatudyColors.muted),
            size: selected ? 26 : 24,
          );
        }),
      ),
    );
  }

  static TextTheme _textTheme(bool dark) {
    final base = Typography.blackMountainView.apply(
      fontFamily: _bodyFontFamily,
      bodyColor: dark ? CatudyColors.darkInk : CatudyColors.ink,
      displayColor: dark ? CatudyColors.darkInk : CatudyColors.blue,
    );
    final bodyColor = dark ? CatudyColors.darkInk : CatudyColors.ink;
    final titleColor = dark ? CatudyColors.darkInk : CatudyColors.blue;
    return base.copyWith(
      displayLarge: _headingStyle(base.displayLarge, titleColor),
      displayMedium: _headingStyle(base.displayMedium, titleColor),
      displaySmall: _headingStyle(base.displaySmall, titleColor),
      headlineLarge: _headingStyle(base.headlineLarge, titleColor),
      headlineMedium: _headingStyle(base.headlineMedium, titleColor),
      headlineSmall: _headingStyle(base.headlineSmall, titleColor),
      titleLarge: _headingStyle(base.titleLarge, titleColor),
      titleMedium: _headingStyle(base.titleMedium, titleColor),
      titleSmall: _headingStyle(base.titleSmall, titleColor),
      bodyLarge: _bodyStyle(base.bodyLarge, bodyColor),
      bodyMedium: _bodyStyle(base.bodyMedium, bodyColor),
      bodySmall: _bodyStyle(base.bodySmall, bodyColor),
      labelLarge: _bodyStyle(base.labelLarge, bodyColor),
      labelMedium: _bodyStyle(base.labelMedium, bodyColor),
      labelSmall: _bodyStyle(base.labelSmall, bodyColor),
    );
  }

  static const _buttonTextStyle = TextStyle(
    fontFamily: _buttonFontFamily,
    fontWeight: FontWeight.w500,
    fontVariations: _buttonFontVariations,
  );
  static const _buttonAnimationDuration = Duration(milliseconds: 120);

  static WidgetStateProperty<Color?> _buttonOverlay(
    Color color, {
    required double pressedAlpha,
    required double hoveredAlpha,
    required double focusedAlpha,
  }) {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return null;
      }
      if (states.contains(WidgetState.pressed)) {
        return color.withValues(alpha: pressedAlpha);
      }
      if (states.contains(WidgetState.hovered)) {
        return color.withValues(alpha: hoveredAlpha);
      }
      if (states.contains(WidgetState.focused)) {
        return color.withValues(alpha: focusedAlpha);
      }
      return null;
    });
  }

  static TextStyle? _headingStyle(TextStyle? base, Color color) =>
      base?.copyWith(
        color: color,
        fontFamily: _headingFontFamily,
        fontWeight: FontWeight.w600,
        fontVariations: _headingFontVariations,
      );

  static TextStyle? _bodyStyle(TextStyle? base, Color color) => base?.copyWith(
    color: color,
    fontFamily: _bodyFontFamily,
    fontWeight: FontWeight.w400,
  );
}
