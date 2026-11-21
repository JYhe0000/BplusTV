import 'package:bplus_tv/common/widgets/app_background.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/marquee.dart';
import 'package:bplus_tv/common/widgets/video_popup_menu.dart';
import 'package:bplus_tv/grpc/bilibili/main/community/reply/v1.pbenum.dart'
    show Mode;
import 'package:bplus_tv/grpc/bilibili/main/community/reply/v1.pb.dart'
    show ReplyInfo;
import 'package:bplus_tv/grpc/reply.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/http/video.dart';
import 'package:bplus_tv/models/model_hot_video_item.dart';
import 'package:bplus_tv/models_new/video/video_detail/data.dart';
import 'package:bplus_tv/models_new/video/video_detail/episode.dart' as ugc;
import 'package:bplus_tv/models_new/video/video_detail/page.dart';
import 'package:bplus_tv/models_new/video/video_detail/section.dart';
import 'package:bplus_tv/tv/tv_back_bar.dart';
import 'package:bplus_tv/tv/tv_constants.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:bplus_tv/utils/date_utils.dart';
import 'package:bplus_tv/utils/duration_utils.dart';
import 'package:bplus_tv/utils/num_utils.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// BLILI-style TV detail page for regular (UGC) videos: cover + metadata +
/// "立即观看", then horizontal rows for parts / season sections, recommended
/// videos and the top comments.
class TvVideoDetailPage extends StatefulWidget {
  const TvVideoDetailPage({
    super.key,
    required this.bvid,
    this.aid,
    this.cid,
    this.title,
    this.cover,
    this.progress,
  });

  final String bvid;
  final int? aid;
  final int? cid;
  final String? title;
  final String? cover;
  final int? progress;

  @override
  State<TvVideoDetailPage> createState() => _TvVideoDetailPageState();
}

