import 'package:flutter/material.dart';

/// Unified design system for CommNEUcate
class AppTheme {
  // Colors
  static const Color background = Color(0xFF07070E);
  static const Color surface = Color(0xFF111120);
  static const Color surfaceElevated = Color(0xFF1A1A2E);
  static const Color surfaceHover = Color(0xFF1E1E32);
  static const Color border = Color(0x1AFFFFFF);
  static const Color borderHover = Color(0x33FFFFFF);

  static const Color primary = Color(0xFF7C6AFF);
  static const Color primaryLight = Color(0xFFA99BFF);
  static const Color primaryDark = Color(0xFF5B4DCC);
  static const Color primaryContainer = Color(0xFF2A245E);

  static const Color secondary = Color(0xFF0FE0B0);
  static const Color secondaryLight = Color(0xFF4FF5D1);
  static const Color secondaryDark = Color(0xFF0CC495);
  static const Color secondaryContainer = Color(0xFF0A4D3A);

  static const Color accent = Color(0xFFF5A623);
  static const Color error = Color(0xFFFF4757);
  static const Color errorContainer = Color(0xFF4D1A1D);
  static const Color success = Color(0xFF0FE0B0);
  static const Color warning = Color(0xFFF5A623);

  static const Color onBackground = Colors.white;
  static const Color onSurface = Colors.white;
  static const Color onPrimary = Color(0xFF07070E);
  static const Color onSecondary = Color(0xFF07070E);
  static const Color onError = Colors.white;

  static const Color outline = Color(0x1AFFFFFF);
  static const Color outlineVariant = Color(0x0DFFFFFF);

