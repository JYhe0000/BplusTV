import 'dart:async';

import 'package:bplus_tv/http/loading_state.dart';
import 'package:bplus_tv/pages/common/common_controller.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('在途加载更多共享完成结果，完成后可以继续加载', () async {
    final controller = _Controller();
    addTearDown(controller.onDelete.call);
    final gate = controller.gate = Completer<void>();

    final first = controller.onLoadMore();
    final second = controller.onLoadMore();
    expect(identical(first, second), isTrue);
    expect(controller.requestCount, 1);

    gate.complete();
    await first;
    controller.gate = null;
    await controller.onLoadMore();
    expect(controller.requestCount, 2);
  });

  test('加载失败会传递异常，并允许下次重试', () async {
    final controller = _Controller()..fail = true;
    addTearDown(controller.onDelete.call);

    await expectLater(controller.onLoadMore(), throwsStateError);
    controller.fail = false;
    await controller.onLoadMore();
    expect(controller.requestCount, 2);
  });

  testWidgets('列表布局时多次触发分页，只在帧结束后准备一次请求', (
    tester,
  ) async {
    final controller = _Controller();
    addTearDown(controller.onDelete.call);
    late Future<void> pending;

    await tester.pumpWidget(
      LayoutBuilder(
        builder: (context, constraints) {
          pending = controller.onLoadMore();
          expect(identical(pending, controller.onLoadMore()), isTrue);
          expect(controller.requestCount, 0);
          return const SizedBox();
        },
      ),
    );
    await pending;
    expect(controller.requestCount, 1);
    expect(controller.requestPhase, isNot(SchedulerPhase.persistentCallbacks));
  });

  testWidgets('等待当前帧结束期间关闭页面，不再发起请求', (tester) async {
    final controller = _Controller();
    late Future<void> pending;

    await tester.pumpWidget(
      LayoutBuilder(
        builder: (context, constraints) {
          pending = controller.onLoadMore();
          controller.onDelete();
          return const SizedBox();
        },
      ),
    );
    await pending;
    expect(controller.requestCount, 0);
  });
}

class _Controller extends CommonController<int, int> {
  @override
  final loadingState = LoadingState<int>.loading().obs;

  int requestCount = 0;
  bool fail = false;
  Completer<void>? gate;
  SchedulerPhase? requestPhase;

  @override
  Future<LoadingState<int>> customGetData() async => const Success(1);

  @override
  Future<void> queryData([bool isRefresh = true]) async {
    requestCount++;
    requestPhase = SchedulerBinding.instance.schedulerPhase;
    if (fail) throw StateError('请求失败');
    await gate?.future;
  }
}
