# Ear Trainer: plan de Diseño sonoro y Dinámica

**Fecha:** 25 de noviembre de 2026.

**Contenido de este documento:**
- Los ejercicios que ya habíamos acordado para Diseño sonoro y Dinámica: qué grabas tú, qué hago yo y en qué orden avanzamos.
- Al final, un resumen de todos los ejercicios que hay hoy en la app, por nivel y por acceso.

Sale de tres documentos anteriores:
- `docs/Ear_Trainer_plan_de_ejercicios_y_acceso.docx`
- `docs/Ear_Trainer_banco_de_ejercicios.docx`
- `docs/Ear_Trainer_guia_de_grabacion_afinacion.docx`

---

## 1. Decisiones de hoy

- **Dinámica sale de la app por ahora.** Ya no aparece en "¿Qué quieres entrenar hoy?" ni en el texto de bienvenida. Su pantalla, su ruta y su demo (DYN_01) siguen guardadas en el código, sin mostrarse, para volver a activarla cuando tenga ejercicios.
- **Dinámica no será Premium.**
  - **Propuesta, por confirmar:** que funcione igual que Frecuencias. El nivel Básico sería gratis con cuenta, e Intermedio y Profesional Premium, como en todas las secciones con niveles.
- **Diseño sonoro sigue siendo sección Premium**, como estaba decidido.
- **Siguiente paso:** crear los ejercicios de las dos secciones.

---

## 2. Reglas que valen para los dos módulos

1. **Cambia una sola cosa.** Todo lo demás es idéntico, así que la respuesta es objetiva y queda guardada en el catálogo (`correct`).
2. **Volumen igualado** entre versiones, para que nadie responda por "la que suena más fuerte". En Dinámica es todavía más importante: el oído debe reconocer la compresión, no el volumen.
3. **Nunca limitador para ganar nivel.**
4. **La IA solo para el material base** (voces, ambientes, música). La variable del ejercicio se aplica siempre por código o en la DAW, con valores exactos.
5. **Muchas variantes de cada ejercicio** (otras voces, frases y fuentes), para que no se memoricen.
6. **Tres niveles por práctica: Básico, Intermedio y Profesional.** Igual que en EQ Avanzado.

---

## 3. Cómo nos repartimos el trabajo

| Tú (Diego) | Yo (Claude) |
|---|---|
| Grabar voces, batería, bajo, música sin máster, room tone y los videos con golpe claro | Escribir los generadores en `tools/` que aplican cada variable por código: ruido, nivel, EQ, reverberación, paneo, compresión, saturación y ducking |
| Grabar con la clase: micrófonos y sincronía | Igualar volumen (LUFS), revisar picos y medir que cada audio tenga exactamente lo que dice el catálogo |
| Dar los permisos por escrito de quien sale en las grabaciones | Crear los ejercicios en `exercises.json`, con niveles, explicaciones y consejos |
| Revisar las explicaciones, los nombres y los consejos que yo escriba | Conectar las pantallas de la app y las pruebas automáticas |
| Probar en el celular y decir qué se siente difícil o fácil | Comprimir a `.m4a` y dejar los WAV en `audio_masters/` |

---

## 4. Diseño sonoro (Premium)

Está pensado para estudiantes de cine, video y podcast. Cada ejercicio parte de un problema real de rodaje o de edición.

### 4.1 Material que ya tenemos en el proyecto

- **9 ambientes** en `assets/ambient`: café, lluvia en la calle, lluvia lenta, viento con pájaros, campo con pájaros, lluvia fría, dos de insectos de noche y viento con nieve.
- **3 foleys** en `assets/foley`: puerta vieja, puerta de carro y puerta de oficina.
- **6 músicas** en `assets/music`, más la salsa.
- **1 voz narrada** (`voice_narration_01`).
- **3 videos** en `assets/video/source`: caminata en el bosque, chica en el campo y gimnasio oscuro.

> **Limitación importante:** hay **una sola voz**. Los ejercicios con voz se pueden armar ya, pero con una sola frase se memorizan rápido. Con las 10 frases habladas de la guía de grabación (bloque F, que sirve también para Dinámica), Diseño sonoro pasa de unos 150 a más de 500 ejercicios.

### 4.2 Ejercicios por nivel

