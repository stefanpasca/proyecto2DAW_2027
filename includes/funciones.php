<?php
/**
 * Funciones de uso general.
 */

declare(strict_types=1);

/** Escapa texto para imprimirlo en HTML (evita XSS). Úsalo SIEMPRE al mostrar datos. */
function e(?string $texto): string
{
    return htmlspecialchars($texto ?? '', ENT_QUOTES, 'UTF-8');
}

/** Construye una URL del proyecto: url('login.php') -> /proyecto2DAW_2027/login.php */
function url(string $ruta = ''): string
{
    return rtrim(URL_BASE, '/') . '/' . ltrim($ruta, '/');
}

/** Redirige a otra página del proyecto y termina. */
function redirigir(string $ruta): never
{
    header('Location: ' . url($ruta));
    exit;
}

/** Inicia la sesión con opciones seguras (si no estaba iniciada). */
function iniciar_sesion(): void
{
    if (session_status() === PHP_SESSION_NONE) {
        session_start([
            'cookie_httponly' => true,
            'cookie_samesite' => 'Lax',
            'use_strict_mode' => true,
        ]);
    }
}

/* ---------- Protección CSRF para formularios POST ---------- */

/** Devuelve el token CSRF de la sesión (lo crea si no existe). */
function csrf_token(): string
{
    iniciar_sesion();
    if (empty($_SESSION['csrf'])) {
        $_SESSION['csrf'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf'];
}

/** Campo oculto para poner dentro de cada <form method="post">. */
function csrf_campo(): string
{
    return '<input type="hidden" name="csrf" value="' . e(csrf_token()) . '">';
}

/** Comprueba el token al recibir un POST. Si no coincide, corta con error 400. */
function csrf_verificar(): void
{
    $enviado = $_POST['csrf'] ?? '';
    if (!is_string($enviado) || !hash_equals(csrf_token(), $enviado)) {
        http_response_code(400);
        exit('Solicitud no válida. Recarga la página e inténtalo de nuevo.');
    }
}
