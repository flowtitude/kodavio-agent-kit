---
name: wp-site-session
description: Protocolo de arranque y cierre de sesión sobre un sitio WordPress vía Kodavio. Usar SIEMPRE antes de operar cualquier sitio - identifica entorno, carga memoria del sitio y aplica guardarraíles.
---

# wp-site-session — Sesión por sitio

## Arranque

1. **Identificar el sitio** en `registry/sites.json`. Si no está → parar y ejecutar `wp-onboard-site`.
2. Anotar del registro: `env`, `guardrails`, `mcp_servers`, `builder`, `language`, `caveats`. Los caveats son vinculantes (p. ej. "no PHP en este sitio").
3. **Memoria local**: leer `sites/{slug}/NOTAS.md`. Si tiene cliente: `Playbook/clients/{client}/HANDBOOK.md`.
4. **Estado en vivo** (MCP del sitio):
   - `kodavio/wp-get-config-summary` → versión WP/PHP, builder activo, flags de seguridad, `php_lint_available`.
   - `kodavio/agent-handbook` → instrucciones del servidor (prevalecen en lo técnico).
5. Contrastar registro vs realidad: si builder/theme/env no cuadran → avisar y actualizar `sites.json` antes de seguir.
6. Aplicar la matriz de `rules/production-guardrails.md` según `env`.
7. Consultar tareas OPS activas del sitio/cliente (`ops.sh`).
8. Presentar al usuario un resumen de 3-5 líneas: sitio, entorno, builder, caveats, qué se va a hacer. Esperar OK si hay gates previsibles.

## Durante la sesión

- Cada tarea pasa por `kodavio/workflow-router` (regla `rules/kodavio-protocol.md`).
- WIP: un sitio a la vez. Cambiar de sitio = cerrar y reabrir este protocolo.

## Cierre

1. Verificación final de lo escrito (read-back / page health).
2. Memoria en su capa (regla "Dos memorias" de AGENTS.md):
   - Decisiones de diseño/scope del sitio → memoria Kodavio (`kodavio/design-write`), para que cualquier agente futuro las vea.
   - Caveats operativos, IDs de backup, gates aprobados, sorpresas → `sites/{slug}/NOTAS.md`.
3. Si hubo acción sensible en producción → `Playbook/rules/sensitive-actions-log.md`.
4. Tiempo en OPS si la tarea es facturable (`ops time <id> <min>`).
5. Errores cometidos → `Playbook/retros/mistakes.md`.
