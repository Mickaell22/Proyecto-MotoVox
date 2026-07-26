# MotoVox

Intercomunicador para moto en tiempo real. Conecta conductor y copiloto por audio P2P sobre WiFi local mediante sockets TCP, sin servidor intermediario, con reducción de ruido RNNoise compilado en C nativo para ARM64.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![TCP Sockets](https://img.shields.io/badge/TCP_Sockets-333333?style=for-the-badge&logo=socketdotio&logoColor=white)
![C](https://img.shields.io/badge/C-00599C?style=for-the-badge&logo=c&logoColor=white)

---

## ¿Cómo funciona?

1. El **host** crea una sala y genera un código QR
2. El **cliente** escanea el QR para conectarse sin configurar IPs
3. El audio se transmite en tiempo real por la red WiFi local
4. RNNoise filtra el ruido de fondo (viento, motor) en tiempo real

---

## Funcionalidades

- **Conexión vía QR** — sin configuración manual de IP
- **Audio P2P en tiempo real** — sockets TCP sobre WiFi local, sin servidor intermediario
- **Reducción de ruido** — RNNoise (C nativo compilado para ARM64 via FFI)
- **Test de micrófono** — pantalla dedicada para verificar audio
- **Sistema de licencias** — estados: desbloqueado / prueba / vencida
- **Compartir APK** — envía el instalador directamente desde la app

---

## Stack

| Capa | Tecnología |
|------|-----------|
| Framework | Flutter (Dart) |
| Plataforma | Android (ARM64) |
| Audio | `flutter_sound` |
| Reducción de ruido | RNNoise (C nativo via FFI) |
| Red | Sockets TCP (`dart:io`) sobre WiFi local, con `tcpNoDelay` |
| QR | `qr_flutter` + `mobile_scanner` |
| Descubrimiento de sala | `network_info_plus` |
| Persistencia | `shared_preferences` |

---

## Correr localmente

```bash
git clone https://github.com/Mickaell22/Proyecto-MotoVox.git
cd Proyecto-MotoVox
flutter pub get
flutter run
```

Requiere Android SDK y dispositivo/emulador con API 21+.
