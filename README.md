# Dicta

Asistente de voz minimalista para iPhone, hecho en Flutter. Todo ocurre en el
dispositivo: no hay cuentas, ni servidores, ni datos que salgan del telefono.

Dictas una frase y Dicta la convierte en:

- **Nota**: se guarda en el historial.
- **Recordatorio**: se guarda y se programa una notificacion local.
- **Evento**: se guarda, se crea en el Calendario y avisa 10 minutos antes.

Los eventos y recordatorios se detectan a partir de expresiones en espanol,
por ejemplo: "manana a las 9 reunirse con Ana", "en 2 horas llamar al
fontanero" o "el viernes a las 17:00 cena".

## Estado

| Comprobacion | Resultado |
| --- | --- |
| `flutter analyze` | Sin incidencias |
| `flutter test` | 5 tests OK |
| `flutter build apk --debug` | OK |
| `flutter build ios --no-codesign` | Se compila en GitHub Actions (macOS) |

## Requisitos

- Flutter 3.41.9 (stable).
- Para generar el `.ipa`: no hace falta Mac. Se compila en GitHub Actions.
- Para instalar en el iPhone: Windows + [Sideloadly](https://sideloadly.io) y un
  Apple ID normal (gratuito).

## Paquete vendorizado

`packages/device_calendar` es una copia de `device_calendar` 3.9.0 incluida en
el repo porque la version publicada no es compatible con AGP 8 ni con el
embedding v2 de Flutter. Se han actualizado los ficheros de build de Android
(`namespace`, `compileSdk`, Java 17, entrada `FlutterPlugin`) y el target de
iOS del podspec. El resto del codigo es el original.

## Compilar el IPA

1. Sube el proyecto a un repositorio **publico** de GitHub (los minutos de
   macOS son gratis en repos publicos).
2. Ve a **Actions > Build iOS (IPA sin firmar) > Run workflow**.
3. Al terminar, descarga el artifact **Dicta-unsigned-ipa**. Dentro esta
   `Dicta-unsigned.ipa`.

El workflow ejecuta `flutter analyze`, `flutter test` y
`flutter build ios --release --no-codesign`, empaqueta `Payload/Runner.app`
y lo sube como artifact durante 30 dias.

## Instalar en el iPhone (Apple ID gratuito)

1. Instala **Sideloadly** en el PC y conecta el iPhone por USB.
   En el iPhone, pulsa **Confiar** cuando pregunte si confias en este equipo.
2. Activa el **Modo Desarrollador** en el iPhone:
   **Ajustes > Privacidad y seguridad > Modo desarrollador** (aparece despues
   de conectar el telefono al PC). Reinicia el iPhone cuando lo pida.
3. Abre Sideloadly, arrastra `Dicta-unsigned.ipa`, escribe tu Apple ID y pulsa
   **Start**. Te pedira la contrasena (y quiza un codigo de verificacion).
4. En el iPhone: **Ajustes > General > VPN y gestion de dispositivos >
   Desarrollador de la app** y pulsa **Confiar**.
5. Abre Dicta y acepta los permisos de microfono, reconocimiento de voz,
   notificaciones y calendario.

### Limites de la firma gratuita

- La app deja de abrir a los **7 dias**.
- Como maximo **3 apps** firmadas con el mismo Apple ID a la vez.
- Para renovar, vuelve a pasar el `.ipa` por Sideloadly (se reinstala
  conservando los datos).

Si te resulta incomodo renovar cada semana, puedes usar
[SideStore](https://sidestore.io), que renueva la firma automaticamente desde
el propio iPhone.

> No se puede usar TrollStore: el iPhone 12 con iOS 26/27 esta fuera del rango
> soportado (14.0 - 16.6.1 / 16.7 RC / 17.0).

## Desarrollo

```bash
flutter pub get
flutter analyze
flutter test
```

Para probar la interfaz sin iPhone:

```bash
flutter run -d windows
```

(En Windows el plugin de notificaciones necesita el componente ATL de Visual
Studio Build Tools; si no esta instalado, usa `flutter build apk` con un
Android conectado.)

## Estructura

```
lib/
  main.dart
  models/note.dart
  screens/        splash, home, compose, history, detail
  services/       nlp, speech, notifications, calendar, notes store, actions
  theme/
  utils/
  widgets/
test/
  nlp_service_test.dart
packages/
  device_calendar/  copia parcheada del plugin
```
