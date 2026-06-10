# AGENTS.md — wp-development

> Puerta de entrada para operar **instalaciones WordPress en vivo a través de Kodavio**.
> La lee cualquier agente: Claude Code, Cursor, Codex, OpenCode, Mavis.
> Fuente única: este archivo. `CLAUDE.md` y `.cursor/rules/` son punteros, no copias.

## Qué es

Capa **cliente** para trabajar con sitios WordPress reales vía el plugin Kodavio (MCP por sitio).
Kodavio (server-side) ya aporta: workflows, playbooks (`kodavio/skill-list`), capability map, handbook, dry-run, backups y tester mode. Esta carpeta aporta lo que el plugin no puede saber:

- **Qué sitios existen** y en qué entorno está cada uno → `registry/sites.json`
- **Qué puede hacer el agente en cada entorno** → `rules/production-guardrails.md`
- **Cómo se arranca y se cierra una sesión por sitio** → skill `wp-site-session`
- **Memoria por sitio** (decisiones, peculiaridades, históricos) → `sites/{slug}/NOTAS.md`
- **Orquestación**: skills locales + subagentes que componen los flujos de Kodavio con las reglas del Playbook de SA

⚠ No confundir: `projects/kodavio` es el **código del plugin** (desarrollo del producto). Aquí se **usa** el plugin contra sitios reales. Bugs del plugin → backlog del proyecto kodavio, no parches aquí.

## Mapa

```
wp-development/
├── AGENTS.md            ← esta puerta (fuente única)
├── CLAUDE.md            → symlink a AGENTS.md
├── .cursor/rules/       → reenvía a AGENTS.md (Cursor)
├── .claude/             skills/ y agents/ symlinked para Claude Code
├── registry/sites.json  ← REGISTRO DE SITIOS: entorno, MCP, builder, guardarraíles
├── rules/               reglas duras locales (guardarraíles, protocolo, código en vivo)
├── skills/              playbooks portables (formato SKILL.md, los lee cualquier agente)
├── agents/              subagentes (formato Claude; otros agentes los usan como prompts)
├── workflows/           WORKFLOWS.md = petición → flujo Kodavio → skill → gates
├── sites/{slug}/        memoria por sitio (NOTAS.md)
└── state.md             estado vivo de esta capa
```

## Protocolo de sesión por sitio (obligatorio)

Antes de tocar cualquier sitio, ejecuta el skill **`wp-site-session`**. Resumen:

1. Localiza el sitio en `registry/sites.json` → anota `env` y `mcp_servers`.
2. Lee `sites/{slug}/NOTAS.md` (peculiaridades, prohibiciones, históricos).
3. Si el sitio pertenece a un cliente → lee `Playbook/clients/{cliente}/HANDBOOK.md`.
4. Por MCP: `kodavio/agent-handbook` + `kodavio/wp-get-config-summary`.
5. Aplica la matriz de guardarraíles según `env` (abajo).
6. Para la tarea concreta: `kodavio/workflow-router` → `kodavio/skill-get` del playbook que toque.

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

| Skill | Cuándo |
|---|---|
| `wp-site-session` | SIEMPRE al empezar a trabajar con un sitio |
| `wp-onboard-site` | Conectar un sitio nuevo a Kodavio + MCP en todos los agentes |
| `wp-page-build` | Crear/editar páginas, secciones, templates (orquesta page_creation) |
| `wp-content-publish` | Posts, contenido editorial, SEO on-page (copy en castellano perfecto) |
| `wp-builder-convert` | Conversión entre builders con rollback |
| `wp-site-health` | Mantenimiento: updates, salud, rendimiento, logs |
| `wp-security-triage` | Sospecha de infección, hardening, auditoría de seguridad |

Los playbooks **del servidor** (bricks-build-page, acf-integration, fluent-suite, woocommerce-operations…) se cargan en runtime con `kodavio/skill-get` — no se duplican aquí.

