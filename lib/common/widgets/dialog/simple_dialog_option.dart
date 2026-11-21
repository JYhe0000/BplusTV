import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:material_ui/material_ui.dart';

const EdgeInsets _padding = .symmetric(horizontal: 16, vertical: 14);

class DialogOption extends StatelessWidget {
  const DialogOption({
    super.key,
    this.onPressed,
    this.child,
  });

  final VoidCallback? onPressed;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onTap: onPressed,
      canRequestFocus: onPressed != null,
      builder: (context, focused, _) => TvFocusHighlight(
        focused: focused,
        radius: 8,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: _padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
