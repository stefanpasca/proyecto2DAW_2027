# Modelo relacional v2.1 de Educate (versión anterior)

## Qué es

Este es el modelo relacional de la primera idea que tuvimos para Educate, la versión 2.1. Lo hicimos con dbdiagram.io igual que el modelo actual. En esa versión Educate era una plataforma de control parental orientada al aprendizaje: los padres controlaban el tiempo de uso de sus hijos y los niños tenían que hacer primero las tareas del colegio antes de poder ver vídeos o jugar a juegos educativos de un catálogo.

Al final abandonamos esta idea y la cambiamos por la actual (un classroom con actividades tipo Kahoot y una tienda de puntos). Más abajo explicamos por qué.

## Cómo se lee

Se lee igual que el modelo actual:

- Cada caja es una tabla y cada fila es una columna con su tipo.
- La llave indica la clave primaria (PK) y las columnas con enlace son claves ajenas (FK) que apuntan a otra tabla.
- Las líneas unen las claves ajenas con la tabla a la que apuntan. `1 - *` es uno a muchos y `1 - 1` es uno a uno.
- NN quiere decir que la columna no puede ser nula.
- En la última página están los enums, que son las listas cerradas de valores.

## Usuarios y consentimiento

- `usuarios`: una sola tabla para todos los roles, que en esta versión eran cuatro: niño, padre, profesor y admin. Igual que ahora, los niños no tenían datos reales: un nombre de usuario inventado, un alias para el ranking y sin email obligatorio. También tenían un `avatar` elegido de una galería propia, para no tener que subir fotos. Del nacimiento solo se guardaba el año, para filtrar el contenido por edad.
- `vinculos_familiares`: tabla intermedia N a M entre padres y niños (un padre puede tener varios hijos y un niño puede tener varios padres o tutores).
- `consentimientos`: aquí el consentimiento lo daba el padre (`padre_id`) para su hijo (`nino_id`). Había tres tipos: registro (para poder usar la cuenta), apoyo (para guardar las preferencias del modo de apoyo) y ranking (para aparecer en el scoreboard con su alias).
- `perfiles_nino`: datos extra del niño como el curso, el nivel, las preferencias de apoyo y si es visible en el ranking. Este último campo solo podía ser true si había un consentimiento de tipo ranking vigente.

## Clases y tareas

- `clases`, `matriculas`, `tareas` y `entregas`: esta parte es muy parecida a la versión actual. Un profesor tiene clases, los niños se matriculan en ellas, cada clase tiene tareas y cada niño hace una entrega por tarea. La diferencia es que aquí cada tarea daba un número fijo de puntos (`puntos`) al entregarla.

## Control parental y catálogo

Esta era la parte principal de la idea original:

- `reglas_control`: las reglas que ponía el padre para cada niño. Si tenía que estudiar primero antes de usar el resto de la web (`estudio_primero`), los minutos máximos al día, la franja horaria permitida y la edad máxima del contenido que podía ver.
- `catalogo`: los vídeos y juegos educativos de la web, con su edad mínima, su categoría y quién los había aprobado.
- `sesiones_uso`: el registro de cuándo usaba el niño cada recurso del catálogo (inicio y fin). Servía para controlar el tiempo diario. Estaba pensado borrar o anonimizar estos registros pasado un tiempo.

## Scoreboard y avisos

- `puntuaciones`: los puntos de cada niño. Podían venir de una tarea, de un juego, de una racha o de un bonus. El campo `referencia_id` guardaba el id de la entrega o del juego, pero sin clave ajena porque podía apuntar a tablas distintas según el origen. El ranking era la suma de los puntos de cada niño y había un tope diario para los puntos de juegos.
- `notificaciones`: los avisos dentro de la web, igual que ahora.

## Por qué lo abandonamos

Lo dejamos por dos motivos principales.

El primero es que trabajar con niños era demasiado complicado por las leyes de protección de datos (RGPD y LOPDGDD). Al ser menores de 14 años necesitábamos el consentimiento de los padres para casi todo, y eso hacía que el modelo se complicara mucho: tres tipos de consentimiento distintos, vínculos entre padres e hijos, comprobar que quien da el consentimiento es de verdad el padre, no poder pedir casi ningún dato al niño en el registro, borrar en cascada todos sus datos si se pedía la supresión, anonimizar el historial de uso... Además, al registrar qué hacía el niño y cuánto tiempo estaba conectado, estábamos guardando bastante información sobre menores, y cuanta más información de menores guardas más obligaciones tienes. Todo esto se iba a llevar una parte muy grande del proyecto solo en temas legales.

El segundo es que la web dependía de tener un catálogo de vídeos y juegos educativos, y ese contenido lo teníamos que poner nosotros. Buscar o crear vídeos y juegos para distintas edades, revisarlos y mantenerlos era demasiado trabajo para el tiempo que tenemos, y sin ese contenido la web no tenía sentido.

## Qué cambió en la versión actual

- Ya no hay rol de padre ni control parental. Desaparecen `vinculos_familiares`, `reglas_control`, `catalogo` y `sesiones_uso`.
- El público ya no son solo niños, son edades mezcladas. Los alumnos de 14 o más se registran solos con email. Para los menores de 14 seguimos guardando el consentimiento, pero lo registra el profesor y es mucho más simple.
- El contenido ya no lo ponemos nosotros, lo crean los profesores con las actividades tipo Kahoot (preguntas, opciones, ordenar, emparejar...).
- Los puntos ahora se ganan con las actividades y se pueden gastar en una tienda de recompensas de cada clase, y el profesor puede dejar que alguna recompensa suba la nota de una tarea.

Algunas ideas sí las hemos mantenido porque funcionaban bien: una sola tabla de usuarios con rol, no guardar datos reales de los menores, el alias para el ranking, guardar solo el año de nacimiento, la tabla de consentimientos con versión del texto legal, y que el ranking se calcule sumando los puntos en vez de guardar un total.