Skills globales ya instaladas que aplican (no reinstalar): `wp-wpcli-and-ops`, `wp-performance-review`, `wp-security-audit`, `design-*`, y el pack oficial WordPress/agent-skills (`wp-block-development`, `wp-plugin-development`, `wp-rest-api`…).

## Subagentes

| Agente | Rol Kodavio | Uso |
|---|---|---|
| `wp-auditor` | auditor | Diagnóstico read-only, nunca escribe |
| `wp-operator` | operator | Admin WP seguro: plugins, settings, usuarios |
| `wp-builder-operator` | builder_operator | Escrituras builder tras brief aprobado |
| `wp-content-writer` | — | Copy, posts, SEO (castellano perfecto / inglés según sitio) |
| `wp-verifier` | verifier / rollback_verifier | Verificación post-write: read-back, salud de página, rollback path |

## Reglas de oro

1. **El agente es el autor; Kodavio es el ejecutor.** Copy, jerarquía, dirección de diseño y CTAs los decides tú ANTES de llamar a create-page. Nunca pidas a Kodavio que se invente el contenido.
2. **dry_run primero, siempre.** Sin excepción en writes.
3. **Producción = drafts.** Nada se publica ni se hace visible sin Human Gate.
4. **Nunca PHP en tema/plugin activo.** Sandbox (`wp-content/kodavio-sandbox/`) o mu-plugin con lint + backup. En producción además: gate.
5. **Un flujo primario por tarea.** `kodavio/workflow-router` decide; los flujos compuestos en orden de dependencia.
6. **Verificar antes de declarar éxito.** Read-back, editor-open check, página sana. El write que "no falló" no es un write verificado.
7. **Memoria.** Lo aprendido de un sitio → `sites/{slug}/NOTAS.md`. Errores → `Playbook/retros/mistakes.md`.
8. **Comunicación en castellano**; código y tecnicismos en inglés. Contenido publicable → `rules/copy-review.md` del Playbook.

## Multi-agente: qué lee cada herramienta

| Agente | Entrada |
|---|---|
| Claude Code | `CLAUDE.md` (→ este archivo) + `.claude/skills/` + `.claude/agents/` (symlinks) |
| Codex / OpenCode / Amp | `AGENTS.md` directamente; skills en `skills/*/SKILL.md` como playbooks |
| Cursor | `.cursor/rules/wp-development.mdc` (reenvía aquí) |

Los MCP por sitio se configuran por herramienta (Claude: `~/.claude.json`; Cursor: `.cursor/mcp.json`; Codex: `~/.codex/config.toml`; OpenCode: `opencode.json`). El skill `wp-onboard-site` cubre el alta en las cuatro.

## Datos locales (NO versionados)

Este repo es un **kit clonable**: nunca contiene datos de sitios ni clientes reales. Lo local vive solo en tu máquina (`.gitignore`):

- `registry/sites.json` — tus sitios reales. Se crea desde `registry/sites.example.json`.
- `sites/{slug}/NOTAS.md` — memoria de cada sitio (solo `sites/_template/` se versiona).
- `state.md`, `.claude/settings.local.json` — estado y permisos de tu máquina.
- Credenciales: **jamás** en este árbol, ni versionadas ni sin versionar. Access store / gestor de secretos.

Si un archivo versionable necesita mencionar un sitio concreto, no lo hagas: la referencia va a `sites.json` (caveats) o a las NOTAS del sitio.

## Doctrina superior (capa SA — opcional fuera de Soluciones Abiertas)

Las referencias a `Playbook/*`, `Handbook/*` y OPS (`ops.sh`) aplican en el entorno de Soluciones Abiertas. Si clonaste este kit y esas rutas no existen, **omítelas**: el resto del sistema es autosuficiente. En entorno SA: Human Gates, autonomía, WIP y comunicación heredan de `Playbook/SYSTEM.md`; acciones sensibles en producción → `Playbook/rules/sensitive-actions-log.md` SIEMPRE (fuera de SA: registra el equivalente en las NOTAS del sitio).
