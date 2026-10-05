<?php
/**
 * Funciones compartidas por database/migrar.php y database/reset.php.
 * No se abre directamente.
 */

declare(strict_types=1);

$rutaConfig = __DIR__ . '/../config/config.php';
if (!is_file($rutaConfig)) {
    $msg = "Falta config/config.php. Copia config/config.example.php como config/config.php y pon tus datos.";
    if (PHP_SAPI === 'cli') {
        fwrite(STDERR, $msg . PHP_EOL);
        exit(1);
    }
    http_response_code(500);
    exit($msg);
}
require_once $rutaConfig;

const TABLA_MIGRACIONES = '_migraciones';
const CARPETA_MIGRACIONES = __DIR__ . '/migraciones';
const SCRIPT_BASE = __DIR__ . '/educate.sql';

function es_cli(): bool
{
    return PHP_SAPI === 'cli';
}

/** Solo se puede usar en desarrollo y desde el propio ordenador. */
function proteger_acceso(): void
{
    if (es_cli()) {
        return;
    }
    $ip = $_SERVER['REMOTE_ADDR'] ?? '';
    if (ENTORNO !== 'desarrollo' || !in_array($ip, ['127.0.0.1', '::1'], true)) {
        http_response_code(403);
        exit('Herramienta disponible solo en desarrollo y desde localhost.');
    }
}

/* ---------- Salida por pantalla (navegador o consola) ---------- */

function pagina_inicio(string $titulo): void
{
    if (es_cli()) {
        echo "== {$titulo} ==" . PHP_EOL;
        return;
    }
    header('Content-Type: text/html; charset=utf-8');
    echo '<!doctype html><html lang="es"><head><meta charset="utf-8">';
    echo '<title>' . htmlspecialchars($titulo) . '</title>';
    echo '<style>body{font-family:system-ui,sans-serif;max-width:860px;margin:2rem auto;padding:0 1rem;color:#1d2733}'
        . 'pre{background:#f2f4f7;padding:1rem;border-left:4px solid #2e5e8c;white-space:pre-wrap}'
        . '.ok{color:#1d7a3a}.err{color:#b3261e}a.boton{display:inline-block;padding:.5rem 1rem;background:#2e5e8c;color:#fff;border-radius:6px;text-decoration:none;margin-right:.5rem}'
        . 'a.peligro{background:#b3261e}</style></head><body>';
    echo '<h1>' . htmlspecialchars($titulo) . '</h1><pre>';
}

function linea(string $texto): void
{
    echo (es_cli() ? $texto : htmlspecialchars($texto)) . PHP_EOL;
    if (!es_cli()) {
        @ob_flush();
        flush();
    }
}

function pagina_fin(string $htmlExtra = ''): void
{
    if (es_cli()) {
        return;
    }
    echo '</pre>' . $htmlExtra . '</body></html>';
}

/* ---------- Conexión como administrador ---------- */

