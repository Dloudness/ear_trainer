import '../../features/home/data/home_mock_data.dart';
import '../../features/home/models/training_module.dart';
import '../../features/modules/models/module_exercise_catalog.dart';
import '../../features/onboarding/models/onboarding_option.dart';
import '../router/app_routes.dart';
import '../storage/progress_repository.dart';

class ContinueTrainingInfo {
  const ContinueTrainingInfo({
    required this.title,
    required this.route,
    required this.accuracyPercent,
    required this.completedCount,
    required this.totalCount,
    required this.hasHistory,
  });

  final String title;
  final String route;
  final int accuracyPercent;
  final int completedCount;
  final int totalCount;
  final bool hasHistory;
}

/// Session state — auth flags stay in memory; progress is persisted locally.
class MockSession {
  MockSession._();

  static final ProgressRepository _progressRepository = ProgressRepository();
  static ProgressSnapshot _progress = const ProgressSnapshot();

  static bool isLoggedIn = false;
  static bool isGuest = false;
  static bool hasCompletedDemo = false;
  static bool hasUsedFreeDailyChallenge = false;
  static bool showLoginPromptAfterChallenge = false;
  static String? trainingFocus;
  static String displayName = 'Diego';

  static bool loginPromptDismissed = false;

  static int get streakDays => _progress.streakDays;
  static int get xp => _progress.xp;
  static List<CompletedExerciseRecord> get completedExercises =>
      List.unmodifiable(_progress.exercises);

  static int get completedExerciseCount => _progress.exercises.length;

  static int get globalAccuracyPercent =>
      _accuracyPercent(_progress.exercises);

  static int get achievements => completedExerciseCount;

  static int get trainingConsistency => globalAccuracyPercent;

  static ContinueTrainingInfo get continueTraining {
    final last = _latestExercise;
    if (last == null) {
      final route = _routeForFocus() ?? AppRoutes.moduleFrecuencias;
      final moduleId = _moduleIdForRoute(route) ?? 'frecuencias';
      return ContinueTrainingInfo(
        title: 'Empieza tu primer ejercicio',
        route: route,
        accuracyPercent: 0,
        completedCount: 0,
        totalCount: _totalExercisesForModule(moduleId),
        hasHistory: false,
      );
    }

    final moduleId = moduleIdForExercise(last.id);
    final module = HomeMockData.moduleById(moduleId);
    final records = _exercisesForModule(moduleId);
    final catalogTotal = _totalExercisesForModule(moduleId);

    return ContinueTrainingInfo(
      title: module?.title ?? 'Entrenamiento',
      route: module?.route ?? AppRoutes.moduleFrecuencias,
      accuracyPercent: _accuracyPercent(records),
      completedCount: records.length,
      totalCount: catalogTotal == 0 ? records.length : catalogTotal,
      hasHistory: true,
    );
  }

  static String get continueModuleTitle => continueTraining.title;

  static int get continueAccuracy => continueTraining.accuracyPercent;

  static List<TrainingModule> get homeModules {
    return HomeMockData.carouselModules
        .map(
          (module) => module.copyWith(
            progress: accuracyForModule(module.id) / 100,
          ),
        )
        .toList();
  }

  static int accuracyForModule(String moduleId) {
    return _accuracyPercent(_exercisesForModule(moduleId));
  }

  static String moduleIdForExercise(String exerciseId) {
    if (exerciseId.startsWith('EQ_') ||
        exerciseId.startsWith('ecualizacion')) {
      return 'frecuencias';
    }
    if (exerciseId.startsWith('REAL_') || exerciseId.startsWith('escucha')) {
      return 'escucha_real';
    }
    if (exerciseId.startsWith('DYN_') || exerciseId.startsWith('dinamica')) {
      return 'dinamica';
    }
    if (exerciseId.startsWith('MUS_') ||
        exerciseId.startsWith('chord_') ||
        exerciseId.startsWith('interval_') ||
        exerciseId.startsWith('entrenamiento')) {
      return 'entrenamiento_musical';
    }
    return 'frecuencias';
  }

  static bool get isLightMode => hasCompletedDemo && !isLoggedIn;
  static bool get hasFullAccess => isLoggedIn;
  static bool get hasEnteredHub => hasCompletedDemo;

  static bool get canAttemptDailyChallenge =>
      hasFullAccess || !hasUsedFreeDailyChallenge;

