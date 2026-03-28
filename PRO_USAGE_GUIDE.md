# ProPlayer Elite v11.0: Guía de Uso Profesional

Bienvenido a la cima de la reproducción multimedia en macOS. Esta guía detalla cómo aprovechar al máximo el motor **Elite v11.0**.

## 1. Motor de Renderizado Metal
ProPlayer utiliza un pipeline de GPU de baja latencia con capacidades de post-procesamiento avanzadas.

### Super-Resolución (SR)
*   **Qué es**: Un algoritmo de *Contrast Adaptive Sharpening* (CAS) que escala contenido 1080p a 2K/4K eliminando el desenfoque del escalado tradicional.
*   **Activación**: `Ajustes > Video > Elite Rendering > Super-Resolution`.
*   **Impacto**: Mejora drástica en la nitidez de bordes y texturas sin penalización notable de FPS.

### Smart Fill (Max)
*   **Propósito**: Diseñado para pantallas ultra-wide y 16:10.
*   **Funcionamiento**: Realiza un re-encuadre inteligente para llenar la pantalla minimizando la distorsión geométrica en el centro de la imagen.

### Ambient Mode
*   **Inmersión**: Genera un aura dinámica basada en los colores promedio de los bordes del video mediante un kernel de desenfoque gaussiano de 15 pasos.
*   **Control**: Ajusta la intensidad en `Ajustes > Video > Ambient intensity`.

## 2. Flujo de Trabajo y UX
*   **Auto-Play**: El motor inicia la reproducción instantáneamente al seleccionar cualquier archivo desde la librería o vía CLI.
*   **Gestión de Ajustes**: Usa el botón "Hecho" en la barra superior para guardar y cerrar de forma segura el panel de control.
*   **Telemetría**: Activa el OSD para visualizar el estado del motor en tiempo real.

## 3. Comandos Rápidos (CLI)
Domina la plataforma desde la terminal:
```bash
# Abrir un archivo directamente en modo 4K
proplayer open "ruta/al/video.mp4"

# Limpiar caché de renderizado
proplayer clean
```

---
*ProPlayer Elite: Diseñado por ingenieros para cinéfilos.*
