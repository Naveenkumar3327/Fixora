import 'package:flutter/material.dart';
import 'dart:ui';

class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF06B6D4); // Electric Cyan
  static const Color secondaryColor = Color(0xFF7C3AED); // Neon Purple
  
  // Accents
  static const Color successColor = Color(0xFF84CC16); // Lime Green
  static const Color warningColor = Color(0xFFF97316); // Sunset Orange
  static const Color errorColor = Color(0xFFEF4444); // Red
  
  // Backgrounds & Surfaces
  static const Color darkBg = Color(0xFF0F172A); // Deep Midnight Blue
  static const Color darkCard = Color(0xFF1E293B); // Dark Slate Card
  static const Color textPrimary = Color(0xFFF8FAFC); // Off-White
  static const Color textSecondary = Color(0xFF94A3B8); // Cool Slate

  static ThemeData get lightTheme => darkTheme; // Enforce dark first design always

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      background: darkBg,
      surface: darkCard,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    scaffoldBackgroundColor: darkBg,
    cardTheme: CardThemeData(
      color: darkCard.withOpacity(0.6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1.2),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -1.0),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard.withOpacity(0.4),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
  );
}

// Premium Background with ambient blurred orbs
class PremiumBackground extends StatelessWidget {
  final Widget child;
  final bool showOrbs;
  final double maxWidth;

  const PremiumBackground({
    super.key,
    required this.child,
    this.showOrbs = true,
    this.maxWidth = 650,
  });

  @override
  Widget build(BuildContext context) {
    final constrainedChild = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );

    if (!showOrbs) {
      return Container(
        color: AppTheme.darkBg,
        child: constrainedChild,
      );
    }
    return Stack(
      children: [
        // Solid Midnight background
        Container(color: AppTheme.darkBg),
        // Top-Left Cyan Glow
        Positioned(
          top: -120,
          left: -120,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withOpacity(0.14),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        // Bottom-Right Purple Glow
        Positioned(
          bottom: -120,
          right: -120,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.secondaryColor.withOpacity(0.14),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        Positioned.fill(child: constrainedChild),
      ],
    );
  }
}

// Glassmorphism Frosted Container
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Border? border;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blur = 16,
    this.color,
    this.border,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: (color ?? AppTheme.darkCard).withOpacity(0.45),
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ?? Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

