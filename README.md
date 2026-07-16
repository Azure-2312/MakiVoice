# MakiVoice 🖐️🗣️ - Traductor de Lengua de Señas Peruana (LSP)

MakiVoice es una plataforma interactiva de traducción de Lengua de Señas Peruana (LSP) en tiempo real, diseñada para integrar un **guante traductor inteligente (ESP32)** y una **aplicación móvil (Flutter)** con asistencia de síntesis de voz y corrección gramatical inteligente.

Este proyecto ha sido optimizado con un diseño premium de **Glassmorphism (Efecto de Ventana Translúcido)** y un sistema educativo interactivo por niveles.

---

## 🚀 Características Principales

* **Traducción en Tiempo Real:** Interfaz dividida en dos paneles: visualizador de gestos e inicial del carácter traducido en tamaño gigante sobre un fondo translúcido Arena.
* **Control de Voz Avanzado:** Configuración rápida para habilitar lectura de letras o palabras completas mediante síntesis de voz (TTS) y el modo de repetición imitativa.
* **Señas Personalizadas:** Glosario interactivo para registrar o sobrescribir gestos analógicos personalizados en tiempo real.
* **Gesto de Espacio Único (`01011`):** Permite ingresar espacios físicos y procesar/autocorregir palabras completas en base al diccionario de 747 palabras y siglas peruanas (ONPE, SUNAT, RENIEC, UNFV, etc.).
* **Ruta de Aprendizaje:** 9 niveles educativos con cuestionarios, controles de racha diaria y exámenes de desbloqueo.

---

## 🔌 1. Guante Traductor (Firmware ESP32)

El guante utiliza una placa **ESP32-WROOM-32**, 5 sensores Flex, un módulo inercial **MPU6500** y 5 sensores de contacto de metal.

### Mapeo de Conexiones de Hardware (Pines)

| Sensor / Componente | Pin en ESP32 | Tipo de Puerto | Función / Dedo |
| :--- | :---: | :--- | :--- |
| **Flex 1** | **GPIO 36 (VP)** | Entrada Analógica (ADC1) | Dedo Pulgar |
| **Flex 2** | **GPIO 34** | Entrada Analógica (ADC1) | Dedo Índice |
| **Flex 3** | **GPIO 35** | Entrada Analógica (ADC1) | Dedo Medio |
| **Flex 4** | **GPIO 32** | Entrada Analógica (ADC1) | Dedo Anular |
| **Flex 5** | **GPIO 33** | Entrada Analógica (ADC1) | Dedo Meñique |
| **Contacto D12** | **GPIO 12** | Entrada Digital (Pull-Up) | Punta del dedo índice |
| **Contacto D13** | **GPIO 13** | Entrada Digital (Pull-Up) | Punta del dedo medio |
| **Contacto D16** | **GPIO 16** | Entrada Digital (Pull-Up) | Falange media del índice |
| **Contacto D17** | **GPIO 17** | Entrada Digital (Pull-Up) | Base del dedo medio |
| **Contacto D18** | **GPIO 18** | Entrada Digital (Pull-Up) | Base del dedo anular |
| **MPU6500 SDA** | **GPIO 21** | Bus I2C | Datos del Acelerómetro/Giro |
| **MPU6500 SCL** | **GPIO 22** | Bus I2C | Reloj del Acelerómetro/Giro |

### Configuración del Firmware en Arduino IDE:
1. Abre el archivo `esp32_firmware/esp32_firmware.ino` en el Arduino IDE.
2. Selecciona la placa **ESP32 Dev Module** (o similar).
3. Conéctalo por USB, selecciona el puerto COM y presiona **Subir**.

---

## 📱 2. Aplicación Móvil (Flutter)

La aplicación móvil procesa las señales en bruto recibidas por Bluetooth, clasifica los caracteres, aplica correcciones por distancia de edición de Levenshtein y las reproduce por voz.

### Requisitos Previos:
* Flutter SDK (Versión estable reciente)
* Android Studio (con SDK de Android instalado)

### Instrucciones para Iniciar:
1. Abre una consola/terminal en la raíz del proyecto.
2. Descarga las dependencias del proyecto:
   ```bash
   flutter pub get
   ```
3. Conecta tu celular por USB (con depuración activa) o abre un emulador, y ejecuta la app:
   ```bash
   flutter run
   ```

---

## 📡 3. Protocolo de Comunicación BLE

* **Nombre del Dispositivo:** `"GuanteLSP"`
* **UUID del Servicio GATT:** `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
* **UUID de la Característica de Datos:** `a5c7823f-1234-4688-b7f5-ea07361b2c1d` (Notificaciones a 20Hz / 50ms)
* **Formato de Trama CSV:**
  `F0,F1,F2,F3,F4,Ax,Ay,Az,Gx,Gy,Gz,D12,D13,D16,D17,D18`
