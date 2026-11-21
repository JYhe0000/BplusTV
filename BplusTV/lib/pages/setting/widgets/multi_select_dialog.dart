import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/tv/tv_focus_card.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class MultiSelectDialog<T> extends StatefulWidget {
  final Iterable<T> initValues;
  final String title;
  final Map<T, String> values;

  const MultiSelectDialog({
    super.key,
    required this.initValues,
    required this.values,
    required this.title,
  });

  @override
  State<MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<MultiSelectDialog<T>> {
  late Set<T> _tempValues;

  @override
  void initState() {
    super.initState();
    _tempValues = widget.initValues.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Material(
      type: .transparency,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.values.entries.map((i) {
            return Builder(
              builder: (context) {
                bool isChecked = _tempValues.contains(i.key);
                return TvFocusRing(
                  enabled: true,
                  radius: 12,
                  child: CheckboxListTile(
                    dense: true,
                    value: isChecked,
                    title: Text(
                      i.value,
                      style: theme.textTheme.titleMedium!,
                    ),
                    onChanged: (value) {
                      isChecked
                          ? _tempValues.remove(i.key)
                          : _tempValues.add(i.key);
                      (context as Element).markNeedsBuild();
                    },
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
    {
      return tvDialogShell(
        title: widget.title,
        minWidth: 400,
        maxWidth: 480,
        content: content,
        actions: [
          TvDialogAction(
            label: '取消',
            onTap: Get.back,
          ),
          TvDialogAction(
            label: '确定',
            onTap: () => Get.back(result: _tempValues),
            primary: true,
          ),
        ],
      );
    }
  }
}
