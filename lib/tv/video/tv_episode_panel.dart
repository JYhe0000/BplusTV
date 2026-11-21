import 'dart:math';

import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/models/common/episode_panel_type.dart';
import 'package:bplus_tv/models_new/pgc/pgc_info_model/episode.dart' as pgc;
import 'package:bplus_tv/models_new/video/video_detail/episode.dart' as ugc;
import 'package:bplus_tv/models_new/video/video_detail/page.dart';
import 'package:bplus_tv/models_new/video/video_detail/section.dart';
import 'package:bplus_tv/pages/video/controller.dart';
import 'package:bplus_tv/pages/video/introduction/ugc/controller.dart';
import 'package:bplus_tv/tv/tv_constants.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/duration_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// TV-native episode/playlist panel.
///
/// Replaces the mobile [EpisodePanel] inside the video info panel's playlist
/// tab. Instead of nesting a focusable widget per row, a single [Focus] node
/// owns an integer index: the D-pad moves that index, and the highlighted row
/// follows it. This keeps remote navigation predictable and cheap no matter how
/// many episodes a season contains.
class TvEpisodePanel extends StatefulWidget {
  const TvEpisodePanel({
    super.key,
    required this.type,
    required this.list,
    required this.cid,
    required this.onChangeEpisode,
    this.ugcIntroController,
    this.heroTag,
    this.bvid,
    this.aid,
    this.cover,
    this.seasonId,
    this.initialTabIndex = 0,
    this.isSupportReverse,
    this.isReversed,
    this.onReverse,
    this.onClose,
    this.autofocus = false,
  });

  final EpisodeType type;

  /// For [EpisodeType.season] this is a `List<SectionItem>`; otherwise it is a
  /// `List<List<BaseEpisodeItem>>` (a single group).
  final List list;
  final int cid;
  final Future<bool> Function(ugc.BaseEpisodeItem) onChangeEpisode;
  final UgcIntroController? ugcIntroController;
  final String? heroTag;
  final String? bvid;
  final int? aid;
  final String? cover;
  final int? seasonId;
  final int initialTabIndex;
  final bool? isSupportReverse;
  final bool? isReversed;
  final VoidCallback? onReverse;
  final VoidCallback? onClose;
  final bool autofocus;

  @override
  State<TvEpisodePanel> createState() => _TvEpisodePanelState();
}

class _TvEpisodePanelState extends State<TvEpisodePanel> {
  static const double _itemExtent = 76;

  final FocusNode _focusNode = FocusNode(debugLabel: 'TvEpisodePanel');
  final ScrollController _scrollController = ScrollController();

  late int _tabIndex;
  late int _index;
  bool _focused = false;

  int get _tabCount =>
      widget.type == EpisodeType.season ? widget.list.length : 1;

  List<ugc.BaseEpisodeItem> get _episodes {
    if (widget.list.isEmpty) return const [];
    if (widget.type == EpisodeType.season) {
      final section = widget.list[_tabIndex] as SectionItem;
      return section.episodes ?? const [];
    }
    return (widget.list[_tabIndex] as List).cast<ugc.BaseEpisodeItem>();
  }

  String _tabTitle(int index) => widget.type == EpisodeType.season
      ? ((widget.list[index] as SectionItem).title ?? '')
      : widget.type.title;

