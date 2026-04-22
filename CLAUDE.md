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

## Flujo de conexión (UX)
```
Piloto                          Copiloto
  |                                 |
toca "Crear"                        |
aparece QR en pantalla              |
  |                      toca "Unirse"
  |                      escanea QR--|
  |<========= audio activo ========>|
```

## Pantallas
1. **Inicio** — dos botones: "Crear sala" / "Unirse" + botón "Compartir app"
2. **QR** — muestra el QR (Host) o abre cámara (Cliente)
3. **Conectado** — estado de conexión, animación de audio, botón silenciar, botón desconectar

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
Teléfono A (host/piloto)       Teléfono B (cliente/copiloto)
  crea hotspot     <--WiFi-->    se conecta al hotspot
  ServerSocket:8766              Socket.connect(:8766)
  muestra QR {ip,port}           escanea QR
       <-------- audio PCM16 por TCP ------->
```

### AudioRelayService (lib/services/audio_relay_service.dart)
- Puerto TCP: `8766`
- Formato: PCM16, 16000 Hz, mono
- Graba con `FlutterSoundRecorder` → stream `Uint8List` → envía por socket
- Recibe datos del socket → `_player.uint8ListSink`
- `AudioSource.voice_communication` — intenta activar AEC hardware de Android
- `enableVoiceProcessing`, `enableNoiseSuppression`, `enableEchoCancellation: true`

## Estado actual (2026-04-22) ✓
- **Conexión y transmisión de voz funcionando** — 2 teléfonos por hotspot, sin internet
- **Supresión de ruido activa** — `AudioSource.voice_communication` + flags de AEC/NS confirmados funcionando (pendiente prueba a fondo en moto con ruido real)
- `NetworkInterface.list()` prioriza `192.168.43.x` (subred de hotspot Android), luego `192.168.x` / `10.x`

## Pendiente
- Probar calidad de audio y supresión de ruido en condiciones reales (moto en movimiento, ruido de viento/motor)
- Latencia — no medida todavía
- Prueba de estabilidad conexión larga duración

## Decisiones de arquitectura
- **Se abandonó WebRTC**: UDP bloqueado en la interfaz AP de hotspot Android. TCP funciona siempre entre AP y cliente.
- **Sin push-to-talk** — distrae al conductor; siempre abierto como intercomunicador real
- **Conexión por QR** — sin tipear IP manualmente
- **Scope inicial**: solo piloto + copiloto (1 a 1)
- **flutter_webrtc eliminado** del proyecto — `webrtc_service.dart` y `signaling_service.dart` borrados

## Hardware futuro
- ESP32-S3 (piloto) + ESP32 normal (copiloto)
- Comunicación por ESP-NOW entre cascos
- Audio directo en el casco sin depender del teléfono
- Batería LiPo en cada casco

## Expansión futura
- Grupos de motos (más de 2 participantes)
- Mayor distancia via internet
- Integración ESP32-S3
