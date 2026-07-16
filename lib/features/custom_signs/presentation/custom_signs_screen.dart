import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../core/constants.dart';
import '../../translator/domain/app_state.dart';
import 'create_sign_screen.dart';

class CustomSignsScreen extends StatefulWidget {
  final AppState appState;

  const CustomSignsScreen({super.key, required this.appState});

  @override
  State<CustomSignsScreen> createState() => _CustomSignsScreenState();
}

class _CustomSignsScreenState extends State<CustomSignsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCreateSignScreen({String? initialWord, dynamic initialData}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateSignScreen(
          appState: widget.appState,
          initialWord: initialWord,
          initialData: initialData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.accent,
                labelColor: AppColors.accent,
                unselectedLabelColor: AppColors.textSecond,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                tabs: const [
                  Tab(text: 'PREDETERMINADAS'),
                  Tab(text: 'PERSONALIZADAS'),
                ],
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPredeterminedTab(),
              _buildCustomTab(),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.background,
            onPressed: () => _openCreateSignScreen(),
            tooltip: 'Registrar nueva seña',
            child: const Icon(Icons.add, size: 28),
          ),
        );
      },
    );
  }

  // --- SEÑAS PREDETERMINADAS (A-Z) ---
  Widget _buildPredeterminedTab() {
    final state = widget.appState;
    final customSigns = state.currentProfile?.customSigns ?? {};
    final alphabet = AppConstants.lspDescriptions.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alphabet.length,
      itemBuilder: (context, index) {
        final letter = alphabet[index];
        final description = AppConstants.lspDescriptions[letter] ?? '';
        final isOverridden = customSigns.containsKey(letter);
        final customData = customSigns[letter];
        final imageName = letter == 'Ñ' ? 'N_tilde' : letter;

        return Card(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isOverridden ? AppColors.accent.withOpacity(0.5) : AppColors.surfaceLight,
              width: isOverridden ? 1.5 : 1,
            ),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen de la seña (A-Z)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceLight),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/$imageName.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.image_not_supported_outlined, size: 20, color: AppColors.textSecond),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Detalles de la seña
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Letra $letter',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: 8),
                          if (isOverridden)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                              ),
                              child: const Text(
                                'SOBREESCRITA',
                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.accent),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isOverridden 
                            ? 'Has configurado un gesto personalizado para esta letra.'
                            : description,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecond, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _openCreateSignScreen(
                              initialWord: letter,
                              initialData: customData,
                            ),
                            icon: const Icon(Icons.edit, size: 12),
                            label: Text(
                              isOverridden ? 'RE-GRABAR' : 'PERSONALIZAR',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.background,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                          ),
                          if (isOverridden) ...[
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                state.removeCustomSign(letter);
                                state.sendResetLetterCommand(letter);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Seña "$letter" restaurada a su valor por defecto')),
                                );
                              },
                              icon: const Icon(Icons.restore, size: 12, color: AppColors.error),
                              label: const Text('RESTAURAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.error),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- SEÑAS PERSONALIZADAS (Creadas por el usuario) ---
  Widget _buildCustomTab() {
    final state = widget.appState;
    final customSigns = state.currentProfile?.customSigns ?? {};

    // Filtrar para mostrar señas que no sean letras individuales A-Z, o mostrarlas todas
    // Mostraremos todas las señas creadas por el usuario
    if (customSigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceLight, width: 1.5),
              ),
              child: const Icon(Icons.style_outlined, color: AppColors.textSecond, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aún no has registrado señas.',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            const Text(
              'Usa el botón (+) para crear una seña personalizada.',
              style: TextStyle(color: AppColors.textSecond, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: customSigns.length,
      itemBuilder: (context, index) {
        final String word = customSigns.keys.elementAt(index);
        final rawData = customSigns[word];

        bool isStaticSign = true;
        String subtitleText = '';
        String? imagePath;

        if (rawData is List) {
          final String fingersStr = List<dynamic>.from(rawData.take(5))
              .map((b) => b is bool ? (b ? '2' : '0') : b.toString())
              .join('');
          final bool isVert = rawData.length >= 6 ? rawData[5] as bool : true;
          isStaticSign = rawData.length >= 7 ? rawData[6] as bool : true;
          subtitleText = 'Postura: $fingersStr · ${isVert ? 'Vertical' : 'Horizontal'}';
        } else if (rawData is Map) {
          isStaticSign = rawData['isStatic'] as bool? ?? true;
          imagePath = rawData['imagePath'] as String?;
          if (isStaticSign) {
            final pattern = List<dynamic>.from(rawData['fingerPattern'] as List);
            final String fingersStr = pattern
                .take(5)
                .map((b) => b is bool ? (b ? '2' : '0') : b.toString())
                .join('');
            final bool isVert = rawData['isVertical'] as bool? ?? true;
            subtitleText = 'Postura: $fingersStr · ${isVert ? 'Vertical' : 'Horizontal'}';
          } else {
            final samples = rawData['samples'] as List?;
            subtitleText = 'Seña Dinámica · ${samples?.length ?? 0} muestras de movimiento';
          }
        }

        return Card(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.surfaceLight),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: imagePath != null && (kIsWeb ? (imagePath.startsWith('http') || imagePath.startsWith('blob:')) : File(imagePath).existsSync())
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? Image.network(
                              imagePath,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                            ),
                    )
                  : const Icon(Icons.star, color: AppColors.accent, size: 24),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    word,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isStaticSign ? AppColors.accent.withOpacity(0.08) : AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isStaticSign ? AppColors.accent.withOpacity(0.3) : AppColors.error.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    isStaticSign ? 'ESTÁTICA' : 'DINÁMICA',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isStaticSign ? AppColors.accent : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                subtitleText,
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecond),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.accent),
                  onPressed: () => _openCreateSignScreen(
                    initialWord: word,
                    initialData: rawData,
                  ),
                  tooltip: 'Editar seña',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () {
                    state.removeCustomSign(word);
                    if (word.length == 1 && AppConstants.lspDescriptions.containsKey(word)) {
                      state.sendResetLetterCommand(word);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Seña personalizada "$word" eliminada')),
                    );
                  },
                  tooltip: 'Eliminar seña',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
