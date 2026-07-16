
class NlpEngine {
  // Lista de palabras comunes en español (Lenguaje cotidiano, señas y siglas/acrónimos)
  final List<String> _spanishDictionary = [
    "A", "ABRIR", "ABUELA", "ABUELO", "ADEMAS", "ADIOS", "ADULTO", "AEROPUERTO",
    "AFP", "AGN", "AGUA", "AHORA", "AIRE", "ALEGRE", "ALEGRIA", "ALGO",
    "ALGODON", "ALGUIEN", "ALGUN", "ALGUNA", "ALGUNAS", "ALGUNOS", "ALMUERZO", "ALTA",
    "ALTO", "ALUMNA", "ALUMNO", "AMIGA", "AMIGO", "AMOR", "ANCHA", "ANCHO",
    "ANIMAL", "ANTES", "APAFA", "APCI", "AQUEL", "AQUELLA", "AQUELLAS", "AQUELLOS",
    "ARBOL", "ARENA", "ARROZ", "ARTE", "ASI", "AUN", "AUNQUE", "AVENIDA",
    "AYER", "AYUDA", "AYUDAME", "AYUDAR", "AZUCAR", "AÑO", "BAILAR", "BAJA",
    "BAJO", "BANCO", "BARRIO", "BAÑO", "BCRP", "BEBE", "BEBER", "BEBIDA",
    "BIBLIOTECA", "BID", "BIEN", "BNP", "BOCA", "BOLA", "BOLSO", "BOSQUE",
    "BRAZO", "BUENA", "BUENO", "BUENOS", "BUSCAR", "CABALLO", "CABELLO", "CABEZA",
    "CAER", "CAF", "CAFE", "CALIENTE", "CALLE", "CAMA", "CAMBIAR", "CAMBIO",
    "CAMINO", "CAMISA", "CAMPO", "CANSADA", "CANSADO", "CANTAR", "CANTIDAD", "CARA",
    "CARNE", "CARRETERA", "CARTA", "CARTON", "CASA", "CASI", "CELULAR", "CENA",
    "CENEPRED", "CEPILLO", "CEPLAN", "CERRAR", "CIELO", "CIENCIA", "CINCO", "CINE",
    "CIUDAD", "CLARA", "CLARO", "CLASE", "CLINICA", "COAR", "COBRE", "CODIGO",
    "COFOPRI", "COLOR", "COMER", "COMIDA", "COMO", "COMPRAR", "COMPRENDER", "COMPRENDO",
    "COMPUTADORA", "CON", "CONADIS", "CONCYTEC", "CONOCER", "CONTAR", "CORAZON", "CORPAC",
    "CORRER", "CORTA", "CORTO", "CREER", "CTS", "CUADERNO", "CUAL", "CUANDO",
    "CUANTO", "CUATRO", "CUCHARA", "CUCHILLO", "CUELLO", "CUERPO", "CURSO", "DAR",
    "DATOS", "DE", "DEBER", "DEBIL", "DECIR", "DEDO", "DEPORTE", "DESARROLLO",
    "DESAYUNO", "DESDE", "DESPUES", "DEVIDA", "DIA", "DIAS", "DIENTE", "DIFERENTE",
    "DIFICIL", "DINERO", "DISCULPA", "DISEÑO", "DNI", "DOLOR", "DONDE", "DORMIR",
    "DOS", "DUDA", "DURANTE", "EL", "ELECTROPERU", "ELLA", "ELLAS", "ELLOS",
    "EMPEZAR", "EMPRESA", "EN", "ENAPU", "ENCONTRAR", "ENFERMA", "ENFERMO", "ENTENDER",
    "ENTIENDO", "ENTONCES", "ENTRAR", "ENTRE", "EP", "EPIS", "EQUIPO", "ERROR",
    "ESA", "ESAS", "ESCRIBIR", "ESCUCHAR", "ESCUELA", "ESE", "ESOS", "ESPACIO",
    "ESPALDA", "ESPEJO", "ESPERAR", "ESPOSA", "ESPOSO", "ESSALUD", "ESTA", "ESTACION",
    "ESTAR", "ESTAS", "ESTE", "ESTOS", "ESTRECHA", "ESTRECHO", "ESTRELLA", "ESTUDIANTE",
    "ESTUDIAR", "EXITO", "EXPLICAR", "FACIL", "FAMILIA", "FAP", "FARMACIA", "FAVOR",
    "FEA", "FECHA", "FELIZ", "FEO", "FFAA", "FIEBRE", "FIIS", "FIN",
    "FLOR", "FMI", "FONAFE", "FONCODES", "FONCOMUN", "FORMA", "FRACASO", "FRIA",
    "FRIO", "FRUTA", "FRUTO", "FUEGO", "FUERTE", "FUTURO", "GALLINA", "GANAR",
    "GATO", "GENTE", "GEOGRAFIA", "GRACIAS", "GRANDE", "GRUPO", "GUANTE", "GUERRA",
    "GUSTAR", "HABER", "HABLAR", "HACER", "HAMBRE", "HASTA", "HERMANA", "HERMANO",
    "HERMOSA", "HERMOSO", "HIERRO", "HIJA", "HIJO", "HILO", "HISTORIA", "HOGAR",
    "HOJA", "HOLA", "HOMBRE", "HOMBRO", "HORA", "HOSPITAL", "HOTEL", "HOY",
    "HUESO", "HUEVO", "IDEA", "IDIOMA", "IGLESIA", "IGP", "IGUAL", "IGV",
    "IIAP", "IMPORTANTE", "INDECI", "INDECOPI", "INEI", "INFORMACION", "INGEMMET", "INIA",
    "INSECTO", "INTERNET", "IPD", "IR", "JABON", "JAMAS", "JARDIN", "JEFE",
    "JNE", "JOVEN", "JUEGO", "JUGAR", "JUGO", "JUNTOS", "LA", "LABIO",
    "LADO", "LAGO", "LANA", "LAPIZ", "LAPTOP", "LARGA", "LARGO", "LAS",
    "LE", "LECHE", "LEER", "LENGUA", "LENGUAJE", "LENTA", "LENTO", "LES",
    "LETRA", "LEÓN", "LIBRO", "LIMPIA", "LIMPIO", "LINEA", "LLAMADA", "LLAMAR",
    "LLAVE", "LLENA", "LLENO", "LLEVAR", "LLORAR", "LLUVIA", "LO", "LOGRAR",
    "LOS", "LSP", "LSP", "LUEGO", "LUGAR", "LUNA", "LUZ", "MADERA",
    "MADRE", "MAESTRA", "MAESTRO", "MAL", "MALA", "MALO", "MAMA", "MANERA",
    "MANO", "MANZANA", "MAR", "MAS", "MATEMATICA", "MAÑANA", "ME", "MEDICAMENTO",
    "MEDICO", "MEDIO", "MEF", "MEJOR", "MEM", "MENOS", "MENSAJE", "MENTIRA",
    "MERCADO", "MES", "MESA", "METAL", "MGP", "MI", "MIA", "MIDIS",
    "MIEDO", "MIENTRAS", "MIMP", "MINAM", "MINCETUR", "MINCUL", "MINDEF", "MINEDU",
    "MINERAL", "MININTER", "MINJUSDH", "MINSA", "MINUTO", "MIO", "MIRAR", "MIS",
    "MISMO", "MOCHILA", "MODO", "MOJADA", "MOJADO", "MOMENTO", "MONO", "MONTAÑA",
    "MOSCA", "MOUSE", "MTC", "MTPE", "MUCHO", "MUERTE", "MUJER", "MUNDO",
    "MUSEO", "MUSICA", "MUY", "MVCS", "NADA", "NADIE", "NARANJA", "NARIZ",
    "NECESITO", "NEGOCIO", "NIEVE", "NIÑA", "NIÑO", "NO", "NOCHE", "NOCHES",
    "NOS", "NOSOTROS", "NUESTRA", "NUESTRAS", "NUESTRO", "NUESTROS", "NUEVA", "NUEVO",
    "NUMERO", "NUNCA", "O", "OCURRIR", "ODIO", "OEA", "OEFA", "OFICINA",
    "OFRECER", "OIR", "OIT", "OJO", "OMS", "ONPE", "ONU", "OREJA",
    "ORO", "OS", "OSCURA", "OSCURIDAD", "OSCURO", "OSINERGMIN", "OSIPTEL", "OSITRAN",
    "OSO", "OTRA", "OTRAS", "OTRO", "OTROS", "OVEJA", "PADRE", "PAGAR",
    "PAIS", "PAJARO", "PALABRA", "PAN", "PANTALLA", "PANTALON", "PAPA", "PAPEL",
    "PARA", "PARECER", "PARED", "PAREJA", "PARQUE", "PARTE", "PASADO", "PASAR",
    "PASO", "PATO", "PAZ", "PBI", "PECHO", "PEDIR", "PELIGROSA", "PELIGROSO",
    "PENSAMIENTO", "PENSAR", "PENSION65", "PEOR", "PEQUEÑA", "PEQUEÑO", "PERDER", "PERMISO",
    "PERMITIR", "PERO", "PERRO", "PERSONA", "PERU", "PESCADO", "PETROPERU", "PEZ",
    "PIE", "PIEDRA", "PIEL", "PIERNA", "PISO", "PLACER", "PLANTA", "PLASTICO",
    "PLATA", "PLATANO", "PLATO", "PLAYA", "PLAZA", "PLUMA", "PNP", "POBRE",
    "POCO", "PODER", "POLLO", "PONER", "POR", "PORFAVOR", "PORQUE", "PRECIO",
    "PREGUNTA", "PRESENTE", "PRIMA", "PRIMERA", "PRIMERO", "PRIMO", "PRINCIPIO", "PROBLEMA",
    "PRODUCE", "PRODUCIR", "PROFESOR", "PROFESORA", "PROGRAMA", "PRONABEC", "PRONTO", "PROYECTO",
    "PUEBLO", "PUEDO", "PUENTE", "PUERTA", "PUERTO", "PUES", "PUNTO", "PÁJARO",
    "QALIWARMA", "QUE", "QUEDAR", "QUERER", "QUESO", "QUIEN", "QUIERO", "QUIZAS",
    "RAPIDA", "RAPIDO", "RATON", "RECIBIR", "RECORDAR", "RED", "REIR", "RELOJ",
    "RENIEC", "RESERVA", "RESPUESTA", "RESTAURANTE", "RICA", "RICO", "RIO", "RODILLA",
    "ROPA", "RREE", "RUC", "RUIDO", "SABER", "SACAR", "SAL", "SALIR",
    "SALUD", "SANA", "SANGRE", "SANIPES", "SANO", "SAT", "SBN", "SBS",
    "SE", "SECA", "SECO", "SEDAPAL", "SEGUIR", "SEGUNDA", "SEGUNDO", "SEGURA",
    "SEGURO", "SEMANA", "SENAMHI", "SENASA", "SENTIR", "SER", "SERFOR", "SERNANP",
    "SERPOST", "SERVICIO", "SERVIR", "SEÑAS", "SEÑOR", "SEÑORA", "SI", "SIEMPRE",
    "SIGLO", "SILENCIO", "SILLA", "SIMA", "SIN", "SINO", "SIS", "SISTEMA",
    "SITIO", "SOBRE", "SOL", "SOLAMENTE", "SOLO", "SOLUCION", "SOPA", "SUCIA",
    "SUCIO", "SUERTE", "SUEÑO", "SUNASS", "SUNAT", "SUS", "SUSALUD", "SUTRAN",
    "SUYA", "SUYO", "TALVEZ", "TAMBIEN", "TAMPOCO", "TARDE", "TARDES", "TC",
    "TE", "TEATRO", "TECHO", "TECLADO", "TECNOLOGIA", "TELA", "TELEFONO", "TEMPRANO",
    "TENEDOR", "TENER", "TENGO", "TERCERA", "TERCERO", "TEXTO", "TI", "TIA",
    "TIEMPO", "TIENDA", "TIERRA", "TIGRE", "TIO", "TLC", "TOALLA", "TODA",
    "TODAS", "TODAVIA", "TODO", "TODOS", "TOMAR", "TOMATE", "TRABAJAR", "TRABAJO",
    "TRADUCTOR", "TRAER", "TRAS", "TRATAR", "TRES", "TRISTE", "TRISTEZA", "TU",
    "TUS", "U", "UIT", "ULTIMA", "ULTIMO", "UN", "UNA", "UNAS",
    "UNESCO", "UNFV", "UNICEF", "UNIVERSIDAD", "UNO", "UNOS", "UÑA", "VACA",
    "VACIA", "VACIO", "VALOR", "VASO", "VECINA", "VECINO", "VENDER", "VENIR",
    "VENTANA", "VER", "VERDAD", "VERDURA", "VESTIDO", "VIAJAR", "VIDA", "VIDRIO",
    "VIEJA", "VIEJO", "VIENTO", "VIVIR", "VOLVER", "VOSOTROS", "Y", "YA",
    "YO", "ZAPATOS", "ÉPOCA",
  ];

