import 'package:bplus_tv/pages/setting/widgets/tv_setting_tile.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;

class NormalItem extends StatefulWidget {
  final String? title;
  final ValueGetter<String>? getTitle;
  final String? subtitle;
  final ValueGetter<String>? getSubtitle;
  final Widget? leading;
  final Widget Function(ThemeData theme)? getTrailing;
  final void Function(BuildContext context, VoidCallback setState)? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? titleStyle;

  const NormalItem({
    this.title,
    this.getTitle,
    this.subtitle,
    this.getSubtitle,
    this.leading,
    this.getTrailing,
    this.onTap,
    this.contentPadding,
    this.titleStyle,
    super.key,
  }) : assert(title != null || getTitle != null);

  @override
  State<NormalItem> createState() => _NormalItemState();
}

class _NormalItemState extends State<NormalItem> {
  @override
  Widget build(BuildContext context) {
    final description = widget.subtitle ?? widget.getSubtitle?.call();
    return TvSettingTile(
      title: Text(widget.title ?? widget.getTitle!()),
      subtitle: description == null ? null : Text(description),
      leading: widget.leading,
      trailing:
          widget.getTrailing?.call(Theme.of(context)) ??
          (widget.onTap == null
              ? null
              : const Icon(Icons.chevron_right_rounded)),
      onTap: widget.onTap == null
          ? null
          : () => widget.onTap!(context, refresh),
    );
  }

  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }
}
