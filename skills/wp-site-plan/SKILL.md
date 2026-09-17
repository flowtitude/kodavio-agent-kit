---
name: wp-site-plan
description: Planificación de un sitio o rediseño completo ANTES de construir - discovery, sitemap, modelo de contenido, dirección de diseño y cola de briefs por página. Produce un plan aprobable que luego ejecuta wp-page-build página a página. Usar para sitios nuevos, rediseños o cuando el encargo es "hazme la web".
---

# wp-site-plan — Planificar antes de construir

> Recorre las fases canónicas (`rules/skill-phases.md`) y ejecuta por **rol**, prefiriendo la ability nativa cuando exista, envuelta en el gate de Kodavio (`rules/ability-source-agnostic.md`).

El antídoto contra "ve construyendo y ya veremos": un plan corto, aprobado por el humano, que convierte un encargo difuso en una cola de tareas precisas. **Nada se construye hasta que el plan tiene OK.**

## Fase 1 — Discovery (entrevista única)

Antes de preguntar nada, lee lo que ya hay:

- `kodavio/scope-read` — quizá el sitio ya tiene alcance.
- Sistema de diseño — rol *orientar diseño* → nativa `bricks/get-design-context` o `kodavio/design-read`.
- **Sitio que ya existe (rediseño):** `kodavio/scope-import-from-site` con `dry_run=true`. Trae páginas, plugins y resumen de diseño leídos del sitio, y **declara en `needs_human` lo que no se puede leer** (audiencia, objetivos, propósito de cada página): esa lista es tu entrevista.
- **Sitio nuevo:** `kodavio/scope-plan-new-site` guarda el encargo, la audiencia y los objetivos **tal cual** y propone un sitemap por defecto. No interpreta el encargo: `plan_report.needs_agent` dice qué tienes que reescribir tú.

Pregunta en una sola tanda lo que siga sin saberse:

1. **Negocio**: qué vende/ofrece, a quién (audiencia), qué acción quiere provocar (lead, venta, llamada).
2. **Contenido disponible**: textos, fotos, logos, testimonios reales — qué existe y qué hay que crear.
3. **Referencias**: 2-3 webs que le gusten y por qué (si aporta imágenes → `wp-reference-to-brief`).
4. **Alcance**: nº de páginas aproximado, idiomas, blog sí/no, ecommerce sí/no, formularios/integraciones.
5. **Restricciones**: marca existente (colores/fuentes), plazos, qué NO quiere.

## Fase 2 — Plan (documento corto, no una biblia)

Produce y presenta para aprobación:

1. **Sitemap** — árbol de páginas con objetivo de cada una (1 línea por página) y prioridad (MVP / fase 2).
2. **Modelo de contenido** — si hay contenido estructurado (servicios, proyectos, productos): CPTs, taxonomías y campos. Esto irá al flujo `content_model_dynamic` ANTES que las páginas que lo consumen.
3. **Dirección de diseño** — tokens base (paleta, tipografía, densidad), 3-4 patrones de sección dominantes (`wp-design-patterns`), y si aplica FDS (`wp-bricks-fds`).
4. **Cola de briefs** — orden de construcción página a página, cada una con su patrón de composición. Regla: primero el modelo de contenido, luego templates/design system, luego páginas, home al final (la home se compone de lo que ya existe).

## Fase 3 — Persistencia (cada cosa en su memoria)

**El plan vive en el alcance del sitio, en Kodavio, y en ningún otro sitio.** Así lo lee cualquier agente que entre después, desde cualquier herramienta. `sites/{slug}/NOTAS.md` guarda decisiones y rarezas del sitio, no el plan.

- **Alcance y cola de construcción** → `kodavio/scope-write` (`mode=merge`, `dry_run` primero). Forma verificada contra el plugin el 2026-09-17:
  - `project`: `brief`, `audience`, `goals`.
  - `strategy`: `positioning`, `primary_conversion`, `builder_preference`, `commerce`, `lead_generation`.
  - `sitemap.pages[]`, una por página en orden de construcción: `title`, `slug`, `purpose`, `priority` (`mvp` / `fase-2`), `status` (`pendiente` → `draft` → `aprobada` → `publicada`), `builder`, `post_id` (cuando exista), `notes`. El patrón de composición y las dependencias se guardan tal cual (acaban en `meta.pattern` y `meta.depends_on`).
  - `content_plan`: `global_components`, `forms`, `backlog`.
  - `build_state.next_actions`: lo siguiente, en orden.
- **Dirección de diseño** → `kodavio/design-write` (lenguaje visual del sitio). Tokens → cadena de `wp-tailwind-windpress`.
- **Read-back**: `kodavio/scope-read` y comprobar que las páginas y sus estados están. Un plan no guardado no existe.

## Fase 4 — Ejecución

Por cada página del plan:

1. `wp-site-session`, y `kodavio/site-build-next-step` para ver qué toca (lo razona con alcance, memoria de diseño, huecos y riesgo). `kodavio/scope-gap-analysis` (`focus=pages`) lista lo que el alcance tiene y el sitio aún no.
2. `wp-page-build` con el encargo de esa página (su `purpose`, `notes` y patrón).
3. Verificación.
4. `kodavio/scope-write`: `status` y `post_id` de la página, y `build_state.next_actions` al día.

Una página aprobada por sesión vale más que cinco a medias. **Cambio de alcance a mitad → `scope-write` primero, construir después**; nunca al revés.

## Anti-patrones

- Construir la home primero.
- Plan de 20 páginas para un negocio que necesita 5.
- Discovery infinito: si el usuario no sabe responder algo, propón tú un default sensato y márcalo como "asunción a validar".
- Páginas con loops dinámicos planificadas antes que su CPT.
