# NOTAS — {nombre del sitio}

> Memoria operativa del sitio. La lee `wp-site-session` al arrancar. Una entrada por sesión de trabajo relevante; lo estructural arriba, el log abajo.

## Ficha

- URL:
- Entorno: production | staging | development
- Cliente / Playbook:
- Builder + theme:
- Stack relevante (SEO plugin, forms, Woo, CRM…):
- Acceso: (referencia al access store, NUNCA credenciales aquí)
- Backups del hosting: (¿hay? ¿probado restore? ¿frecuencia?)
- Kodavio: versión del plugin + fecha del último `capability-map` (¿expone abilities nativas del builder?)

## Prohibiciones y caveats vinculantes

- (p. ej. "no PHP vía Kodavio: lint no disponible", "no auto-actualizar plugin X", "no tocar la home sin OK del cliente")

## Decisiones y peculiaridades

- (decisiones de diseño/arquitectura del sitio que un agente nuevo debe conocer)

## Verificación

> **Contrato de cierre** (`rules/production-guardrails.md` invariante 4). Un write en producción **no puede declararse PASS** sin una entrada aquí, escrita por el pase de `wp-verifier` — que no es quien escribió. Sin entrada, la tarea queda `in_progress`.

### YYYY-MM-DD HH:MM — {qué se verificó}

- **Escrito por:** (agente/persona) · **Verificado por:** (pase separado)
- **Read-back:** qué se releyó y con qué IDs (page/post/template, node_ids tocados)
- **Salud:** frontend 200 · editor abre limpio · encoding (acentos/ñ) intacto
- **Fidelidad al brief:** desviaciones encontradas (o "ninguna")
- **Rollback:** snapshot/backup ID + cómo se revierte en una línea
- **Veredicto:** PASS | PASS con avisos | FAIL — y, si FAIL, qué se hizo

## Log de sesiones

### YYYY-MM-DD
- Qué se hizo, IDs de backup/snapshot, gates aprobados, sorpresas.
