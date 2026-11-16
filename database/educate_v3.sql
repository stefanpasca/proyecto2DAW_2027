-- =====================================================================
--  Educate - Base de datos v3 (classroom + actividades + puntos + tienda)
--  Generado a partir de educate_v3.dbml
--
--  Compatible con:
--    - MariaDB 10.4 o superior
--    - MySQL 8.0.16 o superior (por los CHECK)
--
--  Como usarlo:
--    php database/reset.php      (recrea la BD con este archivo)
--    o bien phpMyAdmin / HeidiSQL -> importar este archivo.
--
--  OJO: borra la base de datos "educate" si ya existe.
--
--  Cambios respecto a v2.1:
--    - Roles: alumno, profesor, admin (desaparece padre).
--    - Eliminadas: vinculos_familiares, reglas_control, catalogo, sesiones_uso.
--    - perfiles_nino -> perfiles_alumno. nino_id -> alumno_id.
--    - Nuevas: actividades, preguntas, opciones, intentos, respuestas,
--              recompensas, canjes.
--    - puntuaciones: referencia_id polimorfica -> intento_id (FK real).
--
--  Reglas que NO se pueden poner en la BD y debe comprobar el servidor PHP:
--    1) Que clases.profesor_id sea un usuario con rol profesor y que todos los
--       alumno_id sean usuarios con rol alumno (una FK solo comprueba que existe).
--    2) Un alumno sin email debe tener creado_por (lo dio de alta un profesor).
--    3) Solo el primer intento completo de una actividad da puntos
--       (intentos.cuenta_para_puntos) y se respeta el tope diario.
--    4) recompensas.tarea_id es obligatorio si tipo = 'bonus_nota'.
--    5) Un canje comprueba saldo y stock dentro de una transaccion.
--    6) bonus_aplicado nunca supera tareas.bonus_max.
--
--  Este archivo solo usa sentencias simples (sin DELIMITER, triggers ni
--  procedimientos): el divisor de SQL de herramientas.php no los soporta.
-- =====================================================================

DROP DATABASE IF EXISTS educate;
CREATE DATABASE educate
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE educate;

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------
-- PERSONAS Y CONSENTIMIENTO
-- ---------------------------------------------------------------------

