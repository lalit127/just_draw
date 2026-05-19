import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/gemini_service.dart';
import '../models/blueprint_result.dart';

// ─── Service provider ───────────────────────────────────────────────────────

final apiKeyProvider = Provider<String>((ref) {
  return dotenv.env['GEMINI_API_KEY'] ?? '';
});

final geminiServiceProvider = Provider<GeminiService>((ref) {
  final key = ref.watch(apiKeyProvider);
  return GeminiService(apiKey: key);
});

// ─── Generation state ────────────────────────────────────────────────────────

enum GenerationStep { idle, analysing, generating, done, error }

class BlueprintState {
  final File? sketchFile;
  final BlueprintAnalysis? analysis;
  final Uint8List? blueprintImageBytes;
  final GenerationStep step;
  final String? errorMessage;

  const BlueprintState({
    this.sketchFile,
    this.analysis,
    this.blueprintImageBytes,
    this.step = GenerationStep.idle,
    this.errorMessage,
  });

  BlueprintState copyWith({
    File? sketchFile,
    BlueprintAnalysis? analysis,
    Uint8List? blueprintImageBytes,
    GenerationStep? step,
    String? errorMessage,
    bool clearError = false,
  }) => BlueprintState(
    sketchFile: sketchFile ?? this.sketchFile,
    analysis: analysis ?? this.analysis,
    blueprintImageBytes: blueprintImageBytes ?? this.blueprintImageBytes,
    step: step ?? this.step,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );

  bool get isLoading =>
      step == GenerationStep.analysing || step == GenerationStep.generating;
  bool get isDone => step == GenerationStep.done;
  bool get hasError => step == GenerationStep.error;

  String get stepLabel {
    switch (step) {
      case GenerationStep.analysing:
        return 'Analysing your sketch…';
      case GenerationStep.generating:
        return 'Generating blueprint…';
      case GenerationStep.done:
        return 'Blueprint ready!';
      case GenerationStep.error:
        return 'Something went wrong';
      default:
        return '';
    }
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class BlueprintNotifier extends StateNotifier<BlueprintState> {
  BlueprintNotifier(this._service) : super(const BlueprintState());

  final GeminiService _service;

  void setSketch(File file) {
    state = BlueprintState(sketchFile: file, step: GenerationStep.idle);
  }

  void reset() {
    state = const BlueprintState();
  }

  Future<void> generate() async {
    final sketch = state.sketchFile;
    if (sketch == null) return;

    // Step 1 — Analyse
    state = state.copyWith(step: GenerationStep.analysing, clearError: true);
    try {
      final analysis = await _service.analyseSketch(sketch);
      state = state.copyWith(analysis: analysis);

      // Step 2 — Generate image
      state = state.copyWith(step: GenerationStep.generating);
      final imageBytes = await _service.generateBlueprintImage(
        analysis.blueprintPrompt,
      );

      state = state.copyWith(
        blueprintImageBytes: imageBytes,
        step: GenerationStep.done,
      );
    } catch (e) {
      state = state.copyWith(
        step: GenerationStep.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final blueprintProvider =
    StateNotifierProvider<BlueprintNotifier, BlueprintState>((ref) {
      return BlueprintNotifier(ref.watch(geminiServiceProvider));
    });
