import 'package:flutter_web_plugins/url_strategy.dart';

UrlStrategy createGithubPagesUrlStrategy() => const HashUrlStrategy();

void configureGithubPagesUrlStrategy() {
  setUrlStrategy(createGithubPagesUrlStrategy());
}
