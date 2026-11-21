import 'package:bplus_tv/pages/fav/pgc/child_view.dart';
import 'package:bplus_tv/pages/fav/pgc/controller.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:bplus_tv/utils/extension/scroll_controller_ext.dart';
import 'package:bplus_tv/utils/feed_back.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class FavPgcPage extends StatefulWidget {
  const FavPgcPage({super.key, required this.type});

  final int type;

  @override
  State<FavPgcPage> createState() => _FavPgcPageState();
}

class _FavPgcPageState extends State<FavPgcPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: 1,
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
              _buildTab(0, '想看'),
              _buildTab(1, '在看'),
              _buildTab(2, '看过'),
            ],
          ),
        ),
        // TextButton(
        //   style: TextButton.styleFrom(
        //     foregroundColor: theme.colorScheme.onSurfaceVariant,
        //     visualDensity:
        //         const VisualDensity(horizontal: -2, vertical: -2),
        //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        //   ),
        //   onPressed: () {},
        //   child: const Text('管理'),
        // ),
        // const SizedBox(width: 12),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
              3,
              (index) => FavPgcChildPage(
                type: widget.type,
                followStatus: index + 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index, String label) {
    final selected = _tabController.index == index;
    return Expanded(
      child: TvFocusable(
        onTap: () {
          feedBack();
          if (!_tabController.indexIsChanging) {
            final tag = '${widget.type}${index + 1}';
            if (Get.isRegistered<FavPgcController>(tag: tag)) {
              Get.find<FavPgcController>(
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
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
