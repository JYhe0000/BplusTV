import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/controller.dart';
import 'package:PiliPlus/tv/tv_focus.dart';
import 'package:PiliPlus/utils/num_utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// TV-native video info header: title, uploader, stats and actions, with large
/// 10-foot typography. Does not reuse the mobile intro layout.
class TvVideoInfo extends StatelessWidget {
  const TvVideoInfo({super.key, required this.controller});

  final UgcIntroController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Obx(() {
      final detail = controller.videoDetail.value;
      final owner = detail.owner;
      final stat = detail.stat;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.title ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (owner?.face case final face?)
                NetworkImgLayer(src: face, width: 60, height: 60),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    owner?.name ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${NumUtils.numFormat(stat?.view ?? 0)} 播放'
                    ' · ${NumUtils.numFormat(stat?.danmaku ?? 0)} 弹幕',
                    style: TextStyle(
                      fontSize: 15,
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Obx(
                () => Row(
                  children: [
                    _TvInfoAction(
                      icon: controller.hasLike.value
                          ? Icons.thumb_up_rounded
                          : Icons.thumb_up_outlined,
                      label: '点赞',
                      active: controller.hasLike.value,
                      onTap: controller.actionLikeVideo,
                    ),
                    _TvInfoAction(
                      icon: Icons.monetization_on_outlined,
                      label: '投币',
                      onTap: controller.actionCoinVideo,
                    ),
                    _TvInfoAction(
                      icon: controller.hasFav.value
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      label: '收藏',
                      active: controller.hasFav.value,
                      onTap: controller.actionFavVideo,
                    ),
                    _TvInfoAction(
                      icon: Icons.share_outlined,
                      label: '分享',
                      onTap: () => controller.actionShareVideo(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _TvInfoAction extends StatelessWidget {
  const _TvInfoAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TvFocusable(
        onTap: onTap,
        builder: (context, focused, hovered) => TvFocusHighlight(
          radius: 14,
          focused: focused,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: focused
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: active ? colorScheme.primary : colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: active
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
