# Regla dura — Protocolo Kodavio

> Cómo se habla con un sitio a través de Kodavio. Complementa al handbook del servidor (`kodavio/agent-handbook`), que prevalece si hay conflicto en lo técnico.

## Orden de llamadas para cualquier tarea

1. `kodavio/workflow-router` con la petición del usuario → flujo primario.
2. `kodavio/skill-get` del playbook que el router/flujo indique. **No escribir sin haber cargado el playbook.**
3. Primeras llamadas del flujo (las lista `kodavio/workflow-list`): config summary, design matrix, builder config, schema…
4. Autoría: el agente redacta content model / payload / brief completo.
5. `dry_run=true` → revisar → write real.
6. Verificación: read-back, `kodavio/tester-verify` si tester mode, page health.
7. Reportar: qué cambió, backup/rollback IDs, qué queda pendiente.

## Flujos (no mezclarlos casualmente)

`diagnostic_audit` < `wordpress_admin` < `design_system` < `content_model_dynamic` < `mini_plugin` < `page_creation` < `builder_migration` — si la petición cruza dominios, flujos compuestos **en orden de dependencia** (content model antes que binding; design system antes que página; miniplugin antes que verificación admin).

## Builder

- Ediciones sobre páginas Bricks existentes: leer árbol → `bricks-apply-patch` o primitivas de nodo. **Nunca** reemplazar el árbol completo salvo rebuild pedido explícitamente.
- Templates/componentes generados → entidades de builder/BD, NO archivos del child theme (salvo contrato Flowkit).
- Code widgets no son layout. Si la solución pasa por un code widget gigante, la solución está mal.
- Perfil de trabajo de diseño: `fast` por defecto; `supervised` para trabajo visual con brief/boceto aprobado; `conversion` para migraciones; `audit` para solo-lectura.

## MCP genéricos vs Kodavio

- Kodavio: todo lo que toque builders, diseño, conversión, scope, administración segura, PHP.
- MCP genérico `wordpress` (CRUD): solo contenido simple donde los metadatos de builder no importan — y tras confirmar a qué sitio apunta.
- Abilities de terceros (`mcp-adapter-discover-abilities`): descubrir → mapear → adaptar. Nunca ejecutar a ciegas.

## Endpoint

Preferido: `/wp-json/mcp/kodavio`. Alias legacy: `/wp-json/mcp/mcp-adapter-default-server`.
