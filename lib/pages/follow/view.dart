import 'package:bplus_tv/common/widgets/dialog/dialog.dart';
import 'package:bplus_tv/common/widgets/dialog/simple_dialog_option.dart';
import 'package:bplus_tv/common/widgets/loading_widget/loading_widget.dart';
import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/common/widgets/scroll_physics.dart' show tabBarView;
import 'package:bplus_tv/common/widgets/view_safe_area.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models/member/tags.dart';
import 'package:bplus_tv/pages/common/fab_mixin.dart';
import 'package:bplus_tv/pages/follow/child/child_controller.dart';
import 'package:bplus_tv/pages/follow/child/child_view.dart';
import 'package:bplus_tv/pages/follow/controller.dart';
import 'package:bplus_tv/pages/follow_tag_sort/view.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/bili_utils.dart';
import 'package:bplus_tv/utils/feed_back.dart';
import 'package:bplus_tv/utils/parse_int.dart';
import 'package:bplus_tv/utils/request_utils.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:flutter/services.dart' show LengthLimitingTextInputFormatter;
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class FollowPage extends StatefulWidget {
  const FollowPage({super.key});

  @override
  State<FollowPage> createState() => _FollowPageState();

  static void toFollowPage({dynamic mid, String? name}) {
    if (mid == null) return;
    Get.toNamed(
      '/follow',
      arguments: {
        'mid': safeToInt(mid),
        'name': name,
      },
    );
  }
}

