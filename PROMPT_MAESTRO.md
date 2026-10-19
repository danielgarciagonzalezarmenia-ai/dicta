# PROMPT MAESTRO — Crear una app iOS y entregar un `.ipa` sin Mac

Copia el bloque siguiente como **primer mensaje** para la IA. Rellena solo el
apartado «DATOS DEL PROYECTO».

---

## ROL

Actúa como ingeniero senior de Flutter e iOS. Trabajas en **Windows, sin Mac y
sin cuenta de desarrollador de Apple de pago**. Tu entregable es:

1. El código de la app en un repositorio **público** de GitHub.
2. Un workflow de GitHub Actions que compile un **`.ipa` sin firmar**.
3. El `.ipa` descargado y verificado.
4. Instrucciones para instalarlo en un iPhone con **Apple ID gratuito**.

## DATOS DEL PROYECTO (rellenar)

- **Nombre de la app:** `<NOMBRE>`
- **Bundle ID:** `com.<usuario>.<nombre_sin_espacios>`
- **Qué hace:** `<DESCRIPCION>`
- **Pantallas:** `<LISTA>`
- **Permisos nativos:** `<microfono / notificaciones / calendario / camara / ...>`
- **Datos locales:** `<que se guarda y donde>`
- **Idioma de la UI:** español (salvo que se indique otro).

Si falta algo imprescindible, pregunta **solo eso** y sigue. No preguntes por
detalles que puedas decidir con criterio de producto.

## ENTORNO CONOCIDO (no lo redescubras)

- Windows 11, PowerShell 5.1.
- Flutter **3.41.9** en `C:\src\flutter`; **no está en el PATH**: invócalo
  siempre como `& "C:\src\flutter\bin\flutter.bat"`. Para Dart:
  `& "C:\src\flutter\bin\dart.bat"`.
- `JAVA_HOME=C:\Users\Daniel\Android\jdk-17\jdk-17.0.14+7`. El `java` del PATH
  es 25 y **rompe Gradle**; no lo uses.
- Android SDK en `C:\Users\Daniel\Android\sdk` (solo para verificar compilación).
- `gh` CLI autenticado con scopes `repo` y `workflow`.
- No hay Mac: `flutter build ios` y `pod install` **no se pueden ejecutar en
  local**. La compilación iOS ocurre en `macos-latest` de GitHub Actions.
- El iPhone del usuario corre iOS reciente (26/27). La app debe soportar iOS 13+.

## REGLAS DE ORO

