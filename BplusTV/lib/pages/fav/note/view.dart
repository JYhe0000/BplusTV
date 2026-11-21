import 'package:bplus_tv/pages/fav/note/child_view.dart';
import 'package:bplus_tv/pages/fav/note/controller.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/extension/scroll_controller_ext.dart';
import 'package:bplus_tv/utils/feed_back.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class FavNotePage extends StatefulWidget {
  const FavNotePage({super.key});

  @override
  State<FavNotePage> createState() => _FavNotePageState();
}

class _FavNotePageState extends State<FavNotePage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) => Row(
            children: [
              _buildTab(0, '未发布笔记'),
              _buildTab(1, '公开笔记'),
            ],
          ),
        ),
        // TextButton(
        //   style: TextButton.styleFrom(
        //     foregroundColor: theme.colorScheme.onSurfaceVariant,
        //     visualDensity: VisualDensity.compact,
        //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        //   ),
        //   onPressed: () async {
        //     final favNoteController = Get.find<FavNoteController>(
        //         tag: _tabController.index == 0 ? 'false' : 'true');
        //     if (favNoteController.enableMultiSelect.value) {
        //       favNoteController.onDisable();
        //     } else {
        //       if (favNoteController.loadingState.value.isSuccess &&
        //           favNoteController.loadingState.value.data?.isNotEmpty ==
        //               true) {
        //         favNoteController.enableMultiSelect.value = true;
        //       }
        //     }
        //   },
        //   child: const Text('管理'),
        // ),
        // const SizedBox(width: 12),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              FavNoteChildPage(isPublish: false),
              FavNoteChildPage(isPublish: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index, String label) {
    final selected = _tabController.index == index;
    final theme = Theme.of(context);
    return Expanded(
      child: TvFocusable(
        onTap: () {
          feedBack();
          if (!_tabController.indexIsChanging) {
            final tag = index == 0 ? 'false' : 'true';
            if (Get.isRegistered<FavNoteController>(tag: tag)) {
              Get.find<FavNoteController>(
                tag: tag,
              ).scrollController.animToTop();
            }
          }
        },
        builder: (context, focused, hovered) => TvFocusHighlight(
          focused: focused,
          radius: 16,
          borderWidth: 2,
          // 无选中底：选中只用文字颜色/字重区分，焦点用光晕反馈
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
