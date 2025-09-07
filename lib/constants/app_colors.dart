import 'package:flutter/material.dart';

/// Application color constants
class AppColors {
  // Primary Colors
  static const Color primary = Colors.blue;
  static const Color primaryLight = Color(0xFF667eea);
  static const Color primaryDark = Color(0xFF000428);

  // Background Gradient Colors
  static const List<Color> backgroundGradient = [
    Color(0xFF667eea),
    Color(0xFF764ba2),
    Color(0xFF6B73FF),
    Color(0xFF000428),
  ];

  // Text Colors
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Colors.white;

  // Background Colors
  static const Color cardBackground = Colors.white;
  static const Color overlayBackground = Colors.black54;

  // UI Component Colors
  static const Color inputBorder = Colors.grey;
  static const Color inputFocusedBorder = Colors.blue;
  static const Color buttonBackground = Colors.blue;
  static const Color buttonText = Colors.white;

  // Status Colors
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  static const Color info = Colors.blue;

  // Opacity Values
  static const double cardOpacity = 0.95;
  static const double overlayOpacity = 0.4;
  static const double infoBoxOpacity = 0.1;
  static const double infoBorderOpacity = 0.3;
}

