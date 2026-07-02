---
name: wp-builder-convert
description: Convertir páginas, templates o sitios entre Bricks, Elementor y Gutenberg vía Kodavio, con auditoría de fidelidad y rollback garantizado. Usar para migraciones de builder o de sistema de diseño.
---

# wp-builder-convert — Conversión entre builders

Flujo Kodavio: `builder_migration` (perfil `conversion`). Playbooks del servidor: `builder-conversion` (simple) o `builder-conversion-advanced` (con dynamic data, forms, Woo, ACF/JetEngine, frameworks). Para migración de versión Elementor: `elementor-migrate-v4`.

## Antes de convertir

1. `wp-site-session` hecho. Conversión en producción = solo sobre copia/draft; tocar el original es **Human Gate**.
2. `kodavio/design-capability-matrix profile=conversion` + `kodavio/builder-conversion-plan` → alcance, riesgos, qué no es convertible.
3. Inventario de la página origen: dynamic data, forms, integraciones (Woo/ACF/JetEngine/Fluent), CSS custom, frameworks de diseño. Cada uno necesita estrategia explícita en el plan.
4. Presentar plan al humano si es producción o >1 página: páginas, orden, criterio de fidelidad, rollback.

## Conversión

1. `kodavio/skill-get slug=builder-conversion[-advanced]`.
2. Convertir hacia **draft nuevo**, original intacto (`builder-transfer-page`, `convert-elementor-to-bricks`, etc., siempre `dry_run` primero). La conversión es irreversible-por-naturaleza: snapshot + dry-run son obligatorios en **cualquier** `execution_profile` (el perfil solo puede subir el verify, nunca saltarse la red de la conversión).
3. `kodavio/conversion-status` tras cada página.
4. Auditoría de fidelidad por página: estructura, estilos, responsive, dynamic bindings vivos, forms que envían. Side-by-side original vs convertida.
5. Bugs conocidos del converter (color como background, video_type, template type forzado — backlog kodavio 0.1.4): revisar específicamente y corregir a mano en la copia.

## Cierre

1. Sign-off humano sobre la copia → cutover (publicar convertida / despublicar original) = **gate**.
2. NO borrar el original ni su meta hasta sign-off explícito posterior. `conversion-rollback` disponible y anotado.
3. Limpieza final de meta del builder viejo: tarea separada, con backup, semanas después.
4. Resultado y rarezas → `sites/{slug}/NOTAS.md`; bugs del converter → backlog del proyecto kodavio.
