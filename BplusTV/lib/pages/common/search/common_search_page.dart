import 'package:bplus_tv/common/widgets/appbar/appbar.dart';
import 'package:bplus_tv/common/widgets/flutter/pop_scope.dart';
import 'package:bplus_tv/common/widgets/loading_widget/http_error.dart';
import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/common/widgets/view_insets_safe_area.dart';
import 'package:bplus_tv/common/widgets/view_sliver_safe_area.dart';
import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/pages/common/multi_select/base.dart';
import 'package:bplus_tv/pages/common/search/common_search_controller.dart';
import 'package:bplus_tv/tv/tv_back_bar.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:bplus_tv/tv/tv_text_input.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

abstract class CommonSearchPageState<S extends StatefulWidget, R, T>
    extends State<S> {
  CommonSearchController<R, T> get controller;

  List<Widget>? get extraActions => null;

  List<Widget>? get multiSelectActions => null;

  @override
  Widget build(BuildContext context) {
    if (controller case final MultiSelectBase multiCtr) {
      return Obx(() {
        final enableMultiSelect = multiCtr.enableMultiSelect.value;
        return popScope(
          canPop: !enableMultiSelect,
          onPopInvokedWithResult: (didPop, result) {
            if (enableMultiSelect) {
              multiCtr.handleSelect();
            }
          },
          child: _build(true),
        );
      });
    }
    return _build(false);
  }

  Widget _build(bool multiSelect) {
    final content = SimpleScaffold(
      appBar: _buildBar(multiSelect),
      body: ViewInsetsSafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: controller.scrollController,
          slivers: [
            ViewSliverSafeArea(
              sliver: Obx(() => _buildBody(controller.loadingState.value)),
            ),
          ],
        ),
      ),
    );
    return TvPageFocus(child: content);
  }

  PreferredSizeWidget _buildBar(bool multiSelect) {
    {
      return _buildTvBar(multiSelect);
    }
  }

  PreferredSizeWidget _buildTvBar(bool multiSelect) {
    final colorScheme = Theme.of(context).colorScheme;
    final canPop = Navigator.of(context).canPop();
    final bar = AppBar(
      automaticallyImplyLeading: false,
      leading: canPop ? const TvBackButton() : null,
      leadingWidth: canPop ? 64 : null,
      actions: [
        TvFocusable(
          onTap: controller.onRefresh,
          builder: (context, focused, hovered) => TvFocusHighlight(
            focused: focused,
            radius: 16,
            borderWidth: 2,
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.search_outlined, size: 22),
            ),
          ),
        ),
        ...?extraActions,
        const SizedBox(width: 10),
      ],
      title: TvFocusable(
        autofocus: true,
        onTap: () => _onTvSearch(context),
        builder: (context, focused, hovered) => TvFocusHighlight(
          focused: focused,
          radius: 12,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    controller.editController.text.isEmpty
                        ? '搜索'
                        : controller.editController.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (multiSelect) {
      return MultiSelectAppBarWidget(
        ctr: controller as MultiSelectBase,
        actions: multiSelectActions,
        child: bar,
      );
    }
    return bar;
  }

  Future<void> _onTvSearch(BuildContext context) async {
    final text = await showTvTextInput(
      context,
      title: '搜索',
      initialValue: controller.editController.text,
    );
    if (text == null) return;
    controller.editController.text = text;
    controller.onRefresh();
    if (mounted) setState(() {});
  }

  Widget _buildBody(LoadingState<List<T>?> loadingState) {
    return switch (loadingState) {
      Loading() => const HttpError(),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? buildList(response)
            : HttpError(onReload: controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }

  Widget buildList(List<T> list);
}
