import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1D61E7);
  static const Color secondary = Color(0xFFE5EEFF);
  static const Color background = Color(0xFFF8FAFF);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFE74C3C);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color success = Color(0xFF4A8BFF); // Changed to blue
  static const Color warning = Color(0xFF64B5F6); // Changed to light blue
  static const Color cardBorder = Color(0xFFE0E0E0); // For card visibility
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1D61E7),
      Color(0xFF4A8BFF),
    ],
  );
}
