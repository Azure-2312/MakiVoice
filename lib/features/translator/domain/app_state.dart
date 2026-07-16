import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/services/bluetooth_service.dart';
import '../../../core/services/nlp_engine.dart';
import '../../../core/services/tts_service.dart';
import '../../profile/domain/profile.dart';
import '../../../main.dart'; // Import para navigatorKey

enum AppConnectionStatus { disconnected, scanning, connected }
enum AutoSpeakMode { letter, word }

class AppState extends ChangeNotifier {
  final GloveBluetoothService _bluetoothService = GloveBluetoothService();
  final TtsService _ttsService = TtsService();
  final NlpEngine _nlpEngine = NlpEngine();

  // Umbrales de calibración por dedo (actualizables vía CALIBRAR/Perfil)
  int umbralThumb = 1845;
  int umbralIndex = 1852;
  int umbralMiddle = 1795;
  int umbralRing = 1900;
  int umbralPinky = 1602;

  // Parámetros del doble filtro (mano quieta y estabilidad)
  static const int _bufferSize = 6;
  static const int _umbralQuietud = 150;
  static const int _msEstabilidad = 400;
  static const int _msCooldown = 800;

  final List<List<int>> _bufferFlex = List.generate(5, (_) => List.filled(6, 2048));
  int _bufferIdx = 0;

  String? _patronActual;
  DateTime? _inicioEstabilidad;
  DateTime? _ultimaEmision;
  String _ultimaLetraEmitida = "";
  DateTime? _lastEmissionTime;

  // ── ESTADO DE TRADUCCIÓN ──────────────────────────────────────────────────
  String translatedText = '';
  String currentLetter = '';
  List<int> fingerPattern = [0, 0, 0, 0, 0];
  List<double> flexPercentages = [0.0, 0.0, 0.0, 0.0, 0.0];
  bool isTranslationActive = true;
  String bleConnectionError = '';
  List<int> rawFlexValues = [1200, 1200, 1200, 1200, 1200];
  double accelX = 0, accelY = 0, accelZ = 0;
  double gyroX = 0, gyroY = 0, gyroZ = 0;
  List<List<dynamic>> gloveDataHistory = [];

  // Autocalibración y clasificación local en Dart
  List<int> sessionMinFlex = [2500, 2500, 2500, 2500, 2500];
  List<int> sessionMaxFlex = [1500, 1500, 1500, 1500, 1500];
  String _lastRecognizedLetter = "";
  String _stableLetter = "";
  int _stabilityCount = 0;



  // Estado para la grabación de señas dinámicas
  bool isRecordingDynamicSign = false;
  List<List<dynamic>> tempRecordingSamples = [];
  double recordingProgress = 0.0;
  Timer? _recordingTimer;
  Timer? _progressTimer;
  bool isSpeaking = false;
  bool autoSpeak = true; // Activo por defecto
  AutoSpeakMode autoSpeakMode = AutoSpeakMode.letter; // Por defecto: Letra por letra
  bool isListening = false;
  bool repeatAfterMeMode = true; // Activo por defecto en "repite tú"
  String? repeatMeTargetLetter;
  Timer? _repeatMeTimer;

  // ── ESTADO DE CONEXIÓN BLE ────────────────────────────────────────────────
  AppConnectionStatus connectionStatus = AppConnectionStatus.disconnected;
  String deviceName = '';
  bool hasSearchedOnce = false; // Variable para saber si ya se buscó al menos una vez
  List<BleDeviceModel> scannedDevices = [];
  StreamSubscription? _bleDataSubscription;
  StreamSubscription? _bleLetterSubscription;
  StreamSubscription? _bleScanSubscription;

  // ── GESTIÓN DE PERFILES Y HIVE ────────────────────────────────────────────
  late Box _profilesBox;
  List<UserProfile> profiles = [];
  UserProfile? currentProfile;
  bool isLoggedIn = false;
  bool showLoginQuizPopup = false; // Popup de quiz al iniciar sesión
  bool isCalibrating = false;
  int calibrationStep = 0; // 0=abierta, 1=cerrado, 2=arriba, 3=abajo, 4=arriba-abajo, 5=izq-der, 6=adelante-atras
  double? _tempAccelUp; // Almacenamiento temporal de aceleración hacia arriba
  List<List<int>> tempCalibrationData = [];

  // Variables para la calibración del movimiento dinámico de 3 segundos
  bool isRecordingMovement = false;
  int recordingCountdownSeconds = 3;
  Timer? _calibrationTimer;
  List<List<double>> _tempMovementData = [];
  double _peakGyroUpDown = 0.0;
  double _peakGyroLeftRight = 0.0;
  double _peakGyroFrontBack = 0.0;
  double _peakAccelUpDown = 0.0;
  double _peakAccelLeftRight = 0.0;
  double _peakAccelFrontBack = 0.0;

  // Sugerencias de autocompletado en tiempo real
  List<String> suggestions = [];
  
  // Buffer para palabra actual
  String _currentWordBuffer = '';

