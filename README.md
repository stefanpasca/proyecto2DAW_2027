# Educate

Plataforma web que convierte el control parental en una herramienta de aprendizaje. Los niños gestionan y entregan sus tareas y, solo cuando las cumplen, acceden a vídeos y juegos aprobados. Padres, tutores y profesores siguen su progreso mediante informes.

Proyecto del módulo de Proyecto de 2º DAW · CPIFP Los Enlaces.

| | |
|---|---|
| **Equipo** | Hugo, David Ultray Stefan Pasca |
| **Tutor** | Oscar Ariño |

## Funcionalidades principales

- **Gestión de tareas**: el profesor crea tareas por clase y el niño las entrega.
- **Control parental orientado al estudio**: "estudio primero", tiempo diario, horario permitido y filtro por edad. Las reglas se comprueban siempre en el servidor.
- **Catálogo propio** de vídeos y juegos aprobados (la web no puede bloquear apps ni webs externas).
- **Informes de progreso** para padres y profesores.
- **Scoreboard** *(segunda fase)*: puntos calculados por el servidor, rankings por clase con alias y solo con permiso de los padres.
- **Modo de apoyo** *(segunda fase)*: tipografía legible, lectura en voz alta, modo foco y menos animaciones para niños con TDAH, dislexia u otras necesidades. Nunca se guarda un diagnóstico.

## Roles

`niño` · `padre/tutor` · `profesor` · `admin`

Los niños **no se registran**: los da de alta un adulto con datos mínimos, y la cuenta queda inactiva hasta que hay consentimiento parental.

## Tecnologías

| Parte | Tecnología |
|---|---|
| Entorno local recomendado | **Laragon** con Apache, PHP 8.2 o superior y MySQL/MariaDB |
| Backend | PHP puro + PDO (sin framework), sesiones de PHP |
| Base de datos | MariaDB o MySQL compatible con el esquema SQL del proyecto |
| Frontend | HTML, CSS y JavaScript con vistas en PHP |
| Editor | Visual Studio Code (configuración común en `.vscode/`) |
| Control de versiones | Git + GitHub |

## Puesta en marcha con Laragon (primera vez)

### 1. Inicia los servicios

1. Instala Laragon.
2. Abre Laragon y pulsa **Start All** para iniciar Apache y MySQL/MariaDB.
3. En el menú de Laragon, comprueba qué versión de PHP y de MySQL/MariaDB está activa. Se recomienda PHP 8.2 o superior y la extensión `pdo_mysql` habilitada.

### 2. Coloca el proyecto

Extrae la carpeta `proyecto2DAW_2027` en:

```text
C:\laragon\www\proyecto2DAW_2027
```

Comprueba que `index.php` está directamente dentro de `proyecto2DAW_2027`, y no en una carpeta duplicada.

La configuración incluida está preparada para abrir el proyecto en:

```text
http://localhost/proyecto2DAW_2027/
```

Si prefieres usar el virtual host automático de Laragon (por ejemplo, `http://proyecto2daw_2027.test/`), cambia `URL_BASE` en `config/config.php` a una cadena vacía (`''`). Para la configuración inicial, usa la URL de `localhost` indicada arriba.

### 3. Revisa la configuración

Este paquete incluye `config/config.php` con valores locales habituales de Laragon. Antes de continuar, abre el archivo y comprueba:

- `DB_HOST`: normalmente `127.0.0.1`.
- `DB_PORT`: normalmente `3306`, pero debe coincidir con el puerto de tu servicio MySQL/MariaDB.
- `DB_ADMIN_USER`: normalmente `root`.
- `DB_ADMIN_PASS`: suele estar vacío en una instalación local estándar de Laragon. Si configuraste una contraseña para `root`, escríbela aquí.
- `DB_PASS`: contraseña local que se asignará al usuario de la aplicación `educate_app`. Puedes cambiarla.

`config/config.php` contiene credenciales locales y está excluido de Git. No subas ese archivo a GitHub. Para futuras clonaciones, copia `config/config.example.php` como `config/config.php` y revisa las credenciales.

### 4. Inicializa la base de datos

Abre en el navegador:

```text
http://localhost/proyecto2DAW_2027/database/reset.php
```

Pulsa **«Sí, reiniciar la base de datos»** únicamente si quieres crear la base de datos desde cero. Este proceso **elimina la base de datos `educate` existente y todos sus datos**, la vuelve a crear, aplica las migraciones y prepara el usuario `educate_app`.

Si ya tienes datos que quieras conservar, **no uses `reset.php`**. Usa `database/migrar.php` solo para aplicar las migraciones pendientes.

### 5. Comprueba la instalación

