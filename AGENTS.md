# AGENTS.md — kodavio-agent-kit

> Puerta de entrada para operar **instalaciones WordPress en vivo a través de Kodavio**.
> La lee cualquier agente: Claude Code, Cursor, Codex, OpenCode, Kilo Code.
> Fuente única: este archivo. `CLAUDE.md` y `.cursor/rules/` son punteros, no copias.

## Qué es

Capa **cliente** para trabajar con sitios WordPress reales vía el plugin Kodavio (MCP por sitio).
Kodavio (server-side) ya aporta: workflows, playbooks (`kodavio/skill-list`), capability map, handbook, dry-run, backups y tester mode. Esta carpeta aporta lo que el plugin no puede saber:

- **Qué sitios existen** y en qué entorno está cada uno → `registry/sites.json`
- **Qué puede hacer el agente en cada entorno** → `rules/production-guardrails.md`
- **Cómo se arranca y se cierra una sesión por sitio** → skill `wp-site-session`
- **Memoria por sitio** (decisiones, peculiaridades, históricos) → `sites/{slug}/NOTAS.md`
- **Orquestación**: skills locales + subagentes que componen los flujos de Kodavio con las reglas de `agentkit/` de SA

⚠ No confundir: `projects/kodavio` es el **código del plugin** (desarrollo del producto). Aquí se **usa** el plugin contra sitios reales. Bugs del plugin → backlog del proyecto kodavio, no parches aquí.

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
├── sites/{slug}/        memoria por sitio (NOTAS.md + PLAN.md si hay plan de sitio)
└── state.md             estado vivo de esta capa
```

**Fuente única, sin excepción.** `CLAUDE.md`, `.claude/skills`, `.claude/agents` y `.agents/skills` son **symlinks**; `.codex/agents/*.toml` se genera con `scripts/gen-codex-agents.sh` y no se edita a mano. Si algo de eso se convierte en copia, cada herramienta acaba leyendo un kit distinto — `scripts/doctor.sh` lo detecta y bloquea el commit.

## Protocolo de sesión por sitio (obligatorio)

Antes de tocar cualquier sitio, ejecuta el skill **`wp-site-session`**. Resumen:

1. Localiza el sitio en `registry/sites.json` → anota `env` y `mcp_servers`.
2. Lee `sites/{slug}/NOTAS.md` (peculiaridades, prohibiciones, históricos).
3. Si el sitio pertenece a un cliente → revisa `sites/{slug}/NOTAS.md` (no hay handbook por cliente en el sistema actual de SA).
4. Por MCP: `kodavio/agent-handbook` + `kodavio/wp-get-config-summary`.
5. Aplica la matriz de guardarraíles según `env` (abajo).
5b. **Antes del primer write**: aplica invariantes 6 y 7 de `rules/production-guardrails.md` (env cross-check + multi-MCP guard).
5c. **Fuente de la ability**: descubre lo que expone el sitio (`kodavio/capability-map` + `mcp-adapter-discover-abilities`) y **prefiere la ability nativa** (Bricks 2.4, WP-core) envuelta en el gate de Kodavio; cae a `kodavio/*` si no hay. Razona por **rol**, no por tool name → `rules/ability-source-agnostic.md`.
6. Para la tarea concreta: `kodavio/workflow-router` → `kodavio/context-bootstrap` → `kodavio/skill-get` del playbook que toque. `context-bootstrap` devuelve scope + sistema de diseño activo + memoria vinculante (`source=human` + `tag=instruction|caveat` son obligatorias) + últimos cambios, en una sola llamada; sustituye llamar a `scope-read`, `design-read` y `memory-list` por separado.

## Matriz de guardarraíles por entorno

Regla canónica completa: `rules/production-guardrails.md`. Resumen ejecutivo:

| Acción | dev | staging | **production** |
|---|---|---|---|
| Lecturas / diagnóstico | libre | libre | libre |
| Crear contenido como draft | libre | libre | libre |
| Publicar / cambio visible | OK | OK | **Human Gate** |
| Builder writes (Bricks/Elementor/Gutenberg) | dry_run → write | dry_run → write | snapshot + dry_run → write **en draft**; publicar = gate |
| Plugins: install/update/activate | OK con dry-run | confirmación | **Human Gate** + `sensitive-actions-log` |
| PHP / snippets | sandbox | sandbox | **Human Gate**; solo sandbox o mu-plugin, nunca tema/plugin activo |
| Borrar (contenido, media, usuarios, plugins) | confirmación | confirmación | **Human Gate siempre** |
| Bulk ops (>10 items) | confirmación | confirmación | **Human Gate** |

Siempre, en todos los entornos: `dry_run=true` antes de cualquier write; conservar originales; anotar backup/rollback IDs en la respuesta.

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
| `wp-content-publish` | Posts, contenido editorial, SEO on-page (copy en castellano perfecto) |
| `wp-copywriting` | Copy comercial (landing, home, página de servicio, sobre nosotros, FAQ) anclado a scope y sistema de diseño |
| `wp-marketing` | Plan de marketing digital sobre WordPress: captación, CRO, secuencias FluentCRM, medición |
| `wp-patterns-author` | Crear y mantener patterns propios para el catálogo de Kodavio (formato spec, plantillas por categoría, validación, packs) |
| `wp-builder-convert` | Conversión entre builders con rollback |
| `wp-site-health` | Mantenimiento: updates, salud, rendimiento, logs |
| `wp-security-triage` | Sospecha de infección, hardening proactivo, auditoría de seguridad |
| `wp-security-cleanup` | Respuesta a incidente: orquesta `wp-malware-cleanup-mcp` + abilities Kodavio + gates humanos para limpiar y endurecer un sitio comprometido |
| `wp-client-report` | Informe de marca blanca (auditoría completa, área o tienda) a partir del trabajo ya hecho; entregarlo es gate |

Los playbooks **del servidor** (bricks-build-page, acf-integration, fluent-suite, woocommerce-operations…) se cargan en runtime con `kodavio/skill-get` — no se duplican aquí.

Skills globales ya instaladas que aplican (no reinstalar): `wp-wpcli-and-ops`, `wp-performance-review`, `wp-security-audit`, `design-*`, y el pack oficial WordPress/agent-skills (`wp-block-development`, `wp-plugin-development`, `wp-rest-api`…).

## Subagentes

| Agente | Rol Kodavio | Uso |
|---|---|---|
| `wp-auditor` | auditor | Diagnóstico read-only, nunca escribe |
| `wp-operator` | operator | Admin WP seguro: plugins, settings, usuarios |
| `wp-bricks-operator` | builder_operator | Especialista Bricks (+FDS): nodos nativos, patch-first, vetos |
| `wp-elementor-operator` | builder_operator | Especialista Elementor: contenedores, site kit, migración v4 |
| `wp-gutenberg-operator` | builder_operator | Especialista Gutenberg: bloques core, patterns, theme.json |
| `wp-builder-operator` | builder_operator | Genérico/fallback cuando el builder es mixto o desconocido |
| `wp-content-architect` | content_architect | CPTs, taxonomías, campos, queries y bindings — antes que las páginas |
| `wp-woo-operator` | operator | WooCommerce con gates de dinero (precios, pedidos, refunds) |
| `wp-content-writer` | — | Copy, posts, SEO (castellano perfecto / inglés según sitio) |
| `wp-verifier` | verifier / rollback_verifier | Verificación post-write: read-back, salud de página, rollback path |

Regla de selección: el especialista del builder del sitio (registry) antes que el genérico. ¿Una capacidad nueva va al plugin o al kit? → `docs/kodavio-vs-kit.md`.

## Reglas de oro

1. **El agente es el autor; Kodavio es el ejecutor.** Copy, jerarquía, dirección de diseño y CTAs los decides tú ANTES de llamar a create-page. Nunca pidas a Kodavio que se invente el contenido.
2. **dry_run primero, siempre — y LEER su salida antes del write real.** Sin excepción en writes.
3. **Producción = drafts.** Nada se publica ni se hace visible sin Human Gate.
4. **Nunca PHP en tema/plugin activo.** Sandbox (`wp-content/kodavio-sandbox/`) o mu-plugin con lint + backup. En producción además: gate.
5. **Un flujo primario por tarea.** `kodavio/workflow-router` decide; los flujos compuestos en orden de dependencia.
6. **Verificar antes de declarar éxito.** Read-back, editor-open check, página sana. El write que "no falló" no es un write verificado — y el que no se ve tampoco: **escrito ≠ visible** (`rules/render-verification.md`).
7. **Memoria en su capa** (ver "Dos memorias" abajo). Errores → `agentkit/retros/mistakes.md`.
8. **Comunicación en castellano**; código y tecnicismos en inglés. Contenido publicable → `agentkit/rules/copy-review.md` (capa SA).
9. **Página existente + verbo de modificación** (cambia/edita/ajusta/corrige/mueve/reordena/reemplaza) ⇒ `action=edit`, **nunca** `create`. Crear solo si la página no existe (verificar con `wp-search` o `builder-router` antes de elegir).
10. **El nombre del server MCP == entorno.** Ej.: `acme_com` = producción; `acme_com_staging` = staging. Verifica el server destino antes de cada write; equivocarlo es escribir en el entorno equivocado.
11. **Los caveats de `registry/sites.json` y `sites/{slug}/NOTAS.md` son vinculantes** (PHP roto, hosting frágil, sin backups). Si un caveat prohíbe la acción, para y pregunta.
12. **No filtrar datos sensibles en el transcript.** Nunca pegues literalmente: emails completos (`user@dominio.com` → `u***@dominio.com`), contraseñas/Application Passwords, license keys, contenido de `wp-config.php`, ni valores de options que parezcan API keys (>=20 chars alfanum + guiones o base64). Reads afectadas: `wp_list_users`, `wc_list_customers`, `fluentcrm_get_contact`/`fluentcrm_list_contacts`, `kodavio/windpress-read-config`, `kodavio/wp-get-config-summary`, change logs de Kodavio. Si el operador necesita el dato, indícale el path en admin (p. ej. `Usuarios > Editar`, `WindPress > License`) y que lo lea él. Detalle: `docs/credentials.md`.

> Si dudas en cualquier regla, para y pregunta. No hay penalización por preguntar; sí la hay por sobreescribir producción.

**Cómo se ve todo esto aplicado:** `docs/field-notes.md` — leer un dry-run de verdad, presentar un Human Gate, un informe de verificación que sirve, el caso caro de create-vs-edit, y los modos de fallo ya verificados en sitios reales. Léelo una vez antes de tu primer write; después, cuando algo salga raro.

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
- `sites/{slug}/NOTAS.md` y `sites/{slug}/PLAN.md` — memoria y cola de briefs de cada sitio (solo `sites/_template/` se versiona). En entorno SA el backlog maestro sigue siendo OPS; PLAN.md es el detalle por sitio.
- `state.md`, `.claude/settings.local.json` — estado y permisos de tu máquina.
- **Skills/subagentes personales del operador** — créalos en `skills/<nombre>/` (visibles para Claude Code porque `.claude/skills` es symlink a `skills/`) y lista su ruta en **`.sync-keep.local`** (una por línea, p. ej. `skills/<tu-skill>/`). `sync-installed.sh` los preserva (no los borra al sincronizar) y `.sync-keep.local` está gitignored, así que tus nombres personales nunca llegan al kit compartido. Para tu flujo propio (intake/analyze/pricing/pm/track…) sin filtrarlo a otros.
- Credenciales: **jamás** en este árbol, ni versionadas ni sin versionar. Access store / gestor de secretos.

Si un archivo versionable necesita mencionar un sitio concreto, no lo hagas: la referencia va a `sites.json` (caveats) o a las NOTAS del sitio.

## Doctrina superior (capa SA — opcional fuera de Soluciones Abiertas)

Las referencias a `agentkit/*` y al script `ops.sh` (en `scripts/` de sa-workspace, no de este kit) aplican en el entorno de Soluciones Abiertas. Si clonaste este kit y esas rutas no existen, **omítelas**: el resto del sistema es autosuficiente. En entorno SA: Human Gates, autonomía, WIP y comunicación heredan de `AGENTS.md` (raíz del workspace); acciones sensibles en producción → `agentkit/retros/sensitive-actions-log.md` SIEMPRE (fuera de SA: registra el equivalente en las NOTAS del sitio).

