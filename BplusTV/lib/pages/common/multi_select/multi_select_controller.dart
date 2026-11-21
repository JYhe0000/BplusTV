import 'package:bplus_tv/pages/common/common_list_controller.dart';
import 'package:bplus_tv/pages/common/multi_select/base.dart';

abstract class MultiSelectController<
  R,
  T extends MultiSelectData
> = CommonListController<R, T>
    with CommonMultiSelectMixin<T>, DeleteItemMixin;
