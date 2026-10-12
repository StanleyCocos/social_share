import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_share_line/social_share_line.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'platform import exports the legacy API and routes to its own channel',
    () async {
      const channel = MethodChannel('social_share_line');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => {'state': 0, 'msg': 'success'},
      );
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      expect(
        await FlutterShare.share(
          ShareModel(platform: SharePlatform.Line, text: 'https://example.com'),
        ),
        {'state': 0, 'msg': 'success'},
      );
    },
  );
}
