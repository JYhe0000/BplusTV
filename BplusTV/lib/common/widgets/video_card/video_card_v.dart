import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/badge.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/image/image_save.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/stat/stat.dart';
import 'package:bplus_tv/common/widgets/video_popup_menu.dart';
import 'package:bplus_tv/http/search.dart';
import 'package:bplus_tv/models/home/rcmd/result.dart';
import 'package:bplus_tv/models/model_rec_video_item.dart';
import 'package:bplus_tv/models_new/video/video_detail/dimension.dart';
import 'package:bplus_tv/tv/tv_card.dart';
import 'package:bplus_tv/utils/app_scheme.dart';
import 'package:bplus_tv/utils/date_utils.dart';
import 'package:bplus_tv/utils/duration_utils.dart';
import 'package:bplus_tv/utils/extension/dimension_ext.dart';
import 'package:bplus_tv/utils/id_utils.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

// 视频卡片 - 垂直布局
class VideoCardV extends StatelessWidget {
  final BaseRcmdVideoItemModel videoItem;
  final VoidCallback? onRemove;
  final bool autofocus;
  final double? gridCoverWidth;

  const VideoCardV({
    super.key,
    required this.videoItem,
    this.onRemove,
    this.autofocus = false,
    this.gridCoverWidth,
  });

