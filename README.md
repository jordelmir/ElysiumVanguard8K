# ProPlayer — El reproductor de video nativo y definitivo para macOS

**Resumen Ejecutivo:**
ProPlayer es un reproductor de video de nivel mundial para macOS diseñado para ofrecer la experiencia de visualización definitiva en pantallas Retina. Desarrollado nativamente con SwiftUI y el framework AVFoundation, provee 5 algoritmos avanzados de escalado de pantalla (Fit, Fill, Stretch, Smart Fill, Custom Zoom), librerías organizadas y controles de reproducción meticulosamente optimizados. Está diseñado sin compromisos para extraer el máximo rendimiento de la arquitectura Apple Silicon (M1+), entregando aceleración por hardware con cero latencia y una interfaz de usuario "glassmorphism" sumamente inmersiva.

---

## 2. Contexto del Sistema (Especificaciones)

| Especificación | Valor |
| :--- | :--- |
| **Sistema Operativo** | macOS 14.0+ (Optimizado para macOS 15+ Sequoia) |
| **Lenguaje de Programación** | Swift 6.2.3 |
| **Entorno de Desarrollo (IDE)** | Compilado vía Swift Package Manager (CLI) / Xcode 16.2 |
| **Arquitectura Objetivo** | Apple Silicon (arm64, M1, M2, M3, M4) |
| **Resolución Objetivo** | 2560×1600 Retina (MacBook Air) y superior |
| **Motores y APIs Core** | AVFoundation, CoreMedia, SwiftUI, Metal (vía AVPlayerLayer) |
| **Control de Paquetes** | Swift Package Manager (SPM) |

---

## 3. Arquitectura del Sistema (Jerarquía)

La aplicación implementa el patrón de arquitectura **MVVM (Model-View-ViewModel)** combinado con inyección de estado manejado por SwiftUI (`@StateObject`, `@ObservedObject`), estructurado para aislamiento de responsabilidades y modularidad extrema:

*   **App Core** (`ProPlayerApp`)
    *   **Views** (Capa de Presentación SwiftUI)
        *   `MainView` (Controlador Maestro de Navegación)
        *   `PlayerView` (Contenedor de Reproducción)
            *   `VideoLayerView` (Envoltorio NSViewRepresentable para AVPlayerLayer y Metal)
            *   `ControlsOverlay` (Panel de Control y HUD)
            *   `TimelineView` (Barra de progreso algorítmica y A-B bounds)
            *   `OSDView` (On-Screen Display de respuesta rápida)
        *   `LibraryView` (Navegador jerárquico de medios y Layouts)
        *   `SettingsView` (Gestión de configuración)
    *   **ViewModels** (Lógica de Negocio y Presentación)
        *   `PlayerViewModel` (Orquestador de comandos de reproducción y estado UI)
        *   `LibraryViewModel` (Gestor asíncrono de persistencia y metabúsqueda)
    *   **Core Engine** (Capa de Dominio y Hardware)
        *   `PlayerEngine` (Wrapper reactivo de `AVPlayer`, despachador de señales de hardware)
    *   **Models** (Entidades de Datos y Dominio)
        *   `VideoItem`, `Playlist`, `PlayerSettings`
    *   **Utils** (Servicios compartidos)
        *   `VideoMetadataExtractor`, `FormatUtils`, `Theme`

---

## 4. Desglose de Implementación

### Configuración del Sistema
*   **[NUEVO]** `Package.swift`
    *   **Responsabilidad:** Declaración de producto ejecutable, define targets y plataformas (macOS v14+), y habilita banderas de concurrencia extricta de Swift 6.
*   **[NUEVO]** `Sources/ProPlayer/Info.plist`
    *   **Responsabilidad:** Metadatos del binario (Bundle ID), asociaciones de extensiones de archivo (MP4, MKV, AVI, etc.) y permisos del Sandbox.
*   **[NUEVO]** `Sources/ProPlayer/ProPlayerApp.swift`
    *   **Responsabilidad:** Ciclo de vida principal, inyección de `MainView`, configuración de la ventana (`WindowGroup`), y mapeo de sub-rutinas globales del `CommandGroup` (Menú de macOS) a notificaciones reactivas.

### Core Engine y Motores
*   **[NUEVO]** `Sources/ProPlayer/Engine/PlayerEngine.swift`
    *   **Responsabilidad:** Núcleo interactivo con `AVFoundation`.
    *   **Características:** Maneja `AVPlayer`, `AVPlayerItem`, KVO (Key-Value Observing) para dimensiones de video, tiempo buffer (+100ms de precisión) y captura asíncrona de snapshots (frame grabbing).
    *   **Estado:** `@Published` para estado de reproducción, progreso, offsets de A-B Loop, y `AVMediaSelectionGroup` para pistas.
