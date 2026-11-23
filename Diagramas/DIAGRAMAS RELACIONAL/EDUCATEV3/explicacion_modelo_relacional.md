# Modelo relacional de Educate

## Cómo se lee

- Cada caja es una tabla y cada fila de la caja es una columna con su tipo (int, varchar, datetime...).
- PK (clave primaria): es lo que identifica cada fila. En casi todas las tablas es un `id` autoincremental. En `matriculas` la clave es la pareja `clase_id` + `alumno_id`, y en `perfiles_alumno` es `usuario_id`.
- FK (clave ajena): es una columna que apunta al id de otra tabla, por ejemplo `clases.profesor_id` apunta a `usuarios.id`. Son las líneas que unen las tablas.
- En las líneas aparece `1` y `*`. `1 - *` quiere decir uno a muchos (un profesor tiene muchas clases y una clase tiene un solo profesor). `1 - 1` es uno a uno.
- Los enums son listas cerradas de valores, por ejemplo `rol_usuario` solo puede ser alumno, profesor o admin. Así la base de datos no deja meter valores que no existen.
- Los colores solo sirven para agrupar las tablas por partes de la aplicación.

## Personas

- `usuarios`: hemos usado una sola tabla para alumnos, profesores y admins, y se diferencian por el campo `rol`. Como hay alumnos menores, no guardamos datos reales de ellos: tienen un nombre de usuario inventado (por ejemplo LeonAzul42) y un `alias` que es lo que sale en el ranking. El email es obligatorio para todos menos para los alumnos. Del nacimiento solo guardamos el año, que es suficiente para saber si tiene menos de 14 años. `creado_por` es el profesor que dio de alta al alumno menor.
- `consentimientos`: sirve para guardar que hay autorización para los alumnos menores de 14. Se guarda la versión del texto legal que se aceptó, la fecha y si se ha revocado. Por eso un usuario menor empieza con `activo = false` y no se activa hasta que hay consentimiento.
- `perfiles_alumno`: datos extra del alumno, el curso y las preferencias de apoyo (esto último es para la fase 2). Está separado de `usuarios` en una relación 1 a 1 porque las preferencias de apoyo son un dato sensible y necesitan su propio consentimiento.

## Classroom

- `clases`: cada clase tiene un profesor y un código de acceso único para que los alumnos se unan.
- `matriculas`: es una tabla intermedia para la relación N a M entre alumnos y clases (un alumno puede estar en varias clases y una clase tiene varios alumnos). Como la clave es la pareja clase + alumno, un alumno no se puede matricular dos veces en la misma clase.
- `tareas`: las tareas de cada clase. El profesor decide si la tarea admite subir nota con puntos (`admite_bonus`) y cuánto como máximo (`bonus_max`).
- `entregas`: lo que entrega cada alumno en cada tarea. Solo puede haber una entrega por alumno y tarea. Guardamos la nota original y el bonus por separado, y la nota final se calcula como `LEAST(10, nota + bonus_aplicado)`, así nunca se pasa de 10 y no se pierde la nota original.

## Actividades

- `actividades`: los cuestionarios y minijuegos de cada clase. El campo `tipo` dice qué tipo es (opción múltiple, verdadero/falso, ordenar, emparejar o completar huecos). Solo las que están publicadas las ven los alumnos.
- `preguntas`: las preguntas de cada actividad, con su orden y un tiempo límite opcional. El campo `config` es un JSON para los datos que necesitan los tipos ordenar, emparejar y completar huecos.
- `opciones`: las respuestas posibles de las preguntas de opción múltiple y verdadero/falso. El campo `es_correcta` nunca se manda al navegador para que no se pueda hacer trampa.
- `intentos`: cada vez que un alumno hace una actividad. Solo el primer intento terminado da puntos (`cuenta_para_puntos`).
- `respuestas`: lo que ha contestado el alumno en cada pregunta de un intento. Con esto el profesor puede ver qué preguntas se fallan más. Las horas en las que se envía y se recibe la pregunta las guarda el servidor, para que el extra por rapidez no se pueda falsear.

## Puntos y tienda

- `puntuaciones`: aquí se guardan los puntos que gana cada alumno en cada clase. Los puntos pueden venir de una actividad o de un ajuste que hace el profesor a mano. Solo se suman, nunca se restan. Un intento solo puede dar puntos una vez porque `intento_id` es único.
- `recompensas`: lo que hay en la tienda de cada clase. Puede ser un privilegio (por ejemplo entregar un día más tarde) o un bonus de nota en una tarea. Tienen un coste en puntos y un stock opcional. En vez de borrarlas se desactivan.
- `canjes`: cada vez que un alumno compra una recompensa. Se guarda lo que costó en ese momento por si luego cambia el precio. El profesor lo aprueba o lo rechaza.

Con estas tablas se calculan dos cosas diferentes:

- Ranking: la suma de todos los puntos ganados. No baja aunque el alumno gaste puntos.
- Saldo: puntos ganados menos los canjes pendientes y aprobados. Si el profesor rechaza un canje, esos puntos vuelven al saldo.

## Notificaciones

- `notificaciones`: los avisos dentro de la web (tarea nueva, nota puesta, canje resuelto...) y si se han leído o no.

## Otros detalles

- Al borrar un registro, cada relación tiene una regla:
  - `cascade`: se borran también los registros que dependen de él. Por ejemplo, si se borra una clase se borran sus tareas, actividades y recompensas.
  - `set null`: el registro se queda pero la referencia pasa a NULL. Por ejemplo, si se borra el profesor que registró un consentimiento, el consentimiento se mantiene.
  - `restrict`: no deja borrar. No se puede borrar un profesor que tiene clases.
- Los índices sirven para que las consultas que más se usan vayan más rápido (por ejemplo las actividades publicadas de una clase o los puntos de un alumno en una clase). Los índices `unique` además impiden duplicados.
- Hemos intentado que cada dato esté guardado en un solo sitio, y los totales (ranking, saldo, nota final) se calculan en vez de guardarse, para que no haya datos que no cuadren.
