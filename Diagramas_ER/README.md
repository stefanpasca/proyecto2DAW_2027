# Diagramas Entidad/Relación

Modelo de datos de **Educate**, versión **2.1**, pensado para **MySQL 8.0.16 o superior** (motor InnoDB, codificación `utf8mb4`).

| Archivo                | Versión | Descripción                                                   |
| ---------------------- | ------- | ------------------------------------------------------------- |
| `EDUCATE v2.1 E_R.pdf` | 2.1     | Diagrama exportado desde [dbdiagram.io](https://dbdiagram.io) |

---

## 1. Visión general

El modelo tiene **13 tablas** organizadas en cuatro bloques:

| Bloque                          | Tablas                                                                | Para qué sirve                                                                                               |
| ------------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| **Usuarios y consentimiento**   | `usuarios`, `consentimientos`, `perfiles_nino`, `vinculos_familiares` | Quién usa la plataforma, qué rol tiene, qué niño pertenece a qué familia y qué permisos han dado los padres. |
| **Clases y tareas**             | `clases`, `matriculas`, `tareas`, `entregas`                          | La parte escolar: el profesor crea clases y tareas, y los niños las entregan.                                |
| **Control parental y catálogo** | `reglas_control`, `catalogo`, `sesiones_uso`                          | Qué contenido existe, qué puede ver cada niño, cuándo y durante cuánto tiempo.                               |
| **Scoreboard y avisos**         | `puntuaciones`, `notificaciones`                                      | Motivación (puntos y rankings) y comunicación con los usuarios.                                              |

### Ideas clave del diseño

- **Una sola tabla de usuarios para todos los roles.** Niños, padres, profesores y administradores están en `usuarios` y se distinguen por la columna `rol`. Los datos que solo tienen los niños van aparte, en `perfiles_nino`.
- **Los informes no tienen tabla propia.** Se calculan en el momento a partir de `entregas`, `puntuaciones` y `sesiones_uso`. Así no hay datos duplicados que puedan descuadrarse.
- **Los niños no se registran solos.** Los da de alta un adulto con datos mínimos, y la cuenta no se activa hasta que hay consentimiento parental.
- **Las reglas importantes se comprueban en el servidor**, nunca solo en el navegador: acceso al contenido, cálculo de puntos y permisos de cada rol.

---

## 2. Entidades

### 2.1 Bloque de usuarios y consentimiento

#### `usuarios`

**Qué representa:** cualquier persona que usa Educate: niño, padre/tutor, profesor o administrador.

**Función:** es la tabla central del modelo. Guarda los datos de acceso (usuario y contraseña), el rol y los datos mínimos de cada persona. Casi todas las demás tablas apuntan a ella.

| Campo             | Significado                                                                                                           |
| ----------------- | --------------------------------------------------------------------------------------------------------------------- |
| `id`              | Identificador único.                                                                                                  |
| `rol`             | `nino`, `padre`, `profesor` o `admin`. Decide qué puede hacer el usuario.                                             |
| `usuario`         | Nombre para iniciar sesión. Para los niños es un nombre inventado sin datos reales (ej.: `LeonAzul42`).               |
| `alias`           | Nombre público que aparece en el ranking. Nunca se muestra el nombre real.                                            |
| `nombre`          | Adultos: nombre real. Niños: opcional, solo nombre de pila o ficticio.                                                |
| `email`           | Obligatorio para adultos y vacío para niños (los avisos por correo solo van a adultos).                               |
| `password_hash`   | Contraseña cifrada con `password_hash()` de PHP. Para los niños es un PIN o contraseña sencilla creada por el adulto. |
| `avatar`          | Identificador de un dibujo de la galería propia. Nunca se suben fotos.                                                |
| `anio_nacimiento` | Solo el año, suficiente para filtrar contenido por edad.                                                              |
| `creado_por`      | Adulto que creó la cuenta (en los niños). Vacío en los adultos que se registran solos.                                |
| `activo`          | Si la cuenta puede usarse. Niños: se activa con el consentimiento. Adultos: al verificar el email.                    |
| `fecha_alta`      | Cuándo se creó la cuenta.                                                                                             |

**Relaciones:** se relaciona consigo misma a través de `creado_por` (un adulto crea a un niño) y es la tabla a la que apuntan todas las demás.

#### `consentimientos`

**Qué representa:** un permiso que un padre o tutor da sobre la cuenta de su hijo.

**Función:** deja constancia legal (RGPD/LOPDGDD) de qué ha autorizado el padre y cuándo. Sin un consentimiento de tipo `registro` vigente, la cuenta del niño no se activa.

| Campo           | Significado                                                                                                                |
| --------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `padre_id`      | Adulto que da el consentimiento.                                                                                           |
| `nino_id`       | Niño al que se refiere.                                                                                                    |
| `tipo`          | `registro` (usar la plataforma), `apoyo` (guardar preferencias del modo de apoyo) o `ranking` (aparecer en el scoreboard). |
| `version_texto` | Versión del texto legal que se aceptó, por si cambia en el futuro.                                                         |
| `fecha`         | Cuándo se dio.                                                                                                             |
| `revocado_en`   | Cuándo se retiró. Si está vacío, sigue vigente.                                                                            |

**Por qué se guarda como historial:** si el padre retira un permiso, no se borra la fila. Se rellena `revocado_en`, y así queda registro de lo que estaba autorizado en cada momento.

#### `perfiles_nino`

**Qué representa:** los datos que solo tienen sentido para un niño.

**Función:** amplía `usuarios` sin llenarla de columnas vacías para los adultos. Es una relación **1:1** con `usuarios` (un niño tiene un perfil).

| Campo                | Significado                                                                                                                                                           |
| -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `usuario_id`         | El niño (es a la vez clave primaria y clave foránea).                                                                                                                 |
| `curso` / `nivel`    | Curso escolar y nivel, para adaptar el contenido.                                                                                                                     |
| `preferencias_apoyo` | JSON con las preferencias del modo de apoyo: tipo de letra, tamaño, lectura en voz alta, modo foco… **Nunca un diagnóstico médico.** Requiere consentimiento `apoyo`. |
| `visible_en_ranking` | Si el niño aparece en el scoreboard. Solo puede activarse con consentimiento `ranking`.                                                                               |

#### `vinculos_familiares`

**Qué representa:** la relación entre un padre/tutor y un niño.

**Función:** resuelve la relación **N:M** entre adultos y niños: un niño puede tener varios tutores (padre, madre…) y un padre puede tener varios hijos. Gracias a ella, un padre solo ve los informes y reglas de **sus** hijos.

| Campo                  | Significado                                                            |
| ---------------------- | ---------------------------------------------------------------------- |
| `padre_id` + `nino_id` | Clave primaria compuesta: cada pareja padre-niño aparece una sola vez. |

---

### 2.2 Bloque de clases y tareas

#### `clases`

**Qué representa:** un grupo de alumnos con un profesor (ej.: "4º B Primaria").

**Función:** agrupa a los niños para asignarles tareas y para los rankings por clase.

| Campo         | Significado                                                                                   |
| ------------- | --------------------------------------------------------------------------------------------- |
| `nombre`      | Nombre de la clase.                                                                           |
| `profesor_id` | Profesor responsable. No se puede borrar un profesor que tenga clases asignadas (`restrict`). |

> Si se elige el inicio de sesión con código de clase, se añadirá aquí un `codigo_acceso` único.

#### `matriculas`

**Qué representa:** que un niño pertenece a una clase.

**Función:** resuelve la relación **N:M** entre clases y niños: una clase tiene muchos alumnos y un niño puede estar en varias clases (por ejemplo, la de su curso y una de refuerzo).

| Campo                  | Significado               |
| ---------------------- | ------------------------- |
| `clase_id` + `nino_id` | Clave primaria compuesta. |

#### `tareas`

**Qué representa:** un trabajo que el profesor manda a una clase.

**Función:** es el centro de la parte educativa. Cuando se crea una tarea, todos los niños matriculados en esa clase la tienen pendiente.

| Campo                             | Significado                                      |
| --------------------------------- | ------------------------------------------------ |
| `clase_id`                        | Clase a la que va dirigida.                      |
| `titulo` / `descripcion`          | Qué hay que hacer.                               |
| `fecha_creacion` / `fecha_limite` | Cuándo se creó y hasta cuándo se puede entregar. |
| `puntos`                          | Puntos que da al completarla (10 por defecto).   |

#### `entregas`

**Qué representa:** la respuesta de un niño a una tarea.

**Función:** registra qué ha entregado cada niño, cuándo y qué nota tiene. Es la tabla que comprueba la regla **"estudio primero"**: si un niño tiene tareas sin entregar, no puede acceder a vídeos ni juegos.

| Campo                  | Significado                                                                             |
| ---------------------- | --------------------------------------------------------------------------------------- |
| `tarea_id` / `nino_id` | Qué tarea y qué niño. Solo puede haber **una entrega por tarea y niño** (índice único). |
| `estado`               | `pendiente` → `entregada` → `revisada`.                                                 |
| `fecha_entrega`        | Cuándo la entregó.                                                                      |
| `contenido`            | La respuesta del niño.                                                                  |
| `nota`                 | Nota del profesor, de 0 a 10.                                                           |

---

### 2.3 Bloque de control parental y catálogo

#### `reglas_control`

**Qué representa:** las normas que un padre fija para su hijo.

**Función:** el servidor consulta esta tabla cada vez que un niño intenta abrir un vídeo o un juego. Es una relación **1:1** con el niño.

| Campo                      | Significado                                                                                                               |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `nino_id`                  | El niño al que se aplican (clave primaria).                                                                               |
| `estudio_primero`          | Si está activo, primero hay que entregar las tareas pendientes.                                                           |
| `minutos_diarios`          | Tiempo máximo de ocio al día.                                                                                             |
| `hora_inicio` / `hora_fin` | Franja horaria en la que se permite el ocio.                                                                              |
| `edad_contenido_max`       | Límite de edad del contenido fijado por el padre. Si está vacío, se usa la edad real (calculada desde `anio_nacimiento`). |

#### `catalogo`

**Qué representa:** un vídeo o un juego aprobado para la plataforma.

**Función:** como una web no puede bloquear YouTube ni otras apps, Educate ofrece su **propio catálogo cerrado**. Solo se muestra lo que está aquí.

| Campo                  | Significado                                                                         |
| ---------------------- | ----------------------------------------------------------------------------------- |
| `tipo`                 | `video` o `juego`.                                                                  |
| `titulo` / `categoria` | Nombre y temática.                                                                  |
| `url_o_ruta`           | Enlace del vídeo (youtube-nocookie) o ruta del juego propio.                        |
| `edad_minima`          | Edad mínima recomendada.                                                            |
| `aprobado_por`         | Adulto que lo aprobó. Si ese usuario se borra, el recurso se conserva (`set null`). |

#### `sesiones_uso`

**Qué representa:** cada vez que un niño abre un vídeo o un juego.

**Función:** permite **controlar el tiempo diario** (sumando la duración de las sesiones de hoy) y genera los datos de uso para los informes de los padres.

| Campo                    | Significado                                                            |
| ------------------------ | ---------------------------------------------------------------------- |
| `nino_id` / `recurso_id` | Quién y qué contenido.                                                 |
| `inicio` / `fin`         | Cuándo empezó y terminó. Si `fin` está vacío, la sesión sigue abierta. |

**Privacidad:** estos registros se borran o anonimizan pasado un tiempo (por ejemplo, 12 meses).

---

### 2.4 Bloque de scoreboard y avisos

#### `puntuaciones`

**Qué representa:** cada vez que un niño gana puntos.

**Función:** es el **historial de puntos**. El ranking no se guarda: se calcula sumando esta tabla (`SUM(puntos)`) por niño, por clase y por periodo (semanal o mensual).

| Campo           | Significado                                                                                                                                 |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `nino_id`       | Quién gana los puntos.                                                                                                                      |
| `origen`        | `tarea`, `juego`, `racha` o `bonus`. Permite aplicar un **tope diario a los puntos de juego**, para que jugar no compense más que estudiar. |
| `referencia_id` | Qué lo generó: el id de la entrega (si es una tarea) o del recurso del catálogo (si es un juego).                                           |
| `motivo`        | Texto descriptivo (ej.: "Racha de 5 días").                                                                                                 |
| `puntos`        | Cantidad. La calcula siempre el servidor.                                                                                                   |
| `fecha`         | Cuándo. Junto con `nino_id` forma un índice para que los rankings sean rápidos.                                                             |

#### `notificaciones`

**Qué representa:** un aviso dentro de la web para un usuario.

**Función:** informa de cosas como "nueva tarea", "tarea corregida" o "tu hijo ha entregado todo". Los correos electrónicos solo se envían a adultos.

| Campo              | Significado             |
| ------------------ | ----------------------- |
| `usuario_id`       | Destinatario.           |
| `tipo` / `mensaje` | Clase de aviso y texto. |
| `leida`            | Si ya la ha visto.      |
| `fecha`            | Cuándo se generó.       |

---

## 3. Relaciones

| Relación                                  | Tipo | Tablas implicadas                        |
| ----------------------------------------- | ---- | ---------------------------------------- |
| Un adulto crea cuentas de niños           | 1:N  | `usuarios` → `usuarios` (`creado_por`)   |
| Un niño tiene un perfil                   | 1:1  | `usuarios` – `perfiles_nino`             |
| Un niño tiene unas reglas de control      | 1:1  | `usuarios` – `reglas_control`            |
| Padres ↔ niños                            | N:M  | `vinculos_familiares`                    |
| Un padre da consentimientos sobre un niño | 1:N  | `usuarios` → `consentimientos`           |
| Un profesor imparte clases                | 1:N  | `usuarios` → `clases`                    |
| Clases ↔ niños                            | N:M  | `matriculas`                             |
| Una clase tiene tareas                    | 1:N  | `clases` → `tareas`                      |
| Una tarea recibe entregas (una por niño)  | 1:N  | `tareas` → `entregas`                    |
| Un niño usa recursos del catálogo         | 1:N  | `usuarios` / `catalogo` → `sesiones_uso` |
| Un niño acumula puntos                    | 1:N  | `usuarios` → `puntuaciones`              |
| Un usuario recibe avisos                  | 1:N  | `usuarios` → `notificaciones`            |

**Borrado:** al eliminar a un niño se borran **en cascada** todos sus datos (perfil, consentimientos, entregas, sesiones, puntos…), cumpliendo el derecho de supresión del RGPD.

---

## 4. Ejemplos de funcionamiento

**Alta de un niño**

1. Un padre se registra (`usuarios`, rol `padre`) y verifica su email → `activo = true`.
2. El padre crea la cuenta de su hijo (`usuarios`, rol `nino`, `creado_por` = padre, `activo = false`).
3. Se crean el `perfiles_nino`, las `reglas_control` y el `vinculos_familiares`.
4. El padre acepta el texto legal → fila en `consentimientos` con tipo `registro` → la cuenta del niño pasa a `activo = true`.

**Un niño quiere ver un vídeo.** El servidor comprueba, en este orden:

1. Que el recurso existe en `catalogo` y que su `edad_minima` es apropiada.
2. Si `estudio_primero` está activo, que no tiene tareas `pendiente` en `entregas`.
3. Que la hora actual está entre `hora_inicio` y `hora_fin`.
4. Que la suma de `sesiones_uso` de hoy no supera `minutos_diarios`.

Si todo se cumple, abre una fila en `sesiones_uso` y se muestra el vídeo.

**Ranking semanal de una clase**

- Se suman las `puntuaciones` de los niños de esa clase (`matriculas`) de los últimos 7 días.
- Solo aparecen los que tienen `visible_en_ranking = true`, y se muestra su `alias`.

---

## 5. Reglas fuera del diagrama

DBML no puede expresar estas reglas, así que van en la base de datos o en el servidor:

- `CHECK (rol = 'nino' OR email IS NOT NULL)`: el email es obligatorio para los adultos.
- Las columnas `padre_id`, `nino_id` y `profesor_id` deben apuntar a usuarios con ese rol (validación en el servidor).
- `visible_en_ranking` solo puede ser `true` si hay consentimiento de tipo `ranking` vigente.
- `preferencias_apoyo` solo se guarda si hay consentimiento de tipo `apoyo` vigente.
- Tope diario de puntos con `origen = 'juego'` (lo calcula el servidor).

---

## 6. Historial de versiones

| Versión | Cambios                                                                                                                                                                                                                                                        |
| ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2.1     | Avatar de galería propia; `puntuaciones` con `origen` y `referencia_id`; se elimina `puntos_totales` (el ranking se calcula); entrega única por tarea y niño; borrado en cascada; `edad_maxima` pasa a `edad_contenido_max`; ENUM para roles, tipos y estados. |
| 2.0     | El niño no se registra solo; tabla `consentimientos`; email opcional para niños; solo año de nacimiento.                                                                                                                                                       |
| 1.0     | Primera versión del modelo.                                                                                                                                                                                                                                    |