class _FollowPageState extends State<FollowPage>
    with SingleTickerProviderStateMixin, BaseFabMixin, LazyFabMixin {
  final _tag = Utils.generateRandomString(8);
  late final FollowController _followController;

  @override
  void initState() {
    super.initState();
    _followController = Get.put(FollowController(_tag), tag: _tag);
  }

  @override
  bool onNotification(UserScrollNotification notification) {
    if (notification.metrics.axisDirection == .down) {
      return super.onNotification(notification);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewPaddingOf(context);
    return SimpleScaffold(
      appBar: _buildAppBar,
      body: _followController.isOwner
          ? fabAnimWrapper(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Obx(
                    () => _buildBody(_followController.followState.value),
                  ),
                ),
              ),
            )
          : _childPage(),
      fab: _followController.isOwner
          ? SlideTransition(
              position: fabAnimation,
              child: Padding(
                padding: .only(
                  right: kFloatingActionButtonMargin + padding.right,
                  bottom: kFloatingActionButtonMargin + padding.bottom,
                ),
                child: FloatingActionButton.extended(
                  onPressed: _followController.toggleOrderType,
                  icon: const Icon(Icons.format_list_bulleted, size: 20),
                  label: Obx(
                    () => Text(_followController.orderType.value.title),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  PreferredSizeWidget get _buildAppBar => AppBar(
    title: _followController.isOwner
        ? const Text('我的关注')
        : Obx(() {
            final name = _followController.name.value;
            if (name != null) return Text('$name的关注');
            return const SizedBox.shrink();
          }),
    actions: _followController.isOwner
        ? [
            _headerIcon(
              icon: Icons.add,
              tooltip: '新建分组',
              onTap: () => RequestUtils.createFavTag(
                context,
                _followController.onCreateFavTag,
              ),
            ),
            _headerIcon(
              icon: Icons.sort,
              tooltip: '分组排序',
              onTap: () {
                if (_followController.followState.value is! Success) {
                  return;
                }
                Get.to(FollowTagSortPage(controller: _followController));
              },
            ),
            _headerIcon(
              icon: Icons.search_outlined,
              tooltip: '搜索',
              onTap: () => Get.toNamed(
                '/followSearch',
                arguments: {
                  'mid': _followController.mid,
                },
              ),
            ),
            TvFocusable(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => tvDialogShell(
                    title: '更多',
                    content: const SizedBox.shrink(),
                    actions: [
                      TvDialogAction(
                        label: '黑名单管理',
                        onTap: () {
                          Get.back();
                          Get.toNamed('/blackListPage');
                        },
                      ),
                    ],
                  ),
                );
              },
              builder: (context, focused, hovered) => TvFocusHighlight(
                focused: focused,
                radius: 16,
                borderWidth: 2,
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: focused
                        ? Theme.of(context).colorScheme.secondaryContainer
                              .withValues(alpha: 0.15)
                        : Colors.transparent,
                  ),
                  child: const Icon(Icons.more_vert),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ]
        : null,
  );

  Widget _childPage([MemberTagItemModel? item]) => FollowChildPage(
    tag: _tag,
    controller: _followController,
    mid: _followController.mid,
    tagid: item?.tagid,
  );

  Widget _headerIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) => Tooltip(
    message: tooltip,
    child: TvFocusable(
      onTap: onTap,
      builder: (context, focused, hovered) => TvFocusHighlight(
        focused: focused,
        radius: 14,
        borderWidth: 2,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon),
        ),
      ),
    ),
  );

  Widget _buildBody(LoadingState loadingState) {
    return switch (loadingState) {
      Loading() => m3eLoading,
      Success() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                child: netflixSurface(
                  radius: 18,
                  child: ViewSafeArea(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: AnimatedBuilder(
                        animation: _followController.tabController!,
                        builder: (context, _) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (
                              int index = 0;
                              index < _followController.tabs.length;
                              index++
                            )
                              _buildFollowTab(index),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: tabBarView(
              controller: _followController.tabController,
              children: _followController.tabs.map(_childPage).toList(),
            ),
          ),
        ],
      ),
      Error() => _childPage(),
    };
  }

  void _onHandleTag(int index, MemberTagItemModel item) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        clipBehavior: Clip.hardEdge,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          DialogOption(
            onPressed: () {
              Get.back();
              String tagName = item.name!;
              showConfirmDialog(
                context: context,
                title: const Text('编辑分组名称'),
                content: TextFormField(
                  autofocus: true,
                  initialValue: tagName,
                  onChanged: (value) => tagName = value,
                  inputFormatters: [LengthLimitingTextInputFormatter(16)],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                onConfirm: () {
                  if (tagName.isNotEmpty) {
                    _followController.onUpdateTag(item, tagName);
                  }
                },
              );
            },
            child: const Text('修改名称', style: TextStyle(fontSize: 14)),
          ),
          DialogOption(
            onPressed: () {
              Get.back();
              showConfirmDialog(
                context: context,
                title: const Text('删除分组'),
                content: const Text('删除后，该分组下的用户依旧保留？'),
                onConfirm: () => _followController.onDelTag(index, item.tagid!),
              );
            },
            child: const Text('删除分组', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowTab(int index) {
    final item = _followController.tabs[index];
    final selected = _followController.tabController!.index == index;
    final theme = Theme.of(context);
    final bool isCustom = BiliUtils.isCustomFollowTag(item.tagid);
    return SizedBox(
      width: 148,
      child: TvFocusable(
        onTap: () {
          feedBack();
          if (!_followController.tabController!.indexIsChanging) {
            try {
              Get.find<FollowChildController>(
                tag: '$_tag${item.tagid}',
              ).animateToTop();
            } catch (_) {}
            _followController.tabController!.animateTo(index);
          }
        },
        onLongPress: isCustom
            ? () {
                Feedback.forLongPress(context);
                _onHandleTag(index, item);
              }
            : null,
        builder: (context, focused, hovered) => TvFocusHighlight(
          focused: focused,
          radius: 16,
          borderWidth: 2,
          // 无选中底：选中只用文字颜色/字重区分，焦点用光晕反馈
          child: Obx(() {
            int? currentCount = _followController.tabs[index].count;
            final label =
                '${item.name}${currentCount != null ? '($currentCount)' : ''}';
            final textStyle = TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            );
            return Container(
              alignment: Alignment.center,
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: isCustom
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textStyle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.menu,
                          size: 18,
                          color: textStyle.color,
                        ),
                      ],
                    )
                  : Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle,
                    ),
            );
          }),
        ),
      ),
    );
  }
}
