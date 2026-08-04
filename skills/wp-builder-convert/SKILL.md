---
name: wp-builder-convert
description: Convertir páginas, templates o sitios entre Bricks, Elementor y Gutenberg vía Kodavio, con auditoría de fidelidad y rollback garantizado. Usar para migraciones de builder o de sistema de diseño.
---

# wp-builder-convert — Conversión entre builders

Flujo Kodavio: `builder_migration` (perfil `conversion`). Playbooks del servidor: `builder-conversion` (simple) o `builder-conversion-advanced` (con dynamic data, forms, Woo, ACF/JetEngine, frameworks). Para migración de versión Elementor: `elementor-migrate-v4`.

> Fases canónicas: `rules/skill-phases.md`. **La conversión es moat de Kodavio: no hay ability nativa equivalente** (ningún builder convierte a otro) → aquí se usa `kodavio/*` directamente; la regla `ability-source-agnostic` no aplica a la conversión.

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
5. **Bugs de fidelidad del converter** (verificados en fuente el 2026-08-04, Kodavio 0.3-dev):
   - ✅ *Color como background* y *template type forzado*: **arreglados**. El color tipográfico ya mapea por widget (`title_color`/`text_color`/`button_text_color`) y el `_elementor_template_type` existente se respeta en vez de sobrescribirse.
   - ⚠️ **`video_type` sigue vivo en Bricks → Elementor**: el converter mete la URL en `youtube_url` y **nunca escribe `video_type`**. Elementor asume `youtube` por defecto → un vídeo de Vimeo, Dailymotion o self-hosted llega **roto**. La dirección inversa (Elementor → Bricks) sí lo resuelve bien.
   - ⚠️ **Vídeo en el camino Semantic Model V2** (el que usa `builder-transfer-page`, o sea las 6 direcciones): al analizar coge `youtube_url ?? vimeo_url ?? hosted_url` **sin mirar `video_type`**. Elementor conserva URLs viejas de proveedores anteriores, así que puede ganar una URL obsoleta y convertir el vídeo equivocado.
   - Regla práctica: **si la página tiene vídeo, verifícalo a mano en la copia convertida** — reproducir, no solo ver que el widget existe.

## Cierre

1. Sign-off humano sobre la copia → cutover (publicar convertida / despublicar original) = **gate**.
2. NO borrar el original ni su meta hasta sign-off explícito posterior. `conversion-rollback` disponible y anotado.
3. Limpieza final de meta del builder viejo: tarea separada, con backup, semanas después.
4. Resultado y rarezas → `sites/{slug}/NOTAS.md`; bugs del converter → backlog del proyecto kodavio.
