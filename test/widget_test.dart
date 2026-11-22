import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ear_trainer/app.dart';

void main() {
  testWidgets('App launches splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const EarTrainerApp());
    expect(find.text('EAR TRAINER'), findsOneWidget);

    // La splash programa un salto a la bienvenida a los 2,2 s. Quitamos la app
    // y dejamos pasar ese tiempo para que el temporizador termine sin navegar.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}
