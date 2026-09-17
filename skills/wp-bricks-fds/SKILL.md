---
name: wp-bricks-fds
description: Preferencias de trabajo con Bricks Builder y el Flowtitude Design System (FDS) - clases semánticas, tokens fluidos, elementos nativos permitidos y vetados, y dónde se guarda cada cosa. Usar SIEMPRE que se construya o edite en un sitio Bricks con FDS/Flowtitude.
---

# wp-bricks-fds — Bricks + Flowtitude Design System

Sitios con theme Flowtitude Child o stack `flowtitude`/`fds` en el registry. El playbook técnico de escritura es el del servidor (`kodavio/skill-get slug=bricks-build-page`); esta skill fija **nuestras preferencias** encima.

> Fases canónicas (`rules/skill-phases.md`) y ejecución por **rol** (`rules/ability-source-agnostic.md`): las lecturas/escrituras de abajo prefieren la ability nativa de Bricks 2.4 envuelta en el gate de Kodavio; fallback a `kodavio/*`.

## Qué es FDS

Design system CSS sobre **Tailwind v4** (vía WindPress). No es un framework: extiende Tailwind con tokens fluidos, componentes y layouts. Todo es fluido (tipografía y spacing escalan con el viewport vía knobs) — por eso **nunca se hardcodean tamaños**.

Antes de construir, orientar el sistema de diseño activo (rol *orientar diseño* → nativa `bricks/get-design-context` o `kodavio/design-read`+`design-get-system`) para ver los tokens activos del sitio (los knobs pueden estar personalizados por proyecto).

## Clases FDS — qué usar

**Tipografía (semántica, nunca tamaños a mano):**

| Necesidad | Clase | Nunca |
|---|---|---|
| Texto gigante decorativo | `.display`, `.display-md`, `.display-sm` | `font-size` inline / `text-9xl` suelto |
| Título principal | `h1` o `.heading` | `clamp()` a mano |
| Título de sección | `h2` o `.heading-md` | `text-3xl` sin contexto |
| Subtítulo | `h3` / `.heading-sm`, `.subheading*` | inventar clases |
| Ante-título / kicker | `.eyebrow` | `text-xs uppercase tracking-widest` manual |
| Lead / intro | `.text-large` | `text-lg` suelto |
| Texto normal | `p` (hereda del body) | `font-size` fijo |

**Botones:** `.btn` + variante de color (`.btn-primary`, `.btn-secondary`, `.btn-dark`, `.btn-light`, `.btn-outline`, `.btn-link`) + tamaño (`.btn-sm`…`.btn-xl`) + forma/layout si toca (`.btn-rounded`, `.btn-block`…). Nunca estilizar un botón a mano.

**Spacing:** tokens semánticos (`--spacing-inner`, `-content`, `-stack`, `-block`, `-columns`, `-section`, `-hero`) y spacing fluido (`-fluid-xs`…`-fluid-2xl`). Una sección usa spacing de sección, no un `padding: 80px`.

**Layout:** secciones con el layout de FDS (`layouts/section.css`), posicionamiento de 9 puntos (`content-flex`), grids proporcionales y auto-fill/fit (`grid-basic`). Utilities Tailwind para el ajuste fino (reglas en `wp-tailwind-windpress`).

**Utilidades propias:** `.bg-image` (fondo full-cover), `.click-parent` (card clickeable entera), `.focus-from-child`.

## Bricks — elementos y políticas

**Estructura con nodos nativos, siempre:**
- **Regla 1 (AJ, 12-sep-2026): solo elementos `div`.** Nunca los elementos `section`, `container` ni
  `block` de Bricks: traen su propio layout (ancho, padding, flex) que pisa al FDS. La raíz de cada
  sección es un `div` con la etiqueta semántica `section` en sus settings; el resto, `div` con la
  etiqueta que toque (`div`, `nav`, `article`, `ul`, `li`…). Vale también para lo que devuelva un
  conversor: se corrige antes de escribir.
- **Regla 2 (AJ, 13-sep-2026): un texto de un solo párrafo es un `text-basic` con su etiqueta
  semántica** (`p`, `span`, `dt`, `dd`, `li`, `blockquote`, `summary`…). El texto enriquecido
  (`text`) solo cuando son varios párrafos. Un `text-basic` con etiqueta `div` está mal.
- **Regla 3 (AJ, 13-sep-2026): la imagen va siempre dentro de un `div` con etiqueta `figure`.**
  Nunca un `image` suelto en la rejilla o en la tarjeta. El FDS ya estila `figure > img`.
- **Regla 4 (AJ, 13-sep-2026): sin elemento `divider` de Bricks.** Con el FDS no se ve: su línea
  la borra el reset `* { border-width: 0 }`, que va en una capa posterior a la de Bricks. Un
  separador es un `div` con etiqueta `hr` y la clase `border-border`.
- Tag semántico vía settings del elemento (`name=heading` + `settings.tag=h2`), **nunca** HTML incrustado en el texto.
- Un nodo de texto (`text-basic`, `text`, `heading`, `button`) contiene texto. Si contiene `<div>`, `<section>`, `<style>` o markup de layout, está mal.
- Ediciones: patch del elemento (rol *escribir/parchear* → nativa `bricks/update-element` o `kodavio/bricks-apply-patch`), no reenviar el árbol. Full-tree replace solo con rebuild pedido explícitamente.
- Clases: clases globales de Bricks + clases FDS. Estilos por-elemento (ID styles) solo para lo genuinamente único de ese elemento.

**Vetados salvo aprobación explícita del humano (`allow_code_widget=true`):**

| Elemento/práctica | Por qué |
|---|---|
| Code widget como layout o sección | Opaco, no editable visualmente, rompe el contrato del builder |
| HTML crudo incrustado en nodos | Invisible para conversión, design memory y QA |
| `<style>` / CSS inline grande | Se sale del design system; imposible de mantener |
| PHP templates para contenido de página | El contenido vive en el builder/BD, no en archivos |
| Estilos hardcodeados (px de font-size, colores hex sueltos) | FDS es fluido y tokenizado; el hardcode rompe la escala |

**Legacy a NO usar:** `flowtitude-lite`, `flowtitude-variables`, `flowtitude-pro` (proyectos antiguos reemplazados por FDS).

## Dónde se guarda cada cosa

- Páginas, templates y componentes generados → **entidades Bricks/BD** (vía Kodavio).
- Archivos del child theme → territorio de **Flowkit** (versionado). Si un template generado debe convertirse en archivo de tema, se exporta como artefacto revisado para Flowkit; no se escribe directo.
- Cambios de tokens/knobs FDS → flujo `design_system`, no ediciones sueltas por página. La cadena completa —memoria de diseño → FDS → WindPress → *Generate* humano → CSS servido— está en `wp-tailwind-windpress`, sección *Cambiar tokens del sistema*.

## Checklist antes de dar por buena una página Bricks+FDS

- [ ] Solo nodos nativos; cero code widgets no aprobados.
- [ ] Tipografía y botones con clases FDS semánticas; cero tamaños/colores hardcodeados.
- [ ] Spacing con tokens semánticos (sección respira como las demás del sitio).
- [ ] Clases repetidas promovidas a clase global.
- [ ] La página abre en el editor Bricks sin avisos y el frontend escala bien entre 410px y 1280px (viewport knobs de FDS).
