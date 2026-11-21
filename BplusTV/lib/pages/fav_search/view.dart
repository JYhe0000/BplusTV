import 'package:bplus_tv/models/common/fav_order_type.dart';
import 'package:bplus_tv/models_new/fav/fav_detail/data.dart';
import 'package:bplus_tv/models_new/fav/fav_detail/media.dart';
import 'package:bplus_tv/pages/common/search/common_search_page.dart';
import 'package:bplus_tv/pages/fav_detail/widget/fav_video_card.dart';
import 'package:bplus_tv/pages/fav_search/controller.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_option_picker.dart';
import 'package:bplus_tv/utils/accounts.dart';
import 'package:bplus_tv/utils/grid.dart';
import 'package:bplus_tv/utils/request_utils.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;

class FavSearchPage extends StatefulWidget {
  const FavSearchPage({super.key});

  @override
  State<FavSearchPage> createState() => _FavSearchPageState();
}

class _FavSearchPageState
    extends
        CommonSearchPageState<FavSearchPage, FavDetailData, FavDetailItemModel>
    with GridMixin {
  @override
  final FavSearchController controller = Get.put(
    FavSearchController(),
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
        onPressed: () => RequestUtils.onCopyOrMove<FavDetailItemModel>(
          context: context,
          isCopy: true,
          ctr: controller,
          mediaId: controller.mediaId,
          mid: Accounts.main.mid,
        ),
        child: Text('复制', style: textStyle),
      ),
      TextButton(
        style: btnStyle,
        onPressed: () => RequestUtils.onCopyOrMove<FavDetailItemModel>(
          context: context,
          isCopy: false,
          ctr: controller,
          mediaId: controller.mediaId,
          mid: Accounts.main.mid,
        ),
        child: Text('移动', style: textStyle),
      ),
    ];
  }

  @override
  List<Widget>? get extraActions => [
    TvFocusable(
      onTap: _showTvSort,
      builder: (context, focused, hovered) => TvFocusHighlight(
        focused: focused,
        radius: 16,
        borderWidth: 2,
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.sort),
        ),
      ),
    ),
  ];

  Future<void> _showTvSort() async {
    final order = await showTvOptionPicker<FavOrderType>(
      context: context,
      title: '排序方式',
      current: controller.order.value,
      options: FavOrderType.values
          .map((e) => TvOption(value: e, label: e.label))
          .toList(),
    );
    if (order == null || order == controller.order.value) return;
    controller
      ..order.value = order
      ..onReload();
  }

  @override
  Widget buildList(List<FavDetailItemModel> list) {
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
              return FavVideoCardH(
                item: item,
                index: index,
                ctr: controller,
              );
            },
            itemCount: list.length,
          ),
        );
      },
    );
  }
}
