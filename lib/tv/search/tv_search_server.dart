import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Hosts a tiny LAN web page on the TV.
///
/// The TV shows a QR code pointing at `http://<tv-ip>:<port>/?t=<token>`.
/// A phone on the same network opens it, types a keyword, and submits it.
/// The keyword is delivered to [onSearch].
///
/// No external backend is involved. The token is single-session and the
/// server shuts itself down after [ttl].
class TvSearchServer {
  TvSearchServer({required this.onSearch});

  final void Function(String keyword) onSearch;

  HttpServer? _server;
  String? _token;
  Timer? _expireTimer;
  bool _busy = false;

  int? get port => _server?.port;

  bool get isRunning => _server != null;

  /// Returns the URL a phone should open, or null if not running.
  Future<String?> get url async {
    if (_server == null || _token == null) return null;
    final ip = await _lanIp();
    if (ip == null) return null;
    return 'http://$ip:${_server!.port}/?t=$_token';
  }

  Future<void> start({Duration ttl = const Duration(minutes: 10)}) async {
    await stop();
    _token = _randomToken();
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0, shared: true);
    _server!.listen(_handle, onError: (_) {});
    _expireTimer = Timer(ttl, stop);
  }

  Future<void> stop() async {
    _expireTimer?.cancel();
    _expireTimer = null;
    final server = _server;
    _server = null;
    _token = null;
    await server?.close(force: true);
  }

  Future<void> _handle(HttpRequest req) async {
    if (_busy) {
      await _respond(req, HttpStatus.serviceUnavailable, {'ok': false});
      return;
    }
    _busy = true;
    try {
      final path = req.uri.path;
      if (req.method == 'POST' && path == '/search') {
        await _handleSearch(req);
      } else if (req.method == 'GET' &&
          (path == '/' || path == '/index.html')) {
        req.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write(_pageHtml);
        await req.response.close();
      } else {
        await _respond(req, HttpStatus.notFound, {'ok': false});
      }
    } catch (_) {
      try {
        await _respond(req, HttpStatus.internalServerError, {'ok': false});
      } catch (_) {}
    } finally {
      _busy = false;
    }
  }

  Future<void> _handleSearch(HttpRequest req) async {
    if (req.uri.queryParameters['t'] != _token || _token == null) {
      await _respond(req, HttpStatus.forbidden, {
        'ok': false,
        'msg': '会话已过期，请重新扫码',
      });
      return;
    }
    final body = await utf8.decoder.bind(req).join();
    String keyword = '';
    try {
      final data = jsonDecode(body);
      if (data is Map && data['keyword'] is String) {
        keyword = (data['keyword'] as String).trim();
      }
    } catch (_) {}
    if (keyword.isEmpty) {
      await _respond(req, HttpStatus.badRequest, {
        'ok': false,
        'msg': '请输入搜索内容',
      });
      return;
    }
    onSearch(keyword);
    await _respond(req, HttpStatus.ok, {'ok': true});
  }

  Future<void> _respond(
    HttpRequest req,
    int status,
    Map<String, Object?> body,
  ) async {
    req.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    await req.response.close();
  }

  static Future<String?> _lanIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          final ip = address.address;
          if (ip.startsWith('169.254.')) continue;
          if (ip.startsWith('192.168.') ||
              ip.startsWith('10.') ||
              ip.startsWith('172.')) {
            return ip;
          }
        }
      }
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback) return address.address;
        }
      }
    } catch (_) {}
    return null;
  }

  static String _randomToken() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
  }

  String get _pageHtml => '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<title>BplusTV 搜索</title>
<style>
  :root { color-scheme: dark; }
  * { box-sizing: border-box; }
  body { margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center;
         background: #121212; color: #eee; font-family: system-ui, -apple-system, "PingFang SC", sans-serif; }
  .card { width: 90%; max-width: 420px; padding: 28px 22px; border-radius: 18px; background: #1e1e1e;
          box-shadow: 0 8px 30px rgba(0,0,0,.5); }
  h1 { margin: 0 0 4px; font-size: 20px; }
  p { margin: 0 0 20px; color: #999; font-size: 13px; }
  input { width: 100%; padding: 14px 16px; font-size: 18px; border-radius: 12px; border: 1px solid #333;
          background: #2a2a2a; color: #eee; outline: none; }
  input:focus { border-color: #5CB67B; }
  button { width: 100%; margin-top: 16px; padding: 14px; font-size: 17px; font-weight: 600;
           border: none; border-radius: 12px; background: #5CB67B; color: #fff; }
  button:active { opacity: .8; }
  button:disabled { background: #444; color: #999; }
  #msg { margin-top: 14px; font-size: 14px; min-height: 20px; text-align: center; color: #5CB67B; }
  #msg.err { color: #ff6b6b; }
</style>
</head>
<body>
  <div class="card">
    <h1>在电视上搜索</h1>
    <p>输入关键词，电视会立即开始搜索</p>
    <input id="kw" type="search" placeholder="输入视频 / UP主 / 番剧" autocomplete="off" autofocus>
    <button id="go">发送到电视</button>
    <div id="msg"></div>
  </div>
<script>
  const token = new URLSearchParams(location.search).get('t') || '';
  const input = document.getElementById('kw');
  const button = document.getElementById('go');
  const msg = document.getElementById('msg');
  async function send() {
    const keyword = input.value.trim();
    if (!keyword) { show('请输入搜索内容', true); return; }
    button.disabled = true;
    show('发送中…', false);
    try {
      const res = await fetch('/search?t=' + encodeURIComponent(token), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ keyword })
      });
      const data = await res.json().catch(() => ({}));
      if (res.ok && data.ok) {
        show('已发送到电视', false);
        input.value = '';
      } else {
        show(data.msg || '发送失败，请重新扫码', true);
      }
    } catch (e) {
      show('网络错误，请确认与电视在同一网络', true);
    } finally {
      button.disabled = false;
      input.focus();
    }
  }
  function show(text, isErr) {
    msg.textContent = text;
    msg.className = isErr ? 'err' : '';
  }
  button.addEventListener('click', send);
  input.addEventListener('keydown', e => { if (e.key === 'Enter') send(); });
</script>
</body>
</html>
''';
}
