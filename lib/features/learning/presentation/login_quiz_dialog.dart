import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../core/constants.dart';
import '../../translator/domain/app_state.dart';
import 'learning_screen.dart'; // Para reutilizar QuizQuestion

class LoginQuizDialog extends StatefulWidget {
  final AppState appState;

  const LoginQuizDialog({super.key, required this.appState});

  static void show(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoginQuizDialog(appState: appState),
    );
  }

  @override
  State<LoginQuizDialog> createState() => _LoginQuizDialogState();
}

class _LoginQuizDialogState extends State<LoginQuizDialog> {
  final List<QuizQuestion> _questions = [];
  final List<int> _selectedIndices = [];
  int _currentIdx = 0;
  int _score = 0;
  bool _initialized = false;
  bool _resultSaved = false;

  @override
  void initState() {
    super.initState();
    _generateQuizQuestions();
  }

  void _generateQuizQuestions() {
    final allLetters = AppConstants.lspDescriptions.keys.toList();
    final List<String> shuffledLetters = List<String>.from(allLetters)..shuffle();

    for (int i = 0; i < min(5, shuffledLetters.length); i++) {
      final String correctLetter = shuffledLetters[i];
      
      final List<String> falseOptions = allLetters
          .where((letter) => letter != correctLetter)
          .toList();
      falseOptions.shuffle();

      final options = [correctLetter, falseOptions[0], falseOptions[1], falseOptions[2]];
      options.shuffle();

      _questions.add(QuizQuestion(
        imageName: correctLetter == 'Ñ' ? 'N_tilde' : correctLetter,
        questionText: '¿Qué letra representa esta seña del guante?',
        options: options,
        correctIndex: options.indexOf(correctLetter),
      ));
    }
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox.shrink();

    final isFinished = _currentIdx >= _questions.length;

    if (isFinished) {
      final approved = _score >= 3;

      if (!_resultSaved) {
        _resultSaved = true;
        final List<Map<String, dynamic>> details = [];
        for (int i = 0; i < _questions.length; i++) {
          final q = _questions[i];
          details.add({
            'questionText': q.questionText,
            'imageName': q.imageName,
            'options': q.options,
            'correctIndex': q.correctIndex,
            'selectedIndex': _selectedIndices[i],
          });
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.appState.saveQuizResult(_score, details);
        });
      }

      return AlertDialog(
        backgroundColor: const Color(0xD8FFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Quiz Diario de Bienvenida',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              approved ? Icons.local_fire_department : Icons.sentiment_neutral_outlined,
              color: approved ? AppColors.accentDim : AppColors.disconnected,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              approved ? '¡Excelente Racha! 🔥' : 'Sigue practicando',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: approved ? AppColors.accentDim : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Puntuación final: $_score de ${_questions.length} correctas.',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              approved
                  ? '¡Tu racha diaria ha aumentado en 1 día! Sigue así para no perder tu fueguito.'
                  : 'Necesitas al menos 3 de 5 respuestas correctas para aumentar tu racha diaria.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecond, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('EMPEZAR A TRADUCIR', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }

    final currentQuestion = _questions[_currentIdx];

    return AlertDialog(
      backgroundColor: const Color(0xD8FFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Quiz de Entrada',
            style: TextStyle(fontSize: 14, color: AppColors.textSecond, fontWeight: FontWeight.bold),
          ),
          Text(
            'Pregunta ${_currentIdx + 1} de ${_questions.length}',
            style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (currentQuestion.imageName.isNotEmpty) ...[
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/${currentQuestion.imageName}.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.image_not_supported_outlined, size: 36, color: AppColors.textSecond),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            currentQuestion.questionText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 18),
          ...List.generate(currentQuestion.options.length, (optIdx) {
            final option = currentQuestion.options[optIdx];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedIndices.add(optIdx);
                    if (optIdx == currentQuestion.correctIndex) {
                      _score++;
                    }
                    _currentIdx++;
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.surfaceLight),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  option,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
