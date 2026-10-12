import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_share_example/main.dart';

void main() {
  testWidgets('example exposes both sharing platforms', (tester) async {
    await tester.pumpWidget(const ShareExampleApp());
    expect(find.text('Facebook'), findsOneWidget);
    expect(find.text('Line'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('分享单图'), findsNWidgets(2));
  });
}
