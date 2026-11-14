# 🎬 NovaDrama

Aplicación móvil desarrollada en **Flutter** para descubrir, buscar y reproducir dramas cortos verticales (estilo ReelShort, NetShort, DramaBox, ShortMax).

---

## 🚀 Características Principales

* **Reproductor Vertical Interactivo (Estilo TikTok / ReelShort):**
  * Deslizamiento vertical (*swipe up / swipe down*) para avanzar o retroceder entre episodios de forma fluida.
  * **Doble toque en pantalla:**
    * Lado derecho: adelanta 10 segundos (`+10s`) con animación.
    * Lado izquierdo: retrocede 10 segundos (`-10s`) con animación.
  * **Control de Encuadre Inteligente:**
    * *Enfocar Drama (Derecha):* Centra el video recortando el fondo de pantalla dividida típico de resubidos anti-copyright.
    * *Pantalla Completa:* Zoom centrado sin bordes negros.
    * *Original Completo:* Muestra el video entero sin recortes.
  * **Zoom Libre:** Soporte para pellizcar con dos dedos (*pinch-to-zoom*) y arrastrar la imagen a gusto.
  * Selector modal rápido de episodios (1 al 45+) en cuadrícula interactiva.
  * Selector de velocidad (0.75x, 1.0x, 1.25x, 1.5x, 2.0x).
  * Pantalla siempre encendida (*Wakelock*) durante la reproducción.

* **Búsqueda Reactiva en Tiempo Real (Live Search):**
  * Filtrado instantáneo de coincidencias locales en memoria mientras tecleas.
  * Consulta profunda en red con debounce automático (400ms) sin necesidad de presionar "Enter".
  * Eliminación de límites artificiales para indexar todos los capítulos y series disponibles.

* **Catálogo y Categorías:**
  * Categorías temáticas: *Tendencias*, *CEO y Multimillonarios*, *Venganza*, *Fantasía*, *Romance*, etc.
  * Sección **Continuar Viendo** con restauración exacta del minuto y segundo donde pausaste.
  * Posibilidad de eliminar series del historial con un solo toque (`✕`).
  * Sección de **Favoritos** persistente con `SharedPreferences`.

* **Actualización Remota Automática (OTA Updater):**
  * Consulta automática a GitHub Releases (`AngelGuevara04/NovaDrama`).
  * Descarga del `.apk` con barra de progreso en tiempo real (MB y porcentaje).
  * Instalador nativo de Android mediante `MethodChannel` (`FileProvider`).

---

## 🛠️ Tecnologías y Dependencias

* **Framework:** Flutter 3.44+ / Dart 3.12+
* **Reproductor de Video:** `video_player: ^2.14.1`
* **Streaming y Extracción:** `youtube_explode_dart: ^3.1.0`
* **Gestión de Estado:** `provider: ^6.1.5+1`
* **Almacenamiento Local:** `shared_preferences: ^2.5.6`
* **Imágenes y Caché:** `cached_network_image: ^4.0.3`
* **Tipografía:** `google_fonts: ^8.2.1` (Outfit)
* **Pantalla Activa:** `wakelock_plus: ^1.8.2`

---

## 📥 Restauración tras formatear la PC

Una vez reinstalado Git y Flutter en tu equipo:

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/AngelGuevara04/NovaDrama.git
   cd NovaDrama
   ```

2. **Obtener dependencias:**
   ```bash
   flutter pub get
   ```

3. **Ejecutar o compilar el APK Release:**
   ```bash
   flutter run
   # o para generar el instalador:
   flutter build apk --release
   ```

4. **Instaladores APK ya compilados:**
   Los binarios de todas las versiones están respaldados en la sección de [Releases de GitHub](https://github.com/AngelGuevara04/NovaDrama/releases).
