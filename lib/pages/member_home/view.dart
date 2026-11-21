import 'dart:math';

import 'package:bplus_tv/common/style.dart';
import 'package:bplus_tv/common/widgets/button/more_btn.dart';
import 'package:bplus_tv/common/widgets/loading_widget/loading_widget.dart';
import 'package:bplus_tv/common/widgets/scroll_physics.dart'
    show platformAlwaysClampingPhysics;
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models_new/space/space/data.dart';
import 'package:bplus_tv/models_new/space/space/tab2.dart';
import 'package:bplus_tv/pages/member/controller.dart';
import 'package:bplus_tv/pages/member_article/widget/item.dart';
import 'package:bplus_tv/pages/member_audio/widgets/item.dart';
import 'package:bplus_tv/pages/member_coin_arc/view.dart';
import 'package:bplus_tv/pages/member_comic/widgets/item.dart';
import 'package:bplus_tv/pages/member_contribute/controller.dart';
import 'package:bplus_tv/pages/member_home/widgets/fav_item.dart';
import 'package:bplus_tv/pages/member_home/widgets/video_card_v_member_home.dart';
import 'package:bplus_tv/pages/member_like_arc/view.dart';
import 'package:bplus_tv/pages/member_pgc/widgets/pgc_card_v_member_pgc.dart';
import 'package:bplus_tv/utils/extension/context_ext.dart';
import 'package:bplus_tv/utils/grid.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class MemberHome extends StatefulWidget {
  const MemberHome({super.key, this.heroTag});

  final String? heroTag;

  @override
  State<MemberHome> createState() => _MemberHomeState();
}

