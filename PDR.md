# MelodAI: Documento de Requisitos del Producto (PRD) V2

Este documento presenta la versión optimizada de los requisitos técnicos y funcionales para el desarrollo de la aplicación móvil MelodAI, incorporando una arquitectura escalable, un stack tecnológico definido y procesos avanzados de optimización de costos y calidad.

## 1. Objetivo del Producto
Proporcionar una herramienta avanzada capaz de aislar cualquier instrumento musical de una mezcla de audio, superando las limitaciones de los modelos de separación estándar mediante la identificación dinámica de instrumentos y el uso de inteligencia artificial de vocabulario abierto. El sistema implementa un ciclo de aprendizaje continuo para reducir la dependencia de modelos costosos a largo plazo.

## 2. Arquitectura de Procesamiento Híbrido
El sistema optimiza los costos operativos y la calidad del audio mediante un enrutador inteligente que clasifica los instrumentos antes de procesarlos.

| Fase | Modelo de IA | Instrumentos | Ventaja Operativa |
| :--- | :--- | :--- | :--- |
| Fase 1 (Estándar) | HTDemucs / Spleeter | Voz, Bajo, Batería, Guitarra, Piano | Bajo costo y alta velocidad |
| Fase 2 (Específica) | AudioSep (Zero-Shot) | Violín, Bandoneón, Congas, Saxo, etc | Flexibilidad total (Prompt-based) |

## 3. Stack Tecnológico Sugerido
Para garantizar la escalabilidad y eficiencia, se define la siguiente infraestructura base:

- **Frontend:** Flutter (Arquitectura Feature-First).
- **Autenticación y Almacenamiento:** Firebase Auth y Firebase Cloud Storage (Google Cloud).
- **Orquestador:** Node.js desplegado en Google Cloud Run o Render.
- **Base de Datos:** MongoDB Atlas.
- **Motor de IA:** Python (PyTorch/TensorFlow) en RunPod o Brev.dev para acceso a GPUs económicas.
- **Colas de Trabajo:** Redis vía Upstash (Serverless).

## 4. Optimizaciones Críticas de Arquitectura
Se han integrado mejoras de nivel Senior para la eficiencia del sistema:

1. **Carga vía Presigned URLs:** La aplicación Flutter sube archivos (MP3, WAV, FLAC, M4A) directamente al bucket. El backend solo gestiona el enlace seguro, eliminando la carga de tráfico pesado en el orquestador Node.js.
2. **Deduplicación por Hash (Caché):** Cálculo de SHA-256 en el cliente. Si la canción ya fue procesada, el sistema devuelve inmediatamente las URLs de las pistas (stems) existentes, reduciendo el gasto de GPU a cero.
3. **Pre-calentamiento de GPU:** El escaneo inicial (Audio Tagging) identifica si se requiere la Fase 2. Si es así, se envía una señal a través de Redis para escalar instancias de GPU antes de que la cola de inferencia se sature.

## 5. Ciclo de Aprendizaje Continuo (Data Flywheel)
El sistema reduce la dependencia de la Fase 2 mediante un flujo de retroalimentación automática:

- **Captura:** Almacenamiento de pistas generadas por el modelo Zero-Shot en un Data Lake.
- **Filtro de Calidad Avanzado:** Validación mediante análisis de **SDR (Signal-to-Distortion Ratio)** y **SIR (Signal-to-Interference Ratio)**. Se descartan archivos con deformaciones de fase o sangrado excesivo.
- **Dataset Incremental y Reentrenamiento:** Acumulación de pistas limpias para actualizar periódicamente el modelo de la Fase 1 (Fine-Tuning).

## 6. Desarrollo de Interfaz y Mixer
El mezclador dinámico debe garantizar un rendimiento fluido en dispositivos móviles:

- **Concurrencia de Audio:** Delegación del motor de reproducción a **Isolates** en Dart o uso de **MethodChannels** para ejecutar la mezcla en código nativo (C++/Kotlin/Swift).
- **Interfaz Adaptativa:** Generación dinámica de controles (faders, mute, solo) según la cantidad de pistas devueltas por el Motor IA.
- **Exportación:** Descarga de pistas individuales o paquetes comprimidos ZIP.
