import 'package:flutter/material.dart';

class GoogleFonts {
  static TextStyle robotoMono({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'IBM', // fallback to our IBM font
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle cairo({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: 'IBM', // استخدام الخط المخصص IBM بشكل عام
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  }

  static TextTheme cairoTextTheme([TextTheme? theme]) {
    return theme ?? const TextTheme();
  }
}