| Nivel | Ejercicio | Qué escucha y qué responde | Material | Quién lo hace |
|---|---|---|---|---|
| **Básico** | ¿Qué ambiente es? | Café, lluvia, bosque, insectos de noche, viento… | Ya está | Claude |
| Básico | ¿Qué ensucia esta toma? | Voz con ruido de café, lluvia, viento, aire acondicionado o zumbido de 60 Hz. ¿Cuál es el ruido? | Ya está (el zumbido se genera por código) | Claude |
| Básico | ¿La música tapa la voz? | Voz con música a -6, -12 o -18 dB. ¿Cuál está equilibrada? | Ya está | Claude |
| Básico | ¿Qué sonido va con la escena? | Un video y 3 ambientes. ¿Cuál corresponde? | Ya está (3 videos) | Claude |
| **Intermedio** | ¿Voz clara o tapada? | La misma voz con y sin pasa altos (80, 120, 200 Hz) o con presencia (+3, +6 dB en 3-5 kHz) | Ya está | Claude |
| Intermedio | ¿Cerca o lejos? | La misma voz o foley a distintas distancias: nivel, brillo y reverberación | Ya está (por código) | Claude |
| Intermedio | ¿Dónde se grabó? | Cuarto pequeño, sala grande, exterior o estudio seco | Ya está (reverberación por código) | Claude |
| Intermedio | ¿De dónde viene el sonido? | Foley a la izquierda, al centro o a la derecha (con audífonos) | Ya está (pocos foleys; conviene grabar más) | Claude |
| **Profesional** | ¿Dónde se corta el ambiente? | Un ambiente con un salto de continuidad en el segundo 1, 2 o 3 | Ya está | Claude |
| Profesional | ¿Cuál está saturada o comprimida de más? | Voz limpia contra recortada (leve o fuerte) o sobrecomprimida | Ya está | Claude |
| Profesional | ¿Está sincronizado? | Video con el sonido a tiempo, adelantado o atrasado 2, 4 o 6 cuadros | **Hay que grabar** clips con golpe claro (claqueta, aplauso, persona hablando de frente) | Diego graba; Claude arma |
| Profesional | ¿Con qué micrófono se grabó? | De cámara, de solapa o de pértiga (variante: cerca, a 1 m, a 3 m) | **Hay que grabar** la misma frase con los tres micrófonos a la vez | Diego, con la clase |

**Para más adelante:** las dos voces al unísono y "canta la nota" con el micrófono. Son de Afinación, no de Diseño sonoro.

### 4.3 Qué grabar para Diseño sonoro

En orden de prioridad:

1. **Voz hablada** (bloque F de la guía): 10 frases de 5 a 8 s, una voz grave y una aguda, 2 tomas. Sirve también para Dinámica.
2. **Room tone** (bloque K): 30 s de silencio de la sala, 2 tomas.
3. **Más foleys**, secos y en mono: pasos, llaves, vaso, papel, ropa, un auto pasando. Así el paneo y "cerca o lejos" tienen variedad. También se pueden crear con IA, como ambientes.
4. **Ruidos de rodaje por separado:** aire acondicionado, tráfico y viento en el micrófono. Pueden ser grabados o hechos con IA.
5. **Videos de sincronía:** de 6 a 10 clips cortos con un golpe claro, en MP4 (H.264).
6. **Micrófonos con la clase:** la misma frase grabada a la vez con cámara, solapa y pértiga, en 2 o 3 espacios.

Nombres sugeridos: `av_noise_hum60_dialog01_01.wav`, `av_room_large_voice01_01.wav`, `av_pan_left_steps01_01.wav`, `av_sync_late_4f_clap01_01.mp4`, `av_mic_lav_voice01_01.wav`.

---

## 5. Dinámica (sin Premium)

### 5.1 La idea

Tú grabas pistas **secas, con su dinámica natural**: sin compresor, sin limitador y sin normalizar. Yo aplico por código la compresión, el limitador, la saturación o el ducking exactos de cada ejercicio, siempre con el volumen percibido igualado.

### 5.2 Ejercicios por nivel

| Nivel | Ejercicio | Qué escucha y qué responde | Material |
|---|---|---|---|
| **Básico** | ¿Cuál suena más fuerte? | Dos versiones a 1, 3 o 6 dB de diferencia | Voz hablada o música |
| Básico | ¿Cuál está saturada? | Limpia contra recortada | Voz hablada o música |
| Básico | ¿Cuál es más pareja? | Natural contra comprimida (con nivel igualado) | Voz hablada |
| Básico | ¿La música baja cuando hablan? | Con o sin ducking | Voz hablada y música de fondo |
| **Intermedio** | ¿Comprimida o natural? | Una sola versión: ¿tiene compresión? | Voz, batería y bajo |
| Intermedio | ¿Se escucha el compresor "respirar"? | Con o sin bombeo audible | Batería y música |
| Intermedio | ¿Cuánta compresión? | 3, 6 o 10 dB de reducción | Voz, batería y bajo |
| **Profesional** | ¿Ataque rápido o lento? | Mismo compresor, solo cambia el ataque | Batería (caja y bombo) y bajo |
| Profesional | ¿Liberación rápida o lenta? | Solo cambia la liberación | Batería y voz cantada |
| Profesional | ¿Ratio 2:1 u 8:1? | Solo cambia la relación | Voz y bajo |
| Profesional | ¿Compresión paralela? | Normal contra paralela | Batería |

