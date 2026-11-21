import 'package:bplus_tv/pages/setting/widgets/tv_setting_tile.dart';
import 'package:bplus_tv/models/common/enum_with_label.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/tv/tv_focus_card.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;

typedef PopupMenuItemSelected<T> = void Function(
  T value,
  VoidCallback setState,
);

List<PopupMenuEntry<T>> enumItemBuilder<T extends EnumWithLabel>(
  Iterable<T> items,
) => items.map((e) => PopupMenuItem(value: e, child: Text(e.label))).toList();

enum DescPosType { subtitle, title, trailing }

class PopupListTile<T> extends StatefulWidget {
  const PopupListTile({
    super.key,
    this.dense,
    this.safeArea = true,
    this.enabled = true,
    this.leading,
    required this.title,
    this.descPosType = .subtitle,
    required this.value,
    required this.itemBuilder,
    required this.onSelected,
    this.titleStyle,
    this.descStyle,
  });

  final bool? dense;
  final bool safeArea;
  final bool enabled;
  final Widget? leading;
  final Widget title;

  final DescPosType descPosType;
  final ValueGetter<(T, String)> value;
  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T> onSelected;
  final TextStyle? titleStyle;
  final TextStyle? descStyle;

  @override
  State<PopupListTile<T>> createState() => _PopupListTileState<T>();
}

class _PopupListTileState<T> extends State<PopupListTile<T>> {
  // TV remotes only emit a synthetic "tap" (OK) — no TapUpDetails — and the
  // popup menu's positioning + requestFocus:false made it un-focusable on a
  // D-pad. Instead, open a TV dialog with a scrollable radio list that
  // the remote can traverse and confirm.
  Future<void> _showTvMenu(T currentValue) async {
    final titleStr = widget.title is Text
        ? ((widget.title as Text).data ?? '选择')
        : '选择';
    final entries = widget
        .itemBuilder(context)
        .whereType<PopupMenuItem<T>>()
        .toList(growable: false);
    final hasSelected = entries.any((e) => e.value == currentValue);
    final result = await showDialog<T>(
      context: context,
      builder: (context) => tvDialogShell(
        title: titleStr,
        minWidth: 400,
        maxWidth: 480,
        maxHeight: 560,
        content: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: RadioGroup<T>(
            groupValue: currentValue,
            onChanged: (v) => Navigator.of(context).pop(v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < entries.length; i++)
                  TvFocusRing(
                    enabled: true,
                    radius: 12,
                    child: RadioListTile<T>(
                      dense: false,
                      value: entries[i].value as T,
                      title: entries[i].child,
                      subtitle: null,
                      autofocus: hasSelected
                          ? entries[i].value == currentValue
                          : i == 0,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || result == null || result == currentValue) return;
    widget.onSelected(result, _refresh);
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (value, descStr) = widget.value();
    Widget title = widget.title;
    Widget? subtitle;
    Widget? trailing;
    final desc = Text(
      descStr,
      style: (widget.descStyle ?? theme.textTheme.bodyLarge!).copyWith(
        color: widget.enabled
            ? theme.colorScheme.secondary
            : theme.disabledColor,
      ),
    );
    switch (widget.descPosType) {
      case DescPosType.subtitle:
        subtitle = desc;
      case DescPosType.title:
        title = Row(
          spacing: 12,
          mainAxisSize: .min,
          children: [title, desc],
        );
      case DescPosType.trailing:
        trailing = desc;
    }
    return TvSettingTile(
      enabled: widget.enabled,
      onTap: () => _showTvMenu(value),
      leading: widget.leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
    );
  }
}
