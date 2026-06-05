import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:chongmi/config/url_strategy.dart';

void main() {
  test('uses hash URL strategy for GitHub Pages routes', () {
    final strategy = createGithubPagesUrlStrategy();

    expect(strategy.runtimeType, HashUrlStrategy);
    expect(strategy, isNot(isA<PathUrlStrategy>()));
  });

  test('configures the URL strategy after Flutter binding initialization', () {
    final source = File('lib/main.dart').readAsStringSync();
    final ensureBinding = source.indexOf(
      'WidgetsFlutterBinding.ensureInitialized()',
    );
    final configureStrategy = source.indexOf('configureGithubPagesUrlStrategy()');
    final runApp = source.indexOf('runApp(');

    expect(ensureBinding, isNonNegative);
    expect(configureStrategy, isNonNegative);
    expect(runApp, isNonNegative);
    expect(ensureBinding, lessThan(configureStrategy));
    expect(configureStrategy, lessThan(runApp));
  });
}
