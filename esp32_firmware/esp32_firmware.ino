/*
 * PROYECTO: GUANTE TRADUCTOR LSP - EMISOR DE DATOS CRUDOS (BLE)
 * HARDWARE: ESP32-WROOM-32 + 5x Sensores Flex + MPU6500 + 5 Sensores de Contacto (Pines 12, 13, 16, 17, 18)
 * COMUNICACIÓN: BLE (GATT Server) - La traducción a letras se hace en el APP (Flutter)
 */
#include <Wire.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// --- PINES ADC1 DEL ESP32 (SENSORES FLEX) ---
const int PIN_FLEX_THUMB  = 36;  // VP (Pulgar)
const int PIN_FLEX_INDEX  = 34;  // D34 (Índice)
const int PIN_FLEX_MIDDLE = 35;  // D35 (Medio)
const int PIN_FLEX_RING   = 32;  // D32 (Anular)
const int PIN_FLEX_PINKY  = 33;  // D33 (Meñique)

// --- PINES DE SENSORES DE CONTACTO ---
// Los GNDs físicos (Punta pulgar, Base índice, Palma) van conectados a GND del ESP32.
// Los pines se configuran con pull-up interno, por lo que reportan LOW (0) al tocar tierra (contacto).
const int PIN_D12 = 12; // Punta del dedo índice
const int PIN_D13 = 13; // Punta del dedo medio
const int PIN_D16 = 16; // Medio del dedo índice
const int PIN_D17 = 17; // Base del dedo medio (anteriormente D4)
const int PIN_D18 = 18; // Base del dedo anular (anteriormente D2)

// --- MPU6500/6050 ---
int MPU = 0x68; // Se autodetecta dinámicamente en setup()

// --- UUIDs del Servidor GATT ---
#define SERVICE_UUID              "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_LETRA_UUID "beb5483e-36e1-4688-b7f5-ea07361b2c1d"
#define CHARACTERISTIC_DATA_UUID  "a5c7823f-1234-4688-b7f5-ea07361b2c1d"

BLEServer* pServer = NULL;
BLECharacteristic* pLetraCharacteristic = NULL;
BLECharacteristic* pDataCharacteristic = NULL;
bool deviceConnected = false;

// --- Filtros de Promedio Móvil (flex) ---
#define NUM_LECTURAS_PROMEDIO 5
int lecturasFlex[5][NUM_LECTURAS_PROMEDIO];
int indiceLectura = 0;

void inicializarFiltros() {
  for (int i = 0; i < 5; i++) {
    int pin = (i == 0) ? PIN_FLEX_THUMB :
              (i == 1) ? PIN_FLEX_INDEX :
              (i == 2) ? PIN_FLEX_MIDDLE :
              (i == 3) ? PIN_FLEX_RING : PIN_FLEX_PINKY;
    int lecturaInicial = analogRead(pin);
    for (int j = 0; j < NUM_LECTURAS_PROMEDIO; j++) {
      lecturasFlex[i][j] = lecturaInicial;
    }
  }
}

int obtenerFlexSuave(int pin, int fingerIdx) {
  lecturasFlex[fingerIdx][indiceLectura] = analogRead(pin);
  long suma = 0;
  for (int j = 0; j < NUM_LECTURAS_PROMEDIO; j++) {
    suma += lecturasFlex[fingerIdx][j];
  }
  return suma / NUM_LECTURAS_PROMEDIO;
}

// --- Control de tiempo ---
unsigned long ultimoEnvio = 0;
const unsigned long INTERVALO_ENVIO = 50; // 20Hz

// =====================================================
//   LECTURA DEL MPU6500 POR I2C (REGISTROS CRUDOS)
// =====================================================
void mpuWrite(byte reg, byte val) {
  Wire.beginTransmission(MPU);
  Wire.write(reg);
  Wire.write(val);
  Wire.endTransmission();
}

bool leerMPU(float &ax, float &ay, float &az, float &gx, float &gy, float &gz) {
  Wire.beginTransmission(MPU);
  Wire.write(0x3B);
  if (Wire.endTransmission(false) != 0) return false;
  Wire.requestFrom(MPU, 14, true);
  if (Wire.available() < 14) return false;
  int16_t AcX = Wire.read() << 8 | Wire.read();
  int16_t AcY = Wire.read() << 8 | Wire.read();
  int16_t AcZ = Wire.read() << 8 | Wire.read();
  Wire.read(); Wire.read(); // Ignorar temperatura
  int16_t GyX = Wire.read() << 8 | Wire.read();
  int16_t GyY = Wire.read() << 8 | Wire.read();
  int16_t GyZ = Wire.read() << 8 | Wire.read();

  const float G_A_MS2 = 9.80665;
  const float DEG2RAD  = 0.017453292519943295;

  ax = (AcX / 16384.0) * G_A_MS2;
  ay = (AcY / 16384.0) * G_A_MS2;
  az = (AcZ / 16384.0) * G_A_MS2;
  gx = (GyX / 131.0) * DEG2RAD;
  gy = (GyY / 131.0) * DEG2RAD;
  gz = (GyZ / 131.0) * DEG2RAD;
  return true;
}