### 5.3 Qué grabar para Dinámica

Es la sección 2.1 de la guía de grabación. En orden de prioridad:

| Bloque | Qué | Para qué nivel |
|---|---|---|
| **F · Voz hablada** | 10 frases de 5 a 8 s (la lista está en la guía), voz grave y aguda, 2 tomas | Básico (también Diseño sonoro) |
| **J · Música de fondo** | 3 o 4 piezas instrumentales de unos 30 s, mezcladas **sin compresión ni limitador en el máster** | Básico |
| H · Batería | Loops de 4 compases a 90 y 120 BPM, más golpes sueltos de caja y bombo (media y fuerte) | Intermedio y Profesional |
| I · Bajo | Una línea de 4 compases a 90 y 120 BPM, por línea directa | Intermedio y Profesional |
| G · Voz cantada | 4 frases de 8 a 12 s que crezcan y bajen | Profesional |
| K · Room tone | 30 s de silencio de la sala | También para Diseño sonoro |

**Con F y J ya se arma todo el nivel Básico de Dinámica.**

**Formato:**
- WAV, 48 kHz, 24 bits.
- Picos entre -12 y -6 dBFS.
- Misma ganancia en todo un bloque.
- Sin efectos.
- Batería y bajo con metrónomo, cortados exactos al compás.

Nombres: `dyn_speech_grave_frase03_01.wav`, `dyn_music_bg_piano_01.wav`, `dyn_drums_loop_120_01.wav`, `dyn_snare_hit_fuerte_05.wav`, `dyn_bass_line_90_01.wav`, `dyn_sing_frase2_01.wav`, `dyn_roomtone_01.wav`.

> **Ojo con la música que ya está en el proyecto:** las 6 músicas y la salsa probablemente vienen masterizadas, es decir, ya comprimidas. Sirven para una versión de prueba del nivel Básico, pero no para los ejercicios definitivos de compresión, porque el "antes" ya tendría compresión.

### 5.4 Cómo entregar las grabaciones

- Carpeta `Documentos\ear_trainer_grabaciones`, **fuera del proyecto**, con una subcarpeta por bloque: `dinamica_voz_hablada`, `dinamica_musica`, `dinamica_bateria`, `dinamica_bajo`, `dinamica_voz_cantada`, `ambiente`, `diseno_foley`, `diseno_videos_sync`, `diseno_microfonos`.
- Si grabas en el estudio, súbelas comprimidas en zip a una nube y bájalas en el computador donde vayamos a trabajar.
- Junto a cada grabación, los permisos por escrito de quien aparece.

---

## 6. Orden de trabajo propuesto

1. **Ya, sin grabar nada:** Diseño sonoro, nivel Básico (ambiente, ruido en la toma, música contra voz, sonido para la escena). Después el Intermedio. Con esto se abre la sección Premium con contenido real.
   - **Hecho el 25 de noviembre:** 95 ejercicios de Básico con `tools/generate_sound_design.dart`, todos a -23 LUFS.
   - **Regla para todos los ejercicios:** las opciones incorrectas deben ser tentadoras, nunca absurdas, y el criterio debe ser objetivo.

     | Práctica | Ejercicios | Cómo es |
     |---|---|---|
     | ¿Qué ambiente es? | 23 | Las opciones suenan parecido. Por ejemplo, la lluvia aparece junto a "río" y "fritura en una sartén". |
     | ¿Qué le pasa a esta toma? | 18 | Un tercio de las tomas están limpias. Las opciones van en parejas que se confunden: zumbido ↔ voz retumbante, aire acondicionado ↔ lluvia de fondo, voz apagada ↔ voz saturada. |
     | ¿Qué ajustarías en esta mezcla? | 21 | La música va a -3, -15 o -26 dB frente a la voz, y la respuesta es bajarla, dejarla así o subirla. La explicación da la referencia de cine y TV: entre 12 y 18 dB por debajo del diálogo. |
     | ¿Cuánta reverberación tiene? | 18 | Voz y foleys en una sala seca, con un poco de sala o con mucha. |
     | ¿Se pueden pegar estas tomas? | 15 | La voz partida en dos tomas. El fondo sigue igual, cambia de volumen (±6 dB) o aparece otro ruido. |

   - **Descartados:**
     - La escena con video, porque el criterio de elección era subjetivo.
     - El paneo, porque con audífonos es demasiado evidente.
   - **Para revisar:**
     - Los nombres de las opciones, las explicaciones y los niveles los escribió Claude.
     - Los ambientes se clasificaron por el nombre del archivo: confirma que cada uno sea lo que dice.
   - **Material que sigue:** tus grabaciones de nevera, lavadora, bus y aire acondicionado. Hoy el aire acondicionado es simulado por código.
   - **La lluvia `Rain_slow_01` no entra:** sus gotas superan -1 dBFS a -23 LUFS, y no usamos limitador.
