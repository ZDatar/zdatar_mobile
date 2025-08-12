import 'package:flutter/material.dart';

/// Collection of custom icons used throughout the app
class AppIcons {
  AppIcons._(); // Private constructor to prevent instantiation

  /// Rotated arrow icon (45 degrees) with teal accent color
  /// Used for indicating upward/diagonal movement or actions
  static Widget sent({Color? color, double? size}) {
    return Transform.rotate(
      angle: 0.785398, // 45 degrees in radians
      child: Icon(
        Icons.arrow_circle_up_rounded,
        color: color ?? Colors.redAccent,
        size: size ?? 45,
      ),
    );
  }

  /// Rotated arrow icon 225 degrees with teal accent color
  static Widget received({Color? color, double? size}) {
    return Transform.rotate(
      angle: 3.926991, // 225 degrees in radians
      child: Icon(
        Icons.arrow_circle_up_rounded,
        color: color ?? Colors.green,
        size: size ?? 45,
      ),
    );
  }
}
