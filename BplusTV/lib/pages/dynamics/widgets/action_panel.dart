import 'package:bplus_tv/models/dynamics/result.dart';
import 'package:bplus_tv/pages/dynamics_repost/view.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/utils/num_utils.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:bplus_tv/utils/request_utils.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class ActionPanel extends StatelessWidget {
  const ActionPanel({
    super.key,
    required this.item,
  });
  final DynamicItemModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final outline = theme.colorScheme.outline;
    final moduleStat = item.modules.moduleStat!;
    final forward = moduleStat.forward!;
    final comment = moduleStat.comment!;
    final like = moduleStat.like!;
    final btnStyle = TextButton.styleFrom(
      tapTargetSize: .padded,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      textStyle: const TextStyle(fontSize: 16),
      foregroundColor: outline,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: Builder(
            builder: (context) {
              return TextButton.icon(
                onPressed: () {
                  {
                    showDialog(
                      context: context,
                      builder: (_) => tvDialogShell(
                        title: '转发',
                        minWidth: 480,
                        maxWidth: 920,
                        maxHeight: 760,
                        content: RepostPanel(
                          item: item,
                          onSuccess: () {
                            int count = forward.count ?? 0;
                            forward.count = count + 1;
                            if (context.mounted) {
                              (context as Element?)?.markNeedsBuild();
                            }
                          },
                        ),
                        actions: [
                          TvDialogAction(
                            label: '关闭',
                            onTap: Get.back,
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                },
                icon: Icon(
                  FontAwesomeIcons.shareFromSquare,
                  size: 20,
                  color: outline,
                  semanticLabel: "转发",
                ),
                style: btnStyle,
                label: Text(
                  forward.count != null
                      ? NumUtils.numFormat(forward.count)
                      : '转发',
                ),
              );
            },
          ),
        ),
        Expanded(
          child: TextButton.icon(
            onPressed: () => PageUtils.pushDynDetail(
              item,
              isPush: true,
              viewComment: true,
            ),
            icon: Icon(
              FontAwesomeIcons.comment,
              size: 20,
              color: outline,
              semanticLabel: "评论",
            ),
            style: btnStyle,
            label: Text(
              comment.count != null ? NumUtils.numFormat(comment.count) : '评论',
            ),
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              final IconData icon;
              final Color color;
              final String label;
              if (like.status ?? false) {
                icon = FontAwesomeIcons.solidThumbsUp;
                color = primary;
                label = '已赞';
              } else {
                icon = FontAwesomeIcons.thumbsUp;
                color = outline;
                label = '点赞';
              }
              final likeIcon = Icon(
                icon,
                size: 20,
                color: color,
                semanticLabel: label,
              );
              return TextButton.icon(
                onPressed: () => RequestUtils.onLikeDynamic(
                  item,
                  likeIcon.color == primary,
                  () {
                    if (context.mounted) {
                      (context as Element?)?.markNeedsBuild();
                    }
                  },
                ),
                icon: likeIcon,
                style: btnStyle,
                label: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Text(
                    like.count != null ? NumUtils.numFormat(like.count) : '点赞',
                    key: ValueKey<int?>(like.count),
                    style: TextStyle(color: like.status! ? primary : outline),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
