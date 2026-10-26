import 'package:flutter/material.dart';

import 'app.dart';
import 'core/session/mock_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MockSession.load();
  runApp(const EarTrainerApp());
}
