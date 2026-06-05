import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:chongmi/services/db_config_service.dart';
import 'package:chongmi/services/leancloud_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chongmi_hive_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('initializes every box used during app startup', () async {
    await LeanCloudService.initialize();

    expect(Hive.isBoxOpen('user'), isTrue);
    expect(Hive.isBoxOpen('settings'), isTrue);
    expect(Hive.isBoxOpen('daily_quote_cache'), isTrue);
  });

  test('opens startup boxes sequentially for browser IndexedDB stability', () {
    final source =
        File('lib/services/db_config_service.dart').readAsStringSync();

    expect(source, contains('_criticalStartupBoxNames'));
    expect(source, contains('_deferredStartupBoxNames'));
    expect(source, contains('kIsWeb'));
    expect(source, contains('unawaited('));
    expect(source, contains('_openDeferredStartupBoxes'));
    expect(source, isNot(contains('Future.wait([')));
  });

  test('uses the Cloudflare WebDAV proxy as the default endpoint', () async {
    await LeanCloudService.initialize();

    expect(
      DbConfigService.webdavUrl,
      'https://love-app-webdav-proxy.chenlichong813.workers.dev/dav/',
    );
  });

  test('migrates the old direct Jianguoyun endpoint to the Cloudflare proxy',
      () async {
    await LeanCloudService.initialize();
    await DbConfigService.saveWebdavConfig(
      url: 'https://dav.jianguoyun.com/dav/',
      user: 'user@example.com',
      password: 'app-password',
    );
    await Hive.close();
    Hive.init(tempDir.path);

    await LeanCloudService.initialize();

    expect(
      DbConfigService.webdavUrl,
      'https://love-app-webdav-proxy.chenlichong813.workers.dev/dav/',
    );
    expect(DbConfigService.webdavUser, 'user@example.com');
    expect(DbConfigService.webdavPassword, 'app-password');
  });
}
