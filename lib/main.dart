import 'package:flutter/material.dart';

import 'app.dart';
import 'core/session/mock_session.dart';
import 'features/exercises/data/exercise_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MockSession.load();
  await ExerciseRepository.instance.load();
  runApp(const EarTrainerApp());
}
