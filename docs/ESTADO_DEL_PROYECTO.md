# Ear Trainer: estado del proyecto

**Última sesión:** 25 de noviembre de 2026 (noche), en el computador de la casa (ffmpeg ya instalado ahí).

## >>> PARA ARRANCAR MAÑANA <<<

Lee **`docs/PLAN_DISENO_SONORO_Y_DINAMICA.md`, sección 0**. Tiene lo que dijo el profesor al probar, qué grabar y cómo mejorar los ejercicios.

**Resumen de la noche del 25 de noviembre:**

- **Diseño sonoro, nivel Básico (Premium):** 95 ejercicios en 5 prácticas, generados con `tools/generate_sound_design.dart`. Están en GitHub (commit `4f13ba2`).

  | Práctica | Cómo quedó |
  |---|---|
  | Ambientes, la toma y la mezcla | Funcionan, pero **suenan iguales**: hay poco material, se memorizan rápido |
  | Reverberación | **No sonó en el Android** del profesor. En el computador sí suena: revisar |
  | Continuidad ("¿se pueden pegar estas tomas?") | **No se entendió**: rediseñar |

- **Audio en Android (versión web):** el reproductor ya no usa el AudioContext de `audioplayers`, que se suspendía. Ahora usa un elemento de audio simple. Ninguna orden puede bloquear el reproductor.
- **Dinámica:** salió de la app hasta tener ejercicios, y no será Premium.
- **Escena con video y paneo:** descartados.
- **El profesor va a grabar:**
  - Ruidos con los DJI: nevera, lavadora, bus, aire acondicionado.
  - Voces de varias personas.
  - Ambientes.
  - Salas.
  - Bancos de sonido con licencia que permita usarlos.

  La lista completa está en la sección 0.3 del plan.
- **Al abrir la app en el celular:** recargar la página, porque el navegador guarda la versión anterior.

## Sesión del 25 de noviembre (día)

- **Filtros:** explicaciones corregidas (corte por octavas, pendiente de 12 dB y corte por tercios con lo que se pierde en cada banda).
- **EQ Avanzado, tres prácticas nuevas** (`tools/generate_eq_practice.dart`, 152 ejercicios, 130 audios, 40 MB en `.m4a`):

| Práctica | Material | Básico | Intermedio | Profesional |
|---|---|---|---|---|
| Shelves (56) | salsa y música | ¿Qué cambió? (más/menos graves o agudos) | ¿Cuánto? ±3, ±6, ±9 dB | ¿En qué frecuencia está el shelf? |
| Resonancias (50) | voz y guitarra | ¿Graves, medios o agudos? | Frecuencia por octavas | Frecuencia por tercios |
| Problemas de voz y guitarra (46) | voz y guitarra | Dos problemas opuestos | Cuatro problemas | ¿En qué frecuencia está el exceso? |

  - Todo a **-24 LUFS** (un shelf de +9 dB superaba -1 dBFS a -23). Pico máximo: -1,9 dBFS.
  - Se midió cada audio contra su referencia: shelves y problemas dentro de 1 dB de lo esperado; resonancias de +12 dB, Q 8.
  - **Revisar:** las explicaciones, los nombres de los problemas ("embarrada", "encajonada", "nasal", "sibilante", "apagada", "delgada", "retumbante", "chillona") y los pares opuestos del nivel Básico los escribió Claude.
- **Intervalos:**
  - **Niveles nuevos:** Básico solo ascendentes (30 ejercicios); Intermedio ascendentes y descendentes (144); Profesional suma armónicos y compuestos (288).
  - **Referencia guiada:** una pista por nivel (18 s, 84 s y 2 min 42 s), que no suena hasta que el estudiante le da play. El nombre del intervalo que suena se ilumina. Los tiempos están en `assets/data/interval_reference.json`.
  - **Repaso:** en los ejercicios de Básico hay un botón "Repasar la referencia".
  - **Generador:** ya no vuelve a crear los audios que existen, así que cambiar los niveles no cambia lo que se escucha.
  - **Pendiente:** si el profesor graba su voz o un video explicando, se puede reemplazar o complementar la pista. Falta hacer lo mismo con la referencia del ruido rosa.
- **Cuidado con `compress_audio.dart` después de un `git pull`:** en esta sesión volvió a convertir unos 64 `.m4a` que no habían cambiado (por las fechas de los archivos). Se restauraron con git. Antes de hacer commit, revisa con `git status` que solo cambien los audios nuevos.

---

## 1. Cómo arrancar en el computador del estudio

Abre PowerShell en la carpeta del proyecto y ejecuta, en este orden:

1. Traer lo último de GitHub:
   ```powershell
   git pull
   ```
2. Instalar ffmpeg. Es la herramienta que comprime los audios y solo se instala una vez por computador:
   ```powershell
   winget install --id Gyan.FFmpeg -e --source winget
   ```
   Después cierra y vuelve a abrir PowerShell.
3. Descargar los paquetes de Flutter:
   ```powershell
   flutter pub get
   ```
4. Comprobar que todo está bien. Deben salir 0 problemas y 34 pruebas aprobadas:
   ```powershell
   flutter analyze
   flutter test
   ```
5. Abrir la app en Chrome:
   ```powershell
   flutter run -d chrome --web-port=5000
   ```
   Para probarla en el celular, en la misma red Wi-Fi:
   ```powershell
   flutter run -d web-server --web-hostname=0.0.0.0 --web-port=5050 --release
   ```
   Luego, en el celular, abre `http://IP-DEL-COMPUTADOR:5050`.

> Si al abrir la app no aparece algo nuevo, recarga la página. El navegador a veces guarda la versión anterior del catálogo.

