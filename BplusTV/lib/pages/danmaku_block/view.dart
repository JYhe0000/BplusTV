import 'package:bplus_tv/common/widgets/button/icon_button.dart';
import 'package:bplus_tv/common/widgets/dialog/dialog.dart';
import 'package:bplus_tv/common/widgets/keep_alive_wrapper.dart';
import 'package:bplus_tv/common/widgets/loading_widget/loading_widget.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/common/widgets/scroll_physics.dart' show tabBarView;
import 'package:bplus_tv/models/common/dm_block_type.dart';
import 'package:bplus_tv/models/user/danmaku_block.dart';
import 'package:bplus_tv/models/user/danmaku_rule.dart';
import 'package:bplus_tv/pages/danmaku_block/controller.dart';
import 'package:bplus_tv/plugin/pl_player/controller.dart';
import 'package:bplus_tv/tv/tv_text_input.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:bplus_tv/utils/storage_key.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class DanmakuBlockPage extends StatefulWidget {
  const DanmakuBlockPage({super.key});

  @override
  State<DanmakuBlockPage> createState() => _DanmakuBlockPageState();
}

class _DanmakuBlockPageState extends State<DanmakuBlockPage> {
  final DanmakuBlockController _controller = Get.put(DanmakuBlockController());
  late PlPlayerController plPlayerController;
  late EdgeInsets padding;

  @override
  void initState() {
    super.initState();
    plPlayerController = Get.arguments as PlPlayerController;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    padding = MediaQuery.viewPaddingOf(context);
  }

  @override
  void dispose() {
    final ruleFilter = RuleFilter.fromRuleTypeEntries(_controller.rules);
    plPlayerController.filters = ruleFilter;
    GStorage.localCache.put(LocalCacheKey.danmakuFilterRules, ruleFilter);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      appBar: AppBar(title: const Text('弹幕屏蔽')),
      body: Column(
        children: [
          TabBar(
            controller: _controller.tabController,
            tabs: DmBlockType.values
                .map(
                  (e) => Obx(
                    () => Tab(
                      text: '${e.label}(${_controller.rules[e.index].length})',
                    ),
                  ),
                )
                .toList(),
          ),
          Expanded(
            child: tabBarView(
              controller: _controller.tabController,
              children: DmBlockType.values
                  .map(
                    (e) => KeepAliveWrapper(
                      child: Obx(
                        () =>
                            tabViewBuilder(e.index, _controller.rules[e.index]),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
      fab: Padding(
        padding: .only(
          right: kFloatingActionButtonMargin + padding.right,
          bottom: kFloatingActionButtonMargin + padding.bottom,
        ),
        child: FloatingActionButton(
          tooltip: '添加',
          onPressed: () => _showAddDialog(
            DmBlockType.values[_controller.tabController.index],
          ),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget tabViewBuilder(int tabIndex, List<SimpleRule> list) {
    if (list.isEmpty) {
      return scrollableError;
    }
    return ListView.builder(
      itemCount: list.length,
      padding: .only(bottom: padding.bottom + 100),
      itemBuilder: (context, itemIndex) {
        final SimpleRule item = list[itemIndex];
        final child = iconButton(
          iconSize: 20,
          tooltip: '删除',
          icon: const Icon(Icons.delete_outlined),
          onPressed: () => showConfirmDialog(
            context: context,
            title: const Text('确定删除该规则？'),
            onConfirm: () => _controller.danmakuFilterDel(
              tabIndex,
              itemIndex,
              item.id,
            ),
          ),
        );
        return ListTile(
          title: Text(
            item.filter,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          trailing: tabIndex == 2
              ? child
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    iconButton(
                      iconSize: 20,
                      tooltip: '编辑',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showAddDialog(
                        DmBlockType.values[_controller.tabController.index],
                        initFilter: item.filter,
                        itemIndex: itemIndex,
                        itemId: item.id,
                      ),
                    ),
                    child,
                  ],
                ),
        );
      },
    );
  }

  void _showAddDialog(
    DmBlockType type, {
    String initFilter = '',
    int? itemIndex,
    int? itemId,
  }) {
    assert((itemIndex == null) == (itemId == null));
    String filter = initFilter;
    final isUid = type == DmBlockType.uid;
    Future<void> submit(String filter) async {
      if (filter != initFilter) {
        if (itemId != null) {
          await _controller.danmakuFilterDel(
            type.index,
            itemIndex!,
            itemId,
          );
        }
        await _controller.danmakuFilterAdd(
          filter: filter,
          type: type.index,
        );
      } else {
        SmartDialog.showToast(
          '输入内容${filter.isEmpty ? "不能为空" : "与上次相同"}',
        );
      }
    }

    {
      showTvTextInput(
        context,
        title: '${itemId != null ? "编辑" : "添加新的"}${type.label}规则',
        initialValue: filter,
        maxLength: isUid ? 20 : null,
      ).then((value) async {
        if (value == null || !context.mounted) return;
        await submit(value);
      });
      return;
    }
  }
}
