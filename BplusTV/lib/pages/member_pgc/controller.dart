import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/http/member.dart';
import 'package:bplus_tv/models/common/member/contribute_type.dart';
import 'package:bplus_tv/models_new/space/space/data.dart';
import 'package:bplus_tv/models_new/space/space_archive/data.dart';
import 'package:bplus_tv/models_new/space/space_archive/item.dart';
import 'package:bplus_tv/pages/common/common_list_controller.dart';
import 'package:bplus_tv/pages/member/controller.dart';
import 'package:get/get.dart';

class MemberBangumiCtr
    extends CommonListController<SpaceArchiveData, SpaceArchiveItem> {
  MemberBangumiCtr({
    required this.mid,
    required this.heroTag,
  });

  final int mid;
  final String? heroTag;
  int? count;
  late final _ctr = Get.find<MemberController>(tag: heroTag);

  @override
  void onInit() {
    super.onInit();
    SpaceData? response = _ctr.loadingState.value.data;
    // season/item/count 均可空，缺失时走分页查询兜底，避免强解包崩溃
    final season = response?.season;
    if (season != null) {
      page = 2;
      final item = season.item;
      loadingState.value = Success(item);
      count = season.count;
      isEnd = season.count != null && (item?.length ?? 0) >= season.count!;
    } else {
      queryData();
    }
  }

  @override
  List<SpaceArchiveItem>? getDataList(SpaceArchiveData response) {
    return response.item;
  }

  @override
  void checkIsEnd(int length) {
    if (count != null && length >= count!) {
      isEnd = true;
    }
  }

  @override
  Future<LoadingState<SpaceArchiveData>> customGetData() =>
      MemberHttp.spaceArchive(
        type: ContributeType.bangumi,
        mid: mid,
        pn: page,
      );
}
