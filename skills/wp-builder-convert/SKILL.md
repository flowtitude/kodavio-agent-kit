---
name: wp-builder-convert
description: Convertir páginas entre Bricks y CrocoBuilder, o de HTML a Bricks, vía Kodavio, con auditoría de fidelidad y marcha atrás. Usar para migraciones de builder o de sistema de diseño. Elementor y Gutenberg están aparcados.
---

# wp-builder-convert — Conversión entre builders

Flujo Kodavio: `builder_migration` (perfil `conversion`). Playbooks del servidor: `builder-conversion` (simple) o `builder-conversion-advanced` (con dynamic data, forms, Woo, ACF/JetEngine, frameworks).

**Perímetro vivo (Kodavio 0.3, verificado el 2026-09-16/17):** Bricks ↔ CrocoBuilder en los dos sentidos (`builder-transfer-page`, en `active`) y HTML → Bricks (`builder-create-from-model` con `html`). Elementor y Gutenberg están **aparcados**: el plugin no registra sus capacidades. Si la conversión los toca, para y díselo al humano.

> Fases canónicas: `rules/skill-phases.md`. **La conversión es moat de Kodavio: no hay ability nativa equivalente** (ningún builder convierte a otro) → aquí se usa `kodavio/*` directamente; la regla `ability-source-agnostic` no aplica a la conversión.

## Antes de convertir

1. `wp-site-session` hecho. Conversión en producción = solo sobre copia/draft; tocar el original es **Human Gate**.
2. `kodavio/design-capability-matrix profile=conversion` + `kodavio/builder-conversion-plan` → alcance, riesgos, qué no es convertible.
3. Inventario de la página origen: dynamic data, forms, integraciones (Woo/ACF/JetEngine/Fluent), CSS custom, frameworks de diseño. Cada uno necesita estrategia explícita en el plan.
4. Presentar plan al humano si es producción o >1 página: páginas, orden, criterio de fidelidad, rollback.

## Conversión

1. `kodavio/skill-get slug=builder-conversion[-advanced]`.
2. Convertir hacia **draft nuevo**, original intacto (`builder-transfer-page` entre builders, `builder-create-from-model` con `html` desde HTML; siempre `dry_run` primero). La conversión es irreversible-por-naturaleza: snapshot + dry-run son obligatorios en **cualquier** `execution_profile` (el perfil solo puede subir el verify, nunca saltarse la red de la conversión).
3. `kodavio/conversion-status` tras cada página.
4. Auditoría de fidelidad por página: estructura, estilos, responsive, dynamic bindings vivos, forms que envían. Side-by-side original vs convertida.
5. **Lo que hay que saber de la conversión hoy** (verificado en WordPress real con Bricks 2.4 y CrocoBuilder, 2026-09-16/17):
   - **Lee poco de cada vez.** `builder-analyze-page` y `bricks-tree-read` devuelven por defecto un resumen (`detail=summary`). El detalle se pide por tramos (`section_offset`/`section_limit`) o por nodo (`node_id`). La respuesta de `builder-transfer-page` también lleva solo la ficha por sección. Si una respuesta pasa de 32 KB, trae un aviso con cómo pedirla troceada: hazle caso.
   - **Bricks → CrocoBuilder:** llegan texto, orden, enlaces, imagen, clases con sus reglas CSS y media queries. **El `alt` no llega**, porque Croco lo deriva del medio y no admite escribirlo. Dilo en el reporte, no es un fallo.
   - **CrocoBuilder → Bricks:** las clases de Croco se dan de alta como clases globales de Bricks con su CSS. Párrafos y listas van al elemento `text` (texto enriquecido).
   - **HTML → Bricks:** el árbol sale solo con `div` (raíz con etiqueta `section`); `summary`, `dt` y `dd` conservan su etiqueta; los formularios muestran sus etiquetas y el checkbox su texto; un encabezado dentro del `<form>` se coloca justo antes. **Lo que Bricks no puede guardar se avisa en `warnings`**: clases en campos, etiquetas y botón de envío. Léelo: `fidelity.native_repairs` cuenta lo repuesto y `fidelity.classes_kept_as_names`, las clases que quedan como nombre (se pintan igual).
   - **Marcha atrás de una transferencia: no es una sola llamada.** Página creada a la papelera (en Bricks, `kodavio/bricks-delete-page`) y **borrar las clases globales que creó** (`bricks/delete-global-class` en Bricks; la API de Croco en Croco). Anota qué clases creó (`created.global_classes.created`) para poder deshacerlo.
   - Si hay vídeo, **reprodúcelo** en la copia convertida; no basta con que el elemento exista.

## Cierre

1. Sign-off humano sobre la copia → cutover (publicar convertida / despublicar original) = **gate**.
2. NO borrar el original ni su meta hasta sign-off explícito posterior. Marcha atrás preparada y anotada (página y clases creadas; ver punto 5).
3. Limpieza final de meta del builder viejo: tarea separada, con backup, semanas después.
4. Resultado y rarezas → `sites/{slug}/NOTAS.md`; bugs del converter → backlog del proyecto kodavio.
