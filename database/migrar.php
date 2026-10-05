<?php
/**
 * APLICA LAS MIGRACIONES PENDIENTES (sin borrar datos)
 *
 * Úsalo después de cada "git pull":
 *   - Navegador: http://localhost/proyecto2DAW_2027/database/migrar.php
 *   - Doble clic en database\migrar.bat
 *   - Consola:   C:\xampp\php\php.exe database\migrar.php
 *
 * Ejecuta, en orden, los archivos de database/migraciones/ que todavía no
 * se hayan aplicado en tu BD, y los apunta en la tabla _migraciones.
 */

declare(strict_types=1);

require_once __DIR__ . '/herramientas.php';
proteger_acceso();

pagina_inicio('Educate · Migraciones');

try {
    $pdo = conexion_admin(DB_NAME);
} catch (PDOException $ex) {
    if (str_contains($ex->getMessage(), '1049')) {
        linea('La base de datos "' . DB_NAME . '" no existe todavía. Ejecuta primero database/reset.php');
    } else {
        linea('ERROR: ' . explicar_error_conexion($ex));
    }
    pagina_fin('<p><a class="boton" href="reset.php">Ir a reset.php</a></p>');
    exit(1);
}

try {
    $aplicadas = aplicar_migraciones($pdo);
    if ($aplicadas === []) {
        linea('Tu base de datos ya está al día. No hay migraciones pendientes.');
    } else {
        linea('');
        linea('Listo: ' . count($aplicadas) . ' migración(es) aplicada(s).');
    }
    $total = count(migraciones_disponibles());
    linea("Migraciones en el repositorio: {$total}");
    pagina_fin('<p><a class="boton" href="../estado.php">Ver estado del proyecto</a></p>');
} catch (Throwable $ex) {
    linea('');
    linea('ERROR: ' . $ex->getMessage());
    linea('');
    linea('La migración que ha fallado NO se ha marcado como aplicada.');
    linea('Corrige el archivo .sql (o avisa a quien lo subió) y vuelve a ejecutar migrar.php.');
    linea('Si la BD ha quedado a medias, usa reset.php para empezar de cero.');
    pagina_fin();
    exit(1);
}
