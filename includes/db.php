<?php
/**
 * Conexión a la base de datos con PDO.
 *
 * Uso:  $stmt = db()->prepare('SELECT * FROM usuarios WHERE usuario = ?');
 *       $stmt->execute([$usuario]);
 *       $fila = $stmt->fetch();
 *
 * REGLA DEL PROYECTO: siempre prepare() + execute() con parámetros.
 * Nunca concatenar datos del usuario dentro del SQL.
 */

declare(strict_types=1);

function db(): PDO
{
    static $pdo = null;

    if ($pdo === null) {
        $dsn = sprintf('mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4', DB_HOST, DB_PORT, DB_NAME);
        $pdo = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]);
    }

    return $pdo;
}
