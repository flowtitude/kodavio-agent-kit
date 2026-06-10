---
name: wp-site-health
description: Revisión de salud y mantenimiento de un sitio WordPress en vivo - updates pendientes, errores, rendimiento, seguridad básica y limpieza. Genera informe y plan; los updates en producción son gate.
---

# wp-site-health — Salud y mantenimiento

Flujo Kodavio: `diagnostic_audit` (read-only) + `wordpress_admin` para aplicar. Playbook servidor: `wordpress-admin-safe`.

## Auditoría (read-only, sin gates)

1. `wp-site-session` hecho.
2. `kodavio/wp-get-config-summary` → versiones WP/PHP/DB, debug flags, memoria, `beta_readiness`.
3. Plugins: `kodavio/wp-list-plugins` → updates pendientes, plugins inactivos acumulados, abandonados (sin update >1 año), duplicados de función.
4. `kodavio/wp-get-change-log` → qué ha pasado últimamente en el sitio.
5. Contenido basura: revisiones masivas, spam comments, transients, drafts antiguos, media huérfana.
6. Frontend: home y 2-3 páginas clave → 200, tiempos razonables, sin errores JS/PHP visibles, mixed content.
7. Flags de riesgo: `WP_DEBUG` en producción, `disallow_file_edit=false`, usuarios admin sospechosos, ¿backups del hosting funcionando?

## Informe

Tabla corta: hallazgo / riesgo (alto-medio-bajo) / acción propuesta / ¿gate?. Lenguaje no técnico si va al cliente (`client-comms.md`).

## Aplicación

- dev/staging: aplicar updates con dry-run, de uno en uno, verificando frontend tras cada plugin mayor.
- **producción**: cada update/limpieza = **Human Gate** + `sensitive-actions-log`. Orden: backup verificado → plugins menores → plugins mayores → tema → core. Tras cada paso: smoke test frontend + admin.
- Si un update rompe algo: rollback inmediato (backup/versión anterior), anotar el plugin en `sites/{slug}/NOTAS.md` como "no auto-actualizar".

## Recurrencia

Sitio con mantenimiento contratado → proponer tarea OPS recurrente, no archivo. Hallazgos de seguridad serios → cambiar a `wp-security-triage`.
