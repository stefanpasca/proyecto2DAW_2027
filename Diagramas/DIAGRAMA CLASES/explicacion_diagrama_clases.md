# Diagrama de clases de Educate

## Cómo se lee

- Cada caja es una clase y tiene tres partes: el nombre, los atributos y los métodos.
- `-` delante quiere decir privado y `+` quiere decir público.
- `?` delante de un tipo quiere decir que puede ser null (por ejemplo `?string`).
- Línea normal: asociación entre clases. En cada extremo se pone la multiplicidad (`1`, `0..1`, `0..*`).
- Línea con rombo negro: composición. El rombo va en la clase que es el "todo", y las partes no tienen sentido sin ella. Por ejemplo, una Pregunta no existe sin su Actividad, y si se borra la actividad se borran sus preguntas. Coincide con los borrados en cascada de la base de datos.
- Línea con triángulo blanco: herencia.
- Las cajas amarillas de la izquierda son enumeraciones, que se usan como tipo en algunos atributos.

## Clases

- `Usuario` es una clase abstracta (no se crean objetos de ella directamente) y `Alumno`, `Profesor` y `Admin` heredan de ella. Así los atributos comunes como el login y la contraseña solo se definen una vez.
- `Matricula`, `Entrega` y `Respuesta` son clases normales, unidas con dos asociaciones de 1 a muchos, porque así es como las vamos a programar.
- Los atributos están en camelCase (por ejemplo `fechaLimite` en vez de `fecha_limite`), que es como se escribe normalmente en PHP.
- Los métodos son las acciones principales de cada clase, por ejemplo:
  - `Alumno`: unirseAClase(), getSaldo(), canjear().
  - `Profesor`: crearClase(), calificar(), resolverCanje().
  - `Entrega`: getNotaFinal(), que aplica el tope de 10.
  - `Respuesta`: calcularPuntos(), que da 10 puntos más un extra de 0 a 5 por rapidez si la respuesta es correcta.