function conexion_admin(?string $baseDatos = null): PDO
{
    $dsn = sprintf('mysql:host=%s;port=%d;charset=utf8mb4', DB_HOST, DB_PORT);
    if ($baseDatos !== null) {
        $dsn .= ';dbname=' . $baseDatos;
    }
    return new PDO($dsn, DB_ADMIN_USER, DB_ADMIN_PASS, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
}

/* ---------- Ejecutar archivos .sql ---------- */

/**
 * Divide un script SQL en sentencias sueltas.
 * Respeta textos entre comillas y quita los comentarios (--, # y bloques).
 * No admite DELIMITER (triggers o procedimientos): no usarlo en migraciones.
 *
 * @return string[]
 */
function sql_dividir(string $sql): array
{
    $sentencias = [];
    $actual = '';
    $n = strlen($sql);
    $comilla = null;

    for ($i = 0; $i < $n; $i++) {
        $c = $sql[$i];

        if ($comilla !== null) {
            $actual .= $c;
            if ($c === '\\' && $comilla !== '`' && $i + 1 < $n) {
                $actual .= $sql[++$i];
            } elseif ($c === $comilla) {
                if ($i + 1 < $n && $sql[$i + 1] === $comilla) {
                    $actual .= $sql[++$i];
                } else {
                    $comilla = null;
                }
            }
            continue;
        }

        if ($c === "'" || $c === '"' || $c === '`') {
            $comilla = $c;
            $actual .= $c;
            continue;
        }

        $esComentarioGuiones = $c === '-' && $i + 1 < $n && $sql[$i + 1] === '-'
            && ($i + 2 >= $n || ctype_space($sql[$i + 2]));
        if ($esComentarioGuiones || $c === '#') {
            $fin = strpos($sql, "\n", $i);
            $i = $fin === false ? $n : $fin;
            $actual .= "\n";
            continue;
        }

        if ($c === '/' && $i + 1 < $n && $sql[$i + 1] === '*') {
            $fin = strpos($sql, '*/', $i + 2);
            $i = $fin === false ? $n : $fin + 1;
            $actual .= ' ';
            continue;
        }

        if ($c === ';') {
            if (trim($actual) !== '') {
                $sentencias[] = trim($actual);
            }
            $actual = '';
            continue;
        }

        $actual .= $c;
    }

    if (trim($actual) !== '') {
        $sentencias[] = trim($actual);
    }
    return $sentencias;
}

/** Ejecuta un archivo .sql completo. Devuelve el número de sentencias ejecutadas. */
function ejecutar_archivo_sql(PDO $pdo, string $ruta): int
{
    $sql = file_get_contents($ruta);
    if ($sql === false) {
        throw new RuntimeException("No se puede leer {$ruta}");
    }
    $sentencias = sql_dividir($sql);
    foreach ($sentencias as $num => $sentencia) {
        try {
            $pdo->exec($sentencia);
        } catch (PDOException $ex) {
            $inicio = mb_substr(preg_replace('/\s+/', ' ', $sentencia), 0, 120);
            throw new RuntimeException(
                'Error en la sentencia ' . ($num + 1) . ' de ' . basename($ruta) . ': '
                . $ex->getMessage() . "\n   SQL: {$inicio}...",
                0,
                $ex
            );
        }
    }
    return count($sentencias);
}

/* ---------- Migraciones ---------- */

function crear_tabla_migraciones(PDO $pdo): void
{
    $pdo->exec('CREATE TABLE IF NOT EXISTS `' . TABLA_MIGRACIONES . '` (
        archivo     VARCHAR(150) NOT NULL PRIMARY KEY,
        aplicada_en DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB COMMENT=\'Control de migraciones aplicadas (database/migrar.php)\'');
}

/** @return string[] Nombres de archivo de migración, ordenados. */
function migraciones_disponibles(): array
{
    $archivos = glob(CARPETA_MIGRACIONES . '/*.sql') ?: [];
    $nombres = array_map('basename', $archivos);
    sort($nombres, SORT_STRING);
    return $nombres;
}

/** Aplica las migraciones que falten. Devuelve la lista de las aplicadas ahora. */
function aplicar_migraciones(PDO $pdo): array
{
    crear_tabla_migraciones($pdo);
    $hechas = $pdo->query('SELECT archivo FROM `' . TABLA_MIGRACIONES . '`')->fetchAll(PDO::FETCH_COLUMN);
    $hechas = array_flip($hechas);
    $aplicadas = [];

    foreach (migraciones_disponibles() as $archivo) {
        if (isset($hechas[$archivo])) {
            continue;
        }
        linea("-> Aplicando {$archivo} ...");
        $n = ejecutar_archivo_sql($pdo, CARPETA_MIGRACIONES . '/' . $archivo);
        $stmt = $pdo->prepare('INSERT INTO `' . TABLA_MIGRACIONES . '` (archivo) VALUES (?)');
        $stmt->execute([$archivo]);
        linea("   OK ({$n} sentencias)");
        $aplicadas[] = $archivo;
    }
    return $aplicadas;
}

/* ---------- Usuario de la aplicación ---------- */

/** Crea el usuario de la web (si no existe), le pone la contraseña de config.php y le da permisos. */
function sincronizar_usuario_app(PDO $pdo): void
{
    if (!preg_match('/^[A-Za-z0-9_]{1,32}$/', DB_USER)) {
        throw new RuntimeException('DB_USER solo puede tener letras, números y guion bajo.');
    }
    if (DB_USER === DB_ADMIN_USER) {
        linea('   (DB_USER es el mismo que DB_ADMIN_USER: no se toca el usuario)');
        return;
    }
    $clave = $pdo->quote(DB_PASS);
    foreach (['localhost', '127.0.0.1'] as $host) {
        $cuenta = "'" . DB_USER . "'@'{$host}'";
        $pdo->exec("CREATE USER IF NOT EXISTS {$cuenta} IDENTIFIED BY {$clave}");
        $pdo->exec("ALTER USER {$cuenta} IDENTIFIED BY {$clave}");
        $pdo->exec('GRANT SELECT, INSERT, UPDATE, DELETE ON `' . DB_NAME . "`.* TO {$cuenta}");
    }
    $pdo->exec('FLUSH PRIVILEGES');
}

/** Mensaje de error legible cuando no se puede conectar como administrador. */
function explicar_error_conexion(PDOException $ex): string
{
    $msg = $ex->getMessage();
    if (str_contains($msg, '2002') || str_contains($msg, 'refused')) {
        return 'No se puede conectar con la BD. ¿Está MySQL arrancado en el panel de XAMPP?';
    }
    if (str_contains($msg, '1045')) {
        return 'Usuario o contraseña de administrador incorrectos. Revisa DB_ADMIN_USER y DB_ADMIN_PASS en config/config.php.';
    }
    return $msg;
}
