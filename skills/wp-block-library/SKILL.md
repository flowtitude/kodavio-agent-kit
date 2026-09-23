---
name: wp-block-library
description: Montar páginas de Bricks con bloques ya hechos de la biblioteca de Kodavio (FDS con WindPress), escribiendo el texto de cada bloque, y guardar en la biblioteca de la licencia los bloques nuevos. Usar cuando el sitio tiene WindPress y el encargo es una página nueva a partir de un briefing.
---

# wp-block-library — Páginas con bloques de la biblioteca

Los bloques viven en `library.flowtitude.com` y se llega a ellos solo a través de Kodavio con licencia válida. Hay dos bibliotecas: la **maestra**, que solo cambia Flowtitude, y la **de la licencia**, que se ve en todos los sitios de esa licencia. Un bloque es HTML con clases del framework y nada más.

> Fases canónicas: `rules/skill-phases.md`. Requiere **Kodavio 0.3.1** o posterior. Las cuatro capacidades están en `foundation`: funcionan de punta a punta, pero la licencia real aún no se ha probado contra el servidor.

## Qué hace y qué no

- **Sí**: crear una **página nueva** de Bricks con bloques en orden y tus textos (`kodavio/block-library-build-page`), y guardar un bloque nuevo en la biblioteca de la licencia (`kodavio/block-library-save`).
- **No**: meter bloques en una página que ya existe. Para eso, `wp-page-build` con `action=edit`.
- **No**: datos dinámicos (bucles, campos). El mapa de la ficha los describe, pero Kodavio todavía no los usa.
- **No**: tocar la maestra. Ninguna capacidad escribe en ella.

## Discovery — ¿el sitio puede pintar estos bloques?

1. `wp-site-session` hecho.
2. `kodavio/block-library-list` (con `tipo` si ya sabes qué buscas: `hero`, `servicios`, `cta`…). Mira `frameworks[].ready`: los bloques FDS necesitan **WindPress activo**. Si sale `false`, para y díselo al humano. Instalar o activar WindPress es otra tarea, y en producción es gate.
3. Si responde `ftl_sin_licencia` o `kodavio_block_library_no_license`, no hay biblioteca en este sitio. No la sustituyas por HTML inventado sin decirlo.
4. **Autoría, antes de elegir bloques**: del briefing sale la secuencia de secciones (qué va primero y por qué) y el texto real de cada una. El texto es tuyo, no del bloque: ni lorem ni el texto de ejemplo del bloque.

## Validate — elegir y rellenar

1. Por cada sección, el bloque que mejor encaja. La `densidad` de la ficha (`poca`, `media`, `mucha`) dice cuánto texto admite: no metas tres párrafos en un bloque de densidad `poca`.
2. `kodavio/block-library-get` de cada uno y escribe tu texto en su HTML. **Cambias texto, enlaces (`href`), imágenes (`src`, `alt`) y cuántas veces se repite un elemento** (una tarjeta más o una menos). **No cambias clases**: `build-page` rechaza cualquier clase que el bloque no tenga (`kodavio_block_library_invented_classes`) y te dice cuál.
3. **Si ningún bloque encaja**: parte del más parecido, ajústalo con clases que existan en el framework (para FDS, `wp-bricks-fds`) y guárdalo como bloque de la licencia (ver Execute). No lo fuerces en un bloque que no le toca.

## Preview — ensayo

`kodavio/block-library-build-page` con `dry_run` (es el valor por defecto). Lee `html_source.fidelity` y `warnings`: lo que Bricks no pueda guardar sale ahí. Si falta un bloque o un texto, vuelve a Validate.

## Confirm

- **Página**: se crea en **draft**. Publicar es gate en producción, como cualquier página (`production-guardrails.md`).
- **Bloque nuevo**: guardarlo es escribir en una biblioteca que se ve en **todos los sitios de la licencia**. Enséñale al humano el bloque y su `slug` antes de guardarlo.

## Execute

- Página: `build-page` con `dry_run=false` y `confirm_create=true`, `status=draft`.
- Bloque nuevo: `kodavio/block-library-save` en ensayo y después con `confirm_write=true`. El servidor aplica el contrato: un solo elemento raíz; sin `data-`, `id`, `style`, `<script>` ni `<style>`. Si lo rechaza, trae la lista de errores: corrígelos todos y vuelve a guardarlo. Lo que necesiten los datos dinámicos va en `mapa`, **nunca** en atributos del HTML.

## Report

1. Read-back y page health de la página creada (`wp-verifier`, pase separado).
2. **El texto se ve, el estilo puede que no**: WindPress compila en el navegador (`rules/render-verification.md`). Mira la URL del draft. Si las clases no tienen estilo, el trabajo está pendiente de un paso humano: abrir WindPress y generar el CSS. Va en primera línea del reporte.
3. Reporta la URL del draft, los bloques usados en orden, los que llevan tu texto y los bloques nuevos guardados (slug y tipo).
