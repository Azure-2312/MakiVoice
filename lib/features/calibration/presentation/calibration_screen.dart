import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as flutter_services;
import '../../../core/app_colors.dart';
import '../../translator/domain/app_state.dart';

class CalibrationScreen extends StatefulWidget {
  final AppState appState;

  const CalibrationScreen({super.key, required this.appState});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  @override
  Widget build(BuildContext context) {
    final state = widget.appState;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── SECCIÓN: CALIBRACIÓN DE UMBRALES ────────────────────────────────
          const Text('CALIBRACIÓN DEL GUANTE',
              style: TextStyle(
                color: AppColors.textSecond,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!state.isCalibrating) ...[
                  const Icon(Icons.tune_outlined, color: AppColors.textSecond, size: 44),
                  const SizedBox(height: 12),
                  const Text(
                    'Calibrar Sensores Flex',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cada mano tiene dimensiones distintas. Calibra el guante para ajustar los umbrales de flexión de tus dedos de forma precisa.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecond, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: state.connectionStatus == AppConnectionStatus.connected
                        ? state.startCalibration
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('INICIAR CALIBRACIÓN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                  if (state.connectionStatus != AppConnectionStatus.connected) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Debes conectar el guante por Bluetooth primero para recibir los valores analógicos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: AppColors.error),
                    ),
                  ],
                ] else ...[
                  // Flujo activo de calibración
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${state.calibrationStep + 1}',
                            style: const TextStyle(color: AppColors.background, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.calibrationStep == 0
                            ? 'Paso 1 de 7: Mano Abierta'
                            : (state.calibrationStep == 1
                                ? 'Paso 2 de 7: Puño Cerrado'
                                : (state.calibrationStep == 2
                                    ? 'Paso 3 de 7: Dedos apuntando arriba'
                                    : (state.calibrationStep == 3
                                        ? 'Paso 4 de 7: Dedos apuntando abajo'
                                        : (state.calibrationStep == 4
                                            ? 'Paso 5 de 7: Mover Arriba-Abajo'
                                            : (state.calibrationStep == 5
                                                ? 'Paso 6 de 7: Mover Izquierda-Derecha'
                                                : 'Paso 7 de 7: Mover Adelante-Atrás'))))),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.calibrationStep == 0
                        ? 'Estira completamente la mano con el guante puesto y mantén la posición firme.'
                        : (state.calibrationStep == 1
                            ? 'Cierra la mano formando un puño bien apretado para registrar la flexión máxima.'
                            : (state.calibrationStep == 2
                                ? 'Apunta tus dedos hacia arriba, moviendo solo la mano (no el brazo), y mantén la posición firme.'
                                : (state.calibrationStep == 3
                                    ? 'Apunta tus dedos hacia abajo, moviendo solo la mano (no el brazo), y mantén la posición firme.'
                                    : (state.calibrationStep == 4
                                        ? 'Mueve la mano de arriba a abajo continuamente durante 3 segundos. Haz clic abajo para iniciar.'
                                        : (state.calibrationStep == 5
                                            ? 'Mueve la mano de izquierda a derecha continuamente durante 3 segundos. Haz clic abajo para iniciar.'
                                            : 'Mueve la mano de adelante hacia atrás continuamente durante 3 segundos. Haz clic abajo para iniciar.'))))),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  
                  // Valores en tiempo real detectados
                  const Text(
                    'Valores ADC actuales capturados:',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecond),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(5, (i) {
                      return Column(
                        children: [
                          Text('D$i', style: const TextStyle(fontSize: 10, color: AppColors.textSecond)),
                          Text(
                            '${state.rawFlexValues[i]}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace', color: AppColors.textPrimary),
                          ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final text = "Flex: ${state.rawFlexValues.join(', ')} | Accel: ${state.accelX.toStringAsFixed(2)}, ${state.accelY.toStringAsFixed(2)}, ${state.accelZ.toStringAsFixed(2)} | Gyro: ${state.gyroX.toStringAsFixed(2)}, ${state.gyroY.toStringAsFixed(2)}, ${state.gyroZ.toStringAsFixed(2)}";
                        flutter_services.Clipboard.setData(flutter_services.ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('¡Lecturas de los sensores copiadas al portapapeles!')),
                        );
                      },
                      icon: const Icon(Icons.copy_all, size: 16, color: AppColors.accent),
                      label: const Text('COPIAR TRAMA DE SENSORES', style: TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.accent),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: state.isRecordingMovement ? null : state.cancelCalibration,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.surfaceLight),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('CANCELAR', style: TextStyle(color: AppColors.textSecond, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: state.calibrationStep >= 4
                            ? ElevatedButton(
                                onPressed: state.isRecordingMovement ? null : state.startMovementRecording,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: AppColors.background,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  state.isRecordingMovement
                                      ? 'GRABANDO (${state.recordingCountdownSeconds}s)'
                                      : 'INICIAR LECTURA',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              )
                            : ElevatedButton(
                                onPressed: state.recordCalibrationStep,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: AppColors.background,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  state.calibrationStep == 0
                                      ? 'REGISTRAR MIN'
                                      : (state.calibrationStep == 1
                                          ? 'REGISTRAR MAX'
                                          : (state.calibrationStep == 2
                                              ? 'REGISTRAR ARRIBA'
                                              : 'REGISTRAR ABAJO')),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