  // Palabras frecuentes personalizadas por el perfil
  List<String> _frequentWords = [];

  // Palabras personalizadas (agregadas por señas personalizadas)
  List<String> _customWords = [];

  void updateCustomAndFrequentWords(List<String> custom, List<String> frequent) {
    _customWords = custom.map((w) => w.toUpperCase()).toList();
    _frequentWords = frequent.map((w) => w.toUpperCase()).toList();
  }

  // Obtener todas las palabras combinadas (diccionario + personalizadas + frecuentes)
  List<String> get _fullDictionary {
    final Set<String> combined = {};
    combined.addAll(_spanishDictionary);
    combined.addAll(_customWords);
    combined.addAll(_frequentWords);
    return combined.toList();
  }

  // Comprobar si el texto acumulado hasta ahora es prefijo de alguna palabra válida
  bool isPrefixOfValidWord(String prefix) {
    if (prefix.isEmpty) return false;
    final upperPrefix = prefix.toUpperCase();
    return _fullDictionary.any((word) => word.startsWith(upperPrefix));
  }

  // Intenta corregir una palabra usando la Distancia de Levenshtein
  // Si encuentra una coincidencia exacta o cercana (distancia <= 2), la devuelve
  String correctWord(String input) {
    final cleaned = input.toUpperCase().trim();
    if (cleaned.isEmpty) return "";

    // Si la palabra ya está en el diccionario, no corregir
    if (_fullDictionary.contains(cleaned)) {
      return cleaned;
    }

    String bestMatch = cleaned;
    int minDistance = 999;
    
    // Reglas de tolerancia de distancia:
    // Para palabras muy cortas (1-3 letras), tolerancia máx de 1 error.
    // Para palabras de 4+ letras, tolerancia máx de 2 errores.
    final int maxAllowedDistance = cleaned.length <= 3 ? 1 : 2;

    for (final word in _fullDictionary) {
      final distance = _levenshteinDistance(cleaned, word);
      if (distance < minDistance) {
        minDistance = distance;
        bestMatch = word;
      }
    }

    if (minDistance <= maxAllowedDistance) {
      return bestMatch;
    }

    return cleaned; // Si está muy lejos, devolver lo que el usuario escribió
  }

  // Obtiene sugerencias de autocompletado mientras escribe
  List<String> getSuggestions(String prefix, {int limit = 3}) {
    if (prefix.isEmpty) return [];
    final upperPrefix = prefix.toUpperCase().trim();
    
    final matches = _fullDictionary
        .where((word) => word.startsWith(upperPrefix) && word != upperPrefix)
        .toList();
    
    // Ordenar: primero las frecuentes, luego por longitud
    matches.sort((a, b) {
      final aFreq = _frequentWords.contains(a);
      final bFreq = _frequentWords.contains(b);
      if (aFreq && !bFreq) return -1;
      if (!aFreq && bFreq) return 1;
      return a.length.compareTo(b.length);
    });

    return matches.take(limit).toList();
  }

  // Algoritmo de Distancia de Levenshtein
  int _levenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = _min3(v1[j] + 1, v0[j + 1] + 1, v0[j] + cost);
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[t.length];
  }

  int _min3(int a, int b, int c) {
    int m = a < b ? a : b;
    return m < c ? m : c;
  }
}
