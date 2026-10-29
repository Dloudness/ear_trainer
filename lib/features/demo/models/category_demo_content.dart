import '../../onboarding/models/onboarding_option.dart';

class CategoryDemoContent {
  const CategoryDemoContent({
    required this.introTitle,
    required this.introSubtitle,
    required this.listenHint,
    required this.optionALabel,
    required this.optionBLabel,
    required this.question,
    required this.correctOption,
    required this.feedbackTitle,
    required this.feedbackBody,
    required this.feedbackIncorrectBody,
    this.chooseALabel,
    this.chooseBLabel,
    this.singleListen = false,
    this.audioAssetA,
    this.audioAssetB,
    this.videoAsset,
  });

  final String introTitle;
  final String introSubtitle;
  final String listenHint;
  final String optionALabel;
  final String optionBLabel;
  final String question;
  final String correctOption;
  final String feedbackTitle;
  final String feedbackBody;
  final String feedbackIncorrectBody;
  final String? chooseALabel;
  final String? chooseBLabel;
  final bool singleListen;
  final String? audioAssetA;
  final String? audioAssetB;
  final String? videoAsset;

  String get choiceA => chooseALabel ?? optionALabel;
  String get choiceB => chooseBLabel ?? optionBLabel;

  String get correctChoiceLabel =>
      correctOption == 'A' ? choiceA : choiceB;

  static CategoryDemoContent forCategory(OnboardingOption category) {
    return switch (category) {
      OnboardingOption.ecualizacionFrecuencias =>
        throw UnsupportedError(
          'Use ExerciseRepository for ecualizacionFrecuencias.',
        ),
      OnboardingOption.dinamicaCompresion => const CategoryDemoContent(
            introTitle: 'Escucha atentamente.',
            introSubtitle: 'Siente la diferencia entre dinámica natural y comprimida.',
            listenHint: 'Compara el punch y la respuesta de cada audio.',
            optionALabel: 'AUDIO A',
            optionBLabel: 'AUDIO B',
            question: '¿Cuál audio suena demasiado comprimido?',
            correctOption: 'B',
            feedbackTitle: 'Buen oído.',
            feedbackBody:
                'El segundo audio pierde transientes y suena más plano y controlado.',
            feedbackIncorrectBody:
                'Compara la respuesta dinámica — el audio B suena más comprimido.',
          ),
      OnboardingOption.entrenamientoMusical =>
        throw UnsupportedError(
          'Use MusicalExerciseScreen for entrenamientoMusical.',
        ),
      OnboardingOption.escuchaReal =>
        throw UnsupportedError(
          'Use EscuchaRealExercises.toDemoContent for escuchaReal.',
        ),
    };
  }
}
