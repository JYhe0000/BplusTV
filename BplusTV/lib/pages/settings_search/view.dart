import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/common/widgets/view_insets_safe_area.dart';
import 'package:bplus_tv/common/widgets/view_sliver_safe_area.dart';
import 'package:bplus_tv/pages/search/controller.dart' show DebounceStreamState;
import 'package:bplus_tv/pages/setting/models/extra_settings.dart';
import 'package:bplus_tv/pages/setting/models/model.dart';
import 'package:bplus_tv/pages/setting/models/play_settings.dart';
import 'package:bplus_tv/pages/setting/models/privacy_settings.dart';
import 'package:bplus_tv/pages/setting/models/recommend_settings.dart';
import 'package:bplus_tv/pages/setting/models/style_settings.dart';
import 'package:bplus_tv/pages/setting/models/ui_style_settings.dart';
import 'package:bplus_tv/pages/setting/models/video_settings.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:bplus_tv/tv/tv_text_input.dart';
import 'package:bplus_tv/utils/grid.dart';
import 'package:bplus_tv/utils/waterfall.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:waterfall_flow/waterfall_flow.dart'
    hide SliverWaterfallFlowDelegateWithMaxCrossAxisExtent;

class SettingsSearchPage extends StatefulWidget {
  const SettingsSearchPage({super.key});

  @override
  State<SettingsSearchPage> createState() => _SettingsSearchPageState();
}

class _SettingsSearchPageState
    extends DebounceStreamState<SettingsSearchPage, String> {
  final _textEditingController = TextEditingController();
  final RxList<SettingsModel> _list = <SettingsModel>[].obs;

  /// 是否已执行过搜索：区分「未输入关键词」与「搜了但没结果」两种空列表。
  bool _searched = false;
  late final _settings = [
    ...extraSettings,
    ...privacySettings,
    ...recommendSettings,
    ...videoSettings,
    ...playSettings,
    ...uiStyleSettings,
    ...styleSettings,
  ];

  @override
  void onValueChanged(String value) {
    if (value.isEmpty) {
      _searched = false;
      _list.clear();
    } else {
      value = value.toLowerCase();
      _searched = true;
      _list.value = _settings
          .where(
            (item) =>
                item.effectiveTitle.toLowerCase().contains(value) ||
                item.effectiveSubtitle?.toLowerCase().contains(value) == true,
          )
          .toList();
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    ctr!.add(query);
    _textEditingController.text = query;
    // AppBar 标题与清空按钮读的是 controller 文本，不在 Obx 内，需手动刷新
    if (mounted) setState(() {});
  }

  Future<void> _startTvSearch() async {
    final result = await showTvTextInput(
      context,
      title: '搜索设置',
      initialValue: _textEditingController.text,
    );
    if (result != null && mounted) {
      _performSearch(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = SimpleScaffold(
      appBar: AppBar(
        actions: [
          if (_textEditingController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _textEditingController.clear();
                _searched = false;
                _list.clear();
                setState(() {});
              },
              icon: const Icon(Icons.clear),
            )
          else
            const SizedBox(width: 10),
          const SizedBox(width: 10),
        ],
        title: _TvSearchTrigger(
          currentText: _textEditingController.text,
          onTap: _startTvSearch,
        ),
      ),
      body: ViewInsetsSafeArea(
        child: CustomScrollView(
          slivers: [
            ViewSliverSafeArea(
              sliver: Obx(
                () {
                  if (_list.isNotEmpty) {
                    return SliverWaterfallFlow(
                      gridDelegate:
                          SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: Grid.smallCardWidth * 2,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (_, index) => _list[index].widget,
                        childCount: _list.length,
                      ),
                    );
                  }
                  // 空列表分两种：未搜过是引导提示，搜过没结果才是空结果提示。
                  // （数据源是本地静态列表，无异步加载失败路径，故不再用错误占位）
                  final theme = Theme.of(context);
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        _searched ? '未找到相关设置' : '输入关键词搜索设置',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    return TvPageFocus(child: content);
  }
}

class _TvSearchTrigger extends StatelessWidget {
  const _TvSearchTrigger({required this.currentText, required this.onTap});

  final String currentText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = currentText.isNotEmpty;
    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, _) => TvFocusHighlight(
        focused: focused,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search,
                size: 22,
                color: focused
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  hasText ? currentText : '搜索设置',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    color: hasText
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
