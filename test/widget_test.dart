import 'package:flutter_test/flutter_test.dart';

import 'package:ear_trainer/app.dart';

void main() {
  testWidgets('App launches splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const EarTrainerApp());
    expect(find.text('EAR TRAINER'), findsOneWidget);
  });
}