// =====================================================
//   LECTURA DE SENSORES DE CONTACTO
// =====================================================
void leerContactos(bool contactos[5]) {
  contactos[0] = digitalRead(PIN_D12) == LOW;
  contactos[1] = digitalRead(PIN_D13) == LOW;
  contactos[2] = digitalRead(PIN_D16) == LOW;
  contactos[3] = digitalRead(PIN_D17) == LOW;
  contactos[4] = digitalRead(PIN_D18) == LOW;
}

// =====================================================
//   CALLBACKS BLE
// =====================================================
class MyServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer)    { deviceConnected = true;  Serial.println(">>> BLE CONECTADO <<<"); }
  void onDisconnect(BLEServer* pServer) { deviceConnected = false; Serial.println(">>> BLE DESCONECTADO <<<"); }
};

class DataCallbacks: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    String value = String(pCharacteristic->getValue().c_str());
    Serial.println("Comando Recibido del Celular: " + value);
  }
};

// =====================================================
//   SETUP
// =====================================================
void setup() {
  Serial.begin(115200);
  delay(300);
  Serial.println("\n--- Guante LSP (Emisor BLE - Flex + MPU + Contacto) ---");

  // Flex
  pinMode(PIN_FLEX_THUMB, INPUT);
  pinMode(PIN_FLEX_INDEX, INPUT);
  pinMode(PIN_FLEX_MIDDLE, INPUT);
  pinMode(PIN_FLEX_RING, INPUT);
  pinMode(PIN_FLEX_PINKY, INPUT);
  inicializarFiltros();

  // Sensores de contacto (pull-up interno, se activan en LOW al hacer contacto con GND)
  pinMode(PIN_D12, INPUT_PULLUP);
  pinMode(PIN_D13, INPUT_PULLUP);
  pinMode(PIN_D16, INPUT_PULLUP);
  pinMode(PIN_D17, INPUT_PULLUP);
  pinMode(PIN_D18, INPUT_PULLUP);

  // I2C / MPU con autodetección de dirección
  Wire.begin(21, 22);
  Wire.setClock(100000);

  byte error, address;
  int foundAddress = -1;
  for (address = 1; address < 127; address++) {
    Wire.beginTransmission(address);
    error = Wire.endTransmission();
    if (error == 0) {
      foundAddress = address;
      break;
    }
  }
  if (foundAddress != -1) {
    MPU = foundAddress;
    Serial.printf("MPU detectado en dirección I2C: 0x%02X\n", MPU);
  } else {
    Serial.println("ADVERTENCIA: No se encontró dispositivo I2C, usando dirección por defecto 0x68.");
  }

  mpuWrite(0x6B, 0x00); // Despertar MPU
  delay(100);

  // BLE
  BLEDevice::init("GuanteLSP");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  BLEService *pService = pServer->createService(SERVICE_UUID);

  pLetraCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_LETRA_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pLetraCharacteristic->addDescriptor(new BLE2902());

  pDataCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_DATA_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_WRITE |
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pDataCharacteristic->addDescriptor(new BLE2902());
  pDataCharacteristic->setCallbacks(new DataCallbacks());

  pService->start();
  BLEDevice::getAdvertising()->start();
  Serial.println(">> Servidor BLE activo.");
}

// =====================================================
//   LOOP
// =====================================================
void loop() {
  if (!deviceConnected) {
    delay(500);
    pServer->startAdvertising();
    return;
  }
  if (millis() - ultimoEnvio < INTERVALO_ENVIO) return;
  ultimoEnvio = millis();

  // 1. Leer y suavizar flexores
  int f0 = obtenerFlexSuave(PIN_FLEX_THUMB, 0);
  int f1 = obtenerFlexSuave(PIN_FLEX_INDEX, 1);
  int f2 = obtenerFlexSuave(PIN_FLEX_MIDDLE, 2);
  int f3 = obtenerFlexSuave(PIN_FLEX_RING, 3);
  int f4 = obtenerFlexSuave(PIN_FLEX_PINKY, 4);
  indiceLectura = (indiceLectura + 1) % NUM_LECTURAS_PROMEDIO;

  // 2. Leer MPU
  float ax = 0, ay = 0, az = 0, gx = 0, gy = 0, gz = 0;
  leerMPU(ax, ay, az, gx, gy, gz);

  // 3. Leer sensores de contacto
  bool contactos[5];
  leerContactos(contactos);

  // 4. Crear trama CSV:
  // F0,F1,F2,F3,F4,Ax,Ay,Az,Gx,Gy,Gz,D12,D13,D16,D17,D18
  String payload = String(f0) + "," + String(f1) + "," + String(f2) + "," + String(f3) + "," + String(f4) +
                   "," + String(ax, 2) + "," + String(ay, 2) + "," + String(az, 2) +
                   "," + String(gx, 2) + "," + String(gy, 2) + "," + String(gz, 2);
  for (int i = 0; i < 5; i++) {
    payload += "," + String(contactos[i] ? 1 : 0);
  }

  // 5. Enviar vía BLE
  pDataCharacteristic->setValue(payload.c_str());
  pDataCharacteristic->notify();

  Serial.println("TRAMA: " + payload);
}
