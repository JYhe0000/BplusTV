final _t9QueryPattern = RegExp(r'^[a-zA-Z2-9 ]+$');
final _cjkPattern = RegExp(r'[\u4e00-\u9fff]');

/// Whether [text] is something the T9 keypad can produce and that should be
/// resolved from pinyin/T9 input into a Chinese search keyword.
bool isT9Query(String text) {
  final value = text.trim();
  return value.isNotEmpty && _t9QueryPattern.hasMatch(value);
}

bool hasCjk(String text) => _cjkPattern.hasMatch(text);

/// Picks the first Chinese suggestion for a T9/pinyin query. Bilibili's
/// suggest endpoint already expands `ywsn` to `药屋少女的呢喃…`, so preferring
/// a Chinese term avoids searching for the raw Latin letters.
String? pickT9Suggestion(String query, Iterable<String> suggestions) {
  if (!isT9Query(query)) return null;
  for (final suggestion in suggestions) {
    final value = suggestion.trim();
    if (value.isNotEmpty && hasCjk(value)) return value;
  }
  return null;
}
