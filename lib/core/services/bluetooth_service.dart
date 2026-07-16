import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../constants.dart';

class BleDeviceModel {
  final String name;
  final String id;
  final BluetoothDevice device;

  BleDeviceModel({required this.name, required this.id, required this.device});
}

class GloveBluetoothService {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _letraCharacteristic;
  BluetoothCharacteristic? _dataCharacteristic;
  StreamSubscription<List<int>>? _letraSubscription;
  StreamSubscription<List<int>>? _dataSubscription;
  bool _isMocking = false;
  Timer? _mockTimer;

  bool get isMocking => _isMocking;

  // Stream de datos crudos (CSV format) - mantiene compatibilidad con visualización de sensores
  final _dataController = StreamController<String>.broadcast();
  Stream<String> get dataStream => _dataController.stream;

  // Stream de letras y palabras traducidas del guante
  final _letterController = StreamController<String>.broadcast();
  Stream<String> get letterStream => _letterController.stream;

  // Stream de dispositivos escaneados
  final _scanController = StreamController<List<BleDeviceModel>>.broadcast();
  Stream<List<BleDeviceModel>> get scanResultsStream => _scanController.stream;

  // Stream del estado de la conexión BLE
  final _connectionStateController = StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionStateStream => _connectionStateController.stream;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  // Escanear dispositivos BLE con el nombre o servicio del guante
  Future<void> startScan() async {
    _isMocking = false;
    _mockTimer?.cancel();
    
    // Iniciar escaneo de BLE (aumentado a 10 segundos)
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    
    // Escuchar resultados
    FlutterBluePlus.scanResults.listen((results) {
      final list = results
          .map((r) {
            final name = r.advertisementData.advName.isNotEmpty
                ? r.advertisementData.advName
                : r.device.platformName;
            return BleDeviceModel(
              name: name,
              id: r.device.remoteId.str,
              device: r.device,
            );
          })
          .where((m) => m.name.isNotEmpty)
          .toList();
      _scanController.add(list);
    });
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  // Conectar al guante físico
  Future<bool> connectTo(BluetoothDevice device) async {
    try {
      _isMocking = false;
      _mockTimer?.cancel();
      
      // Cancelar suscripciones existentes antes de conectar para evitar duplicados
      await _letraSubscription?.cancel();
      _letraSubscription = null;
      await _dataSubscription?.cancel();
      _dataSubscription = null;
      
      _connectedDevice = device;
      
      // Escuchar el estado de conexión para detectar desconexiones abruptas
      await _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.listen((state) {
        _connectionStateController.add(state);
      });
      
      await device.connect(autoConnect: false, license: License.nonprofit);
      
      // Limpiar caché GATT en Android para evitar servicios obsoletos cacheados por el sistema operativo
      if (!kIsWeb && Platform.isAndroid) {
        try {
          await device.clearGattCache();
          debugPrint("[BLE] GATT cache cleared successfully.");
        } catch (err) {
          debugPrint("[BLE] Failed to clear GATT cache: $err");
        }
      }

      // Descubrir servicios
      List<BluetoothService> services = await device.discoverServices();
      _letraCharacteristic = null;
      _dataCharacteristic = null;

      final targetServiceUuid = AppConstants.bleServiceUuid.toLowerCase().replaceAll("-", "");
      final targetDataUuid = AppConstants.bleCharacteristicDataUuid.toLowerCase().replaceAll("-", "");

      for (var service in services) {
        final sUuid = service.uuid.toString().toLowerCase().replaceAll("-", "");
        if (sUuid == targetServiceUuid) {
          for (var char in service.characteristics) {
            final cUuid = char.uuid.toString().toLowerCase().replaceAll("-", "");
            if (cUuid == targetDataUuid) {
              _dataCharacteristic = char;
            }
          }
        }
      }

      if (_dataCharacteristic != null) {
        // Habilitar notificaciones en la característica de datos analógicos crudos
        await _dataCharacteristic!.setNotifyValue(true);
        _dataSubscription = _dataCharacteristic!.onValueReceived.listen((value) {
          final decoded = utf8.decode(value).trim();
          if (decoded.isNotEmpty) {
            _dataController.add(decoded);
          }
        });

        return true;
      } else {
        await disconnect();
        return false;
      }
    } catch (e) {
      debugPrint("BLE CONNECTION ERROR: $e");
      await disconnect();
      rethrow; // Lanzar excepción para que AppState la capture y la muestre al usuario
    }
  }

  // Desconectar dispositivo
  Future<void> disconnect() async {
    _mockTimer?.cancel();
    _isMocking = false;
    
    await _letraSubscription?.cancel();
    _letraSubscription = null;
    await _dataSubscription?.cancel();
    _dataSubscription = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    _connectionStateController.add(BluetoothConnectionState.disconnected);

    _letraCharacteristic = null;
    _dataCharacteristic = null;

    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
  }

  // Escribir datos de comandos al guante (CALIBRAR, CUSTOM, etc.)
  Future<bool> writeData(String data) async {
    if (_isMocking) {
      debugPrint("[MOCK BLE WRITE] Escribiendo en DataCharacteristic: '$data'");
      return true;
    }
    if (_connectedDevice == null || _dataCharacteristic == null) {
      debugPrint("[BLE WRITE ERROR] Dispositivo no conectado o característica de datos no disponible");
      return false;
    }
    try {
      await _dataCharacteristic!.write(utf8.encode(data));
      debugPrint("[BLE WRITE SUCCESS] Comando enviado: '$data'");
      return true;
    } catch (e) {
      debugPrint("[BLE WRITE ERROR] Error al enviar comando: $e");
      return false;
    }
  }

  // ── MODO DEMO / SIMULACIÓN (Para cuando no tienen el ESP32 físico) ─────────
  void startMockingData(List<String> textSequence) {
    _isMocking = true;
    _mockTimer?.cancel();

    _letraSubscription?.cancel();
    _letraSubscription = null;
    _dataSubscription?.cancel();
    _dataSubscription = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _letraCharacteristic = null;
    _dataCharacteristic = null;

    if (_connectedDevice != null) {
      _connectedDevice!.disconnect();
      _connectedDevice = null;
    }

    int letterIndex = 0;
    
    // Mapeo básico de letras a flexiones de dedos [Pulgar, Índice, Medio, Anular, Meñique]
    // 0 = estirado (1200 analógico), 1 = doblado (4000 analógico)
    final patterns = {
      'A': [4000, 1200, 1200, 1200, 1200], // Pulgar doblado, resto estirado (10000)
      'B': [1200, 4000, 4000, 4000, 4000], // Pulgar estirado, resto doblados (01111)
      'C': [1200, 1200, 1200, 1200, 1200], // Todos estirados horizontal (00000)
      'D': [4000, 1200, 4000, 4000, 4000], // Solo índice estirado (10111)
      'E': [4000, 4000, 4000, 4000, 1200], // Solo meñique estirado (11110)
      'H': [1200, 1200, 4000, 4000, 4000], // Pulgar e índice estirados vertical (00111)
      'O': [1200, 1200, 1200, 1200, 1200], // Todos estirados vertical (00000)
      'L': [1200, 1200, 4000, 4000, 4000], // Pulgar e índice estirados horizontal (00111)
      ' ': [1200, 4000, 1200, 4000, 4000], // Espacio: gesto 01011 (Pulgar y Medio doblados)
    };

    _mockTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!_isMocking) {
        timer.cancel();
        return;
      }

      if (letterIndex >= textSequence.length) {
        timer.cancel();
        _isMocking = false;
        _dataController.add("FINISHED_MOCK");
        return;
      }

      final char = textSequence[letterIndex].toUpperCase();
      final flexVals = patterns[char] ?? [1200, 1200, 1200, 1200, 1200];
      
      // Agregar un poco de variación de ruido analógico aleatorio (+-50)
      final r = Random();
      final f1 = flexVals[0] + r.nextInt(100) - 50;
      final f2 = flexVals[1] + r.nextInt(100) - 50;
      final f3 = flexVals[2] + r.nextInt(100) - 50;
      final f4 = flexVals[3] + r.nextInt(100) - 50;
      final f5 = flexVals[4] + r.nextInt(100) - 50;

      // Aceleración y giro mock (orientación vertical/horizontal)
      // L y C son horizontales (ay = 9.8), las demás son verticales (ay = 0.0)
      double ax = 0.0;
      double ay = (char == 'L' || char == 'C') ? 9.8 : 0.0;
      double az = char == 'L' || char == 'C' ? 0.0 : 9.8;

      final mockCsv = "$f1,$f2,$f3,$f4,$f5,$ax,$ay,$az,0.0,0.0,0.0";
      _dataController.add(mockCsv);
      
      // También publicamos la letra simulada en el letterStream
      _letterController.add(char);

      letterIndex++;
    });
  }

  void stopMocking() {
    _isMocking = false;
    _mockTimer?.cancel();
  }
}
