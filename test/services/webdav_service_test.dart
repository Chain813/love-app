import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:chongmi/services/db_config_service.dart';
import 'package:chongmi/services/leancloud_service.dart';
import 'package:chongmi/services/webdav_service.dart';

void main() {
  late Directory tempDir;
  late HttpServer server;
  late List<String> mkcolPaths;
  late String? lastPutPath;
  late Map<String, dynamic>? lastJsonPut;

  Future<void> startServer(
    FutureOr<void> Function(HttpRequest request) handler,
  ) async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    unawaited(
      server.forEach((request) async {
        try {
          await handler(request);
        } catch (error) {
          request.response.statusCode = HttpStatus.internalServerError;
          request.response.write(error.toString());
        } finally {
          await request.response.close();
        }
      }),
    );
  }

  String serverUrl() => 'http://127.0.0.1:${server.port}/dav/';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chongmi_webdav_test_');
    Hive.init(tempDir.path);
    await LeanCloudService.initialize();
    await DbConfigService.setDbType(DbType.webdav);
    mkcolPaths = [];
    lastPutPath = null;
    lastJsonPut = null;
  });

  tearDown(() async {
    await server.close(force: true);
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('login creates both sync and image directories', () async {
    await startServer((request) {
      if (request.method == 'PROPFIND') {
        request.response.statusCode = 207;
        return;
      }
      if (request.method == 'MKCOL') {
        mkcolPaths.add(request.uri.path);
        request.response.statusCode = HttpStatus.created;
        return;
      }
      if (request.method == 'GET' &&
          request.uri.path.contains('couple_relation.json')) {
        request.response.statusCode = HttpStatus.notFound;
        return;
      }
      request.response.statusCode = HttpStatus.ok;
    });
    await DbConfigService.saveWebdavConfig(
      url: serverUrl(),
      user: 'old@example.com',
      password: 'old-password',
    );

    await WebdavService.registerOrLogin('user@example.com', 'app-password');

    expect(mkcolPaths.any((path) => path.contains('love_app_sync')), isTrue);
    expect(mkcolPaths.any((path) => path.contains('images')), isTrue);
  });

  test('failed image upload does not persist a broken diary image reference',
      () async {
    await startServer((request) async {
      if (request.method == 'PUT' && request.uri.path.contains('/images/')) {
        request.response.statusCode = HttpStatus.notFound;
        return;
      }
      if (request.method == 'PUT' &&
          request.uri.path.contains('diaries.json')) {
        await utf8.decoder.bind(request).join();
        request.response.statusCode = HttpStatus.ok;
        return;
      }
      request.response.statusCode = HttpStatus.ok;
    });
    await DbConfigService.saveWebdavConfig(
      url: serverUrl(),
      user: 'user@example.com',
      password: 'app-password',
    );
    await Hive.box('user').put('current_user', {
      'objectId': 'user-1',
      'couple_id': 'couple-1',
    });

    await WebdavService.saveDiary(
      objectId: 'diary-1',
      content: 'hello',
      mood: 'happy',
      weather: 'sunny',
      tags: const [],
      date: '2026-06-05',
      imageUrl: 'data:image/png;base64,${base64Encode([1, 2, 3])}',
    );

    final list = Hive.box('diaries').get('list') as List<dynamic>;
    expect((list.single as Map)['image_url'], isEmpty);
  });

  test('deleting a wish uploads a tombstone instead of dropping the id',
      () async {
    await startServer((request) async {
      if (request.method == 'PUT' && request.uri.path.contains('wishes.json')) {
        lastJsonPut = {
          'body': jsonDecode(await utf8.decoder.bind(request).join()),
        };
        request.response.statusCode = HttpStatus.ok;
        return;
      }
      request.response.statusCode = HttpStatus.ok;
    });
    await DbConfigService.saveWebdavConfig(
      url: serverUrl(),
      user: 'user@example.com',
      password: 'app-password',
    );
    await Hive.box('wishes').put('list', [
      {
        'objectId': 'wish-1',
        'title': 'old wish',
        'updatedAt': '2026-06-01T00:00:00.000Z',
      }
    ]);

    await WebdavService.deleteWish('wish-1');

    final uploaded = lastJsonPut!['body'] as List<dynamic>;
    expect(
      uploaded,
      contains(
        isA<Map>()
            .having((item) => item['objectId'], 'objectId', 'wish-1')
            .having((item) => item['deleted'], 'deleted', isTrue),
      ),
    );
  });

  test('fetching wishes filters records deleted by remote tombstones',
      () async {
    await startServer((request) {
      if (request.method == 'GET' && request.uri.path.contains('wishes.json')) {
        request.response.statusCode = HttpStatus.ok;
        request.response.write(
          jsonEncode([
            {
              'objectId': 'wish-1',
              'deleted': true,
              'updatedAt': '2026-06-02T00:00:00.000Z',
            }
          ]),
        );
        return;
      }
      request.response.statusCode = HttpStatus.ok;
    });
    await DbConfigService.saveWebdavConfig(
      url: serverUrl(),
      user: 'user@example.com',
      password: 'app-password',
    );
    await Hive.box('wishes').put('list', [
      {
        'objectId': 'wish-1',
        'title': 'old wish',
        'updatedAt': '2026-06-01T00:00:00.000Z',
      }
    ]);

    final wishes = await WebdavService.fetchWishes();

    expect(wishes, isEmpty);
  });

  test('WebDAV location update uploads the current user profile', () async {
    await startServer((request) async {
      if (request.method == 'GET' &&
          request.uri.path.contains('locations.json')) {
        request.response.statusCode = HttpStatus.notFound;
        return;
      }
      if (request.method == 'PUT' &&
          request.uri.path.contains('locations.json')) {
        lastPutPath = request.uri.path;
        lastJsonPut = {
          'body': jsonDecode(await utf8.decoder.bind(request).join()),
        };
        request.response.statusCode = HttpStatus.ok;
        return;
      }
      request.response.statusCode = HttpStatus.ok;
    });
    await DbConfigService.saveWebdavConfig(
      url: serverUrl(),
      user: 'user@example.com',
      password: 'app-password',
    );
    await Hive.box('user').put('current_user', {
      'objectId': 'user-1',
      'username': 'user@example.com',
      'nickname': 'Me',
    });

    await LeanCloudService.updateLocation(25.04, 121.56);

    expect(lastPutPath, contains('locations.json'));
    final uploaded = lastJsonPut!['body'] as List<dynamic>;
    expect(
      uploaded,
      contains(
        isA<Map>()
            .having((item) => item['objectId'], 'objectId', 'user-1')
            .having((item) => item['latitude'], 'latitude', 25.04)
            .having((item) => item['longitude'], 'longitude', 121.56)
            .having(
              (item) => item['location_updated_at'],
              'location_updated_at',
              isNotEmpty,
            ),
      ),
    );
  });

  test('WebDAV partner location is read from the shared locations file',
      () async {
    await startServer((request) {
      if (request.method == 'GET' &&
          request.uri.path.contains('locations.json')) {
        request.response.statusCode = HttpStatus.ok;
        request.response.write(
          jsonEncode([
            {
              'objectId': 'partner-1',
              'nickname': 'Partner',
              'latitude': 25.05,
              'longitude': 121.57,
              'location_updated_at': '2026-06-05T12:00:00.000Z',
              'updatedAt': '2026-06-05T12:00:00.000Z',
            }
          ]),
        );
        return;
      }
      request.response.statusCode = HttpStatus.ok;
    });
    await DbConfigService.saveWebdavConfig(
      url: serverUrl(),
      user: 'user@example.com',
      password: 'app-password',
    );

    final location = await LeanCloudService.fetchPartnerLocation('partner-1');

    expect(location, isNotNull);
    expect(location!['nickname'], 'Partner');
    expect(location['latitude'], 25.05);
    expect(location['longitude'], 121.57);
  });

  test('remote period tombstones hide older local period dates', () async {
    await startServer((request) {
      if (request.method == 'GET' &&
          request.uri.path.contains('period_logs.json')) {
        request.response.statusCode = HttpStatus.ok;
        request.response.write(
          jsonEncode([
            {
              'objectId': '2026-06-05',
              'date': '2026-06-05',
              'deleted': true,
              'updatedAt': '2026-06-06T00:00:00.000Z',
            }
          ]),
        );
        return;
      }
      request.response.statusCode = HttpStatus.ok;
    });
    await DbConfigService.saveWebdavConfig(
      url: serverUrl(),
      user: 'user@example.com',
      password: 'app-password',
    );
    await Hive.box('period_logs').put('list', ['2026-06-05']);

    final dates = await WebdavService.fetchPeriodLogs();

    expect(dates, isEmpty);
    expect(Hive.box('period_logs').get('list'), isEmpty);
  });

  test('removing a period date uploads a tombstone record', () async {
    await startServer((request) async {
      if (request.method == 'PUT' &&
          request.uri.path.contains('period_logs.json')) {
        lastJsonPut = {
          'body': jsonDecode(await utf8.decoder.bind(request).join()),
        };
        request.response.statusCode = HttpStatus.ok;
        return;
      }
      request.response.statusCode = HttpStatus.ok;
    });
    await DbConfigService.saveWebdavConfig(
      url: serverUrl(),
      user: 'user@example.com',
      password: 'app-password',
    );
    await Hive.box('period_logs').put('list', ['2026-06-05']);

    await WebdavService.togglePeriodLog('2026-06-05', false);

    final uploaded = lastJsonPut!['body'] as List<dynamic>;
    expect(
      uploaded,
      contains(
        isA<Map>()
            .having((item) => item['objectId'], 'objectId', '2026-06-05')
            .having((item) => item['date'], 'date', '2026-06-05')
            .having((item) => item['deleted'], 'deleted', isTrue),
      ),
    );
  });
}
