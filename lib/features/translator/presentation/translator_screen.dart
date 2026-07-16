import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../calibration/presentation/calibration_screen.dart';
import '../../custom_signs/presentation/custom_signs_screen.dart';
import '../../learning/presentation/learning_screen.dart';
import '../../learning/presentation/login_quiz_dialog.dart';
import '../../profile/domain/profile.dart';
import '../domain/app_state.dart';
import 'lsp_letter_image.dart';
import 'voice_controls.dart';

class MainScreen extends StatefulWidget {
  final AppState appState;

  const MainScreen({super.key, required this.appState});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _letterController;
  late Animation<double> _pulseAnim;
  late Animation<double> _letterAnim;
  int _currentTab = 0;



  AppState get _appState => widget.appState;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _letterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _letterAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _letterController, curve: Curves.elasticOut),
    );

    final isNewUser = _appState.currentProfile != null && _appState.currentProfile!.flexMid[0] == 2600;
    if (isNewUser) {
      _currentTab = 4; // Empezar en Conexión para emparejar y luego calibrar
    }

    _appState.addListener(_onStateChange);

    // Abrir el quiz si se requiere en el primer render de MainScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_appState.showLoginQuizPopup) {
        _appState.showLoginQuizPopup = false;
        LoginQuizDialog.show(context, _appState);
      }
    });
  }

  void _onStateChange() {
    if (_appState.isListening) {
      _letterController.forward(from: 0);
    }

    // Escuchar cambios de estado para abrir el quiz
    if (_appState.showLoginQuizPopup) {
      _appState.showLoginQuizPopup = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        LoginQuizDialog.show(context, _appState);
      });
    }
  }

  void _onTabChanged(int index) {
    final isNewUser = _appState.currentProfile != null && _appState.currentProfile!.flexMid[0] == 2600;
    if (isNewUser && index != 2 && index != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Bienvenido! Primero conecta tu guante y completa la calibración para desbloquear el resto de secciones.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _currentTab = index;
      _appState.isTranslationActive = (index == 0);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _letterController.dispose();

    _appState.removeListener(_onStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildActiveTab(),
                ),
                _buildBottomNav(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveTab() {
    switch (_currentTab) {
      case 0:
        return _buildTranslatorTab();
      case 1:
        return LearningScreen(appState: _appState);
      case 2:
        return CalibrationScreen(appState: _appState);
      case 3:
        return CustomSignsScreen(appState: _appState);
      case 4:
        return _buildConnectionTab();
      default:
        return _buildTranslatorTab();
    }
  }

  void _showPasswordConfirmationDialog(UserProfile p) {
    final passController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xD8FFFFFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Ingresar contraseña para ${p.name}',
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          content: TextField(
            controller: passController,
            obscureText: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Contraseña del perfil',
              labelStyle: TextStyle(color: AppColors.textSecond, fontSize: 13),
              prefixIcon: Icon(Icons.lock_outline, color: AppColors.accent),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.surfaceLight),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.accent),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: AppColors.textSecond, fontSize: 12)),
            ),
            TextButton(
              onPressed: () {
                if (_appState.verifyProfilePassword(p, passController.text)) {
                  _appState.login(p);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sesión iniciada como ${p.name}')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contraseña incorrecta. Acceso denegado.')),
                  );
                }
              },
              child: const Text('INGRESAR', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        );
      },
    );
  }

  void _showProfileOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xD8FFFFFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Perfil de Usuario',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sesión iniciada como:',
                style: TextStyle(color: AppColors.textSecond, fontSize: 11),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.accent.withOpacity(0.15),
                    child: const Icon(Icons.person, color: AppColors.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _appState.currentProfile?.name ?? 'Estándar',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.surfaceLight, height: 1),
              const SizedBox(height: 12),
              const Text(
                'Cambiar de perfil:',
                style: TextStyle(color: AppColors.textSecond, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_appState.profiles.length <= 1)
                const Text(
                  'No hay otros perfiles creados.',
                  style: TextStyle(color: AppColors.textSecond, fontSize: 11, fontStyle: FontStyle.italic),
                )
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _appState.profiles
                          .where((p) => p.id != _appState.currentProfile?.id)
                          .map((p) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  leading: const Icon(Icons.person_outline, color: AppColors.textSecond, size: 16),
                                  title: Text(p.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                                  onTap: () {
                                    Navigator.pop(context); // Cerrar diálogo principal
                                    _showPasswordConfirmationDialog(p);
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _appState.logout();
                Navigator.pop(context);
              },
              child: const Text(
                'CERRAR SESIÓN',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CERRAR',
                style: TextStyle(color: AppColors.textSecond, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/maki_voice_logo_transparent.png',
            height: 40,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          _buildStreakBadge(),
          if (_appState.currentProfile != null && (_appState.currentProfile?.quizStreak ?? 0) > 0)
            const SizedBox(width: 8),
          _buildConnectionBadge(),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.account_circle, color: AppColors.accent, size: 28),
            onPressed: _showProfileOptionsDialog,
            tooltip: 'Opciones de Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBadge() {
    final streak = _appState.currentProfile?.quizStreak ?? 0;
    if (streak == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentDim.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accentDim,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$streak ',
            style: const TextStyle(
              color: AppColors.accentDim,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            '🔥',
            style: TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionBadge() {
    final isConnected = _appState.connectionStatus == AppConnectionStatus.connected;
    final isScanning = _appState.connectionStatus == AppConnectionStatus.scanning;

    return GestureDetector(
      onTap: () => _onTabChanged(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isConnected
              ? AppColors.accent.withOpacity(0.15)
              : AppColors.error.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isConnected ? AppColors.accent : AppColors.error,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            if (isScanning)
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.textSecond,
                ),
              )
            else
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Transform.scale(
                  scale: isConnected ? _pulseAnim.value : 1.0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected
                          ? AppColors.connected
                          : AppColors.disconnected,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 7),
            Text(
              isConnected
                  ? _appState.deviceName.split(' ').first // Recortar si nombre muy largo
                  : isScanning
                      ? 'Buscando...'
                      : 'Sin conexión',
              style: TextStyle(
                color: isConnected ? AppColors.accent : AppColors.error,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── TAB 0: TRADUCTOR ──────────────────────────────────────────────────────
  Widget _buildTranslatorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          if (_appState.repeatMeTargetLetter != null) _buildRepeatAfterMeBanner(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: LspLetterImage(
                  letter: _appState.currentLetter,
                  size: 130,
                  customImagePath: () {
                    final clean = _appState.currentLetter.trim().toUpperCase();
                    final signData = _appState.currentProfile?.customSigns[clean];
                    if (signData is Map) {
                      return signData['imagePath'] as String?;
                    }
                    return null;
                  }(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCurrentLetterCard(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Barra de sugerencias de autocompletado en tiempo real
          if (_appState.suggestions.isNotEmpty) _buildSuggestionsBar(),
          
          _buildTextArea(),
          const SizedBox(height: 16),
          VoiceControls(appState: _appState),
        ],
      ),
    );
  }

  Widget _buildRepeatAfterMeBanner() {
    if (_appState.repeatMeTargetLetter == null) return const SizedBox.shrink();

    final letter = _appState.repeatMeTargetLetter!;
    final imageName = letter == 'Ñ' ? 'N_tilde' : letter;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent, // Sapphire blue
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/$imageName.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.image_not_supported_outlined, size: 24, color: AppColors.textSecond),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Intenta hacerla tú también!',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Seña detectada: $letter\nImita este gesto con tu mano para practicar.',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsBar() {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _appState.suggestions.length,
        itemBuilder: (context, i) {
          final sugg = _appState.suggestions[i];
          return GestureDetector(
            onTap: () => _appState.applySuggestion(sugg),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.accent.withOpacity(0.5), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, size: 13, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text(
                    sugg,
                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentLetterCard() {
    return Container(
      height: 170, // Matches LspLetterImage size: 130 (total height = size + 40 = 170)
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceLight,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('SEÑA DETECTADA',
              style: TextStyle(
                color: AppColors.textSecond,
                fontSize: 9,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _letterAnim,
            builder: (_, __) {
              return Transform.scale(
                scale: 0.8 + (_letterAnim.value * 0.2),
                child: Opacity(
                  opacity: _letterAnim.value.clamp(0.0, 1.0),
                  child: Text(
                    _appState.currentLetter.isEmpty ? '—' : _appState.currentLetter,
                    style: TextStyle(
                      color: _appState.currentLetter.isEmpty ? AppColors.textSecond : AppColors.accent,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextArea() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(20),
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
              const Text('TEXTO TRADUCIDO',
                  style: TextStyle(
                    color: AppColors.textSecond,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  )),
              Row(
                children: [
                  _buildTextIconButton(
                    icon: Icons.backspace_outlined,
                    tooltip: 'Borrar última letra',
                    onTap: _appState.deleteLastChar,
                  ),
                  const SizedBox(width: 8),
                  _buildTextIconButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Limpiar todo',
                    color: AppColors.error,
                    onTap: _appState.clearText,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _appState.translatedText.isEmpty
              ? Text(
                  'Enciende y conecta el guante para empezar a traducir señas...',
                  style: TextStyle(
                    color: AppColors.textSecond.withOpacity(0.4),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : RichText(
                  text: TextSpan(
                    children: _buildHighlightedText(_appState.translatedText),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildTextIconButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: (color ?? AppColors.accent).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (color ?? AppColors.accent).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color ?? AppColors.accent,
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildHighlightedText(String text) {
    if (text.isEmpty) return [];
    if (text.length == 1) {
      return [
        TextSpan(
          text: text,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ];
    }
    return [
      TextSpan(
        text: text.substring(0, text.length - 1),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
      TextSpan(
        text: text[text.length - 1],
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    ];
  }



  // ── TAB 3: CONEXIÓN BLUETOOTH ─────────────────────────────────────────────
  Widget _buildConnectionTab() {
    final isConnected = _appState.connectionStatus == AppConnectionStatus.connected;
    final isScanning = _appState.connectionStatus == AppConnectionStatus.scanning;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESTADO BLUETOOTH BLE',
            style: TextStyle(
              color: AppColors.textSecond,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          if (!isConnected) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bluetooth_disabled, color: AppColors.textSecond, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Guante Desconectado: Conecte el guante via bluetooth',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (isConnected) ...[
            _buildConnectedCard(),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                if (_appState.deviceName.contains("Simulado")) {
                  _appState.stopMockSequence();
                } else {
                  _appState.disconnect();
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.error.withOpacity(0.5), width: 1),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bluetooth_disabled,
                      color: AppColors.error,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'DESCONECTAR GUANTE',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Botón Buscar
            GestureDetector(
              onTap: isScanning ? null : _appState.scanDevices,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isScanning ? AppColors.surface : AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isScanning ? AppColors.surfaceLight : AppColors.accent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isScanning ? Icons.sync : Icons.bluetooth_searching,
                      color: isScanning ? AppColors.textSecond : AppColors.accent,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isScanning 
                          ? 'BUSCANDO DISPOSITIVOS...' 
                          : (_appState.hasSearchedOnce ? 'BUSCAR DE NUEVO' : 'BUSCAR GUANTE'),
                      style: TextStyle(
                        color: isScanning ? AppColors.textSecond : AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Lista de dispositivos encontrados
            if (isScanning || _appState.scannedDevices.isNotEmpty) ...[
              const Text('DISPOSITIVOS ENCONTRADOS:', style: TextStyle(fontSize: 11, color: AppColors.textSecond)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _appState.scannedDevices.length,
                  itemBuilder: (context, i) {
                    final dev = _appState.scannedDevices[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceLight),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          title: Text(
                            dev.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          subtitle: Text(dev.id, style: const TextStyle(fontSize: 10, color: AppColors.textSecond)),
                          trailing: const Icon(Icons.link, color: AppColors.accent),
                          onTap: () => _appState.connectToDevice(dev),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              _buildInstructionsCard(),
              const SizedBox(height: 24),
              // Botón Simulación Guante
              GestureDetector(
                onTap: _appState.startMockSequence,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceLight, width: 1.5),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.science, color: AppColors.textSecond, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'SIMULAR GUANTE (DEMO MOCK)',
                        style: TextStyle(
                          color: AppColors.textSecond,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildConnectedCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bluetooth_connected,
              color: AppColors.accent,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _appState.deviceName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Guante conectado por BLE. Transmitiendo.',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    final steps = [
      'Enciende el ESP32 de tu guante.',
      'Asegúrate de tener el Bluetooth encendido en el celular.',
      'Presiona BUSCAR GUANTE para detectar el dispositivo BLE.',
      'Selecciona "GuanteLSP" para sincronizar automáticamente.',
      'Si aún no tienes el hardware, usa el botón de SIMULAR GUANTE abajo.',
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instrucciones de conexión',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...steps.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(
                          color: AppColors.textSecond,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── BOTTOM NAV ────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final isNewUser = _appState.currentProfile != null && _appState.currentProfile!.flexMid[0] == 2600;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.6),
            border: Border(top: BorderSide(color: AppColors.surfaceLight.withOpacity(0.6))),
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.translate,
                label: 'TRADUCIR',
                isActive: _currentTab == 0,
                onTap: isNewUser ? () => _onTabChanged(0) : () => _onTabChanged(0),
                isDisabled: isNewUser,
              ),
              _NavItem(
                icon: Icons.school,
                label: 'APRENDER',
                isActive: _currentTab == 1,
                onTap: isNewUser ? () => _onTabChanged(1) : () => _onTabChanged(1),
                isDisabled: isNewUser,
              ),
              _NavItem(
                icon: Icons.tune,
                label: 'CALIBRAR',
                isActive: _currentTab == 2,
                onTap: () => _onTabChanged(2),
              ),
              _NavItem(
                icon: Icons.style,
                label: 'SEÑAS',
                isActive: _currentTab == 3,
                onTap: isNewUser ? () => _onTabChanged(3) : () => _onTabChanged(3),
                isDisabled: isNewUser,
              ),
              _NavItem(
                icon: Icons.bluetooth,
                label: 'CONEXIÓN',
                isActive: _currentTab == 4,
                onTap: () => _onTabChanged(4),
                badge: _appState.connectionStatus != AppConnectionStatus.connected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textSecond,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                )),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool badge;
  final bool isDisabled;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = isActive
        ? AppColors.accent
        : (isDisabled ? AppColors.textSecond.withOpacity(0.25) : AppColors.textSecond.withOpacity(0.6));

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: displayColor,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: displayColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (badge && !isDisabled)
                Positioned(
                  top: 2,
                  right: 22,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
