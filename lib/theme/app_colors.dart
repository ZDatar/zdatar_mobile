import 'package:flutter/material.dart';

class AppColors {
  // Light theme colors
  static const Color lightPrimary = Color(0xFF1B4965);
  static const Color lightSecondary = Color(0xFF76C7FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightAccent = Color(0xFF2979FF);
  static const Color lightWarning = Color(0xFFFFC300);
  static const Color lightError = Color(0xFFFF5733);
  static const Color lightSuccess = Color(0xFF4CAF50);

  // Dark theme colors
  static const Color darkPrimary = Color(0xFF0D1B2A);
  static const Color darkSecondary = Color(0xFF76C7FF);
  static const Color darkSurface = Color(0xFF1B263B);
  static const Color darkCard = Color(0xFF1B263B);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0BEC5);
  static const Color darkAccent = Color(0xFF2979FF);
  static const Color darkWarning = Color(0xFFFFC300);
  static const Color darkError = Color(0xFFFF5733);
  static const Color darkSuccess = Color(0xFF4CAF50);

  // Legacy colors for backward compatibility
  static const Color primary = Color(0xFF0D1B2A);
  static const Color secondary = Color(0xFF76C7FF);
  static const Color accent = Color(0xFF2979FF);
  static const Color card = Color(0xFF1B263B);
  static const Color text = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color warning = Color(0xFFFFC300);
  static const Color error = Color(0xFFFF5733);
  static const Color success = Color(0xFF4CAF50);
}

class AppRadius {
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double xlarge = 20.0;
  static const double xxlarge = 24.0;

  static BorderRadius get smallRadius => BorderRadius.circular(small);
  static BorderRadius get mediumRadius => BorderRadius.circular(medium);
  static BorderRadius get largeRadius => BorderRadius.circular(large);
  static BorderRadius get xlargeRadius => BorderRadius.circular(xlarge);
  static BorderRadius get xxlargeRadius => BorderRadius.circular(xxlarge);
}