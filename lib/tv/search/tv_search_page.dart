import 'dart:async';
import 'dart:math' as math;

import 'package:bplus_tv/common/widgets/app_background.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/http/search.dart';
import 'package:bplus_tv/pages/search/controller.dart';
import 'package:bplus_tv/tv/search/t9_keyboard.dart';
import 'package:bplus_tv/tv/search/t9_query.dart';
import 'package:bplus_tv/tv/search/tv_full_keyboard.dart';
import 'package:bplus_tv/tv/search/tv_qr_search.dart';
import 'package:bplus_tv/tv/tv_back_bar.dart';
import 'package:bplus_tv/tv/tv_constants.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:bplus_tv/utils/storage.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// 左右各 16dp 内边距，以及键盘与建议之间的 1dp 分隔线。
const double _kSearchPagePadding = 33;

/// 为紧凑横屏保留一列可读建议，避免输入控件挤占列表空间。
const double _kMinSuggestionWidth = 300;

/// 根据搜索页的 [maxWidth] 分配键盘宽度，并为建议区保留空间。
@visibleForTesting
double tvKeyboardWidthFor(double maxWidth) {
  final available = (maxWidth - _kSearchPagePadding)
      .clamp(0.0, double.infinity)
      .toDouble();
  final minSuggestionWidth = math.min(
    _kMinSuggestionWidth,
    available * 0.54,
  );
  final maxKeyboardWidth = math.max(
    0.0,
    available - minSuggestionWidth,
  );
  return (available * 0.32)
      .clamp(math.min(320.0, available * 0.5), 400.0)
      .clamp(0.0, maxKeyboardWidth)
      .toDouble();
}

/// 搜索键盘与建议区按可用宽度分栏，减少键盘的首屏占用。
class TvSearchPage extends StatefulWidget {
  const TvSearchPage({super.key});

  @override
  State<TvSearchPage> createState() => _TvSearchPageState();
}

class _TvSearchPageState extends State<TvSearchPage> {
  static const double _headerHeight = 36;
  static const double _itemHeight = 54;

  static const _fallbackHotWords = [
    '凡人修仙传',
    '三体',
    '鬼灭之刃',
    '仙逆',
    '间谍过家家',
    '咒术回战',
    '原神',
    '崩坏：星穹铁道',
    '海贼王',
    '火影忍者',
  ];

  final _tag = Utils.generateRandomString(6);
  late final SSearchController _searchController;
  final FocusNode _keyboardFocus = FocusNode(debugLabel: 'TvSearchKeyboard');
  final FocusNode _backFocus = FocusNode(debugLabel: 'TvSearchBack');
  final FocusNode _keyboardModeFocus = FocusNode(
    debugLabel: 'TvSearchKeyboardMode',
  );
  final FocusNode _remoteFocus = FocusNode(debugLabel: 'TvSearchRemote');
  final FocusNode _clearFocus = FocusNode(debugLabel: 'TvSearchClear');
  final FocusNode _historyFocus = FocusNode(debugLabel: 'TvSearchHistory');
  final FocusNode _trendingFocus = FocusNode(debugLabel: 'TvSearchTrending');
  final FocusNode _compactSuggestionFocus = FocusNode(
    debugLabel: 'TvSearchCompactSuggestions',
  );
  final ScrollController _historyScroll = ScrollController();
  final ScrollController _trendingScroll = ScrollController();
  final ScrollController _compactSuggestionScroll = ScrollController();

  int _historyIndex = 0;
  int _trendingIndex = 0;
  int _compactSuggestionIndex = 0;
  bool _historyFocused = false;
  bool _trendingFocused = false;
  bool _compactSuggestionFocused = false;
  bool _showCompactTrending = false;
  bool _useFullKeyboard = false;
  bool _compactLayout = true;
  String _text = '';
  List<String> _t9Suggestions = const [];
  Timer? _suggestDebounce;
  int _suggestSeq = 0;
  bool _searchPending = false;