CREATE TABLE usuarios (
  id               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  rol              ENUM('alumno','profesor','admin') NOT NULL,
  usuario          VARCHAR(50)  NOT NULL COMMENT 'Nombre de acceso. Menores: sin datos reales (ej. LeonAzul42)',
  alias            VARCHAR(50)  NOT NULL COMMENT 'Nombre publico en el ranking. Nunca el nombre real',
  nombre           VARCHAR(100) NULL     COMMENT 'Adultos: nombre real. Menores: opcional, de pila o ficticio',
  email            VARCHAR(150) NULL     COMMENT 'Obligatorio salvo para alumnos',
  password_hash    VARCHAR(255) NOT NULL COMMENT 'password_hash() de PHP. Menores: PIN creado por el profesor',
  anio_nacimiento  SMALLINT UNSIGNED NULL COMMENT 'Solo el anio. Decide si es menor de 14',
  creado_por       INT UNSIGNED NULL     COMMENT 'Profesor que dio de alta al alumno menor. NULL si se registro solo',
  activo           TINYINT(1)   NOT NULL DEFAULT 0 COMMENT 'Menores: se activa al registrar el consentimiento',
  fecha_alta       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_usuarios_usuario (usuario),
  UNIQUE KEY uq_usuarios_email (email),
  KEY ix_usuarios_creado_por (creado_por),
  CONSTRAINT chk_usuarios_email_no_alumnos CHECK (rol = 'alumno' OR email IS NOT NULL),
  CONSTRAINT fk_usuarios_creado_por FOREIGN KEY (creado_por)
    REFERENCES usuarios (id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE consentimientos (
  id              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  alumno_id       INT UNSIGNED NOT NULL,
  registrado_por  INT UNSIGNED NULL     COMMENT 'Profesor que confirmo la autorizacion. SET NULL si se borra',
  tipo            ENUM('registro','apoyo') NOT NULL,
  version_texto   VARCHAR(20)  NOT NULL COMMENT 'Version del texto legal aceptado',
  fecha           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  revocado_en     DATETIME     NULL     COMMENT 'NULL si sigue vigente',
  PRIMARY KEY (id),
  KEY ix_consentimientos_alumno_tipo (alumno_id, tipo),
  KEY ix_consentimientos_registrado_por (registrado_por),
  CONSTRAINT fk_consentimientos_alumno FOREIGN KEY (alumno_id)
    REFERENCES usuarios (id) ON DELETE CASCADE,
  CONSTRAINT fk_consentimientos_registrado_por FOREIGN KEY (registrado_por)
    REFERENCES usuarios (id) ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Solo para alumnos menores de 14: prueba de que existe autorizacion';

CREATE TABLE perfiles_alumno (
  usuario_id          INT UNSIGNED NOT NULL,
  curso               VARCHAR(50)  NULL,
  preferencias_apoyo  JSON         NULL COMMENT 'Solo preferencias de uso. Nunca un diagnostico',
  PRIMARY KEY (usuario_id),
  CONSTRAINT fk_perfiles_alumno_usuario FOREIGN KEY (usuario_id)
    REFERENCES usuarios (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- CLASSROOM: CLASES, TAREAS Y ENTREGAS
-- ---------------------------------------------------------------------

CREATE TABLE clases (
  id              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre          VARCHAR(100) NOT NULL,
  profesor_id     INT UNSIGNED NOT NULL,
  codigo_acceso   VARCHAR(10)  NOT NULL COMMENT 'Codigo para que el alumno se una a la clase',
  fecha_creacion  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_clases_codigo (codigo_acceso),
  KEY ix_clases_profesor (profesor_id),
  CONSTRAINT fk_clases_profesor FOREIGN KEY (profesor_id)
    REFERENCES usuarios (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE matriculas (
  clase_id   INT UNSIGNED NOT NULL,
  alumno_id  INT UNSIGNED NOT NULL,
  fecha      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (clase_id, alumno_id),
  KEY ix_matriculas_alumno (alumno_id),
  CONSTRAINT fk_matriculas_clase FOREIGN KEY (clase_id)
    REFERENCES clases (id) ON DELETE CASCADE,
  CONSTRAINT fk_matriculas_alumno FOREIGN KEY (alumno_id)
    REFERENCES usuarios (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE tareas (
  id              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  clase_id        INT UNSIGNED NOT NULL,
  titulo          VARCHAR(150) NOT NULL,
  descripcion     TEXT         NULL,
  fecha_creacion  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_limite    DATE         NULL,
  admite_bonus    TINYINT(1)   NOT NULL DEFAULT 0 COMMENT 'El profesor decide si se puede subir nota con puntos',
  bonus_max       DECIMAL(4,2) NOT NULL DEFAULT 0.00 COMMENT 'Tope de bonus (0 a 10). Ej: 0.50',
  PRIMARY KEY (id),
  KEY ix_tareas_clase (clase_id),
  CONSTRAINT chk_tareas_bonus_max CHECK (bonus_max >= 0 AND bonus_max <= 10),
  CONSTRAINT fk_tareas_clase FOREIGN KEY (clase_id)
    REFERENCES clases (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE entregas (
  id              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tarea_id        INT UNSIGNED NOT NULL,
  alumno_id       INT UNSIGNED NOT NULL,
  estado          ENUM('pendiente','entregada','revisada') NOT NULL DEFAULT 'pendiente',
  fecha_entrega   DATETIME     NULL,
  contenido       TEXT         NULL,
  nota            DECIMAL(4,2) NULL COMMENT 'Nota original 0 a 10. Nunca se mezcla con el bonus',
  bonus_aplicado  DECIMAL(4,2) NOT NULL DEFAULT 0.00 COMMENT 'Nota final = LEAST(10, nota + bonus_aplicado)',
  PRIMARY KEY (id),
  UNIQUE KEY uq_entregas_tarea_alumno (tarea_id, alumno_id),
  KEY ix_entregas_alumno (alumno_id),
  CONSTRAINT chk_entregas_nota CHECK (nota IS NULL OR (nota >= 0 AND nota <= 10)),
  CONSTRAINT chk_entregas_bonus CHECK (bonus_aplicado >= 0 AND bonus_aplicado <= 10),
  CONSTRAINT fk_entregas_tarea FOREIGN KEY (tarea_id)
    REFERENCES tareas (id) ON DELETE CASCADE,
  CONSTRAINT fk_entregas_alumno FOREIGN KEY (alumno_id)
    REFERENCES usuarios (id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- ACTIVIDADES (tipo Kahoot y minijuegos)
-- ---------------------------------------------------------------------

CREATE TABLE actividades (
  id              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  clase_id        INT UNSIGNED NOT NULL,
  tipo            ENUM('opcion_multiple','verdadero_falso','ordenar','emparejar','completar_huecos') NOT NULL,
  titulo          VARCHAR(150) NOT NULL,
  descripcion     TEXT         NULL,
  publicada       TINYINT(1)   NOT NULL DEFAULT 0 COMMENT 'Solo las publicadas las ve el alumno',
  fecha_limite    DATE         NULL,
  fecha_creacion  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY ix_actividades_clase_publicada (clase_id, publicada),
  CONSTRAINT fk_actividades_clase FOREIGN KEY (clase_id)
    REFERENCES clases (id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Todas comparten estructura: preguntas + opciones. El tipo decide la pantalla';

CREATE TABLE preguntas (
  id               INT UNSIGNED NOT NULL AUTO_INCREMENT,
  actividad_id     INT UNSIGNED NOT NULL,
  enunciado        TEXT         NOT NULL,
  orden            SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  tiempo_limite_s  SMALLINT UNSIGNED NULL COMMENT 'Segundos. NULL = sin limite (y sin extra por rapidez)',
  config           JSON         NULL COMMENT 'Datos propios de ordenar, emparejar y completar huecos',
  PRIMARY KEY (id),
  UNIQUE KEY uq_preguntas_actividad_orden (actividad_id, orden),
  CONSTRAINT chk_preguntas_tiempo CHECK (tiempo_limite_s IS NULL OR tiempo_limite_s > 0),
  CONSTRAINT fk_preguntas_actividad FOREIGN KEY (actividad_id)
    REFERENCES actividades (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE opciones (
  id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  pregunta_id  INT UNSIGNED NOT NULL,
  texto        VARCHAR(255) NOT NULL,
  es_correcta  TINYINT(1)   NOT NULL DEFAULT 0 COMMENT 'Nunca se envia al navegador mientras se juega',
  orden        SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_opciones_pregunta_orden (pregunta_id, orden),
  CONSTRAINT fk_opciones_pregunta FOREIGN KEY (pregunta_id)
    REFERENCES preguntas (id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Solo opcion multiple y verdadero/falso';

CREATE TABLE intentos (
  id                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  actividad_id        INT UNSIGNED NOT NULL,
  alumno_id           INT UNSIGNED NOT NULL,
  numero_intento      SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  inicio              DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fin                 DATETIME     NULL COMMENT 'NULL = intento sin terminar',
  aciertos            SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  puntos_obtenidos    INT UNSIGNED NOT NULL DEFAULT 0,
  cuenta_para_puntos  TINYINT(1)   NOT NULL DEFAULT 0 COMMENT 'Solo el primer intento completo da puntos',
  PRIMARY KEY (id),
  UNIQUE KEY uq_intentos_actividad_alumno_num (actividad_id, alumno_id, numero_intento),
  KEY ix_intentos_alumno (alumno_id),
  CONSTRAINT chk_intentos_numero CHECK (numero_intento >= 1),
  CONSTRAINT fk_intentos_actividad FOREIGN KEY (actividad_id)
    REFERENCES actividades (id) ON DELETE CASCADE,
  CONSTRAINT fk_intentos_alumno FOREIGN KEY (alumno_id)
    REFERENCES usuarios (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE respuestas (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  intento_id     INT UNSIGNED NOT NULL,
  pregunta_id    INT UNSIGNED NOT NULL,
  respuesta      JSON         NULL COMMENT 'Lo que contesto el alumno (segun el tipo)',
  es_correcta    TINYINT(1)   NOT NULL DEFAULT 0,
  puntos         SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '10 + extra por rapidez (0 a 5) si acierta',
  servida_en     DATETIME(3)  NOT NULL COMMENT 'Hora en que el SERVIDOR envio la pregunta',
  respondida_en  DATETIME(3)  NULL     COMMENT 'Hora en que el SERVIDOR recibio la respuesta',
  PRIMARY KEY (id),
  UNIQUE KEY uq_respuestas_intento_pregunta (intento_id, pregunta_id),
  KEY ix_respuestas_pregunta (pregunta_id),
  CONSTRAINT chk_respuestas_tiempos CHECK (respondida_en IS NULL OR respondida_en >= servida_en),
  CONSTRAINT fk_respuestas_intento FOREIGN KEY (intento_id)
    REFERENCES intentos (id) ON DELETE CASCADE,
  CONSTRAINT fk_respuestas_pregunta FOREIGN KEY (pregunta_id)
    REFERENCES preguntas (id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Permite ver aciertos y fallos por pregunta. El tiempo lo mide siempre el servidor';

-- ---------------------------------------------------------------------
-- PUNTOS Y TIENDA
-- ---------------------------------------------------------------------

CREATE TABLE puntuaciones (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  alumno_id   INT UNSIGNED NOT NULL,
  clase_id    INT UNSIGNED NOT NULL COMMENT 'Los puntos son por clase',
  origen      ENUM('actividad','ajuste') NOT NULL,
  intento_id  INT UNSIGNED NULL COMMENT 'Un intento puntua como mucho una vez. SET NULL si se borra la actividad',
  motivo      VARCHAR(100) NULL,
  puntos      INT          NOT NULL COMMENT 'Siempre >= 0. Solo suman: de aqui sale el ranking',
  fecha       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_puntuaciones_intento (intento_id),
  KEY ix_puntuaciones_clase_alumno (clase_id, alumno_id),
  KEY ix_puntuaciones_alumno_clase_fecha (alumno_id, clase_id, fecha),
  CONSTRAINT chk_puntuaciones_puntos CHECK (puntos >= 0),
  CONSTRAINT fk_puntuaciones_alumno FOREIGN KEY (alumno_id)
    REFERENCES usuarios (id) ON DELETE CASCADE,
  CONSTRAINT fk_puntuaciones_clase FOREIGN KEY (clase_id)
    REFERENCES clases (id) ON DELETE CASCADE,
  CONSTRAINT fk_puntuaciones_intento FOREIGN KEY (intento_id)
    REFERENCES intentos (id) ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Puntos GANADOS. Ranking = suma por alumno y clase. Los calcula siempre el servidor';

CREATE TABLE recompensas (
  id           INT UNSIGNED NOT NULL AUTO_INCREMENT,
  clase_id     INT UNSIGNED NOT NULL,
  nombre       VARCHAR(100) NOT NULL,
  descripcion  VARCHAR(255) NULL,
  coste        INT UNSIGNED NOT NULL,
  tipo         ENUM('privilegio','bonus_nota') NOT NULL,
  tarea_id     INT UNSIGNED NULL COMMENT 'Solo bonus_nota: tarea a la que afecta',
  bonus_nota   DECIMAL(4,2) NULL COMMENT 'Solo bonus_nota: puntos que suma (limitado por tareas.bonus_max)',
  stock        INT UNSIGNED NULL COMMENT 'NULL = ilimitado',
  activa       TINYINT(1)   NOT NULL DEFAULT 1 COMMENT 'Mejor desactivar que borrar',
  PRIMARY KEY (id),
  KEY ix_recompensas_clase_activa (clase_id, activa),
  KEY ix_recompensas_tarea (tarea_id),
  CONSTRAINT chk_recompensas_coste CHECK (coste > 0),
  CONSTRAINT chk_recompensas_tipo CHECK (
    (tipo = 'privilegio' AND bonus_nota IS NULL)
    OR (tipo = 'bonus_nota' AND bonus_nota IS NOT NULL AND bonus_nota > 0)
  ),
  CONSTRAINT fk_recompensas_clase FOREIGN KEY (clase_id)
    REFERENCES clases (id) ON DELETE CASCADE,
  CONSTRAINT fk_recompensas_tarea FOREIGN KEY (tarea_id)
    REFERENCES tareas (id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE canjes (
  id             INT UNSIGNED NOT NULL AUTO_INCREMENT,
  recompensa_id  INT UNSIGNED NOT NULL,
  alumno_id      INT UNSIGNED NOT NULL,
  coste_pagado   INT UNSIGNED NOT NULL COMMENT 'Precio en el momento de comprar',
  estado         ENUM('pendiente','aprobado','rechazado') NOT NULL DEFAULT 'pendiente',
  fecha          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resuelto_en    DATETIME     NULL,
  nota_profesor  VARCHAR(255) NULL,
  PRIMARY KEY (id),
  KEY ix_canjes_alumno_estado (alumno_id, estado),
  KEY ix_canjes_recompensa (recompensa_id),
  CONSTRAINT fk_canjes_recompensa FOREIGN KEY (recompensa_id)
    REFERENCES recompensas (id) ON DELETE CASCADE,
  CONSTRAINT fk_canjes_alumno FOREIGN KEY (alumno_id)
    REFERENCES usuarios (id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Si se rechaza, dejan de contar los puntos gastados';

CREATE TABLE notificaciones (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  usuario_id  INT UNSIGNED NOT NULL,
  tipo        VARCHAR(30)  NULL COMMENT 'tarea_nueva, nota, actividad_nueva, canje_pendiente, canje_resuelto...',
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
--  Adultos y alumnos con email -> contrasena: Educate2026!
--  Alumno menor (LeonAzul42)   -> PIN:        1234
-- =====================================================================

INSERT INTO usuarios (id, rol, usuario, alias, nombre, email, password_hash, anio_nacimiento, creado_por, activo) VALUES
 (1, 'admin',    'admin',       'Admin',      'Administrador', 'admin@educate.test',  '$2y$10$iX50zdemKmQ1ykvD.qa7GegihWqVTEz.SZcHx92oZqrLRGD1qAc6u', NULL, NULL, 1),
 (2, 'profesor', 'profe.ruiz',  'Profe Ruiz', 'Carmen Ruiz',   'cruiz@educate.test',   '$2y$10$iX50zdemKmQ1ykvD.qa7GegihWqVTEz.SZcHx92oZqrLRGD1qAc6u', NULL, NULL, 1),
 (3, 'profesor', 'profe.gomez', 'Profe Gomez','Pablo Gomez',   'pgomez@educate.test',  '$2y$10$iX50zdemKmQ1ykvD.qa7GegihWqVTEz.SZcHx92oZqrLRGD1qAc6u', NULL, NULL, 1),
 (4, 'alumno',   'ana.garcia',  'Ana',        'Ana Garcia',    'ana@educate.test',     '$2y$10$iX50zdemKmQ1ykvD.qa7GegihWqVTEz.SZcHx92oZqrLRGD1qAc6u', 2009, NULL, 1),
 (5, 'alumno',   'marco.lopez', 'Marco',      'Marco Lopez',   'marco@educate.test',   '$2y$10$iX50zdemKmQ1ykvD.qa7GegihWqVTEz.SZcHx92oZqrLRGD1qAc6u', 2010, NULL, 1),
 (6, 'alumno',   'sara.perez',  'Sara',       'Sara Perez',    'sara@educate.test',    '$2y$10$iX50zdemKmQ1ykvD.qa7GegihWqVTEz.SZcHx92oZqrLRGD1qAc6u', 2009, NULL, 1),
 (7, 'alumno',   'LeonAzul42',  'LeonAzul',   'Leo',           NULL,                   '$2y$10$CgLMwDb3.ju8ZtCaBW9cFeieQYbJiFagji3Oh89oy.wMD7SuNmYZS', 2016, 3,    1);
-- LeonAzul42 es menor de 14: lo dio de alta el profesor 3 (creado_por) y tiene consentimiento.

INSERT INTO perfiles_alumno (usuario_id, curso, preferencias_apoyo) VALUES
 (4, '1 Bachillerato', NULL),
 (5, '1 Bachillerato', '{"fuente":"legible","modo_foco":true,"animaciones":false}'),
 (6, '1 Bachillerato', NULL),
 (7, '4 Primaria',     NULL);

INSERT INTO consentimientos (alumno_id, registrado_por, tipo, version_texto) VALUES
 (7, 3, 'registro', 'v1.0');

INSERT INTO clases (id, nombre, profesor_id, codigo_acceso) VALUES
 (1, '1B Bachillerato - Matematicas', 2, 'K7P4QX'),
 (2, '4A Primaria - Lengua',          3, 'LEN4AB');

INSERT INTO matriculas (clase_id, alumno_id) VALUES (1, 4), (1, 5), (1, 6), (2, 7);

INSERT INTO tareas (id, clase_id, titulo, descripcion, fecha_limite, admite_bonus, bonus_max) VALUES
 (1, 1, 'Derivadas: ejercicios 1 a 10', 'Resuelve los diez ejercicios de la pagina 52.', CURDATE() - INTERVAL 2 DAY, 1, 0.50),
 (2, 1, 'Problemas de integrales',      'Resuelve los problemas 3, 4 y 5.',               CURDATE() + INTERVAL 3 DAY, 0, 0.00),
 (3, 2, 'Lectura: El pequeno robot',    'Lee el cuento y escribe dos frases sobre el.',   CURDATE() + INTERVAL 5 DAY, 0, 0.00);

-- Una revisada con nota, una entregada sin revisar y dos pendientes
INSERT INTO entregas (id, tarea_id, alumno_id, estado, fecha_entrega, contenido, nota, bonus_aplicado) VALUES
 (1, 1, 4, 'revisada',  NOW() - INTERVAL 3 DAY, 'f(x)=x^2, derivada: 2x ...', 8.00, 0.00),
 (2, 1, 5, 'entregada', NOW() - INTERVAL 1 DAY, 'Ejercicio 1: 2x ...',        NULL, 0.00),
 (3, 2, 4, 'pendiente', NULL,                   NULL,                          NULL, 0.00),
 (4, 3, 7, 'pendiente', NULL,                   NULL,                          NULL, 0.00);

-- Una actividad de cada tipo (las 4 y 5 son borradores sin publicar)
INSERT INTO actividades (id, clase_id, tipo, titulo, descripcion, publicada) VALUES
 (1, 1, 'opcion_multiple',  'Repaso de derivadas',            'Test rapido de derivadas basicas.', 1),
 (2, 1, 'verdadero_falso',  'Verdadero o falso: limites',     NULL,                                1),
 (3, 1, 'ordenar',          'Ordena la regla de la cadena',   NULL,                                1),
 (4, 1, 'emparejar',        'Funciones y sus derivadas',      NULL,                                0),
 (5, 1, 'completar_huecos', 'Completa las derivadas',         NULL,                                0),
 (6, 2, 'opcion_multiple',  'Comprension: El pequeno robot',  NULL,                                1);

INSERT INTO preguntas (id, actividad_id, enunciado, orden, tiempo_limite_s, config) VALUES
 (1, 1, 'Cual es la derivada de x^2?',                          1, 20, NULL),
 (2, 1, 'Cual es la derivada de sen(x)?',                       2, 20, NULL),
 (3, 2, 'El limite de 1/x cuando x tiende a infinito es 0.',    1, 15, NULL),
 (4, 3, 'Ordena los pasos para derivar (x^2+1)^3.',             1, NULL,
   '{"elementos":["Identificar la funcion externa y la interna","Derivar la funcion externa","Multiplicar por la derivada de la interna","Simplificar"]}'),
 (5, 4, 'Empareja cada funcion con su derivada.',               1, NULL,
   '{"pares":[["x^2","2x"],["sen(x)","cos(x)"],["e^x","e^x"]]}'),
 (6, 5, 'La derivada de x^3 es {1}x^2.',                        1, NULL,
   '{"huecos":[["3","tres"]]}'),
 (7, 6, 'Como se llama el robot del cuento?',                   1, 20, NULL);

INSERT INTO opciones (id, pregunta_id, texto, es_correcta, orden) VALUES
 (1,  1, 'x',      0, 1),
 (2,  1, '2x',     1, 2),
 (3,  1, 'x^2',    0, 3),
 (4,  2, 'cos(x)',  1, 1),
 (5,  2, '-cos(x)', 0, 2),
 (6,  2, 'tan(x)',  0, 3),
 (7,  3, 'Verdadero', 1, 1),
 (8,  3, 'Falso',     0, 2),
 (9,  7, 'Bolt',  1, 1),
 (10, 7, 'Max',   0, 2),
 (11, 7, 'Pixel', 0, 3);

-- Ana (1) y Marco (2) completan la actividad 1; Ana la repite (3) sin puntos
INSERT INTO intentos (id, actividad_id, alumno_id, numero_intento, inicio, fin, aciertos, puntos_obtenidos, cuenta_para_puntos) VALUES
 (1, 1, 4, 1, NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 2 DAY + INTERVAL 40 SECOND, 2, 27, 1),
 (2, 1, 5, 1, NOW() - INTERVAL 1 DAY, NOW() - INTERVAL 1 DAY + INTERVAL 35 SECOND, 1, 12, 1),
 (3, 1, 4, 2, NOW() - INTERVAL 1 HOUR, NOW() - INTERVAL 1 HOUR + INTERVAL 30 SECOND, 2, 0, 0);

INSERT INTO respuestas (intento_id, pregunta_id, respuesta, es_correcta, puntos, servida_en, respondida_en) VALUES
 (1, 1, '{"opcion_id":2}', 1, 14, NOW(3) - INTERVAL 2 DAY,                       NOW(3) - INTERVAL 2 DAY + INTERVAL 6 SECOND),
 (1, 2, '{"opcion_id":4}', 1, 13, NOW(3) - INTERVAL 2 DAY + INTERVAL 10 SECOND,  NOW(3) - INTERVAL 2 DAY + INTERVAL 18 SECOND),
 (2, 1, '{"opcion_id":2}', 1, 12, NOW(3) - INTERVAL 1 DAY,                       NOW(3) - INTERVAL 1 DAY + INTERVAL 9 SECOND),
 (2, 2, '{"opcion_id":5}', 0, 0,  NOW(3) - INTERVAL 1 DAY + INTERVAL 12 SECOND,  NOW(3) - INTERVAL 1 DAY + INTERVAL 20 SECOND),
 (3, 1, '{"opcion_id":2}', 1, 0,  NOW(3) - INTERVAL 1 HOUR,                      NOW(3) - INTERVAL 1 HOUR + INTERVAL 5 SECOND),
 (3, 2, '{"opcion_id":4}', 1, 0,  NOW(3) - INTERVAL 1 HOUR + INTERVAL 8 SECOND,  NOW(3) - INTERVAL 1 HOUR + INTERVAL 15 SECOND);

-- Puntos: los intentos 1 y 2 (el 3 no cuenta) y 20 puntos manuales para Sara
INSERT INTO puntuaciones (alumno_id, clase_id, origen, intento_id, motivo, puntos, fecha) VALUES
 (4, 1, 'actividad', 1,    'Repaso de derivadas',      27, NOW() - INTERVAL 2 DAY),
 (5, 1, 'actividad', 2,    'Repaso de derivadas',      12, NOW() - INTERVAL 1 DAY),
 (6, 1, 'ajuste',    NULL, 'Participacion en clase',   20, NOW() - INTERVAL 1 DAY);

INSERT INTO recompensas (id, clase_id, nombre, descripcion, coste, tipo, tarea_id, bonus_nota, stock, activa) VALUES
 (1, 1, 'Entregar un dia mas tarde', 'Un dia extra en una tarea a elegir.',   25, 'privilegio', NULL, NULL, 5,    1),
 (2, 1, 'Elegir sitio en clase',     'Elige tu sitio durante una semana.',    15, 'privilegio', NULL, NULL, NULL, 1),
 (3, 1, 'Bonus +0,5 en Derivadas',   'Suma 0,5 a la nota de la tarea 1.',     40, 'bonus_nota', 1,    0.50, NULL, 1);

-- Saldo: Ana 27-15 = 12 (canje aprobado). Sara 20-15 = 5 (canje pendiente cuenta como gastado)
INSERT INTO canjes (recompensa_id, alumno_id, coste_pagado, estado, resuelto_en, nota_profesor) VALUES
 (2, 4, 15, 'aprobado',  NOW() - INTERVAL 1 HOUR, 'Vale, sitio junto a la ventana.'),
 (2, 6, 15, 'pendiente', NULL,                    NULL);

INSERT INTO notificaciones (usuario_id, tipo, mensaje) VALUES
 (2, 'canje_pendiente', 'Sara ha canjeado "Elegir sitio en clase".'),
 (4, 'canje_resuelto',  'Tu canje "Elegir sitio en clase" ha sido aprobado.'),
 (5, 'actividad_nueva', 'Nueva actividad: "Ordena la regla de la cadena".');


-- =====================================================================
--  CONSULTAS DE COMPROBACION (opcional: copiar en la pestana SQL)
-- =====================================================================
-- Ranking de la clase 1 (puntos GANADOS):
--   SELECT u.alias, SUM(p.puntos) AS puntos
--     FROM puntuaciones p JOIN usuarios u ON u.id = p.alumno_id
--    WHERE p.clase_id = 1 GROUP BY u.id, u.alias ORDER BY puntos DESC;
--
-- Saldo disponible de un alumno en una clase (ganados - canjes pendientes y aprobados):
--   SELECT
--     (SELECT COALESCE(SUM(puntos), 0) FROM puntuaciones WHERE alumno_id = 4 AND clase_id = 1)
--     - (SELECT COALESCE(SUM(c.coste_pagado), 0) FROM canjes c
--          JOIN recompensas r ON r.id = c.recompensa_id
--         WHERE c.alumno_id = 4 AND r.clase_id = 1 AND c.estado IN ('pendiente','aprobado'))
--     AS saldo;
--
-- Puntos ganados hoy (para el tope diario):
--   SELECT COALESCE(SUM(puntos), 0) FROM puntuaciones
--    WHERE alumno_id = 4 AND clase_id = 1 AND fecha >= CURDATE();
--
-- Nota final de una entrega:
--   SELECT nota, bonus_aplicado, LEAST(10, nota + bonus_aplicado) AS nota_final FROM entregas WHERE id = 1;
--
-- Resultados por pregunta de una actividad:
--   SELECT p.enunciado, COUNT(*) AS respuestas, SUM(r.es_correcta) AS aciertos
--     FROM respuestas r JOIN preguntas p ON p.id = r.pregunta_id
--    WHERE p.actividad_id = 1 GROUP BY p.id, p.enunciado;
--
-- Debe FALLAR (profesor sin email -> salta el CHECK):
--   INSERT INTO usuarios (rol, usuario, alias, password_hash) VALUES ('profesor','sinmail','x','x');
-- Debe FALLAR (nota fuera de rango):
--   UPDATE entregas SET nota = 11 WHERE id = 1;
-- Debe FALLAR (dos entregas de la misma tarea y alumno):
--   INSERT INTO entregas (tarea_id, alumno_id) VALUES (1, 4);
