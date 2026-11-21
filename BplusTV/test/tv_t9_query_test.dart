import 'package:bplus_tv/tv/search/t9_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recognizes T9 letters, digits and spaces as resolvable queries', () {
    expect(isT9Query('ywsn'), isTrue);
    expect(isT9Query('9976'), isTrue);
    expect(isT9Query(' ywsn '), isTrue);
    expect(isT9Query('药屋少女'), isFalse);
    expect(isT9Query(''), isFalse);
    expect(isT9Query('.'), isFalse);
  });

  test('prefers the first Chinese suggestion for a T9 query', () {
    expect(
      pickT9Suggestion('ywsn', const [
        'ywsn',
        '药屋少女的呢喃第一季',
        '药物少女的呢喃',
      ]),
      '药屋少女的呢喃第一季',
    );
    expect(pickT9Suggestion('ywsn', const ['ywsn']), isNull);
    expect(pickT9Suggestion('药屋少女', const ['药屋少女']), isNull);
  });
}
