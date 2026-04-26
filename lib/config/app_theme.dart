import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
class AppColors {
  // Surfaces
  static const Color bg       = Color(0xFFF6F3EE);
  static const Color bg2      = Color(0xFFEEE9E0);
  static const Color card     = Color(0xFFFFFFFF);
  static const Color cardAlt  = Color(0xFFFBF8F2);

  // Ink (text / icons)
  static const Color ink      = Color(0xFF1F1D1A);
  static const Color ink2     = Color(0xFF413E39);
  static const Color ink3     = Color(0xFF7A746C);
  static const Color ink4     = Color(0xFFA8A29A);

  // Borders / dividers
  static const Color line     = Color(0x141F1D1A);  // ~8 % opacity
  static const Color line2    = Color(0x241F1D1A);  // ~14% opacity

  // Brand — sage
  static const Color sage     = Color(0xFF7F9778);
  static const Color sageDeep = Color(0xFF5E7658);
  static const Color sageSoft = Color(0xFFC7D4C1);
  static const Color sageBg   = Color(0xFFE8EEE4);

  // Accent — clay / warm
  static const Color clay     = Color(0xFFC7A68A);
  static const Color claySoft = Color(0xFFE9D9C7);
  static const Color stone    = Color(0xFFBFB5A7);

  // Semantic
  static const Color success  = Color(0xFF7F9778);
  static const Color warn     = Color(0xFFC89968);
  static const Color danger   = Color(0xFFC4756B);
  static const Color dangerBg = Color(0xFFF7E5E2);
}

// ── Shadows ───────────────────────────────────────────────────────────────────
class AppShadows {
  static const List<BoxShadow> sh1 = [
    BoxShadow(color: Color(0x0A1F1D1A), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A1F1D1A), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> sh2 = [
    BoxShadow(color: Color(0x0F1F1D1A), blurRadius: 6, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x0F1F1D1A), blurRadius: 28, offset: Offset(0, 10)),
  ];
  static const List<BoxShadow> sh3 = [
    BoxShadow(color: Color(0x1A1F1D1A), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x141F1D1A), blurRadius: 60, offset: Offset(0, 20)),
  ];
}

// ── Radii ─────────────────────────────────────────────────────────────────────
class AppRadius {
  static const double xs   = 8;
  static const double sm   = 12;
  static const double md   = 18;
  static const double lg   = 24;
  static const double xl   = 32;
  static const double pill = 999;
}

// ── Typography helpers ────────────────────────────────────────────────────────
class AppText {
  static TextStyle body({
    double size = 15,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double? height,
    double letterSpacing = -0.01,
  }) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle display({
    double size = 28,
    Color color = AppColors.ink,
    FontStyle style = FontStyle.italic,
    double letterSpacing = -0.03,
  }) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: FontWeight.w400,
        fontStyle: style,
        color: color,
        letterSpacing: letterSpacing * size,
      );

  static TextStyle label({
    double size = 11,
    Color color = AppColors.ink3,
    double letterSpacing = 2,
  }) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: letterSpacing,
      );
}

