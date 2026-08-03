# Regla dura — Fases canónicas de una skill

> Toda skill de construcción/edición/admin recorre seis fases: **Discovery → Validate → Preview → Confirm → Execute → Report**. Es el vocabulario común del ecosistema (las skills nativas de Bricks usan el mismo patrón). Una skill de dominio puede nombrar sub-fases propias, pero **debe cubrir las seis**; ninguna se salta.
>
> Dentro de cada fase, la ejecución es **agnóstica de la fuente** (`ability-source-agnostic.md`): preferir la ability nativa envuelta en el gate de Kodavio, fallback a `kodavio/*`.

## Las seis fases

1. **Discovery** — orientarse antes de tocar nada. Sesión del sitio (`wp-site-session`), entorno + guardarraíles, qué builder/frameworks hay, qué abilities expone el sitio (`kodavio/capability-map` + `mcp-adapter-discover-abilities`), y el contexto persistente (`kodavio/context-bootstrap`: scope + sistema de diseño + memoria vinculante). **Autoría** (copy, jerarquía, dirección de diseño) es del agente y vive aquí.
2. **Validate** — decidir la acción de forma determinista (create vs edit), cargar el contrato técnico del playbook del servidor (`kodavio/skill-get`), y comprobar que el payload es coherente. Nada se escribe aún.
3. **Preview** — ver el resultado sin commitear: `dry_run=true` y leer su salida (p. ej. `materialization_plan`), o el render nativo (rol *previsualizar* → `bricks/render-elements`). Si el preview delata pérdida (mapped < enviado, bloques desconocidos), el contrato está mal → volver a Validate.
4. **Confirm** — Human Gate donde el guardarraíl lo exija (producción, publicar, destructivo, plugins, bulk, dinero) y desambiguación cerrada si hubo conflicto. Sin gate superado, no se ejecuta.
5. **Execute** — el write, por la mejor fuente disponible (rol → nativa envuelta en el gate, o `kodavio/*`), respetando el `execution_profile`: draft en producción, snapshot antes de tocar publicado, nunca reemplazo de árbol entero sin petición explícita.
6. **Report** — verificar (read-back + page health + editor-open + revisión visual del preview; verifier como **pase separado**) y reportar: qué cambió, IDs de snapshot/backup, URL de preview, y qué falta para publicar.

## Invariantes transversales (todas las fases)

- El verifier (Report) **no es quien escribió** (Execute) — pase separado, no autoaprobación.
- El `execution_profile` solo **añade** cautela; nunca rebaja el guardarraíl de entorno.
- El contrato técnico del builder se carga en runtime (`skill-get`), no se memoriza en la skill (evita drift).
