import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/badge.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/progress_bar/video_progress_indicator.dart';
import 'package:bplus_tv/common/widgets/select_mask.dart';
import 'package:bplus_tv/http/search.dart';
import 'package:bplus_tv/http/user.dart';
import 'package:bplus_tv/models/common/badge_type.dart';
import 'package:bplus_tv/models_new/history/list.dart';
import 'package:bplus_tv/models_new/video/video_detail/dimension.dart';
import 'package:bplus_tv/pages/common/multi_select/base.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/date_utils.dart';
import 'package:bplus_tv/utils/duration_utils.dart';
import 'package:bplus_tv/utils/id_utils.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class HistoryItem extends StatelessWidget {
  final HistoryItemModel item;
  final MultiSelectBase ctr;
  final void Function(int kid, String business) onDelete;

  const HistoryItem({
    super.key,
    required this.item,
    required this.ctr,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDuration = item.duration != null && item.duration != 0;
    int aid = item.history.oid!;
    String bvid = item.history.bvid ?? IdUtils.av2bv(aid);
    final business = item.history.business;
    final enableMultiSelect = ctr.enableMultiSelect.value;

    final onLongPress = enableMultiSelect
        ? null
        : () => ctr
            ..enableMultiSelect.value = true
            ..onSelect(item);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        focusColor: theme.colorScheme.primary.withValues(alpha: 0.2),
        onTap: enableMultiSelect
            ? () => ctr.onSelect(item)
            : () async {
                if (business?.contains('article') == true) {
                  PageUtils.toDupNamed(
                    '/articlePage',
                    parameters: {
                      'id': business == 'article-list'
                          ? '${item.history.cid}'
                          : '${item.history.oid}',
                      'type': 'read',
                    },
                  );
                } else if (business == 'live') {
                  if (item.liveStatus == 1) {
                    PageUtils.toLiveRoom(item.history.oid);
                  } else {
                    SmartDialog.showToast('直播未开播');
                  }
                } else if (business == 'pgc') {
                  PageUtils.viewPgc(
                    epId: item.history.epid,
                    progress: item.playbackProgress,
                  );
                } else if (business == 'cheese') {
                  if (item.uri?.isNotEmpty == true) {
                    PageUtils.viewPgcFromUri(
                      item.uri!,
                      isPgc: false,
                      aid: item.history.oid,
                      progress: item.playbackProgress,
                    );
                  }
                } else {
                  int? cid = item.history.cid;
                  Dimension? dimension;
                  if (cid == null) {
                    if (await SearchHttp.ab2cWithDimension(
                          aid: aid,
                          bvid: bvid,
                          part: item.history.page,
                        )
                        case final res?) {
                      cid = res.cid;
                      dimension = res.dimension;
                    }
                  }
                  if (cid != null) {
                    // TODO: dimension
                    PageUtils.toVideoPage(
                      aid: aid,
                      bvid: bvid,
                      cid: cid,
                      cover: item.cover,
                      title: item.title,
                      dimension: dimension,
                      progress: item.playbackProgress,
                    );
                  }
                }
              },
        onLongPress: onLongPress,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Style.safeSpace,
                vertical: 5,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: Style.aspectRatio,
                    child: LayoutBuilder(
                      builder: (context, boxConstraints) {
                        double maxWidth = boxConstraints.maxWidth;
                        double maxHeight = boxConstraints.maxHeight;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            NetworkImgLayer(
                              src: item.cover?.isNotEmpty == true
                                  ? item.cover
                                  : item.covers?.firstOrNull ?? '',
                              width: maxWidth,
                              height: maxHeight,
                            ),
                            if (hasDuration)
                              PBadge(
                                text: item.progress == -1
                                    ? '已看完'
                                    : '${DurationUtils.formatDuration(item.progress)}/${DurationUtils.formatDuration(item.duration)}',
                                right: 6.0,
                                bottom: 8.0,
                                type: PBadgeType.gray,
                              ),
                            if (item.isFav == 1)
                              const PBadge(
                                text: '已收藏',
                                top: 6.0,
                                right: 6.0,
                                type: PBadgeType.gray,
                              )
                            else if (item.badge?.isNotEmpty == true)
                              PBadge(
                                text: item.badge,
                                top: 6.0,
                                right: 6.0,
                                type: business == 'live' && item.liveStatus != 1
                                    ? PBadgeType.gray
                                    : PBadgeType.primary,
                              ),
                            if (hasDuration &&
                                item.progress != null &&
                                item.progress != 0)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: VideoProgressIndicator(
                                  color: theme.colorScheme.primary,
                                  backgroundColor:
                                      theme.colorScheme.secondaryContainer,
                                  progress: item.progress == -1
                                      ? 1
                                      : item.progress! / item.duration!,
                                ),
                              ),
                            Positioned.fill(
                              child: selectMask(
                                theme.colorScheme,
                                item.checked,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  content(theme),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: 0,
              width: 48,
              height: 48,
              child: TvFocusable(
                onTap: () => _showTvMenu(context),
                builder: (context, focused, hovered) => TvFocusHighlight(
                  focused: focused,
                  radius: 12,
                  child: Center(
                    child: Icon(
                      Icons.more_vert_outlined,
                      color: focused
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTvMenu(BuildContext pageContext) {
    final business = item.history.business;
    showDialog(
      context: pageContext,
      builder: (dialogContext) => tvDialogShell(
        title: '更多',
        minWidth: 420,
        content: const SizedBox.shrink(),
        actions: [
          if (item.authorMid != null && item.authorName?.isNotEmpty == true)
            TvDialogAction(
              label: '访问：${item.authorName}',
              autofocus: true,
              onTap: () => Get
                ..back()
                ..toNamed('/member?mid=${item.authorMid}'),
            ),
          if (business != 'pgc' &&
              item.badge != '番剧' &&
              item.tagName?.contains('动画') != true &&
              business != 'live' &&
              business?.contains('article') != true)
            TvDialogAction(
              label: '稍后再看',
              onTap: () {
                Get.back();
                UserHttp.toViewLater(bvid: item.history.bvid);
              },
            ),
          TvDialogAction(
            label: '删除记录',
            onTap: () {
              Get.back();
              onDelete(item.kid!, business!);
            },
          ),
        ],
      ),
    );
  }

  Widget content(ThemeData theme) {
    return Expanded(
      child: Column(
        spacing: 2,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title!,
            style: TextStyle(
              fontSize: 16,
              height: 1.3,
              letterSpacing: 0.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (item.history.business == 'pgc' &&
              item.showTitle?.isNotEmpty == true)
            Text(
              item.showTitle!,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.outline,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const Spacer(),
          if (item.authorName?.isNotEmpty == true)
            Text(
              item.authorName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: theme.textTheme.labelMedium!.fontSize,
                color: theme.colorScheme.outline,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 48),
            child: Text(
              DateFormatUtils.chatFormat(item.viewAt!, isHistory: true),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: theme.textTheme.labelMedium!.fontSize,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
