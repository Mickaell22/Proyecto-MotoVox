# MotoVox

App de intercomunicador para moto — piloto y copiloto, siempre abierto (sin push-to-talk), funciona sin internet.

## Principio de diseño
**Práctico y fácil de usar** — el piloto no puede distraerse. Todo debe ser 1-2 toques máximo.

## Stack actual
- **Flutter** (Android)
- **flutter_sound 9.30.x** — grabación y reproducción de audio PCM en tiempo real
- **TCP sockets (dart:io)** — transporte de audio entre dispositivos (reemplazó WebRTC)
- **Hotspot WiFi** — un teléfono crea hotspot, el otro se conecta, sin internet requerido
- **qr_flutter** — genera QR con IP+puerto para conectarse fácil
- **mobile_scanner** — escanea el QR del otro teléfono
- **RNNoise** (en progreso) — red neuronal de Mozilla para supresión de ruido, compilada como `.so` nativo ARM64 y llamada vía `dart:ffi`

## Flujo de conexión (UX)
```
Piloto                              Copiloto
  |                                     |
toca "Crear sala"                        |
sala anunciada por UDP                   |
QR visible como fallback                 |
  |                          toca "Unirse"
  |                          ve la sala en lista
  |                          toca la sala --------|
  |<============= audio activo =================>|
```

## Pantallas
1. **Inicio** — dos botones: "Crear sala" / "Unirse" + botón "Compartir app"
2. **QR** (host) — muestra QR + anuncia sala por UDP. (cliente) — escanea QR como fallback
3. **Salas disponibles** — lista de salas detectadas en la red, tap para conectar, botón "Escanear QR" al fondo
4. **Conectado** — estado de conexión, animación de audio, botón silenciar, botón desconectar

## Dispositivos de prueba
- 2 teléfonos Android (ADB ID: `103953736M000152`)
- Entorno de build: `/home/mickaell/Desktop/MotoVox`
- Flutter: `/opt/flutter/bin/flutter`
- ADB: `/home/mickaell/Android/Sdk/platform-tools/adb`

## Comandos útiles
```bash
# Analizar código (sin su — flutter analyze no necesita SDK Android)
/opt/flutter/bin/flutter analyze lib/

# Build APK (solo arm64) — ANDROID_HOME requerido, NO usar su mickaell
ANDROID_HOME=/home/mickaell/Android/Sdk \
  /opt/flutter/bin/flutter build apk --split-per-abi --target-platform android-arm64

# Instalar en dispositivo
/home/mickaell/Android/Sdk/platform-tools/adb install -r \
  build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# Limpiar caché (si el build usa código viejo)
ANDROID_HOME=/home/mickaell/Android/Sdk /opt/flutter/bin/flutter clean
```

> **Importante**: `su mickaell -c "flutter build..."` falla porque el file watcher
> de Flutter choca con el entorno de root. Usar siempre `ANDROID_HOME=... /opt/flutter/bin/flutter ...`
> directamente desde root en el directorio del proyecto.

## Dependencias actuales (pubspec.yaml)
```yaml
dependencies:
  flutter_sound: ^9.2.0          # resuelve a 9.30.0
  network_info_plus: ^4.1.0
  permission_handler: ^11.0.0
  qr_flutter: ^4.1.0
  mobile_scanner: ^3.5.6
  share_plus: ^7.2.2
  shared_preferences: ^2.2.3
  http: ^1.2.1
```

## Arquitectura actual
```
Teléfono A (host/piloto)          Teléfono B (cliente/copiloto)
  crea hotspot     <--WiFi-->       se conecta al hotspot
  ServerSocket:puerto_dinámico      UDP escucha :8767
  UDP broadcast :8767 cada 2s  -->  ve sala en lista
  muestra QR (fallback)             tap sala → Socket.connect(ip, puerto)
       <-------- audio PCM16 por TCP ------->
```

### AudioRelayService (lib/services/audio_relay_service.dart)
- Puerto TCP: **dinámico** — el SO asigna uno libre con `bind(0)`. `actualPort` expone el puerto asignado.
- Formato: PCM16, 16000 Hz, mono
- Graba con `FlutterSoundRecorder` → stream `Uint8List` → filtro de voz → envía por socket
- Recibe datos del socket → `_player.uint8ListSink`
- `AudioSource.voice_communication` — activa AEC hardware de Android
- `enableVoiceProcessing`, `enableNoiseSuppression`, `enableEchoCancellation: true`
- Filtro software actual: biquad bandpass 300 Hz–3400 Hz (HPF + LPF en cascada)
  - Elimina ruido grave del motor (< 300 Hz) y silbido de viento (> 3400 Hz)
  - Limitación: no distingue voz de otros sonidos en el mismo rango (aplausos, música)
  - Será reemplazado por RNNoise (Fase 4)

### AudioTestService (lib/services/audio_test_service.dart)
- Graba 5 segundos a archivo WAV temporal con la misma configuración que la llamada real
- Reproduce el archivo inmediatamente después para que el usuario oiga cómo suena
- Estados: `idle → recording → playing → done`
- Pantalla: `lib/screens/audio_test_screen.dart` — accesible desde Configuración → sección Audio

### RoomDiscoveryService (lib/services/room_discovery_service.dart)
- Puerto UDP discovery: `8767`
- Host: broadcast UDP a `255.255.255.255:8767` cada 2s con `{id, name, ip, port}`
- Cliente: escucha `0.0.0.0:8767`, construye lista de `RoomInfo`, expira salas a los 7s sin señal
- Soporta múltiples salas simultáneas en la misma red (cada una con puerto TCP distinto)

