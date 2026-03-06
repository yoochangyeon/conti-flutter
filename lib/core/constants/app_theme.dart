import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:conti_app/core/constants/app_spacing.dart';

// ─────────────────────────────────────────────
// Toss-inspired Design Tokens for Conti
// ─────────────────────────────────────────────
// Design principles:
//   - Light mode first, clean white backgrounds
//   - Semantic color tokens (primary, success, error)
//   - Gray scale 50-900 for clear text hierarchy
//   - Generous spacing, large touch targets
//   - Clean flat cards — no glassmorphism
// ─────────────────────────────────────────────

class AppColors {
  AppColors._();

  // ─── Brand ───
  static const Color primary = Color(0xFF3182F6);
  static const Color primaryLight = Color(0xFFEBF2FF);
  static const Color primaryDark = Color(0xFF1B64DA);

  // ─── Semantic ───
  static const Color success = Color(0xFF34C759);
  static const Color successLight = Color(0xFFE8F8EE);
  static const Color warning = Color(0xFFFF9500);
  static const Color warningLight = Color(0xFFFFF4E0);
  static const Color error = Color(0xFFFF3B30);
  static const Color errorLight = Color(0xFFFFEBEB);

  // ─── Gray Scale ───
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF2F4F6);
  static const Color gray200 = Color(0xFFE5E8EB);
  static const Color gray300 = Color(0xFFD1D6DB);
  static const Color gray400 = Color(0xFFB0B8C1);
  static const Color gray500 = Color(0xFF8B95A1);
  static const Color gray600 = Color(0xFF6B7684);
  static const Color gray700 = Color(0xFF4E5968);
  static const Color gray800 = Color(0xFF333D4B);
  static const Color gray900 = Color(0xFF191F28);

  // ─── Interaction States ───
  static const Color primaryPressed = Color(0xFF1B64DA);
  static const Color primaryDisabled = Color(0xFFB0D0FF);
  static const Color overlay = Color(0x52000000);
  static const Color dimmed = Color(0x29000000);
  static const Color skeleton = Color(0xFFF2F4F6);

  // ─── Dark Mode Surfaces ───
  static const Color darkBg = Color(0xFF17171C);
  static const Color darkSurface = Color(0xFF222228);
  static const Color darkSurfaceHigh = Color(0xFF2C2C34);
  static const Color darkDivider = Color(0xFF38383E);

  // ─── Accent palette (for charts, avatars, badges) ───
  static const Color blue = Color(0xFF3182F6);
  static const Color teal = Color(0xFF2AC1BC);
  static const Color green = Color(0xFF34C759);
  static const Color orange = Color(0xFFFF9500);
  static const Color pink = Color(0xFFFF6B6B);
  static const Color purple = Color(0xFF9B59B6);

  static const List<Color> accentPalette = [blue, teal, green, orange, pink, purple];
}

class AppTheme {
  AppTheme._();

  // ─── Legacy aliases (for gradual migration) ───
  static const Color primaryColor = AppColors.primary;
  static const Color secondaryColor = AppColors.teal;
  static const Color tertiaryColor = AppColors.pink;
  static const Color errorColor = AppColors.error;
  static const Color darkSurface = AppColors.darkBg;
  static const Color darkSurfaceContainer = AppColors.darkSurface;
  static const Color darkSurfaceContainerHigh = AppColors.darkSurfaceHigh;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [AppColors.primary, AppColors.teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [AppColors.primary, AppColors.pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [AppColors.darkBg, AppColors.darkSurface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Themes ───
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.teal,
      onSecondary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      errorContainer: AppColors.errorLight,
      surface: AppColors.white,
      onSurface: AppColors.gray900,
      onSurfaceVariant: AppColors.gray600,
      surfaceContainerLowest: AppColors.white,
      surfaceContainerLow: AppColors.gray50,
      surfaceContainer: AppColors.gray100,
      surfaceContainerHigh: AppColors.gray100,
      surfaceContainerHighest: AppColors.gray200,
      outline: AppColors.gray200,
      outlineVariant: AppColors.gray100,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: AppColors.primaryLight,
      secondary: AppColors.teal,
      onSecondary: AppColors.darkBg,
      error: AppColors.error,
      onError: AppColors.white,
      errorContainer: const Color(0xFF3D1515),
      surface: AppColors.darkBg,
      onSurface: AppColors.gray50,
      onSurfaceVariant: AppColors.gray400,
      surfaceContainerLowest: AppColors.darkBg,
      surfaceContainerLow: AppColors.darkSurface,
      surfaceContainer: AppColors.darkSurface,
      surfaceContainerHigh: AppColors.darkSurfaceHigh,
      surfaceContainerHighest: AppColors.darkSurfaceHigh,
      outline: AppColors.darkDivider,
      outlineVariant: AppColors.darkSurface,
    );
    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Pretendard',
      scaffoldBackgroundColor: isDark ? AppColors.darkBg : AppColors.gray50,

      // ─── AppBar ───
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.darkBg : AppColors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),

      // ─── Cards ───
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark ? AppColors.darkSurface : AppColors.white,
        margin: EdgeInsets.zero,
      ),

      // ─── Input Fields ───
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: AppColors.gray400,
          fontWeight: FontWeight.w400,
          fontSize: 15,
        ),
        labelStyle: const TextStyle(
          color: AppColors.gray600,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),

      // ─── Buttons ───
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          side: BorderSide(color: colorScheme.outline),
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),

      // ─── FAB ───
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),

      // ─── Chips ───
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        backgroundColor:
            isDark ? AppColors.darkSurfaceHigh : AppColors.gray100,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),

      // ─── Divider ───
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkDivider : AppColors.gray200,
        thickness: 1,
        space: 1,
      ),

      // ─── BottomSheet ───
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        surfaceTintColor: Colors.transparent,
      ),

      // ─── Dialog ───
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
        surfaceTintColor: Colors.transparent,
      ),

      // ─── SnackBar ───
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.gray800,
      ),

      // ─── TabBar ───
      tabBarTheme: TabBarThemeData(
        labelStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
        labelColor: colorScheme.onSurface,
        unselectedLabelColor: AppColors.gray400,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),

      // ─── ListTile ───
      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // ─── Typography ───
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: colorScheme.onSurface,
          height: 1.25,
        ),
        displayMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          color: colorScheme.onSurface,
          height: 1.3,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: colorScheme.onSurface,
          height: 1.35,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: colorScheme.onSurface,
          height: 1.35,
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: colorScheme.onSurface,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: colorScheme.onSurface,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isDark ? AppColors.gray300 : AppColors.gray700,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.gray500,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: colorScheme.onSurface,
          height: 1.4,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.gray600,
          height: 1.35,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.gray500,
          height: 1.3,
        ),
      ),
    );
  }
}
