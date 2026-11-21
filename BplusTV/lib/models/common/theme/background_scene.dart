import 'package:bplus_tv/models/common/enum_with_label.dart';
import 'package:material_ui/material_ui.dart';

const Map<BackgroundScene, List<int>> _hues = {
  BackgroundScene.aurora: [0xFF42A5F5, 0xFF00E5A0, 0xFF7C4DFF],
  BackgroundScene.twilight: [0xFF3D5AFE, 0xFFD500F9, 0xFFFF6E40],
  BackgroundScene.ocean: [0xFF00B8D4, 0xFF1565C0, 0xFF0D47A1],
  BackgroundScene.sunrise: [0xFFFF8A65, 0xFFFFB300, 0xFFF4511E],
  BackgroundScene.peach: [0xFFF48FB1, 0xFFFF7043, 0xFFFFAB40],
  BackgroundScene.nebula: [0xFF5C6BC0, 0xFF4527A0, 0xFF1A237E],
};

/// The wallpaper shown on the very back layer of the main page.
///
/// Each preset is a hue-tinted gradient built from the active [ColorScheme] so
/// it follows the app theme (light/dark, accent color) while keeping its own
/// iOS-style character. [none] disables the wallpaper.
enum BackgroundScene implements EnumWithLabel {
  none('关闭'),
  aurora('极光'),
  twilight('暮光'),
  ocean('海洋'),
  sunrise('日出'),
  peach('蜜桃'),
  nebula('星云');

  @override
  final String label;
  const BackgroundScene(this.label);

  /// The [LinearGradient] for this scene, or `null` when the wallpaper is off.
  LinearGradient? gradient(ColorScheme colorScheme) {
    if (this == none) return null;
    final dark = colorScheme.brightness == Brightness.dark;
    final roles = [
      colorScheme.primary,
      colorScheme.tertiary,
      colorScheme.primaryContainer,
    ];
    final hues = _hues[this]!;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        for (var i = 0; i < hues.length; i++)
          Color.lerp(roles[i], Color(hues[i]), 0.65)!.withValues(
            alpha: dark ? 0.55 : 0.5,
          ),
      ],
    );
  }
}
