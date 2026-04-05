# MotoVox

App de intercomunicador para moto — piloto y copiloto, siempre abierto (sin push-to-talk), funciona sin internet.

## Principio de diseño
**Práctico y fácil de usar** — el piloto no puede distraerse. Todo debe ser 1-2 toques máximo.

## Stack
- **Flutter** (Android)
- **flutter_webrtc** — audio en tiempo real, cancelación de eco, VAD incluidos
- **RNNoise** — supresión de ruido de viento y motor
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
3. **Conectado** — estado de conexión, nivel de audio, botón desconectar

## Objetivo del primer sprint (viernes 2026-04-03)
- Conectar 2 teléfonos Android por hotspot
- Audio bidireccional siempre activo
- Conexión via QR sin tipear nada
- Sin login, sin grupos, sin diseño elaborado — que funcione y suene bien

## Dispositivos de prueba
- 2 teléfonos Android

## Decisiones tomadas
- Sin push-to-talk (distrae al conductor)
- Siempre abierto como intercomunicador real
- Conexión por QR — sin tipear IP manualmente
- Scope inicial: solo piloto + copiloto (1 a 1)
- Expansión futura: grupos de motos, mayor distancia via internet, integración ESP32-S3

## Hardware futuro
- ESP32-S3 (piloto) + ESP32 normal (copiloto)
- Comunicación por ESP-NOW entre cascos
- Audio directo en el casco sin depender del teléfono
- Batería LiPo en cada casco

## Dependencias principales
```yaml
dependencies:
  flutter_webrtc: ^0.9.47
  network_info_plus: ^4.1.0
  permission_handler: ^11.0.0
  qr_flutter: ^4.1.0
  mobile_scanner: ^3.5.6
  share_plus: ^7.2.2
```

## Arquitectura básica
```
Teléfono A (host)          Teléfono B (cliente)
  crea hotspot    <--WiFi-->  se conecta al hotspot
  muestra QR                  escanea QR
  WebRTC offer               WebRTC answer
       <-------- audio ------->
```