class _MemberHomeState extends State<MemberHome>
    with AutomaticKeepAliveClientMixin, GridMixin {
  @override
  bool get wantKeepAlive => true;

  late final _ctr = Get.find<MemberController>(tag: widget.heroTag);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildBody(_ctr.loadingState.value);
  }

  late final gridDelegateV = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: 18,
    crossAxisSpacing: 18,
    maxCrossAxisExtent: 340,
    childAspectRatio: Style.aspectRatio,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(68),
  );

  late final gridDelegateAudio = Grid.videoCardHDelegate();

  late final gridDelegatePgc = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: Style.cardSpace,
    crossAxisSpacing: Style.cardSpace,
    maxCrossAxisExtent: 220,
    childAspectRatio: 0.75,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(52),
  );

  Widget _buildBody(LoadingState<SpaceData?> loadingState) {
    final isVertical = context.width < 600;
    final setting = _ctr.spaceSetting;
    final isOwner = setting != null;
    final color = Theme.of(context).colorScheme.outline;
    return switch (loadingState) {
      Loading() => m3eLoading,
      Success(response: final res) =>
        res != null
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1480),
                  child: CustomScrollView(
                    physics: platformAlwaysClampingPhysics,
                    slivers: [
                      if (res.archive?.item?.isNotEmpty == true) ...[
                        _header(
                          color,
                          title: '视频',
                          param: 'contribute',
                          param1: 'video',
                          count: res.archive!.count ?? 0,
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Style.safeSpace,
                          ),
                          sliver: SliverGrid.builder(
                            gridDelegate: gridDelegateV,
                            itemBuilder: (context, index) {
                              return VideoCardVMemberHome(
                                videoItem: res.archive!.item![index],
                              );
                            },
                            itemCount: min(
                              isVertical ? 4 : 8,
                              res.archive!.item!.length,
                            ),
                          ),
                        ),
                      ],
                      if (res.favourite2?.item?.isNotEmpty == true) ...[
                        _header(
                          color,
                          title: '收藏',
                          param: 'favorite',
                          count: res.favourite2!.count ?? 0,
                          visible: isOwner ? setting.favVideo == 1 : null,
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 144,
                            child: MemberFavItem(
                              item: res.favourite2!.item!.first,
                            ),
                          ),
                        ),
                      ],
                      if (res.coinArchive?.item?.isNotEmpty == true) ...[
                        _header(
                          color,
                          title: '最近投币的视频',
                          param: 'coinArchive',
                          count: res.coinArchive!.count ?? 0,
                          visible: isOwner ? setting.coinsVideo == 1 : null,
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Style.safeSpace,
                          ),
                          sliver: SliverGrid.builder(
                            gridDelegate: gridDelegateV,
                            itemBuilder: (context, index) {
                              return VideoCardVMemberHome(
                                videoItem: res.coinArchive!.item![index],
                              );
                            },
                            itemCount: min(
                              isVertical ? 2 : 4,
                              res.coinArchive!.item!.length,
                            ),
                          ),
                        ),
                      ],
                      if (res.likeArchive?.item?.isNotEmpty == true) ...[
                        _header(
                          color,
                          title: '最近点赞的视频',
                          param: 'likeArchive',
                          count: res.likeArchive!.count ?? 0,
                          visible: isOwner ? setting.likesVideo == 1 : null,
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Style.safeSpace,
                          ),
                          sliver: SliverGrid.builder(
                            gridDelegate: gridDelegateV,
                            itemBuilder: (context, index) {
                              return VideoCardVMemberHome(
                                videoItem: res.likeArchive!.item![index],
                              );
                            },
                            itemCount: min(
                              isVertical ? 2 : 4,
                              res.likeArchive!.item!.length,
                            ),
                          ),
                        ),
                      ],
                      if (res.article?.item?.isNotEmpty == true) ...[
                        _header(
                          color,
                          title: '图文',
                          param: 'contribute',
                          param1: 'opus',
                          count: res.article!.count ?? 0,
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 144,
                            child: MemberArticleItem(
                              item: res.article!.item!.first,
                            ),
                          ),
                        ),
                      ],
                      if (res.audios?.item?.isNotEmpty == true) ...[
                        _header(
                          color,
                          title: '音频',
                          param: 'contribute',
                          param1: 'audio',
                          count: res.audios!.count ?? 0,
                        ),
                        SliverGrid.builder(
                          gridDelegate: gridDelegateAudio,
                          itemBuilder: (context, index) {
                            return MemberAudioItem(
                              item: res.audios!.item![index],
                            );
                          },
                          itemCount: isVertical
                              ? 1
                              : min(3, res.audios!.count ?? 0),
                        ),
                      ],
                      if (res.comic?.item?.isNotEmpty == true) ...[
                        _header(
                          color,
                          title: '漫画',
                          param: 'contribute',
                          param1: 'comic',
                          count: res.comic!.count ?? 0,
                        ),
                        SliverGrid.builder(
                          gridDelegate: gridDelegate,
                          itemBuilder: (context, index) {
                            return MemberComicItem(
                              item: res.comic!.item![index],
                            );
                          },
                          itemCount: isVertical
                              ? 1
                              : min(3, res.comic!.count ?? 0),
                        ),
                      ],
                      if (res.season?.item?.isNotEmpty == true) ...[
                        _header(
                          color,
                          title: '追番',
                          param: 'bangumi',
                          count: res.season!.count ?? 0,
                          visible: isOwner ? setting.bangumi == 1 : null,
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Style.safeSpace,
                          ),
                          sliver: SliverGrid.builder(
                            gridDelegate: gridDelegatePgc,
                            itemBuilder: (context, index) {
                              return PgcCardVMemberPgc(
                                item: res.season!.item![index],
                              );
                            },
                            itemCount: min(
                              isVertical ? 3 : 6,
                              res.season!.item!.length,
                            ),
                          ),
                        ),
                      ],
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height:
                              100 + MediaQuery.viewPaddingOf(context).bottom,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : scrollableError,
      Error(:final errMsg) => scrollErrorWidget(errMsg: errMsg),
    };
  }

  Widget _header(
    Color color, {
    required String title,
    required String param,
    String? param1,
    required int count,
    bool? visible,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$title '),
                  TextSpan(
                    text: count.toString(),
                    style: TextStyle(fontSize: 13, color: color),
                  ),
                  if (visible != null)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Icon(
                          visible ? Icons.visibility : Icons.visibility_off,
                          size: 17,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            moreTextButton(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              onTap: () {
                int index = _ctr.tab2!.indexWhere(
                  (item) => item.param == param,
                );
                if (index != -1) {
                  if (const [
                    'video',
                    'opus',
                    'audio',
                    'comic',
                  ].contains(param1)) {
                    List<SpaceTab2Item> items = _ctr.tab2!
                        .firstWhere((item) => item.param == param)
                        .items!;
                    int index1 = items.indexWhere(
                      (item) => item.param == param1,
                    );
                    if (index1 != -1) {
                      try {
                        final contributeCtr = Get.find<MemberContributeCtr>(
                          tag: widget.heroTag,
                        );
                        // contributeCtr.tabController?.animateTo(index1);
                        if (contributeCtr.tabController?.index != index1) {
                          contributeCtr.tabController?.index = index1;
                        }
                        // if (kDebugMode) debugPrint('initialized');
                      } catch (e) {
                        _ctr.contributeInitialIndex.value = index1;
                        // if (kDebugMode) debugPrint('not initialized');
                      }
                    }
                  }
                  _ctr.tabController?.animateTo(index);
                } else {
                  if (param == 'coinArchive') {
                    Get.to(
                      MemberCoinArcPage(
                        mid: _ctr.mid,
                        name: _ctr.username,
                      ),
                    );
                    return;
                  }

                  if (param == 'likeArchive') {
                    Get.to(
                      MemberLikeArcPage(
                        mid: _ctr.mid,
                        name: _ctr.username,
                      ),
                    );
                    return;
                  }

                  // else TODO
                  SmartDialog.showToast('view $param');
                }
              },
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
