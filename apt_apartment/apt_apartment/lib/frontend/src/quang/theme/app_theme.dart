import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFF0F766E);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    );

    return _base(
      colorScheme: colorScheme,
      overlayStyle: SystemUiOverlayStyle.dark,
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );

    return _base(
      colorScheme: colorScheme,
      overlayStyle: SystemUiOverlayStyle.light,
    );
  }

  static ThemeData _base({
    required ColorScheme colorScheme,
    required SystemUiOverlayStyle overlayStyle,
  }) {
    final radius = BorderRadius.circular(20);
    final inputRadius = BorderRadius.circular(18);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface.withValues(alpha: 0.92),
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: overlayStyle,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface.withValues(alpha: 0.86),
        shape: RoundedRectangleBorder(borderRadius: radius),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface.withValues(alpha: 0.96),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: radius.topLeft),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        shape: StadiumBorder(
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.50),
          ),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurface),
        secondaryLabelStyle: TextStyle(color: colorScheme.onSurface),
        backgroundColor: colorScheme.surface.withValues(alpha: 0.70),
        selectedColor: colorScheme.primary.withValues(alpha: 0.18),
        checkmarkColor: colorScheme.primary,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.75),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface.withValues(alpha: 0.90),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: const StadiumBorder(),
          side: BorderSide(color: colorScheme.outlineVariant),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  static Decoration appBackground(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final top = isDark
        ? scheme.primary.withValues(alpha: 0.14)
        : scheme.primary.withValues(alpha: 0.10);
    final bottom = isDark
        ? scheme.surface.withValues(alpha: 0.98)
        : scheme.surface.withValues(alpha: 0.98);

    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          top,
          bottom,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }
}
