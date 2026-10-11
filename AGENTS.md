# AGENTS.md — kodavio-agent-kit

Capa **cliente** para trabajar con sitios WordPress reales vía el plugin Kodavio (MCP por sitio).
Kodavio aporta workflows, playbooks, capability map, handbook, dry-run, backups y tester mode; este
kit aporta qué sitios hay (`registry/sites.json`), qué se puede hacer en cada entorno
(`rules/production-guardrails.md`), cómo se abre y cierra una sesión (skill `wp-site-session`) y la
memoria por sitio (`sites/{slug}/NOTAS.md`). `projects/kodavio` es el **código del plugin**: sus
bugs van a su backlog, no se parchean aquí.

**Ajustes del operador:** si junto a un fichero del kit hay otro con el mismo nombre y `.local.md`
(`AGENTS.local.md`, `rules/<regla>.local.md`, `skills/<slug>/SKILL.local.md`), léelo justo después:
manda sobre el original. Los ficheros del kit no se editan.

Mapa, tablas completas, multi-agente, datos locales y capa SA: `docs/guia-del-kit.md`.

## Protocolo de sesión por sitio (obligatorio)

Antes de tocar cualquier sitio, la skill **`wp-site-session`**. En resumen:

1. `registry/sites.json` → `env` y `mcp_servers` del sitio; después `sites/{slug}/NOTAS.md`.
2. Por MCP: `kodavio/agent-handbook` + `kodavio/wp-get-config-summary`.
3. Aplica la matriz de abajo según `env`; **antes del primer write**, las invariantes 6 y 7 de
   `rules/production-guardrails.md` (env cross-check + multi-MCP guard).
4. Descubre lo que expone el sitio (`kodavio/capability-map` + `mcp-adapter-discover-abilities`) y
   **prefiere la ability nativa** envuelta en el gate de Kodavio; razona por rol, no por nombre de
   tool (`rules/ability-source-agnostic.md`).
5. Para la tarea: `kodavio/workflow-router` → `kodavio/context-bootstrap` (scope + diseño + memoria
   vinculante + últimos cambios en una llamada) → `kodavio/skill-get` del playbook que toque.

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

Siempre, en todos los entornos: conservar originales y anotar backup/rollback IDs en la respuesta.

## Reglas de oro

1. **El agente es el autor; Kodavio es el ejecutor.** Copy, jerarquía, diseño y CTAs se deciden ANTES de crear; nunca pidas a Kodavio que invente el contenido.
2. **dry_run primero, siempre — y LEER su salida antes del write real.**
3. **Producción = drafts.** Nada se publica ni se hace visible sin Human Gate.
4. **Nunca PHP en tema/plugin activo.** Sandbox (`wp-content/kodavio-sandbox/`) o mu-plugin con lint + backup; en producción, además, gate.
5. **Un flujo primario por tarea.** `kodavio/workflow-router` decide; los compuestos, en orden de dependencia.
6. **Verificar antes de declarar éxito:** read-back, editor-open check, página sana. El write que «no falló» no es un write verificado, y el que no se ve tampoco: **escrito ≠ visible** (`rules/render-verification.md`).
7. **Memoria en su capa** (abajo).
8. **Castellano** al comunicar; código y tecnicismos en inglés.
9. **Página existente + verbo de modificación** (cambia, edita, ajusta, corrige, mueve, reordena, reemplaza) ⇒ `action=edit`, **nunca** `create`; crear solo si no existe (verificar con `wp-search` o `builder-router` antes de elegir).
10. **El nombre del server MCP == entorno** (`acme_com` = producción, `acme_com_staging` = staging). Verifica el destino antes de cada write.
11. **Los caveats de `registry/sites.json` y `sites/{slug}/NOTAS.md` son vinculantes.** Si uno prohíbe la acción, para y pregunta.
12. **No filtrar datos sensibles en el transcript.** Nunca pegues literalmente: emails completos (`user@dominio.com` → `u***@dominio.com`), contraseñas/Application Passwords, license keys, contenido de `wp-config.php`, ni valores de options que parezcan API keys (>=20 chars alfanum + guiones o base64). Reads afectadas: `wp_list_users`, `wc_list_customers`, `fluentcrm_get_contact`/`fluentcrm_list_contacts`, `kodavio/windpress-read-config`, `kodavio/wp-get-config-summary`, change logs de Kodavio. Si el operador necesita el dato, indícale el path en admin (p. ej. `Usuarios > Editar`, `WindPress > License`) y que lo lea él. Detalle: `docs/credentials.md`.

> Si dudas en cualquier regla, para y pregunta. No hay penalización por preguntar; sí la hay por sobreescribir producción.

Cómo se ve aplicado (un dry-run leído de verdad, un Human Gate, un informe de verificación, el caso caro de create-vs-edit, fallos vistos en vivo): `docs/field-notes.md`. Léelo antes de tu primer write.

## Dos memorias

Cada hecho vive en una sola capa. Lo que describe **el sitio** y debería saber cualquier agente que se
conecte → memoria de Kodavio (`kodavio/design-write`, scope). Lo que describe **cómo trabajas tú con
ese sitio** (riesgos, permisos, hosting, historia operativa) → `sites/{slug}/NOTAS.md`, al cerrar la
sesión. Tabla completa: `docs/guia-del-kit.md`.

## Skills y subagentes

Están en `skills/` y `agents/`; cuándo usar cada uno, en `docs/guia-del-kit.md`. Toda skill de
construcción, edición o administración recorre las fases canónicas (`rules/skill-phases.md`). Los
playbooks del servidor se cargan con `kodavio/skill-get`. Subagente: el especialista del builder del
sitio antes que el genérico.
