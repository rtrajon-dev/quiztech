import 'package:flutter/material.dart';

/// Central color palette for the app.
class AppColors {
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Color(0xFFD4D4D4);

  static const Color primary = Color(0xFF1F41BB);
  static const Color lightBlue = Color.fromARGB(255, 222, 227, 249);

  /// Signature blue → cyan gradient used across quiz surfaces.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF3550DC),
      Color(0xFF27E9F7),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
