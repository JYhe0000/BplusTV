import 'package:bplus_tv/models/common/video/source_type.dart';
import 'package:bplus_tv/models_new/later/data.dart';
import 'package:bplus_tv/models_new/later/list.dart';
import 'package:bplus_tv/pages/common/search/common_search_page.dart';
import 'package:bplus_tv/pages/later/widgets/video_card_h_later.dart';
import 'package:bplus_tv/pages/later_search/controller.dart';
import 'package:bplus_tv/utils/grid.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:bplus_tv/utils/request_utils.dart';
import 'package:bplus_tv/utils/storage_pref.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;

class LaterSearchPage extends StatefulWidget {
  const LaterSearchPage({super.key});

  @override
  State<LaterSearchPage> createState() => _LaterSearchPageState();
}

class _LaterSearchPageState
    extends CommonSearchPageState<LaterSearchPage, LaterData, LaterItemModel>
    with GridMixin {
  late final enablePlayAll = Pref.enablePlayAll;

  @override
  final LaterSearchController controller = Get.put(
    LaterSearchController(),
    tag: Utils.generateRandomString(8),
  );

  @override
  List<Widget>? get multiSelectActions {
    final btnStyle = TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      visualDensity: VisualDensity.standard,
    );
    final textStyle = TextStyle(
      color: ColorScheme.of(context).onSurfaceVariant,
    );
    return [
      TextButton(
        style: btnStyle,
        onPressed: () => RequestUtils.onCopyOrMove<LaterItemModel>(
          context: context,
          isCopy: true,
          ctr: controller,
          mediaId: null,
          mid: controller.mid,
        ),
        child: Text('复制', style: textStyle),
      ),
      TextButton(
        style: btnStyle,
        onPressed: () => RequestUtils.onCopyOrMove<LaterItemModel>(
          context: context,
          isCopy: false,
          ctr: controller,
          mediaId: null,
          mid: controller.mid,
        ),
        child: Text('移动', style: textStyle),
      ),
    ];
  }

  @override
  Widget buildList(List<LaterItemModel> list) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final inset = ((constraints.crossAxisExtent - 1600) / 2)
            .clamp(0.0, double.infinity)
            .toDouble();
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(inset + 8, 8, inset + 8, 48),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 840,
              mainAxisExtent: 140,
              mainAxisSpacing: 10,
              crossAxisSpacing: 14,
            ),
            itemBuilder: (context, index) {
              if (index == list.length - 1) {
                controller.onLoadMore();
              }
              final item = list[index];
              return VideoCardHLater(
                index: index,
                videoItem: item,
                ctr: controller,
                onViewLater: (cid) {
                  PageUtils.toVideoPage(
                    bvid: item.bvid,
                    cid: cid,
                    cover: item.pic,
                    title: item.title,
                    dimension: item.dimension,
                    extraArguments: enablePlayAll
                        ? {
                            'oid': item.aid,
                            'sourceType': SourceType.watchLater,
                            'count': controller.count,
                            'favTitle': '稍后再看',
                            'mediaId': controller.mid,
                            'desc': false,
                            'isContinuePlaying': index != 0,
                          }
                        : const {'viewLater': true},
                  );
                },
              );
            },
            itemCount: list.length,
          ),
        );
      },
    );
  }
}
