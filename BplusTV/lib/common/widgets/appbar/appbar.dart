import 'package:bplus_tv/common/widgets/scaffold/bar_overrides.dart';
import 'package:bplus_tv/common/widgets/view_safe_area.dart';
import 'package:bplus_tv/pages/common/multi_select/base.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class MultiSelectAppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  final MultiSelectBase ctr;
  final bool? visible;
  final AppBar child;
  final List<Widget>? actions;

  const MultiSelectAppBarWidget({
    super.key,
    required this.ctr,
    this.visible,
    this.actions,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (visible ?? ctr.enableMultiSelect.value) {
      final style = TextButton.styleFrom(
        minimumSize: const Size(
          TvShellMetrics.minimumFocusTarget,
          TvShellMetrics.minimumFocusTarget,
        ),
      );
      final colorScheme = ColorScheme.of(context);
      return overrideAppbar(
        context,
        AppBar(
          bottom: child.bottom,
          leading: IconButton(
            tooltip: '取消',
            onPressed: ctr.handleSelect,
            icon: const Icon(Icons.close_outlined),
          ),
          title: Obx(() => Text('已选: ${ctr.checkedCount}')),
          actions: [
            TextButton(
              style: style,
              onPressed: () => ctr.handleSelect(checked: true),
              child: const Text('全选'),
            ),
            ...?actions,
            TextButton(
              style: style,
              onPressed: () {
                if (ctr.checkedCount == 0) {
                  return;
                }
                ctr.onRemove();
              },
              child: Text(
                '移除',
                style: TextStyle(color: colorScheme.error),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
      );
    }
    return overrideAppbar(context, child);
  }

  @override
  Size get preferredSize => child.preferredSize;
}
