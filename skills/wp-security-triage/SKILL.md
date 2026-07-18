---
name: wp-security-triage
description: Triage de seguridad de un sitio WordPress - sospecha de infección, hardening post-incidente o auditoría preventiva. Combina Kodavio (read-only) con el MCP wp-malware-cleanup y el protocolo de brechas del Playbook.
---

# wp-security-triage — Seguridad

> Recorre las fases canónicas (`rules/skill-phases.md`). Read-only + MCP wp-malware-cleanup; ejecuta por **rol** donde aplique (`rules/ability-source-agnostic.md`).

> Lección aprendida en incidentes reales: limpiar sin cerrar el vector ni rotar credenciales = reinfección garantizada. Auditoría de código estática → skill global `wp-security-audit`.

## Triage (read-only primero)

1. `wp-site-session` hecho. Si hay infección activa, Kodavio puede estar comprometido también: preferir SSH/FS directo (MCP `wp-malware-cleanup`) para inspección.
2. Señales: usuarios admin no reconocidos (`wp-list-users` o WP-CLI), plugins/mu-plugins desconocidos, archivos PHP recientes en `uploads/`, cron jobs raros, `.htaccess` modificado, redirects en frontend, change log de Kodavio con escrituras no nuestras.
3. Con el MCP `wp-malware-cleanup`: escaneo de patrones (backdoors tipo clone-admin, eval/base64, webshells).
4. Clasificar: limpio / sospechoso / comprometido. Comprometido → abrir alerta OPS y avisar YA, antes de limpiar.

## Si está comprometido — orden de actuación

1. **Contener**: nada de limpiar a medias. Snapshot/backup del estado infectado (evidencia) primero.
2. Rotar credenciales: WP admins, application passwords (incluida la de Kodavio), SFTP/SSH, DB. Las viejas se consideran quemadas.
3. Limpiar con `wp-malware-cleanup` + verificación manual de los hallazgos (cada archivo antes de borrar = confirmar que es malicioso; borrar = gate).
4. Buscar el **vector** (plugin vulnerable, credencial robada, sitio vecino en el mismo hosting) — limpiar sin cerrar el vector = reinfección.
5. Hardening: updates, `DISALLOW_FILE_EDIT`, eliminar usuarios/keys sobrantes, revisar permisos FS.
6. Vigilancia: re-escaneo a las 48h y a la semana (proponer tarea OPS programada).

## Preventivo (sitio sano)

Checklist corto: updates al día, usuarios mínimos, application passwords con rol mínimo, backups restaurables probados, `WP_DEBUG` off, login protegido. Resultado → informe + `sites/{slug}/NOTAS.md`.

## Gates

Todo lo destructivo (borrar archivos, usuarios, rotar credenciales de cliente) = **Human Gate** + `sensitive-actions-log`. Comunicar al cliente → `client-comms.md`, sin alarmismo y sin tecnicismos.
