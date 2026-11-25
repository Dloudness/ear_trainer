# EAR TRAINER

App de entrenamiento auditivo para productores, ingenieros de sonido y músicos. Estilo gaming, oscuro (fondo #0B0F14, acentos cian y azul). Flutter + Dart. Dueño del proyecto: profesor de audio, no programador; explica los cambios en español y de forma sencilla.

## Estado del proyecto (verificar contra el código)
- Estructura: lib/core/* y lib/features/* (auth, challenge, demo, exercises, home, modules, onboarding, splash, welcome).
- Ejercicios leídos de assets/data/exercises.json mediante ExerciseRepository. Hecho: EQ (A/B), intervalos y acordes (una sola escucha). Pendiente o parcial: Dinámica, Escucha Real (aún hardcodeado y subjetivo).
- EQ avanzado > Filtros (tools/generate_filters.dart): pasa altos/bajos Butterworth 6-24 dB/oct sobre la salsa (source/music_instrumental_01, primeros 10 s) y music_attention_competing_01, todo a -23 LUFS (a -20 el pasa altos pasaba de 0 dBFS). Niveles LevelLadder.filters: Básico (¿HPF o LPF?), Intermedio (corte por octavas), Profesional (pendiente y corte por tercios). 60 ejercicios EQ_FILT_*.
- EQ avanzado: ejercicios de banda con ruido rosa y música (assets/eq/eq_band, eq_music, eq_pink_noise), generados con tools/generate_eq_levels.dart.
- Progreso (XP, racha, resultados) persistido con shared_preferences. Login y membresía son maqueta (MockSession), sin backend.
- Corre en Chrome: flutter run -d chrome --web-port=5000 (puerto fijo para que el almacenamiento del navegador persista).

## Decisiones de producto ya tomadas
- Audiencia: móvil primero, pero la versión web debe ser buena en escritorio con monitores de estudio.
- Tres niveles de acceso: "free" (sin cuenta), "account" (con registro) y "premium" (membresía). Gratis sin cuenta: intervalos ascendentes perf8, perf5 y min2 (en ese orden, distractores fijos y claros) y EQ_01 a EQ_03. EQ_04 y EQ_05 son "account".
- Entrenamiento Musical: dos tarjetas (Intervalos y Acordes) que abren directo un ejercicio aleatorio entre los desbloqueados. Sin pantalla de secciones.
- NO mostrar nunca cuántos ejercicios hay (ni totales ni "X de Y"): se busca sensación de ejercicios infinitos.
- NO revelar la respuesta antes de responder: el "intro" es genérico por tipo; "explanation" y "tip" solo se ven después.
- Sin cuenta: máximo 5 respuestas, contando repeticiones (MockSession.freeExerciseLimit / answersGiven); al pedir el siguiente se exige registro y no se puede continuar sin él (ensureCanPractice).
- Al registrarse (nombre y correo, aún de maqueta) por el límite gratis, el usuario va al Home. Si dice "Ahora no", va a un Home de invitado que muestra su avance e invita a crear la cuenta (gratis); sin cuenta no hay más ejercicios. Un usuario registrado abre la app directo en el Home.
- Premium: pantalla de planes (lib/features/subscription/presentation/screens/plans_screen.dart) con Anual (destacado), Mensual y Estudiante; precios aún sin definir (Plans.all). Home muestra tarjeta "Lleva tu oído más lejos" y candado Premium en áreas premium (hoy Acordes). Qué contenido es premium además de Acordes está por decidir. Pagos aún no implementados.
- Home = consejero educativo, no juego: recomienda qué reforzar según las últimas 10 respuestas por área (Ecualización, Tonos puros, Intervalos, Acordes, Afinación), felicita logros y da un consejo del día (lib/features/home/models/mentor.dart). Sin XP ni retos tipo juego.
- Afinación en contexto: solo piano por ahora. La guitarra está excluida (MusicalPools.tuningContextExcluded) porque algunas notas suenan desafinadas tras el reafinado; volver a activarla solo tras auditar nota por nota con las grabaciones originales.
- Sin bucle de reintento: si falla, puede ver la respuesta (opcional) y pasa al siguiente ejercicio. Nunca "Volver a intentar" (evita memorizar ejercicios).
- Máximo 3 escuchas por ejercicio (en A/B, 3 por clip). Play siempre reinicia desde cero. Sin botón Repetir. Tras responder, el audio es ilimitado.
- Ventanas de contexto "¿Por qué entrenar...?" (intervalos, acordes, EQ) con versión "full" (principiante) y "short". Incluyen "Con este entrenamiento aprenderás a:".
- Dinámica bloqueada por progreso en el Home (candado distinto al de membresía) hasta tener contenido real.
- Regla de ejercicios objetivos: se cambia UNA variable conocida; la respuesta correcta vive en el JSON ("correct"), nunca se deduce del nombre del archivo.
- Precios iniciales (suscripción mensual, por validar): estudiantes 8.000 COP; público general en Colombia 15.000-16.000 COP; internacional en USD con precio propio. Habrá licencias para cursos e instituciones (universidades). Aún no implementado en la app.
- Afinación en contexto (A2-A5): se construirá por código a partir de muestras reales grabadas por el dueño (piano, guitarra, voz). Guía: docs/Ear_Trainer_guia_de_grabacion_afinacion.docx.
- Plan futuro: cuentas reales y progreso en la nube (Firebase o Supabase), audios premium en almacenamiento protegido, pagos, web en dominio propio. Ejercicios por IA a más largo plazo. Nada de esto antes del piloto.

## Convenciones de audio
- Nombres solo en minúscula, números y guion bajo; sin espacios, tildes, # ni paréntesis. Sostenido = "sharp". Patrón: intervalos interval_{intervalo}_{asc|desc|harm}_{nota}_{NN}; acordes chord_{calidad}_{root|inv1|inv2|inv3}_{raíz}_{NN}; EQ freq_/filter_ con frecuencia y ganancia.
- Masters en WAV sin compresión dentro de audio_masters/ (mismas carpetas que assets/, fuera de la app). La app usa solo AAC .m4a (192k mono, 256k estéreo) en assets/. Los generadores escriben en audio_masters/; después de cualquier generador o audio nuevo correr: dart run tools/compress_audio.dart (convierte y pasa las rutas del JSON a .m4a; necesita ffmpeg). Una prueba falla si el catálogo apunta a algo que no es .m4a o no existe.
- Nivel igualado (~-20 LUFS) entre original y procesado en EQ.
- Cada subcarpeta de assets debe declararse en pubspec.yaml con barra final (Flutter no incluye subcarpetas automáticamente).
- Los audios del piloto van en assets/ (descargables); los premium reales irán a almacenamiento protegido.

## Reglas de trabajo
- Antes de editar: explica qué archivos tocarás. Cambios mínimos, sin rediseñar la identidad visual.
- Ejecuta flutter analyze al terminar y resume qué cambió.
- No instales dependencias ni borres archivos sin avisar.
- El dueño hace commit antes de cambios grandes; propón un mensaje de commit al terminar.
- No inventes que algo existe: verifica en el código.