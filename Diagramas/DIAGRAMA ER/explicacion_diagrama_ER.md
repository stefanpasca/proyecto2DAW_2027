# Diagrama entidad-relación de Educate

## Cómo se lee

- Rectángulo: entidad (USUARIO, CLASE, TAREA...).
- Rombo: relación entre entidades (Imparte, Entrega, Canjea...). Dentro pone el tipo de relación: 1:1, 1:N o N:M.
- Óvalo: atributo. Si está subrayado es la clave primaria.
- Triángulo ES UN: jerarquía. ADMIN, PROFESOR y ALUMNO son tipos de USUARIO. Es total (todo usuario es de uno de los tres tipos) y exclusiva (solo puede ser de uno).
- Cardinalidades (mín, máx): el número que está al lado de una entidad dice cuántas veces aparece esa entidad por cada una de la otra. Por ejemplo, PROFESOR (1,1) Imparte (0,N) CLASE quiere decir que una clase la imparte un solo profesor y que un profesor puede impartir de 0 a N clases.

## Diferencias con el modelo relacional

- En el E/R no aparecen las claves ajenas, porque ya están representadas por las relaciones.
- `matriculas`, `entregas` y `respuestas` en el E/R no son entidades, son relaciones N:M con atributos (Se matricula, Entrega y Responde). Cuando se pasa al modelo relacional, las relaciones N:M se convierten en tablas intermedias, y por eso en dbdiagram sí son tablas.
- `perfiles_alumno` no aparece como entidad. Sus atributos (curso y preferencias_apoyo) están en ALUMNO, porque es una relación 1 a 1.
- Los tipos de usuario se ven como una jerarquía, aunque en la base de datos todo está en la tabla `usuarios` con el campo `rol`.

## Relaciones principales

- Personas: un profesor da de alta alumnos menores y registra sus consentimientos, y cada alumno puede tener varios consentimientos.
- Classroom: un profesor imparte clases, los alumnos se matriculan en clases (N:M), cada clase contiene tareas y los alumnos entregan tareas (N:M).
- Actividades: una clase propone actividades, una actividad se compone de preguntas, cada pregunta incluye opciones, un alumno realiza intentos sobre una actividad y en cada intento responde preguntas (N:M).
- Puntos y tienda: un alumno gana puntuaciones en una clase, un intento genera como mucho una puntuación (1:1), una clase ofrece recompensas, una recompensa puede afectar a una tarea y un alumno canjea recompensas.