Abre:

```text
http://localhost/proyecto2DAW_2027/
```

La página de estado comprobará PHP, `pdo_mysql` y la conexión con la base de datos. Si la conexión falla, confirma que MySQL/MariaDB está iniciado, que el puerto es correcto y que `DB_ADMIN_PASS` coincide con tu instalación.

### 6. VS Code (opcional)

Abre la carpeta `C:\laragon\www\proyecto2DAW_2027` en VS Code e instala las extensiones recomendadas. Si el validador de PHP no encuentra el ejecutable, configura `php.validate.executablePath` en los ajustes de usuario con la ruta real del `php.exe` activo en Laragon. La ruta exacta varía según la versión instalada.

### Usuarios de prueba

| Usuario | Rol | Contraseña / PIN |
|---|---|---|
| `admin` | admin | `Educate2026!` |
| `laura.padre` | padre | `Educate2026!` |
| `profe.ruiz` | profesor | `Educate2026!` |
| `LeonAzul42`, `GatoVerde7` | niño | `1234` |
| `BuhoRojo9` | niño (inactivo, sin consentimiento) | `1234` |

## Trabajo diario

1. Abre Laragon y pulsa **Start All**.
2. `git pull` para traer lo último.
3. **Si han llegado migraciones nuevas**, abre `database/migrar.php`. La página de estado avisa si tienes alguna pendiente.
4. Programa en tu rama, guarda y recarga el navegador (F5). No hay que compilar.
5. `git add` + `git commit` + `git push` y abre un *pull request*.

### Cambios en la base de datos

- **Nunca** cambies tablas a mano sin dejarlo escrito: crea una migración en `database/migraciones/` (`001_que_hace.sql`, `002_...`). Las instrucciones están en [`database/migraciones/README.md`](database/migraciones/README.md).
- Cuando los demás hagan `git pull` y ejecuten `migrar.php`, tendrán el mismo cambio sin perder sus datos.
- Si tu BD se queda rota, `database/reset.php` la recrea desde cero. Recuerda que elimina los datos existentes.

### Reglas de código

- Cada página empieza con `require_once __DIR__ . '/includes/bootstrap.php';` (o `/../includes/...` desde una subcarpeta).
- Consultas **siempre** con `db()->prepare(...)` + `execute([...])`. Nunca concatenar datos del usuario en el SQL.
- Al imprimir datos en HTML, **siempre** con `e($texto)`.
- Formularios POST con `<?= csrf_campo() ?>` dentro del `<form>` y `csrf_verificar();` al recibirlos.
- Los roles y permisos se comprueban en el servidor, en cada página.

## Estructura del repositorio

```
proyecto2DAW_2027/
├── config/
│   ├── config.example.php   Plantilla de configuración (sí se sube)
│   └── config.php           Configuración local (NO se sube a Git)
├── database/
│   ├── educate.sql          BD v2.1 completa + datos de prueba
│   ├── migraciones/         Cambios de la BD posteriores, numerados
│   ├── migrar.php           Aplica las migraciones pendientes
│   └── reset.php            Recrea la BD desde cero
├── includes/
│   ├── bootstrap.php        Arranque común de todas las páginas
│   ├── db.php               Conexión PDO: db()
│   └── funciones.php        e(), url(), redirigir(), sesión y CSRF
├── docs/                    Guías del proyecto
├── Diagramas_ER/            Modelo de datos (diagrama entidad-relación)
├── .vscode/                 Configuración y extensiones comunes de VS Code
├── index.php                Entrada (de momento redirige a estado.php)
└── estado.php               Comprobación del entorno (temporal)
```

Próximas carpetas según la guía: `padre/`, `profesor/`, `nino/`, `admin/`, `css/`, `js/`, `img/avatares/`.

## Ramas

| Rama | Uso |
|---|---|
| `main` | Versión estable del proyecto |
| `Diagramas_ER` | Trabajo sobre el modelo de datos |
| `feature/...` | Una rama por funcionalidad (`feature/login`, `feature/familias`...) con *pull request* a `main` |

## Estado

- [x] Propuesta, maqueta visual y prototipo básico
- [x] Elección de tecnología: PHP puro + PDO; Laragon para desarrollo local
- [x] Modelo de datos v2.1
- [x] Script SQL (`database/educate.sql`) con datos de prueba
- [x] Estructura base, conexión a la BD y sistema de migraciones
- [ ] Login, sesiones y roles (v0.1)
- [ ] Alta de niños, clases, tareas y entregas (v0.1)
- [ ] Reparto de tareas
- [ ] Desarrollo del MVP: control parental, catálogo e informe básico