  // Inicializar estado, base de datos local y servicios
  Future<void> init() async {
    await Hive.initFlutter();
    _profilesBox = await Hive.openBox('lsp_profiles_box');
    _loadProfiles();
    
    // Sincronizar umbrales del detector de señas
    _updateSenaDetectorThresholds();
    
    // Configurar listener para datos BLE
    _bleDataSubscription = _bluetoothService.dataStream.listen((csvData) {
      if (csvData == "FINISHED_MOCK") {
        stopMockSequence();
        return;
      }
      _processIncomingGloveData(csvData);
    });

    // Configurar listener para letras traducidas en modo simulación
    _bleLetterSubscription = _bluetoothService.letterStream.listen((letter) {
      if (!_bluetoothService.isMocking) return;
      if (letter == "FINISHED_MOCK") {
        return;
      }
      if (letter == "---" || letter.trim().isEmpty || letter == '—') {
        currentLetter = '';
        notifyListeners();
        return;
      }
      if (letter.length == 1) {
        _handleNewCharacter(letter);
      }
    });

    // Configurar listener para escaneo BLE
    _bleScanSubscription = _bluetoothService.scanResultsStream.listen((devices) {
      scannedDevices = devices;
      notifyListeners();
    });

    // Configurar listener para estado de conexión BLE
    _bluetoothService.connectionStateStream.listen((state) {
      if (state == BluetoothConnectionState.disconnected && connectionStatus == AppConnectionStatus.connected) {
        connectionStatus = AppConnectionStatus.disconnected;
        bleConnectionError = 'El guante se ha apagado repentinamente o ha salido del rango.';
        hasSearchedOnce = false;
        notifyListeners();
        
        // Mostrar popup global de error sin importar en qué pantalla estemos
        if (navigatorKey.currentContext != null) {
          showDialog(
            context: navigatorKey.currentContext!,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF2C2F36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                  SizedBox(width: 10),
                  Text('Guante Desconectado', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: const Text(
                'El dispositivo guante-traductor se ha apagado repentinamente o ha perdido la conexión. Por favor, asegúrate de que esté encendido y vuelve a buscarlo.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('ENTENDIDO', style: TextStyle(color: Color(0xFF5A85EE), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _bleDataSubscription?.cancel();
    _bleLetterSubscription?.cancel();
    _bleScanSubscription?.cancel();
    _repeatMeTimer?.cancel();
    _recordingTimer?.cancel();
    _progressTimer?.cancel();
    _bluetoothService.disconnect();
    super.dispose();
  }

  void startRecordingDynamicSign() {
    isRecordingDynamicSign = true;
    tempRecordingSamples = [];
    recordingProgress = 0.0;
    notifyListeners();

    const duration = Duration(seconds: 2);
    const tickInterval = Duration(milliseconds: 50);
    int elapsed = 0;

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(tickInterval, (timer) {
      elapsed += tickInterval.inMilliseconds;
      recordingProgress = (elapsed / duration.inMilliseconds).clamp(0.0, 1.0);
      notifyListeners();
      if (elapsed >= duration.inMilliseconds) {
        timer.cancel();
      }
    });

    _recordingTimer?.cancel();
    _recordingTimer = Timer(duration, () {
      isRecordingDynamicSign = false;
      _progressTimer?.cancel();
      notifyListeners();
    });
  }

  void cancelRecordingDynamicSign() {
    isRecordingDynamicSign = false;
    tempRecordingSamples.clear();
    recordingProgress = 0.0;
    _recordingTimer?.cancel();
    _progressTimer?.cancel();
    notifyListeners();
  }

  // ── MÉTODOS DE PERFIL Y PERSISTENCIA ──────────────────────────────────────
  void _loadProfiles() {
    final List<dynamic>? rawProfiles = _profilesBox.get('profiles');
    if (rawProfiles != null && rawProfiles.isNotEmpty) {
      profiles = rawProfiles
          .map((p) {
            final prof = UserProfile.fromJson(Map<String, dynamic>.from(p as Map));
            if (prof.id == 'test_user') {
              return prof.copyWith(learningLevel: 9);
            }
            return prof;
          })
          .toList();
    } else {
      profiles = [];
    }

    // Asegurarse de que exista el usuario de prueba calibrado
    final hasTestUser = profiles.any((p) => p.id == 'test_user');
    if (!hasTestUser) {
      final testProfile = UserProfile(
        id: 'test_user',
        name: 'TEST',
        password: '123',
        flexMin: [1200, 1200, 1200, 1200, 1200],
        flexMid: [1845, 1852, 1795, 1900, 1602], // Calibrado (valores distintos a 2600)
        flexMax: [4000, 4000, 4000, 4000, 4000],
        frequentWords: ["HOLA", "GRACIAS", "BIEN", "NECESITO", "AYUDA"],
        customSigns: {},
        quizHistory: const [],
        examHistory: const [],
        learningLevel: 9, // Todos los niveles desbloqueados
        quizStreak: 5,
        umbralInclinacion: 2.0,
        umbralMovimientoGyro: 1.2,
        umbralMovimientoAccel: 2.5,
      );
      profiles.add(testProfile);
      _saveProfilesToDisk();
    }

    if (profiles.isNotEmpty) {
      final lastActiveId = _profilesBox.get('active_profile_id') as String?;
      currentProfile = profiles.firstWhere(
        (p) => p.id == lastActiveId,
        orElse: () => profiles.first,
      );
    } else {
      currentProfile = null;
    }
    
    // Cargar diccionarios personalizados del perfil actual
    _updateNlpEngineWithProfile();
    _updateSenaDetectorThresholds();
  }

  void _saveProfilesToDisk() {
    final List<Map<String, dynamic>> raw = profiles.map((p) => p.toJson()).toList();
    _profilesBox.put('profiles', raw);
    if (currentProfile != null) {
      _profilesBox.put('active_profile_id', currentProfile!.id);
    }
  }

  void selectProfile(String id) {
    currentProfile = profiles.firstWhere((p) => p.id == id);
    _saveProfilesToDisk();
    _updateNlpEngineWithProfile();
    _updateSenaDetectorThresholds();
    notifyListeners();
  }

  void login(UserProfile profile) {
    currentProfile = profile;
    isLoggedIn = true;

    // Activar popup del quiz solo si no es usuario nuevo (ya calibró) y no lo ha completado hoy
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final isNewUser = profile.flexMid[0] == 2600;
    if (!isNewUser && profile.lastQuizDate != todayStr) {
      showLoginQuizPopup = true;
    }

    _saveProfilesToDisk();
    _updateNlpEngineWithProfile();
    _updateSenaDetectorThresholds();
    notifyListeners();
  }

  void logout() {
    isLoggedIn = false;
    notifyListeners();
  }

  void createProfile(String name, String password) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newProf = UserProfile.defaultProfile(id, name, password);
    profiles.add(newProf);
    currentProfile = newProf;
    isLoggedIn = true;
    showLoginQuizPopup = false; // No mostrar quiz a usuarios nuevos que no han calibrado

    _saveProfilesToDisk();
    _updateNlpEngineWithProfile();
    _updateSenaDetectorThresholds();
    notifyListeners();
  }

  bool verifyProfilePassword(UserProfile profile, String password) {
    return profile.password == password;
  }

  void saveQuizResult(int score, List<Map<String, dynamic>> details) {
    if (currentProfile == null) return;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    final newHistory = List<Map<String, dynamic>>.from(currentProfile!.quizHistory);
    newHistory.add({
      'date': todayStr,
      'score': score,
      'total': details.length,
      'details': details,
    });

    final approved = score >= 3;
    final newStreak = approved ? currentProfile!.quizStreak + 1 : currentProfile!.quizStreak;

    final updated = currentProfile!.copyWith(
      quizStreak: newStreak,
      lastQuizDate: todayStr,
      quizHistory: newHistory,
    );
    _updateCurrentProfile(updated);
    notifyListeners();
  }

  void saveExamResult(int levelNum, int score, List<Map<String, dynamic>> details) {
    if (currentProfile == null) return;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    final newHistory = List<Map<String, dynamic>>.from(currentProfile!.examHistory);
    newHistory.add({
      'date': todayStr,
      'levelNum': levelNum,
      'score': score,
      'total': details.length,
      'details': details,
    });

    final updated = currentProfile!.copyWith(
      examHistory: newHistory,
    );
    _updateCurrentProfile(updated);
    notifyListeners();
  }

  void deleteProfile(String id) {
    profiles.removeWhere((p) => p.id == id);
    if (currentProfile?.id == id) {
      currentProfile = profiles.isNotEmpty ? profiles.first : null;
      if (currentProfile == null) {
        isLoggedIn = false;
      }
    }
    _saveProfilesToDisk();
    _updateNlpEngineWithProfile();
    notifyListeners();
  }

  void _updateNlpEngineWithProfile() {
    if (currentProfile == null) return;
    _nlpEngine.updateCustomAndFrequentWords(
      currentProfile!.customSigns.keys.toList(),
      currentProfile!.frequentWords,
    );
  }

  // ── FLUJO DE CALIBRACIÓN DE SENSORES ──────────────────────────────────────
  void startCalibration() {
    isCalibrating = true;
    calibrationStep = 0; // Inicia con mano abierta
    tempCalibrationData = [];
    notifyListeners();
  }

  void recordCalibrationStep() {
    if (calibrationStep == 0) {
      // Paso 0: Guardar lecturas para mano abierta (flexMin)
      final minVals = List<int>.from(rawFlexValues);
      final updatedProf = currentProfile!.copyWith(
        flexMin: minVals,
      );
      _updateCurrentProfile(updatedProf);
      calibrationStep = 1; // Avanzar a puño cerrado (Paso 1)
      notifyListeners();
    } else if (calibrationStep == 1) {
      // Paso 1: Guardar lecturas para puño cerrado (flexMax) y calcular flexMid (Umbral)
      final maxVals = List<int>.from(rawFlexValues);
      
      // Calcular flexMid como 1/4 (25%) del recorrido desde Mano Abierta hacia Mano Cerrada
      final minVals = currentProfile!.flexMin; // Mano Abierta
      final List<int> midVals = List.generate(5, (i) {
        final openVal = minVals[i]; // Abierto
        final closedVal = maxVals[i]; // Cerrado
        return (openVal + (closedVal - openVal) * 0.25).round();
      });

      final updatedProf = currentProfile!.copyWith(
        flexMax: maxVals,
        flexMid: midVals,
      );
      _updateCurrentProfile(updatedProf);
      
      calibrationStep = 2; // Avanzar a calibrar orientación Hacia Arriba (Paso 2)
      notifyListeners();
    } else if (calibrationStep == 2) {
      // Paso 2: Guardar aceleración para Mano Hacia Arriba (inicio)
      _tempAccelUp = accelX;
      calibrationStep = 3; // Avanzar a calibrar orientación Hacia Abajo (Paso 3)
      notifyListeners();
    } else {
      // Paso 3: Guardar aceleración para Mano Hacia Abajo (final) y calcular el umbral a 4/6 (66.6%)
      final double accelDown = accelX;
      final double accelUp = _tempAccelUp ?? 9.8;
      
      // Umbral = arriba + (abajo - arriba) * (4/6)
      final double umbralInclinacion = accelUp + (accelDown - accelUp) * (4.0 / 6.0);

      final updatedProf = currentProfile!.copyWith(
        umbralInclinacion: umbralInclinacion,
      );
      _updateCurrentProfile(updatedProf);
      
      calibrationStep = 4; // Avanzar a los pasos de movimiento dinámico
      notifyListeners();
    }
  }

  // Iniciar la grabación del movimiento actual durante 3 segundos
  void startMovementRecording() {
    isRecordingMovement = true;
    recordingCountdownSeconds = 3;
    _tempMovementData = [];
    notifyListeners();

    _calibrationTimer?.cancel();
    _calibrationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      recordingCountdownSeconds--;
      if (recordingCountdownSeconds <= 0) {
        timer.cancel();
        _finishMovementRecording();
      } else {
        notifyListeners();
      }
    });
  }

  // Procesar los picos al finalizar los 3 segundos
  void _finishMovementRecording() {
    isRecordingMovement = false;
    
    double maxGyro = 0.0;
    double maxAccelDelta = 0.0;
    
    if (_tempMovementData.isNotEmpty) {
      for (int i = 0; i < _tempMovementData.length - 1; i++) {
        final current = _tempMovementData[i];
        final next = _tempMovementData[i + 1];
        
        final double gx = next[3];
        final double gy = next[4];
        final double gz = next[5];
        
        final double ax1 = current[0];
        final double ay1 = current[1];
        final double az1 = current[2];
        
        final double ax2 = next[0];
        final double ay2 = next[1];
        final double az2 = next[2];
        
        final double gyroFrame = [gx.abs(), gy.abs(), gz.abs()].reduce(max);
        if (gyroFrame > maxGyro) maxGyro = gyroFrame;
        
        final double accelDelta = [(ax2 - ax1).abs(), (ay2 - ay1).abs(), (az2 - az1).abs()].reduce(max);
        if (accelDelta > maxAccelDelta) maxAccelDelta = accelDelta;
      }
    }
    
    // Guardar picos según el paso dinámico correspondiente
    if (calibrationStep == 4) {
      _peakGyroUpDown = maxGyro;
      _peakAccelUpDown = maxAccelDelta;
      calibrationStep = 5; // Avanzar a Izquierda-Derecha
    } else if (calibrationStep == 5) {
      _peakGyroLeftRight = maxGyro;
      _peakAccelLeftRight = maxAccelDelta;
      calibrationStep = 6; // Avanzar a Adelante-Atrás
    } else if (calibrationStep == 6) {
      _peakGyroFrontBack = maxGyro;
      _peakAccelFrontBack = maxAccelDelta;
      
      // Calcular los umbrales finales a partir de la mitad de los picos grabados
      double maxRecordedGyro = [_peakGyroUpDown, _peakGyroLeftRight, _peakGyroFrontBack].reduce(max);
      double maxRecordedAccel = [_peakAccelUpDown, _peakAccelLeftRight, _peakAccelFrontBack].reduce(max);
      
      double umbralGyro = maxRecordedGyro * (1.0 / 3.0);
      double umbralAccel = maxRecordedAccel * (1.0 / 3.0);
      
      // Clámpar a valores mínimos y máximos lógicos
      umbralGyro = umbralGyro.clamp(0.8, 3.0);
      umbralAccel = umbralAccel.clamp(1.5, 5.0);
      
      final updatedProf = currentProfile!.copyWith(
        umbralMovimientoGyro: umbralGyro,
        umbralMovimientoAccel: umbralAccel,
      );
      _updateCurrentProfile(updatedProf);
      
      calibrationStep = 0; // Resetear
      isCalibrating = false; // Fin de la calibración completa
      notifyListeners();

      // Enviar umbrales de flexores al guante
      final thresholds = updatedProf.flexMid;
      final String calibCommand = "CALIBRAR,${thresholds[0]},${thresholds[1]},${thresholds[2]},${thresholds[3]},${thresholds[4]}";
      sendCommandToGlove(calibCommand);
    }
    notifyListeners();
  }

  void cancelCalibration() {
    isCalibrating = false;
    notifyListeners();
  }

  void _updateCurrentProfile(UserProfile updated) {
    final index = profiles.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      profiles[index] = updated;
      currentProfile = updated;
      _saveProfilesToDisk();
      _updateNlpEngineWithProfile();
      _updateSenaDetectorThresholds();
    }
  }

  void _updateSenaDetectorThresholds() {
    if (currentProfile != null) {
      if (currentProfile!.flexMid[0] != 2600) {
        umbralThumb = currentProfile!.flexMid[0];
        umbralIndex = currentProfile!.flexMid[1];
        umbralMiddle = currentProfile!.flexMid[2];
        umbralRing = currentProfile!.flexMid[3];
        umbralPinky = currentProfile!.flexMid[4];
        debugPrint("[Detector] Umbrales actualizados desde el perfil: "
            "Thumb: $umbralThumb, "
            "Index: $umbralIndex, "
            "Middle: $umbralMiddle, "
            "Ring: $umbralRing, "
            "Pinky: $umbralPinky");
      }
    }
  }

  void unlockNextLevel(int completedLevel) {
    if (currentProfile == null) return;
    if (completedLevel == currentProfile!.learningLevel && completedLevel < 9) {
      final updated = currentProfile!.copyWith(
        learningLevel: completedLevel + 1,
      );
      _updateCurrentProfile(updated);
      notifyListeners();
    }
  }

  void toggleRepeatAfterMe() {
    repeatAfterMeMode = !repeatAfterMeMode;
    if (!repeatAfterMeMode) {
      repeatMeTargetLetter = null;
      _repeatMeTimer?.cancel();
    }
    notifyListeners();
  }

  // ── MÉTODOS DE CONEXIÓN (SOLO BLE) ────────────────────────────────────────
  Future<void> scanDevices() async {
    connectionStatus = AppConnectionStatus.scanning;
    hasSearchedOnce = true;
    notifyListeners();
    try {
      // El escaneo tomará los 10 segundos configurados en el servicio internamente
      await _bluetoothService.startScan();
      
      // Asegurar que la UI muestre "buscando" durante exactamente los 10 segundos
      await Future.delayed(const Duration(seconds: 10));
      
      // Una vez terminado el tiempo de búsqueda, si no se seleccionó ningún guante y sigue "buscando",
      // volvemos a estado desconectado para que vuelva a aparecer el botón de "BUSCAR DE NUEVO".
      if (connectionStatus == AppConnectionStatus.scanning) {
        connectionStatus = AppConnectionStatus.disconnected;
        notifyListeners();
      }
    } catch (e) {
      connectionStatus = AppConnectionStatus.disconnected;
      notifyListeners();
    }
  }

  Future<void> connectToDevice(BleDeviceModel deviceModel) async {
    bleConnectionError = '';
    notifyListeners();
    try {
      final success = await _bluetoothService.connectTo(deviceModel.device);
      if (success) {
        connectionStatus = AppConnectionStatus.connected;
        deviceName = deviceModel.name;
      } else {
        connectionStatus = AppConnectionStatus.disconnected;
        deviceName = '';
        bleConnectionError = 'No se encontró la característica de datos del guante (UUID a5c7823f-1234-4688-b7f5-ea07361b2c1d).';
      }
    } catch (e) {
      connectionStatus = AppConnectionStatus.disconnected;
      deviceName = '';
      bleConnectionError = e.toString();
    }
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _bluetoothService.disconnect();
    connectionStatus = AppConnectionStatus.disconnected;
    deviceName = '';
    notifyListeners();
  }

  Future<bool> sendCommandToGlove(String command) async {
    if (_bluetoothService.isMocking) {
      debugPrint("[MOCK WRITE] Escribiendo comando: '$command'");
      return true;
    }
    return await _bluetoothService.writeData(command);
  }

  // Envía la configuración de una letra personalizada por BLE con valores analógicos reales
  void sendSetLetterCommand(String letter, List<int> pattern, bool isVertical, bool isDynamic, List<int> rawFlex) {
    int orientation = isVertical ? 0 : 3; // 0: Vertical, 3: Cualquiera
    int dynamicVal = isDynamic ? 1 : 0;
    
    // Formato: SET_LETRA,L,f0,f1,f2,f3,f4,orientation,dynamic
    final command = "SET_LETRA,$letter,${rawFlex[0]},${rawFlex[1]},${rawFlex[2]},${rawFlex[3]},${rawFlex[4]},$orientation,$dynamicVal";
    sendCommandToGlove(command);
    debugPrint("[BLE COMMAND] Sent: $command");
  }

  // Envía el comando de restauración de una letra a valores de fábrica por BLE
  void sendResetLetterCommand(String letter) {
    final command = "RESET_LETRA,$letter";
    sendCommandToGlove(command);
    debugPrint("[BLE COMMAND] Sent: $command");
  }

  // Activa el modo simulación para desarrollo sin guante físico
  void startMockSequence() {
    connectionStatus = AppConnectionStatus.connected;
    deviceName = "GuanteLSP (Simulado)";
    notifyListeners();
    
    // Secuencia de prueba: Deletreo de la palabra "HOLA"
    _bluetoothService.startMockingData([
      'H', 'O', 'L', 'A', ' '
    ]);
  }

  void stopMockSequence() {
    _bluetoothService.stopMocking();
    connectionStatus = AppConnectionStatus.disconnected;
    deviceName = '';
    notifyListeners();
  }

  // ── PROCESAMIENTO DE DATOS Y GESTOS ───────────────────────────────────────
  void _processIncomingGloveData(String csvData) {
    debugPrint("[DEBUG] _processIncomingGloveData: '$csvData'");
    // Formato esperado: F1,F2,F3,F4,F5,Ax,Ay,Az,Gx,Gy,Gz
    final parts = csvData.split(',');
    if (parts.length < 5) return;

    try {
      // 1. Obtener valores analógicos de flexión
      final List<int> flex = [
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
        int.parse(parts[3]),
        int.parse(parts[4]),
      ];
      rawFlexValues = flex;

      // 2. Obtener acelerómetro si está disponible (MPU6050)
      if (parts.length >= 8) {
        accelX = double.parse(parts[5]);
        accelY = double.parse(parts[6]);
        accelZ = double.parse(parts[7]);
      }

      // Obtener giroscopio si está disponible
      if (parts.length >= 11) {
        gyroX = double.parse(parts[8]);
        gyroY = double.parse(parts[9]);
        gyroZ = double.parse(parts[10]);
      } else {
        gyroX = 0;
        gyroY = 0;
        gyroZ = 0;
      }

      // 3. Obtener sensores de contacto si están disponibles (los 5 nuevos valores al final)
      List<int> contactos = [0, 0, 0, 0, 0];
      if (parts.length >= 16) {
        contactos = [
          int.parse(parts[11]),
          int.parse(parts[12]),
          int.parse(parts[13]),
          int.parse(parts[14]),
          int.parse(parts[15]),
        ];
      }

      // Guardar lecturas de movimiento durante la calibración activa
      if (isRecordingMovement) {
        _tempMovementData.add([accelX, accelY, accelZ, gyroX, gyroY, gyroZ]);
      }

      // 4. Normalizar valores flex según el perfil actual (Interpolación a trozos de 3 puntos)
      flexPercentages = List.generate(5, (i) {
        final openVal = currentProfile?.flexMin[i] ?? 1200;
        final midVal = currentProfile?.flexMid[i] ?? 2600;
        final closedVal = currentProfile?.flexMax[i] ?? 4000;
        
        if (openVal == closedVal) return 0.0;
        
        final val = flex[i];
        double percent;
        
        if (openVal < closedVal) {
          // Mano abierta = ADC bajo, Cerrado = ADC alto
          if (val <= openVal) {
            percent = 0.0;
          } else if (val >= closedVal) {
            percent = 100.0;
          } else if (val < midVal) {
            final range = midVal - openVal;
            percent = range > 0 ? ((val - openVal) / range) * 50.0 : 0.0;
          } else {
            final range = closedVal - midVal;
            percent = range > 0 ? 50.0 + ((val - midVal) / range) * 50.0 : 50.0;
          }
        } else {
          // Mano abierta = ADC alto, Cerrado = ADC bajo
          if (val >= openVal) {
            percent = 0.0;
          } else if (val <= closedVal) {
            percent = 100.0;
          } else if (val > midVal) {
            final range = openVal - midVal;
            percent = range > 0 ? ((openVal - val) / range) * 50.0 : 0.0;
          } else {
            final range = midVal - closedVal;
            percent = range > 0 ? 50.0 + ((midVal - val) / range) * 50.0 : 50.0;
          }
        }
        return percent.clamp(0.0, 100.0);
      });

      // Mapeo de 3 estados: 0 (Abierto), 1 (Semicerrado), 2 (Cerrado)
      fingerPattern = flexPercentages.map((p) {
        if (p < 34.0) return 0;
        if (p < 68.0) return 1;
        return 2;
      }).toList();

      // Si estamos en modo de calibración, no traducir gestos todavía
      if (isCalibrating) {
        notifyListeners();
        return;
      }

      // Grabar muestras dinámicas en tiempo real si está activo
      if (isRecordingDynamicSign) {
        tempRecordingSamples.add([
          flex[0], flex[1], flex[2], flex[3], flex[4],
          accelX, accelY, accelZ,
          gyroX, gyroY, gyroZ
        ]);
      }

      // Guardar en el historial local para evaluar gestos dinámicos (últimas 60 muestras = 3s)
      gloveDataHistory.add([
        flex[0], flex[1], flex[2], flex[3], flex[4],
        accelX, accelY, accelZ,
        gyroX, gyroY, gyroZ
      ]);
      if (gloveDataHistory.length > 60) {
        gloveDataHistory.removeAt(0);
      }

      // Actualizar límites dinámicos de sesión en base a los valores recibidos
      for (int i = 0; i < 5; i++) {
        int val = flex[i];
        if (val < sessionMinFlex[i]) {
          if (val > 400) sessionMinFlex[i] = val; // Filtrar ruidos extremos
        }
        if (val > sessionMaxFlex[i]) {
          if (val < 3800) sessionMaxFlex[i] = val; // Filtrar picos erráticos
        }
      }

      // Ejecutar motor de reconocimiento local solo si la traducción está activa
      if (isTranslationActive) {
        bool matchedCustom = _recognizeLocalCustomSigns();
        
        // Si no se reconoció una seña personalizada de palabra completa, usar el algoritmo de estabilidad de 2 filtros
        if (!matchedCustom) {
          _processDetectionFilters(flex, contactos, accelX, accelY, accelZ);
        }
      }

      notifyListeners();
    } catch (e) {
      // Evitar caídas si se recibe trama dañada
    }
  }

  bool manoEstaQuieta(List<int> nuevosValores) {
    // Actualizar buffer con los nuevos valores
    for (int d = 0; d < 5; d++) {
      _bufferFlex[d][_bufferIdx] = nuevosValores[d];
    }
    _bufferIdx = (_bufferIdx + 1) % _bufferSize;

    // Verificar rango de cada dedo
    for (int d = 0; d < 5; d++) {
      int minVal = _bufferFlex[d].reduce((a, b) => a < b ? a : b);
      int maxVal = _bufferFlex[d].reduce((a, b) => a > b ? a : b);
      if ((maxVal - minVal) > _umbralQuietud) return false;
    }
    return true;
  }

  bool detectarMovimiento() {
    if (gloveDataHistory.length < 3) return false;
    
    double maxGyro = 0.0;
    double maxAccelDelta = 0.0;
    
    final double umbralGyro = currentProfile?.umbralMovimientoGyro ?? 1.2;
    final double umbralAccel = currentProfile?.umbralMovimientoAccel ?? 2.5;
    
    // Analizar las últimas 3 muestras (aprox 150ms a 20Hz)
    for (int i = gloveDataHistory.length - 3; i < gloveDataHistory.length - 1; i++) {
      final current = gloveDataHistory[i];
      final next = gloveDataHistory[i + 1];
      
      final double gx = (next[8] as num).toDouble();
      final double gy = (next[9] as num).toDouble();
      final double gz = (next[10] as num).toDouble();
      
      final double ax1 = (current[5] as num).toDouble();
      final double ay1 = (current[6] as num).toDouble();
      final double az1 = (current[7] as num).toDouble();
      
      final double ax2 = (next[5] as num).toDouble();
      final double ay2 = (next[6] as num).toDouble();
      final double az2 = (next[7] as num).toDouble();
      
      final double gyroMaxFrame = [gx.abs(), gy.abs(), gz.abs()].reduce(max);
      if (gyroMaxFrame > maxGyro) maxGyro = gyroMaxFrame;
      
      final double accelDelta = [(ax2 - ax1).abs(), (ay2 - ay1).abs(), (az2 - az1).abs()].reduce(max);
      if (accelDelta > maxAccelDelta) maxAccelDelta = accelDelta;
    }
    
    return maxGyro > umbralGyro || maxAccelDelta > umbralAccel;
  }

  String calcularPatron(List<int> flex, List<int> contactos) {
    List<int> umbrales = [umbralThumb, umbralIndex, umbralMiddle, umbralRing, umbralPinky];
    String patronFlex = List.generate(5, (i) => flex[i] > umbrales[i] ? '1' : '0').join();
    String patronContactos = contactos.join();
    return patronFlex + patronContactos;
  }

  void _processDetectionFilters(List<int> flex, List<int> contactos, double ax, double ay, double az) {
    if (!manoEstaQuieta(flex)) {
      _patronActual = null;
      _inicioEstabilidad = null;
      return;
    }

    // Calcular patrón binario actual (de 10 dígitos) para compatibilidad
    String patron = calcularPatron(flex, contactos);

    // 1. Extraer los 5 dígitos del patrón base de flexión (Ejemplo: "10000")
    List<int> umbrales = [umbralThumb, umbralIndex, umbralMiddle, umbralRing, umbralPinky];
    String patronFlex = List.generate(5, (i) => flex[i] > umbrales[i] ? '1' : '0').join();

    // 2. Extraer el estado de cada sensor de contacto (0 o 1)
    // Asumiendo el orden: d12, d13, d16, d17 (antes d4), d18 (antes d2)
    bool d12 = contactos[0] == 1; // punta dedo indice
    bool d13 = contactos[1] == 1; // punta dedo medio
    bool d16 = contactos[2] == 1; // medio dedo indice
    bool d17 = contactos[3] == 1; // base dedo medio (antes d4)
    bool d18 = contactos[4] == 1; // base dedo anular (antes d2)

    String? letra;
    final double umbralInclinacion = currentProfile?.umbralInclinacion ?? 2.0;

    // 3. Primer filtro: El patrón binario de flexión
    switch (patronFlex) {
      case '10000': 
        // GRUPO: A, C, T
        if (d16) {
          letra = 'T';
        } else if (d13) {
          letra = 'A';
        } else {
          letra = 'C';
        }
        break;

      case '11000': 
        // GRUPO: G, L, Q
        if (d13) {
          letra = 'G';
        } else {
          letra = (ax < umbralInclinacion) ? 'Q' : 'L'; // Q hacia abajo, L vertical/arriba
        }
        break;

      case '01100': 
        // GRUPO: H, V, N
        if (d18) {
          letra = 'H';
        } else {
          letra = (ax < umbralInclinacion) ? 'N' : 'V'; // N hacia abajo, V vertical/arriba
        }
        break;

      case '11100': 
        // GRUPO: K, R
        if (d17) {
          letra = 'K';
        } else {
          letra = 'R';
        }
        break;

      case '00000': 
        // GRUPO: O, S, X, E
        if (d12) {
          letra = 'O';
        } else if (d13) {
          letra = 'S';
        } else if (d17) {
          letra = 'X';
        } else {
          letra = 'E';
        }
        break;

    // ----- LETRAS QUE YA EXISTÍAN Y NO NECESITAN CONTACTO -----
    case '01011':
      letra = ' '; // Gesto 01011 = Espacio (Finalizar palabra)
      break;
    case '01111':
      letra = 'B';
      break;
    case '01000':
      if (ax < umbralInclinacion) {
        letra = 'P'; // P hacia abajo
      } else {
        // Es D (vertical). Si se detecta movimiento pronunciado, es Z
        if (detectarMovimiento()) {
          letra = 'Z';
        } else {
          letra = 'D';
        }
      }
      break;
    case '00111':
      letra = 'F';
      break;
    case '00001':
      // Si se detecta movimiento con el meñique extendido, es J. Si no, es I.
      if (detectarMovimiento()) {
        letra = 'J';
      } else {
        letra = 'I';
      }
      break;
    case '01110':
      letra = (ax < umbralInclinacion) ? 'M' : 'W'; // M hacia abajo, W vertical/arriba
      break;
    case '01001':
      letra = 'U';
      break;
    case '10001':
      letra = 'Y';
      break;
  }

    if (letra == null) {
      _patronActual = null;
      _inicioEstabilidad = null;
      return;
    }

    // Si el patrón cambió respecto al que veníamos evaluando, reiniciar cronómetro
    if (patron != _patronActual) {
      _patronActual = patron;
      _inicioEstabilidad = DateTime.now();
      return;
    }

    // El patrón se mantiene igual desde inicioEstabilidad
    final ahora = DateTime.now();
    final msSostenido = ahora.difference(_inicioEstabilidad!).inMilliseconds;

    // Verificar cooldown entre letras
    final msDesdUltima = _ultimaEmision == null
        ? 999999
        : ahora.difference(_ultimaEmision!).inMilliseconds;

    if (msSostenido >= _msEstabilidad && msDesdUltima >= _msCooldown) {
      final ahoraMismo = DateTime.now();
      final msDesdeUltimaVisualizacion = _lastEmissionTime == null
          ? 999999
          : ahoraMismo.difference(_lastEmissionTime!).inMilliseconds;

      if (msDesdeUltimaVisualizacion >= 1000) {
        _handleNewCharacter(letra);
        _ultimaLetraEmitida = letra;
        _ultimaEmision = ahoraMismo;

        currentLetter = letra;
        _lastEmissionTime = ahoraMismo;
        notifyListeners();

        // Limpiar pantalla tras 3 segundos
        Timer(const Duration(seconds: 3), () {
          if (currentLetter == letra) {
            currentLetter = '';
            notifyListeners();
          }
        });

        _patronActual = null;
        _inicioEstabilidad = null;
      }
    }
  }

  String _lastTriggeredCustomSign = "";
  DateTime _lastTriggeredTime = DateTime.now().subtract(const Duration(seconds: 5));

  // Convierte lecturas flex analógicas crudas en patrón de 3 estados (0, 1, 2) según calibración activa
  List<int> getFingerPatternFromRaw(List<int> raw) {
    return List.generate(5, (i) {
      final openVal = currentProfile?.flexMin[i] ?? 1200;
      final midVal = currentProfile?.flexMid[i] ?? 2600;
      final closedVal = currentProfile?.flexMax[i] ?? 4000;
      if (openVal == closedVal) return 0;
      final val = raw[i];
      double percent;
      if (openVal < closedVal) {
        if (val <= openVal) {
          percent = 0.0;
        } else if (val >= closedVal) {
          percent = 100.0;
        } else if (val < midVal) {
          final range = midVal - openVal;
          percent = range > 0 ? ((val - openVal) / range) * 50.0 : 0.0;
        } else {
          final range = closedVal - midVal;
          percent = range > 0 ? 50.0 + ((val - midVal) / range) * 50.0 : 50.0;
        }
      } else {
        if (val >= openVal) {
          percent = 0.0;
        } else if (val <= closedVal) {
          percent = 100.0;
        } else if (val > midVal) {
          final range = openVal - midVal;
          percent = range > 0 ? ((openVal - val) / range) * 50.0 : 0.0;
        } else {
          final range = midVal - closedVal;
          percent = range > 0 ? 50.0 + ((midVal - val) / range) * 50.0 : 50.0;
        }
      }
      double pct = percent.clamp(0.0, 100.0);
      if (pct < 34.0) return 0;
      if (pct < 68.0) return 1;
      return 2;
    });
  }

  bool _recognizeLocalCustomSigns() {
    if (currentProfile == null || currentProfile!.customSigns.isEmpty) return false;
    final now = DateTime.now();
    bool isVertical = accelY.abs() < 6.0;

    for (var entry in currentProfile!.customSigns.entries) {
      final word = entry.key;
      final rawData = entry.value;

      bool isStatic = true;
      List<int> targetFingerPattern = [];
      bool targetIsVertical = true;
      List<List<dynamic>>? samples;

      if (rawData is List) {
        if (rawData.length >= 6) {
          targetFingerPattern = List<dynamic>.from(rawData.take(5))
              .map((e) => e is bool ? (e ? 2 : 0) : (e as num).toInt())
              .toList();
          targetIsVertical = rawData[5] as bool;
          isStatic = rawData.length >= 7 ? rawData[6] as bool : true;
        } else {
          continue;
        }
      } else if (rawData is Map) {
        isStatic = rawData['isStatic'] as bool? ?? true;
        if (isStatic) {
          targetFingerPattern = List<dynamic>.from(rawData['fingerPattern'] as List)
              .map((e) => e is bool ? (e ? 2 : 0) : (e as num).toInt())
              .toList();
          targetIsVertical = rawData['isVertical'] as bool? ?? true;
        } else {
          final rawSamples = rawData['samples'] as List?;
          if (rawSamples != null) {
            samples = rawSamples.map((e) => List<dynamic>.from(e as List)).toList();
          }
        }
      }

      if (isStatic) {
        bool match = true;
        for (int i = 0; i < 5; i++) {
          if (targetFingerPattern[i] != fingerPattern[i]) {
            match = false;
            break;
          }
        }
        if (match && targetIsVertical == isVertical) {
          if (word == _lastTriggeredCustomSign && now.difference(_lastTriggeredTime).inMilliseconds < 2500) {
            return true;
          }
          _lastTriggeredCustomSign = word;
          _lastTriggeredTime = now;
          _appendCompletedWord(word);
          return true;
        }
      } else {
        if (samples == null || samples.isEmpty || gloveDataHistory.length < 15) continue;

        // Obtener la postura inicial y final grabadas
        final startFlexRaw = List<int>.from(samples.first.take(5).map((e) => (e as num).toInt()));
        final endFlexRaw = List<int>.from(samples.last.take(5).map((e) => (e as num).toInt()));

        final startFingerPattern = getFingerPatternFromRaw(startFlexRaw);
        final endFingerPattern = getFingerPatternFromRaw(endFlexRaw);

        // 1. Verificar si la postura actual coincide con el final de la seña
        bool currentMatchesEnd = true;
        for (int i = 0; i < 5; i++) {
          if (endFingerPattern[i] != fingerPattern[i]) {
            currentMatchesEnd = false;
            break;
          }
        }
        if (!currentMatchesEnd) continue;

        // 2. Buscar en el historial si hace 1.2s - 2.5s se adoptó la postura inicial
        int startIndex = -1;
        int searchEndIndex = (gloveDataHistory.length * 0.6).round();
        for (int i = 0; i < searchEndIndex; i++) {
          final histFlex = List<int>.from(gloveDataHistory[i].take(5).map((e) => (e as num).toInt()));
          final histPattern = getFingerPatternFromRaw(histFlex);

          bool patternMatchesStart = true;
          for (int j = 0; j < 5; j++) {
            if (histPattern[j] != startFingerPattern[j]) {
              patternMatchesStart = false;
              break;
            }
          }
          if (patternMatchesStart) {
            startIndex = i;
            break;
          }
        }

        if (startIndex == -1) continue;

        // 3. Verificar si hubo suficiente movimiento en ese lapso
        double totalGyroMotion = 0.0;
        for (int i = startIndex; i < gloveDataHistory.length; i++) {
          final gx = (gloveDataHistory[i][8] as num).toDouble();
          final gy = (gloveDataHistory[i][9] as num).toDouble();
          final gz = (gloveDataHistory[i][10] as num).toDouble();
          totalGyroMotion += gx.abs() + gy.abs() + gz.abs();
        }

        if (totalGyroMotion > 10.0) {
          if (word == _lastTriggeredCustomSign && now.difference(_lastTriggeredTime).inMilliseconds < 2500) {
            return true;
          }
          _lastTriggeredCustomSign = word;
          _lastTriggeredTime = now;
          _appendCompletedWord(word);
          return true;
        }
      }
    }
    return false;
  }



  // Evita spam de la misma letra y maneja la transición de deletreo
  DateTime _lastCharTime = DateTime.now();
  String _lastRegisteredChar = "";

  void _handleNewCharacter(String char) {
    final now = DateTime.now();
    final diff = now.difference(_lastCharTime).inMilliseconds;
    debugPrint("[DEBUG] _handleNewCharacter: char='$char', last='$_lastRegisteredChar', diff=${diff}ms");
    // Debounce: evitar registrar la misma letra repetidamente en menos de 1.2 segundos (salvo en simulación)
    if (!_bluetoothService.isMocking && char == _lastRegisteredChar && diff < 1200) {
      debugPrint("[DEBUG] _handleNewCharacter: DEBOUNCED '$char'");
      return;
    }

    // Detectar si es una letra repetida consecutivamente
    final bool isRepeated = (char == _lastRegisteredChar);

    _lastCharTime = now;
    _lastRegisteredChar = char;
    currentLetter = char;
    isListening = true;

    // Iniciar visualización de "Repite tú" si el modo está activo y es un caracter normal (no espacio)
    if (repeatAfterMeMode && char != ' ' && char != '---' && char != '—') {
      repeatMeTargetLetter = char;
      _repeatMeTimer?.cancel();
      _repeatMeTimer = Timer(const Duration(seconds: 3), () {
        repeatMeTargetLetter = null;
        notifyListeners();
      });
    }

    notifyListeners();

    // Animación de parpadeo
    Future.delayed(const Duration(milliseconds: 300), () {
      isListening = false;
      notifyListeners();
    });

    if (char == ' ') {
      // Si recibimos espacio, finaliza la palabra actual
      _finalizeWord();
    } else {
      // Letra normal: añadir al buffer de deletreo
      _currentWordBuffer += char;
      translatedText += char;
      
      // Actualizar sugerencias de autocompletado en base al buffer actual
      suggestions = _nlpEngine.getSuggestions(_currentWordBuffer);
      
      // Si estamos simulando o la opción autoSpeak está habilitada y el modo es de letra, pronunciar la letra individual
      if (_bluetoothService.isMocking || (autoSpeak && autoSpeakMode == AutoSpeakMode.letter && !isRepeated)) {
        _ttsService.speak(char.toLowerCase());
      }
      
      notifyListeners();
    }
  }

  // Al presionar espacio o completar gesto
  void _finalizeWord() {
    if (_currentWordBuffer.isNotEmpty) {
      // Corregir palabra localmente por Levenshtein
      final corrected = _nlpEngine.correctWord(_currentWordBuffer);
      
      // Reemplazar la última palabra en el texto traducido con la palabra corregida
      if (translatedText.isNotEmpty) {
        final words = translatedText.trim().split(' ');
        if (words.isNotEmpty) {
          words.last = corrected;
          translatedText = words.join(' ') + ' ';
        }
      }
      
      // Si estamos simulando o la opción autoSpeak está habilitada y el modo es de palabra, pronunciar la palabra completa
      if (_bluetoothService.isMocking || (autoSpeak && autoSpeakMode == AutoSpeakMode.word)) {
        _ttsService.speak(corrected);
      }
      
      // Registrar en palabras frecuentes si fue exitosa
      _registerWordUsage(corrected);
      
      _currentWordBuffer = '';
      suggestions.clear();
      notifyListeners();
    } else {
      // Solo agregar espacio si no hay palabra a corregir
      if (translatedText.isNotEmpty && !translatedText.endsWith(' ')) {
        translatedText += ' ';
        notifyListeners();
      }
    }
  }

  // Añadir una palabra completa de golpe (ej. seña personalizada)
  void _appendCompletedWord(String word) {
    if (translatedText.isNotEmpty && !translatedText.endsWith(' ')) {
      translatedText += ' ';
    }
    translatedText += '$word ';
    _currentWordBuffer = '';
    suggestions.clear();
    
    // TTS instantáneo (como es seña personalizada de palabra completa, la leemos si autoSpeak está habilitada)
    if (autoSpeak) {
      _ttsService.speak(word);
    }
    
    _registerWordUsage(word);
    notifyListeners();
  }

  // Registra el uso de palabras para actualizar las frecuentes
  void _registerWordUsage(String word) {
    if (currentProfile == null) return;
    final upperWord = word.toUpperCase();
    
    final freq = List<String>.from(currentProfile!.frequentWords);
    
    // Si ya existe, mover al principio
    if (freq.contains(upperWord)) {
      freq.remove(upperWord);
      freq.insert(0, upperWord);
    } else {
      freq.insert(0, upperWord);
      if (freq.length > 10) {
        freq.removeLast(); // Mantener solo las 10 más frecuentes
      }
    }

    final updated = currentProfile!.copyWith(
      frequentWords: freq,
    );
    _updateCurrentProfile(updated);
  }

  // Agrega una seña estática con el patrón actual
  void registerCustomSignStatic(String word, List<int> pattern, bool isVertical, List<int> rawFlex, {String? imagePath}) {
    if (currentProfile == null) return;
    
    final Map<String, dynamic> signData = {
      'isStatic': true,
      'fingerPattern': pattern,
      'isVertical': isVertical,
      'rawFlex': rawFlex,
      'imagePath': imagePath,
    };

    final updatedSigns = Map<String, dynamic>.from(currentProfile!.customSigns);
    updatedSigns[word.toUpperCase()] = signData;

    final updated = currentProfile!.copyWith(
      customSigns: updatedSigns,
    );
    _updateCurrentProfile(updated);
    notifyListeners();
  }

  // Agrega una seña dinámica con las muestras grabadas
  void registerCustomSignDynamic(String word, List<List<dynamic>> samples, {String? imagePath}) {
    if (currentProfile == null) return;

    final Map<String, dynamic> signData = {
      'isStatic': false,
      'samples': samples,
      'imagePath': imagePath,
    };

    final updatedSigns = Map<String, dynamic>.from(currentProfile!.customSigns);
    updatedSigns[word.toUpperCase()] = signData;

    final updated = currentProfile!.copyWith(
      customSigns: updatedSigns,
    );
    _updateCurrentProfile(updated);
    notifyListeners();
  }

  // Actualiza una seña existente
  void updateCustomSign(String oldWord, String newWord, Map<String, dynamic> updatedData) {
    if (currentProfile == null) return;
    final updatedSigns = Map<String, dynamic>.from(currentProfile!.customSigns);
    
    if (oldWord.toUpperCase() != newWord.toUpperCase()) {
      updatedSigns.remove(oldWord.toUpperCase());
    }
    updatedSigns[newWord.toUpperCase()] = updatedData;

    final updated = currentProfile!.copyWith(
      customSigns: updatedSigns,
    );
    _updateCurrentProfile(updated);
    notifyListeners();
  }

  // Copia la imagen importada a una ubicación persistente local y la asocia a la seña
  Future<String?> associateImageToCustomSign(String word, String sourcePath) async {
    if (currentProfile == null) return null;
    if (kIsWeb) return sourcePath;
    try {
      final originalFile = File(sourcePath);
      if (!await originalFile.exists()) return null;

      final directory = await getApplicationDocumentsDirectory();
      final extension = sourcePath.split('.').last;
      final newFileName = 'custom_sign_${word.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final persistentFile = await originalFile.copy('${directory.path}/$newFileName');
      
      final upperWord = word.toUpperCase();
      if (currentProfile!.customSigns.containsKey(upperWord)) {
        final existing = currentProfile!.customSigns[upperWord];
        if (existing is Map) {
          final updatedData = Map<String, dynamic>.from(existing);
          updatedData['imagePath'] = persistentFile.path;
          
          final updatedSigns = Map<String, dynamic>.from(currentProfile!.customSigns);
          updatedSigns[upperWord] = updatedData;

          final updated = currentProfile!.copyWith(
            customSigns: updatedSigns,
          );
          _updateCurrentProfile(updated);
        }
      }
      notifyListeners();
      return persistentFile.path;
    } catch (e) {
      debugPrint("Error al copiar la imagen de la seña personalizada: $e");
      return null;
    }
  }

  // Agrega una seña personalizada con un patrón y orientación específicos (Wrapper de compatibilidad)
  void registerCustomSignWithPattern(String word, List<int> pattern, bool isVertical, List<int> rawFlex, {bool isStatic = true}) {
    if (isStatic) {
      registerCustomSignStatic(word, pattern, isVertical, rawFlex);
    } else {
      registerCustomSignDynamic(word, tempRecordingSamples);
    }
  }

  // Agrega una seña personalizada con el patrón actual (Wrapper de compatibilidad)
  void registerCustomSign(String word, {bool isStatic = true}) {
    final bool isVertical = accelY.abs() < 6.0;
    registerCustomSignWithPattern(word, fingerPattern, isVertical, rawFlexValues, isStatic: isStatic);
  }

  void removeCustomSign(String word) {
    if (currentProfile == null) return;
    final updatedSigns = Map<String, dynamic>.from(currentProfile!.customSigns);
    updatedSigns.remove(word.toUpperCase());

    final updated = currentProfile!.copyWith(
      customSigns: updatedSigns,
    );
    _updateCurrentProfile(updated);
    notifyListeners();
  }

  // Aplicar una de las sugerencias del autocompletado
  void applySuggestion(String word) {
    if (translatedText.isNotEmpty) {
      final words = translatedText.trim().split(' ');
      if (words.isNotEmpty) {
        words.last = word;
        translatedText = words.join(' ') + ' ';
      }
    } else {
      translatedText = '$word ';
    }
    
    _ttsService.speak(word);
    _registerWordUsage(word);
    
    _currentWordBuffer = '';
    suggestions.clear();
    notifyListeners();
  }

  // ── MÉTODOS DE EDICIÓN MANUAL Y TEXTO ─────────────────────────────────────
  void clearText() {
    translatedText = '';
    _currentWordBuffer = '';
    currentLetter = '';
    suggestions.clear();
    notifyListeners();
  }

  void deleteLastChar() {
    if (translatedText.isNotEmpty) {
      translatedText = translatedText.substring(0, translatedText.length - 1);
      
      // Reconstruir buffer
      final words = translatedText.trim().split(' ');
      if (words.isNotEmpty && !translatedText.endsWith(' ')) {
        _currentWordBuffer = words.last;
      } else {
        _currentWordBuffer = '';
      }
      notifyListeners();
    }
  }

  void toggleAutoSpeak() {
    autoSpeak = !autoSpeak;
    notifyListeners();
  }

  void setAutoSpeakMode(AutoSpeakMode mode) {
    autoSpeakMode = mode;
    notifyListeners();
  }

  Future<void> speakAllText() async {
    isSpeaking = true;
    notifyListeners();
    await _ttsService.speak(translatedText);
    isSpeaking = false;
    notifyListeners();
  }

  Future<void> stopSpeaking() async {
    await _ttsService.stop();
    isSpeaking = false;
    notifyListeners();
  }
}
