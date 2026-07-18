---
name: wp-patterns-author
description: Crear patterns propios para el catálogo de Kodavio (hero, CTA, features, testimonial…) en el formato correcto. Asistente para autorar specs JSON, validar antes de guardar, organizar tu biblioteca por categorías y exportar packs entre sitios.
---

# wp-patterns-author — Crear patrones para Kodavio

> Recorre las fases canónicas (`rules/skill-phases.md`). El motor de patrones es moat de Kodavio (sin equivalente nativo); se usa `kodavio/*` directamente.

Skill de **autoría de patrones**. El plugin Kodavio incluye un catálogo Core de patterns (hero centrado, CTA banner, features, etc.) que se materializan en Bricks/Elementor/Gutenberg desde un único spec. Esta skill ayuda al operador a **crear los suyos propios** en el formato correcto, sin que tenga que aprender el motor.

## Por qué necesitas esto

Un pattern es una pieza de página reutilizable expresada como **datos puros** (JSON). El plugin lo materializa al builder del sitio (Bricks o Elementor) usando los tokens del sistema de diseño activo. Ventaja: el mismo pattern funciona en cualquier sitio con cualquier sistema, sin código.

Limitación: el spec **tiene que cumplir el contrato** del motor (`Kodavio_Pattern_Materializer`). Un campo mal puesto y el pattern no aparece en el catálogo.

## Dónde se gestionan

`WP Admin › Kodavio › Diseño y memoria › Patterns` (desde 0.1.8). Allí ves Core + tuyos en la misma tabla, los filtras por fuente y categoría, los editas, los duplicas y los exportas/importas como pack JSON. Esta skill te asiste para que **el JSON que pegas en el editor sea válido**.

## Cuándo arrancarla

- *"Crea un pattern para los testimonios que usamos siempre así"*.
- *"Tengo este hero que repito en 6 landings — guárdalo como pattern"*.
- *"Quiero un pattern de pricing de 3 columnas"*.
- *"Ayúdame a estructurar el catálogo de patterns del cliente X"*.

## Fase 0 — Contexto

1. `wp-site-session` ejecutado.
2. `kodavio/context-bootstrap` — sistema de diseño activo (los roles que ofrece son los que vas a poder referenciar) + memoria.
3. `kodavio/patterns-list` para ver el catálogo actual y no duplicar lo que ya hay.
4. `kodavio/design-capability-matrix` para saber qué roles están disponibles en el sistema activo.

## Fase 1 — Anatomía del spec

Un pattern es un objeto con esta forma mínima:

```json
{
  "key": "testimonial-card",
  "label": "Tarjeta de testimonio",
  "category": "social_proof",
  "summary": "Tarjeta con foto, cita y nombre del cliente sobre fondo claro.",
  "roles": ["color_background", "color_text", "container_max", "spacing_md"],
  "spec": {
    "type": "section",
    "props": { "band": "lg", "bg": "color_background" },
    "children": [
      {
        "type": "stack",
        "props": { "max": "container_max", "gap": "spacing_md", "align": "center" },
        "children": [
          { "type": "image", "url": "{{photo_url}}", "props": { "rounded": "full", "size": "sm" } },
          { "type": "text", "text": "{{quote}}", "props": { "color": "color_text", "align": "center" } },
          { "type": "heading", "level": 4, "text": "{{name}}", "props": { "color": "color_text", "align": "center" } }
        ]
      }
    ]
  }
}
```

### Campos top-level

| Campo | Obligatorio | Qué guarda |
|---|---|---|
| `key` | sí | Slug único en kebab-case. No puede coincidir con uno Core. |
| `label` | sí | Nombre visible en el catálogo |
| `category` | sí | Agrupador: `hero`, `cta`, `features`, `pricing`, `social_proof`, `faq`, `team`, `custom`… |
| `summary` | sí | Una línea descriptiva |
| `roles` | sí | Lista de roles del sistema de diseño que usa (tokens, contenedores, espaciados). El motor los resuelve al builder destino. |
| `spec` | sí | Árbol de nodos (estructura visual) |
| `preview_image_url` | opcional | URL de imagen de muestra (no se sube desde aquí; pega URL del media library del sitio o del CDN) |

### Tipos de nodos del `spec`

| `type` | Hijos / contenido | Props comunes |
|---|---|---|
| `section` | `children` | `band` (sm/md/lg/xl), `bg` (rol de color) |
| `stack` | `children` | `max` (rol de contenedor), `gap` (rol de espaciado), `align` (left/center/right) |
| `row` | `children` | igual que stack, layout horizontal |
| `grid` | `children` | `cols` (1-6), `gap` |
| `heading` | `text` | `level` (1-6), `color`, `align` |
| `text` | `text` | `color`, `align`, `size` (sm/md/lg) |
| `button` | `text`, `url` | `bg`, `variant` (primary/secondary/ghost) |
| `image` | `url` | `rounded` (none/sm/lg/full), `size`, `alt` |
| `divider` | — | `color`, `thickness` |

