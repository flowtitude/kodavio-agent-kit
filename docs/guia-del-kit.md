# Guía del kit

> Lo que no hace falta en cada sesión: mapa, ajustes, tablas completas de skills y subagentes,
> memorias, multi-agente, datos locales y capa SA. La entrada es `AGENTS.md`.

## Mapa

```
kodavio-agent-kit/
├── AGENTS.md            ← esta puerta (fuente única)
├── CLAUDE.md            → symlink a AGENTS.md
├── .cursor/rules/       → reenvía a AGENTS.md (Cursor)
├── .claude/             skills/ y agents/ symlinked para Claude Code
├── registry/sites.json  ← REGISTRO DE SITIOS: entorno, MCP, builder, guardarraíles
│                          (contrato en registry/sites.schema.json)
├── rules/               reglas duras locales (guardarraíles, fases, rol de la ability, render, protocolo)
├── skills/              playbooks portables (formato SKILL.md, los lee cualquier agente)
├── agents/              subagentes (formato Claude; .codex/agents se GENERA desde aquí)
├── workflows/           WORKFLOWS.md = petición → flujo Kodavio → skill → gates
├── docs/field-notes.md  cómo se ve el trabajo bien hecho + modos de fallo vistos en vivo
├── docs/kodavio-gaps-*  qué NO puede hacer la ability hoy, con el rodeo que sí funciona
├── scripts/doctor.sh    detector de deriva del kit — verde/rojo, engánchalo al pre-commit
├── registry/abilities-kodavio.json  qué capacidades expone el plugin de verdad
│                          (generado: kodavio/scripts/export-abilities-manifest.php)
├── sites/{slug}/        memoria por sitio (NOTAS.md); el plan del sitio vive en Kodavio (scope)
└── state.md             estado vivo de esta capa
```

## Tus ajustes sobre el kit (`*.local.md`)

**Si junto a un fichero del kit hay otro con el mismo nombre y `.local.md`, léelo justo después y
manda sobre el original.** `AGENTS.local.md` sobre este fichero, `rules/<regla>.local.md` sobre esa
regla, `skills/<slug>/SKILL.local.md` sobre esa skill.

Ahí van los ajustes del operador. **No se editan los ficheros del kit**: están fuera de git, así que
no llegan al kit compartido, y `scripts/actualizar-kit.sh` no los toca. Si alguien edita el fichero
del kit igualmente, la actualización tampoco lo pisa: deja la versión nueva como `<fichero>.nuevo`
y avisa.

**Fuente única, sin excepción.** `CLAUDE.md`, `.claude/skills`, `.claude/agents` y `.agents/skills` son **symlinks**; `.codex/agents/*.toml` se genera con `scripts/gen-codex-agents.sh` y no se edita a mano. Si algo de eso se convierte en copia, cada herramienta acaba leyendo un kit distinto — `scripts/doctor.sh` lo detecta y bloquea el commit.

## Skills locales (esta capa)

> Toda skill de construcción/edición/admin recorre las **fases canónicas** Discovery → Validate → Preview → Confirm → Execute → Report (`rules/skill-phases.md`), ejecutando por **rol** (`rules/ability-source-agnostic.md`), no por tool name.


