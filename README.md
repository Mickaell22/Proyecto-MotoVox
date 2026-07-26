# MotoVox

Intercomunicador para moto en tiempo real. Conecta conductor y copiloto por audio P2P sobre WiFi local con sockets TCP, sin internet ni servidor intermediario, y reducción de ruido RNNoise compilada en C nativo para ARM64.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![Sockets TCP/UDP](https://img.shields.io/badge/Sockets-TCP_%2F_UDP-4A5568?style=for-the-badge)
![C](https://img.shields.io/badge/C-00599C?style=for-the-badge&logo=c&logoColor=white)
![FFI](https://img.shields.io/badge/dart%3Affi-0175C2?style=for-the-badge)

---

## ¿Cómo funciona?

1. Un teléfono crea el **hotspot** WiFi y el otro se conecta — no hace falta internet
2. El **host** abre una sala: escucha en un puerto TCP y la anuncia por broadcast UDP cada 2 s
3. El **cliente** ve la sala en una lista y toca para conectarse (el QR queda como respaldo)
4. El audio viaja como PCM16 por el socket TCP, con `tcpNoDelay` para no acumular latencia
5. RNNoise filtra el ruido de fondo (viento, motor) antes de enviarlo

---

## Funcionalidades

- **Audio P2P en tiempo real** — sockets TCP sobre WiFi local, sin servidor intermediario
- **Descubrimiento automático de salas** — broadcast UDP, sin tipear IPs
- **Conexión vía QR** — respaldo cuando el broadcast no llega
- **Reducción de ruido** — RNNoise (C nativo compilado para ARM64 vía FFI)
- **Salas simultáneas** — puertos TCP dinámicos, cada sala independiente
- **Test de micrófono** — pantalla dedicada para verificar audio
- **Sistema de licencias** — estados: desbloqueado / prueba / vencida
- **Compartir APK** — envía el instalador directamente desde la app

---

## Stack

| Capa | Tecnología |
|------|-----------|
| Framework | Flutter (Dart) |
| Plataforma | Android (ARM64) |
| Audio | `flutter_sound` — PCM16, 16 kHz, mono |
| Reducción de ruido | RNNoise (C nativo compilado con el NDK, llamado por `dart:ffi`) |
| Transporte de audio | Sockets TCP (`dart:io`), puerto dinámico, `tcpNoDelay` |
| Descubrimiento de sala | Broadcast UDP en el puerto 8767 + `network_info_plus` |
| QR | `qr_flutter` + `mobile_scanner` |
| Persistencia | `shared_preferences` |

> **Por qué sockets crudos y no WebRTC:** el hotspot de Android bloquea UDP en la interfaz AP,
> que es justo lo que WebRTC necesita para el media path. TCP sí funciona siempre entre el AP y
> el cliente, así que el transporte se resolvió con sockets directos y descubrimiento por
> broadcast UDP. `flutter_webrtc` se eliminó del proyecto.

---

## Correr localmente

```bash
git clone https://github.com/Mickaell22/MotoVox.git
cd MotoVox
flutter pub get
flutter run
```

Requiere Android SDK y dispositivo con API 21+. Para probar el intercomunicador hacen falta
**dos teléfonos** en la misma red WiFi (o uno haciendo de hotspot): el emulador no sirve porque
el descubrimiento va por broadcast UDP.
