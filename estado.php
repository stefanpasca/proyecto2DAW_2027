<?php
/**
 * PÁGINA DE ESTADO (temporal, solo para desarrollo)
 * Comprueba que PHP, la configuración y la base de datos funcionan.
 * Se quitará cuando exista el login.
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/bootstrap.php';

if (ENTORNO !== 'desarrollo') {
    http_response_code(404);
    exit;
}

$comprobaciones = [];
$tablas = [];
$migraciones = [];
$versionBd = null;

$comprobaciones[] = ['PHP ' . PHP_VERSION, version_compare(PHP_VERSION, '8.1', '>='), 'Se necesita PHP 8.1 o superior'];
$comprobaciones[] = ['Extensión pdo_mysql', extension_loaded('pdo_mysql'), 'Activa extension=pdo_mysql en php.ini'];

try {
    $pdo = db();
    $versionBd = (string) $pdo->query('SELECT VERSION()')->fetchColumn();
    $comprobaciones[] = ['Conexión como ' . DB_USER, true, ''];

    $nombres = $pdo->query('SHOW TABLES')->fetchAll(PDO::FETCH_COLUMN);
    foreach ($nombres as $tabla) {
        if ($tabla === '_migraciones') {
            continue;
        }
        $filas = (int) $pdo->query('SELECT COUNT(*) FROM `' . str_replace('`', '', $tabla) . '`')->fetchColumn();
        $tablas[$tabla] = $filas;
    }
    $comprobaciones[] = [count($tablas) . ' tablas en la BD (' . DB_NAME . ')', count($tablas) >= 13, 'Deberían ser al menos 13. Ejecuta database/reset.php'];

    if (in_array('_migraciones', $nombres, true)) {
        $migraciones = $pdo->query('SELECT archivo, aplicada_en FROM _migraciones ORDER BY archivo')->fetchAll();
    }
} catch (PDOException $ex) {
    $comprobaciones[] = ['Conexión como ' . DB_USER, false, $ex->getMessage() . ' → ¿Está MySQL arrancado en XAMPP? Si lo está, ejecuta database/reset.php para crear la BD y el usuario.'];
}

$pendientes = [];
$enRepo = array_map('basename', glob(__DIR__ . '/database/migraciones/*.sql') ?: []);
$aplicadasNombres = array_column($migraciones, 'archivo');
foreach ($enRepo as $archivo) {
    if (!in_array($archivo, $aplicadasNombres, true)) {
        $pendientes[] = $archivo;
    }
}
?>
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Educate · Estado</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 860px; margin: 2rem auto; padding: 0 1rem; color: #1d2733; }
    h1 { color: #2e5e8c; margin-bottom: .2rem; }
    table { border-collapse: collapse; width: 100%; margin: .5rem 0 1.5rem; }
    td, th { border-bottom: 1px solid #dde3ea; padding: .4rem .6rem; text-align: left; }
    th { background: #f2f4f7; }
    .ok { color: #1d7a3a; font-weight: 600; }
    .err { color: #b3261e; font-weight: 600; }
    .aviso { background: #fff6e0; border-left: 4px solid #d99a00; padding: .6rem 1rem; }
    a.boton { display: inline-block; padding: .5rem 1rem; background: #2e5e8c; color: #fff; border-radius: 6px; text-decoration: none; margin: 0 .4rem .4rem 0; }
    small { color: #5b6876; }
  </style>
</head>
<body>
  <h1>Educate · Estado del entorno</h1>
  <small>Página temporal de desarrollo. Se sustituirá por el login.</small>

  <h2>Comprobaciones</h2>
  <table>
    <?php foreach ($comprobaciones as [$texto, $ok, $ayuda]): ?>
      <tr>
        <td class="<?= $ok ? 'ok' : 'err' ?>"><?= $ok ? '✔' : '✘' ?></td>
        <td><?= e($texto) ?><?php if (!$ok && $ayuda): ?><br><small><?= e($ayuda) ?></small><?php endif; ?></td>
      </tr>
    <?php endforeach; ?>
    <?php if ($versionBd): ?>
      <tr><td></td><td>Servidor de BD: <?= e($versionBd) ?></td></tr>
    <?php endif; ?>
  </table>

  <?php if ($pendientes): ?>
    <p class="aviso"><strong>Hay <?= count($pendientes) ?> migración(es) sin aplicar:</strong>
      <?= e(implode(', ', $pendientes)) ?>. Ejecuta <code>database/migrar.php</code>.</p>
  <?php endif; ?>

  <p>
    <a class="boton" href="database/migrar.php">Aplicar migraciones</a>
    <a class="boton" href="database/reset.php">Reiniciar BD</a>
    <a class="boton" href="/phpmyadmin/">phpMyAdmin</a>
  </p>

  <?php if ($tablas): ?>
    <h2>Tablas</h2>
    <table>
      <tr><th>Tabla</th><th>Filas</th></tr>
      <?php foreach ($tablas as $tabla => $filas): ?>
        <tr><td><?= e($tabla) ?></td><td><?= $filas ?></td></tr>
      <?php endforeach; ?>
    </table>
  <?php endif; ?>

  <h2>Migraciones aplicadas</h2>
  <?php if ($migraciones): ?>
    <table>
      <tr><th>Archivo</th><th>Aplicada</th></tr>
      <?php foreach ($migraciones as $m): ?>
        <tr><td><?= e($m['archivo']) ?></td><td><?= e($m['aplicada_en']) ?></td></tr>
      <?php endforeach; ?>
    </table>
  <?php else: ?>
    <p><small>Ninguna todavía.</small></p>
  <?php endif; ?>
</body>
</html>