  Future<void> onPushDetail() async {
    switch (videoItem.goto) {
      case 'bangumi':
        PageUtils.viewPgc(epId: videoItem.param!);
        break;
      case 'av':
        var bvid = videoItem.bvid ?? IdUtils.av2bv(videoItem.aid!);
        var cid = videoItem.cid;
        bool isVertical = false;
        Dimension? dimension;
        if (videoItem is RcmdVideoItemAppModel) {
          if (videoItem.uri case final uri?) {
            isVertical = uri.isVerticalFromUri;
          }
        }
        if (cid == null) {
          if (await SearchHttp.ab2cWithDimension(aid: videoItem.aid, bvid: bvid)
              case final res?) {
            cid = res.cid;
            dimension = res.dimension;
          }
        }
        if (cid != null) {
          PageUtils.toVideoPage(
            aid: videoItem.aid,
            bvid: bvid,
            cid: cid,
            cover: videoItem.cover,
            title: videoItem.title,
            isVertical: isVertical,
            dimension: dimension,
          );
        }
        break;
      // 动态
      case 'picture':
        try {
          PiliScheme.routePushFromUrl(videoItem.uri!);
        } catch (err) {
          SmartDialog.showToast(err.toString());
        }
        break;
      default:
        if (videoItem.uri?.isNotEmpty == true) {
          PiliScheme.routePushFromUrl(videoItem.uri!);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coverWidth = gridCoverWidth;
    void onLongPress() {
      if (videoItem.goto == 'av') {
        VideoPopupMenu.show(
          context,
          videoItem: videoItem,
          onRemove: onRemove,
        );
        return;
      }
      imageSaveDialog(
        title: videoItem.title,
        cover: videoItem.cover,
        bvid: videoItem.bvid,
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        TvCard(
          onTap: onPushDetail,
          onLongPress: onLongPress,
          autofocus: autofocus,
          radius: 12,
          focusColor: Theme.of(context).colorScheme.primary,
          child: NetflixSegment(
            radius: 12,
            child: Column(
              crossAxisAlignment: .start,
              children: [
                AspectRatio(
                  aspectRatio: Style.aspectRatio,
                  child: coverWidth == null
                      ? LayoutBuilder(
                          builder: (context, constraints) => _cover(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ),
                        )
                      : _cover(
                          coverWidth,
                          coverWidth / Style.aspectRatio,
                          clip: false,
                        ),
                ),
                content(context),
              ],
            ),
          ),
        ),
        if (videoItem.goto == 'av')
          Positioned(
            right: -5,
            bottom: -2,
            width: 29,
            height: 29,
            child: coverWidth == null
                ? VideoPopupMenu(
                    iconSize: 17,
                    videoItem: videoItem,
                    onRemove: onRemove,
                  )
                : Builder(
                    builder: (context) => Semantics(
                      button: true,
                      label: MaterialLocalizations.of(context).showMenuTooltip,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => VideoPopupMenu.show(
                          context,
                          videoItem: videoItem,
                          onRemove: onRemove,
                          openBelow: true,
                        ),
                        child: Icon(
                          Icons.more_vert_outlined,
                          color: ColorScheme.of(context).outline,
                          size: 17,
                        ),
                      ),
                    ),
                  ),
          ),
      ],
    );
  }

  Widget _cover(double width, double height, {bool clip = true}) => Stack(
    clipBehavior: Clip.none,
    children: [
      NetworkImgLayer(
        src: videoItem.cover,
        width: width,
        height: height,
        borderRadius: const .vertical(top: .circular(12)),
        clip: clip,
      ),
      if (videoItem.duration > 0)
        PBadge(
          bottom: 6,
          right: 7,
          size: .small,
          type: .gray,
          text: DurationUtils.formatDuration(videoItem.duration),
        ),
    ],
  );

  Widget content(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const .fromLTRB(6, 5, 6, 5),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Expanded(
              child: Text(
                videoItem.title,
                maxLines: 2,
                overflow: .ellipsis,
                style: const TextStyle(height: 1.38),
              ),
            ),
            videoStat(theme),
            Row(
              spacing: 2,
              children: [
                if (videoItem.goto == 'bangumi')
                  PBadge(
                    text: videoItem.pgcBadge,
                    isStack: false,
                    size: .small,
                    type: .line_primary,
                    fontSize: 9,
                  ),
                if (videoItem.rcmdReason != null)
                  PBadge(
                    text: videoItem.rcmdReason,
                    isStack: false,
                    size: .small,
                    type: .secondary,
                  ),
                if (videoItem.goto == 'picture')
                  const PBadge(
                    text: '动态',
                    isStack: false,
                    size: .small,
                    type: .line_primary,
                    fontSize: 9,
                  ),
                if (videoItem.isFollowed)
                  const PBadge(
                    text: '已关注',
                    isStack: false,
                    size: .small,
                    type: .secondary,
                  ),
                // Flexible, not Expanded: with several badges on the left the
                // name was being squeezed to nothing. Loose fit lets it take
                // only what it needs and ellipsise the rest.
                Flexible(
                  child: Text(
                    videoItem.owner.name.toString(),
                    maxLines: 1,
                    overflow: .ellipsis,
                    semanticsLabel: 'UP：${videoItem.owner.name}',
                    style: TextStyle(
                      height: 1.5,
                      fontSize: theme.textTheme.labelMedium!.fontSize,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                if (videoItem.goto == 'av') const SizedBox(width: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static final shortFormat = DateFormat('M-d');
  static final longFormat = DateFormat('yy-M-d');

  Widget videoStat(ThemeData theme) {
    return Row(
      children: [
        StatWidget(
          type: .play,
          value: videoItem.stat.view,
        ),
        if (videoItem.goto != 'picture') ...[
          const SizedBox(width: 4),
          StatWidget(
            type: .danmaku,
            value: videoItem.stat.danmu,
          ),
        ],
        if (videoItem is RcmdVideoItemModel) ...[
          const Spacer(),
          Text.rich(
            maxLines: 1,
            TextSpan(
              style: TextStyle(
                fontSize: theme.textTheme.labelSmall!.fontSize,
                color: theme.colorScheme.outline.withValues(alpha: 0.8),
              ),
              text: DateFormatUtils.dateFormat(
                videoItem.pubdate,
                short: shortFormat,
                long: longFormat,
              ),
            ),
          ),
          const SizedBox(width: 2),
        ],
      ],
    );
  }
}
