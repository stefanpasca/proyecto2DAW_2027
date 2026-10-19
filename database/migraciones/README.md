# Migraciones

Aquí va **cada cambio** que se haga en la base de datos después de `educate.sql`.
Así los tres tenemos siempre la misma BD sin reimportar nada.

## Cómo crear una migración

1. Crea un archivo nuevo con el siguiente número libre y un nombre que diga qué hace:

   ```
   001_codigo_acceso_clases.sql
   002_tabla_insignias.sql
   ```

   Usa siempre tres cifras (`001`, `010`...) para que se ordenen bien.
   Si dos personas cogen el mismo número a la vez, el que haga *merge* después
   renombra el suyo al siguiente número libre.

2. Escribe dentro el SQL del cambio, por ejemplo:

   ```sql
   ALTER TABLE clases
     ADD COLUMN codigo_acceso VARCHAR(10) NULL UNIQUE AFTER nombre;
   ```

3. Pruébala en tu ordenador con `database/migrar.php`.
4. Actualiza el diagrama DBML si cambia el modelo.
5. Haz *commit* de la migración junto con el código PHP que la usa.

## Reglas

- **Nunca edites una migración que ya está en `main`**: los demás ya la han aplicado.
  Si hay que corregir algo, crea otra migración nueva.
- No uses `DELIMITER` (triggers o procedimientos almacenados): el script no lo admite.
- No hagas cambios de estructura «a mano» en phpMyAdmin sin crear su migración.
- Si tu BD se queda rota, `database/reset.php` la recrea desde cero
  (`educate.sql` + todas las migraciones + datos de prueba).
