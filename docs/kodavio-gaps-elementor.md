# Brechas conocidas de Kodavio en Elementor (plantillas de producto y Pro)

> Origen: sesión de construcción de una plantilla Single Product de Elementor Pro sobre un sitio WooCommerce real (WP 7.0, Elementor 4.1.4, modo `v4_v3`, WooCommerce + Product Add-Ons), 2026-07-04/06. Cada punto está **reproducido**, no supuesto.
>
> **Qué hace este doc en el kit:** evita que el agente pierda una sesión intentando algo que la ability no puede hacer, y le da el rodeo que sí funciona. Es criterio del operador — inerte sin Kodavio. Los arreglos viven en el backlog del **plugin**, no aquí (`docs/kodavio-vs-kit.md`).
>
> Complementa `docs/field-notes.md`. Léelo antes de construir plantillas de Elementor Pro.

**En una frase:** Kodavio construye el *contenido* de casi cualquier plantilla vía inserción cruda de árbol, pero no cierra la última milla de las plantillas de producto (tipo + condiciones + preview), su generador semántico se queda en widgets nativos, y en esta versión de Elementor no aplica las clases CSS de contenedor.

---

## 1. `create` no materializa widgets no-nativos (Woo / Pro)

`elementor-create-page` y `builder-workflow action=create` materializan desde `content_model.sections` pero **solo generan widgets nativos**: `heading`, `text-editor`, `button`, `image` y contenedores.

Probado: pasar widgets Woo como `blocks` con las claves `widgetType`, `type`, `name` y `widget` → **todas ignoradas o degradadas a `text-editor`**. No se puede crear una plantilla de producto "desde un modelo o prompt".

## 2. `single-product` no es creable desde cero (catch-22)

Crear con `template_type: "single-product"` exige 5 widgets Woo presentes (`woocommerce-product-title`, `-price`, `-add-to-cart`, `-data-tabs`, `-related`). Pero por el punto 1 el materializer **no sabe generarlos**: exige unos widgets que él mismo no puede crear. `product-archive` probablemente igual.

**Rodeo que funciona:** crear `template_type: "single"` (no exige widgets) → `elementor-insert-content` con el árbol Woo crudo (preserva `widgetType` tal cual) → plantilla funcional, pero atascada como tipo "single". Para que sea "single-product" de verdad, el operador crea el contenedor en blanco desde la UI de Elementor y ahí se inserta el árbol.

## 3. Faltan abilities para el meta y para Theme Builder

No hay forma vía MCP de fijar `_elementor_template_type` (re-tipar una plantilla), asignar *display conditions* de Theme Builder, ni fijar *preview settings*. El ciclo «construir → asignar → previsualizar» **no es 100% agente**: obliga a dos clics del operador. `conversion-visual-preview` no sirve (es solo para diffs de conversión con backup previo).

## 4. Las clases CSS de contenedor no llegan al DOM ⚠️ la más molesta

En Elementor 4.1.4 / modo `v4_v3`, el `_css_classes` puesto en un **container** (vía `insert-content` o `node-update`) **no aparece en el HTML**. Solo se renderizan las clases de **widget**.

Reproducido sobre una plantilla real: las clases de widget aparecían; las seis clases de contenedor daban **0 ocurrencias en el DOM**.

**Impacto:** no puedes estilar contenedores por clase semántica; hay que caer al `.elementor-element-<id>`, frágil porque cambia si se reconstruye el nodo. Degrada el patrón class-first que recomienda el propio design memory de Kodavio.

Hipótesis: en v4 la estructura de clases de contenedor cambió (posible `classes` con `$$type` en atomic) y el adapter escribe `_css_classes`, que la v4 no honra en contenedores v3.

## 5. El ancho de flex-child de contenedor no se aplica

Un container flex-child con `width: {%: 62}` + `_element_width: "custom"` + `_element_custom_width: {%: 62}` **no genera ninguna regla CSS de ancho** → los hijos caen a `flex: 1 1 0` (50/50 simétrico) en vez del 62/38 pedido. Para columnas asimétricas hay que forzar `flex-basis` por CSS externo apuntando al id de elemento (con la fragilidad del punto 4).

## 6. No se puede crear `loop-grid` ni Loop Item por MCP

Falla por los dos métodos (`elementor-node-create` y `elementor-insert-content`) con `Unknown Elementor schema for node loop-grid`. La lista de `elementor-list-widgets` (28 widgets) no lo incluye.

**Impacto:** no se puede montar el patrón Loop Grid + Loop Item de Elementor Pro por MCP. Rodeo: estilar por CSS el grid nativo existente, o usar `woocommerce-products` (sí soportado, pero con la tarjeta por defecto).

## 7. El CSS compilado de Elementor NO se regenera por MCP ⚠️

Tras escribir o insertar nodos por MCP, el estilo (fondo, padding, tipografía, flex de contenedor) **no aparece en el frontend**: vive en el CSS compilado (`uploads/elementor/css/post-<id>.css`) y ese archivo no se regenera. Confirmado que **ni el toggle draft→publish lo regenera** (el `Last-Modified` no cambia). El contenido sí aparece; el estilo no.

Lo único que lo regenera: un **Guardar/Update desde el editor** de Elementor, o Elementor › Tools › Regenerate CSS. Ambos son del operador.

**Consecuencia para el reporte:** si construyes por MCP en Elementor, tu «terminado» incluye decirle al humano que tiene que abrir la plantilla y dar Update, o el trabajo no se ve. No lo des por hecho ni lo omitas.

## 8. No se puede crear el widget `icon` por MCP

Falla con `Unknown Elementor schema for node icon` — y **invalida el insert entero**: tres iconos rechazados hicieron que no se insertara nada, aunque el resto de nodos validaban. Rodeo: widget `html` con `<i class="fas fa-…"></i>` dentro de un span estilado (si Font Awesome ya está cargado), o `image`.

> Cuidado con este modo de fallo: **un nodo inválido tumba el lote completo**. En inserts grandes, valida por partes antes de mandar el árbol entero.

---

## Lo que SÍ funciona (para no romperlo)

- `insert-content` preserva cualquier `widgetType`, incluidos los de Woo y Pro → es la vía fiable para materializar.
- `node-update settings_mode=merge` aplica cambios de settings limpios.
- El patch de CSS con backup + lint + health-check es sólido.

## Prioridad de arreglo sugerida (backlog del plugin)

1. **#4** — que las clases de contenedor se rendericen: hoy es el tapón de cualquier plantilla no trivial.
2. **#1 y #2** — que `create` acepte un `elements` crudo, o relajar el validador de single-product para permitir shell + inserción. El motor de inserción cruda ya existe; falta cablearlo al create.
3. **#7** — una ability `regenerate-css`, o que las escrituras de nodos disparen la recompilación.
4. **#3** — abilities para tipo de plantilla, condiciones y preview.
5. **#6 y #8** — meter `loop-grid`, Loop Item, `icon`, `icon-list` e `icon-box` en el safe-schema.
6. **#5** — cablear el ancho de flex-child de contenedor.
