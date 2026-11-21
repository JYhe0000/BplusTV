import 'package:bplus_tv/models_new/history/data.dart';
import 'package:bplus_tv/models_new/history/list.dart';
import 'package:bplus_tv/pages/common/search/common_search_page.dart';
import 'package:bplus_tv/pages/history/widgets/item.dart';
import 'package:bplus_tv/pages/history_search/controller.dart';
import 'package:bplus_tv/utils/grid.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;

class HistorySearchPage extends StatefulWidget {
  const HistorySearchPage({super.key});

  @override
  State<HistorySearchPage> createState() => _HistorySearchPageState();
}

class _HistorySearchPageState
    extends
        CommonSearchPageState<HistorySearchPage, HistoryData, HistoryItemModel>
    with GridMixin {
  @override
  final HistorySearchController controller = Get.put(
    HistorySearchController(),
    tag: Utils.generateRandomString(8),
  );

  @override
  Widget buildList(List<HistoryItemModel> list) {
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
              return HistoryItem(
                item: item,
                ctr: controller,
                onDelete: (kid, business) =>
                    controller.onDelHistory(index, kid, business),
              );
            },
            itemCount: list.length,
          ),
        );
      },
    );
  }
}
