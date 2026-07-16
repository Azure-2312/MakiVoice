import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as flutter_services;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/app_colors.dart';
import '../../../core/constants.dart';
import '../../translator/domain/app_state.dart';
import '../../translator/presentation/hand_visualizer.dart';

class CreateSignScreen extends StatefulWidget {
  final AppState appState;
  final String? initialWord;
  final dynamic initialData;

  const CreateSignScreen({
    super.key,
    required this.appState,
    this.initialWord,
    this.initialData,
  });

  @override
  State<CreateSignScreen> createState() => _CreateSignScreenState();
}

class _CreateSignScreenState extends State<CreateSignScreen> {
  int _currentStep = 0; // 0 = Seleccionar Tipo, 1 = Captura/Lectura, 2 = Asignación
  bool _isStatic = true;

  // Datos capturados
  List<int> _capturedFingerPattern = [0, 0, 0, 0, 0];
  List<int> _capturedRawFlexValues = [1200, 1200, 1200, 1200, 1200];
  bool _capturedIsVertical = true;
  List<List<dynamic>> _capturedDynamicSamples = [];

  final TextEditingController _wordController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _selectedImagePath;
  String? _selectedVideoPath;

  @override
  void initState() {
    super.initState();
    if (widget.initialWord != null) {
      _wordController.text = widget.initialWord!;
    }
    
    if (widget.initialData != null) {
      final data = widget.initialData;
      if (data is List) {
        _isStatic = data.length >= 7 ? data[6] as bool : true;
        _capturedFingerPattern = List<dynamic>.from(data.take(5))
            .map((e) => e is bool ? (e ? 2 : 0) : (e as num).toInt())
            .toList();
        _capturedIsVertical = data.length >= 6 ? data[5] as bool : true;
      } else if (data is Map) {
        _isStatic = data['isStatic'] as bool? ?? true;
        _selectedImagePath = data['imagePath'] as String?;
        _selectedVideoPath = data['videoPath'] as String?;
        if (_isStatic) {
          _capturedFingerPattern = List<dynamic>.from(data['fingerPattern'] as List)
              .map((e) => e is bool ? (e ? 2 : 0) : (e as num).toInt())
              .toList();
          _capturedIsVertical = data['isVertical'] as bool? ?? true;
          _capturedRawFlexValues = List<int>.from(data['rawFlex'] ?? [1200, 1200, 1200, 1200, 1200]);
        } else {
          final samples = data['samples'] as List?;
          if (samples != null) {
            _capturedDynamicSamples = samples.map((e) => List<dynamic>.from(e as List)).toList();
          }
        }
      }
      // Si estamos editando, empezamos directamente en el paso 1 (pero con los datos precargados)
    }
  }

  @override
  void dispose() {
    _wordController.dispose();
    super.dispose();
  }