class _TvVideoDetailPageState extends State<TvVideoDetailPage> {
  bool _loading = true;
  String? _error;
  VideoDetailData? _detail;
  List<HotVideoItemModel> _related = const [];
  List<ReplyInfo> _comments = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await VideoHttp.videoIntro(bvid: widget.bvid);
    if (!mounted) return;
    if (res case Success(:final response)) {
      setState(() {
        _detail = response;
        _loading = false;
      });
      _loadRelated();
      _loadComments(response.aid ?? widget.aid);
    } else if (res case Error(:final errMsg)) {
      setState(() {
        _loading = false;
        _error = errMsg;
      });
    }
  }

  Future<void> _loadRelated() async {
    final res = await VideoHttp.relatedVideoList(bvid: widget.bvid);
    if (!mounted) return;
    if (res case Success(:final response)) {
      setState(() => _related = response ?? const []);
    }
  }

  Future<void> _loadComments(int? aid) async {
    if (aid == null) return;
    final res = await ReplyGrpc.mainList(
      oid: aid,
      mode: Mode.MAIN_LIST_HOT,
      offset: null,
      cursorNext: null,
    );
    if (!mounted) return;
    if (res case Success(:final response)) {
      setState(() => _comments = response.replies.take(6).toList());
    }
  }

  /// D-pad navigation: moves focus via normal traversal, then scrolls the
  /// vertical page so the newly focused widget stays visible. When traversal
  /// cannot move any further (first/last focusable on page), jumps straight to
  /// the top / bottom so the whole page can still be reached.
  KeyEventResult _handleNavKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.arrowDown:
        final before = FocusManager.instance.primaryFocus;
        final isUp = event.logicalKey == LogicalKeyboardKey.arrowUp;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (FocusManager.instance.primaryFocus == before) {
            _scrollToVerticalEnd(isUp ? 0.0 : double.infinity);
          } else {
            _scrollToFocused(isUp: isUp);
          }
        });
        return KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  ScrollableState? _verticalScrollable([BuildContext? from]) {
    final ctx = from ?? FocusManager.instance.primaryFocus?.context;
    if (ctx is! BuildContext || !ctx.mounted) return null;
    ScrollableState? vertical;
    ctx.visitAncestorElements((element) {
      final w = element.widget;
      if (w is Scrollable && w.axisDirection == AxisDirection.down) {
        vertical = (element as StatefulElement).state as ScrollableState;
        return false;
      }
      return true;
    });
    return vertical;
  }

  void _scrollToVerticalEnd(double target) {
    final vertical = _verticalScrollable();
    if (vertical == null) return;
    final position = vertical.position;
    final clamped = target.isFinite
        ? target.clamp(position.minScrollExtent, position.maxScrollExtent)
        : position.maxScrollExtent;
    position.animateTo(
      clamped,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  /// Whether [node] is the top-most focusable of its scope, i.e. no other
  /// focusable widget sits above it. Used so that moving up onto the first
  /// focusable (e.g. the header's "进入主页") also scrolls the page all the way
  /// back to the top in a single press.
  bool _isTopmostFocusable(FocusNode node) {
    final scope = node.nearestScope;
    if (scope == null) return false;
    final object = node.context?.findRenderObject();
    if (object is! RenderBox || !object.attached) return false;
    final top = object.localToGlobal(Offset.zero).dy;
    for (final other in scope.traversalDescendants) {
      if (identical(other, node)) continue;
      final ctx = other.context;
      if (ctx == null || !ctx.mounted) continue;
      final box = ctx.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      if (box.localToGlobal(Offset.zero).dy < top - 1) return false;
    }
    return true;
  }

  void _scrollToFocused({required bool isUp}) {
    final node = FocusManager.instance.primaryFocus;
    final ctx = node?.context;
    if (ctx is! BuildContext || !ctx.mounted) return;
    final mediaRow = ctx.findAncestorStateOfType<_MediaRowState>();
    if (mediaRow != null) {
      mediaRow.reveal();
      return;
    }
    final object = ctx.findRenderObject();
    if (object is! RenderBox || !object.attached) return;
    final vertical = _verticalScrollable();
    if (vertical == null) return;
    final scrollableBox = vertical.context.findRenderObject() as RenderBox;
    if (!scrollableBox.attached) return;
    // Moving up onto the first focusable should reveal the whole header, even
    // if that widget itself is already on screen.
    if (isUp && node != null && _isTopmostFocusable(node)) {
      vertical.position.animateTo(
        0.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      return;
    }
    final viewportRect =
        scrollableBox.localToGlobal(Offset.zero) & scrollableBox.size;
    final objectRect = object.localToGlobal(Offset.zero) & object.size;
    if (objectRect.bottom <= viewportRect.bottom &&
        objectRect.top >= viewportRect.top) {
      return;
    }
    // The focused widget sits on the first screen (little to nothing above
    // it) but is currently above the viewport: bring the page all the way
    // back to the top instead of leaving it mid-scroll.
    // objectRect 是全局坐标，需减去 viewport 的全局偏移换成内容坐标，
    // 再叠加已滚动的 pixels，才能与 viewportDimension（长度）同量纲比较。
    final contentTop =
        objectRect.top - viewportRect.top + vertical.position.pixels;
    if (contentTop < vertical.position.viewportDimension) {
      vertical.position.animateTo(
        0.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      return;
    }
    vertical.position.ensureVisible(
      object,
      alignment: 0.12,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _revealMediaRow(BuildContext context) {
    final object = context.findRenderObject();
    if (object is! RenderBox || !object.attached || !object.hasSize) return;
    final vertical = _verticalScrollable(context);
    if (vertical == null) return;
    final viewportObject = vertical.context.findRenderObject();
    if (viewportObject is! RenderBox || !viewportObject.attached) return;

    final viewportRect =
        viewportObject.localToGlobal(Offset.zero) & viewportObject.size;
    final rowRect = object.localToGlobal(Offset.zero) & object.size;
    if (rowRect.top >= viewportRect.top &&
        rowRect.bottom <= viewportRect.bottom) {
      return;
    }
    vertical.position.ensureVisible(
      object,
      alignment: 0.12,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _playDefault() {
    final detail = _detail;
    if (detail == null) return;
    final cid = widget.cid ?? detail.cid;
    if (cid == null) return;
    PageUtils.toVideoPage(
      bvid: detail.bvid ?? widget.bvid,
      aid: detail.aid ?? widget.aid,
      cid: cid,
      cover: detail.pic ?? widget.cover,
      title: detail.title ?? widget.title,
      progress: widget.progress,
      direct: true,
    );
  }

  void _playPart(Part part) {
    final detail = _detail;
    if (part.cid == null) return;
    PageUtils.toVideoPage(
      bvid: detail?.bvid ?? widget.bvid,
      aid: detail?.aid ?? widget.aid,
      cid: part.cid!,
      cover: part.firstFrame ?? detail?.pic ?? widget.cover,
      title: part.part,
      progress: widget.progress,
      direct: true,
    );
  }

  void _playEpisode(ugc.EpisodeItem episode) {
    if (episode.cid == null) return;
    PageUtils.toVideoPage(
      bvid: episode.bvid ?? _detail?.bvid ?? widget.bvid,
      aid: episode.aid ?? _detail?.aid ?? widget.aid,
      cid: episode.cid!,
      seasonId: _detail?.seasonId,
      epId: episode.epId,
      cover: episode.cover,
      title: episode.title,
      progress: widget.progress,
      direct: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_loading) {
      return const TvPageFocus(
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppBackground(),
            Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(child: CircularProgressIndicator()),
            ),
            TvBackOverlay(),
          ],
        ),
      );
    }
    if (_error != null || _detail == null) {
      return TvPageFocus(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const AppBackground(),
            Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: Text(
                  _error ?? '加载失败',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ),
            const TvBackOverlay(),
          ],
        ),
      );
    }
    final detail = _detail!;
    final pages = detail.pages ?? const <Part>[];
    final sections = (detail.ugcSeason?.sections ?? const <SectionItem>[])
        .where((e) => e.episodes?.isNotEmpty == true)
        .toList();

    return TvPageFocus(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const AppBackground(),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: Focus(
              onKeyEvent: _handleNavKey,
              skipTraversal: true,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1720),
                      child: ListView(
                        padding: const EdgeInsets.all(
                          TvConstants.focusHalo + 2,
                        ),
                        children: [
                          const TvBackRow(),
                          const SizedBox(height: 8),
                          _buildHeader(
                            context,
                            detail,
                            viewportHeight: constraints.maxHeight,
                          ),
                          if (pages.length > 1) ...[
                            const SizedBox(height: 32),
                            _MediaRow(
                              title: '分P',
                              onReveal: _revealMediaRow,
                              items: [
                                for (final part in pages)
                                  _MediaData(
                                    title: part.part ?? '',
                                    cover: part.firstFrame ?? detail.pic,
                                    duration: part.duration,
                                    onTap: () => _playPart(part),
                                  ),
                              ],
                            ),
                          ],
                          for (final section in sections) ...[
                            const SizedBox(height: 32),
                            _MediaRow(
                              title: section.title ?? '选集',
                              onReveal: _revealMediaRow,
                              items: [
                                for (final episode in section.episodes!)
                                  _MediaData(
                                    title: episode.title ?? '',
                                    cover: episode.cover,
                                    duration: episode.arc?.duration,
                                    onTap: () => _playEpisode(episode),
                                  ),
                              ],
                            ),
                          ],
                          if (_related.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            _MediaRow(
                              title: '推荐视频',
                              onReveal: _revealMediaRow,
                              items: [
                                for (final item in _related)
                                  _MediaData(
                                    title: item.title,
                                    cover: item.cover,
                                    duration: item.duration,
                                    subtitle:
                                        '${item.owner.name}  ·  ${NumUtils.numFormat(item.stat.view ?? 0)} 播放',
                                    onTap: () => PageUtils.toVideoPage(
                                      bvid: item.bvid!,
                                      cid: item.cid!,
                                      cover: item.cover,
                                      title: item.title,
                                      direct: true,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                          if (_comments.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            const Text(
                              '评论',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            for (final comment in _comments)
                              _CommentTile(item: comment),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    VideoDetailData detail, {
    required double viewportHeight,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final stat = detail.stat;
    final publishTime = DateFormatUtils.dateFormat(detail.pubdate ?? 0);
    final statItems = <({IconData icon, String label, String text})>[
      (
        icon: Icons.play_circle_outline_rounded,
        label: '播放',
        text: NumUtils.numFormat(stat?.view ?? 0),
      ),
      (
        icon: Icons.subtitles_outlined,
        label: '弹幕',
        text: NumUtils.numFormat(stat?.danmaku ?? 0),
      ),
      (
        icon: Icons.thumb_up_outlined,
        label: '点赞',
        text: NumUtils.numFormat(stat?.like ?? 0),
      ),
      (
        icon: Icons.monetization_on_outlined,
        label: '投币',
        text: NumUtils.numFormat(stat?.coin ?? 0),
      ),
      (
        icon: Icons.star_border_rounded,
        label: '收藏',
        text: NumUtils.numFormat(stat?.favorite ?? 0),
      ),
      (
        icon: Icons.mode_comment_outlined,
        label: '评论',
        text: NumUtils.numFormat(stat?.reply ?? 0),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isShort = viewportHeight < 500;
        final isCompact = availableWidth < 1000 || isShort;
        final isStacked = availableWidth < 560;
        final maxCoverHeight = isShort
            ? (viewportHeight - 96).clamp(72.0, 144.0).toDouble()
            : 220.0;
        final coverWidth = (availableWidth * (isStacked ? 0.55 : 0.3))
            .clamp(0.0, maxCoverHeight * 16 / 9)
            .toDouble();
        final coverHeight = coverWidth * 9 / 16;
        final cover = ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: coverWidth,
            height: coverHeight,
            child: NetworkImgLayer(
              src: detail.pic ?? widget.cover,
              width: coverWidth,
              height: coverHeight,
            ),
          ),
        );
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarqueeText(
              detail.title ?? widget.title ?? '',
              spacing: 80,
              velocity: 45,
              style: TextStyle(
                fontSize: isCompact ? 22 : 28,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            SizedBox(height: isCompact ? 8 : 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildWatchButton(context, compact: isCompact),
                _buildMoreActionsButton(context, detail, compact: isCompact),
              ],
            ),
            SizedBox(height: isCompact ? 10 : 14),
            Row(
              children: [
                if (detail.owner?.face case final face?)
                  ClipOval(
                    child: NetworkImgLayer(
                      src: face,
                      width: isCompact ? 32 : 40,
                      height: isCompact ? 32 : 40,
                    ),
                  ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.owner?.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '发布于 $publishTime',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (detail.owner?.mid case final mid?) ...[
              const SizedBox(height: 12),
              TvFocusable(
                onTap: () => Get.toNamed('/member?mid=$mid'),
                builder: (context, focused, hovered) => TvFocusHighlight(
                  radius: 10,
                  focused: focused,
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: TvConstants.minTargetSize,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '进入主页',
                      style: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                for (final item in statItems)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon, size: 18, color: colorScheme.outline),
                      const SizedBox(width: 6),
                      Text(
                        '${item.label} ${item.text}',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        );

        final Widget hero;
        if (isStacked) {
          hero = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              content,
              const SizedBox(height: 16),
              Align(alignment: Alignment.centerLeft, child: cover),
            ],
          );
        } else {
          hero = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              cover,
              SizedBox(width: isCompact ? 20 : 28),
              Expanded(child: content),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            hero,
            if (detail.desc?.isNotEmpty == true) ...[
              const SizedBox(height: 20),
              Text(
                detail.desc!,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildWatchButton(BuildContext context, {required bool compact}) {
    final colorScheme = Theme.of(context).colorScheme;
    return TvFocusable(
      autofocus: true,
      onTap: _playDefault,
      builder: (context, focused, hovered) => TvFocusHighlight(
        radius: 14,
        focused: focused,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: TvConstants.minTargetSize,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 20 : 28,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                size: compact ? 24 : 26,
                color: colorScheme.onPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.progress != null ? '继续观看' : '立即观看',
                style: TextStyle(
                  fontSize: compact ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreActionsButton(
    BuildContext context,
    VideoDetailData detail, {
    required bool compact,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TvFocusable(
      onTap: () => VideoPopupMenu.showTvForDetails(
        context,
        title: detail.title ?? widget.title ?? '',
        bvid: detail.bvid ?? widget.bvid,
        cid: widget.cid ?? detail.cid,
        cover: detail.pic ?? widget.cover,
        ownerName: detail.owner?.name,
        ownerMid: detail.owner?.mid,
      ),
      builder: (context, focused, hovered) => TvFocusHighlight(
        radius: 14,
        focused: focused,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: TvConstants.minTargetSize,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 20,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.more_horiz_rounded,
                size: compact ? 22 : 24,
                color: colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                '更多操作',
                style: TextStyle(
                  fontSize: compact ? 15 : 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaData {
  const _MediaData({
    required this.title,
    required this.onTap,
    this.cover,
    this.duration,
    this.subtitle,
  });

  final String title;
  final String? cover;
  final int? duration;
  final String? subtitle;
  final VoidCallback onTap;
}

class _MediaRow extends StatefulWidget {
  const _MediaRow({
    required this.title,
    required this.items,
    required this.onReveal,
  });

  final String title;
  final List<_MediaData> items;
  final ValueChanged<BuildContext> onReveal;

  @override
  State<_MediaRow> createState() => _MediaRowState();
}

class _MediaRowState extends State<_MediaRow> {
  final GlobalKey _rowKey = GlobalKey();

  void reveal() {
    final rowContext = _rowKey.currentContext;
    if (rowContext != null && rowContext.mounted) {
      widget.onReveal(rowContext);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: _rowKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 216,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) => _MediaCard(
              data: widget.items[index],
              onFocus: reveal,
            ),
          ),
        ),
      ],
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({required this.data, required this.onFocus});

  final _MediaData data;
  final VoidCallback onFocus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TvFocusable(
      onTap: data.onTap,
      onFocusChange: (focused) {
        if (focused) onFocus();
      },
      builder: (context, focused, hovered) {
        return TvFocusHighlight(
          radius: 12,
          focused: focused,
          borderWidth: 2,
          color: colorScheme.primary,
          child: SizedBox(
            width: 236,
            child: NetflixSegment(
              radius: 12,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          NetworkImgLayer(
                            src: data.cover,
                            width: 236,
                            height: 133,
                          ),
                          if (data.duration != null && data.duration! > 0)
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  DurationUtils.formatDuration(data.duration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Text(
                        data.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.25,
                          color: focused ? colorScheme.primary : null,
                          fontWeight: focused
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.item});

  final ReplyInfo item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final member = item.member;
    final message = item.content.message.replaceAll('\n', ' ').trim();
    return TvFocusable(
      builder: (context, focused, hovered) {
        return TvFocusHighlight(
          radius: 10,
          focused: focused,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NetworkImgLayer(
                  type: .avatar,
                  src: member.face,
                  width: 48,
                  height: 48,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.isEmpty ? '[图片]' : message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, height: 1.4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${NumUtils.numFormat(item.like.toInt())} 赞',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
