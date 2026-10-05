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

TBD

## Estructura del repositorio

```
proyecto2DAW_2027/
├── README.md          Este archivo
└── Diagramas_ER/      Modelo de datos (diagrama entidad-relación)
```

## Ramas

| Rama | Uso |
|---|---|
| `main` | Versión estable del proyecto |
| `Diagramas_ER` | Trabajo sobre el modelo de datos |

## Estado

- [x] Propuesta, maqueta visual y prototipo básico
- [x] Elección de tecnología: PHP + MySQL 8
- [x] Modelo de datos v2.1
- [ ] Script SQL para MySQL 8
- [ ] Framework de PHP y de frontend
- [ ] Reparto de tareas
- [ ] Desarrollo del MVP: registro y roles, tareas, control parental, catálogo e informe básico
