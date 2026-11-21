import 'package:bplus_tv/common/widgets/dialog/dialog.dart';
import 'package:bplus_tv/common/widgets/flutter/refresh_indicator.dart';
import 'package:bplus_tv/common/widgets/image/network_img_layer.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/common/widgets/loading_widget/loading_widget.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models_new/follow/list.dart';
import 'package:bplus_tv/pages/fan/controller.dart';
import 'package:bplus_tv/pages/follow_type/view.dart';
import 'package:bplus_tv/pages/share/view.dart' show UserModel;
import 'package:bplus_tv/tv/tv_focus_card.dart';
import 'package:bplus_tv/utils/parse_int.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class FansPage extends StatefulWidget {
  const FansPage({
    super.key,
    this.showName = true,
    this.onSelect,
  });

  final bool showName;
  final ValueChanged<UserModel>? onSelect;

  @override
  State<FansPage> createState() => _FansPageState();

  static void toFansPage({dynamic mid, String? name}) {
    if (mid == null) {
      return;
    }
    Get.toNamed(
      '/fan',
      arguments: {
        'mid': safeToInt(mid),
        'name': name,
      },
    );
  }
}

class _FansPageState extends FollowTypePageState<FansPage> {
  @override
  late final FansController controller;
  late final flag = widget.onSelect == null && controller.isOwner;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      FansController(widget.showName),
      tag: Get.arguments?['mid']?.toString() ?? Utils.generateRandomString(8),
    );
  }

  @override
  PreferredSizeWidget? get appBar => widget.showName
      ? AppBar(
          title: controller.isOwner
              ? const Text('我的粉丝')
              : Obx(() {
                  final name = controller.name.value;
                  if (name != null) return Text('$name的粉丝');
                  return const SizedBox.shrink();
                }),
        )
      : null;

  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      appBar: appBar,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: refreshIndicator(
            onRefresh: controller.onRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  sliver: Obx(() {
                    return switch (controller.loadingState.value) {
                      Loading() => SliverFillRemaining(child: m3eLoading),
                      Success(:final response) =>
                        response != null && response.isNotEmpty
                            ? SliverLayoutBuilder(
                                builder: (context, constraints) =>
                                    SliverGrid.builder(
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount:
                                                constraints.crossAxisExtent >=
                                                    1000
                                                ? 2
                                                : 1,
                                            mainAxisExtent: 100,
                                            mainAxisSpacing: 12,
                                            crossAxisSpacing: 16,
                                          ),
                                      itemCount: response.length,
                                      itemBuilder: (context, index) {
                                        if (index == response.length - 1) {
                                          controller.onLoadMore();
                                        }
                                        return buildItem(
                                          index,
                                          response[index],
                                        );
                                      },
                                    ),
                              )
                            : HttpError(onReload: controller.onReload),
                      Error(:final errMsg) => HttpError(
                        errMsg: errMsg,
                        onReload: controller.onReload,
                      ),
                    };
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildItem(int index, FollowItemModel item) {
    void onRemove() => showConfirmDialog(
      context: context,
      title: Text('确定移除 ${item.uname} ？'),
      onConfirm: () => controller.onRemoveFan(index, item.mid),
    );

    return TvFocusRing(
      radius: 14,
      child: netflixSurface(
        radius: 14,
        child: InkWell(
          onTap: () {
            if (widget.onSelect != null) {
              widget.onSelect!(
                UserModel(
                  mid: item.mid,
                  name: item.uname!,
                  avatar: item.face!,
                  selected: true,
                ),
              );
              return;
            }
            Get.toNamed('/member?mid=${item.mid}');
          },
          onLongPress: flag ? onRemove : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                NetworkImgLayer(
                  src: item.face,
                  type: .avatar,
                  width: 56,
                  height: 56,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.uname ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (item.sign?.isNotEmpty == true) ...[
                        const SizedBox(height: 5),
                        Text(
                          item.sign!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (flag) ...[
                  const SizedBox(width: 8),
                  TvFocusButton(
                    onTap: onRemove,
                    child: IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      tooltip: '移除粉丝',
                      onPressed: onRemove,
                      icon: const Icon(Icons.person_remove_outlined),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
