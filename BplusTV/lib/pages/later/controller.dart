import 'package:bplus_tv/common/widgets/dialog/dialog.dart';
import 'package:bplus_tv/tv/tv_dialog.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/http/user.dart';
import 'package:bplus_tv/models/common/later_view_type.dart';
import 'package:bplus_tv/models/common/video/source_type.dart';
import 'package:bplus_tv/models_new/later/data.dart';
import 'package:bplus_tv/models_new/later/list.dart';
import 'package:bplus_tv/pages/common/common_list_controller.dart'
    show CommonListController;
import 'package:bplus_tv/pages/common/multi_select/base.dart';
import 'package:bplus_tv/pages/common/multi_select/multi_select_controller.dart';
import 'package:bplus_tv/pages/later/base_controller.dart';
import 'package:bplus_tv/utils/accounts.dart';
import 'package:bplus_tv/utils/extension/get_ext.dart';
import 'package:bplus_tv/utils/extension/scroll_controller_ext.dart';
import 'package:bplus_tv/utils/page_utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

mixin BaseLaterController
    on
        CommonListController<LaterData, LaterItemModel>,
        CommonMultiSelectMixin<LaterItemModel>,
        DeleteItemMixin<LaterData, LaterItemModel> {
  ValueChanged<int>? updateCount;

  @override
  void onRemove() {
    showConfirmDialog(
      context: Get.context!,
      title: const Text('提示'),
      content: const Text('确认删除所选稍后再看吗？'),
      onConfirm: () async {
        final removeList = allChecked.toSet();
        SmartDialog.showLoading(msg: '请求中');
        final res = await UserHttp.toViewDel(
          aids: removeList.map((item) => item.aid).join(','),
        );
        if (res.isSuccess) {
          updateCount?.call(removeList.length);
          afterDelete(removeList);
        }
        SmartDialog.dismiss();
      },
    );
  }

  // single
  void toViewDel(
    BuildContext context,
    int index,
    int? aid,
  ) {
    {
      showTvConfirm(
        context: context,
        title: '提示',
        message: '即将移除该视频，确定是否移除',
        confirmLabel: '确认移除',
      ).then((res) async {
        if (res != true) return;
        final res2 = await UserHttp.toViewDel(aids: aid.toString());
        if (res2.isSuccess) {
          loadingState
            ..value.data!.removeAt(index)
            ..refresh();
          updateCount?.call(1);
        }
      });
      return;
    }
  }
}

class LaterController extends MultiSelectController<LaterData, LaterItemModel>
    with BaseLaterController {
  LaterController(this.laterViewType);
  final LaterViewType laterViewType;

  late final mid = Accounts.main.mid;

  final RxBool asc = false.obs;

  // 用 putOrFind 复用根页面已创建的实例：Get.put 同 tag 会新建并替换，
  // 导致父页面持有旧实例、子页面拿到新实例，多选状态不同步。
  final LaterBaseController baseCtr = Get.putOrFind(
    LaterBaseController.new,
    tag: 'laterBase',
  );

  @override
  RxBool get enableMultiSelect => baseCtr.enableMultiSelect;

  @override
  RxInt get rxCount => baseCtr.checkedCount;

  @override
  Future<LoadingState<LaterData>> customGetData() => UserHttp.seeYouLater(
    page: page,
    viewed: laterViewType.type,
    asc: asc.value,
  );

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  List<LaterItemModel>? getDataList(response) {
    baseCtr.counts[laterViewType.index] = response.count ?? 0;
    return response.list;
  }

  @override
  void checkIsEnd(int length) {
    if (length >= baseCtr.counts[laterViewType.index]) {
      isEnd = true;
    }
  }

  // 一键清空
  void toViewClear(BuildContext context, [int? cleanType]) {
    String content = switch (cleanType) {
      1 => '确定清空已失效视频吗？',
      2 => '确定清空已看完视频吗？',
      _ => '确定清空稍后再看列表吗？',
    };
    showConfirmDialog(
      context: context,
      title: const Text('确认'),
      content: Text(content),
      onConfirm: () async {
        final res = await UserHttp.toViewClear(cleanType);
        if (res.isSuccess) {
          onReload();
          final restTypes = List<LaterViewType>.from(LaterViewType.values)
            ..remove(laterViewType);
          for (final item in restTypes) {
            try {
              Get.find<LaterController>(tag: item.type.toString()).onReload();
            } catch (_) {}
          }
          SmartDialog.showToast('已清空');
        } else {
          res.toast();
        }
      },
    );
  }

  // 稍后再看播放全部
  void toViewPlayAll() {
    if (loadingState.value case Success(:final response)) {
      if (response == null || response.isEmpty) return;

      for (LaterItemModel item in response) {
        if (item.cid == null || item.pgcLabel?.isNotEmpty == true) {
          continue;
        } else {
          PageUtils.toVideoPage(
            bvid: item.bvid,
            cid: item.cid!,
            cover: item.pic,
            title: item.title,
            dimension: item.dimension,
            extraArguments: {
              'sourceType': SourceType.watchLater,
              'count': baseCtr.counts[LaterViewType.all.index],
              'favTitle': '稍后再看',
              'mediaId': mid,
              'desc': asc.value,
            },
          );
          break;
        }
      }
    }
  }

  @override
  ValueChanged<int>? get updateCount =>
      (count) => baseCtr.counts[laterViewType.index] -= count;

  @override
  Future<void> onReload() {
    scrollController.jumpToTop();
    return super.onReload();
  }
}
