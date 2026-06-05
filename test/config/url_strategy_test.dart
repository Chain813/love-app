import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:chongmi/config/url_strategy.dart';

void main() {
  test('uses hash URL strategy for GitHub Pages routes', () {
    final strategy = createGithubPagesUrlStrategy();

    expect(strategy.runtimeType, HashUrlStrategy);
    expect(strategy, isNot(isA<PathUrlStrategy>()));
  });
}
