import 'package:bplus_tv/common/widgets/app_background.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/marquee.dart';
import 'package:bplus_tv/models/common/video/video_type.dart';
import 'package:bplus_tv/models_new/pgc/pgc_info_model/episode.dart';
import 'package:bplus_tv/models_new/pgc/pgc_info_model/result.dart';
import 'package:bplus_tv/tv/tv_back_bar.dart';
import 'package:bplus_tv/tv/tv_constants.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:bplus_tv/utils/duration_utils.dart';
import 'package:bplus_tv/utils/num_utils.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:material_ui/material_ui.dart';

/// TV PGC (bangumi / cinema) detail page modelled after BLILI's
/// `tv_details_view`: cover + metadata + "立即观看", then horizontal rows for
/// the episode list and any extra sections (PV / 花絮).
class TvPgcDetailPage extends StatelessWidget {
  const TvPgcDetailPage({
    super.key,
    required this.pgcItem,
    this.progress,
    this.off = false,
    this.initialEpId,
  });

  final PgcInfoModel pgcItem;
  final int? progress;
  final bool off;
  final int? initialEpId;

  @override
  Widget build(BuildContext context) {
    final episodes = pgcItem.episodes ?? const [];
    final sections = (pgcItem.section ?? const [])
        .where((e) => e.episodes?.isNotEmpty == true)
        .toList();
    return TvPageFocus(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const AppBackground(),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: LayoutBuilder(
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
                          viewportHeight: constraints.maxHeight,
                        ),
                        if (episodes.isNotEmpty) ...[
                          const SizedBox(height: 36),
                          _EpisodeRow(
                            title: '选集',
                            episodes: episodes,
                            onTap: (episode) =>
                                _play(episode, asSection: false),
                          ),
                        ],
                        for (final section in sections) ...[
                          const SizedBox(height: 28),
                          _EpisodeRow(
                            title: section.title ?? '更多',
                            episodes: section.episodes!,
                            onTap: (episode) => _play(episode, asSection: true),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required double viewportHeight}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final stat = pgcItem.stat;
    final score = pgcItem.rating?.score;
    final statItems = <({IconData icon, String label, String value})>[
      if (score != null && score > 0)
        (
          icon: Icons.star_rounded,
          label: '评分',
          value: score.toStringAsFixed(1),
        ),
      if (stat?.view != null)
        (
          icon: Icons.play_circle_outline_rounded,
          label: '播放',
          value: NumUtils.numFormat(stat!.view),
        ),
      if (stat?.danmaku != null)
        (
          icon: Icons.subtitles_outlined,
          label: '弹幕',
          value: NumUtils.numFormat(stat!.danmaku),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isShort = viewportHeight < 500;
        final isCompact = availableWidth < 1000 || isShort;
        final isStacked = availableWidth < 480;
        final hasCover = pgcItem.cover?.isNotEmpty == true;
        final maxCoverHeight = isShort
            ? (viewportHeight - 96).clamp(72.0, 168.0).toDouble()
            : 280.0;
        final coverWidth = (availableWidth * (isStacked ? 0.36 : 0.22))
            .clamp(0.0, maxCoverHeight / 1.4)
            .toDouble();
        final coverHeight = coverWidth * 1.4;
        final cover = hasCover
            ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: coverWidth,
                  height: coverHeight,
                  child: NetworkImgLayer(
                    src: pgcItem.cover,
                    width: coverWidth,
                    height: coverHeight,
                  ),
                ),
              )
            : null;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarqueeText(
              pgcItem.title ?? '',
              spacing: 80,
              velocity: 45,
              style: TextStyle(
                fontSize: isCompact ? 22 : 28,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            SizedBox(height: isCompact ? 8 : 12),
            _WatchButton(
              compact: isCompact,
              label: progress != null ? '继续观看' : '立即观看',
              onTap: () {
                final episode = _initialEpisode();
                if (episode != null) _play(episode, asSection: false);
              },
            ),
            if (pgcItem.subtitle?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(
                pgcItem.subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompact ? 15 : 17,
                  color: colorScheme.outline,
                ),
              ),
            ],
            if (statItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 18,
                runSpacing: 10,
                children: [
                  for (final item in statItems)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.65,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.icon,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '${item.label} ${item.value}',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        );

        final Widget hero;
        if (isStacked) {
          hero = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              content,
              if (cover != null) ...[
                const SizedBox(height: 16),
                cover,
              ],
            ],
          );
        } else {
          hero = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cover != null) ...[
                cover,
                SizedBox(width: isCompact ? 20 : 32),
              ],
              Expanded(child: content),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            hero,
            if (pgcItem.evaluate?.isNotEmpty == true) ...[
              const SizedBox(height: 20),
              Text(
                pgcItem.evaluate!,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isCompact ? 15 : 17,
                  height: 1.5,
                  color: textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  EpisodeItem? _initialEpisode() {
    final episodes = pgcItem.episodes;
    if (episodes != null && episodes.isNotEmpty) {
      if (initialEpId != null) {
        final match = PageUtils.findEpisode(episodes, epId: initialEpId);
        if (match.epId == initialEpId) return match;
      }
      return PageUtils.findEpisode(
        episodes,
        epId: pgcItem.userStatus?.progress?.lastEpId,
      );
    }
    return pgcItem.section?.firstOrNull?.episodes?.firstOrNull;
  }

  void _play(EpisodeItem episode, {required bool asSection}) {
    if (episode.bvid == null || episode.cid == null) return;
    PageUtils.toVideoPage(
      videoType: asSection ? VideoType.ugc : VideoType.pgc,
      bvid: episode.bvid,
      cid: episode.cid!,
      seasonId: pgcItem.seasonId,
      epId: episode.epId,
      pgcType: asSection ? null : pgcItem.type,
      cover: episode.cover,
      progress: progress,
      extraArguments: asSection
          ? {'pgcApi': true, 'pgcItem': pgcItem}
          : {'pgcItem': pgcItem},
      off: off,
    );
  }
}

class _WatchButton extends StatelessWidget {
  const _WatchButton({
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TvFocusable(
      autofocus: true,
      onTap: onTap,
      builder: (context, focused, hovered) => TvFocusHighlight(
        radius: 14,
        focused: focused,
        child: AnimatedContainer(
          duration: TvConstants.focusDuration,
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
                label,
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
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({
    required this.title,
    required this.episodes,
    required this.onTap,
  });

  final String title;
  final List<EpisodeItem> episodes;
  final ValueChanged<EpisodeItem> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: episodes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final episode = episodes[index];
              return _EpisodeCard(
                episode: episode,
                onTap: () => onTap(episode),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  const _EpisodeCard({required this.episode, required this.onTap});

  final EpisodeItem episode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = episode.longTitle ?? episode.title ?? '';
    final duration = episode.duration;
    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, hovered) => TvFocusHighlight(
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
                          src: episode.cover,
                          width: 224,
                          height: 126,
                        ),
                        if (duration != null && duration > 0)
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
                                DurationUtils.formatDuration(duration ~/ 1000),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        if (episode.badge?.isNotEmpty == true)
                          Positioned(
                            left: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                episode.badge!,
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
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
                      title,
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
      ),
    );
  }
}
