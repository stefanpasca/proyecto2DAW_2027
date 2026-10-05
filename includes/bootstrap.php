<?php
/**
 * Punto de arranque común. Toda página PHP empieza con:
 *
 *     require_once __DIR__ . '/includes/bootstrap.php';        (desde la raíz)
 *     require_once __DIR__ . '/../includes/bootstrap.php';     (desde una subcarpeta)
 *
 * Carga la configuración, la conexión a la BD y las funciones comunes.
 */

declare(strict_types=1);

$rutaConfig = __DIR__ . '/../config/config.php';
if (!is_file($rutaConfig)) {
    http_response_code(500);
    echo '<h1>Falta config/config.php</h1>';
    echo '<p>Copia <code>config/config.example.php</code> como <code>config/config.php</code> ';
    echo 'y pon tus datos. Después abre <code>database/reset.php</code>.</p>';
    exit;
}
require_once $rutaConfig;

if (ENTORNO === 'desarrollo') {
    ini_set('display_errors', '1');
    error_reporting(E_ALL);
} else {
    ini_set('display_errors', '0');
}

date_default_timezone_set('Europe/Madrid');
mb_internal_encoding('UTF-8');

require_once __DIR__ . '/db.php';
require_once __DIR__ . '/funciones.php';
