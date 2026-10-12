import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_share_facebook/social_share_facebook.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'platform import exports the public API and routes to its own channel',
    () async {
      const channel = MethodChannel('social_share_facebook');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => {'state': 0, 'msg': 'success'},
      );
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      expect(
        await FlutterShare.share(
          ShareModel(
            platform: SharePlatform.Facebook,
            text: 'https://example.com',
          ),
        ),
        {'state': 0, 'msg': 'success'},
      );
    },
  );
}
