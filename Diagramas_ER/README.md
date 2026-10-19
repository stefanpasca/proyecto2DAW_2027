# Diagramas Entidad/Relación

Modelo de datos de Educate para **MySQL 8.0.16 o superior**.

## Archivos

| Archivo | Versión | Descripción |
|---|---|---|
| `EDUCATE v2.1 E_R.pdf` | 2.1 | Diagrama exportado desde [dbdiagram.io](https://dbdiagram.io) |

## Tablas (v2.1)

| Grupo | Tablas |
|---|---|
| Usuarios y consentimiento | `usuarios`, `consentimientos`, `perfiles_nino`, `vinculos_familiares` |
| Clases y tareas | `clases`, `matriculas`, `tareas`, `entregas` |
| Control parental y catálogo | `reglas_control`, `catalogo`, `sesiones_uso` |
| Scoreboard y avisos | `puntuaciones`, `notificaciones` |

- Todos los roles (niño, padre, profesor, admin) comparten la tabla `usuarios`.
- Las relaciones N:M se resuelven con tablas intermedias: padres ↔ niños (`vinculos_familiares`) y clases ↔ niños (`matriculas`).
- Los informes no tienen tabla: se calculan a partir de entregas, puntuaciones y sesiones.

## Protección de datos de menores

- El niño lo da de alta un adulto. Su email es opcional y su `usuario` de acceso no contiene datos reales.
- Solo se guarda el **año** de nacimiento.
- La cuenta del niño está inactiva hasta que existe un consentimiento parental de tipo `registro`.
- El modo de apoyo guarda solo preferencias de uso, **nunca un diagnóstico**.
- Al borrar un niño se borran en cascada todos sus datos (derecho de supresión, RGPD).
- Los registros de `sesiones_uso` se borran o anonimizan pasado un tiempo (ej.: 12 meses).

## Reglas fuera del diagrama

DBML no puede expresar estas reglas, así que van en la base de datos o en el servidor:

- `CHECK (rol = 'nino' OR email IS NOT NULL)`: el email es obligatorio para los adultos.
- Las columnas `padre_id`, `nino_id` y `profesor_id` deben apuntar a usuarios con ese rol (validación en el servidor).
- `visible_en_ranking` solo puede ser `true` si hay consentimiento de tipo `ranking` vigente.
- Tope diario de puntos con `origen = 'juego'` (lo calcula el servidor).

## Historial de versiones

| Versión | Cambios |
|---|---|
| 2.1 | Avatar de galería propia; `puntuaciones` con `origen` y `referencia_id`; se elimina `puntos_totales` (el ranking se calcula); entrega única por tarea y niño; borrado en cascada; `edad_maxima` pasa a `edad_contenido_max`; ENUM para roles, tipos y estados. |
| 2.0 | El niño no se registra solo; tabla `consentimientos`; email opcional para niños; solo año de nacimiento. |
| 1.0 | Primera versión del modelo. |
