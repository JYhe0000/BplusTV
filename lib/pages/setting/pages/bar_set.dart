import 'package:bplus_tv/common/widgets/pair.dart';
import 'package:bplus_tv/common/widgets/reorder_mixin.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/models/common/enum_with_label.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:bplus_tv/tv/tv_back_bar.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class BarSetPage extends StatefulWidget {
  const BarSetPage({super.key});

  @override
  State<BarSetPage> createState() => _BarSetPageState();
}

class _BarSetPageState extends State<BarSetPage> with ReorderMixin {
  late final String key;
  late final String title;
  late final List<Pair<EnumWithLabel, bool>> list;
  late EdgeInsets padding;
  int? _tvReorderIndex;

  @override
  void initState() {
    super.initState();
    final Map<String, dynamic> args = Get.arguments;
    key = args['key'];
    title = args['title'];
    final List? cache = GStorage.setting.get(key);
    list = (args['defaultBars'] as List<EnumWithLabel>)
        .map((e) => Pair(first: e, second: cache?.contains(e.index) ?? true))
        .toList();
    if (cache != null && cache.isNotEmpty) {
      final cacheIndex = {for (int i = 0; i < cache.length; i++) cache[i]: i};
      list.sort((a, b) {
        final indexA = cacheIndex[a.first.index] ?? cacheIndex.length;
        final indexB = cacheIndex[b.first.index] ?? cacheIndex.length;
        return indexA.compareTo(indexB);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewPad = MediaQuery.viewPaddingOf(context);
    padding = .only(top: 10, right: viewPad.right + 34, bottom: viewPad.bottom);
  }

  void saveEdit() {
    GStorage.setting.put(
      key,
      list.where((e) => e.second).map((e) => e.first.index).toList(),
    );
    SmartDialog.showToast('保存成功，下次启动时生效');
  }

  void onReset() {
    Get.back();
    GStorage.setting.delete(key);
    SmartDialog.showToast('重置成功，下次启动时生效');
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = SimpleScaffold(
      appBar: tvBackBar(
        actions: [
          TextButton(onPressed: onReset, child: const Text('重置')),
          TextButton(onPressed: saveEdit, child: const Text('保存')),
          const SizedBox(width: 12),
        ],
      ),
      body: _buildTvBody(),
    );
    return TvPageFocus(child: content);
  }

  Widget _buildTvBody() {
    final scheme = Theme.of(context).colorScheme;
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (_tvReorderIndex == null || event is KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
            _tvReorderIndex! > 0) {
          setState(() {
            final item = list.removeAt(_tvReorderIndex!);
            _tvReorderIndex = _tvReorderIndex! - 1;
            list.insert(_tvReorderIndex!, item);
          });
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
            _tvReorderIndex! < list.length - 1) {
          setState(() {
            final item = list.removeAt(_tvReorderIndex!);
            _tvReorderIndex = _tvReorderIndex! + 1;
            list.insert(_tvReorderIndex!, item);
          });
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: ListView(
        children: [
          ...list.asMap().entries.map((entry) {
            final index = entry.key;
            final e = entry.value;
            final isMoving = _tvReorderIndex == index;
            return Container(
              key: ValueKey(e.hashCode),
              color: isMoving ? scheme.primaryContainer : null,
              child: CheckboxListTile(
                value: e.second,
                onChanged: (bool? value) {
                  e.second = value!;
                  setState(() {});
                },
                title: Text(e.first.label),
                secondary: IconButton(
                  autofocus: index == 0 && _tvReorderIndex == null,
                  icon: Icon(
                    isMoving ? Icons.check_circle : Icons.swap_vert,
                  ),
                  onPressed: () {
                    if (_tvReorderIndex == null) {
                      setState(() => _tvReorderIndex = index);
                    } else if (isMoving) {
                      setState(() => _tvReorderIndex = null);
                    } else {
                      setState(() => _tvReorderIndex = index);
                    }
                  },
                ),
              ),
            );
          }),
          Padding(
            padding: padding,
            child: _tvReorderIndex != null
                ? Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _tvReorderIndex = null),
                      icon: const Icon(Icons.check),
                      label: const Text('完成排序'),
                    ),
                  )
                : const Align(
                    alignment: Alignment.centerRight,
                    child: Text('选择要移动的项目，然后用↑↓调整位置'),
                  ),
          ),
        ],
      ),
    );
  }
}
