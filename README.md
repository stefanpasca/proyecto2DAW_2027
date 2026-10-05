# Educate

Plataforma web que convierte el control parental en una herramienta de aprendizaje. Los niños gestionan y entregan sus tareas y, solo cuando las cumplen, acceden a vídeos y juegos aprobados. Padres, tutores y profesores siguen su progreso mediante informes.

Proyecto del módulo de Proyecto de 2º DAW · CPIFP Los Enlaces.

| | |
|---|---|
| **Equipo** | Hugo, David y Stefan Pasca |
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
| Entorno local | **XAMPP 8.2.12** (Apache 2.4, PHP 8.2, MariaDB 10.4, phpMyAdmin). Todos con la misma versión |
| Backend | PHP puro + PDO (sin framework), sesiones de PHP |
| Base de datos | MariaDB 10.4 en desarrollo (XAMPP), compatible con MySQL 8.0.16+ para el despliegue |
| Frontend | HTML, CSS y JavaScript con vistas en PHP |
| Editor | Visual Studio Code (configuración común en `.vscode/`) |
| Control de versiones | Git + GitHub |

## Puesta en marcha (primera vez)

1. Instala **XAMPP 8.2.12** en `C:\xampp` y arranca **Apache** y **MySQL** desde el panel.
2. Clona el repositorio dentro de `htdocs`:
   ```
   cd C:\xampp\htdocs
   git clone https://github.com/stefanpasca/proyecto2DAW_2027.git
   ```
3. Copia `config/config.example.php` como `config/config.php` y cambia `DB_PASS` por una contraseña tuya.
   (`config.php` no se sube a GitHub: cada uno tiene el suyo.)
4. Abre **http://localhost/proyecto2DAW_2027/database/reset.php** y pulsa «Sí, reiniciar».
   Crea la BD `educate` con los datos de prueba y el usuario `educate_app` con tu contraseña.
   *(También vale hacer doble clic en `database\reset.bat`.)*
5. Abre **http://localhost/proyecto2DAW_2027/** → página de estado: todo debe salir en verde.
6. En VS Code: *Archivo → Abrir carpeta* → `C:\xampp\htdocs\proyecto2DAW_2027` e instala las extensiones recomendadas que te propone.

### Usuarios de prueba

| Usuario | Rol | Contraseña / PIN |
|---|---|---|
| `admin` | admin | `Educate2026!` |
| `laura.padre` | padre | `Educate2026!` |
| `profe.ruiz` | profesor | `Educate2026!` |
| `LeonAzul42`, `GatoVerde7` | niño | `1234` |
| `BuhoRojo9` | niño (inactivo, sin consentimiento) | `1234` |

## Trabajo diario

1. Arranca Apache y MySQL en XAMPP.
2. `git pull` para traer lo último.
3. **Si han llegado migraciones nuevas**, abre `database/migrar.php` (o doble clic en `database\migrar.bat`).
   La página de estado avisa si tienes alguna pendiente.
4. Programa en tu rama, guarda y recarga el navegador (F5). No hay que compilar.
5. `git add` + `git commit` + `git push` y abre un *pull request*.

### Cambios en la base de datos

- **Nunca** cambies tablas a mano sin dejarlo escrito: crea una migración en `database/migraciones/`
  (`001_que_hace.sql`, `002_...`). Las instrucciones están en [`database/migraciones/README.md`](database/migraciones/README.md).
- Cuando los demás hagan `git pull` y ejecuten `migrar.php`, tendrán el mismo cambio sin perder sus datos.
- Si tu BD se queda rota: `database/reset.php` la recrea desde cero.

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
│   └── config.php           Tu configuración local (NO se sube)
├── database/
│   ├── educate.sql          BD v2.1 completa + datos de prueba
│   ├── migraciones/         Cambios de la BD posteriores, numerados
│   ├── migrar.php / .bat    Aplica las migraciones pendientes
│   └── reset.php / .bat     Recrea la BD desde cero
├── includes/
│   ├── bootstrap.php        Arranque común de todas las páginas
│   ├── db.php               Conexión PDO: db()
│   └── funciones.php        e(), url(), redirigir(), sesión y CSRF
├── docs/                    Guía de arranque v0.1 (Word)
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
- [x] Elección de tecnología: PHP puro + PDO, XAMPP (MariaDB 10.4)
- [x] Modelo de datos v2.1
- [x] Script SQL (`database/educate.sql`) con datos de prueba
- [x] Estructura base, conexión a la BD y sistema de migraciones
- [ ] Login, sesiones y roles (v0.1)
- [ ] Alta de niños, clases, tareas y entregas (v0.1)
- [ ] Reparto de tareas
- [ ] Desarrollo del MVP: control parental, catálogo e informe básico
