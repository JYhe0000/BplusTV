import 'package:bplus_tv/common/widgets/scaffold/simple_scaffold.dart';
import 'package:bplus_tv/common/widgets/scroll_physics.dart' show tabBarView;
import 'package:bplus_tv/common/widgets/view_safe_area.dart';
import 'package:bplus_tv/pages/member_search/child/view.dart';
import 'package:bplus_tv/pages/member_search/controller.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/tv/tv_focus_card.dart';
import 'package:bplus_tv/tv/tv_page_focus.dart';
import 'package:bplus_tv/utils/feed_back.dart';
import 'package:bplus_tv/utils/utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class MemberSearchPage extends StatefulWidget {
  const MemberSearchPage({super.key});

  @override
  State<MemberSearchPage> createState() => _MemberSearchPageState();
}

class _MemberSearchPageState extends State<MemberSearchPage> {
  final _controller = Get.put(
    MemberSearchController(),
    tag: Utils.generateRandomString(8),
  );

  @override
  Widget build(BuildContext context) {
    final content = SimpleScaffold(
      appBar: AppBar(
        actions: [
          TvFocusButton(
            radius: 8,
            onTap: _controller.submit,
            child: IconButton(
              tooltip: '搜索',
              onPressed: _controller.submit,
              icon: const Icon(Icons.search, size: 22),
            ),
          ),
          const SizedBox(width: 10),
        ],
        title: TextField(
          autofocus: true,
          focusNode: _controller.focusNode,
          controller: _controller.editingController,
          textInputAction: TextInputAction.search,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: '搜索',
            visualDensity: .standard,
            border: InputBorder.none,
            suffixIcon: TvFocusButton(
              radius: 8,
              onTap: _controller.onClear,
              child: IconButton(
                tooltip: '清空',
                icon: const Icon(Icons.clear, size: 22),
                onPressed: _controller.onClear,
              ),
            ),
          ),
          onSubmitted: (value) => _controller.submit(),
          onChanged: (value) {
            if (value.isEmpty) {
              _controller.hasData.value = false;
            }
          },
        ),
      ),
      body: ViewSafeArea(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Obx(() {
              return Opacity(
                opacity: _controller.hasData.value ? 1 : 0,
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _controller.tabController,
                      builder: (context, _) => Row(
                        children: [
                          _buildTab(0, '视频', _controller.counts[0]),
                          _buildTab(1, '动态', _controller.counts[1]),
                        ],
                      ),
                    ),
                    Expanded(
                      child: tabBarView(
                        controller: _controller.tabController,
                        children: [
                          MemberSearchChildPage(
                            controller: _controller.arcCtr,
                            searchType: .archive,
                          ),
                          MemberSearchChildPage(
                            controller: _controller.dynCtr,
                            searchType: .dynamic,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            Obx(
              () => _controller.hasData.value
                  ? const SizedBox.shrink()
                  : Align(
                      alignment: const Alignment(0, -0.5),
                      child: Text(
                        '搜索「${_controller.uname}」的动态、视频',
                        textAlign: TextAlign.center,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
    return TvPageFocus(child: content);
  }

  Widget _buildTab(int index, String label, int count) {
    final selected = _controller.tabController.index == index;
    return Expanded(
      child: TvFocusable(
        onTap: () {
          feedBack();
          if (!_controller.tabController.indexIsChanging) {
            if (index == 0) {
              _controller.arcCtr.animateToTop();
            } else {
              _controller.dynCtr.animateToTop();
            }
          }
        },
        builder: (context, focused, hovered) => TvFocusHighlight(
          focused: focused,
          radius: 16,
          borderWidth: 2,
          // 无选中底：选中只用文字颜色/字重区分，焦点用光晕反馈
          child: Obx(
            () => Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '$label ${count != -1 ? count : ''}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