  @override
  void initState() {
    super.initState();
    _searchController = Get.put(SSearchController(_tag), tag: _tag);
    _text = _searchController.controller.text;
    if (_text.isNotEmpty) {
      _searchController.onChange(_text);
      _scheduleT9Suggestions(_text);
    }
  }

  @override
  void dispose() {
    _suggestDebounce?.cancel();
    _keyboardFocus.dispose();
    _backFocus.dispose();
    _keyboardModeFocus.dispose();
    _remoteFocus.dispose();
    _clearFocus.dispose();
    _historyFocus.dispose();
    _trendingFocus.dispose();
    _compactSuggestionFocus.dispose();
    _historyScroll.dispose();
    _trendingScroll.dispose();
    _compactSuggestionScroll.dispose();
    Get.delete<SSearchController>(tag: _tag);
    super.dispose();
  }

  void _onTextChanged(String text) {
    _text = text;
    _searchController.controller.text = text;
    _searchController.onChange(text);
    _scheduleT9Suggestions(text);
    if (mounted) setState(() {});
  }

  /// T9 only produces Latin letters, so ask Bilibili's search-suggest API to
  /// turn a pinyin query such as `ywsn` into a Chinese keyword.
  Future<List<String>> _fetchSuggestions(String query) async {
    try {
      final res = await SearchHttp.searchSuggest(term: query);
      if (res case Success(:final response)) {
        return (response.tag ?? const [])
            .map((item) => item.term?.trim() ?? '')
            .where((word) => word.isNotEmpty)
            .toSet()
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  void _scheduleT9Suggestions(String text) {
    _suggestDebounce?.cancel();
    final seq = ++_suggestSeq;
    final query = text.trim();
    _t9Suggestions = const [];
    if (!isT9Query(query)) {
      return;
    }
    _suggestDebounce = Timer(const Duration(milliseconds: 220), () async {
      final suggestions = await _fetchSuggestions(query);
      if (!mounted || seq != _suggestSeq || _text.trim() != query) return;
      setState(() => _t9Suggestions = suggestions);
    });
  }

  Future<String> _resolveT9Keyword(String keyword) async {
    if (!isT9Query(keyword)) return keyword;
    final cached = pickT9Suggestion(keyword, _t9Suggestions);
    if (cached != null) return cached;
    final fetched = await _fetchSuggestions(keyword);
    return pickT9Suggestion(keyword, fetched) ?? keyword;
  }

  Future<void> _search(String keyword) async {
    var text = keyword.trim();
    if (text.isEmpty || _searchPending) return;
    _searchPending = true;
    try {
      text = await _resolveT9Keyword(text);
      if (!mounted) return;
      if (_text != text) {
        setState(() => _text = text);
      }
      _searchController.controller.text = text;
      _searchController.validateUid();
      if (_searchController.recordSearchHistory.value) {
        final list = _searchController.historyList;
        final index = list.indexOf(text);
        if (index != 0) {
          if (index != -1) list.removeAt(index);
          list.insert(0, text);
          GStorage.historyWord.put('cacheList', list);
        }
      }
      await Get.toNamed(
        '/searchResult',
        parameters: {'tag': _tag, 'keyword': text},
        arguments: {
          'initIndex': _searchController.initIndex,
          'fromSearch': true,
        },
      );
    } finally {
      _searchPending = false;
    }
  }

  void _requestSuggestionFocus({required bool trending}) {
    final items = trending ? _trendingItems : _primarySuggestionItems;
    if (items.isEmpty) return;
    if (trending) {
      _trendingIndex = _trendingIndex.clamp(0, items.length - 1);
      _trendingFocus.requestFocus();
      _ensureVisible(_trendingScroll, _trendingIndex);
    } else {
      _historyIndex = _historyIndex.clamp(0, items.length - 1);
      _historyFocus.requestFocus();
      _ensureVisible(_historyScroll, _historyIndex);
    }
  }

  void _requestCompactSuggestionFocus({bool? trending}) {
    if (trending != null && _showCompactTrending != trending) {
      setState(() => _showCompactTrending = trending);
    }
    if (!_showCompactTrending && _primarySuggestionItems.isEmpty) {
      setState(() => _showCompactTrending = true);
    }
    final items = _compactSuggestionItems;
    if (items.isEmpty) return;
    _compactSuggestionIndex = _compactSuggestionIndex.clamp(
      0,
      items.length - 1,
    );
    _compactSuggestionFocus.requestFocus();
    _ensureVisible(_compactSuggestionScroll, _compactSuggestionIndex);
  }

  void _focusSuggestionsFromKeyboard() {
    if (_compactLayout) {
      _requestCompactSuggestionFocus(trending: false);
    } else if (_primarySuggestionItems.isNotEmpty) {
      _requestSuggestionFocus(trending: false);
    } else {
      _requestSuggestionFocus(trending: true);
    }
  }

  void _toggleKeyboard() {
    setState(() => _useFullKeyboard = !_useFullKeyboard);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keyboardFocus.requestFocus();
    });
  }

  List<String> get _compactSuggestionItems =>
      _showCompactTrending ? _trendingItems : _primarySuggestionItems;

  KeyEventResult _onCompactSuggestionKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final items = _compactSuggestionItems;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        if (_compactSuggestionIndex > 0) {
          setState(() => _compactSuggestionIndex--);
          _ensureVisible(_compactSuggestionScroll, _compactSuggestionIndex);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        if (_compactSuggestionIndex < items.length - 1) {
          setState(() => _compactSuggestionIndex++);
          _ensureVisible(_compactSuggestionScroll, _compactSuggestionIndex);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        _keyboardFocus.requestFocus();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        if (event is KeyRepeatEvent) return KeyEventResult.handled;
        if (_showCompactTrending && _primarySuggestionItems.isNotEmpty) {
          _requestCompactSuggestionFocus(trending: false);
        } else if (!_showCompactTrending && _trendingItems.isNotEmpty) {
          _requestCompactSuggestionFocus(trending: true);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.gameButtonA:
        if (event is KeyRepeatEvent) return KeyEventResult.handled;
        if (_compactSuggestionIndex >= 0 &&
            _compactSuggestionIndex < items.length) {
          _search(items[_compactSuggestionIndex]);
        }
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// 紧凑行高随用户字号增长，滚动定位与实际行高保持一致。
  double _itemHeightFor(BuildContext context) {
    final textHeight = MediaQuery.textScalerOf(context).scale(15) * 1.25;
    return math.max(_itemHeight, textHeight + 28);
  }

  void _ensureVisible(ScrollController controller, int index) {
    if (!controller.hasClients) return;
    final itemHeight = _itemHeightFor(context);
    final position = controller.position;
    final top = index * itemHeight;
    final current = position.pixels;
    final viewport = position.viewportDimension;
    double? target;
    if (top < current) {
      target = top;
    } else if (top + itemHeight > current + viewport) {
      target = top + itemHeight - viewport;
    }
    if (target == null) return;
    controller.animateTo(
      target
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble(),
      duration: TvConstants.focusScrollDuration,
      curve: TvConstants.focusScrollCurve,
    );
  }

  KeyEventResult _onSuggestionKey(
    FocusNode node,
    KeyEvent event, {
    required bool trending,
  }) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final items = trending ? _trendingItems : _primarySuggestionItems;
    var index = trending ? _trendingIndex : _historyIndex;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        if (index > 0) {
          index--;
          setState(() {
            if (trending) {
              _trendingIndex = index;
            } else {
              _historyIndex = index;
            }
          });
          _ensureVisible(trending ? _trendingScroll : _historyScroll, index);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        if (index < items.length - 1) {
          index++;
          setState(() {
            if (trending) {
              _trendingIndex = index;
            } else {
              _historyIndex = index;
            }
          });
          _ensureVisible(trending ? _trendingScroll : _historyScroll, index);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        if (trending && _primarySuggestionItems.isNotEmpty) {
          _requestSuggestionFocus(trending: false);
        } else {
          _keyboardFocus.requestFocus();
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        if (!trending && _trendingItems.isNotEmpty) {
          _requestSuggestionFocus(trending: true);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.gameButtonA:
        if (event is KeyRepeatEvent) return KeyEventResult.handled;
        if (index >= 0 && index < items.length) _search(items[index]);
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  List<String> get _historyItems => _searchController.historyList
      .where((word) => word.trim().isNotEmpty)
      .toList();

  bool get _showSearchSuggestions =>
      _text.trim().isNotEmpty &&
      _searchController.searchSuggestion &&
      _searchController.searchSuggestList.isNotEmpty;

  List<String> get _searchSuggestionItems => _showSearchSuggestions
      ? _searchController.searchSuggestList
            .map((item) => item.term?.trim() ?? '')
            .where((word) => word.isNotEmpty)
            .toSet()
            .toList()
      : const [];

  bool get _showSuggestions =>
      _t9Suggestions.isNotEmpty || _showSearchSuggestions;

  List<String> get _primarySuggestionItems {
    if (_t9Suggestions.isNotEmpty) return _t9Suggestions;
    return _showSearchSuggestions ? _searchSuggestionItems : _historyItems;
  }

  List<String> get _trendingItems {
    if (_searchController.enableTrending) {
      final state = _searchController.trendingState.value;
      if (state case Success(:final response)) {
        final words =
            response.list
                ?.map(
                  (item) =>
                      item.showName.isEmpty ? item.keyword : item.showName,
                )
                .where((word) => word.trim().isNotEmpty)
                .toList() ??
            const <String>[];
        if (words.isNotEmpty) return words;
      }
    }
    if (_searchController.enableSearchRcmd) {
      final state = _searchController.recommendData.value;
      if (state case Success(:final response)) {
        final words =
            response.list
                ?.map(
                  (item) =>
                      item.showName.isEmpty ? item.keyword : item.showName,
                )
                .where((word) => word.trim().isNotEmpty)
                .toList() ??
            const <String>[];
        if (words.isNotEmpty) return words;
      }
    }
    return _fallbackHotWords;
  }

  Future<void> _remoteSearch() async {
    final keyword = await showTvQrSearch(context);
    if (mounted) _remoteFocus.requestFocus();
    if (keyword == null || keyword.trim().isEmpty || !mounted) return;
    _onTextChanged(keyword.trim());
    _search(keyword);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        const AppBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: TvPageFocus(
            child: SafeArea(
              child: BackdropGroup(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final keyboardWidth = tvKeyboardWidthFor(
                      constraints.maxWidth,
                    );
                    final compact = constraints.maxWidth < 960;
                    if (_compactLayout != compact) {
                      final restoreSuggestions =
                          _historyFocus.hasFocus ||
                          _trendingFocus.hasFocus ||
                          _compactSuggestionFocus.hasFocus;
                      final wasTrending = _compactLayout
                          ? _showCompactTrending
                          : _trendingFocus.hasFocus;
                      if (restoreSuggestions) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted ||
                              ModalRoute.of(context)?.isCurrent == false) {
                            return;
                          }
                          if (compact) {
                            _requestCompactSuggestionFocus(
                              trending: wasTrending,
                            );
                          } else {
                            _requestSuggestionFocus(trending: wasTrending);
                          }
                        });
                      }
                    }
                    _compactLayout = compact;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: keyboardWidth,
                            child: _buildKeyboardPanel(colorScheme),
                          ),
                          VerticalDivider(
                            width: 1,
                            color: colorScheme.outline.withValues(alpha: 0.15),
                          ),
                          Expanded(
                            child: compact
                                ? _buildCompactSuggestionPanel(colorScheme)
                                : _buildSuggestionPanel(colorScheme),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyboardPanel(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TvBackButton(focusNode: _backFocus),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '搜索',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TvFocusable(
                focusNode: _keyboardModeFocus,
                onTap: _toggleKeyboard,
                builder: (context, focused, hovered) => TvFocusHighlight(
                  focused: focused,
                  radius: 18,
                  child: netflixSurface(
                    radius: 18,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 48,
                        minWidth: 72,
                      ),
                      child: Center(
                        child: Text(_useFullKeyboard ? '全键盘' : 'T9'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: netflixSurface(
                  radius: 22,
                  child: SizedBox(
                    height: 48,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _text.isEmpty ? '使用遥控器输入关键词' : _text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            color: _text.isEmpty
                                ? colorScheme.outline
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _iconAction(
                colorScheme,
                focusNode: _remoteFocus,
                icon: Icons.qr_code_rounded,
                tooltip: '手机扫码搜索',
                onTap: _remoteSearch,
              ),
              const SizedBox(width: 8),
              _iconAction(
                colorScheme,
                focusNode: _clearFocus,
                icon: Icons.backspace_outlined,
                tooltip: '清空输入',
                onTap: () => _onTextChanged(''),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _useFullKeyboard
                ? TvFullKeyboard(
                    key: const ValueKey('full-keyboard'),
                    focusNode: _keyboardFocus,
                    initialText: _text,
                    onChanged: _onTextChanged,
                    onSubmit: _search,
                    onExitUp: _focusClear,
                    onExitLeft: _focusBack,
                    onExitRight: _focusSuggestionsFromKeyboard,
                  )
                : T9Keyboard(
                    key: const ValueKey('t9'),
                    focusNode: _keyboardFocus,
                    autofocus: true,
                    initialText: _text,
                    onChanged: _onTextChanged,
                    onSubmit: _search,
                    onExitUp: _focusClear,
                    onExitLeft: _focusBack,
                    onExitRight: _focusSuggestionsFromKeyboard,
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            _useFullKeyboard ? '方向键选择 · 确认输入' : '连续按同一数字键切换字母',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _iconAction(
    ColorScheme colorScheme, {
    required FocusNode focusNode,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: TvFocusable(
        focusNode: focusNode,
        onTap: onTap,
        builder: (context, focused, hovered) => TvFocusHighlight(
          focused: focused,
          radius: 24,
          child: netflixSurface(
            radius: 24,
            child: SizedBox.square(
              dimension: 48,
              child: Icon(
                icon,
                color: focused ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _focusBack() => _backFocus.requestFocus();

  void _focusClear() => _clearFocus.requestFocus();

  Widget _buildCompactSuggestionPanel(ColorScheme colorScheme) {
    return Obx(() {
      final primaryItems = _primarySuggestionItems;
      final items = _showCompactTrending ? _trendingItems : primaryItems;
      if (_compactSuggestionIndex >= items.length) {
        _compactSuggestionIndex = items.isEmpty ? 0 : items.length - 1;
      }
      final showSearchSuggestions = _showSuggestions;
      final title = _showCompactTrending
          ? '热门搜索'
          : showSearchSuggestions
          ? '搜索建议'
          : '搜索历史';
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _headerHeight,
              child: Row(
                children: [
                  Icon(
                    _showCompactTrending
                        ? Icons.local_fire_department_rounded
                        : showSearchSuggestions
                        ? Icons.search_rounded
                        : Icons.history_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '按 → 切换',
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Focus(
                focusNode: _compactSuggestionFocus,
                onFocusChange: (value) => setState(() {
                  _compactSuggestionFocused = value;
                }),
                onKeyEvent: _onCompactSuggestionKey,
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          '暂无$title',
                          style: TextStyle(color: colorScheme.outline),
                        ),
                      )
                    : ListView.builder(
                        controller: _compactSuggestionScroll,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final itemHeight = _itemHeightFor(context);
                          return SizedBox(
                            height: itemHeight,
                            child: _SearchWordTile(
                              word: items[index],
                              focused:
                                  _compactSuggestionFocused &&
                                  _compactSuggestionIndex == index,
                              icon: _showCompactTrending
                                  ? Icons.local_fire_department_rounded
                                  : showSearchSuggestions
                                  ? Icons.search_rounded
                                  : Icons.history_rounded,
                              height: itemHeight - 6,
                              onTap: () => _search(items[index]),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSuggestionPanel(ColorScheme colorScheme) {
    return Obx(() {
      final showSuggestions = _showSuggestions;
      final history = showSuggestions
          ? (_t9Suggestions.isNotEmpty
                ? _t9Suggestions
                : _searchSuggestionItems)
          : _historyItems;
      final trending = _trendingItems;
      if (_historyIndex >= history.length) {
        _historyIndex = history.isEmpty ? 0 : history.length - 1;
      }
      if (_trendingIndex >= trending.length) {
        _trendingIndex = trending.isEmpty ? 0 : trending.length - 1;
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _suggestionColumn(
                title: showSuggestions ? '搜索建议' : '搜索历史',
                icon: showSuggestions
                    ? Icons.search_rounded
                    : Icons.history_rounded,
                words: history,
                emptyText: showSuggestions ? '暂无搜索建议' : '暂无搜索历史',
                focused: _historyFocused,
                focusNode: _historyFocus,
                scrollController: _historyScroll,
                selectedIndex: _historyIndex,
                onFocusChange: (value) =>
                    setState(() => _historyFocused = value),
                onKey: (node, event) => _onSuggestionKey(
                  node,
                  event,
                  trending: false,
                ),
                onTap: _search,
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _suggestionColumn(
                title: '热门搜索',
                icon: Icons.local_fire_department_rounded,
                words: trending,
                emptyText: '暂无热门搜索',
                focused: _trendingFocused,
                focusNode: _trendingFocus,
                scrollController: _trendingScroll,
                selectedIndex: _trendingIndex,
                onFocusChange: (value) =>
                    setState(() => _trendingFocused = value),
                onKey: (node, event) => _onSuggestionKey(
                  node,
                  event,
                  trending: true,
                ),
                onTap: _search,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _suggestionColumn({
    required String title,
    required IconData icon,
    required List<String> words,
    required String emptyText,
    required bool focused,
    required FocusNode focusNode,
    required ScrollController scrollController,
    required int selectedIndex,
    required ValueChanged<bool> onFocusChange,
    required KeyEventResult Function(FocusNode, KeyEvent) onKey,
    required ValueChanged<String> onTap,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _headerHeight,
          child: Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: words.isEmpty
              ? Center(
                  child: Text(
                    emptyText,
                    style: TextStyle(color: colorScheme.outline),
                  ),
                )
              : Focus(
                  focusNode: focusNode,
                  onFocusChange: onFocusChange,
                  onKeyEvent: onKey,
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: words.length,
                    itemBuilder: (context, index) {
                      final itemHeight = _itemHeightFor(context);
                      return SizedBox(
                        height: itemHeight,
                        child: _SearchWordTile(
                          word: words[index],
                          focused: focused && selectedIndex == index,
                          icon: title == '搜索历史'
                              ? Icons.history_rounded
                              : Icons.search_rounded,
                          height: itemHeight - 6,
                          onTap: () => onTap(words[index]),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _SearchWordTile extends StatelessWidget {
  const _SearchWordTile({
    required this.word,
    required this.focused,
    required this.icon,
    required this.height,
    required this.onTap,
  });

  final String word;
  final bool focused;
  final IconData icon;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedScale(
          scale: 1,
          duration: TvConstants.focusDuration,
          curve: Curves.easeOutCubic,
          child: TvFocusHighlight(
            focused: focused,
            radius: 10,
            borderWidth: 2,
            color: colorScheme.primary,
            child: netflixSurface(
              radius: 10,
              child: SizedBox(
                height: height,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 19,
                        color: focused
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          word,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: focused ? FontWeight.w600 : null,
                            color: focused ? colorScheme.primary : null,
                          ),
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
    );
  }
}
