<?php
/**
 * PLANTILLA DE CONFIGURACIÓN
 *
 * 1. Copia este archivo en la misma carpeta con el nombre config.php
 * 2. Cambia DB_PASS por la contraseña que quieras para el usuario educate_app
 * 3. Abre http://localhost/proyecto2DAW_2027/database/reset.php
 *    (crea la BD y deja el usuario educate_app con esta contraseña)
 *
 * config.php está en el .gitignore: cada uno tiene el suyo y NUNCA se sube a GitHub.
 */

// 'desarrollo' muestra errores y permite usar database/reset.php y migrar.php.
// En el servidor de despliegue se pondrá 'produccion'.
define('ENTORNO', 'desarrollo');

// Ruta del proyecto dentro de htdocs (para construir enlaces)
define('URL_BASE', '/proyecto2DAW_2027');

// Conexión a la base de datos (XAMPP: MariaDB en el puerto 3306)
define('DB_HOST', '127.0.0.1');
define('DB_PORT', 3306);
define('DB_NAME', 'educate');   // No cambiar: educate.sql crea la BD con este nombre

// Usuario que usa la web. Solo tiene permisos SELECT, INSERT, UPDATE y DELETE.
define('DB_USER', 'educate_app');
define('DB_PASS', 'cambia_esta_clave');

// Usuario administrador. Solo lo usan database/reset.php y database/migrar.php
// para crear tablas y aplicar cambios. En XAMPP por defecto: root sin contraseña.
define('DB_ADMIN_USER', 'root');
define('DB_ADMIN_PASS', '');
