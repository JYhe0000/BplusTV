import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/pendant_avatar.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/tv/tv_card.dart';
import 'package:bplus_tv/models/search/result.dart';
import 'package:bplus_tv/utils/bili_utils.dart';
import 'package:bplus_tv/utils/num_utils.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:material_ui/material_ui.dart';

class SearchUserItem extends StatelessWidget {
  const SearchUserItem({
    super.key,
    required this.item,
  });

  final SearchUserItemModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = TextStyle(
      fontSize: 15,
      color: theme.colorScheme.outline,
    );
    return NetflixSegment(
      radius: 16,
      child: TvCard(
        radius: 16,
        scale: 1,
        onTap: () => Get.toNamed('/member?mid=${item.mid}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Style.safeSpace,
            vertical: 10,
          ),
          child: Row(
            children: [
              PendantAvatar(
                item.upic,
                size: 42,
                officialType: item.officialVerify?.type,
                liveBottom: -5,
                liveFontSize: 11,
                roomId: item.isLive == 1 ? item.roomId : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.uname!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        BiliUtils.levelPicture(
                          item.level!,
                          isSeniorMember: item.isSeniorMember == 1,
                          height: 11,
                        ),
                      ],
                    ),
                    Text(
                      '粉丝：${NumUtils.numFormat(item.fans)}  视频：${NumUtils.numFormat(item.videos)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style,
                    ),
                    if (item.officialVerify?.desc?.isNotEmpty == true)
                      Text(
                        item.officialVerify!.desc!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
