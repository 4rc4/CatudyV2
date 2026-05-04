import 'package:flutter/material.dart';

class CatudyColors {
  const CatudyColors._();

  static const ink = Color(0xFF13235F);
  static const muted = Color(0xFF665B86);
  static const paper = Color(0xFFFFF6EF);
  static const surface = Color(0xFFFFFAF7);
  static const surfaceStrong = Color(0xFFEFE6FF);
  static const line = Color(0xFFD8C8FF);
  static const teal = Color(0xFF5BC8BC);
  static const tealDark = Color(0xFF2D8F88);
  static const coral = Color(0xFFFF765F);
  static const yellow = Color(0xFFFFD16F);
  static const blue = Color(0xFF143985);
  static const violet = Color(0xFF7561C8);
  static const violetDark = Color(0xFF4F4599);
  static const lavender = Color(0xFFBBA6F3);
  static const lavenderSoft = Color(0xFFEADFFF);
  static const cream = Color(0xFFFFF3EB);

  static const darkInk = Color(0xFFF4F0FF);
  static const darkMuted = Color(0xFFC9BFEA);
  static const darkPaper = Color(0xFF15112A);
  static const darkSurface = Color(0xFF211B3A);
  static const darkSurfaceStrong = Color(0xFF302852);
  static const darkLine = Color(0xFF5A4C88);
  static const darkCream = Color(0xFF281D36);

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color paperFor(BuildContext context) {
    return isDark(context) ? darkPaper : paper;
  }

  static Color surfaceFor(BuildContext context) {
    return isDark(context) ? darkSurface : surface;
  }

  static Color surfaceStrongFor(BuildContext context) {
    return isDark(context) ? darkSurfaceStrong : surfaceStrong;
  }

  static Color creamFor(BuildContext context) {
    return isDark(context) ? darkCream : cream;
  }

  static Color inkFor(BuildContext context) {
    return isDark(context) ? darkInk : ink;
  }

  static Color mutedFor(BuildContext context) {
    return isDark(context) ? darkMuted : muted;
  }

  static Color lineFor(BuildContext context) {
    return isDark(context) ? darkLine : line;
  }

  static Color blueFor(BuildContext context) {
    return isDark(context) ? darkInk : blue;
  }
}