  // Semantic colors for specific use cases
  static const Color itemPending = Color(0xFFF5A623);
  static const Color itemApproved = Color(0xFF0FE0B0);
  static const Color itemRejected = Color(0xFFFF4757);
  static const Color itemClaimed = Color(0xFF7C6AFF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF060612), Color(0xFF10102A), Color(0xFF060F1A)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surfaceElevated],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1AFFFFFF),
      Color(0x0DFFFFFF),
    ],
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0x337C6AFF), Color(0x1F0FE0B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Spacing
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double space2xl = 48;

  // Border radius
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  // Shadows
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowGlow = [
    BoxShadow(
      color: Color(0x2E7C6AFF),
      blurRadius: 40,
      offset: Offset(0, 8),
    ),
  ];

  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  // Typography
  static const TextStyle displayLarge = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w900,
    color: onBackground,
    letterSpacing: -2,
    height: 1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 44,
    fontWeight: FontWeight.w900,
    color: onBackground,
    letterSpacing: -1.5,
    height: 1.1,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w900,
    color: onBackground,
    letterSpacing: -1,
    height: 1.2,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: onBackground,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: onBackground,
    letterSpacing: -0.25,
    height: 1.3,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: onBackground,
    height: 1.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: onBackground,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: onBackground,
    height: 1.4,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: onBackground,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: onBackground,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: onBackground,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Color(0xFFB0B0C8),
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: onBackground,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: onBackground,
    letterSpacing: 0.5,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Color(0xFFB0B0C8),
    letterSpacing: 1.2,
    height: 1.4,
  );

  // Animation durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 350);
  static const Duration durationPage = Duration(milliseconds: 400);

  // Curves
  static const Curve curveStandard = Curves.easeInOutCubic;
  static const Curve curveEmphasized = Curves.easeOutCubic;
  static const Curve curveDecelerate = Curves.easeOutQuart;
  static const Curve curveSpring = Curves.elasticOut;

  /// Get the theme data for MaterialApp
  static ThemeData get themeData {
    final colorScheme = ColorScheme.dark(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onBackground,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onBackground,
      tertiary: accent,
      onTertiary: onBackground,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onBackground,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceElevated,
      onSurfaceVariant: Color(0xFFB0B0C8),
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: Colors.black,
      scrim: Colors.black87,
      inverseSurface: Colors.white,
      onInverseSurface: background,
      inversePrimary: primaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: titleLarge,
        iconTheme: const IconThemeData(color: onBackground, size: 24),
        actionsIconTheme: const IconThemeData(color: onBackground, size: 24),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: labelLarge,
          shadowColor: primary.withValues(alpha: 0.3),
        ),
      ),

      // Filled Button (for secondary actions)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: surfaceElevated,
          foregroundColor: onBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            side: BorderSide(color: border, width: 1),
          ),
          textStyle: labelLarge,
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onBackground,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          side: BorderSide(color: border, width: 1),
          textStyle: labelLarge,
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: labelLarge,
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: bodyMedium.copyWith(color: Color(0xFF6B6B8A)),
        labelStyle: bodyMedium.copyWith(color: Color(0xFFB0B0C8)),
        errorStyle: bodySmall.copyWith(color: error),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: outlineVariant, width: 1),
        ),
        prefixIconColor: Color(0xFF6B6B8A),
        suffixIconColor: Color(0xFF6B6B8A),
      ),

      // Text Field (for TextField widget)
      textFieldTheme: TextFieldThemeData(
        decoration: InputDecorationTheme(
          filled: true,
          fillColor: surface,
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: Color(0xFF6B6B8A),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
        selectedLabelStyle: labelSmall,
        unselectedLabelStyle: labelSmall,
      ),

      // Navigation Rail
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        selectedIconTheme: const IconThemeData(color: secondary, size: 24),
        unselectedIconTheme: const IconThemeData(color: Color(0xFF6B6B8A), size: 24),
        selectedLabelTextStyle: labelSmall.copyWith(color: secondary),
        unselectedLabelTextStyle: labelSmall.copyWith(color: Color(0xFF6B6B8A)),
        labelType: NavigationRailLabelType.all,
        useIndicator: true,
        indicatorColor: secondary.withValues(alpha: 0.1),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        extendedTextStyle: labelLarge,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary.withValues(alpha: 0.2),
        disabledColor: surface.withValues(alpha: 0.5),
        labelStyle: labelMedium.copyWith(color: Color(0xFFB0B0C8)),
        secondaryLabelStyle: labelMedium.copyWith(color: primary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
          side: BorderSide(color: border, width: 1),
        ),
        side: BorderSide(color: border, width: 1),
        brightness: Brightness.dark,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleTextStyle: titleMedium,
        subtitleTextStyle: bodySmall,
        leadingAndTrailingTextStyle: bodyMedium,
        iconColor: Color(0xFF6B6B8A),
        textColor: onBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        tileColor: Colors.transparent,
        selectedTileColor: primary.withValues(alpha: 0.1),
        selectedColor: primary,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: BorderSide(color: border, width: 1),
        ),
        titleTextStyle: headlineSmall,
        contentTextStyle: bodyMedium,
        alignment: Alignment.center,
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
        modalBackgroundColor: surface,
        constraints: const BoxConstraints(maxWidth: 560),
      ),

      // Snack Bar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: bodyMedium,
        actionTextColor: primaryLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        elevation: 4,
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: surfaceElevated,
          borderRadius: BorderRadius.circular(radiusSm),
          border: Border.all(color: border, width: 1),
        ),
        textStyle: bodySmall,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        preferBelow: false,
        verticalOffset: 8,
      ),

      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surfaceElevated,
        circularTrackColor: surfaceElevated,
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: surfaceElevated,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.1),
        valueIndicatorColor: primary,
        valueIndicatorTextStyle: labelSmall.copyWith(color: onPrimary),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: Color(0xFF6B6B8A),
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: labelLarge,
        unselectedLabelStyle: labelLarge,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStatePropertyAll(primary.withValues(alpha: 0.1)),
      ),

      // Expansion Tile
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: surface,
        collapsedBackgroundColor: surface,
        textColor: onBackground,
        collapsedTextColor: onBackground,
        iconColor: Color(0xFF6B6B8A),
        collapsedIconColor: Color(0xFF6B6B8A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: border, width: 1),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: border, width: 1),
        ),
      ),
    );
  }
}