  static bool get shouldShowLoginPrompt =>
      isLightMode && showLoginPromptAfterChallenge && !loginPromptDismissed;

  static Future<void> load() async {
    _progress = await _progressRepository.load();
    hasCompletedDemo = _progress.hasCompletedDemo;
    trainingFocus = _progress.trainingFocus;
  }

  static Future<void> recordExerciseResult({
    required String exerciseId,
    required bool correct,
  }) async {
    final now = DateTime.now();
    final records = [..._progress.exercises];
    final index = records.indexWhere((item) => item.id == exerciseId);

    if (index >= 0) {
      final current = records[index];
      records[index] = current.copyWith(
        correct: correct,
        attempts: current.attempts + 1,
        completedAt: now,
      );
    } else {
      records.add(
        CompletedExerciseRecord(
          id: exerciseId,
          correct: correct,
          attempts: 1,
          completedAt: now,
        ),
      );
    }

    _progress = _progress.copyWith(
      exercises: records,
      xp: _progress.xp + (correct ? 50 : 10),
      streakDays: _nextStreakDays(now),
      lastActivityDate: _dateKey(now),
    );
    await _progressRepository.save(_progress);
  }

  static int _nextStreakDays(DateTime now) {
    final today = _dateKey(now);
    final last = _progress.lastActivityDate;
    if (last == today) {
      return _progress.streakDays == 0 ? 1 : _progress.streakDays;
    }

    final yesterday = _dateKey(now.subtract(const Duration(days: 1)));
    if (last == yesterday) return _progress.streakDays + 1;
    return 1;
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static Future<void> completeDemo() async {
    hasCompletedDemo = true;
    _progress = _progress.copyWith(hasCompletedDemo: true);
    await _progressRepository.save(_progress);
  }

  static void completeFreeDailyChallenge() {
    if (isLightMode && !hasUsedFreeDailyChallenge) {
      hasUsedFreeDailyChallenge = true;
      showLoginPromptAfterChallenge = true;
    }
  }

  static void dismissLoginPrompt() {
    loginPromptDismissed = true;
  }

  static void signInAsGuest() {
    isLoggedIn = true;
    isGuest = true;
    loginPromptDismissed = true;
    showLoginPromptAfterChallenge = false;
  }

  static void signIn() {
    isLoggedIn = true;
    isGuest = false;
    loginPromptDismissed = true;
    showLoginPromptAfterChallenge = false;
  }

  static Future<void> setTrainingFocus(String focus) async {
    trainingFocus = focus;
    _progress = _progress.copyWith(trainingFocus: focus);
    await _progressRepository.save(_progress);
  }

  static CompletedExerciseRecord? get _latestExercise {
    if (_progress.exercises.isEmpty) return null;
    final sorted = [..._progress.exercises]
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return sorted.first;
  }

  static List<CompletedExerciseRecord> _exercisesForModule(String moduleId) {
    return _progress.exercises
        .where((item) => moduleIdForExercise(item.id) == moduleId)
        .toList();
  }

  static int _accuracyPercent(List<CompletedExerciseRecord> records) {
    if (records.isEmpty) return 0;
    final correct = records.where((item) => item.correct).length;
    return ((correct / records.length) * 100).round();
  }

  static int _totalExercisesForModule(String moduleId) {
    final category = switch (moduleId) {
      'frecuencias' => OnboardingOption.ecualizacionFrecuencias,
      'dinamica' => OnboardingOption.dinamicaCompresion,
      'escucha_real' => OnboardingOption.escuchaReal,
      'entrenamiento_musical' => OnboardingOption.entrenamientoMusical,
      _ => null,
    };
    if (category == null) return 0;
    return ModuleExerciseCatalog.forCategory(category).length;
  }

  static String? _moduleIdForRoute(String route) {
    for (final module in HomeMockData.carouselModules) {
      if (module.route == route) return module.id;
    }
    return null;
  }

  static String? _routeForFocus() {
    final focus = trainingFocus?.toLowerCase() ?? '';
    if (focus.contains('ecualiz') || focus.contains('frecuen')) {
      return AppRoutes.moduleFrecuencias;
    }
    if (focus.contains('dinám') || focus.contains('dinam')) {
      return AppRoutes.moduleDinamica;
    }
    if (focus.contains('musical')) {
      return AppRoutes.moduleMusical;
    }
    if (focus.contains('escucha')) {
      return AppRoutes.moduleEscuchaReal;
    }
    return null;
  }
}
