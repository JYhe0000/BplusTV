import 'package:PiliPlus/tv/tv_focus.dart';
import 'package:material_ui/material_ui.dart';

/// TV-native player header: back button + title, large and D-pad focusable.
class TvHeaderControl extends StatelessWidget {
  const TvHeaderControl({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.transparent, Color(0xB3000000)],
        ),
      ),
      child: Row(
        children: [
          TvFocusable(
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            builder: (context, focused, hovered) => TvFocusHighlight(
              radius: 12,
              focused: focused,
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: focused ? 0.22 : 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
