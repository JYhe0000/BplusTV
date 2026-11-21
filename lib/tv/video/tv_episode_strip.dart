import 'dart:math';

import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/models_new/pgc/pgc_info_model/episode.dart' as pgc;
import 'package:bplus_tv/models_new/video/video_detail/episode.dart' as ugc;
import 'package:bplus_tv/models_new/video/video_detail/page.dart';
import 'package:bplus_tv/pages/video/controller.dart';
import 'package:bplus_tv/pages/video/introduction/ugc/controller.dart';
import 'package:bplus_tv/tv/tv_constants.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/duration_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// One selectable group inside [TvEpisodeStrip] (a video's own parts, a season
/// section, or a PGC episode list).
class TvEpisodeGroup {
  const TvEpisodeGroup({
    required this.title,
    required this.episodes,
    this.isSeason = false,
  });

  final String title;
  final List<ugc.BaseEpisodeItem> episodes;

  /// Whether picking an episode here should also update the season's current
  /// cid (used to keep the season position in sync).
  final bool isSeason;
}

/// Compact bottom episode selector for the TV player.
///
/// A short horizontal strip of thumbnail cards that slides in from the bottom
/// on the DOWN key. It is deliberately small (about a quarter of the screen)
/// so it never covers the video the way a full-height side panel would.
class TvEpisodeStrip extends StatefulWidget {
  const TvEpisodeStrip({
    super.key,
    required this.groups,
    required this.cid,
    required this.onChangeEpisode,
    this.title = '选集',
    this.ugcIntroController,
    this.heroTag,
    this.cover,
    this.initialTabIndex = 0,
    this.onClose,
  });

  final List<TvEpisodeGroup> groups;
  final String title;
  final int cid;
  final Future<bool> Function(ugc.BaseEpisodeItem) onChangeEpisode;
  final UgcIntroController? ugcIntroController;
  final String? heroTag;
  final String? cover;
  final int initialTabIndex;
  final VoidCallback? onClose;

  @override
  State<TvEpisodeStrip> createState() => _TvEpisodeStripState();
}

class _TvEpisodeStripState extends State<TvEpisodeStrip> {
  static const double _cardWidth = 124;
  static const double _thumbHeight = 70;
  static const double _itemExtent = 138;

  final FocusNode _focusNode = FocusNode(debugLabel: 'TvEpisodeStrip');
  final ScrollController _scroll = ScrollController();

  late int _tabIndex;
  late int _index;

  /// 0 = group tab row, 1 = card row.
  int _row = 1;
  bool _focused = false;

  int get _tabCount => widget.groups.length;

  List<ugc.BaseEpisodeItem> get _episodes =>
      _tabCount == 0 ? const [] : widget.groups[_tabIndex].episodes;

  int _findCurrentIndex(int tab) {
    if (tab < 0 || tab >= _tabCount) return 0;
    final index = widget.groups[tab].episodes.indexWhere(
      (e) => e.cid == widget.cid,
    );
    return index < 0 ? 0 : index;
  }

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTabIndex.clamp(0, max(0, _tabCount - 1)).toInt();
    _index = _findCurrentIndex(_tabIndex);
    // The player's Focus already owns focus, so `autofocus` alone is not
    // enough here: take focus explicitly once the strip is on screen, so the
    // very next D-pad press moves inside the strip instead of first moving
    // focus onto it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      _scrollToIndex(_index, animate: false);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index, {bool animate = true}) {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final offset = index * _itemExtent;
    final viewport = position.viewportDimension;
    final current = _scroll.offset;
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
      _scroll.animateTo(
        clamped,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    } else {
      _scroll.jumpTo(clamped);
    }
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
    final isSeason = widget.groups[_tabIndex].isSeason;
    widget.onChangeEpisode(episode).then((res) {
      if (!mounted || !res) return;
      setState(() => _index = index);
      if (isSeason && widget.ugcIntroController != null) {
        try {
          Get.find<VideoDetailController>(
            tag: widget.ugcIntroController!.heroTag,
          ).seasonCid = episode.cid;
        } catch (_) {}
      }
    });
  }

  void _changeTab(int delta) {
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

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final length = _episodes.length;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (_row == 0) {
          _changeTab(-1);
        } else if (_index > 0) {
          setState(() => _index--);
          _scrollToIndex(_index);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        if (_row == 0) {
          _changeTab(1);
        } else if (_index < length - 1) {
          setState(() => _index++);
          _scrollToIndex(_index);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        if (_row == 1 && _tabCount > 1) {
          setState(() => _row = 0);
        } else {
          widget.onClose?.call();
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        if (_row == 0) {
          setState(() => _row = 1);
          _scrollToIndex(_index, animate: false);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        if (_row == 0) {
          setState(() => _row = 1);
          _scrollToIndex(_index, animate: false);
        } else {
          _select(_index);
        }
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
    return Align(
      alignment: Alignment.bottomCenter,
      child: netflixSurface(
        radius: 18,
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onFocusChange: (value) {
            if (_focused != value) {
              setState(() => _focused = value);
              if (value) _scrollToIndex(_index, animate: false);
            }
          },
          onKeyEvent: _onKey,
          child: SizedBox(
            height: 172,
            width: double.infinity,
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
                              fontSize: 16,
                              color: colorScheme.outline,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                          itemExtent: _itemExtent,
                          itemCount: episodes.length,
                          itemBuilder: (context, index) {
                            final episode = episodes[index];
                            return _TvEpisodeCard(
                              data: _dataOf(episode),
                              order: index + 1,
                              isCurrent: episode.cid == widget.cid,
                              isFocused:
                                  _focused && _row == 1 && index == _index,
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
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Flexible(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '共 $count 集',
            style: TextStyle(fontSize: 12, color: colorScheme.outline),
          ),
          if (_tabCount > 1) ...[
            const SizedBox(width: 20),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < _tabCount; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AnimatedContainer(
                          duration: TvConstants.focusDuration,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: i == _tabIndex
                                ? colorScheme.primary
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.groups[i].title,
                            style: TextStyle(
                              fontSize: 13,
                              color: i == _tabIndex
                                  ? colorScheme.onPrimary
                                  : Colors.white70,
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

class _TvEpisodeCard extends StatelessWidget {
  const _TvEpisodeCard({
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
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              SizedBox(
                width: _TvEpisodeStripState._cardWidth,
                height: _TvEpisodeStripState._thumbHeight,
                child: data.cover?.isNotEmpty == true
                    ? NetworkImgLayer(
                        src: data.cover,
                        width: _TvEpisodeStripState._cardWidth,
                        height: _TvEpisodeStripState._thumbHeight,
                        cacheWidth: true,
                      )
                    : const ColoredBox(color: Colors.black26),
              ),
              if (isCurrent)
                Positioned.fill(
                  child: ColoredBox(
                    color: colorScheme.primary.withValues(alpha: 0.38),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              Positioned(
                left: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '$order',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (data.duration != null && data.duration! > 0)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      DurationUtils.formatDuration(data.duration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          data.title.isEmpty ? '第$order集' : data.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: isCurrent ? colorScheme.primary : Colors.white,
            fontWeight: isFocused || isCurrent
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
        if (data.isCharging)
          Text(
            '充电专属',
            style: TextStyle(fontSize: 11, color: colorScheme.error),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: TvFocusHighlight(
          focused: isFocused,
          radius: TvConstants.focusRadius,
          borderWidth: 2,
          color: colorScheme.primary,
          child: AnimatedContainer(
            duration: TvConstants.focusDuration,
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isCurrent
                  ? colorScheme.secondaryContainer.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(TvConstants.focusRadius),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
