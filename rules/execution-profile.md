# Regla dura — Perfil de ejecución (execution_profile)

> Disciplina de escritura de la sesión: cuánto dry-run, cuánto verify y cuándo leer antes de escribir. La define el humano en **Kodavio › Tools › Perfil de ejecución** y el plugin la impone. Esta regla dice cómo respetarla; el contrato vinculante lo devuelve el propio servidor.

## Fuente de verdad

`kodavio/context-bootstrap` devuelve `execution_profile { id, label, contract }` en cada arranque de tarea. El campo `execution_profile.headline` es la instrucción vinculante para toda la sesión. `kodavio/agent-handbook` también la incluye en `runtime_preferences`. **El plugin funciona sin este kit**: si operas un sitio con Kodavio sin el kit descargado, esta disciplina llega igual por el bootstrap — respétala siempre.

> Ojo: no confundir con el **perfil de flujo** del `workflow-router` (`fast`/`supervised`/`conversion`/`audit`), que describe la postura del flujo. El `execution_profile` es la postura de **riesgo** elegida por el humano y se aplica por encima del flujo.

## Los tres perfiles

| Perfil | dry-run | backup | verify | read-before-write |
|---|---|---|---|---|
| **Rápido** (`fast`) | solo destructivos/elevados | por irreversibilidad | read-back de lo escrito | solo al editar |
| **Equilibrado** (`balanced`, defecto) | destructivos | por irreversibilidad | ligero (lo recién escrito) | solo al editar |
| **Seguro** (`safe`) | **siempre** | por irreversibilidad | completo | **siempre** |

- **Backup por irreversibilidad en los tres**: WordPress ya cubre `post_content` con revisiones; el backup propio protege lo que WP no (options, JSON serializados, ficheros, mu-plugins, kit Elementor, tokens de diseño). El perfil cambia el dry-run, el verify y el read-before-write, no el backup.
- **Los destructivos/elevados nunca se saltan el dry-run**, ni en Rápido: borrados, install/uninstall de plugins, escritura de PHP y operaciones bulk piden dry-run + confirmación explícita en cualquier perfil.

## Cómo aplicarla en el pipeline

1. Al arrancar tarea, lee `execution_profile.contract` del bootstrap.
2. Ajusta tu disciplina de escritura a la tabla:
   - `dry_run=always` → toda escritura pasa por dry-run antes del write real.
   - `dry_run=destructive_only` → escribe directo salvo destructivos/elevados.
   - `read_before_write=always` → lee el árbol/fichero antes de cada write; `on_edit` → solo cuando editas algo existente.
   - `verify=full` → read-back + page health + revisión visual; `light_written` → read-back de lo escrito; `read_back_written` → confirma que lo escrito quedó.
3. Si el humano no cambió nada, el perfil es **Equilibrado**.
4. El perfil es un mínimo de prudencia, no un techo: ante una operación claramente irreversible, sube la cautela aunque el perfil sea Rápido.

## Precedencia (importante)

El `execution_profile` **nunca rebaja** los guardarraíles de entorno. Sobre un sitio en vivo mandan primero:

- `rules/production-guardrails.md` y la regla de oro «dry_run primero, siempre» de `AGENTS.md`: en **producción/staging** el dry-run antes de cada write y los drafts + Human Gate se mantienen **aunque el perfil sea Rápido**. La relajación de dry-run de `fast` (escribir directo salvo destructivos) aplica de hecho solo en **dev** o donde no haya un guardarraíl más estricto.
- Los `caveats` del sitio (`registry/sites.json`, `sites/{slug}/NOTAS.md`) y la memoria vinculante (`source=human` + `tag=caveat`).

Regla mental: el perfil solo puede **añadir** cautela respecto al entorno, nunca quitarla. En caso de conflicto, gana lo más estricto.