> **Roles vs valores literales**: `bg: "color_background"` (rol) > `bg: "#ffffff"` (literal). El motor resuelve el rol al token del sistema de diseño activo. Si el cliente cambia de paleta, el pattern se adapta solo.

### Variables (`{{...}}`)

Los textos/URLs pueden ser plantillas: `"{{photo_url}}"`, `"{{quote}}"`, `"{{name}}"`. Al aplicar el pattern, el agente sustituye los placeholders con el contenido real. **Buena práctica**: nombrar las variables por su rol semántico, no por su contenido (`{{quote}}` > `{{texto1}}`).

## Fase 2 — Plantillas por categoría

Ofrece al operador una plantilla base por categoría. Algunas comunes:

- **Hero centrado** (1 columna): heading + subheading + CTA primaria. Roles: `color_background`, `color_text`, `color_primary`, `container_max`, `spacing_md`.
- **CTA banner** (banda primaria): heading + botón sobre fondo primario. Roles: `color_primary`, `color_background`, `container_max`.
- **Features 3 col** (grid): 3 columnas de icono + titular + texto corto. Roles: `color_text`, `container_max`, `spacing_lg`.
- **Testimonial card** (la del ejemplo arriba).
- **Pricing 3 col**: 3 columnas con plan, precio, lista de beneficios, CTA. Roles: `color_text`, `color_primary`, `container_max`.
- **FAQ accordion**: títulos con expandable. Roles: `color_text`, `container_max`, `spacing_md`.

Cuando el operador no sabe por dónde empezar, **empieza siempre por la plantilla más cercana y la adapta**, no desde cero.

## Fase 3 — Validación antes de guardar

El editor del admin valida con `Kodavio_Pattern_Materializer::validate` antes de guardar — si el spec está mal, no entra. Para no perder ese tiempo:

1. **JSON válido**: pega el spec en un validador (`jq` en terminal o cualquier validador online) antes de copiarlo al editor.
2. **`key` no colisiona con Core**: revisa `kodavio/patterns-list` o el listado del admin. Si quieres "personalizar" uno Core, **duplica** desde el admin (botón "Duplicar") y modifica la copia.
3. **`roles` consistentes con el spec**: cada rol mencionado en `props` debe estar declarado en `roles`. Si usas `bg: "color_primary"` y `color_primary` no está en `roles`, el motor lo rechaza.
4. **Builders soportados**: el motor decide qué builders soporta el spec según los tipos de nodos usados. Si tu pattern usa un tipo exótico no portable, solo aparecerá en builders compatibles.
5. **Probar el render**: tras guardar, llama `kodavio/patterns-apply` con `dry_run=true` sobre una página de pruebas — devuelve el plan de materialización. Si `mapped_blocks` < bloques enviados, hay algo del spec que el builder destino no entiende.

## Fase 4 — Empaquetado / Export

Cuando tienes un set de patterns útiles, expórtalos como pack:

1. `WP Admin › Kodavio › Diseño y memoria › Patterns › Generar pack`. Sale el JSON listo.
2. Descárgalo como `.json` o cópialo.
3. En el siguiente sitio: pega el JSON en el bloque "Importar pack". Marca *"reemplazar"* solo si quieres reemplazar la biblioteca actual; si no, fusiona.

Los Core nunca se sobrescriben con un import — solo se importan los **tuyos**. Los duplicados o inválidos se descartan con motivo.

## Reglas duras

1. **No metas datos del cliente en el spec del pattern**. Usa `{{variables}}` para todo lo que cambie por sitio (textos, fotos, URLs). El pattern es **estructura**, no contenido.
2. **No uses URLs literales del media library**: las imágenes hardcodeadas se rompen al portar a otro sitio. Usa `{{photo_url}}` y rellena al aplicar.
3. **Una responsabilidad por pattern**: un hero es un hero. Si tu pattern hace hero + features + testimonios, **divídelo en tres patterns** y aplícalos en secuencia.
4. **Usa roles, no colores literales** (con la excepción puntual de blanco/negro fijos cuando el sistema de diseño los expone como tokens).
5. **Documenta variables en `summary`**: "Tarjeta de testimonio (variables: `photo_url`, `quote`, `name`)" — el siguiente agente lo agradece.

## Cierre

- `kodavio/memory-write` con `source=agent`, `type=decision`, key `patterns/authored/{key}`, con: por qué se creó este pattern, dónde se usa, qué variables tiene. Así el próximo agente sabe cuándo usarlo.
- Si la biblioteca propia llega a un punto estable, **export pack** y guarda el JSON en el repo del cliente o en `Playbook/clients/{cliente}/` (si aplica) como respaldo.
