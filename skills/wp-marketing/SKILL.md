---
name: wp-marketing
description: Planificación de marketing digital sobre WordPress — embudo de captación, secuencias de email, CRO de landing, campañas con FluentCRM/FluentForms/WooCommerce, contenido pilar y medición. Genera plan accionable, no campañas creativas.
---

# wp-marketing — Planificación de marketing sobre WordPress

Skill de **planificación**: convierte un objetivo de negocio en un plan ejecutable encima del stack Kodavio + Fluent + Woo. **No mueve datos** (CRM, automatizaciones, audiencias) — el agente operativo lo hace después siguiendo el plan.

## Cuándo arrancarla

- Pide *"montar embudo de captación"*, *"plan de email para Black Friday"*, *"mejorar conversión de esta landing"*, *"campaña de lanzamiento"*, *"qué hago con la lista que tengo abandonada"*.
- También para **diagnóstico CRO**: la landing existe, el tráfico viene, las ventas no llegan → esta skill propone hipótesis y experimentos antes de tocar nada.
- Si la petición es **sólo escribir texto** de una landing → `wp-copywriting`. Esta cubre el plan; aquella el copy.

## Fase 0 — Contexto

1. `wp-site-session` ejecutado.
2. `kodavio/workflow-router` con la petición.
3. `kodavio/context-bootstrap` — scope (audiencia, oferta), sistema de diseño, memoria vinculante. Cualquier `caveat` de tono, naming, restricciones legales (RGPD, sectores regulados) → vinculante.
4. **Inventario**: qué hay vivo en el sitio.
   - FluentCRM presente → `mcp__fluentcrm__fluentcrm_list_lists/tags/automations` para saber con qué cuentas.
   - FluentForms / Gravity / Fluent Booking → puntos de entrada de leads.
   - WooCommerce → catálogo, pedidos, abandono de carrito.
   - Analytics: si hay datos de tráfico/conversión, pídelos al operador (no inventes).
5. **NO escribir nada todavía**. El plan se decide antes de cualquier write.

## Fase 1 — Diagnóstico

Antes del plan, alinea expectativas con realidad:

1. **Objetivo medible** (no "más ventas"): "captar 50 leads cualificados/mes para servicio X" o "subir conversión de landing Y del 1,4% al 2,5%".
2. **Etapa del embudo donde está el cuello de botella** (lo más común que el operador NO ha mirado):
   - Tráfico bajo → problema de captación.
   - Tráfico alto + bounce alto → problema de promesa / fit landing↔ad.
   - Tráfico OK + conversión baja → problema de copy/CTA/fricción del form.
   - Conversión OK + LTV bajo → problema de retención/secuencia post-venta.
3. **Recursos reales** (presupuesto ads, tiempo del operador para escribir, lista actual y su salud, herramientas activas). No propongas plan de 20h/sem si el operador tiene 2h.

Si falta diagnóstico (no hay datos), **arranca por experimentos baratos** (test de copy, ad mínima, encuesta a 10 clientes) antes de plan grande.

## Fase 2 — Plan accionable

Estructura tipo (adapta por caso):

### Captación
- Canales (ads, SEO, partners, referrals) con prioridad y por qué.
- Activos a construir (landings, lead magnets, posts pilar).
- Métrica de éxito por canal y umbral mínimo para seguir o cortar.

### Conversión
- Landings/CTAs a tocar (con prioridad por impacto vs esfuerzo).
- Hipótesis de cambio (no "rediseña la landing"; "cambiar la promesa del hero a X y medir 2 semanas").
- Cómo se mide cada hipótesis.

### Nutrición / Retención
- Secuencias FluentCRM con **objetivo concreto** por email (no "newsletter semanal porque sí").
- Tags y listas necesarias.
- Triggers (formulario X, compra Y, abandono Z).

### Medición
- Eventos a trackear (FluentAnalytics o el que tenga el sitio).
- Reporte semanal/mensual y qué se mira.
- Criterio de parar / pivotar.

## Fase 3 — Reglas duras

1. **Nada se "lanza" sin haberlo medido antes**: cada experimento tiene métrica de éxito y duración mínima.
2. **No dispares automatizaciones sin probar el flujo**: enviarse uno mismo a la lista primero, luego pilotar con 50 contactos.
3. **RGPD / consentimiento**: si la lista no tiene consent claro, **no enviar**. Plantea limpieza antes.
4. **No prometer lo que el equipo no puede entregar**: si vendes "respuesta en 1h" pero solo hay alguien de 9 a 14, no lo prometas.
5. **No mezclar listas frías y calientes** en la misma secuencia.
6. **Producción = Human Gate** para campañas que se envíen a >100 contactos o que toquen ofertas activas.

## Fase 4 — Entrega operativa

El plan termina como **lista de tareas concretas** para el agente operativo (`wp-content-publish`, `wp-page-build`, los MCPs de FluentCRM/Forms/Cart):

```
P1 — Captación
  - [ ] Crear landing servicio X (wp-page-build, copy de wp-copywriting)
  - [ ] Lead magnet "Guía de Y" (wp-content-publish + form FluentForms)
  - [ ] Lista FluentCRM "leads_servicio_x" + tag entrada
P2 — Conversión
  - [ ] Test A/B copy hero landing Z (variant via Bricks template + traffic split)
  - [ ] Reducir campos del form de 7 a 3
P3 — Nutrición
  - [ ] Secuencia 5 emails (email 1: bienvenida + entrega lead magnet; email 2-3: casos; ...)
```

Cada tarea debe estar **lista para que otro agente la coja sin contexto adicional**.

## Cierre

- `kodavio/memory-write` con `source=agent`, `type=decision`, key tipo `marketing/plan-q3-2026`, con: objetivo, canales priorizados, hipótesis activas, métrica de éxito, fecha de revisión. La próxima sesión hereda el plan vivo y sus métricas.
- Cualquier decisión narrativa vinculante para futuras campañas (ej: "no usamos descuentos por defecto") → entry con `tag=instruction`.
