import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/tv/player/tv_player_layout.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:material_ui/material_ui.dart';

/// TV-native player header: back button + title, large and D-pad focusable.
class TvHeaderControl extends StatelessWidget {
  const TvHeaderControl({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight =
            TvPlayerLayout.maybeSizeOf(context)?.height ??
            (constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : MediaQuery.sizeOf(context).height);
        final compact = constraints.maxWidth < 900 || availableHeight < 500;
        final radius = compact ? 12.0 : 16.0;
        const buttonSize = 48.0;

        return netflixPlayerSurface(
          radius: radius,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 22,
              vertical: compact ? 6 : 10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.34),
                ],
              ),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: '返回',
                  child: TvFocusable(
                    // 屏幕返回按钮直接退出，遥控器返回键才先收起控制条。
                    onTap: onBack ?? () => Navigator.of(context).pop(),
                    builder: (context, focused, hovered) => TvFocusHighlight(
                      radius: 12,
                      focused: focused,
                      borderWidth: focused ? 2.5 : 0,
                      child: SizedBox(
                        width: buttonSize,
                        height: buttonSize,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: focused ? 0.12 : 0.06,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: compact ? 21 : 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: compact ? 10 : 16),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 17 : 20,
                      fontWeight: FontWeight.w700,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
