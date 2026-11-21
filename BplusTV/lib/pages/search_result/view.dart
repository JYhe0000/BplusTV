import 'dart:async';

import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:bplus_tv/common/widgets/scroll_physics.dart' show tabBarView;
import 'package:bplus_tv/models/common/search/search_type.dart';
import 'package:bplus_tv/pages/search/controller.dart';
import 'package:bplus_tv/pages/search_panel/all/view.dart';
import 'package:bplus_tv/pages/search_panel/article/view.dart';
import 'package:bplus_tv/pages/search_panel/live/view.dart';
import 'package:bplus_tv/pages/search_panel/pgc/view.dart';
import 'package:bplus_tv/pages/search_panel/user/view.dart';
import 'package:bplus_tv/pages/search_panel/video/view.dart';
import 'package:bplus_tv/pages/search_result/controller.dart';
import 'package:bplus_tv/tv/tv_back_bar.dart';
import 'package:bplus_tv/tv/tv_constants.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class SearchResultPage extends StatefulWidget {
  const SearchResultPage({super.key});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage>
    with SingleTickerProviderStateMixin {
  late SearchResultController _searchResultController;
  late TabController _tabController;
  final String _tag = DateTime.now().millisecondsSinceEpoch.toString();
  final bool _isFromSearch = Get.arguments?['fromSearch'] ?? false;
  final List<FocusNode> _tabFocusNodes = List.generate(
    SearchType.values.length,
    (index) => FocusNode(debugLabel: 'SearchResultTab$index'),
  );
  final FocusScopeNode _contentFocusScope = FocusScopeNode(
    debugLabel: 'SearchResultContent',
    directionalTraversalEdgeBehavior: TraversalEdgeBehavior.parentScope,
  );
  final GlobalKey _contentKey = GlobalKey();
  Timer? _contentFocusRetry;
  int _contentFocusRequest = 0;
  SSearchController? sSearchController;

  @override
  void initState() {
    super.initState();
    _searchResultController = Get.put(
      SearchResultController(),
      tag: _tag,
    );

    _tabController = TabController(
      vsync: this,
      initialIndex: (Get.arguments?['initIndex'] as int? ?? 0).clamp(
        0,
        SearchType.values.length - 1,
      ),
      length: SearchType.values.length,
    );

    if (_isFromSearch) {
      try {
        sSearchController = Get.find<SSearchController>(
          tag: Get.parameters['tag'],
        );
        _tabController.addListener(listener);
      } catch (_) {}
    }
  }

  void listener() {
    sSearchController?.initIndex = _tabController.index;
  }

  @override
  void dispose() {
    _cancelContentFocus();
    _tabController
      ..removeListener(listener)
      ..dispose();
    for (final node in _tabFocusNodes) {
      node.dispose();
    }
    _contentFocusScope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortViewport = MediaQuery.sizeOf(context).height < 500;
    return TvPageFocus(
      child: BackdropGroup(
        child: SimpleScaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            toolbarHeight: shortViewport ? 56 : 60,
            titleSpacing: 8,
            automaticallyImplyLeading: false,
            leading: const TvBackButton(),
            leadingWidth: 64,
            shape: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            title: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: TvFocusable(
                  onTap: () {
                    if (_isFromSearch) {
                      Get.back();
                    } else {
                      Get.offNamed(
                        '/search',
                        parameters: {'text': _searchResultController.keyword},
                      );
                    }
                  },
                  builder: (context, focused, hovered) => TvFocusHighlight(
                    focused: focused,
                    radius: 12,
                    focusedScale: 1,
                    child: NetflixSurface(
                      radius: 12,
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: TvConstants.minTargetSize,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 22,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _searchResultController.keyword,
                                style: theme.textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '修改搜索',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: focused
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1200;
                final content = FocusScope(
                  key: _contentKey,
                  node: _contentFocusScope,
                  child: tabBarView(
                    controller: _tabController,
                    children: SearchType.values
                        .map(
                          (item) => AnimatedBuilder(
                            animation: _tabController,
                            builder: (context, child) => ExcludeFocus(
                              excluding: _tabController.index != item.index,
                              child: child!,
                            ),
                            child: switch (item) {
                              .all => SearchAllPanel(
                                tag: _tag,
                                searchType: item,
                                keyword: _searchResultController.keyword,
                              ),
                              .video => SearchVideoPanel(
                                tag: _tag,
                                searchType: item,
                                keyword: _searchResultController.keyword,
                              ),
                              .media_bangumi || .media_ft => SearchPgcPanel(
                                tag: _tag,
                                searchType: item,
                                keyword: _searchResultController.keyword,
                              ),
                              .live_room => SearchLivePanel(
                                tag: _tag,
                                searchType: item,
                                keyword: _searchResultController.keyword,
                              ),
                              .bili_user => SearchUserPanel(
                                tag: _tag,
                                searchType: item,
                                keyword: _searchResultController.keyword,
                              ),
                              .article => SearchArticlePanel(
                                tag: _tag,
                                searchType: item,
                                keyword: _searchResultController.keyword,
                              ),
                            },
                          ),
                        )
                        .toList(),
                  ),
                );
                if (wide) {
                  return Row(
                    children: [
                      SizedBox(
                        width: 160,
                        child: ClipRect(
                          child: _buildTvTabBar(theme, vertical: true),
                        ),
                      ),
                      VerticalDivider(
                        width: 1,
                        color: theme.colorScheme.outline.withValues(
                          alpha: 0.12,
                        ),
                      ),
                      Expanded(child: content),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRect(child: _buildTvTabBar(theme)),
                    Expanded(child: content),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _onTabTap(int index) {
    if (!_tabController.indexIsChanging) {
      if (_searchResultController.toTopIndex.value == index) {
        _searchResultController.toTopIndex.refresh();
      } else {
        _searchResultController.toTopIndex.value = index;
      }
    }
  }

  void _cancelContentFocus() {
    _contentFocusRequest++;
    _contentFocusRetry?.cancel();
    _contentFocusRetry = null;
  }

  void _enterContent(int index) {
    _cancelContentFocus();
    final request = _contentFocusRequest;
    if (_tabController.index != index) _tabController.index = index;

    // 新分类可能还没挂载，等首个可用结果出现；离开原分类按钮后不再抢焦点。
    void tryFocus(int retriesLeft) {
      if (!mounted ||
          request != _contentFocusRequest ||
          !_tabFocusNodes[index].hasPrimaryFocus ||
          _tabController.index != index ||
          ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      final target = _tabController.indexIsChanging
          ? null
          : TvFocusUtils.firstFocusable(_contentFocusScope);
      if (target != null) {
        target.requestFocus();
        Scrollable.ensureVisible(target.context!, alignment: 0.15);
        return;
      }
      if (retriesLeft > 0) {
        _contentFocusRetry = Timer(
          const Duration(milliseconds: 100),
          () => tryFocus(retriesLeft - 1),
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => tryFocus(20));
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Widget _buildTvTabBar(ThemeData theme, {bool vertical = false}) {
    final colorScheme = theme.colorScheme;
    final compact = !vertical && MediaQuery.sizeOf(context).height < 500;
    return SizedBox(
      width: vertical ? double.infinity : null,
      height: vertical
          ? double.infinity
          : compact
          ? 56
          : 60,
      child: ListView.separated(
        scrollDirection: vertical ? Axis.vertical : Axis.horizontal,
        padding: vertical
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
            : EdgeInsets.fromLTRB(12, 4, 12, compact ? 4 : 8),
        itemCount: SearchType.values.length,
        separatorBuilder: (_, _) => SizedBox(
          width: vertical ? 0 : 6,
          height: vertical ? 4 : 0,
        ),
        itemBuilder: (context, index) {
          final item = SearchType.values[index];
          return Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: (_, event) {
              final enterContent = vertical
                  ? LogicalKeyboardKey.arrowRight
                  : LogicalKeyboardKey.arrowDown;
              if (event.logicalKey == enterContent &&
                  (event is KeyDownEvent || event is KeyRepeatEvent)) {
                if (event is KeyDownEvent) _enterContent(index);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TvFocusable(
              focusNode: _tabFocusNodes[index],
              onFocusChange: (focused) {
                if (!focused) _cancelContentFocus();
              },
              onTap: () {
                _cancelContentFocus();
                if (_tabController.indexIsChanging) return;
                _onTabTap(index);
                if (_tabController.index != index) {
                  _tabController.animateTo(index);
                }
              },
              builder: (context, focused, hovered) => Obx(() {
                final count = _searchResultController.count[item.index];
                final label =
                    '${item.label}${count != -1 ? ' ${count > 99 ? '99+' : count}' : ''}';
                return AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    final selected = _tabController.index == index;
                    return TvFocusHighlight(
                      radius: 12,
                      focused: focused,
                      focusedScale: 1,
                      child: NetflixSegment(
                        radius: 12,
                        child: AnimatedContainer(
                          duration: TvConstants.focusDuration,
                          constraints: const BoxConstraints(
                            minWidth: TvConstants.minTargetSize,
                            minHeight: TvConstants.minTargetSize,
                          ),
                          padding: vertical
                              ? const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                )
                              : const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                          alignment: vertical
                              ? Alignment.centerLeft
                              : Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? colorScheme.primary.withValues(alpha: 0.24)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? colorScheme.primary.withValues(alpha: 0.65)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: selected || focused || hovered
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
