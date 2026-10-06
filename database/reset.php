<?php
/**
 * REINICIA LA BASE DE DATOS DESDE CERO
 *
 *   1. Borra y vuelve a crear la BD "educate" con database/educate.sql (incluye datos de prueba)
 *   2. Aplica todas las migraciones de database/migraciones/
 *   3. Crea el usuario educate_app (o le cambia la contraseña) según config/config.php
 *
 * Úsalo la primera vez que montas el proyecto, o cuando tu BD esté hecha un lío.
 * ¡BORRA TODOS LOS DATOS de tu BD local!
 *
 *   - Navegador: http://localhost/proyecto2DAW_2027/database/reset.php
 *   - Consola:   C:\xampp\php\php.exe database\reset.php --si
 */

declare(strict_types=1);

require_once __DIR__ . '/herramientas.php';
proteger_acceso();

$confirmado = es_cli()
    ? in_array('--si', $argv ?? [], true)
    : (($_GET['confirmar'] ?? '') === 'si');

pagina_inicio('Educate · Reiniciar base de datos');

if (!$confirmado) {
    linea('Esto BORRA la base de datos "' . DB_NAME . '" de tu ordenador y la crea de nuevo');
    linea('con educate.sql, todas las migraciones y los datos de prueba.');
    linea('');
    linea('También deja el usuario "' . DB_USER . '" con la contraseña que tienes en config/config.php.');
    if (es_cli()) {
        linea('');
        linea('Para confirmar, ejecuta:  C:\\xampp\\php\\php.exe database\\reset.php --si');
    }
    pagina_fin('<p><a class="boton peligro" href="?confirmar=si">Sí, reiniciar la base de datos</a>'
        . '<a class="boton" href="../estado.php">Cancelar</a></p>');
    exit(0);
}

try {
    $pdo = conexion_admin();
} catch (PDOException $ex) {
    linea('ERROR: ' . explicar_error_conexion($ex));
    pagina_fin();
    exit(1);
}

try {
    linea('1/3 Creando la base de datos con educate.sql ...');
    $n = ejecutar_archivo_sql($pdo, SCRIPT_BASE);
    linea("   OK ({$n} sentencias)");

    $pdo->exec('USE `' . DB_NAME . '`');

    linea('2/3 Aplicando migraciones ...');
    $aplicadas = aplicar_migraciones($pdo);
    if ($aplicadas === []) {
        linea('   No hay migraciones todavía.');
    }

    linea('3/3 Preparando el usuario de la web "' . DB_USER . '" ...');
    sincronizar_usuario_app($pdo);
    linea('   OK');

    // Comprobación final: la web se conecta con su propio usuario
    $dsn = sprintf('mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4', DB_HOST, DB_PORT, DB_NAME);
    $app = new PDO($dsn, DB_USER, DB_PASS, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
    $usuarios = (int) $app->query('SELECT COUNT(*) FROM usuarios')->fetchColumn();

    linea('');
    linea("TODO LISTO. La web se conecta como " . DB_USER . " y ve {$usuarios} usuarios de prueba.");
    linea('Adultos: admin, laura.padre, profe.ruiz  (contraseña Educate2026!)');
    linea('Niños:   LeonAzul42, GatoVerde7, BuhoRojo9 (PIN 1234; BuhoRojo9 está inactivo a propósito)');
    pagina_fin('<p><a class="boton" href="../estado.php">Ver estado del proyecto</a></p>');
} catch (Throwable $ex) {
    linea('');
    linea('ERROR: ' . $ex->getMessage());
    pagina_fin();
    exit(1);
}
