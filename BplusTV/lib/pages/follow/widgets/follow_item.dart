import 'package:bplus_tv/common/widgets/pendant_avatar.dart';
import 'package:bplus_tv/models_new/follow/list.dart';
import 'package:bplus_tv/pages/share/view.dart' show UserModel;
import 'package:bplus_tv/tv/tv_focus_card.dart';
import 'package:bplus_tv/utils/feed_back.dart';
import 'package:bplus_tv/utils/request_utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class FollowItem extends StatelessWidget {
  final FollowItemModel item;
  final bool isOwner;
  final ValueChanged? afterMod;
  final ValueChanged<UserModel>? onSelect;

  const FollowItem({
    super.key,
    required this.item,
    this.afterMod,
    bool? isOwner,
    this.onSelect,
  }) : isOwner = isOwner ?? false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    Widget? followBtn;
    if (isOwner) {
      final isFollow = item.attribute != -1;
      followBtn = TvFocusRing(
        radius: 12,
        child: FilledButton.tonal(
          onPressed: () => RequestUtils.actionRelationMod(
            context: context,
            mid: item.mid,
            isFollow: isFollow,
            afterMod: afterMod,
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size(92, 48),
            padding: const .symmetric(horizontal: 16),
            foregroundColor: isFollow ? colorScheme.outline : null,
            backgroundColor: isFollow ? colorScheme.onInverseSurface : null,
          ),
          child: Text(
            '${isFollow ? '已' : ''}关注',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.hasBoundedHeight && constraints.maxHeight < 84;
        return TvFocusRing(
          radius: 14,
          child: Material(
            type: .transparency,
            child: InkWell(
              onTap: () {
                if (onSelect != null) {
                  onSelect!.call(
                    UserModel(
                      mid: item.mid,
                      name: item.uname!,
                      avatar: item.face!,
                      selected: true,
                    ),
                  );
                } else {
                  feedBack();
                  Get.toNamed('/member?mid=${item.mid}');
                }
              },
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: compact ? 6 : 12,
                ),
                child: Row(
                  children: [
                    PendantAvatar(
                      size: 52,
                      badgeSize: 16,
                      item.face,
                      officialType: item.officialVerify?.type,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 4,
                        crossAxisAlignment: .start,
                        children: [
                          Text(
                            item.uname!,
                            maxLines: 1,
                            overflow: .ellipsis,
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (item.sign != null)
                            Text(
                              item.sign!,
                              maxLines: 1,
                              overflow: .ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.outline,
                              ),
                            ),
                        ],
                      ),
                    ),
                    ?followBtn,
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
