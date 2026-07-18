# Regla dura — Agnóstico de la fuente de la ability

> El agente ejecuta usando **la mejor fuente disponible** de cada capacidad, no una tool concreta. Cuando el sitio expone una ability **nativa** del builder o de WordPress (p. ej. Bricks 2.4, WP-core 6.9+), se **prefiere la nativa** y se **envuelve en el gate/verify de Kodavio**; si no existe, se cae a la ability `kodavio/*` equivalente. La disciplina (entorno, gates, verificación) es del kit; la ejecución puede ser nativa o de Kodavio, indistintamente.
>
> Doctrina canónica: plugin Kodavio `docs/design/ecosystem-mcp-strategy-2026-07.md` (capa de disciplina = producto; delegar primitivas a lo nativo). Complementa a `kodavio-protocol.md`.

## Por qué

El ecosistema estandarizó una capa MCP nativa (WordPress Abilities API en 6.9, Bricks 2.4 con ~140 abilities). Reimplementar primitivas por builder es batalla perdida. El valor del kit **no** es tener tools propias, es que el modelo use bien **cualesquiera** que existan, sin romper el sitio. Por eso las skills razonan por **rol**, no por nombre de tool.

## Orden operativo

1. **Descubrir** qué hay en el sitio: `kodavio/capability-map` + `mcp-adapter-discover-abilities`. Detecta si el builder/WP exponen abilities nativas (Bricks 2.4: `bricks/*`).
2. **Preferir la nativa** cuando exista y esté habilitada (Bricks › Settings › AI on; no `BRICKS_DISABLE_MCP`).
3. **Envolver en el gate del kit**: la nativa ejecuta, pero el entorno/Human Gate/verify siguen siendo de Kodavio (`production-guardrails.md`, `execution-profile.md`). La nativa **no** decide si se escribe en producción — eso lo decide el gate.
4. **Fallback a `kodavio/*`** si no hay nativa, está desactivada o falla. Comportamiento nunca peor que sin capa nativa.
5. **Verificar** según el perfil, sea quien sea el que escribió.

## Mapa rol → ability (referenciar por ROL, no por tool name)

| Rol | Nativo (Bricks 2.4 / WP-core) | Kodavio (fallback / wrapper) |
|---|---|---|
| Orientar diseño (tokens/clases/paleta) | `bricks/get-design-context` | `kodavio/design-read` |
| Leer árbol de elementos | `bricks/get-page-elements`, `bricks/get-page-structure` | `kodavio/builder-workflow` (action=read), `kodavio/bricks-tree-read` |
| Escribir/parchear elementos | `bricks/set-page-elements`, `bricks/update-element`, `bricks/batch-update-elements`, `bricks/add-element`, `bricks/remove-element` | `kodavio/bricks-apply-patch`, `kodavio/bricks-node-*`, `kodavio/builder-workflow` |
| Previsualizar sin commit | `bricks/render-elements` | `dry_run=true` de Kodavio |
| Revisión / rollback | `bricks/list-revisions`, `bricks/restore-revision` | snapshots/backups de Kodavio |
| Sistema de diseño (clases/vars/theme styles/components) | `bricks/create/update-global-class`, `set-global-variables`, `create-theme-style`, `create-component` | `kodavio/bricks-global-class-upsert`, `kodavio/bricks-theme-style-upsert`, `kodavio/design-*` |
| Modelo de contenido | `bricks/list-cms-sources` | `kodavio/content-list-*`, `kodavio/scope-read` |

> El propio plugin ya delega server-side donde puede (p. ej. la escritura de árbol Bricks pasa por `bricks/set-page-elements` nativo si existe, heredando revisión + CSS-regen). Esta regla alinea el **lado cliente**: el agente también debe preferir la nativa al leer/orientar/previsualizar.

## Lo que SIEMPRE es de Kodavio (el moat — no delegable)

La nativa es single-site y "reversibility over gating". El kit aporta lo que ninguna capa de abilities da, y **no se delega jamás**:

- **Gates por entorno** y Human Gates (`production-guardrails.md`).
- **`execution_profile`** (postura de riesgo humana; solo añade cautela).
- **Cross-check de entorno** (no escribir en el entorno equivocado) y **multi-MCP guard**.
- **create-vs-edit determinista** (no reconstruir páginas publicadas).
- **Verifier como pase separado** (quien escribe no se autoaprueba).

## En una línea

Descubrir → **preferir nativa** → envolver en el gate de Kodavio → si no hay, `kodavio/*` → verificar. La fuente de la ability es intercambiable; la disciplina no.
</content>