| Skill | Cuándo |
|---|---|
| `wp-site-session` | SIEMPRE al empezar a trabajar con un sitio |
| `wp-onboard-site` | Comando interactivo de alta de sitio (`/wp-onboard-site`); alternativa terminal: `scripts/add-site.sh` |
| `wp-site-plan` | Sitios nuevos/rediseños: discovery → sitemap → modelo de contenido → cola de briefs aprobada |
| `wp-page-build` | Crear/editar páginas, secciones, templates (orquesta page_creation) |
| `wp-reference-to-brief` | Imagen de referencia/mockup → brief de construcción (requiere modelo con visión) |
| `wp-design-patterns` | Fase de autoría: anatomía de sección, ritmo de página, catálogo de patrones |
| `wp-bricks-fds` | Sitios Bricks con Flowtitude Design System: clases, tokens, elementos vetados |
| `wp-tailwind-windpress` | Tailwind v4 vía WindPress: detección, reglas de utilities, convivencia con Bricks |
| `wp-block-library` | Página nueva con bloques de la biblioteca (FDS + WindPress) y guardar bloques propios de la licencia |
| `wp-content-publish` | Posts, contenido editorial, SEO on-page (copy en castellano perfecto) |
| `wp-copywriting` | Copy comercial (landing, home, página de servicio, sobre nosotros, FAQ) anclado a scope y sistema de diseño |
| `wp-marketing` | Plan de marketing digital sobre WordPress: captación, CRO, secuencias FluentCRM, medición |
| `wp-builder-convert` | Conversión entre builders con rollback |
| `wp-site-health` | Mantenimiento: updates, salud, rendimiento, logs |
| `wp-security-triage` | Sospecha de infección, hardening proactivo, auditoría de seguridad |
| `wp-security-cleanup` | Respuesta a incidente: orquesta `wp-malware-cleanup-mcp` + abilities Kodavio + gates humanos para limpiar y endurecer un sitio comprometido |
| `wp-client-report` | Informe de marca blanca (auditoría completa, área o tienda) a partir del trabajo ya hecho; entregarlo es gate |

Los playbooks **del servidor** (bricks-build-page, acf-integration, fluent-suite, woocommerce-operations, configurar-sitio…) se cargan en runtime con `kodavio/skill-get` — no se duplican aquí.

Skills globales ya instaladas que aplican (no reinstalar): `wp-wpcli-and-ops`, `wp-performance-review`, `wp-security-audit`, `design-*`, y el pack oficial WordPress/agent-skills (`wp-block-development`, `wp-plugin-development`, `wp-rest-api`…).

## Subagentes

| Agente | Rol Kodavio | Uso |
|---|---|---|
| `wp-auditor` | auditor | Diagnóstico read-only, nunca escribe |
| `wp-operator` | operator | Admin WP seguro: plugins, settings, usuarios |
| `wp-bricks-operator` | builder_operator | Especialista Bricks (+FDS): nodos nativos, patch-first, vetos |
| `wp-elementor-operator` | builder_operator | Especialista Elementor: contenedores, site kit, migración v4 |
| `wp-gutenberg-operator` | builder_operator | Especialista Gutenberg: bloques core, patterns, theme.json |
| `wp-builder-operator` | builder_operator | Genérico/fallback cuando el builder es mixto o desconocido, y CrocoBuilder |
| `wp-content-architect` | content_architect | CPTs, taxonomías, campos, queries y bindings — antes que las páginas |
| `wp-woo-operator` | operator | WooCommerce con gates de dinero (precios, pedidos, refunds) |
| `wp-content-writer` | — | Copy, posts, SEO (castellano perfecto / inglés según sitio) |
| `wp-verifier` | verifier / rollback_verifier | Verificación post-write: read-back, salud de página, rollback path |

Regla de selección: el especialista del builder del sitio (registry) antes que el genérico. ¿Una capacidad nueva va al plugin o al kit? → `docs/kodavio-vs-kit.md`.

## Dos memorias: Kodavio (servidor) vs NOTAS.md (local)

Kodavio YA tiene memoria propia en cada sitio. No duplicar — cada hecho vive en una sola capa:

| | **Memoria Kodavio** (en el sitio) | **`sites/{slug}/NOTAS.md`** (en tu máquina) |
|---|---|---|
| Qué es | `design-read/write` (lenguaje visual, tokens), `scope-read` (audiencia, sitemap, ofertas), change log (auditoría de escrituras) | Memoria del **operador** sobre el sitio |
| Quién la ve | Cualquier agente/persona que se conecte a ESE sitio | Solo tú y tus agentes |
| Qué guarda | Decisiones de diseño y alcance DEL sitio | Caveats operativos ("no auto-actualizar plugin X", "no PHP: lint roto"), datos de hosting/backups, gates aprobados, incidentes, relación prod↔staging, contexto de cliente |
| Cuándo escribir | Tras decisiones de diseño/scope: `kodavio/design-write` | Al cierre de sesión (`wp-site-session`) |

