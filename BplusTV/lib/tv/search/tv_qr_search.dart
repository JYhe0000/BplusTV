import 'dart:async';

import 'package:bplus_tv/common/widgets/netflix_surface.dart';
import 'package:bplus_tv/tv/search/tv_search_server.dart';
import 'package:bplus_tv/tv/tv_focus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

/// Shows a QR code that a phone can scan to type a search keyword which is
/// then sent back to the TV over the LAN. Resolves with the keyword, or null
/// if the dialog was dismissed.
Future<String?> showTvQrSearch(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const TvQrSearchDialog(),
  );
}

class TvQrSearchDialog extends StatefulWidget {
  const TvQrSearchDialog({super.key});

  @override
  State<TvQrSearchDialog> createState() => _TvQrSearchDialogState();
}

class _TvQrSearchDialogState extends State<TvQrSearchDialog> {
  late final TvSearchServer _server;
  String? _url;
  String? _error;

  @override
  void initState() {
    super.initState();
    _server = TvSearchServer(onSearch: _onSearch);
    _start();
  }

  Future<void> _start() async {
    try {
      await _server.start();
      final url = await _server.url;
      if (!mounted) return;
      setState(() {
        _url = url;
        if (url == null) {
          _error = '未检测到局域网地址，请确认电视已连接网络';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '无法启动局域网服务：$e');
    }
  }

  void _onSearch(String keyword) {
    if (!mounted) return;
    Navigator.of(context).pop(keyword);
  }

  @override
  void dispose() {
    // `stop` is async; close the listener eagerly so a queued request can no
    // longer call back into a disposed dialog.
    unawaited(_server.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(32),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 600.0;
          final qrSize = (available * 0.42).clamp(120.0, 260.0);
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: netflixSurface(
              radius: 32,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '手机扫码搜索',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '用手机扫码，在手机上输入关键词，电视会立即搜索',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.outline,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      )
                    else if (_url == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: CircularProgressIndicator(),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SizedBox(
                          width: qrSize,
                          height: qrSize,
                          child: PrettyQrView.data(
                            data: _url!,
                            errorCorrectLevel: QrErrorCorrectLevel.M,
                            decoration: const PrettyQrDecoration(
                              quietZone: PrettyQrQuietZone.modules(1),
                            ),
                          ),
                        ),
                      ),
                    if (_url != null) ...[
                      const SizedBox(height: 12),
                      SelectableText(
                        _url!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.outline,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '请确保手机与电视连接同一网络',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.outline,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TvFocusable(
                      autofocus: true,
                      onTap: () => Navigator.of(context).maybePop(),
                      builder: (context, focused, hovered) => TvFocusHighlight(
                        radius: 24,
                        focused: focused,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 96,
                            minHeight: 48,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '关闭',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
