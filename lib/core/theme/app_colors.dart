import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Deep Teal with Gold Accents
  static const Color primaryLight = Color(0xFF006B5D); // Deep Teal
  static const Color primaryDark = Color(0xFF4ECDC4); // Bright Teal
  
  static const Color secondaryLight = Color(0xFFD4AF37); // Antique Gold
  static const Color secondaryDark = Color(0xFFFFD700); // Bright Gold
  
  // Background Colors
  static const Color backgroundLight = Color(0xFFFAFBFC); // Soft White
  static const Color backgroundDark = Color(0xFF0F1419); // Deep Dark Blue
  
  static const Color surfaceLight = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceDark = Color(0xFF1A1F2E); // Dark Blue Gray
  
  // Card Colors
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF242B3D);
  
  // Text Colors
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textPrimaryDark = Color(0xFFE8E8E8);
  
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  
  // Accent Colors - Sophisticated Palette
  static const Color accentPurple = Color(0xFF8B5CF6); // Violet
  static const Color accentOrange = Color(0xFFFF8A65); // Coral Orange
  static const Color accentBlue = Color(0xFF3B82F6); // Bright Blue
  static const Color accentGreen = Color(0xFF10B981); // Emerald
  static const Color accentRose = Color(0xFFEC4899); // Rose Pink
  
  // Status Colors
  static const Color success = Color(0xFF059669); // Green
  static const Color warning = Color(0xFFD97706); // Amber
  static const Color error = Color(0xFFDC2626); // Red
  static const Color info = Color(0xFF2563EB); // Blue
  static const Color lightStatusError = Color(0xFFDC2626); // Light theme error color
  static const Color lightStatusWarning = Color(0xFFD97706); // Light theme warning color
  
  // Neutral Colors
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF171717);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, Color(0xFF008B7A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryLight, Color(0xFFFFE55C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentPurple, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x3A000000);
  
  // Border Colors
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF374151);
  
  // Shimmer Colors
  static const Color shimmerBaseLight = Color(0xFFE5E7EB);
  static const Color shimmerHighlightLight = Color(0xFFF9FAFB);
  static const Color shimmerBaseDark = Color(0xFF374151);
  static const Color shimmerHighlightDark = Color(0xFF4B5563);
  
  // Additional missing colors
  static const Color surface = surfaceLight;
  static const Color onSurface = textPrimaryLight;
  static const Color onSurfaceDark = textPrimaryDark;
  static const Color lightShadow = shadowLight;
  static const Color darkShadow = shadowDark;
  
  // Additional gradients
  static const List<Color> lightGradientSecondary = [secondaryLight, Color(0xFFFFE55C)];
  static const List<Color> darkGradientSecondary = [secondaryDark, Color(0xFFFFE55C)];
  
  // Missing getters for gradients
  static const List<Color> darkGradientPrimary = [primaryDark, Color(0xFF008B7A)];
  static const List<Color> lightGradientPrimary = [primaryLight, Color(0xFF008B7A)];
  
  // Missing text colors
  static const Color darkTextSecondary = textSecondaryDark;
  static const Color lightTextSecondary = textSecondaryLight;
  static const Color darkTextPrimary = textPrimaryDark;
  static const Color lightTextPrimary = textPrimaryLight;
  
  // Missing accent colors
  static const Color darkAccentPrimary = accentPurple;
  static const Color lightAccentPrimary = accentBlue;
  static const Color darkAccentSecondary = accentOrange;
  static const Color lightAccentSecondary = accentGreen;
  
  // Additional missing getters from errors
  static const Color lightSurface = surfaceLight;
  static const Color darkSurface = surfaceDark;
  static const Color lightBorder = borderLight;
  static const Color darkBorder = borderDark;
  static const Color lightStatusSuccess = success;
  static const Color lightStatusInfo = info;
  static const Color darkStatusInfo = info;
  static const Color darkStatusSuccess = success;
  static const Color darkStatusError = error;
  static const Color darkStatusWarning = warning;
  
  // Primary getter for compatibility
  static const Color primary = primaryLight;
}