*   **[NUEVO]** `Sources/ProPlayer/Utilities/VideoMetadataExtractor.swift`
    *   **Responsabilidad:** Servicio utilitario de red/IO.
    *   **Características:** Usa `AVAssetImageGenerator` concurentemente (`async`/`await`) para generar thumbnails sin bloquear el UI thread, y parser de FourCC para códecs.

### Subsistema de UI y Modelos
*   **[NUEVO]** `Sources/ProPlayer/Views/Player/VideoLayerView.swift`
    *   **Responsabilidad:** Renderizado RAW en pantalla.
    *   **Características:** Envuelve un `NSView` que expone un `AVPlayerLayer` para aprovechar la aceleración por GPU (Metal). Implementa las lógicas matemáticas para el **Smart Fill** customizado (máximo 15% de stretch algorítmico).
*   **[NUEVO]** `Sources/ProPlayer/ViewModels/PlayerViewModel.swift`
    *   **Responsabilidad:** Coordina la UI del reproductor.
    *   **Características:** Expone rutinas `togglePlayPause()`, `seek()`, `cycleGravityMode()`. Delega el trabajo pesado a `PlayerEngine`. Controla el *auto-hide* del overlay usando `Timer.scheduledTimer`.
*   **[NUEVO]** `Sources/ProPlayer/Views/Player/PlayerView.swift`
    *   **Responsabilidad:** Composición principal de UI para visualización.
    *   **Características:** Soporte de `Drag & Drop`, gestos de trackpad (`MagnifyGesture`), intercepción de eventos de teclado mediante `NSViewRepresentable` de teclado custom y Context Menus.
*   **[NUEVO]** `Sources/ProPlayer/Models/VideoItem.swift` y `PlayerSettings.swift`
    *   **Responsabilidad:** Estructuras `Codable` para configuración de usuario persistida de manera local en `Application Support`, y modelado estructurado de los activos indexados.

---

## 5. Plan de Verificación y Pruebas

### Verificación Automatizada

Utiliza el administrador de paquetes Swift (SPM) nativo de la cadena de compilación de Apple para generar un binario de producción optimizado (Release).

```bash
# Navegar a la raíz del proyecto
cd "/Users/jordelmirsdevhome/Downloads/PoC/Plataforma pedagogica progracion con ia"

# Compilar en modo Release con optimización de código activa
swift build -c release

# Validar que el binario existe y es ejecutable
file .build/release/ProPlayer
```
*Criterio de éxito:* El compilador debe finalizar la tarea sin códigos de error (`Exit code: 0`), y el archivo binario debe crearse y estar designado para arm64 / mach-o.

### Verificación Manual (QA del Usuario)

Ejecuta el bundle `.app` y somételo al siguiente protocolo de estrés:

1.  **Doble clic a `ProPlayer.app`**: Valida que la aplicación carga instantáneamente una pestaña gris/transparente de Galería ("Library").
2.  **Importación por Arrastre (Drag & Drop)**: Suelta un archivo de video (por ejemplo un `.mp4` o `.mov` de prueba) sobre la interfaz. Verifica que la aplicación cambia automáticamente de vista e inicia la reproducción en tiempo real.
3.  **Auditoría de Adaptación Completa de Pantalla**: 
    - Presiona la tecla `A` o usa el ícono en la barra superior.
    - Cíclicamente alterna a través de los estados: **Fit** -> **Fill** -> **Stretch** -> **Smart Fill** -> **Custom Zoom**.
    - *Asegúrate* de que el modo **Stretch** fuerce al video a ocupar absolutamente cada píxel de la resolución 2560x1600 Retina del M1 sin conservar líneas negras, y que el **Smart Fill** ofrezca un escalado de compromiso con mínima distorsión facial o estructural.
4.  **Flujos de Telemetría UI (Atajos)**:
    - Pulsa la barra `Espaciadora` secuencialmente para Pausa/Reproducción.
    - Emplea las flechas del teclado `← / →` y valida saltos precisos de 5 segundos.
    - Pulsa `F` para transicionar a pantalla completa verdadera (Full-Screen nativo System-wide).
5.  **A-B Loop Core**: Pulsa `R` en un segundo específico, reproduce un par de segundos, y pulsa `R` nuevamente. La reproducción debe entrar en un salto cíclico infinito entre esas marcas (bucle de entrenamiento) sin pausas de *buffering*.
6.  **Captura en Memoria Directa**: Oprime `S`. Abre el gestor de archivos (`Finder`) en tu carpeta "Imágenes" (o Pictures) y constata la existencia del snapshot originario desde los buffers de `AVFoundation` en formato PNG full HD.