  // Muestra un menú de selección de fuente multimedia (Cámara o Galería)
  void _showMediaSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'SELECCIONAR MULTIMEDIA',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecond, fontSize: 11, letterSpacing: 1),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.accent),
                title: const Text('Tomar Foto con Cámara', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  _captureImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.accent),
                title: const Text('Seleccionar Foto de Galería', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  _captureImage(ImageSource.gallery);
                },
              ),
              if (!_isStatic) ...[
                const Divider(color: AppColors.surfaceLight),
                ListTile(
                  leading: const Icon(Icons.videocam, color: AppColors.error),
                  title: const Text('Grabar Video con Cámara', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    _captureVideo(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.video_library, color: AppColors.error),
                  title: const Text('Seleccionar Video de Galería', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    _captureVideo(ImageSource.gallery);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
          _selectedVideoPath = null; // Limpiar video si se selecciona foto
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al capturar la imagen.')),
      );
    }
  }

  Future<void> _captureVideo(ImageSource source) async {
    try {
      final XFile? video = await _picker.pickVideo(source: source);
      if (video != null) {
        setState(() {
          _selectedVideoPath = video.path;
          _selectedImagePath = null; // Limpiar imagen si se selecciona video
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al grabar el video.')),
      );
    }
  }

  void _playVideo() async {
    if (_selectedVideoPath == null) return;
    final path = _selectedVideoPath!;
    if (kIsWeb) {
      final Uri uri = Uri.parse(path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      return;
    }
    final file = File(path);
    if (await file.exists()) {
      final Uri uri = Uri.file(path);
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          // Intentar abrir como string directo
          final url = Uri.parse('file://$path');
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No hay una app para reproducir videos: $e')),
        );
      }
    }
  }

  void _captureStaticPattern() {
    if (widget.appState.connectionStatus != AppConnectionStatus.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El guante debe estar conectado para capturar la seña.')),
      );
      return;
    }

    setState(() {
      _capturedFingerPattern = List<int>.from(widget.appState.fingerPattern);
      _capturedRawFlexValues = List<int>.from(widget.appState.rawFlexValues);
      _capturedIsVertical = widget.appState.accelY.abs() < 6.0;
      _currentStep = 2; // Avanzar a asignación de palabra
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Seña estática capturada!')),
    );
  }

  void _startDynamicRecording() {
    if (widget.appState.connectionStatus != AppConnectionStatus.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El guante debe estar conectado para grabar movimiento.')),
      );
      return;
    }

    widget.appState.startRecordingDynamicSign();
    
    // Timer para monitorear cuándo finaliza la grabación del AppState
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!widget.appState.isRecordingDynamicSign) {
        timer.cancel();
        setState(() {
          _capturedDynamicSamples = List<List<dynamic>>.from(widget.appState.tempRecordingSamples);
          _currentStep = 2; // Avanzar al paso 3
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Movimiento dinámico grabado con éxito!')),
        );
      }
    });
  }

  Future<String?> _associateVideoToCustomSign(String word, String sourcePath) async {
    if (kIsWeb) return sourcePath;
    try {
      final originalFile = File(sourcePath);
      if (!await originalFile.exists()) return null;

      final directory = await getApplicationDocumentsDirectory();
      final extension = sourcePath.split('.').last;
      final newFileName = 'custom_sign_video_${word.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final persistentFile = await originalFile.copy('${directory.path}/$newFileName');
      
      final upperWord = word.toUpperCase();
      final state = widget.appState;
      if (state.currentProfile!.customSigns.containsKey(upperWord)) {
        final existing = state.currentProfile!.customSigns[upperWord];
        if (existing is Map) {
          final updatedData = Map<String, dynamic>.from(existing);
          updatedData['videoPath'] = persistentFile.path;
          state.updateCustomSign(upperWord, upperWord, updatedData);
        }
      }
      return persistentFile.path;
    } catch (e) {
      debugPrint("Error al copiar el video de la seña personalizada: $e");
      return null;
    }
  }

  void _saveSign() async {
    final word = _wordController.text.trim().toUpperCase();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, escribe una palabra para asociar.')),
      );
      return;
    }

    final state = widget.appState;

    if (widget.initialWord != null && widget.initialWord != word) {
      // Si se editó el nombre de la palabra asociada, eliminamos la anterior de Hive
      state.removeCustomSign(widget.initialWord!);
      
      // Si era una letra predeterminada, restauramos los valores de fábrica en el guante
      if (widget.initialWord!.length == 1 && AppConstants.lspDescriptions.containsKey(widget.initialWord!)) {
        state.sendResetLetterCommand(widget.initialWord!);
      }
    }

    if (_isStatic) {
      // Guardar en Hive
      state.registerCustomSignStatic(
        word,
        _capturedFingerPattern,
        _capturedIsVertical,
        _capturedRawFlexValues,
        imagePath: _selectedImagePath,
      );
      
      // Si es una letra predeterminada, enviar comando BLE SET_LETRA
      if (word.length == 1 && AppConstants.lspDescriptions.containsKey(word)) {
        state.sendSetLetterCommand(word, _capturedFingerPattern, _capturedIsVertical, false, _capturedRawFlexValues);
      }
    } else {
      // Guardar en Hive
      state.registerCustomSignDynamic(
        word,
        _capturedDynamicSamples,
        imagePath: _selectedImagePath,
      );
      
      // Asociar video si está seleccionado
      if (_selectedVideoPath != null) {
        final persistentPath = await _associateVideoToCustomSign(word, _selectedVideoPath!);
        if (persistentPath != null) {
          _selectedVideoPath = persistentPath;
        }
      }

      // Si es una letra predeterminada, calcular patrón inicial de dedos del primer frame grabado
      if (word.length == 1 && AppConstants.lspDescriptions.containsKey(word) && _capturedDynamicSamples.isNotEmpty) {
        final firstSample = _capturedDynamicSamples.first;
        final flexValues = List<int>.from(firstSample.take(5).map((e) => (e as num).toInt()));
        final pattern = state.getFingerPatternFromRaw(flexValues);
        final double ay = firstSample[6] is num ? (firstSample[6] as num).toDouble() : 0.0;
        final bool isVertical = ay.abs() < 6.0;
        
        state.sendSetLetterCommand(word, pattern, isVertical, true, flexValues);
      }
    }

    // Copiar la imagen a una ubicación persistente si es necesario
    if (_selectedImagePath != null && !_selectedImagePath!.contains('/app_flutter/')) {
      await state.associateImageToCustomSign(word, _selectedImagePath!);
    }

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Seña para "$word" guardada con éxito!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          widget.initialWord == null ? 'NUEVA SEÑA' : 'EDITAR SEÑA',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.accent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStepWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET INDICADOR DE PASOS ---
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceLight, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepNode(0, 'Tipo'),
          _buildStepLine(0),
          _buildStepNode(1, 'Captura'),
          _buildStepLine(1),
          _buildStepNode(2, 'Palabra'),
        ],
      ),
    );
  }

  Widget _buildStepNode(int step, String title) {
    bool isCompleted = _currentStep > step;
    bool isActive = _currentStep == step;

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.accent
                : (isCompleted ? AppColors.connected : AppColors.surfaceLight),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: AppColors.background)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? AppColors.background : AppColors.textSecond,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.textPrimary : AppColors.textSecond,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int afterStep) {
    bool isPassed = _currentStep > afterStep;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        height: 2,
        color: isPassed ? AppColors.connected : AppColors.surfaceLight,
      ),
    );
  }

  // --- RENDERIZADO DEL PASO ACTIVO ---
  Widget _buildCurrentStepWidget() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Selector();
      case 1:
        return _buildStep2Capture();
      case 2:
        return _buildStep3Details();
      default:
        return _buildStep1Selector();
    }
  }

  // --- PASO 1: SELECCIONAR TIPO ---
  Widget _buildStep1Selector() {
    return Padding(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'PASO 1: SELECCIONA EL TIPO DE GESTO',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          const Text(
            '¿Qué tipo de seña vas a registrar con tu guante?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecond),
          ),
          const SizedBox(height: 32),
          
          // Tarjeta Estática
          GestureDetector(
            onTap: () {
              setState(() {
                _isStatic = true;
                _currentStep = 1;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _isStatic && _currentStep == 1 ? AppColors.accent : AppColors.surfaceLight, width: 1.5),
              ),
              child: const Row(
                children: [
                  Icon(Icons.back_hand_outlined, color: AppColors.accent, size: 36),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seña Estática', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                        SizedBox(height: 4),
                        Text('Registra una postura fija de los dedos (Ej: Vocales, Letras A, B, C).', style: TextStyle(fontSize: 11, color: AppColors.textSecond, height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tarjeta Dinámica
          GestureDetector(
            onTap: () {
              setState(() {
                _isStatic = false;
                _currentStep = 1;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: !_isStatic && _currentStep == 1 ? AppColors.accent : AppColors.surfaceLight, width: 1.5),
              ),
              child: const Row(
                children: [
                  Icon(Icons.gesture_outlined, color: AppColors.error, size: 36),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seña Dinámica', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                        SizedBox(height: 4),
                        Text('Registra una secuencia de movimiento durante 2 segundos (Ej: Letras J, Z, o palabras en movimiento).', style: TextStyle(fontSize: 11, color: AppColors.textSecond, height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- PASO 2: CAPTURA EN TIEMPO REAL ---
  Widget _buildStep2Capture() {
    final state = widget.appState;

    return ListenableBuilder(
      listenable: state,
      key: const ValueKey(1),
      builder: (context, _) {
        bool isGloveConnected = state.connectionStatus == AppConnectionStatus.connected;
        bool isRecording = state.isRecordingDynamicSign;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isStatic ? 'PASO 2: CAPTURAR POSTURA ESTÁTICA' : 'PASO 2: GRABAR MOVIMIENTO DINÁMICO',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _isStatic
                    ? 'Adopta la postura en el guante y presiona capturar.'
                    : 'Mantén presionado el botón y realiza el movimiento continuo de 2 segundos.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecond),
              ),
              const SizedBox(height: 20),

              // --- VISUALIZADOR EN TIEMPO REAL ---
              HandVisualizer(appState: state),
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
              const SizedBox(height: 24),

              // --- INTERFAZ DE CAPTURA SEGÚN TIPO ---
              if (_isStatic) ...[
                ElevatedButton.icon(
                  onPressed: isGloveConnected ? _captureStaticPattern : null,
                  icon: const Icon(Icons.screenshot_monitor, size: 18),
                  label: const Text('CAPTURAR POSTURA ACTUAL', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ] else ...[
                if (isRecording) ...[
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: state.recordingProgress,
                        backgroundColor: AppColors.surfaceLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.error),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Grabando: ${(state.recordingProgress * 100).round()}%',
                        style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: isGloveConnected ? _startDynamicRecording : null,
                    icon: const Icon(Icons.fiber_manual_record, size: 18, color: Colors.white),
                    label: const Text('INICIAR GRABACIÓN (2s)', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ],

              if (!isGloveConnected) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Debes conectar el guante por Bluetooth.',
                        style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              const Divider(color: AppColors.surfaceLight),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep = 0),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.surfaceLight),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('VOLVER A PASO 1', style: TextStyle(color: AppColors.textSecond, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- PASO 3: FORMULARIO DE DETALLES ---
  Widget _buildStep3Details() {
    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'PASO 3: ASIGNA LA PALABRA Y DETALLES',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Define el significado y añade multimedia de referencia.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textSecond),
          ),
          const SizedBox(height: 24),

          // Campo de Palabra
          TextField(
            controller: _wordController,
            style: const TextStyle(color: AppColors.textPrimary),
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Palabra o Letra asociada',
              labelStyle: TextStyle(color: AppColors.textSecond, fontSize: 13),
              hintText: 'Ej. GRACIAS, AYUDA, A, B',
              hintStyle: TextStyle(color: AppColors.surfaceLight),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.surfaceLight),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.accent),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sección de multimedia
          const Text(
            'MULTIMEDIA DE REFERENCIA (OPCIONAL)',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecond, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _showMediaSourceSheet,
            icon: const Icon(Icons.perm_media, size: 18),
            label: Text(
              (_selectedImagePath == null && _selectedVideoPath == null) ? 'SUBIR FOTO O VIDEO' : 'CAMBIAR MULTIMEDIA',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.accent),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          
          // Preview de Imagen
          if (_selectedImagePath != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kIsWeb
                      ? Image.network(
                          _selectedImagePath!,
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(_selectedImagePath!),
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: 16),
                const Text('Imagen de referencia cargada', style: TextStyle(fontSize: 12, color: AppColors.textSecond, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: AppColors.error),
                  onPressed: () => setState(() => _selectedImagePath = null),
                ),
              ],
            ),
          ],

          // Preview de Video
          if (_selectedVideoPath != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.play_circle_fill, color: AppColors.error, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Video de seña dinámica', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(
                          _selectedVideoPath!.split('/').last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecond),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_arrow, color: AppColors.accent),
                    onPressed: _playVideo,
                    tooltip: 'Reproducir video',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: AppColors.error),
                    onPressed: () => setState(() => _selectedVideoPath = null),
                    tooltip: 'Eliminar video',
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
          const Divider(color: AppColors.surfaceLight),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 1),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.surfaceLight),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('RE-CAPTURAR GESTO', style: TextStyle(color: AppColors.textSecond, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveSign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('GUARDAR SEÑA', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