Regla práctica: si el dato describe **el sitio** y debería conocerlo cualquier agente que se conecte → memoria Kodavio. Si describe **cómo trabajas tú con ese sitio** (riesgos, permisos, hosting, historia operativa) → NOTAS.md. Además NOTAS.md sobrevive a reinstalaciones del plugin y sirve cuando el sitio está caído o comprometido.

## Multi-agente: qué lee cada herramienta

| Agente | Entrada |
|---|---|
| Claude Code | `CLAUDE.md` (→ este archivo) + `.claude/skills/` + `.claude/agents/` (symlinks) |
| Codex / OpenCode / Amp | `AGENTS.md` directamente; skills en `skills/*/SKILL.md` como playbooks |
| Cursor | `.cursor/rules/kodavio-agent-kit.mdc` (reenvía aquí) |
| Kilo Code | `AGENTS.md` nativo + skills vía `.claude/skills/` (estándar Agent Skills); `agents/` como prompts de referencia para custom modes |

Los MCP por sitio se configuran por herramienta, cada una en su fichero de config de máquina (Claude: `~/.claude.json`; Cursor: config MCP propia de Cursor; Codex: `~/.codex/config.toml`; OpenCode: `opencode.json`; Kilo: `~/.config/kilo/kilo.jsonc`) — ninguno vive dentro de este repo. El skill `wp-onboard-site` cubre el alta en las cinco.

## Datos locales (NO versionados)

Este repo es un **kit clonable**: nunca contiene datos de sitios ni clientes reales. Lo local vive solo en tu máquina (`.gitignore`):

- `registry/sites.json` — tus sitios reales. Se crea desde `registry/sites.example.json`.
- `sites/{slug}/NOTAS.md` — memoria de cada sitio (solo `sites/_template/` se versiona). **El plan y la cola de construcción no van aquí**: viven en el alcance del sitio en Kodavio (`kodavio/scope-*`, ver `wp-site-plan`).
- `state.md`, `.claude/settings.local.json` — estado y permisos de tu máquina.
- **Ajustes sobre ficheros del kit** — en `*.local.md` junto al original (ver arriba). Nunca editando el fichero del kit.
- **Skills/subagentes personales del operador** — créalos en `skills/<nombre>/` (visibles para Claude Code porque `.claude/skills` es symlink a `skills/`) y lista su ruta en **`.sync-keep.local`** (una por línea, p. ej. `skills/<tu-skill>/`). `scripts/actualizar-kit.sh` los preserva (no los borra al actualizar) y `.sync-keep.local` está gitignored, así que tus nombres personales nunca llegan al kit compartido. Para tu flujo propio (intake/analyze/pricing/pm/track…) sin filtrarlo a otros.
- Credenciales: **jamás** en este árbol, ni versionadas ni sin versionar. Access store / gestor de secretos.

Si un archivo versionable necesita mencionar un sitio concreto, no lo hagas: la referencia va a `sites.json` (caveats) o a las NOTAS del sitio.

## Doctrina superior (capa SA — opcional fuera de Soluciones Abiertas)

Las referencias a `agentkit/*` y al script `ops.sh` (del workspace de agentkit, no de este kit) aplican en el entorno de Soluciones Abiertas. Si clonaste este kit y esas rutas no existen, **omítelas**: el resto del sistema es autosuficiente. En entorno SA: Human Gates, autonomía, WIP y comunicación heredan de `AGENTS.md` (raíz del workspace); acciones sensibles en producción → `agentkit/retros/sensitive-actions-log.md` SIEMPRE (fuera de SA: registra el equivalente en las NOTAS del sitio).
