# EAR TRAINER

App de entrenamiento auditivo para productores, ingenieros de sonido y músicos. Estilo gaming, oscuro (fondo #0B0F14, acentos cian y azul). Flutter + Dart. Dueño del proyecto: profesor de audio, no programador; explica los cambios en español y de forma sencilla.

## Estado del proyecto (verificar contra el código)
- Estructura: lib/core/* y lib/features/* (auth, challenge, demo, exercises, home, modules, onboarding, splash, welcome).
- Ejercicios leídos de assets/data/exercises.json mediante ExerciseRepository. Hecho: EQ (A/B), intervalos y acordes (una sola escucha). Pendiente o parcial: Dinámica, Escucha Real (aún hardcodeado y subjetivo).
- EQ avanzado: ejercicios de banda con ruido rosa y música (assets/eq/eq_band, eq_music, eq_pink_noise), generados con tools/generate_eq_levels.dart.
- Progreso (XP, racha, resultados) persistido con shared_preferences. Login y membresía son maqueta (MockSession), sin backend.
- Corre en Chrome: flutter run -d chrome --web-port=5000 (puerto fijo para que el almacenamiento del navegador persista).

## Decisiones de producto ya tomadas
- Audiencia: móvil primero, pero la versión web debe ser buena en escritorio con monitores de estudio.
- Tres niveles de acceso: "free" (sin cuenta), "account" (con registro) y "premium" (membresía). Gratis sin cuenta: intervalos ascendentes perf8, perf5 y min2 (en ese orden, distractores fijos y claros) y EQ_01 a EQ_03. EQ_04 y EQ_05 son "account".
- Entrenamiento Musical: dos tarjetas (Intervalos y Acordes) que abren directo un ejercicio aleatorio entre los desbloqueados. Sin pantalla de secciones.
- NO mostrar nunca cuántos ejercicios hay (ni totales ni "X de Y"): se busca sensación de ejercicios infinitos.
- NO revelar la respuesta antes de responder: el "intro" es genérico por tipo; "explanation" y "tip" solo se ven después.
- Sin cuenta: máximo 5 ejercicios distintos (MockSession.freeExerciseLimit); al pedir el siguiente se exige registro y no se puede continuar sin él (ensureCanPractice).
- Sin bucle de reintento: si falla, puede ver la respuesta (opcional) y pasa al siguiente ejercicio. Nunca "Volver a intentar" (evita memorizar ejercicios).
- Máximo 3 escuchas por ejercicio (en A/B, 3 por clip). Play siempre reinicia desde cero. Sin botón Repetir. Tras responder, el audio es ilimitado.
- Ventanas de contexto "¿Por qué entrenar...?" (intervalos, acordes, EQ) con versión "full" (principiante) y "short". Incluyen "Con este entrenamiento aprenderás a:".
- Dinámica bloqueada por progreso en el Home (candado distinto al de membresía) hasta tener contenido real.
- Regla de ejercicios objetivos: se cambia UNA variable conocida; la respuesta correcta vive en el JSON ("correct"), nunca se deduce del nombre del archivo.
- Plan futuro: cuentas reales y progreso en la nube (Firebase o Supabase), audios premium en almacenamiento protegido, pagos, web en dominio propio. Ejercicios por IA a más largo plazo. Nada de esto antes del piloto.

## Convenciones de audio
- Nombres solo en minúscula, números y guion bajo; sin espacios, tildes, # ni paréntesis. Sostenido = "sharp". Patrón: intervalos interval_{intervalo}_{asc|desc|harm}_{nota}_{NN}; acordes chord_{calidad}_{root|inv1|inv2|inv3}_{raíz}_{NN}; EQ freq_/filter_ con frecuencia y ganancia.
- WAV sin compresión. Nivel igualado (~-20 LUFS) entre original y procesado en EQ.
- Cada subcarpeta de assets debe declararse en pubspec.yaml con barra final (Flutter no incluye subcarpetas automáticamente).
- Los audios del piloto van en assets/ (descargables); los premium reales irán a almacenamiento protegido.

## Reglas de trabajo
- Antes de editar: explica qué archivos tocarás. Cambios mínimos, sin rediseñar la identidad visual.
- Ejecuta flutter analyze al terminar y resume qué cambió.
- No instales dependencias ni borres archivos sin avisar.
- El dueño hace commit antes de cambios grandes; propón un mensaje de commit al terminar.
- No inventes que algo existe: verifica en el código.