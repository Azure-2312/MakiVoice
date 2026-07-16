class AppConstants {
  // Nombre del dispositivo Bluetooth esperado
  static const String deviceName = 'GuanteLSP';

  // PIN de emparejamiento Bluetooth (si se requiere)
  static const String bluetoothPin = '1234';

  // UUIDs para el servicio BLE y características
  static const String bleServiceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String bleCharacteristicLetraUuid = "beb5483e-36e1-4688-b7f5-ea07361b2c1d";
  static const String bleCharacteristicDataUuid = "a5c7823f-1234-4688-b7f5-ea07361b2c1d";

  // Secuencia de demo para pruebas sin guante físico
  static const List<String> demoSequence = ['H', 'O', 'L', 'A', ' '];

  // Intervalo entre letras en el modo demo (milisegundos)
  static const int demoIntervalMs = 800;

  // Duración de la animación "RECIBIENDO" (milisegundos)
  static const int listeningIndicatorMs = 350;

  // Duración simulada de Text-to-Speech en modo demo (segundos)
  static const int demoSpeakDurationSec = 2;

  // Glosario de Descripciones LSP para el abecedario
  static const Map<String, String> lspDescriptions = {
    'A': 'Puño cerrado con el pulgar extendido al costado lateral.',
    'B': 'Mano abierta con los cuatro dedos juntos apuntando arriba y el pulgar doblado sobre la palma.',
    'C': 'Dedos arqueados formando una media luna horizontal.',
    'D': 'Dedo índice extendido verticalmente, los demás dedos doblados tocando el pulgar.',
    'E': 'Dedos encogidos contra la palma, mostrando las uñas hacia adelante.',
    'F': 'Dedos índice y pulgar tocándose en círculo (pinza), los otros tres extendidos arriba.',
    'G': 'Dedos índice y pulgar extendidos horizontalmente apuntando al lateral.',
    'H': 'Dedos índice y medio extendidos juntos en posición horizontal, otros doblados.',
    'I': 'Dedo meñique extendido verticalmente, los demás doblados en puño.',
    'J': 'Dedo meñique extendido dibuja una curva en forma de gancho "J" en el aire.',
    'K': 'Dedos índice y medio extendidos verticalmente, con el pulgar interceptando el medio en el centro.',
    'L': 'Dedos índice y pulgar extendidos formando un ángulo de 90 grados (letra L).',
    'M': 'Dedos índice, medio y anular colgados hacia abajo pasando sobre el pulgar.',
    'N': 'Dedos índice y medio colgados apuntando hacia abajo sobre el pulgar.',
    'Ñ': 'Igual que la N pero realizando un balanceo de lado a lado con la muñeca.',
    'O': 'Dedos curvados tocando la punta del pulgar para formar un círculo cerrado.',
    'P': 'Dedo índice extendido hacia abajo y el medio doblado en ángulo, apoyado en el pulgar.',
    'Q': 'Dedos índice y pulgar forman una pinza apuntando hacia abajo.',
    'R': 'Dedos índice y medio cruzados verticalmente (gesto de dedos cruzados).',
    'S': 'Mano en forma de puño cerrado trazando una curva en el aire.',
    'T': 'Puño cerrado con el pulgar cruzado entre los dedos índice y medio.',
    'U': 'Dedos índice y medio extendidos verticalmente juntos, otros doblados.',
    'V': 'Dedos índice y medio extendidos formando una "V" (dedos de la paz).',
    'W': 'Dedos índice, medio y anular extendidos verticalmente y separados.',
    'X': 'Dedo índice encogido en forma de gancho y jalando hacia atrás.',
    'Y': 'Dedos pulgar y meñique completamente extendidos, otros doblados (cuernos).',
    'Z': 'Dedo índice extendido dibujando la letra Z en el aire.',
  };
}
