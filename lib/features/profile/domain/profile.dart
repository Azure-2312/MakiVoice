class UserProfile {
  final String id;
  final String name;
  final String password;
  final List<int> flexMin;
  final List<int> flexMid;
  final List<int> flexMax;
  final List<String> frequentWords;
  final Map<String, dynamic> customSigns; // Mapea palabra -> List de enteros/dobles para patrón de gestos
  final List<Map<String, dynamic>> quizHistory; // Historial de quizzes resueltos
  final List<Map<String, dynamic>> examHistory; // Historial de exámenes de nivel resueltos
  final int learningLevel; // Nivel actual desbloqueado en la ruta de aprendizaje (1 a 9)
  final int quizStreak; // Racha de días con quiz resuelto con éxito (mínimo 3 de 5)
  final String? lastQuizDate; // Fecha de la última vez que resolvió con éxito el quiz (YYYY-MM-DD)
  final double umbralInclinacion; // Umbral de inclinación (ax) calibrado por el usuario
  final double umbralMovimientoGyro; // Umbral de giroscopio calibrado dinámicamente
  final double umbralMovimientoAccel; // Umbral de aceleración rápida calibrado dinámicamente

  UserProfile({
    required this.id,
    required this.name,
    required this.password,
    required this.flexMin,
    required this.flexMid,
    required this.flexMax,
    required this.frequentWords,
    required this.customSigns,
    required this.quizHistory,
    required this.examHistory,
    this.learningLevel = 1,
    this.quizStreak = 0,
    this.lastQuizDate,
    this.umbralInclinacion = 2.0,
    this.umbralMovimientoGyro = 1.2,
    this.umbralMovimientoAccel = 2.5,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? password,
    List<int>? flexMin,
    List<int>? flexMid,
    List<int>? flexMax,
    List<String>? frequentWords,
    Map<String, dynamic>? customSigns,
    List<Map<String, dynamic>>? quizHistory,
    List<Map<String, dynamic>>? examHistory,
    int? learningLevel,
    int? quizStreak,
    String? lastQuizDate,
    double? umbralInclinacion,
    double? umbralMovimientoGyro,
    double? umbralMovimientoAccel,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      password: password ?? this.password,
      flexMin: flexMin ?? this.flexMin,
      flexMid: flexMid ?? this.flexMid,
      flexMax: flexMax ?? this.flexMax,
      frequentWords: frequentWords ?? this.frequentWords,
      customSigns: customSigns ?? this.customSigns,
      quizHistory: quizHistory ?? this.quizHistory,
      examHistory: examHistory ?? this.examHistory,
      learningLevel: learningLevel ?? this.learningLevel,
      quizStreak: quizStreak ?? this.quizStreak,
      lastQuizDate: lastQuizDate ?? this.lastQuizDate,
      umbralInclinacion: umbralInclinacion ?? this.umbralInclinacion,
      umbralMovimientoGyro: umbralMovimientoGyro ?? this.umbralMovimientoGyro,
      umbralMovimientoAccel: umbralMovimientoAccel ?? this.umbralMovimientoAccel,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'password': password,
    'flexMin': flexMin,
    'flexMid': flexMid,
    'flexMax': flexMax,
    'frequentWords': frequentWords,
    'customSigns': customSigns,
    'quizHistory': quizHistory,
    'examHistory': examHistory,
    'learningLevel': learningLevel,
    'quizStreak': quizStreak,
    'lastQuizDate': lastQuizDate,
    'umbralInclinacion': umbralInclinacion,
    'umbralMovimientoGyro': umbralMovimientoGyro,
    'umbralMovimientoAccel': umbralMovimientoAccel,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final min = List<int>.from(json['flexMin'] as List);
    final max = List<int>.from(json['flexMax'] as List);
    final mid = json['flexMid'] != null
        ? List<int>.from(json['flexMid'] as List)
        : List.generate(5, (i) => ((min[i] + max[i]) / 2).round());

    final rawHistory = json['quizHistory'] as List?;
    final history = rawHistory != null
        ? List<Map<String, dynamic>>.from(
            rawHistory.map((x) => Map<String, dynamic>.from(x as Map)))
        : <Map<String, dynamic>>[];

    final rawExamHistory = json['examHistory'] as List?;
    final examHist = rawExamHistory != null
        ? List<Map<String, dynamic>>.from(
            rawExamHistory.map((x) => Map<String, dynamic>.from(x as Map)))
        : <Map<String, dynamic>>[];

    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      password: json['password'] as String? ?? '',
      flexMin: min,
      flexMid: mid,
      flexMax: max,
      frequentWords: List<String>.from(json['frequentWords'] as List),
      customSigns: Map<String, dynamic>.from(json['customSigns'] ?? {}),
      quizHistory: history,
      examHistory: examHist,
      learningLevel: json['learningLevel'] as int? ?? 1,
      quizStreak: json['quizStreak'] as int? ?? 0,
      lastQuizDate: json['lastQuizDate'] as String?,
      umbralInclinacion: (json['umbralInclinacion'] as num?)?.toDouble() ?? 2.0,
      umbralMovimientoGyro: (json['umbralMovimientoGyro'] as num?)?.toDouble() ?? 1.2,
      umbralMovimientoAccel: (json['umbralMovimientoAccel'] as num?)?.toDouble() ?? 2.5,
    );
  }

  factory UserProfile.defaultProfile(String id, String name, String password) {
    return UserProfile(
      id: id,
      name: name,
      password: password,
      flexMin: [1200, 1200, 1200, 1200, 1200],
      flexMid: [2600, 2600, 2600, 2600, 2600],
      flexMax: [4000, 4000, 4000, 4000, 4000],
      frequentWords: ["HOLA", "GRACIAS", "BIEN", "NECESITO", "AYUDA"],
      customSigns: {},
      quizHistory: const [],
      examHistory: const [],
      learningLevel: 1,
      quizStreak: 0,
      lastQuizDate: null,
      umbralInclinacion: 2.0,
      umbralMovimientoGyro: 1.2,
      umbralMovimientoAccel: 2.5,
    );
  }
}
