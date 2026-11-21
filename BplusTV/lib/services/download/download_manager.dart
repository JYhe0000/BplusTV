import 'dart:async';
import 'dart:io';

import 'package:bplus_tv/http/init.dart';
import 'package:bplus_tv/models_new/download/bili_download_entry_info.dart';
import 'package:bplus_tv/utils/extension/file_ext.dart';
import 'package:bplus_tv/utils/extension/string_ext.dart';
import 'package:dio/dio.dart';

class DownloadManager {
  final String url;
  final String path;
  final void Function(int, int)? onReceiveProgress;
  final void Function([Object? error]) onDone;

  DownloadStatus _status = DownloadStatus.downloading;

  DownloadStatus get status => _status;
  final _cancelToken = CancelToken();
  late Future<void> task;

  DownloadManager({
    required this.url,
    required this.path,
    required this.onReceiveProgress,
    required this.onDone,
  }) {
    task = _start();
  }

  Future<void> _start() async {
    final file = File(path);
    IOSink? sink;

    Future<void> onError(Object e, {bool delete = false}) async {
      try {
        await sink?.close();
      } catch (_) {}
      // 用户主动暂停/取消, 保留文件以便续传, 不视为失败
      if (_status == DownloadStatus.pause) {
        return;
      }
      if (_status == DownloadStatus.downloading) {
        _status = DownloadStatus.failDownload;
        if (delete && file.existsSync()) {
          await file.tryDel();
        }
      }
      onDone(e);
    }

    int received;
    try {
      if (file.existsSync()) {
        received = await file.length();
      } else {
        file.createSync(recursive: true);
        received = 0;
      }
      sink = file.openWrite(
        mode: received == 0 ? FileMode.writeOnly : FileMode.writeOnlyAppend,
      );
    } catch (e) {
      await onError(e, delete: true);
      return;
    }

    Response<ResponseBody> response;
    try {
      response = await Request.http11Dio.get<ResponseBody>(
        url.http2https,
        options: Options(
          headers: {'range': 'bytes=$received-'},
          responseType: ResponseType.stream,
          validateStatus: (status) =>
              status != null &&
              (status == 416 || (status >= 200 && status < 300)),
        ),
        cancelToken: _cancelToken,
      );
    } on DioException catch (e) {
      await onError(e, delete: true);
      return;
    }

    final data = response.data;
    if (data == null) {
      await onError(StateError('empty response'), delete: true);
      return;
    }

    // 服务端忽略 Range 返回 200, 无法续传, 需归零并覆盖写入, 避免文件损坏
    if (received > 0 && response.statusCode != 206) {
      received = 0;
      try {
        await sink.close();
      } catch (_) {}
      sink = file.openWrite(mode: FileMode.writeOnly);
    }

    // content-range 形如 "bytes 100-199/250", 取其总长度作为基准
    final contentRange = response.headers.value('content-range');
    final totalFromRange = contentRange == null
        ? null
        : int.tryParse(contentRange.split('/').last);
    final contentLength = totalFromRange ?? data.contentLength + received;
    final out = sink;

    if (received == 0) {
      onReceiveProgress?.call(0, contentLength);
    }

    int? last;
    try {
      await for (final chunk in data.stream) {
        out.add(chunk);
        received += chunk.length;
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (last != now) {
          last = now;
          onReceiveProgress?.call(received, contentLength);
        }
      }
      await out.close();
      _status = DownloadStatus.completed;
      onDone();
    } catch (e) {
      await onError(e);
      return;
    }
  }

  Future<void> cancel({required bool isDelete}) {
    if (!isDelete && _status == DownloadStatus.downloading) {
      _status = DownloadStatus.pause;
    }
    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel();
    }
    return task;
  }
}
