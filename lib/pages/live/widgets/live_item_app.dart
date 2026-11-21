import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/image/image_save.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/http/live.dart';
import 'package:bplus_tv/models_new/live/live_feed_index/card_data_list_item.dart';
import 'package:bplus_tv/models_new/live/live_feed_index/feedback.dart';
import 'package:bplus_tv/pages/search/widgets/search_text.dart';
import 'package:bplus_tv/tv/tv_card.dart';
import 'package:bplus_tv/utils/extension/iterable_ext.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

// 视频卡片 - 垂直布局
class LiveCardVApp extends StatelessWidget {
  final CardLiveItem item;
  final bool showFirstFrame;

  const LiveCardVApp({
    super.key,
    required this.item,
    this.showFirstFrame = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void onLongPress() => imageSaveDialog(
      title: item.title,
      cover: showFirstFrame ? item.systemCover : item.cover,
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TvCard(
          onTap: () => PageUtils.toLiveRoom(item.roomid),
          onLongPress: onLongPress,
          radius: 12,
          child: NetflixSegment(
            radius: 12,
            child: Column(
              crossAxisAlignment: .start,
              children: [
                AspectRatio(
                  aspectRatio: Style.aspectRatio16x9,
                  child: LayoutBuilder(
                    builder: (context, boxConstraints) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        NetworkImgLayer(
                          src: showFirstFrame ? item.systemCover : item.cover,
                          width: boxConstraints.maxWidth,
                          height: boxConstraints.maxHeight,
                          borderRadius: const .vertical(top: .circular(12)),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: videoStat(),
                        ),
                      ],
                    ),
                  ),
                ),
                liveContent(theme),
              ],
            ),
          ),
        ),
        if (!item.feedback.isNullOrEmpty)
          Positioned(
            right: 0,
            bottom: 0,
            width: 48,
            height: 48,
            child: IconButton(
              padding: .zero,
              onPressed: () {
                Widget actionButton(Reason r) => SearchText(
                  text: r.name!,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  onTap: (_) async {
                    Get.back();
                    SmartDialog.showLoading(msg: '正在提交');
                    final res = await LiveHttp.liveFeedback(
                      item.roomid!,
                      r.id!,
                      r.idType!,
                    );
                    SmartDialog.dismiss();
                    if (res.isSuccess) {
                      SmartDialog.showToast('提交成功');
                    } else {
                      res.toast();
                    }
                  },
                );

                final feedback = item.feedback!;
                showDialog(
                  context: context,
                  builder: (context) {
                    return SimpleDialog(
                      contentPadding: const .fromLTRB(24, 16, 24, 19),
                      children: [
                        for (var i in feedback) ...[
                          const SizedBox(height: 5),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: i.title,
                                  style: theme.textTheme.titleMedium,
                                ),
                                TextSpan(
                                  text: '\n${i.subtitle}',
                                  style: TextStyle(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: i.reasons!.map(actionButton).toList(),
                          ),
                        ],
                        const Divider(),
                        Center(
                          child: FilledButton.tonal(
                            onPressed: Get.back,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(80, 48),
                            ),
                            child: const Text('取消'),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: Icon(
                Icons.more_vert_outlined,
                size: 17,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
      ],
    );
  }

  Widget liveContent(ThemeData theme) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 40, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item.title.toString(),
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontSize: 15,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              item.uname.toString(),
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: theme.textTheme.labelMedium!.fontSize,
                color: theme.colorScheme.outline,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget videoStat() {
    return Container(
      height: 50,
      padding: const EdgeInsets.only(top: 26, left: 10, right: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Colors.transparent, Colors.black54],
          tileMode: TileMode.mirror,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              item.areaName.toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
          ),
          if (item.watchedShow?.textLarge case final textLarge?) ...[
            const SizedBox(width: 8),
            Text(
              textLarge,
              maxLines: 1,
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
