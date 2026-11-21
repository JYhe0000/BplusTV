import 'package:bplus_tv/utils/font_utils.dart';
import 'package:bplus_tv/utils/storage_pref.dart';
import 'package:material_ui/material_ui.dart';

/// 默认 TV 主题：紧凑黑灰面板、白色焦点和红色强调。
abstract final class NetflixStyle {
  static const double radius = 6;
  static const double navRadius = 8;
  static const double panelRadius = 8;

  static const Color accent = Color(0xFFE50914);
  static const Color page = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF181818);
  static const Color nav = Color(0xFF141414);
  static const Color panel = Color(0xFF222222);
  static const Color stroke = Color(0xFF383838);
  static const Color text = Color(0xFFFFFFFF);
  static const Color secondaryText = Color(0xFFB3B3B3);
  static const Color disabledText = Color(0xFF737373);
  static const Color focus = Color(0xFFFFFFFF);

  static const ColorScheme _colorScheme = ColorScheme.dark(
    primary: accent,
    onPrimary: text,
    primaryContainer: Color(0xFF57080D),
    onPrimaryContainer: text,
    secondary: text,
    onSecondary: page,
    secondaryContainer: panel,
    onSecondaryContainer: text,
    tertiary: secondaryText,
    onTertiary: page,
    tertiaryContainer: panel,
    onTertiaryContainer: text,
    error: Color(0xFFFF6B6B),
    onError: page,
    errorContainer: Color(0xFF57080D),
    onErrorContainer: text,
    surface: surface,
    onSurface: text,
    onSurfaceVariant: secondaryText,
    surfaceDim: page,
    surfaceBright: Color(0xFF333333),
    surfaceContainerLowest: page,
    surfaceContainerLow: nav,
    surfaceContainer: surface,
    surfaceContainerHigh: panel,
    surfaceContainerHighest: Color(0xFF333333),
    outline: disabledText,
    outlineVariant: stroke,
    inverseSurface: text,
    onInverseSurface: page,
    inversePrimary: accent,
    surfaceTint: Colors.transparent,
  );

  static ThemeData themeData() {
    final fontFamily = FontUtils.fontFamily;
    final fontWeight = Pref.appFontWeight;
    TextStyle type(double size, {Color color = text}) => TextStyle(
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      fontSize: size,
      color: color,
    );

    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
    );
    const panelShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(panelRadius)),
      side: BorderSide(color: stroke),
    );
    final focusSide = WidgetStateProperty.resolveWith<BorderSide>((states) {
      if (states.contains(WidgetState.disabled)) {
        return const BorderSide(color: stroke, width: 2);
      }
      return BorderSide(
        color: states.contains(WidgetState.focused) ? focus : stroke,
        width: 2,
      );
    });
    final overlay = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.disabled)) return Colors.transparent;
      if (states.contains(WidgetState.pressed)) {
        return const Color(0x33FFFFFF);
      }
      if (states.contains(WidgetState.focused)) {
        return const Color(0x29FFFFFF);
      }
      if (states.contains(WidgetState.hovered)) {
        return const Color(0x14FFFFFF);
      }
      return Colors.transparent;
    });
    final buttonStyle = ButtonStyle(
      visualDensity: VisualDensity.compact,
      minimumSize: const WidgetStatePropertyAll(Size(40, 36)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      textStyle: WidgetStatePropertyAll(type(14)),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.disabled) ? disabledText : text;
      }),
      shape: const WidgetStatePropertyAll(shape),
      side: focusSide,
      overlayColor: overlay,
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    );
    final primaryButton = buttonStyle.copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.disabled) ? panel : accent;
      }),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _colorScheme,
      fontFamily: fontFamily,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      scaffoldBackgroundColor: page,
      canvasColor: page,
      cardColor: surface,
      dividerColor: stroke,
      disabledColor: disabledText,
      hintColor: secondaryText,
      focusColor: const Color(0x33FFFFFF),
      hoverColor: const Color(0x14FFFFFF),
      splashFactory: NoSplash.splashFactory,
      textTheme: TextTheme(
        displayLarge: type(36),
        displayMedium: type(32),
        displaySmall: type(28),
        headlineLarge: type(26),
        headlineMedium: type(24),
        headlineSmall: type(22),
        titleLarge: type(18),
        titleMedium: type(16),
        titleSmall: type(14),
        bodyLarge: type(15),
        bodyMedium: type(14),
        bodySmall: type(12, color: secondaryText),
        labelLarge: type(14),
        labelMedium: type(12),
        labelSmall: type(11, color: secondaryText),
      ),
      iconTheme: const IconThemeData(color: text, size: 22),
      primaryIconTheme: const IconThemeData(color: text, size: 22),
      appBarTheme: AppBarThemeData(
        backgroundColor: page,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 12,
        toolbarHeight: 48,
        centerTitle: false,
        titleTextStyle: type(16),
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(style: primaryButton),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
      outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle),
      textButtonTheme: TextButtonThemeData(style: buttonStyle),
      iconButtonTheme: IconButtonThemeData(
        style: buttonStyle.copyWith(
          padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        hintStyle: type(14, color: secondaryText),
        labelStyle: type(14, color: secondaryText),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(radius)),
          borderSide: BorderSide(color: stroke),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(radius)),
          borderSide: BorderSide(color: stroke),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(radius)),
          borderSide: BorderSide(color: focus, width: 2),
        ),
      ),
      listTileTheme: ListTileThemeData(
        dense: true,
        minVerticalPadding: 6,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        textColor: text,
        iconColor: secondaryText,
        selectedColor: text,
        selectedTileColor: panel,
        shape: shape,
        titleTextStyle: type(14),
        subtitleTextStyle: type(12, color: secondaryText),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: panelShape,
        titleTextStyle: type(18),
        contentTextStyle: type(14),
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 480),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: panelShape,
        clipBehavior: Clip.antiAlias,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: panel,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: panelShape,
        textStyle: type(14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: nav,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 56,
        indicatorColor: panel,
        labelTextStyle: WidgetStatePropertyAll(type(12)),
        iconTheme: const WidgetStatePropertyAll(IconThemeData(color: text)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: nav,
        indicatorColor: panel,
        selectedIconTheme: const IconThemeData(color: text, size: 24),
        unselectedIconTheme: const IconThemeData(
          color: secondaryText,
          size: 22,
        ),
        selectedLabelTextStyle: type(12),
        unselectedLabelTextStyle: type(12, color: secondaryText),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: stroke,
        circularTrackColor: stroke,
        refreshBackgroundColor: panel,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: stroke,
        thumbColor: text,
        overlayColor: Color(0x33FFFFFF),
        trackHeight: 3,
      ),
      switchTheme: const SwitchThemeData(
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        shape: Border(),
        collapsedShape: Border(),
        textColor: text,
        collapsedTextColor: text,
        iconColor: text,
        collapsedIconColor: secondaryText,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: panel,
        actionTextColor: text,
        closeIconColor: text,
        contentTextStyle: type(14),
        shape: shape,
        elevation: 0,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.all(Radius.circular(radius)),
        ),
        textStyle: type(12),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: text,
        selectionColor: Color(0x66E50914),
        selectionHandleColor: text,
      ),
    );
  }
}