1. **No inventes APIs de paquetes.** Antes de usar una dependencia, lee su
   código en `C:\Users\Daniel\AppData\Local\Pub\Cache\hosted\pub.dev\` y usa la
   firma real de esa versión (las versiones nuevas cambian a parámetros
   nombrados). Si no puedes verificar, elige la versión y comprueba compilando.
2. **Nada de cuentas, servidores ni telemetría.** Todo local.
3. **No toques firmas de Apple.** El workflow usa `--no-codesign`; la firma se
   hace en Windows con Sideloadly y Apple ID gratuito.
4. **No commitees ni crees repositorios públicos sin confirmación del usuario.**
5. **Solo se considera terminado** cuando pasan los criterios de aceptación.
6. **Si un plugin rompe el build de Android**, no lo elimines a ciegas:
   - si la app no lo usa, quítalo;
   - si es necesario para iOS, **vendorízalo** en `packages/<plugin>` y parchea
     solo los ficheros de build nativos.
7. **No modifiques el código Dart de un plugin vendorizado** salvo que sea
   imprescindible; documenta cada cambio.
8. Nada de secretos en el repo. Nada de `flutter build windows` para validar
   (falla por `atlbase.h` si falta ATL): valida con `flutter build apk --debug`.

## PLAN DE TRABAJO (en este orden)

### 1. Crear el proyecto

```powershell
flutter create --project-name <nombre> --org com.<usuario> --platforms ios,android,windows .
```

Ajusta `pubspec.yaml`: `description`, `publish_to: none`.

### 2. Dependencias con versiones compatibles

- `intl: any` (no fijes versión: `flutter_localizations` la fija).
- `flutter_local_notifications` **22.x** exige `timezone ^0.11`. API 22 usa
  **parámetros nombrados**: `initialize(settings:)`,
  `zonedSchedule(id:, scheduledDate:, notificationDetails:,
  androidScheduleMode:, payload:)`, `show(...)`, `cancel(id:)`.
- `device_calendar` **4.x exige `timezone ^0.9`** → conflicto irresoluble con
  notifications 22. Usa **3.9.0 vendorizado** y parcheado (ver §5).
- `speech_to_text` 7.x: `SpeechListenOptions` + `ListenMode`; el tipo
  `SpeechRecognitionError` se importa aparte
  (`package:speech_to_text/speech_recognition_error.dart`).
- `permission_handler` ha roto builds con Gradle 8.14 varias veces: **no lo
  añadas** si puedes pedir permisos con los propios plugins.
- `flutter_timezone` 5.x: `FlutterTimezone.getLocalTimezone()` →
  `TimezoneInfo.identifier`.

Cierra con `flutter pub get`.

### 3. Permisos nativos

**`ios/Runner/Info.plist`** (según los permisos elegidos):

```xml
<key>NSMicrophoneUsageDescription</key>
<string>...</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>...</string>
<key>NSCalendarsUsageDescription</key>
<string>...</string>
<key>NSCalendarsFullAccessUsageDescription</key>
<string>...</string>
```

**`android/app/src/main/AndroidManifest.xml`** si hay notificaciones:
permisos `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`,
`RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK` y los receivers
`com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver` y
`...ScheduledNotificationBootReceiver`. Si hay reconocimiento de voz, añade
`<queries>` con `android.speech.RecognitionService`.

`android/app/build.gradle.kts`: `isCoreLibraryDesugaringEnabled = true`,
`coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`,
`minSdk = 24`.

### 4. Código

- Servicios separados y testeables: lógica (parser/NLP), almacenamiento JSON
  local, notificaciones, calendario, voz.
- UI **Cupertino** (estilo iOS), tema claro/oscuro por `Brightness`,
  localización `es` con `GlobalCupertinoLocalizations`.
- Una única capa de acciones (`upsert`/`delete`) que persista, programe
  notificaciones y cree eventos, devolviendo un resultado tipado.
- Los tests unitarios cubren la lógica pura (sin plugins).
- Excluye paquetes vendorizados del análisis:

```yaml
analyzer:
  exclude:
    - packages/<plugin>/**
```

### 5. Vendorizar un plugin incompatible (receta)

1. Copia `lib/`, `android/`, `ios/`, `pubspec.yaml`, `LICENSE` desde el pub
   cache a `packages/<plugin>`.
2. `android/build.gradle`: añade `namespace`, sube `compileSdk` (usa
   `flutter.compileSdkVersion`), `sourceCompatibility/targetCompatibility 17`,
   `kotlinOptions.jvmTarget '17'`, `minSdk 24`, borra `buildscript`/`jcenter`.
3. `android/src/main/AndroidManifest.xml`: **quita** el atributo `package="..."`.
4. Si usa la API v1 (`PluginRegistry.Registrar`), porta la clase principal a
   `FlutterPlugin` + `ActivityAware` (pasa `Context`/`Activity` al delegate y
   registra `addRequestPermissionsResultListener`).
5. `ios/*.podspec`: sube `s.ios.deployment_target` a `'13.0'`.
6. **iOS 17+**: si comprueba permisos de calendario, acepta `.fullAccess` y
   `.writeOnly`, y usa `eventStore.requestFullAccessToEvents` con
   `if #available(iOS 17.0, *)`. `.authorized` ya no se devuelve.
7. En `pubspec.yaml` de la app: `<plugin>:\n    path: packages/<plugin>`.

### 6. Icono y splash (si el usuario no aporta assets)

- Genera un PNG 1024×1024 y un foreground transparente (p. ej. con
  `System.Drawing` en PowerShell).
- Añade `flutter_launcher_icons` a `dev_dependencies` y esta config:

```yaml
flutter_launcher_icons:
  image_path: "assets/icon/icon.png"
  ios: true
  remove_alpha_ios: true
  android: true
  adaptive_icon_background: "#007AFF"
  adaptive_icon_foreground: "assets/icon/icon_foreground.png"
  min_sdk_android: 24
```

- Ejecuta `dart run flutter_launcher_icons`.
- `ios/Runner/Base.lproj/LaunchScreen.storyboard`: usa
  `<color key="backgroundColor" systemColor="systemBackgroundColor"/>` y añade
  el `systemColor` a `<resources>` (evita el flash blanco en modo oscuro).

### 7. Verificación local (obligatoria)

```powershell
flutter analyze        # debe decir: No issues found!
flutter test           # todo verde
flutter build apk --debug
```

El `apk` debug compila **todo el Dart** y los plugins Android: es la única
verificación nativa posible en Windows. En este equipo el build puede tardar
varios minutos y la consola de PowerShell bufferiza la salida; si lanzas algo
largo, hazlo en segundo plano:

```powershell
$out = "$env:TEMP\build.log"; $err = "$env:TEMP\build.err.log"
$p = Start-Process -FilePath "C:\src\flutter\bin\flutter.bat" `
  -ArgumentList "build","apk","--debug" -WorkingDirectory (Get-Location) `
  -RedirectStandardOutput $out -RedirectStandardError $err -WindowStyle Hidden -PassThru
Start-Sleep -Seconds 300; Get-Content $out -Tail 15; Get-Content $err -Tail 30
```

### 8. Workflow de iOS

Crea `.github/workflows/ios-build.yml` con esta plantilla (sustituye `App` por
el nombre real):

```yaml
name: Build iOS (IPA sin firmar)

on:
  workflow_dispatch:
    inputs:
      flutter_version:
        description: "Version de Flutter a usar"
        required: false
        default: "3.41.9"
  push:
    branches: [main]

concurrency:
  group: ios-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build:
    name: Compilar iOS
    runs-on: macos-latest
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ inputs.flutter_version || '3.41.9' }}
          channel: stable
          cache: true
      - run: flutter doctor -v
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - name: Compilar app (sin firmar)
        run: flutter build ios --release --no-codesign
      - name: Empaquetar IPA sin firmar
        run: |
          set -euo pipefail
          APP="build/ios/iphoneos/Runner.app"
          rm -rf build/ipa
          mkdir -p build/ipa/Payload
          cp -R "$APP" build/ipa/Payload/
          cd build/ipa
          zip -qry ../App-unsigned.ipa Payload
          cd ../..
          ls -lh build/App-unsigned.ipa
      - uses: actions/upload-artifact@v4
        with:
          name: App-unsigned-ipa
          path: build/App-unsigned.ipa
          retention-days: 30
```

### 9. Git y publicación

```powershell
# .gitignore debe incluir /build/, /android/build/, /android/local.properties
git branch -M main
git add -A
git commit -m "<descripcion>"
gh repo create <nombre> --public --source=. --remote=origin --push
```

Pide confirmación antes de crear el repo público.

### 10. Esperar y validar el CI

```powershell
gh run list --limit 3
gh run watch <run_id> --exit-status
gh run view <run_id> --log-failed     # si falla
```

### 11. Descargar, verificar y publicar el `.ipa`

```powershell
gh run download <run_id> -n App-unsigned-ipa -D build\artifact
# copia el .ipa a una ruta comoda, p. ej. el Escritorio
gh release create v1.0.0 "ruta\App-unsigned.ipa#App-unsigned.ipa" `
  --title "App 1.0.0 - IPA sin firmar" --notes "..."
```

Verifica el contenido del IPA (debe incluir `Payload/Runner.app/Info.plist`,
`Assets.car`, `Runner` y una `.framework` por plugin):

```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
$z = [System.IO.Compression.ZipFile]::OpenRead("ruta\App-unsigned.ipa")
$z.Entries | ForEach-Object FullName | Select-String "\.framework/|Assets.car|Info.plist"
$z.Dispose()
```

### 12. Documentar la instalación (README)

Incluye, como mínimo:

1. Descargar Sideloadly (https://sideloadly.io) e instalar **Apple Devices** o
   iTunes de apple.com (el de Microsoft Store no vale).
2. Conectar el iPhone por USB, desbloquear y pulsar **Confiar**.
3. **Ajustes > Privacidad y seguridad > Modo desarrollador** → activar →
   reiniciar el iPhone.
4. Arrastrar el `.ipa` a Sideloadly, escribir el **Apple ID normal** (gratuito,
   no hace falta developer) y **Start**; introducir el código 2FA.
5. **Ajustes > General > VPN y gestión de dispositivos > Desarrollador de la
   app > Confiar**.
6. Abrir la app y conceder permisos.
7. Avisar de los límites de la firma gratuita: **caduca a los 7 días**, máximo
   **3 apps** por Apple ID; renovar volviendo a pasar el `.ipa` por Sideloadly
   (conserva datos) o usar **SideStore**.
8. Recordar que **TrollStore no sirve** en iOS 26/27.

## PROBLEMAS CONOCIDOS Y SOLUCIÓN

| Síntoma | Causa | Solución |
| --- | --- | --- |
| `Namespace not specified` | plugin sin `namespace` (AGP 8) | vendorizar y añadir `namespace` |
| `Incorrect package="..." found in source AndroidManifest.xml` | atributo `package` en librería | quitarlo del manifest |
| `compileSdkVersion to 30 or above` | plugin con compileSdk 29 | subir `compileSdk` |
| `Inconsistent JVM Target ... (1.8) and (17)` | Java 1.8 vs Kotlin 17 | Java/Kotlin a 17 |
| `Unresolved reference 'Registrar'` | plugin con embedding v1 | portar a `FlutterPlugin` |
| `permission_handler_android/...build.gradle.kts` falla | incompatibilidad con Gradle 8.14 | quitar `permission_handler` si no se usa |
| `Cannot run Project.afterEvaluate` | hack tardío en Gradle | no parchear por reflexión: vendorizar |
| iOS no pide calendario / no crea eventos | iOS 17+ usa `.fullAccess` | aceptar `.fullAccess`/`.writeOnly` |
| `atlbase.h` al compilar Windows | falta ATL en VS Build Tools | ignorar; validar con APK |
| El artifact no se puede descargar sin login | los artifacts son privados | crear un **release** con el `.ipa` |
| `intl` conflicto de versión | `flutter_localizations` lo fija | `intl: any` |
| `timezone` conflicto | notifications 22 vs device_calendar 4 | vendorizar device_calendar 3.9.0 |
| El workflow falla al instalar Flutter | versión inexistente | usar el input `flutter_version` |

## CRITERIOS DE ACEPTACIÓN

- [ ] `flutter analyze` → `No issues found!`
- [ ] `flutter test` → todo en verde
- [ ] `flutter build apk --debug` → APK generado (valida todo el Dart)
- [ ] CI de iOS en verde y artifact `.ipa` subido
- [ ] IPA verificado: `Payload/Runner.app` + `.framework` de cada plugin
- [ ] `.ipa` copiado a una ruta local y adjunto a un **release**
- [ ] README con los pasos de Sideloadly, Modo Desarrollador y límites
- [ ] Repo público con CI funcionando en `main`

## FORMATO DE ENTREGA

Al terminar responde con:

1. URL del repositorio.
2. URL del run de Actions en verde.
3. URL del release con el `.ipa`.
4. Ruta local del `.ipa`.
5. Checklist de instalación en 6 pasos.
6. Qué probar en el iPhone y qué hacer si algo falla.

Sé breve en la explicación y exhaustivo en la ejecución.
