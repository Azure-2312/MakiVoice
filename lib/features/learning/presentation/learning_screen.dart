import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../core/constants.dart';
import '../../translator/domain/app_state.dart';
import 'login_quiz_dialog.dart';

class LearningScreen extends StatefulWidget {
  final AppState appState;

  const LearningScreen({super.key, required this.appState});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _historyType = 'Quiz';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── PESTAÑAS DE APRENDIZAJE ──────────────────────────────────────────
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textSecond,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
            tabs: const [
              Tab(text: 'RUTA NIVELES'),
              Tab(text: 'GLOSARIO LSP'),
              Tab(text: 'HISTORIAL'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLevelsRoute(),
              _buildGlossaryTab(),
              _buildQuizHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ── RUTA DE APRENDIZAJE POR NIVELES ──────────────────────────────────────
  Widget _buildLevelsRoute() {
    final currentLevel = widget.appState.currentProfile?.learningLevel ?? 1;

    final levels = [
      {
        'num': 1,
        'title': 'Nivel 1: Las Vocales',
        'desc': 'Domina las señas de las letras A, E, I, O, U.',
        'items': ['A', 'E', 'I', 'O', 'U'],
      },
      {
        'num': 2,
        'title': 'Nivel 2: Consonantes Simples',
        'desc': 'Aprende las consonantes más utilizadas del abecedario.',
        'items': ['B', 'C', 'D', 'F', 'G', 'H', 'L', 'M', 'N', 'P', 'S', 'T', 'V', 'W', 'Y'],
      },
      {
        'num': 3,
        'title': 'Nivel 3: Consonantes Complejas',
        'desc': 'Gesto, inclinación y movimiento (J, K, Ñ, Q, R, X, Z).',
        'items': ['J', 'K', 'Ñ', 'Q', 'R', 'X', 'Z'],
      },
      {
        'num': 4,
        'title': 'Nivel 4: Palabras Cortas',
        'desc': 'Deletreo de palabras con respuestas visuales en señas.',
        'items': ['HOLA', 'ADIOS', 'BAÑO', 'AGUA', 'CASA', 'AMIGO'],
      },
      {
        'num': 5,
        'title': 'Nivel 5: Frases Útiles',
        'desc': 'Deletreo de frases útiles con respuestas visuales en señas.',
        'items': ['BUENOS DIAS', 'COMO ESTAS', 'NECESITO AYUDA', 'POR FAVOR'],
      },
      {
        'num': 6,
        'title': 'Nivel 6: Deletreo Corto (2-3 Letras)',
        'desc': 'Identifica la secuencia de señas correcta para palabras cortas.',
        'items': ['SOL', 'PAN', 'DIA', 'MAR', 'CON', 'UNO', 'DOS'],
      },
      {
        'num': 7,
        'title': 'Nivel 7: Deletreo Corto II (2-3 Letras)',
        'desc': 'Continúa practicando secuencias de señas para palabras cortas.',
        'items': ['RIO', 'MIL', 'MAS', 'SIN', 'VER', 'DAR', 'SER'],
      },
      {
        'num': 8,
        'title': 'Nivel 8: Deletreo Intermedio (4-5 Letras)',
        'desc': 'Identifica la secuencia de señas correcta para palabras medianas.',
        'items': ['CASA', 'MESA', 'GATO', 'PINO', 'MANO', 'LIBRO', 'AMIGO'],
      },
      {
        'num': 9,
        'title': 'Nivel 9: Descifrar Señas a Texto',
        'desc': 'Mira la secuencia de señas en pantalla y descifra la palabra correcta.',
        'items': ['SOL', 'PAN', 'DIA', 'RIO', 'MIL', 'MAS', 'VER', 'DAR', 'CON', 'UNO'],
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: levels.length,
      itemBuilder: (context, i) {
        final level = levels[i];
        final levelNum = level['num'] as int;
        final isLocked = levelNum > currentLevel;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isLocked ? AppColors.surface.withOpacity(0.5) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLocked ? AppColors.surfaceLight : AppColors.accent.withOpacity(0.2),
              width: isLocked ? 1.0 : 1.5,
            ),
            boxShadow: isLocked
                ? []
                : [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono de Estado de Nivel
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLocked
                        ? AppColors.surfaceLight.withOpacity(0.5)
                        : (levelNum < currentLevel
                            ? AppColors.connected.withOpacity(0.12)
                            : AppColors.accent.withOpacity(0.12)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLocked
                        ? Icons.lock_outline
                        : (levelNum < currentLevel ? Icons.check : Icons.play_arrow),
                    color: isLocked
                        ? AppColors.textSecond.withOpacity(0.5)
                        : (levelNum < currentLevel ? AppColors.connected : AppColors.accent),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level['title'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isLocked ? AppColors.textSecond.withOpacity(0.6) : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        level['desc'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecond.withOpacity(isLocked ? 0.5 : 0.8),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (!isLocked)
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _showStudyDialog(level['title'] as String, level['items'] as List<String>, levelNum <= 3),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surfaceLight,
                                foregroundColor: AppColors.textPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: const Text('ESTUDIAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _startLevelExam(levelNum, level['items'] as List<String>, levelNum <= 3),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: AppColors.surface,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: const Text('DAR EXAMEN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ),
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

  // ── MODO ESTUDIO: DETALLE DEL NIVEL ──────────────────────────────────────
  void _showStudyDialog(String title, List<String> items, bool isLetters) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xD8FFFFFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          content: SizedBox(
            width: double.maxFinite,
            height: 380,
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, idx) {
                final item = items[idx];
                final desc = isLetters ? (AppConstants.lspDescriptions[item] ?? 'Seña estándar de abecedario.') : 'Se deletrea letra a letra.';
                return Card(
                  color: AppColors.background,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.surfaceLight),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        if (isLetters) ...[
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.surfaceLight),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/images/${item == 'Ñ' ? 'N_tilde' : item}.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.image_not_supported_outlined, size: 24, color: AppColors.textSecond),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.accent),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                desc,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecond),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CERRAR', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ── EXAMEN DE NIVEL ──────────────────────────────────────────────────────
  void _startLevelExam(int levelNum, List<String> items, bool isLetters) {
    List<QuizQuestion> examQuestions = [];
    final random = Random();

    if (levelNum == 1 || levelNum == 2 || levelNum == 3) {
      // Niveles 1, 2, 3: Identificar letra individual a partir de imagen (pregunta: imagen -> respuestas: letras)
      final List<String> shuffledItems = List<String>.from(items)..shuffle();
      for (int i = 0; i < min(5, shuffledItems.length); i++) {
        final String correctLetter = shuffledItems[i];
        
        final List<String> falseOptions = AppConstants.lspDescriptions.keys
            .where((letter) => letter != correctLetter)
            .toList();
        falseOptions.shuffle();

        final options = [correctLetter, falseOptions[0], falseOptions[1], falseOptions[2]];
        options.shuffle();

        examQuestions.add(QuizQuestion(
          imageName: correctLetter == 'Ñ' ? 'N_tilde' : correctLetter,
          questionText: '¿Qué letra representa esta seña del guante?',
          options: options,
          correctIndex: options.indexOf(correctLetter),
        ));
      }
    } else if (levelNum == 4 || levelNum == 5) {
      // Niveles 4, 5: Identificar imagen de seña para posición específica de palabra (pregunta: texto -> respuestas: imágenes de señas)
      final List<String> shuffledItems = List<String>.from(items)..shuffle();
      for (int i = 0; i < min(5, shuffledItems.length); i++) {
        final String targetWordStr = shuffledItems[i];
        final String targetWord = targetWordStr.replaceAll(' ', '');
        final int charPos = random.nextInt(3); // 0 = primera, 1 = última, 2 = intermedia
        String positionName;
        int targetIdx;
        
        if (charPos == 0 || targetWord.length <= 2) {
          positionName = 'primera';
          targetIdx = 0;
        } else if (charPos == 1) {
          positionName = 'última';
          targetIdx = targetWord.length - 1;
        } else {
          positionName = 'letra intermedia';
          targetIdx = random.nextInt(targetWord.length - 2) + 1; // index 1 a len-2
        }
        
        final String correctChar = targetWord[targetIdx];
        final List<String> falseOptions = AppConstants.lspDescriptions.keys
            .where((c) => c != correctChar)
            .toList();
        falseOptions.shuffle();
        
        final options = [correctChar, falseOptions[0], falseOptions[1], falseOptions[2]];
        options.shuffle();
        
        examQuestions.add(QuizQuestion(
          imageName: '',
          questionText: 'En base a la palabra/frase "$targetWordStr", ¿cuál es la seña que representa la $positionName ("$correctChar")?',
          options: options,
          optionsAreImages: true,
          correctIndex: options.indexOf(correctChar),
        ));
      }
    } else if (levelNum == 6 || levelNum == 7 || levelNum == 8) {
      // Niveles 6, 7, 8: Deletreo con secuencias de imágenes (pregunta: palabra texto -> respuestas: secuencias de imágenes)
      final List<String> shuffledItems = List<String>.from(items)..shuffle();
      for (int i = 0; i < min(5, shuffledItems.length); i++) {
        final String targetWord = shuffledItems[i].toUpperCase();
        final int len = targetWord.length;
        
        final String correctSeq = targetWord.split('').join(',');
        
        final List<String> otherSameLengthWords = items
            .map((w) => w.toUpperCase())
            .where((w) => w != targetWord && w.length == len)
            .toList();
        otherSameLengthWords.shuffle();
        
        final List<String> falseSeqs = [];
        for (int k = 0; k < 3; k++) {
          if (k < otherSameLengthWords.length) {
            falseSeqs.add(otherSameLengthWords[k].split('').join(','));
          } else {
            final List<String> randomChars = [];
            final keys = AppConstants.lspDescriptions.keys.toList();
            for (int j = 0; j < len; j++) {
              randomChars.add(keys[random.nextInt(keys.length)]);
            }
            falseSeqs.add(randomChars.join(','));
          }
        }
        
        final options = [correctSeq, falseSeqs[0], falseSeqs[1], falseSeqs[2]];
        options.shuffle();
        
        examQuestions.add(QuizQuestion(
          imageName: '',
          questionText: '¿Cuál de las siguientes secuencias de señas deletrea correctamente la palabra "$targetWord"?',
          options: options,
          optionsAreImageSequences: true,
          correctIndex: options.indexOf(correctSeq),
        ));
      }
    } else if (levelNum == 9) {
      // Nivel 9: Descifrar señas a texto (pregunta: secuencias de imágenes -> respuestas: palabras de 3 letras en texto)
      final List<String> shuffledItems = List<String>.from(items)..shuffle();
      for (int i = 0; i < min(5, shuffledItems.length); i++) {
        final String targetWord = shuffledItems[i].toUpperCase();
        final List<String> questionImages = targetWord.split('');
        
        final List<String> otherWords = items
            .map((w) => w.toUpperCase())
            .where((w) => w != targetWord && w.length == targetWord.length)
            .toList();
        otherWords.shuffle();
        
        final List<String> falseOptions = [];
        for (int k = 0; k < 3; k++) {
          if (k < otherWords.length) {
            falseOptions.add(otherWords[k]);
          } else {
            final keys = AppConstants.lspDescriptions.keys.toList();
            falseOptions.add('${keys[random.nextInt(keys.length)]}${keys[random.nextInt(keys.length)]}${keys[random.nextInt(keys.length)]}');
          }
        }
        
        final options = [targetWord, falseOptions[0], falseOptions[1], falseOptions[2]];
        options.shuffle();
        
        examQuestions.add(QuizQuestion(
          questionImages: questionImages,
          questionText: 'Descifra la palabra de ${targetWord.length} letras escrita en señas:',
          options: options,
          correctIndex: options.indexOf(targetWord),
        ));
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamPlayScreen(
          questions: examQuestions,
          levelNum: levelNum,
          appState: widget.appState,
        ),
      ),
    ).then((_) {
      setState(() {});
    });
  }



  // DIÁLOGO DE JUEGO DEL QUIZ (COMÚN EXAMEN Y GENERAL)
  void _showQuizPlayDialog(List<QuizQuestion> questions, {required bool isExam, int levelNum = 0}) {
    int currentIdx = 0;
    int score = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isFinished = currentIdx >= questions.length;

            if (isFinished) {
              final approved = score >= 4;

              if (isExam && approved) {
                // Desbloquear nivel
                widget.appState.unlockNextLevel(levelNum);
              }

              return AlertDialog(
                backgroundColor: const Color(0xD8FFFFFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text(
                  isExam ? 'Resultados del Examen' : 'Quiz Completado',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      approved ? Icons.stars : Icons.sentiment_neutral_outlined,
                      color: approved ? AppColors.connected : AppColors.error,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      approved ? '¡Excelente trabajo!' : 'Sigue practicando',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: approved ? AppColors.connected : AppColors.error),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Puntuación final: $score de ${questions.length} correctas.',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    if (isExam)
                      Text(
                        approved
                            ? 'Has desbloqueado exitosamente el siguiente nivel.'
                            : 'Necesitas al menos 4 de 5 respuestas correctas para desbloquear el siguiente nivel.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecond, height: 1.4),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {}); // Actualiza la pantalla de niveles
                    },
                    child: const Text('SALIR', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            }

            final currentQuestion = questions[currentIdx];

            return AlertDialog(
              backgroundColor: const Color(0xD8FFFFFF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isExam ? 'Examen Nivel $levelNum' : 'Quiz General',
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecond, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Pregunta ${currentIdx + 1} de ${questions.length}',
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
                  if (currentQuestion.questionImages.isNotEmpty) ...[
                    Container(
                      height: 120,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceLight),
                      ),
                      child: Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: currentQuestion.questionImages.map((l) {
                              final img = l == 'Ñ' ? 'N_tilde' : l;
                              return Container(
                                width: 70,
                                height: 90,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.surfaceLight),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    'assets/images/$img.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Center(child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  ),
                                ),
                              );
                            }).toList(),
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
                          if (optIdx == currentQuestion.correctIndex) {
                            score++;
                          }
                          setDialogState(() {
                            currentIdx++;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.surfaceLight),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _buildOptionContent(currentQuestion, option),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── GLOSARIO VISUAL DE ABECEDARIO LSP (TAB 3) ───────────────────────────
  Widget _buildGlossaryTab() {
    final List<String> keys = AppConstants.lspDescriptions.keys.toList();
    final filteredKeys = keys.where((k) {
      if (_searchQuery.isEmpty) return true;
      return k.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (AppConstants.lspDescriptions[k] ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Barra de Búsqueda
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.textPrimary),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar letra o palabras clave...',
              hintStyle: const TextStyle(color: AppColors.textSecond, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecond),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.surfaceLight),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.accent),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // Lista de Letras
        Expanded(
          child: filteredKeys.isEmpty
              ? const Center(
                  child: Text(
                    'No se encontraron coincidencias.',
                    style: TextStyle(color: AppColors.textSecond, fontSize: 13),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filteredKeys.length,
                  itemBuilder: (context, idx) {
                    final letter = filteredKeys[idx];
                    return GestureDetector(
                      onTap: () => _showGlossaryDetail(letter),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceLight),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/images/${letter == 'Ñ' ? 'N_tilde' : letter}.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.image_not_supported_outlined, size: 20, color: AppColors.textSecond),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              letter,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showGlossaryDetail(String letter) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xD8FFFFFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceLight),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/${letter == 'Ñ' ? 'N_tilde' : letter}.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.image_not_supported_outlined, size: 48, color: AppColors.textSecond),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Letra: $letter',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.accent),
              ),
              const SizedBox(height: 12),
              Text(
                AppConstants.lspDescriptions[letter] ?? 'Seña estándar de abecedario LSP.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ENTENDIDO', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuizHistoryTab() {
    final profile = widget.appState.currentProfile;
    final quizHistory = profile?.quizHistory ?? [];
    final examHistory = profile?.examHistory ?? [];
    final streak = profile?.quizStreak ?? 0;

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final alreadyDoneToday = profile?.lastQuizDate == todayStr;

    final activeHistory = _historyType == 'Quiz' ? quizHistory : examHistory;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de tipo de historial
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _historyType = 'Quiz';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _historyType == 'Quiz' ? AppColors.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'QUIZZES',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: _historyType == 'Quiz' ? AppColors.background : AppColors.textSecond,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _historyType = 'Exámenes';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _historyType == 'Exámenes' ? AppColors.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'EXÁMENES',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: _historyType == 'Exámenes' ? AppColors.background : AppColors.textSecond,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_historyType == 'Quiz') ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'Racha de Quizzes',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecond),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.local_fire_department, color: AppColors.accentDim, size: 18),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$streak ${streak == 1 ? "día" : "días"}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alreadyDoneToday
                              ? '¡Quiz de hoy completado! Regresa mañana.'
                              : 'Aún no has resuelto el quiz de hoy.',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecond),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => LoginQuizDialog(appState: widget.appState),
                      ).then((_) {
                        setState(() {});
                      });
                    },
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('NUEVO QUIZ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.surface,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          Text(
            _historyType == 'Quiz' ? 'HISTORIAL DE EVALUACIONES (QUIZ)' : 'HISTORIAL DE EVALUACIONES (EXÁMENES)',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecond,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          if (activeHistory.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.assignment_outlined, size: 48, color: AppColors.textSecond.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text(
                      _historyType == 'Quiz' ? 'No hay quizzes registrados' : 'No hay exámenes registrados',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecond, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _historyType == 'Quiz'
                          ? 'Resuelve tu primer quiz diario para empezar tu historial.'
                          : 'Realiza tu primer examen de nivel para empezar tu historial.',
                      style: const TextStyle(color: AppColors.textSecond, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeHistory.length,
              itemBuilder: (context, idx) {
                final quiz = activeHistory[activeHistory.length - 1 - idx];
                final date = quiz['date'] as String;
                final score = quiz['score'] as int;
                final total = quiz['total'] as int;
                final approved = _historyType == 'Quiz' ? score >= 3 : score >= 4;
                final int? examLevel = quiz['levelNum'] as int?;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.surfaceLight),
                  ),
                  elevation: 0,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: approved ? AppColors.connected.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        approved ? Icons.check_circle_outline : Icons.highlight_off,
                        color: approved ? AppColors.connected : AppColors.error,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      _historyType == 'Quiz' ? 'Quiz del $date' : 'Examen Nivel $examLevel del $date',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Puntaje: $score / $total (${(score / total * 100).round()}% de aciertos)',
                      style: const TextStyle(color: AppColors.textSecond, fontSize: 11),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textSecond),
                    onTap: () => _showQuizDetailDialog(quiz),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOptionContent(QuizQuestion q, String option, {Color? textColor}) {
    if (q.optionsAreImages) {
      final img = option == 'Ñ' ? 'N_tilde' : option;
      return Container(
        height: 36,
        padding: const EdgeInsets.all(2),
        child: Image.asset(
          'assets/images/$img.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Text(option, style: TextStyle(color: textColor ?? AppColors.textPrimary)),
        ),
      );
    } else if (q.optionsAreImageSequences) {
      final letters = option.split(',');
      return Wrap(
        spacing: 4,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: letters.map((l) {
          final img = l == 'Ñ' ? 'N_tilde' : l;
          return Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                'assets/images/$img.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(child: Text(l, style: const TextStyle(fontSize: 8))),
              ),
            ),
          );
        }).toList(),
      );
    } else {
      return Text(
        option,
        style: TextStyle(color: textColor ?? AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
      );
    }
  }

  void _showQuizDetailDialog(Map<String, dynamic> quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizDetailScreen(quiz: quiz),
      ),
    );
  }
}

// Clase Auxiliar para Preguntas
class QuizQuestion {
  final String imageName;
  final List<String> questionImages;
  final String questionText;
  final List<String> options;
  final bool optionsAreImages;
  final bool optionsAreImageSequences;
  final int correctIndex;

  QuizQuestion({
    this.imageName = '',
    this.questionImages = const [],
    required this.questionText,
    required this.options,
    this.optionsAreImages = false,
    this.optionsAreImageSequences = false,
    required this.correctIndex,
  });
}

// ── PANTALLA COMPLETA DE EXAMEN ───────────────────────────────────────────
class ExamPlayScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final int levelNum;
  final AppState appState;

  const ExamPlayScreen({
    super.key,
    required this.questions,
    required this.levelNum,
    required this.appState,
  });

  @override
  State<ExamPlayScreen> createState() => _ExamPlayScreenState();
}

class _ExamPlayScreenState extends State<ExamPlayScreen> {
  int _currentIdx = 0;
  int _score = 0;
  final List<int> _selectedIndices = [];
  bool _resultSaved = false;

  @override
  Widget build(BuildContext context) {
    final isFinished = _currentIdx >= widget.questions.length;

    if (isFinished) {
      final approved = _score >= 4;

      if (!_resultSaved) {
        _resultSaved = true;
        final List<Map<String, dynamic>> details = [];
        for (int i = 0; i < widget.questions.length; i++) {
          final q = widget.questions[i];
          details.add({
            'questionText': q.questionText,
            'imageName': q.imageName,
            'options': q.options,
            'correctIndex': q.correctIndex,
            'selectedIndex': _selectedIndices[i],
            'optionsAreImages': q.optionsAreImages,
            'optionsAreImageSequences': q.optionsAreImageSequences,
          });
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.appState.saveExamResult(widget.levelNum, _score, details);
          if (approved) {
            widget.appState.unlockNextLevel(widget.levelNum);
          }
        });
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('Resultados del Examen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.surfaceLight),
              ),
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      approved ? Icons.stars : Icons.sentiment_neutral_outlined,
                      color: approved ? AppColors.connected : AppColors.error,
                      size: 72,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      approved ? '¡Excelente trabajo! 🎉' : 'Sigue practicando 📚',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: approved ? AppColors.connected : AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Puntuación final: $_score de ${widget.questions.length} correctas (${(_score / widget.questions.length * 100).round()}%).',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      approved
                          ? 'Has desbloqueado exitosamente el siguiente nivel.'
                          : 'Necesitas al menos 4 de 5 respuestas correctas para aprobar y desbloquear el siguiente nivel.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecond, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('VOLVER A NIVELES', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final currentQuestion = widget.questions[_currentIdx];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Examen Nivel ${widget.levelNum}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textSecond),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xD8FFFFFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('¿Abandonar Examen?', style: TextStyle(fontWeight: FontWeight.bold)),
                content: const Text('Si sales ahora, perderás tu progreso actual en esta evaluación.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('NO, CONTINUAR', style: TextStyle(color: AppColors.textSecond, fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Cerrar diálogo
                      Navigator.pop(context); // Salir del examen
                    },
                    child: const Text('SÍ, SALIR', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIdx) / widget.questions.length,
            backgroundColor: AppColors.surfaceLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            minHeight: 6,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.surfaceLight),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Pregunta ${_currentIdx + 1} de ${widget.questions.length}',
                        style: const TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.bold, letterSpacing: 1),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (currentQuestion.imageName.isNotEmpty) ...[
                        Container(
                          height: 180,
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
                                child: Icon(Icons.image_not_supported_outlined, size: 48, color: AppColors.textSecond),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (currentQuestion.questionImages.isNotEmpty) ...[
                        Container(
                          height: 140,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.surfaceLight),
                          ),
                          child: Center(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: currentQuestion.questionImages.map((l) {
                                  final img = l == 'Ñ' ? 'N_tilde' : l;
                                  return Container(
                                    width: 70,
                                    height: 110,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.surfaceLight),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        'assets/images/$img.png',
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => Center(child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold))),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        currentQuestion.questionText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      ...List.generate(currentQuestion.options.length, (optIdx) {
                        final option = currentQuestion.options[optIdx];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
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
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _buildOptionContent(currentQuestion, option),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionContent(QuizQuestion q, String option) {
    if (q.optionsAreImages) {
      final img = option == 'Ñ' ? 'N_tilde' : option;
      return Container(
        height: 36,
        padding: const EdgeInsets.all(2),
        child: Image.asset(
          'assets/images/$img.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Text(option, style: const TextStyle(color: AppColors.textPrimary)),
        ),
      );
    } else if (q.optionsAreImageSequences) {
      final letters = option.split(',');
      return Wrap(
        spacing: 4,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: letters.map((l) {
          final img = l == 'Ñ' ? 'N_tilde' : l;
          return Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                'assets/images/$img.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(child: Text(l, style: const TextStyle(fontSize: 8))),
              ),
            ),
          );
        }).toList(),
      );
    } else {
      return Text(
        option,
        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
      );
    }
  }
}

// ── PANTALLA DE DETALLE DE HISTORIAL (COMPLETA) ─────────────────────────
class QuizDetailScreen extends StatelessWidget {
  final Map<String, dynamic> quiz;

  const QuizDetailScreen({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    final details = List<Map<String, dynamic>>.from(quiz['details'] as List);
    final int? examLevel = quiz['levelNum'] as int?;
    final titleText = examLevel != null ? 'Examen Nivel $examLevel del ${quiz['date']}' : 'Quiz del ${quiz['date']}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: details.length,
        itemBuilder: (context, i) {
          final d = details[i];
          final qText = d['questionText'] as String;
          final imgName = d['imageName'] as String;
          final options = List<String>.from(d['options'] as List);
          final correctIdx = d['correctIndex'] as int;
          final selectedIdx = d['selectedIndex'] as int;
          final isCorrect = correctIdx == selectedIdx;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCorrect ? AppColors.connected.withOpacity(0.3) : AppColors.error.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imgName.isNotEmpty)
                      Container(
                        width: 64,
                        height: 64,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceLight),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/$imgName.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image_not_supported_outlined, size: 24, color: AppColors.textSecond),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        qText,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...List.generate(options.length, (optIdx) {
                  final option = options[optIdx];
                  final isCorrectOpt = optIdx == correctIdx;
                  final isSelectedOpt = optIdx == selectedIdx;

                  Color bgColor = AppColors.background;
                  Color textColor = AppColors.textPrimary;
                  BorderSide border = BorderSide(color: AppColors.surfaceLight);

                  if (isCorrectOpt) {
                    bgColor = AppColors.connected.withOpacity(0.12);
                    textColor = AppColors.connected;
                    border = const BorderSide(color: AppColors.connected, width: 2);
                  } else if (isSelectedOpt && !isCorrect) {
                    bgColor = AppColors.error.withOpacity(0.12);
                    textColor = AppColors.error;
                    border = const BorderSide(color: AppColors.error, width: 2);
                  }

                  final bool optImages = d['optionsAreImages'] as bool? ?? false;
                  final bool optSequences = d['optionsAreImageSequences'] as bool? ?? false;
                  final tempQ = QuizQuestion(
                    imageName: imgName,
                    questionText: qText,
                    options: options,
                    correctIndex: correctIdx,
                    optionsAreImages: optImages,
                    optionsAreImageSequences: optSequences,
                  );

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.fromBorderSide(border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildOptionContentStatic(tempQ, option, textColor: textColor),
                          ),
                        ),
                        if (isCorrectOpt)
                          const Icon(Icons.check_circle, color: AppColors.connected, size: 20)
                        else if (isSelectedOpt && !isCorrect)
                          const Icon(Icons.cancel, color: AppColors.error, size: 20),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionContentStatic(QuizQuestion q, String option, {Color? textColor}) {
    if (q.optionsAreImages) {
      final img = option == 'Ñ' ? 'N_tilde' : option;
      return Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        child: Image.asset(
          'assets/images/$img.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Text(option, style: TextStyle(color: textColor ?? AppColors.textPrimary)),
        ),
      );
    } else if (q.optionsAreImageSequences) {
      final letters = option.split(',');
      return Wrap(
        spacing: 6,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: letters.map((l) {
          final img = l == 'Ñ' ? 'N_tilde' : l;
          return Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/$img.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(child: Text(l, style: const TextStyle(fontSize: 10))),
              ),
            ),
          );
        }).toList(),
      );
    } else {
      return Text(
        option,
        style: TextStyle(color: textColor ?? AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
      );
    }
  }
}
