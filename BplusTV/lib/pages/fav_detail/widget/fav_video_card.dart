import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/badge.dart';
import 'package:bplus_tv/common/widgets/button/icon_button.dart';
import 'package:bplus_tv/common/widgets/image/image_save.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/select_mask.dart';
import 'package:bplus_tv/common/widgets/stat/stat.dart';
import 'package:bplus_tv/grpc/bilibili/app/listener/v1.pbenum.dart'
    show PlaylistSource;
import 'package:bplus_tv/models/common/badge_type.dart';
import 'package:bplus_tv/models/common/stat_type.dart';
import 'package:bplus_tv/models_new/fav/fav_detail/media.dart';
import 'package:bplus_tv/pages/audio/view.dart';
import 'package:bplus_tv/pages/fav_detail/controller.dart';
import 'package:bplus_tv/utils/date_utils.dart';
import 'package:bplus_tv/utils/duration_utils.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

// 收藏视频卡片 - 水平布局
class FavVideoCardH extends StatelessWidget {
  final FavDetailItemModel item;
  final int? index;
  final BaseFavController? ctr;
  final bool enableTvFocus;

  const FavVideoCardH({
    super.key,
    required this.item,
    this.index,
    this.ctr,
    this.enableTvFocus = true,
  }) : assert(ctr == null || index != null);

  bool get isSort => ctr == null;

  @override
  Widget build(BuildContext context) {
    final isOwner = !isSort && ctr!.isOwner;
    late final enableMultiSelect = ctr?.enableMultiSelect.value ?? false;
    final colorScheme = ColorScheme.of(context);

    final onLongPress = isSort || enableMultiSelect
        ? null
        : isOwner && !enableMultiSelect
        ? () {
            ctr!
              ..enableMultiSelect.value = true
              ..onSelect(item);
          }
        : () => imageSaveDialog(
            title: item.title,
            cover: item.cover,
            bvid: item.bvid,
          );

    void onTap() {
      if (isSort) return;
      if (enableMultiSelect) {
        ctr!.onSelect(item);
        return;
      }
      if (!const [0, 16].contains(item.attr)) {
        Get.toNamed('/member?mid=${item.upper?.mid}');
        return;
      }
      switch (item.type) {
        case 12:
          AudioPage.toAudioPage(
            oid: item.id!,
            itemType: 3,
            from: PlaylistSource.AUDIO_CARD,
          );
          break;
        case 24:
          PageUtils.viewPgc(
            seasonId: item.ogv!.seasonId,
            epId: item.id,
          );
          break;
        default:
          ctr!.onViewFav(item, index);
          break;
      }
    }

    final body = Padding(
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
                      src: item.cover,
                      width: maxWidth,
                      height: maxHeight,
                    ),
                    PBadge(
                      text: DurationUtils.formatDuration(item.duration),
                      right: 6.0,
                      bottom: 6.0,
                      type: PBadgeType.gray,
                    ),
                    if (item.type == 12)
                      const PBadge(
                        text: '音频',
                        top: 6.0,
                        right: 6.0,
                        type: PBadgeType.gray,
                      )
                    else
                      PBadge(
                        text: item.ogv?.typeName,
                        top: 6.0,
                        right: 6.0,
                        bottom: null,
                        left: null,
                      ),
                    if (!isSort)
                      Positioned.fill(
                        child: selectMask(
                          colorScheme,
                          item.checked,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          content(context, colorScheme, isOwner),
        ],
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: (enableTvFocus
          ? TvFocusable(
              onTap: isSort ? null : onTap,
              onLongPress: onLongPress,
              builder: (context, focused, hovered) => TvFocusHighlight(
                focused: focused,
                radius: 12,
                child: body,
              ),
            )
          : body),
    );
  }

  Widget content(BuildContext context, ColorScheme colorScheme, bool isOwner) {
    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            spacing: 3,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title!,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.type == 24 && item.intro?.isNotEmpty == true)
                Text(
                  item.intro!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.outline,
                  ),
                ),
              const Spacer(),
              Text(
                '${DateFormatUtils.dateFormat(item.favTime)} ${item.upper?.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  height: 1,
                  fontSize: 12,
                  color: colorScheme.outline,
                ),
              ),
              if (item.type != 24)
                Row(
                  spacing: 8,
                  children: [
                    StatWidget(
                      type: StatType.play,
                      value: item.cntInfo?.play,
                    ),
                    StatWidget(
                      type: StatType.danmaku,
                      value: item.cntInfo?.danmaku,
                    ),
                  ],
                ),
            ],
          ),
          if (isOwner)
            Positioned(
              right: 0,
              bottom: -8,
              child: iconButton(
                size: 48,
                icon: const Icon(Icons.clear),
                tooltip: '取消收藏',
                iconColor: colorScheme.outline,
                onPressed: () {
                  {
                    showTvConfirm(
                      context: context,
                      title: '提示',
                      message: '要取消收藏吗?',
                      confirmLabel: '确定取消',
                    ).then((res) {
                      if (res == true) {
                        ctr!.onCancelFav(index!, item.id!, item.type!);
                      }
                    });
                    return;
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