## Estado actual (2026-05-03) ✓
- **Conexión y transmisión de voz funcionando** — 2 teléfonos por hotspot, sin internet
- **Supresión de ruido activa** — `AudioSource.voice_communication` + flags de AEC/NS confirmados funcionando
- **Descubrimiento automático de salas** — UDP broadcast; el copiloto ve la sala en lista sin escanear QR
- **Múltiples salas simultáneas** — puertos TCP dinámicos, cada sala independiente
- **QR como fallback** — sigue disponible en la pantalla del host
- **Test de audio** — graba 5 segundos y reproduce (acceso en Configuración → Audio)
- **Filtro bandpass por software** — biquad 300 Hz–3400 Hz; elimina ruido fuera del rango de voz
- `NetworkInterface.list()` prioriza `192.168.43.x` (subred de hotspot Android)

## Pendiente
- **RNNoise Fase 3/4** — procesador de frames, integración (ver Roadmap)
- **Versioning** — nunca se ha gestionado; el app real está en `1.2.0` pero pubspec dice `1.0.0+1`
  - Agregar `package_info_plus` y leer versión dinámicamente en `settings_screen.dart`
  - Esquema: MINOR por feature nueva, PATCH por bug fix
  - Bumpar a `1.2.0+3` al iniciar la próxima sesión
- Probar calidad de audio en condiciones reales (moto en movimiento)
- Latencia — no medida todavía
- Prueba de estabilidad conexión larga duración
- Nombre de sala personalizable (actualmente "MotoVox" fijo)

## Roadmap: RNNoise (supresión de ruido ML)

RNNoise es una red neuronal recurrente (GRU) de Mozilla, ~100 KB, diseñada para separar
voz humana de cualquier otro sonido en tiempo real. Es lo que usan Discord, Zoom y similares.
Funciona en frames de **480 muestras** (30 ms a 16 kHz).

### Fase 1 — Compilar librnnoise.so para ARM64 ✓ COMPLETADA
**Resultado**: `lib/arm64-v8a/librnnoise.so` (5.75 MB) incluido en el APK.

- Fuentes en `android/app/src/main/cpp/rnnoise/` (modelo lite: `rnnoise_data_little.c`)
- `CMakeLists.txt` con `-O3 -ffast-math -DFLOAT_APPROX`
- `build.gradle.kts` con `externalNativeBuild.cmake` + `abiFilters("arm64-v8a")`
- Fixes aplicados: stub `x86/x86_arch_macros.h`, alias `rnnoise_data.h` → `rnnoise_data_little.h`, define `FLOAT_APPROX`
- Símbolos exportados: `rnnoise_create`, `rnnoise_destroy`, `rnnoise_process_frame`, `rnnoise_get_frame_size`

### Fase 2 — Dart FFI wrapper ✓ COMPLETADA
**Resultado**: `lib/native/rnnoise_ffi.dart` — carga `librnnoise.so`, expone `init()` / `processFrame()` / `dispose()`.

- `inputBuf` / `outputBuf`: buffers `Pointer<Float>` de 480 elementos reutilizables (sin copias extra)
- `processFrame()` retorna VAD probability 0.0–1.0
- Dependencia `ffi: ^2.1.0` agregada a `pubspec.yaml`

### Fase 3 — RnnoiseProcessor (buffer + conversión) ← SIGUIENTE
**Objetivo**: adaptar los chunks de flutter_sound (4096 bytes variables) al frame fijo de RNNoise (960 bytes = 480 muestras PCM16).

Archivo: `lib/services/rnnoise_processor.dart`

Lógica:
- Acumula bytes entrantes en buffer interno
- Cuando hay ≥ 960 bytes: extrae frame, convierte PCM16 → float32, llama `processFrame()`, convierte float32 → PCM16, emite
- Resto del buffer se conserva para el siguiente chunk

### Fase 4 — Integración y prueba
**Objetivo**: reemplazar el filtro bandpass con RNNoise en la llamada real y en el test de audio.

Cambios:
- `AudioRelayService._applyVoiceFilter()` → delegar a `RnnoiseProcessor`
- `AudioTestService` → pasar audio por `RnnoiseProcessor` antes de escribir al WAV
- Probar con aplausos, ruido de motor, viento — solo la voz debe pasar
- Medir latencia adicional por frame (target: < 5 ms)

## Decisiones de arquitectura
- **Se abandonó WebRTC**: UDP bloqueado en la interfaz AP de hotspot Android. TCP funciona siempre entre AP y cliente.
- **Sin push-to-talk** — distrae al conductor; siempre abierto como intercomunicador real
- **Descubrimiento por UDP broadcast** — sin tipear IP ni escanear QR; el QR queda de fallback
- **Puertos TCP dinámicos** — cada sala usa el puerto que el SO asigne, permite múltiples salas en red
- **Scope inicial**: solo piloto + copiloto (1 a 1)
- **flutter_webrtc eliminado** del proyecto — `webrtc_service.dart` y `signaling_service.dart` borrados
- **Filtro bandpass (biquad)** — solución temporal hasta integrar RNNoise; filtra frecuencias fuera del rango de voz pero no distingue voz de otros sonidos en banda
- **RNNoise vía dart:ffi** — elegido sobre plugins Flutter inexistentes; compila como `.so` con NDK y se llama directamente desde Dart sin overhead de platform channels

## Hardware futuro
- ESP32-S3 (piloto) + ESP32 normal (copiloto)
- Comunicación por ESP-NOW entre cascos
- Audio directo en el casco sin depender del teléfono
- Batería LiPo en cada casco

## Expansión futura
- Grupos de motos (más de 2 participantes)
- Mayor distancia via internet
- Integración ESP32-S3