  int _findCurrentIndex(int tab) {
    if (tab < 0 || tab >= _tabCount) return 0;
    final episodes = widget.type == EpisodeType.season
        ? (widget.list[tab] as SectionItem).episodes ?? const []
        : (widget.list[tab] as List).cast<ugc.BaseEpisodeItem>();
    final index = episodes.indexWhere((e) => e.cid == widget.cid);
    return index < 0 ? 0 : index;
  }

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.type == EpisodeType.season
        ? widget.initialTabIndex.clamp(0, max(0, _tabCount - 1)).toInt()
        : 0;
    _index = _findCurrentIndex(_tabIndex);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToIndex(_index, animate: false),
    );
  }

  @override
  void didUpdateWidget(TvEpisodePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cid == oldWidget.cid && widget.list == oldWidget.list) {
      return;
    }
    final tab = widget.type == EpisodeType.season
        ? widget.initialTabIndex.clamp(0, max(0, _tabCount - 1)).toInt()
        : 0;
    final index = _findCurrentIndex(tab);
    if (tab != _tabIndex || index != _index) {
      setState(() {
        _tabIndex = tab;
        _index = index;
      });
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToIndex(_index, animate: false),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index, {bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final offset = index * _itemExtent;
    final viewport = position.viewportDimension;
    final current = _scrollController.offset;
    double? target;
    if (offset < current) {
      target = offset;
    } else if (offset + _itemExtent > current + viewport) {
      target = offset + _itemExtent - viewport;
    }
    if (target == null) return;
    final clamped = target
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if (animate) {
      _scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(clamped);
    }
  }

  void _switchTab(int delta) {
    final next = (_tabIndex + delta).clamp(0, _tabCount - 1).toInt();
    if (next == _tabIndex) return;
    setState(() {
      _tabIndex = next;
      _index = _findCurrentIndex(next);
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToIndex(_index, animate: false),
    );
  }

  void _select(int index) {
    final episodes = _episodes;
    if (index < 0 || index >= episodes.length) return;
    final episode = episodes[index];
    if (episode.cid == widget.cid) return;
    final title = _dataOf(episode).title;
    if (title.isNotEmpty) {
      SmartDialog.showToast('切换到：$title');
    }
    widget.onClose?.call();
    widget.onChangeEpisode(episode).then((res) {
      if (!mounted || !res) return;
      setState(() => _index = index);
      if (widget.type == EpisodeType.season &&
          widget.ugcIntroController != null) {
        try {
          Get.find<VideoDetailController>(
            tag: widget.ugcIntroController!.heroTag,
          ).seasonCid = episode.cid;
        } catch (_) {}
      }
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final length = _episodes.length;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        if (_index > 0) {
          setState(() => _index--);
          _scrollToIndex(_index);
        } else {
          node.previousFocus();
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        if (_index < length - 1) {
          setState(() => _index++);
          _scrollToIndex(_index);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        if (_tabCount > 1) _switchTab(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        if (_tabCount > 1) _switchTab(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        _select(_index);
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  _TvEpisodeData _dataOf(ugc.BaseEpisodeItem episode) {
    var title = '';
    String? cover;
    int? duration;
    var isCharging = false;
    switch (episode) {
      case Part part:
        cover = part.firstFrame ?? widget.cover;
        title = part.part ?? '';
        duration = part.duration;
      case ugc.EpisodeItem item:
        title = item.title ?? '';
        cover = item.arc?.pic;
        duration = item.arc?.duration;
        isCharging = item.attribute == 8;
      case pgc.EpisodeItem item:
        title = item.showTitle ?? item.title ?? '';
        cover = item.cover;
        duration = item.from == 'pugv'
            ? item.duration
            : (item.duration == null ? null : item.duration! ~/ 1000);
    }
    return _TvEpisodeData(
      title: title,
      cover: cover,
      duration: duration,
      badge: episode.badge,
      isCharging: isCharging,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final episodes = _episodes;
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (value) {
        if (_focused != value) {
          setState(() => _focused = value);
          if (value) _scrollToIndex(_index, animate: false);
        }
      },
      onKeyEvent: _onKey,
      child: netflixSurface(
        radius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colorScheme, episodes.length),
            Expanded(
              child: episodes.isEmpty
                  ? Center(
                      child: Text(
                        '暂无选集',
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.outline,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemExtent: _itemExtent,
                      itemCount: episodes.length,
                      itemBuilder: (context, index) {
                        final episode = episodes[index];
                        return _TvEpisodeRow(
                          data: _dataOf(episode),
                          order: index + 1,
                          isCurrent: episode.cid == widget.cid,
                          isFocused: _focused && index == _index,
                          onTap: () {
                            setState(() => _index = index);
                            _select(index);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  widget.type.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '共 $count 集',
                style: TextStyle(fontSize: 13, color: colorScheme.outline),
              ),
            ],
          ),
          if (_tabCount > 1) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < _tabCount; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AnimatedContainer(
                        duration: TvConstants.focusDuration,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: i == _tabIndex
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _tabTitle(i),
                          style: TextStyle(
                            fontSize: 14,
                            color: i == _tabIndex
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                            fontWeight: i == _tabIndex
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TvEpisodeData {
  const _TvEpisodeData({
    required this.title,
    this.cover,
    this.duration,
    this.badge,
    this.isCharging = false,
  });

  final String title;
  final String? cover;
  final int? duration;
  final String? badge;
  final bool isCharging;
}

class _TvEpisodeRow extends StatelessWidget {
  const _TvEpisodeRow({
    required this.data,
    required this.order,
    required this.isCurrent,
    required this.isFocused,
    required this.onTap,
  });

  final _TvEpisodeData data;
  final int order;
  final bool isCurrent;
  final bool isFocused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlighted = isFocused || isCurrent;
    final child = Row(
      children: [
        SizedBox(
          width: 34,
          child: isCurrent
              ? Icon(
                  Icons.play_arrow_rounded,
                  size: 26,
                  color: colorScheme.primary,
                )
              : Text(
                  '$order',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        if (data.cover?.isNotEmpty == true)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: NetworkImgLayer(
              src: data.cover,
              width: 84,
              height: 48,
              cacheWidth: true,
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              height: 1.25,
              fontWeight: highlighted ? FontWeight.w600 : FontWeight.normal,
              color: isCurrent ? colorScheme.primary : null,
            ),
          ),
        ),
        if (data.isCharging)
          _Pill(text: '充电专属', color: colorScheme.error)
        else if (data.badge?.isNotEmpty == true)
          _Pill(text: data.badge!, color: colorScheme.secondary),
        if (data.duration != null && data.duration! > 0) ...[
          const SizedBox(width: 12),
          Text(
            DurationUtils.formatDuration(data.duration),
            style: TextStyle(fontSize: 14, color: colorScheme.outline),
          ),
          const SizedBox(width: 4),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: TvFocusHighlight(
          focused: isFocused,
          radius: TvConstants.focusRadius,
          child: AnimatedContainer(
            duration: TvConstants.focusDuration,
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isCurrent
                  ? colorScheme.secondaryContainer.withValues(alpha: 0.5)
                  : colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
              borderRadius: BorderRadius.circular(TvConstants.focusRadius),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color),
      ),
    );
  }
}
