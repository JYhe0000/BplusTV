import 'package:bplus_tv/common/widgets/smartisan/smartisan_style.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_constants.dart';
import 'package:material_ui/material_ui.dart';

/// One remote target per setting, with a stable, high-contrast reading surface.
class TvSettingTile extends StatelessWidget {
  const TvSettingTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final smartisan = SmartisanStyle.of(context);
    final brightness = theme.brightness;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final radius = smartisan ? SmartisanStyle.cardRadius : 20.0;
    final titleStyle =
        (smartisan ? theme.textTheme.titleMedium! : theme.textTheme.titleLarge!)
            .copyWith(fontSize: smartisan ? 16 : 18);
    final subtitleStyle =
        (smartisan ? theme.textTheme.bodySmall! : theme.textTheme.bodyLarge!)
            .copyWith(fontSize: smartisan ? 13 : 14);
    final minHeight = smartisan
        ? 52.0
        : TvConstants.settingRowMinHeight(viewportHeight);
    return TvFocusable(
      canRequestFocus: enabled && onTap != null,
      onTap: enabled ? onTap : null,
      builder: (context, focused, hovered) {
        final borderColor = focused
            ? (smartisan ? SmartisanStyle.accentOf(brightness) : scheme.primary)
            : smartisan
            ? SmartisanStyle.strokeOf(brightness)
            : scheme.outlineVariant;
        final fill = smartisan
            ? (focused
                  ? SmartisanStyle.rowSelectedOf(brightness)
                  : SmartisanStyle.cardOf(brightness))
            : (focused
                  ? scheme.surfaceContainerHighest
                  : scheme.surfaceContainerLow);
        // 保留各风格的底色与排版，焦点描边统一使用公共组件。
        return TvFocusHighlight(
          focused: focused,
          radius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(
              minHeight: minHeight,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: smartisan ? 10 : 14,
              vertical: smartisan ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: borderColor,
                width: focused
                    ? 1.5
                    : smartisan
                    ? SmartisanStyle.hairline
                    : 0.8,
              ),
              boxShadow: smartisan && !focused
                  ? SmartisanStyle.cardShadow
                  : null,
            ),
            child: ExcludeFocus(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final stackTrailing = constraints.maxWidth < 300;
                  final text = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DefaultTextStyle(
                        style: titleStyle.copyWith(
                          color: enabled
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                        ),
                        child: title,
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: smartisan ? 2 : 4),
                        DefaultTextStyle(
                          style: subtitleStyle.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          child: subtitle!,
                        ),
                      ],
                    ],
                  );
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          if (leading != null) ...[
                            IconTheme(
                              data: IconThemeData(
                                size: smartisan ? 20 : 24,
                                color: enabled
                                    ? (smartisan
                                          ? SmartisanStyle.iconGrey
                                          : scheme.onSurface)
                                    : scheme.onSurfaceVariant,
                              ),
                              child: leading!,
                            ),
                            SizedBox(width: smartisan ? 10 : 14),
                          ],
                          Expanded(child: text),
                          if (trailing != null && !stackTrailing) ...[
                            SizedBox(width: smartisan ? 10 : 18),
                            trailing!,
                          ],
                        ],
                      ),
                      if (trailing != null && stackTrailing) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: trailing,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
