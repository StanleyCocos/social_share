import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_share_core/social_share_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const facebook = MethodChannel('social_share_facebook');
  const line = MethodChannel('social_share_line');

  tearDown(() {
    messenger.setMockMethodCallHandler(facebook, null);
    messenger.setMockMethodCallHandler(line, null);
  });

  for (final platform in SharePlatform.values) {
    final channel = platform == SharePlatform.Facebook ? facebook : line;
    for (final payload in [
      ('hello & #中文', ''),
      ('https://example.com/?a=1&b=中文#anchor', ''),
      ('', 'https://example.com/image.webp'),
      ('', '/cache/local image.jpg'),
      ('text takes priority', '/cache/photo.jpg'),
      ('', ''),
    ]) {
      test('$platform preserves text/image payload $payload', () async {
        MethodCall? received;
        messenger.setMockMethodCallHandler(channel, (call) async {
          received = call;
          return {'state': 0, 'msg': 'success'};
        });
        final response = await FlutterShare.share(
          ShareModel(platform: platform, text: payload.$1, image: payload.$2),
        );
        expect(received!.method, 'share');
        expect(received!.arguments, {
          'platform': platform.toString(),
          'text': payload.$1,
          'image': payload.$2,
        });
        expect(response, {'state': 0, 'msg': 'success'});
      });
    }
    for (final state in [0, 1, 2]) {
      test('$platform preserves result state $state and callback', () async {
        messenger.setMockMethodCallHandler(
          channel,
          (_) async => {'state': state, 'msg': 'native message'},
        );
        int? callbackState;
        String? callbackMessage;
        final response = await FlutterShare.share(
          ShareModel(platform: platform),
          result: (value, message) {
            callbackState = value;
            callbackMessage = message;
          },
        );
        expect(response, {'state': state, 'msg': 'native message'});
        expect(callbackState, state);
        expect(callbackMessage, 'native message');
      });
    }
  }
  test(
    'omitted platform preserves the iOS LINE dispatch payload',
    () async {
      messenger.setMockMethodCallHandler(line, (call) async {
        expect(call.arguments, {
          'platform': 'null',
          'text': 'hello',
          'image': '',
        });
        return {'state': 0, 'msg': ''};
      });
      expect(await FlutterShare.share(ShareModel(text: 'hello')), {
        'state': 0,
        'msg': '',
      });
    },
  );
  test(
    'LINE-only integration can read the iOS platform version',
    () async {
      messenger.setMockMethodCallHandler(line, (call) async {
        expect(call.method, 'getPlatformVersion');
        return 'iOS 15.6';
      });
      expect(await FlutterShare.platformVersion, 'iOS 15.6');
    },
  );
  test('platform version preserves the public getter', () async {
    messenger.setMockMethodCallHandler(facebook, (call) async {
      expect(call.method, 'getPlatformVersion');
      return 'iOS 15.6';
    });
    expect(await FlutterShare.platformVersion, 'iOS 15.6');
  });
}