// ── Full Material Theme ───────────────────────────────────────────────────────
ThemeData buildAppTheme() {
  final base = GoogleFonts.dmSansTextTheme();

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.sage,
      onPrimary: Colors.white,
      secondary: AppColors.clay,
      onSecondary: Colors.white,
      surface: AppColors.card,
      onSurface: AppColors.ink,
      error: AppColors.danger,
      onError: Colors.white,
      outline: AppColors.line2,
    ),
    scaffoldBackgroundColor: AppColors.bg,

    // Typography
    textTheme: base.copyWith(
      displayLarge: AppText.display(size: 48),
      displayMedium: AppText.display(size: 36),
      displaySmall: AppText.display(size: 28),
      headlineLarge: AppText.body(size: 24, weight: FontWeight.w600),
      headlineMedium: AppText.body(size: 20, weight: FontWeight.w600),
      headlineSmall: AppText.body(size: 18, weight: FontWeight.w600),
      titleLarge: AppText.body(size: 17, weight: FontWeight.w500),
      titleMedium: AppText.body(size: 15, weight: FontWeight.w500),
      titleSmall: AppText.body(size: 13, weight: FontWeight.w500),
      bodyLarge: AppText.body(size: 16),
      bodyMedium: AppText.body(size: 14),
      bodySmall: AppText.body(size: 13, color: AppColors.ink3),
      labelLarge: AppText.body(size: 15, weight: FontWeight.w500),
      labelMedium: AppText.body(size: 13, weight: FontWeight.w500),
      labelSmall: AppText.label(),
    ),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: AppText.body(size: 17, weight: FontWeight.w600),
      iconTheme: const IconThemeData(color: AppColors.ink, size: 24),
    ),

    // Cards
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),

    // Dividers
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 0,
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.line, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.sage, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      hintStyle: AppText.body(size: 15, color: AppColors.ink4),
      labelStyle: AppText.body(size: 15, color: AppColors.ink3),
    ),

    // Elevated buttons → primary dark ink
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        textStyle: AppText.body(size: 16, weight: FontWeight.w500),
      ),
    ),

    // Text buttons
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        textStyle: AppText.body(size: 14, weight: FontWeight.w500),
      ),
    ),

    // Outlined buttons
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.line2, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        minimumSize: const Size(double.infinity, 56),
        textStyle: AppText.body(size: 16, weight: FontWeight.w500),
      ),
    ),

    // Bottom navigation bar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: AppColors.ink,
      unselectedItemColor: AppColors.ink4,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 10),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),

    // Snack bars
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: AppText.body(size: 14, color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // Dialogs
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      elevation: 0,
      titleTextStyle: AppText.body(size: 18, weight: FontWeight.w600),
      contentTextStyle: AppText.body(size: 15, color: AppColors.ink2),
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.bg2,
      selectedColor: AppColors.ink,
      labelStyle: AppText.body(size: 13, weight: FontWeight.w500),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),

    // Progress indicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.sage,
    ),

    // FloatingActionButton
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.ink,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}

// ── Shared Input Field ────────────────────────────────────────────────────────

class PilateField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const PilateField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.sh1,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: AppText.body(size: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppText.body(size: 15, color: AppColors.ink4),
          prefixIcon: Icon(icon, color: AppColors.ink3, size: 20),
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.line, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.line, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.sage, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.danger, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ── Reusable Widget Helpers ───────────────────────────────────────────────────

/// Pill-shaped tag / chip
class AppTag extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;
  final double fontSize;

  const AppTag({
    super.key,
    required this.label,
    this.background = AppColors.sageBg,
    this.textColor = AppColors.sageDeep,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppText.body(size: fontSize, weight: FontWeight.w500, color: textColor),
      ),
    );
  }
}

/// Section header with optional action
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title, style: AppText.body(size: 18, weight: FontWeight.w600)),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: AppText.body(size: 13, color: AppColors.ink3)),
            ),
        ],
      ),
    );
  }
}

/// Styled card with warm shadow
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final double? borderRadius;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadows;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
    this.onTap,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.lg),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color ?? AppColors.card,
            borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.lg),
            boxShadow: shadows ?? AppShadows.sh1,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Primary dark button (pill shaped)
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? leading;
  final Widget? trailing;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.ink,
          foregroundColor: textColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 8)],
                  Text(label,
                      style: AppText.body(size: 16, weight: FontWeight.w500, color: textColor ?? Colors.white)),
                  if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                ],
              ),
      ),
    );
  }
}

/// Sage soft button
class AppButtonSoft extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? background;
  final Color? foreground;

  const AppButtonSoft({
    super.key,
    required this.label,
    this.onPressed,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: background ?? AppColors.sageBg,
          foregroundColor: foreground ?? AppColors.sageDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Text(
          label,
          style: AppText.body(size: 14, weight: FontWeight.w500, color: foreground ?? AppColors.sageDeep),
        ),
      ),
    );
  }
}

/// Stat widget used in Profile
class StatBox extends StatelessWidget {
  final String value;
  final String label;

  const StatBox({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppText.display(size: 28)),
        const SizedBox(height: 3),
        Text(label, style: AppText.body(size: 11, color: AppColors.ink3)),
      ],
    );
  }
}

/// Niveau color helper
Color niveauColor(String niveau) {
  switch (niveau) {
    case 'Avancé':
      return AppColors.danger;
    case 'Intermédiaire':
      return AppColors.warn;
    default:
      return AppColors.sage;
  }
}

Color niveauBg(String niveau) {
  switch (niveau) {
    case 'Avancé':
      return AppColors.dangerBg;
    case 'Intermédiaire':
      return const Color(0xFFF3E6D4);
    default:
      return AppColors.sageBg;
  }
}
