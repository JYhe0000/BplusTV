import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/models/common/member/contribute_type.dart';
import 'package:bplus_tv/models_new/space/space_archive/data.dart';
import 'package:bplus_tv/models_new/space/space_archive/item.dart';
import 'package:bplus_tv/pages/member_video/controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('投稿分页', () {
    test('下一页追加内容，保留原视频对象及到达末页前的内容', () async {
      final controller = _ArchiveController([
        _page(['101', '102']),
        _page(['103', '104']),
        _page([], hasNext: false),
      ]);
      addTearDown(controller.onClose);

      await controller.queryData();
      final firstVideo = controller.loadingState.value.data!.first;
      await controller.onLoadMore();

      expect(_ids(controller), ['101', '102', '103', '104']);
      expect(controller.loadingState.value.data!.first, same(firstVideo));
      expect(controller.lastAid, '104');

      await controller.onLoadMore();
      expect(_ids(controller), ['101', '102', '103', '104']);
      expect(controller.isEnd, isTrue);

      await controller.onLoadMore();
      expect(controller.requestCount, 3);
    });

    test('刷新替换旧内容，刷新后的加载更多仍追加到新列表', () async {
      final controller = _ArchiveController([
        _page(['101', '102']),
        _page(['103']),
        _page(['201', '202']),
        _page(['203'], hasNext: false),
      ]);
      addTearDown(controller.onClose);

      await controller.queryData();
      await controller.onLoadMore();
      await controller.onRefresh();
      expect(_ids(controller), ['201', '202']);

      await controller.onLoadMore();
      expect(_ids(controller), ['201', '202', '203']);
      expect(controller.isEnd, isTrue);
    });
  });
}

List<String?> _ids(MemberVideoCtr controller) => [
  for (final item in controller.loadingState.value.data!) item.param,
];

SpaceArchiveData _page(List<String> ids, {bool hasNext = true}) =>
    SpaceArchiveData(
      item: [
        for (final id in ids)
          SpaceArchiveItem.fromJson({'param': id, 'title': id}),
      ],
      hasNext: hasNext,
    );

class _ArchiveController extends MemberVideoCtr {
  _ArchiveController(this.responses)
    : super(
        heroTag: null,
        type: ContributeType.video,
        mid: 1,
        seasonId: null,
        seriesId: null,
      ) {
    page = 0;
  }

  final List<SpaceArchiveData> responses;
  int requestCount = 0;

  @override
  Future<LoadingState<SpaceArchiveData>> customGetData() async =>
      Success(responses[requestCount++]);
}
