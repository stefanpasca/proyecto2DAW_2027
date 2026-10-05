<?php
/**
 * Punto de entrada.
 * TODO (paso 2.5 de la guía): si hay sesión, redirigir al panel según el rol;
 * si no, ir a login.php. De momento lleva a la página de estado.
 */

declare(strict_types=1);

require_once __DIR__ . '/includes/bootstrap.php';

redirigir('estado.php');
