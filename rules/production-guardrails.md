# Regla dura — Guardarraíles por entorno (sitios WP vía Kodavio)

> La matriz que decide qué puede hacer un agente en cada sitio. El `env` lo fija `registry/sites.json`, **no** el `environment_type` que reporte WordPress.
> Hereda de: `Playbook/rules/sensitive-actions-log.md` (gates) y `Playbook/SYSTEM.md` (Human Gates globales) — capa SA, opcional fuera de Soluciones Abiertas (ver AGENTS.md › Doctrina superior).

## Invariantes (todos los entornos)

1. `dry_run=true` antes de CUALQUIER write. Se lee el resultado del dry-run antes del write real.
2. Conservar originales: conversiones y ediciones de builder guardan backup/snapshot; el ID de rollback se reporta en la respuesta final.
3. El agente redacta el contenido ANTES del write (content model / payload concreto). Nunca se delega la creatividad a Kodavio.
4. Verificación post-write obligatoria: read-back + page health / editor-open check. **Contrato de cierre**: una tarea NO puede declararse PASS sobre un write en producción sin output explícito de `wp-verifier` registrado en `sites/{slug}/NOTAS.md` (sección Verificación con timestamp + IDs read-back + veredicto PASS/PASS-avisos/FAIL). Si trabaja un solo agente, el verifier corre como **pase separado** (otra invocación, no en la misma respuesta del write). Sin ese registro la tarea queda `in_progress`, no se cierra.
5. Toda operación elevada queda anotada: qué, dónde, backup ID, cómo revertir.
6. **Env cross-check antes del primer write**: ejecuta `kodavio/wp-get-config-summary` y compara `environment_type` y `siteurl` contra `env` y `url` del registry. El `env` del registry sigue mandando (ver línea 3), pero ante discrepancia con `environment_type` o `siteurl` ≠ `url`: PARAR, mostrar el desajuste al humano y esperar confirmación antes de continuar. Anotar en `sites/{slug}/NOTAS.md`.
7. **Multi-MCP guard**: si en la sesión hay cargados >1 servers Kodavio (p. ej. `acme_com` + `acme_com_staging`), antes del primer write declara explícitamente el server destino y su `env` (`'voy a escribir en acme_com_staging, env=staging'`) y, si la última instrucción del humano solo mencionó el cliente sin sufijo, espera confirmación. Aplica también cuando el slug del registry incluye sufijos `_staging`/`_dev`.

## Perfil `development`

- Lecturas, drafts, publicación, builder writes: **autonomía total** (con invariantes).
- Plugins install/update/activate: OK con dry-run.
- PHP: sandbox (`wp-content/kodavio-sandbox/`) o mu-plugin con lint. Tema/plugin activo: solo con confirmación.
- Borrado: pedir confirmación (es recuperable vía papelera → preferir papelera a delete permanente).

## Perfil `staging`

- Lecturas, drafts: libre. Publicación en staging: OK (no es visible al público real).
- Builder writes: dry_run → write → verify.
- Plugins y PHP: con confirmación del usuario en la conversación.
- Borrado y bulk (>10 items): confirmación explícita.
- Recordar SIEMPRE: staging no sincroniza solo con producción. Decir qué falta para llevarlo a prod.

## Perfil `production` — Human Gates

| Acción | Tratamiento |
|---|---|
| Lecturas, diagnóstico, auditoría | Libre |
| Crear contenido como **draft** | Libre (es invisible al público) |
| **Publicar** o editar contenido ya publicado | **GATE** — mostrar diff/preview y esperar OK |
| Builder write sobre página publicada | Snapshot (`bricks-snapshot-page` o equivalente) + trabajar en draft/clon; aplicar al original = **GATE** |
| Plugins: install / update / activate / deactivate | **GATE** + entrada en `sensitive-actions-log` |
| Tema: cambiar / actualizar | **GATE** + log |
| PHP / snippets / mu-plugins | **GATE**; solo sandbox o mu-plugin con lint + backup. Tema/plugin activo: prohibido salvo orden explícita |
| Usuarios: crear/editar/borrar, roles | **GATE** |
| Settings del sitio (permalinks, lectura, URLs) | **GATE** |
| Borrar cualquier cosa | **GATE siempre**; preferir papelera/desactivar a destruir |
| Bulk ops (>10 items, contando llamadas individuales en una misma sesión) | **GATE** con muestra de 2-3 items primero. **No paralelizar writes** contra el mismo post/template (Bricks/Elementor guardan el árbol en una sola fila de postmeta como `_bricks_page_content` / `_elementor_data`; escrituras concurrentes pisan datos). Para >5 escrituras: en serie, con read-back entre lotes. |
| Conversión de builder | Solo sobre copia/draft; tocar el original = **GATE** |

**GATE** = parar, presentar plan + impacto + rollback, esperar confirmación explícita del humano. La aprobación de un gate vale para ESA acción, no para las siguientes.

## Señales de parada inmediata

- El sitio responde raro tras un write (500, white screen, layout roto) → parar, rollback con el backup ID, avisar.
- Kodavio devuelve éxito pero el read-back no coincide → tratar como fallo, no como éxito.
- El sitio no está en `registry/sites.json` → no operar; ejecutar `wp-onboard-site` primero.
- Tarea OPS con tag `supervision` → gate en todo.

## Errores → reglas

Cada error en un sitio en vivo se anota en `Playbook/retros/mistakes.md` y, si afecta a un solo sitio, también en `sites/{slug}/NOTAS.md`. Dos coincidencias → regla nueva aquí.
