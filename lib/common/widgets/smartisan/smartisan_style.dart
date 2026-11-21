import 'package:bplus_tv/smartisan/smartisan_material_theme.dart';
import 'package:bplus_tv/smartisan/smartisan_palette.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bplus_tv/utils/font_utils.dart';
import 'package:bplus_tv/utils/storage_pref.dart';

/// Design tokens and ThemeData for the Smartisan OS 8 skin.
///
/// The full ThemeData comes from the Smartisan OS UI Kit (`lib/smartisan/`);
/// these constants are the small subset used by the app's surface, background
/// and settings-row adapters so they stay in sync with the kit palette.
abstract final class SmartisanStyle {
  static bool get enabled => Pref.uiStyle.isSmartisan;

  static bool of(BuildContext context) =>
      Theme.of(context).extension<SPalette>() != null;

  // ------------------------------------------------------------------- light

  static const Color accent = Color(0xFF5B87EB);
  static const Color accentPressed = Color(0xFF4772E6);
  static const Color accentStroke = Color(0xFF3F68E2);
  static const Color accentText = Color(0xFF5079D9);
  static const Color brandRed = Color(0xFFCD3F3A);
  static const Color page = Color(0xFFF5F5F5);
  static const Color pageStripe = Color(0xFFEEEEEE);
  static const Color card = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFF2F2F2);
  static const Color stroke = Color(0xFFE2E2E2);
  static const Color text = Color(0xFF333333);
  static const Color titleText = Color(0xFF636363);
  static const Color secondaryText = Color(0xFF7F7F7F);
  static const Color tertiaryText = Color(0xFF9D9D9D);
  static const Color disabledText = Color(0xFFBABABA);
  static const Color iconGrey = Color(0xFF929292);

  // -------------------------------------------------------------------- dark
  // The system itself has no dark theme; these are derived with the same
  // low-contrast / hairline logic.

  static const Color darkPage = Color(0xFF161616);
  static const Color darkPageStripe = Color(0xFF1A1A1A);
  static const Color darkCard = Color(0xFF1F1F1F);
  static const Color darkDivider = Color(0xFF2A2A2A);
  static const Color darkStroke = Color(0xFF333333);
  static const Color darkText = Color(0xFFE8E8E8);
  static const Color darkTitle = Color(0xFFC9C9C9);
  static const Color darkSecondary = Color(0xFF9D9D9D);
  static const Color darkDisabled = Color(0xFF5E5E5E);
  static const Color darkAccent = Color(0xFF6E94F0);
  static const Color darkAccentText = Color(0xFF7FA0F0);

  /// Selected / focused list row on the real device (whole row `#e5eeff`).
  static const Color rowSelected = Color(0xFFE5EEFF);

  static Color rowSelectedOf(Brightness brightness) =>
      brightness == .dark ? darkAccent.withValues(alpha: 0.22) : rowSelected;

  // ---------------------------------------------------------------- geometry

  static const double cardRadius = 10;
  static const double dialogRadius = 12;
  static const double sheetRadius = 20;
  static const double buttonRadius = 10;
  static const double smallRadius = 6;
  static const double hairline = 0.8;

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 16,
      offset: Offset(0, 10),
    ),
  ];

  static Color pageOf(Brightness brightness) =>
      brightness == Brightness.dark ? darkPage : page;

  static Color stripeOf(Brightness brightness) =>
      brightness == Brightness.dark ? darkPageStripe : pageStripe;

  static Color cardOf(Brightness brightness) =>
      brightness == Brightness.dark ? darkCard : card;

  static Color strokeOf(Brightness brightness) =>
      brightness == Brightness.dark ? darkStroke : stroke;

  static Color dividerOf(Brightness brightness) =>
      brightness == Brightness.dark ? darkDivider : divider;

  static Color textOf(Brightness brightness) =>
      brightness == Brightness.dark ? darkText : text;

  static Color titleOf(Brightness brightness) =>
      brightness == Brightness.dark ? darkTitle : titleText;

  static Color secondaryOf(Brightness brightness) =>
      brightness == Brightness.dark ? darkSecondary : secondaryText;

  static Color accentOf(Brightness brightness) =>
      brightness == Brightness.dark ? darkAccent : accent;

  static Color accentTextOf(Brightness brightness) =>
      brightness == Brightness.dark ? darkAccentText : accentText;

  // ------------------------------------------------------------------- theme

  /// The kit's complete `ThemeData`: grey page, white hairline cards, centred
  /// grey bar titles, no ripple, gradient primary buttons, recessed sliders,
  /// Smartisan dialogs/sheets/menus and horizontal page transitions.
  static ThemeData themeData({required bool isDark}) =>
      SmartisanMaterialTheme.build(
        isDark: isDark,
        accent: accent,
        fontFamily: FontUtils.fontFamily,
        fontWeight: Pref.appFontWeight,
      );

  static BorderRadius get cardBorder =>
      const BorderRadius.all(Radius.circular(cardRadius));
}
