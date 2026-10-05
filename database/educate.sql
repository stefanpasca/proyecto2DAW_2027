-- =====================================================================
--  Educate - Base de datos v2.1
--  Generado a partir de educate_v2.1.dbml (05/10/2026)
--
--  Compatible con:
--    - XAMPP 8.2.x  -> MariaDB 10.4 (aunque el panel diga "MySQL")
--    - MySQL 8.0.16 o superior (para el despliegue con Docker)
--
--  Como usarlo:
--    phpMyAdmin (http://localhost/phpmyadmin) -> pestana "Importar"
--    -> elegir este archivo -> "Importar". Crea la BD "educate" desde cero.
--
--  OJO: borra la base de datos "educate" si ya existe.
-- =====================================================================

DROP DATABASE IF EXISTS educate;
CREATE DATABASE educate
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE educate;

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------
-- USUARIOS Y CONSENTIMIENTO
-- ---------------------------------------------------------------------

CREATE TABLE usuarios (
  id               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  rol              ENUM('nino','padre','profesor','admin') NOT NULL,
  usuario          VARCHAR(50)  NOT NULL COMMENT 'Nombre de acceso. Ninos: sin datos reales (ej. LeonAzul42)',
  alias            VARCHAR(50)  NOT NULL COMMENT 'Nombre publico en el ranking',
  nombre           VARCHAR(100) NULL     COMMENT 'Adultos: nombre real. Ninos: opcional, de pila o ficticio',
  email            VARCHAR(150) NULL     COMMENT 'Obligatorio salvo para ninos',
  password_hash    VARCHAR(255) NOT NULL COMMENT 'password_hash() de PHP',
  avatar           VARCHAR(50)  NULL     COMMENT 'Id de avatar de la galeria propia. Nunca fotos',
  anio_nacimiento  SMALLINT UNSIGNED NULL COMMENT 'Solo el anio',
  creado_por       INT UNSIGNED NULL     COMMENT 'Adulto que dio de alta la cuenta',
  activo           TINYINT(1)   NOT NULL DEFAULT 0 COMMENT 'Ninos: tras consentimiento. Adultos: al verificar email',
  fecha_alta       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_usuarios_usuario (usuario),
  UNIQUE KEY uq_usuarios_email (email),
  KEY ix_usuarios_creado_por (creado_por),
  CONSTRAINT chk_usuarios_email_adultos CHECK (rol = 'nino' OR email IS NOT NULL),
  CONSTRAINT fk_usuarios_creado_por FOREIGN KEY (creado_por)
    REFERENCES usuarios (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE consentimientos (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  padre_id       INT UNSIGNED NOT NULL,
  nino_id        INT UNSIGNED NOT NULL,
  tipo           ENUM('registro','apoyo','ranking') NOT NULL,
  version_texto  VARCHAR(20)  NOT NULL COMMENT 'Version del texto legal aceptado',
  fecha          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  revocado_en    DATETIME     NULL     COMMENT 'NULL si sigue vigente',
  PRIMARY KEY (id),
  KEY ix_consentimientos_nino_tipo (nino_id, tipo),
  KEY ix_consentimientos_padre (padre_id),
  CONSTRAINT fk_consentimientos_padre FOREIGN KEY (padre_id)
    REFERENCES usuarios (id) ON DELETE CASCADE,
  CONSTRAINT fk_consentimientos_nino FOREIGN KEY (nino_id)
    REFERENCES usuarios (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE perfiles_nino (
  usuario_id           INT UNSIGNED NOT NULL,
  curso                VARCHAR(50)  NULL,
  nivel                VARCHAR(50)  NULL,
  preferencias_apoyo   JSON         NULL COMMENT 'Solo preferencias de uso. Nunca un diagnostico',
  visible_en_ranking   TINYINT(1)   NOT NULL DEFAULT 0,
  PRIMARY KEY (usuario_id),
  CONSTRAINT fk_perfiles_nino_usuario FOREIGN KEY (usuario_id)
    REFERENCES usuarios (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE vinculos_familiares (
  padre_id  INT UNSIGNED NOT NULL,
  nino_id   INT UNSIGNED NOT NULL,
  PRIMARY KEY (padre_id, nino_id),
  KEY ix_vinculos_nino (nino_id),
  CONSTRAINT fk_vinculos_padre FOREIGN KEY (padre_id)
    REFERENCES usuarios (id) ON DELETE CASCADE,
  CONSTRAINT fk_vinculos_nino FOREIGN KEY (nino_id)
    REFERENCES usuarios (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- CLASES Y TAREAS
-- ---------------------------------------------------------------------

CREATE TABLE clases (
  id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre       VARCHAR(100) NOT NULL,
  profesor_id  INT UNSIGNED NOT NULL,
  PRIMARY KEY (id),
  KEY ix_clases_profesor (profesor_id),
  CONSTRAINT fk_clases_profesor FOREIGN KEY (profesor_id)
    REFERENCES usuarios (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE matriculas (
  clase_id  INT UNSIGNED NOT NULL,
  nino_id   INT UNSIGNED NOT NULL,
  PRIMARY KEY (clase_id, nino_id),
  KEY ix_matriculas_nino (nino_id),
  CONSTRAINT fk_matriculas_clase FOREIGN KEY (clase_id)
    REFERENCES clases (id) ON DELETE CASCADE,
  CONSTRAINT fk_matriculas_nino FOREIGN KEY (nino_id)
    REFERENCES usuarios (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE tareas (
  id              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  clase_id        INT UNSIGNED NOT NULL,
  titulo          VARCHAR(150) NOT NULL,
  descripcion     TEXT         NULL,
  fecha_creacion  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_limite    DATE         NULL,
  puntos          INT          NOT NULL DEFAULT 10,
  PRIMARY KEY (id),
  KEY ix_tareas_clase (clase_id),
  CONSTRAINT chk_tareas_puntos CHECK (puntos >= 0),
  CONSTRAINT fk_tareas_clase FOREIGN KEY (clase_id)
    REFERENCES clases (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE entregas (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tarea_id       INT UNSIGNED NOT NULL,
  nino_id        INT UNSIGNED NOT NULL,
  estado         ENUM('pendiente','entregada','revisada') NOT NULL DEFAULT 'pendiente',
  fecha_entrega  DATETIME     NULL,
  contenido      TEXT         NULL,
  nota           DECIMAL(4,2) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_entregas_tarea_nino (tarea_id, nino_id),
  KEY ix_entregas_nino (nino_id),
  CONSTRAINT chk_entregas_nota CHECK (nota IS NULL OR (nota >= 0 AND nota <= 10)),
  CONSTRAINT fk_entregas_tarea FOREIGN KEY (tarea_id)
    REFERENCES tareas (id) ON DELETE CASCADE,
  CONSTRAINT fk_entregas_nino FOREIGN KEY (nino_id)
    REFERENCES usuarios (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- CONTROL PARENTAL Y CATALOGO
-- ---------------------------------------------------------------------

CREATE TABLE reglas_control (
  nino_id             INT UNSIGNED NOT NULL,
  estudio_primero     TINYINT(1)   NOT NULL DEFAULT 1,
  minutos_diarios     INT          NULL,
  hora_inicio         TIME         NULL,
  hora_fin            TIME         NULL,
  edad_contenido_max  INT          NULL COMMENT 'Si es NULL se usa la edad real',
  PRIMARY KEY (nino_id),
  CONSTRAINT chk_reglas_minutos CHECK (minutos_diarios IS NULL OR minutos_diarios >= 0),
  CONSTRAINT fk_reglas_nino FOREIGN KEY (nino_id)
    REFERENCES usuarios (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE catalogo (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tipo          ENUM('video','juego') NOT NULL,
  titulo        VARCHAR(150) NOT NULL,
  url_o_ruta    VARCHAR(255) NULL,
  edad_minima   INT          NULL,
  categoria     VARCHAR(50)  NULL,
  aprobado_por  INT UNSIGNED NULL,
  PRIMARY KEY (id),
  KEY ix_catalogo_aprobado_por (aprobado_por),
  CONSTRAINT fk_catalogo_aprobado_por FOREIGN KEY (aprobado_por)
    REFERENCES usuarios (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE sesiones_uso (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nino_id     INT UNSIGNED NOT NULL,
  recurso_id  INT UNSIGNED NOT NULL,
  inicio      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fin         DATETIME     NULL,
  PRIMARY KEY (id),
  KEY ix_sesiones_nino_inicio (nino_id, inicio),
  KEY ix_sesiones_recurso (recurso_id),
  CONSTRAINT fk_sesiones_nino FOREIGN KEY (nino_id)
    REFERENCES usuarios (id) ON DELETE CASCADE,
  CONSTRAINT fk_sesiones_recurso FOREIGN KEY (recurso_id)
    REFERENCES catalogo (id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Borrar o anonimizar registros antiguos (ej. tras 12 meses)';

-- ---------------------------------------------------------------------
-- SCOREBOARD Y AVISOS
-- ---------------------------------------------------------------------

CREATE TABLE puntuaciones (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nino_id        INT UNSIGNED NOT NULL,
  origen         ENUM('tarea','juego','racha','bonus') NOT NULL,
  referencia_id  INT UNSIGNED NULL COMMENT 'Id de entrega (tarea) o de catalogo (juego). Sin FK: polimorfica',
  motivo         VARCHAR(100) NULL,
  puntos         INT          NOT NULL,
  fecha          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_puntuaciones_nino_fecha (nino_id, fecha),
  CONSTRAINT fk_puntuaciones_nino FOREIGN KEY (nino_id)
    REFERENCES usuarios (id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Los puntos los calcula siempre el servidor';

CREATE TABLE notificaciones (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id  INT UNSIGNED NOT NULL,
  tipo        VARCHAR(30)  NULL,
  mensaje     VARCHAR(255) NULL,
  leida       TINYINT(1)   NOT NULL DEFAULT 0,
  fecha       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_notificaciones_usuario (usuario_id, leida),
  CONSTRAINT fk_notificaciones_usuario FOREIGN KEY (usuario_id)
    REFERENCES usuarios (id) ON DELETE CASCADE
) ENGINE=InnoDB;


-- =====================================================================
--  DATOS DE PRUEBA (solo para desarrollo, nunca en produccion)
--
--  Adultos -> contrasena: Educate2026!
--  Ninos   -> PIN:        1234
-- =====================================================================

INSERT INTO usuarios (id, rol, usuario, alias, nombre, email, password_hash, avatar, anio_nacimiento, creado_por, activo) VALUES
 (1, 'admin',    'admin',        'Admin',        'Administrador', 'admin@educate.test',   '$2y$10$iX50zdemKmQ1ykvD.qa7GegihWqVTEz.SZcHx92oZqrLRGD1qAc6u', NULL,      NULL, NULL, 1),
 (2, 'padre',    'laura.padre',  'Laura',        'Laura Martin',  'laura@educate.test',   '$2y$10$iX50zdemKmQ1ykvD.qa7GegihWqVTEz.SZcHx92oZqrLRGD1qAc6u', NULL,      NULL, NULL, 1),
 (3, 'profesor', 'profe.ruiz',   'Profe Ruiz',   'Carmen Ruiz',   'cruiz@educate.test',   '$2y$10$iX50zdemKmQ1ykvD.qa7GegihWqVTEz.SZcHx92oZqrLRGD1qAc6u', NULL,      NULL, NULL, 1),
 (4, 'nino',     'LeonAzul42',   'LeonAzul',     'Leo',           NULL,                   '$2y$10$CgLMwDb3.ju8ZtCaBW9cFeieQYbJiFagji3Oh89oy.wMD7SuNmYZS', 'leon',    2016, 2,    1),
 (5, 'nino',     'GatoVerde7',   'GatoVerde',    NULL,            NULL,                   '$2y$10$CgLMwDb3.ju8ZtCaBW9cFeieQYbJiFagji3Oh89oy.wMD7SuNmYZS', 'gato',    2017, 2,    1),
 (6, 'nino',     'BuhoRojo9',    'BuhoRojo',     NULL,            NULL,                   '$2y$10$CgLMwDb3.ju8ZtCaBW9cFeieQYbJiFagji3Oh89oy.wMD7SuNmYZS', 'buho',    2016, 3,    0);
-- BuhoRojo9 lo dio de alta la profesora y sigue INACTIVO: falta el consentimiento de un padre/tutor.

INSERT INTO perfiles_nino (usuario_id, curso, nivel, preferencias_apoyo, visible_en_ranking) VALUES
 (4, '4 Primaria', 'medio', NULL, 1),
 (5, '3 Primaria', 'inicial', '{"fuente":"legible","modo_foco":true,"animaciones":false}', 0),
 (6, '4 Primaria', 'medio', NULL, 0);

INSERT INTO vinculos_familiares (padre_id, nino_id) VALUES (2, 4), (2, 5);

INSERT INTO consentimientos (padre_id, nino_id, tipo, version_texto) VALUES
 (2, 4, 'registro', 'v1.0'),
 (2, 4, 'ranking',  'v1.0'),
 (2, 5, 'registro', 'v1.0'),
 (2, 5, 'apoyo',    'v1.0');

INSERT INTO reglas_control (nino_id, estudio_primero, minutos_diarios, hora_inicio, hora_fin, edad_contenido_max) VALUES
 (4, 1, 60, '17:00:00', '20:30:00', NULL),
 (5, 1, 45, '17:00:00', '20:00:00', 8);

INSERT INTO clases (id, nombre, profesor_id) VALUES (1, '4A Primaria - Matematicas', 3);

INSERT INTO matriculas (clase_id, nino_id) VALUES (1, 4), (1, 5), (1, 6);

INSERT INTO tareas (id, clase_id, titulo, descripcion, fecha_limite, puntos) VALUES
 (1, 1, 'Tablas de multiplicar del 7', 'Escribe la tabla del 7 completa.',            CURDATE() - INTERVAL 2 DAY, 10),
 (2, 1, 'Problemas de fracciones',     'Resuelve los 5 problemas de la pagina 34.',   CURDATE() + INTERVAL 1 DAY, 15),
 (3, 1, 'Lectura: El pequeno robot',   'Lee el cuento y escribe dos frases sobre el.', CURDATE() + INTERVAL 5 DAY, 10);

-- Ejemplos de entrega: una revisada con nota, una entregada sin revisar y una pendiente
INSERT INTO entregas (id, tarea_id, nino_id, estado, fecha_entrega, contenido, nota) VALUES
 (1, 1, 4, 'revisada',  NOW() - INTERVAL 3 DAY, '7x1=7, 7x2=14, 7x3=21, ... 7x10=70', 9.00),
 (2, 2, 4, 'entregada', NOW() - INTERVAL 1 HOUR, 'Problema 1: 3/4 ...',               NULL),
 (3, 1, 5, 'pendiente', NULL,                     NULL,                                NULL);

-- Puntos por la entrega revisada (los calcula el servidor al corregir)
INSERT INTO puntuaciones (nino_id, origen, referencia_id, motivo, puntos, fecha) VALUES
 (4, 'tarea', 1, 'Tarea revisada: Tablas de multiplicar del 7', 10, NOW() - INTERVAL 2 DAY);

INSERT INTO catalogo (tipo, titulo, url_o_ruta, edad_minima, categoria, aprobado_por) VALUES
 ('video', 'Las fracciones explicadas', 'https://www.youtube-nocookie.com/embed/VIDEO_ID', 7, 'matematicas', 1),
 ('video', 'El ciclo del agua',          'https://www.youtube-nocookie.com/embed/VIDEO_ID', 6, 'ciencias',    1),
 ('juego', 'Memoria de animales',        'juegos/memoria/index.html',                       5, 'logica',      1);

INSERT INTO notificaciones (usuario_id, tipo, mensaje) VALUES
 (2, 'entrega', 'LeonAzul ha entregado "Problemas de fracciones".'),
 (3, 'entrega', 'LeonAzul ha entregado "Problemas de fracciones".');


-- =====================================================================
--  CONSULTAS DE COMPROBACION (opcional: copiar en la pestana SQL)
-- =====================================================================
-- SELECT rol, COUNT(*) FROM usuarios GROUP BY rol;
-- SELECT u.alias, t.titulo, e.estado, e.nota
--   FROM entregas e JOIN usuarios u ON u.id = e.nino_id JOIN tareas t ON t.id = e.tarea_id;
-- Debe FALLAR (adulto sin email -> salta el CHECK):
-- INSERT INTO usuarios (rol, usuario, alias, password_hash) VALUES ('padre','sinmail','x','x');
