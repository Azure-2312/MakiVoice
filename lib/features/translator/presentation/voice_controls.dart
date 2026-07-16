import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../domain/app_state.dart';

class VoiceControls extends StatelessWidget {
  final AppState appState;

  const VoiceControls({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CONTROL DE SÍNTESIS DE VOZ',
                style: TextStyle(
                  color: AppColors.textSecond,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                )),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.settings, color: AppColors.accent, size: 20),
                onPressed: () => _showSettingsDialog(context),
                tooltip: 'Configuración de Lectura',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (appState.translatedText.isNotEmpty) {
                      appState.speakAllText();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: appState.isSpeaking
                          ? AppColors.accent
                          : AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          appState.isSpeaking
                              ? Icons.volume_up
                              : Icons.play_arrow_rounded,
                          color: appState.isSpeaking
                              ? AppColors.background
                              : AppColors.accent,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          appState.isSpeaking
                              ? 'LEYENDO FRASE...'
                              : 'LEER TEXTO',
                          style: TextStyle(
                            color: appState.isSpeaking
                                ? AppColors.background
                                : AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: appState.stopSpeaking,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.error.withOpacity(0.4), width: 1),
                  ),
                  child: const Icon(Icons.stop_rounded,
                      color: AppColors.error, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xD8FFFFFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.settings, color: AppColors.accent),
              SizedBox(width: 10),
              Text(
                'Configuración de Voz',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: ListenableBuilder(
            listenable: appState,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Interruptor Auto-lectura
                  GestureDetector(
                    onTap: appState.toggleAutoSpeak,
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 24,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: appState.autoSpeak
                                ? AppColors.accent
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: appState.autoSpeak
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: appState.autoSpeak
                                    ? AppColors.background
                                    : AppColors.textSecond,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Auto-lectura instantánea',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                )),
                              Text('Pronunciación automática de la traducción',
                                style: TextStyle(
                                  color: AppColors.textSecond,
                                  fontSize: 10,
                                )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Selector de modo de voz (letras vs palabras)
                  if (appState.autoSpeak) ...[
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.surfaceLight, height: 1),
                    const SizedBox(height: 12),
                    const Text('MODO DE LECTURA',
                      style: TextStyle(
                        color: AppColors.textSecond,
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      )),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => appState.setAutoSpeakMode(AutoSpeakMode.letter),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: appState.autoSpeakMode == AutoSpeakMode.letter
                                    ? AppColors.accent.withOpacity(0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: appState.autoSpeakMode == AutoSpeakMode.letter
                                      ? AppColors.accent
                                      : AppColors.surfaceLight,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Letra por Letra',
                                  style: TextStyle(
                                    color: appState.autoSpeakMode == AutoSpeakMode.letter
                                        ? AppColors.accent
                                        : AppColors.textSecond,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => appState.setAutoSpeakMode(AutoSpeakMode.word),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: appState.autoSpeakMode == AutoSpeakMode.word
                                    ? AppColors.accent.withOpacity(0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: appState.autoSpeakMode == AutoSpeakMode.word
                                      ? AppColors.accent
                                      : AppColors.surfaceLight,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Palabra Completa',
                                  style: TextStyle(
                                    color: appState.autoSpeakMode == AutoSpeakMode.word
                                        ? AppColors.accent
                                        : AppColors.textSecond,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.surfaceLight, height: 1),
                  const SizedBox(height: 16),
                  
                  // Modo Repite Tú
                  GestureDetector(
                    onTap: appState.toggleRepeatAfterMe,
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 24,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: appState.repeatAfterMeMode
                                ? AppColors.accent
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: appState.repeatAfterMeMode
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: appState.repeatAfterMeMode
                                    ? AppColors.background
                                    : AppColors.textSecond,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Modo "Repite tú": Imitar señas',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                )),
                              Text('Muestra visualmente cómo hacer la seña de la letra detectada',
                                style: TextStyle(
                                  color: AppColors.textSecond,
                                  fontSize: 10,
                                )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'CERRAR',
                style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}