---

## 2. Qué se hizo en esta sesión

### Acceso y Premium
- **Sin cuenta:** máximo 5 respuestas, contando las repeticiones. Después se pide crear la cuenta.
- **Cuenta gratis:** el nivel **Básico** es ilimitado en las tres secciones gratis:
  - Frecuencias (EQ, ruido rosa y tonos puros).
  - Intervalos.
  - Afinación.
- **Premium:**
  - Los niveles **Intermedio y Profesional**.
  - Las secciones **Acordes** y **Diseño sonoro**.
  - Más adelante, **Dinámica**.
- Cuando alguien sin Premium gana el siguiente nivel, ve el mensaje "¡Lo lograste! El nivel X te espera en Premium".
- Las secciones Premium solo llevan un **candado discreto**, sin sombreado.
- Se agregó el texto **"la app se actualiza constantemente"** en la pantalla de planes y en el Home.
- **Escucha real** se retiró.

### Fluidez del audio
- **Precarga:** al abrir un ejercicio, el audio se empieza a descargar antes de dar Play, así suena casi al instante.
- **Compresión:** los audios de la app pasaron de WAV a AAC (`.m4a`). El peso bajó de cerca de **1 GB a unos 155 MB**.
  - Se revisaron los 1154 archivos: duran exactamente lo mismo que el original.
  - El tono de 16 kHz y la salsa conservan los agudos.
- **Los WAV originales no se borraron.** Están en la carpeta **`audio_masters/`**, con la misma organización que `assets/`.

### Nuevos ejercicios: EQ Avanzado → Filtros (60 ejercicios)
- Pasa altos y pasa bajos tipo Butterworth, con pendientes de 6, 12, 18 y 24 dB por octava.
- Usan **la salsa** (`music_instrumental_01`, primeros 10 s) y `music_attention_competing_01` (13 s).

| Nivel | Pregunta | Acceso |
|---|---|---|
| Básico | ¿Pasa altos o pasa bajos? | Gratis con cuenta |
| Intermedio | ¿Dónde está el corte? Por octavas | Premium |
| Profesional | ¿Qué pendiente tiene? Y el corte por tercios de octava | Premium |

- **Controles de calidad:**
  - Todo está a **-23 LUFS** para que nadie responda por volumen. A -20 LUFS algunos pasa altos superaban 0 dBFS.
  - El pico real máximo es -1,8 dBTP.
  - La respuesta de los filtros se midió y es exacta.
- **Revisar:** las explicaciones y consejos de estos ejercicios los escribió Claude. Conviene que el profesor los revise.

---

## 3. Regla nueva para los audios (importante)

1. Los WAV maestros viven en `audio_masters/`. La app solo usa `.m4a` en `assets/`.
2. Cada vez que se agregue un audio nuevo o se corra un generador de `tools/`, hay que ejecutar:
   ```powershell
   dart run tools/compress_audio.dart
   ```
   Este comando convierte solo lo nuevo y actualiza las rutas del catálogo.
3. Si se olvida ese paso, una prueba (`flutter test`) avisa qué audio falta.
4. Cada carpeta nueva de audio se declara en `pubspec.yaml`, como siempre.

---

## 4. Pendientes, en orden sugerido

1. **Probar los Filtros en el celular** y revisar las explicaciones.
2. **Más ejercicios de EQ por código:** hechos shelves, resonancias y problemas de voz y guitarra (25 de noviembre). Falta: **ancho de Q**.
3. **Diseño sonoro (Premium):** unos 150 ejercicios con los ambientes, la voz y los videos que ya existen:
   - Identificar el ambiente.
   - Ruido en la toma.
   - Voz clara o apagada.
   - Cerca o lejos.
   - Paneo.
   - Saturación.
4. **Nombre de la app.** Propuestas: Loudness Ear, Loudness EarLab, EarLab, Oído Pro, Escucha Activa, Sonic Mentor, TrueEar. Falta revisar qué dominios están libres.
5. **Precios en la app** (aún no se muestran):
   - Estudiantes: 8.000 COP al mes.
   - Público general en Colombia: 15.000 a 16.000 COP.
   - Internacional: en USD.
6. **Carpeta `eq_band`** (168 MB en `audio_masters/`, ningún ejercicio la usa). Decidir si se borra.

### Material para traer del estudio
- Proyecto de salsa: piano y base melódica, en WAV.
- Voz cantada, para EQ de voz y afinación.
- Grabaciones originales de guitarra (con sus CSV), para auditar nota por nota la afinación en contexto. Hoy la guitarra está excluida.
- Grabaciones para Dinámica (ver `docs/Ear_Trainer_guia_de_grabacion_afinacion.docx`).

---

## 5. Archivos clave

| Archivo | Qué es |
|---|---|
| `CLAUDE.md` | Decisiones de producto y reglas de trabajo. Claude lo lee al empezar. |
| `docs/ESTADO_DEL_PROYECTO.md` | Este informe |
| `docs/Ear_Trainer_plan_de_ejercicios_y_acceso.docx` | Plan de ejercicios y niveles de acceso |
| `tools/compress_audio.dart` | Convierte los masters WAV a `.m4a` |
| `tools/generate_filters.dart` | Genera los ejercicios de Filtros |
| `lib/features/modules/models/practice_levels.dart` | Niveles y qué es Premium |
| `lib/features/subscription/.../plans_screen.dart` | Pantalla de planes (los precios se ponen aquí) |

**Para retomar con Claude en el estudio:** abre el proyecto y dile "Lee `docs/ESTADO_DEL_PROYECTO.md` y continuemos con el pendiente 1".
