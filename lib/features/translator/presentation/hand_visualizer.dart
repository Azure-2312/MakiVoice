import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../domain/app_state.dart';

class HandVisualizer extends StatelessWidget {
  final AppState appState;

  const HandVisualizer({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceLight, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ESTADO DE SENSORES',
                style: TextStyle(
                  color: AppColors.textSecond,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                )),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: appState.isListening
                      ? AppColors.accent.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.radio_button_checked,
                      size: 8,
                      color: appState.isListening
                          ? AppColors.accent
                          : AppColors.textSecond,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      appState.isListening ? 'LETRANDO' : 'LISTO',
                      style: TextStyle(
                        color: appState.isListening
                            ? AppColors.accent
                            : AppColors.textSecond,
                        fontSize: 9,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Visualizador de flexión de dedos
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _FingerColumn(index: 0, label: 'Pulgar', fingerHeight: 60, appState: appState),
              const SizedBox(width: 10),
              _FingerColumn(index: 1, label: 'Índice', fingerHeight: 90, appState: appState),
              const SizedBox(width: 10),
              _FingerColumn(index: 2, label: 'Medio', fingerHeight: 100, appState: appState),
              const SizedBox(width: 10),
              _FingerColumn(index: 3, label: 'Anular', fingerHeight: 88, appState: appState),
              const SizedBox(width: 10),
              _FingerColumn(index: 4, label: 'Meñique', fingerHeight: 70, appState: appState),
            ],
          ),
          const SizedBox(height: 16),

          // Base de la Palma
          Container(
            width: 220,
            height: 15,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 16),

          // Monitor de orientación (Acelerómetro MPU6050)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAxisMonitor('Acc X', appState.accelX),
                _buildAxisMonitor('Acc Y', appState.accelY),
                _buildAxisMonitor('Acc Z', appState.accelZ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAxisMonitor(String axis, double val) {
    return Column(
      children: [
        Text(axis, style: const TextStyle(fontSize: 9, color: AppColors.textSecond)),
        const SizedBox(height: 2),
        Text(val.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'monospace',
            )),
      ],
    );
  }
}

class _FingerColumn extends StatelessWidget {
  final int index;
  final String label;
  final double fingerHeight;
  final AppState appState;

  const _FingerColumn({
    required this.index,
    required this.label,
    required this.fingerHeight,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    final fingerState = appState.fingerPattern[index];
    final bool isActive = (fingerState >= 1);
    
    // Calcular porcentaje de flexión en base a los valores del perfil
    final minVal = appState.currentProfile?.flexMin[index] ?? 1200;
    final maxVal = appState.currentProfile?.flexMax[index] ?? 4000;
    final rawVal = appState.rawFlexValues[index];
    
    double percent = 0.0;
    if (maxVal != minVal) {
      percent = (((rawVal - minVal) / (maxVal - minVal)) * 100).clamp(0.0, 100.0);
    }

    // Color correspondiente al estado actual del dedo
    final Color stateColor = fingerState == 2
        ? AppColors.accent
        : (fingerState == 1
            ? const Color(0xFFFFB300) // Ámbar/Naranja para Semicerrado
            : AppColors.textSecond);

    return Column(
      children: [
        // Indicador de doblado (0 = Abierto, 1 = Semicerrado, 2 = Cerrado)
        Text(
          '$fingerState',
          style: TextStyle(
            color: stateColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        
        // Barra de flexión
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 28,
              height: fingerHeight,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 28,
              height: (percent / 100) * fingerHeight,
              decoration: BoxDecoration(
                color: fingerState == 2
                    ? AppColors.accent
                    : (fingerState == 1
                        ? const Color(0xFFFFB300)
                        : AppColors.accent.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: (fingerState == 2 ? AppColors.accent : const Color(0xFFFFB300)).withOpacity(0.3),
                          blurRadius: 8,
                        )
                      ]
                    : [],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        
        // Etiqueta del dedo
        Text(
          label.substring(0, 3),
          style: const TextStyle(fontSize: 8, color: AppColors.textSecond),
        ),
        
        // Lectura analógica raw
        Text(
          '$rawVal',
          style: const TextStyle(fontSize: 8, color: AppColors.textSecond, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}
