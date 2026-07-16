import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../translator/domain/app_state.dart';
import '../domain/profile.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool _isLoginMode = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  UserProfile? _selectedProfile;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    
    // Seleccionar el primer perfil por defecto si existe
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<AppState>(context, listen: false);
      if (state.profiles.isNotEmpty) {
        setState(() {
          _selectedProfile = state.profiles.first;
          _passwordController.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _nameController.clear();
      _passwordController.clear();
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  void _handleAuthSubmit(AppState state) {
    if (_isLoginMode) {
      if (_selectedProfile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecciona o crea un perfil.')),
        );
        return;
      }
      final password = _passwordController.text;
      if (!state.verifyProfilePassword(_selectedProfile!, password)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña incorrecta. Inténtalo de nuevo.')),
        );
        return;
      }
      state.login(_selectedProfile!);
    } else {
      final name = _nameController.text.trim();
      final password = _passwordController.text;
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, ingresa tu nombre.')),
        );
        return;
      }
      if (password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, ingresa una contraseña.')),
        );
        return;
      }
      state.createProfile(name, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final profiles = state.profiles;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── LOGO MAKI VOICE TRANSPARENTE ─────────────────────────────
                Image.asset(
                  'assets/images/maki_voice_logo_transparent.png',
                  width: 320,
                  height: 160,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Traductor de Lengua de Señas Peruana',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecond,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 36),

                // ── SELECCIÓN DE PESTAÑA (LOGIN / REGISTRO) ──────────────────
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.surfaceLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!_isLoginMode) {
                              _toggleMode();
                              if (profiles.isNotEmpty) {
                                _selectedProfile = profiles.first;
                              }
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isLoginMode ? AppColors.accent : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Center(
                              child: Text(
                                'INGRESAR',
                                style: TextStyle(
                                  color: _isLoginMode ? AppColors.background : AppColors.textSecond,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_isLoginMode) _toggleMode();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isLoginMode ? AppColors.accent : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Center(
                              child: Text(
                                'REGISTRARSE',
                                style: TextStyle(
                                  color: !_isLoginMode ? AppColors.background : AppColors.textSecond,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── ANIMACIÓN DE TRANSICIÓN CONTENIDO ────────────────────────
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _isLoginMode
                      ? _buildLoginView(profiles, state)
                      : _buildRegisterView(),
                ),

                const SizedBox(height: 32),

                // ── BOTÓN DE ACCIÓN PRINCIPAL ────────────────────────────────
                ElevatedButton(
                  onPressed: () => _handleAuthSubmit(state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 64),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                    shadowColor: AppColors.accent.withOpacity(0.4),
                  ),
                  child: Text(
                    _isLoginMode ? 'INICIAR SESIÓN' : 'CREAR E INGRESAR',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginView(List<UserProfile> profiles, AppState state) {
    if (profiles.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: const Column(
          children: [
            Icon(Icons.person_off_rounded, color: AppColors.textSecond, size: 48),
            SizedBox(height: 12),
            Text(
              'No hay perfiles registrados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Registra tu nombre en la pestaña superior derecha para continuar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecond,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SELECCIONA TU PERFIL',
              style: TextStyle(
                color: AppColors.textSecond,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accentDim.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accentDim.withOpacity(0.3), width: 0.5),
              ),
              child: const Text(
                'Prueba: TEST (Contraseña: 123)',
                style: TextStyle(
                  color: AppColors.accentDim,
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final p = profiles[index];
              final isSel = _selectedProfile?.id == p.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.accent.withOpacity(0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSel ? AppColors.accent : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: CircleAvatar(
                      backgroundColor: isSel
                          ? AppColors.accent.withOpacity(0.2)
                          : AppColors.surfaceLight,
                      child: Icon(
                        Icons.person,
                        color: isSel ? AppColors.accent : AppColors.textSecond,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      p.name,
                      style: TextStyle(
                        color: isSel ? AppColors.accent : AppColors.textPrimary,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Gestos: ${p.customSigns.length}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecond),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                      onPressed: () {
                        state.deleteProfile(p.id);
                        if (_selectedProfile?.id == p.id) {
                          setState(() {
                            _selectedProfile = state.profiles.isNotEmpty
                                ? state.profiles.first
                                : null;
                            _passwordController.clear();
                          });
                        }
                      },
                    ),
                    onTap: () {
                      setState(() {
                        _selectedProfile = p;
                        _passwordController.clear();
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
        if (_selectedProfile != null) ...[
          const SizedBox(height: 20),
          const Text(
            'CONTRASEÑA DEL PERFIL',
            style: TextStyle(
              color: AppColors.textSecond,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Introduce la contraseña',
                labelStyle: TextStyle(color: AppColors.textSecond, fontSize: 13),
                prefixIcon: Icon(Icons.lock_outline, color: AppColors.accent),
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
          ),
        ],
      ],
    );
  }

  Widget _buildRegisterView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'REGISTRAR NUEVO USUARIO',
          style: TextStyle(
            color: AppColors.textSecond,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                textCapitalization: TextCapitalization.words,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Nombre del usuario',
                  labelStyle: TextStyle(color: AppColors.textSecond, fontSize: 13),
                  hintText: 'Ej. Juan, María',
                  hintStyle: TextStyle(color: AppColors.surfaceLight),
                  counterStyle: TextStyle(color: AppColors.textSecond, fontSize: 9),
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.accent),
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
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Establecer contraseña',
                  labelStyle: TextStyle(color: AppColors.textSecond, fontSize: 13),
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.accent),
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
            ],
          ),
        ),
      ],
    );
  }
}
