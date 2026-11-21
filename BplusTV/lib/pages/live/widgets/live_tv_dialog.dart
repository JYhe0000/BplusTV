import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:material_ui/material_ui.dart';

/// 沿用统一弹窗外观与焦点域，直播页面的关闭目标保持 48dp。
class LiveTvDialog extends StatelessWidget {
  const LiveTvDialog({
    super.key,
    required this.title,
    required this.content,
    required this.maxWidth,
    this.maxHeight = 560,
  });

  final String title;
  final Widget content;
  final double maxWidth;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return tvDialogShell(
      title: title,
      minWidth: 0,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: content),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerRight,
              child: TvFocusable(
                autofocus: true,
                onTap: () => Navigator.of(context).pop(),
                builder: (context, focused, hovered) => TvFocusHighlight(
                  focused: focused,
                  radius: 12,
                  child: const SizedBox(
                    width: 112,
                    height: 48,
                    child: Center(
                      child: Text('关闭', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