2. **Mientras tanto, tú grabas F y J** (voz hablada y música sin máster). Si alcanza el tiempo, también K y los foleys.
3. **Con F y J:**
   - Dinámica Básico.
   - Vuelve a aparecer en la app, con la decisión de acceso que tomes.
   - Diseño sonoro crece con más voces.
4. **Con H, I y G** (batería, bajo y voz cantada): Dinámica Intermedio y Profesional.
5. **Con la clase:** sincronía con video y micrófonos (Diseño sonoro Profesional).

**Después de cada paso:**
- Pruebas en el celular.
- Revisas las explicaciones.
- Commit y push.

---

## 7. Lo que tienes que decidir

1. **Acceso a Dinámica:** ¿Básico gratis con cuenta e Intermedio y Profesional Premium, como Frecuencias? ¿O toda gratis?
2. **Voces con IA o grabadas:** para arrancar Diseño sonoro con más de una voz, ¿usamos voces sintéticas (ElevenLabs) mientras grabas las reales?
3. **Foleys y ruidos:** ¿los grabas tú o los hacemos con IA (revisando la licencia)?

---

## 8. Resumen de todos los ejercicios de la app (hoy)

**Acceso:**
- **Libre:** se puede sin cuenta (máximo 5 respuestas) y sin límite con la cuenta gratis.
- **Cuenta:** necesita la cuenta gratis.
- **Premium:** necesita la membresía.

### Frecuencias (sección gratis)

| Práctica | Básico | Intermedio | Profesional | Acceso |
|---|---|---|---|---|
| EQ Inicial, A/B (8) | 8 ejercicios, sin niveles | — | — | 6 libres (EQ_01 a EQ_03 y tres de filtros), EQ_04 y EQ_05 con cuenta |
| EQ Avanzado · Ruido rosa (28) | Nivel 1: con referencia, 2 escuchas | Nivel 2: 1 escucha de referencia | Nivel 3: sin referencia | Nivel 1 libre; 2 y 3 Premium |
| EQ Avanzado · Filtros (60) | 12: ¿pasa altos o pasa bajos? | 16: corte por octavas | 32: pendiente y corte por tercios | Básico libre; resto Premium |
| EQ Avanzado · Shelves (56) | 16: ¿qué cambió? | 24: ¿cuánto? ±3/6/9 dB | 16: ¿en qué frecuencia? | Básico libre; resto Premium |
| EQ Avanzado · Resonancias (50) | 12: graves, medios o agudos | 14: por octavas | 24: por tercios | Básico libre; resto Premium |
| EQ Avanzado · Problemas de voz y guitarra (46) | 11: dos problemas | 11: cuatro problemas | 24: ¿en qué frecuencia? | Básico libre; resto Premium |
| Tonos puros · Frecuencia del tono (79) | 27: octavas | 52: tercios | — | Octavas libre; Tercios Premium |
| Tonos puros · ¿Más agudo o más grave? (30) | 30, sin niveles | — | — | Libre |

En el ruido rosa los 28 ejercicios son los mismos en los tres niveles. Lo que cambia es la referencia que se puede escuchar.

### Entrenamiento musical

| Práctica | Básico | Intermedio | Profesional | Acceso |
|---|---|---|---|---|
| Intervalos (462) | 30: solo ascendentes | 144: ascendentes y descendentes | 288: armónicos y compuestos | Básico con cuenta (3 libres: octava, 5ta justa y 2da menor); resto Premium |
| Acordes (61) | Sin niveles | — | — | Toda Premium |
| Afinación de notas (28) | Sin niveles | — | — | Libre |
| Afinación en contexto, piano (276) | 84: nota fuera de la escala | 96: 50 cents | 96: 25, 15 y 10 cents | Básico con cuenta; resto Premium |

Hay además 276 ejercicios de afinación en contexto con guitarra en el catálogo, **apagados** hasta auditar las grabaciones nota por nota.

### Secciones sin ejercicios todavía

| Sección | Estado | Acceso previsto |
|---|---|---|
| Diseño sonoro | Básico listo desde el 25 de noviembre: 95 ejercicios en 5 prácticas. Intermedio y Profesional pendientes | Premium |
| Dinámica | Retirada de la app hasta tener ejercicios | No Premium (por definir) |

### En números

- **1.460 ejercicios** en el catálogo, de los cuales **1.184 están activos**. Los otros 276 son los de guitarra apagados.
- **Libres o con cuenta (nivel Básico y prácticas sin niveles):** 286. De Frecuencias son 144 y de Musical 142.
- **Solo Premium:** 898. Son los niveles Intermedio y Profesional, más los 61 de Acordes.

Recuerda que en la app nunca se muestran estas cantidades: la idea es que los ejercicios se sientan infinitos.
