import 'package:flutter_test/flutter_test.dart';

import 'package:cloudparty/main.dart';

void main() {
  testWidgets('App renders CloudParty shell', (WidgetTester tester) async {
    await tester.pumpWidget(const CloudPartyApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('CloudParty'), findsOneWidget);
  });
}
