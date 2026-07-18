---
name: wp-site-plan
description: Planificación de un sitio o rediseño completo ANTES de construir - discovery, sitemap, modelo de contenido, dirección de diseño y cola de briefs por página. Produce un plan aprobable que luego ejecuta wp-page-build página a página. Usar para sitios nuevos, rediseños o cuando el encargo es "hazme la web".
---

# wp-site-plan — Planificar antes de construir

> Recorre las fases canónicas (`rules/skill-phases.md`) y ejecuta por **rol**, prefiriendo la ability nativa cuando exista, envuelta en el gate de Kodavio (`rules/ability-source-agnostic.md`).

El antídoto contra "ve construyendo y ya veremos": un plan corto, aprobado por el humano, que convierte un encargo difuso en una cola de tareas precisas. **Nada se construye hasta que el plan tiene OK.**

## Fase 1 — Discovery (entrevista única)

Pregunta en una sola tanda lo que no sepas ya (revisa antes `kodavio/scope-read` y el sistema de diseño — rol *orientar diseño* → nativa `bricks/get-design-context` o `kodavio/design-read` — quizá el sitio ya tiene scope):

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

- Scope (audiencia, sitemap, ofertas, integraciones) → memoria Kodavio del sitio si hay ability de escritura disponible; si no, anotado para volcarlo.
- Dirección de diseño → `kodavio/design-write` (lenguaje visual del sitio).
- La cola de trabajo → `sites/{slug}/PLAN.md` (local): checklist de páginas con estado (pendiente/draft/aprobada/publicada). Es el backlog operativo del sitio; se actualiza en cada sesión.

## Fase 4 — Ejecución

Por cada ítem de la cola: `wp-site-session` → `wp-page-build` con el brief del plan → verificación → marcar en PLAN.md. Una página aprobada por sesión vale más que cinco a medias. Cambios de alcance a mitad → se actualiza el plan primero (y el scope en Kodavio), no se improvisa.

## Anti-patrones

- Construir la home primero.
- Plan de 20 páginas para un negocio que necesita 5.
- Discovery infinito: si el usuario no sabe responder algo, propón tú un default sensato y márcalo como "asunción a validar".
- Páginas con loops dinámicos planificadas antes que su CPT.
