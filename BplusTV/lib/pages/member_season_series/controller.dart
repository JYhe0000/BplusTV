import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/http/member.dart';
import 'package:bplus_tv/models_new/space/space_season_series/item.dart';
import 'package:bplus_tv/models_new/space/space_season_series/season.dart';
import 'package:bplus_tv/pages/common/common_list_controller.dart';

class SeasonSeriesController
    extends CommonListController<SpaceSsData, SpaceSsModel> {
  SeasonSeriesController(this.mid);
  final int mid;
  int? count;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  List<SpaceSsModel>? getDataList(SpaceSsData response) {
    count = response.page?.total;
    return (response.seasonsList ?? <SpaceSsModel>[]) +
        (response.seriesList ?? <SpaceSsModel>[]);
  }

  @override
  void checkIsEnd(int length) {
    if (count != null && length >= count!) {
      isEnd = true;
    }
  }

  @override
  Future<LoadingState<SpaceSsData>> customGetData() =>
      MemberHttp.seasonSeriesList(
        mid: mid,
        pn: page,
      );
}
