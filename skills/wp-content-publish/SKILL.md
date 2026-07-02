---
name: wp-content-publish
description: Crear y publicar contenido editorial (posts, páginas de texto, landing copy) con SEO on-page en sitios WordPress vía Kodavio o MCP genérico. Incluye revisión de copy y flujo draft-aprobación-publicación.
---

# wp-content-publish — Contenido editorial y SEO

## Cuándo

Posts de blog, noticias, fichas, textos de páginas — donde manda el contenido, no el layout. Si hay que construir layout → `wp-page-build`.

## Herramienta

- Sitio con builder en la página destino → vía Kodavio (los metadatos del builder importan).
- Post/página de contenido puro → CRUD (`wp-create-post`/`wp_create_post`) es suficiente, confirmando el sitio destino del server MCP.

## Flujo

1. `wp-site-session` hecho. Idioma del sitio según el campo `language` del registry — nunca asumirlo. Aplica el **`execution_profile`** del bootstrap (`rules/execution-profile.md`) a la escritura del contenido; publicar sigue siendo Human Gate en producción sea cual sea el perfil.
2. **Investigación mínima**: leer 2-3 posts existentes del sitio → tono, estructura, categorías y tags reales (no inventar taxonomía nueva sin avisar).
3. **Redacción** (subagente wp-content-writer para lotes):
   - Castellano perfecto → checklist `Playbook/rules/copy-review.md` (capa SA; si no existe en tu entorno, exige el mismo estándar con criterio propio). Inglés → registro editorial del sitio.
   - SEO on-page: title ≤60 chars con keyword, meta description 120-155, H1 único, H2/H3 jerárquicos, slug corto, enlaces internos a 2-3 contenidos existentes, alt text en imágenes.
   - Detectar el plugin SEO del sitio (Yoast/RankMath/SEOPress) en la lista de plugins y escribir sus meta fields, no inventar campos.
4. **Imágenes**: solo de fuentes con licencia (media library existente, Unsplash, generadas). Subir con filename descriptivo + alt. No hotlinking.
5. **Crear como draft** con categorías/tags existentes.
6. **Gate de publicación**: en producción, presentar título + preview URL + meta y esperar OK. En dev/staging se puede publicar directo.
7. Verificar publicado: URL final responde 200, sin shortcodes rotos visibles, featured image presente.

## Lotes (varios posts)

Mostrar 1 post completo de muestra → OK del humano → resto del lote con la misma plantilla. Bulk >10 = gate aunque sean drafts (taxonomía y media se ensucian rápido).

## SEO audit

Para auditoría SEO de contenido existente usa la skill global `market-seo` si está instalada (entorno SA); si no, audita con los criterios on-page del punto 3. Esta skill es de producción de contenido.
