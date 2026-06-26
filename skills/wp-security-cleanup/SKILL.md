---
name: wp-security-cleanup
description: Limpieza forense de un sitio WordPress comprometido — orquesta el MCP wp-malware-cleanup-mcp (escaneo + cleanup + hardening) junto con las abilities de Kodavio (auditoría de admins, change log, plugin/theme inspection) y los human gates del kit. NUNCA destructivo sin confirmación humana.
---

# wp-security-cleanup — Sitio hackeado: triage + limpieza + hardening

Skill **operativa de incidente**. Cuando un sitio WordPress está comprometido (malware, webshell, admin oculto, redirecciones SEO, drop-ins maliciosos), esta skill orquesta el MCP propio **`wp-malware-cleanup-mcp`** + las abilities de Kodavio + los gates humanos del kit en un protocolo seguro.

> Esto es **respuesta a incidente** sobre un sitio EN VIVO. No es prevención (eso es `wp-security-triage` para hardening proactivo).

## Cuándo arrancarla

- El operador reporta *"el sitio X está hackeado"*, *"Google marca el sitio como peligroso"*, *"hay PHP raro en uploads"*, *"el sitio redirige a casino/farma"*, *"me han creado un admin que no soy yo"*.
- El operador ha visto **señales claras**: archivos `.php` en `wp-content/uploads/`, drop-ins (`db.php`, `advanced-cache.php`) que no se acuerdan haber instalado, plugins extraños activos, admins desconocidos, change log con cambios fuera de horario.
- Si las señales son inciertas (lentitud, errores intermitentes, plugins legítimos no actualizados) → `wp-site-health` antes que esto.

## Pre-requisitos

1. **MCP `wp-malware-cleanup-mcp` registrado y activo** en tu herramienta. El sitio tiene que estar dado de alta con `wp_add_site` (registro propio del MCP).
2. **Acceso SSH al servidor** del sitio (el MCP opera por SSH+WP-CLI). Si no hay SSH, esta skill **no aplica** — escala al hosting.
3. **`wp-site-session` ejecutado** para tener el contexto local del sitio (NOTAS.md, env, caveats).
4. **Operador disponible** para confirmar gates. **Esta skill no opera sola en producción** — toda acción destructiva requiere confirmación humana explícita en el momento.

## Protocolo de incidente (en orden, sin saltar pasos)

### Fase 0 — Triage de minutos

Antes de tocar nada, qué sé:

1. `kodavio/context-bootstrap` — caveats del sitio en memoria, sistema de diseño activo (no es relevante aquí pero verifica que el sitio responde por MCP).
2. `kodavio/wp-get-config-summary` — versión WP/PHP, plugins activos, debug flags.
3. `kodavio/memory-list tag=caveat` — si hay caveat "este sitio no tiene backups", el plan cambia: **backup ANTES** de todo.
4. **Confirma al operador**: *"Voy a iniciar un escaneo de seguridad sobre {sitio}. Solo lecturas, no se modifica nada todavía. ¿Adelante?"*

### Fase 1 — Escaneo (solo lectura, sin gates)

Con `wp-malware-cleanup-mcp`:

1. `wp_full_scan_verbose` — informe completo. Anota: archivos sospechosos, integridad de core, mu-plugins/drop-ins, admins recientes, app passwords, queries cron sospechosas.
2. `wp_verify_core` — diff vs checksums oficiales de WP. Cualquier alteración en `wp-includes/` o `wp-admin/` es **roja**.
3. `wp_scan_webshells` + `wp_scan_uploads` — `.php` ejecutable bajo `wp-content/uploads/` = inyección.
4. `wp_scan_mu_plugins` + `wp_scan_hidden_plugins` + `wp_scan_suspicious_plugins` — drop-ins no autorizados, plugins ocultos del listado del admin.
5. `wp_scan_hidden_admins` + `wp_list_admins` + `wp_find_recent_users` + `wp_scan_app_passwords` — usuarios creados fuera de protocolo, app passwords no reconocidas.
6. `wp_check_db_injections` + `wp_check_cron_events` — opciones con payload, queries cron que llaman a URLs externas.
7. **Cruce con Kodavio**: `kodavio/wp-get-change-log` para ver writes del agente (descarta falsos positivos) y `kodavio/wp-list-plugins` para validar el listado.

### Fase 2 — Informe + plan (Human Gate)

**Para antes de la limpieza**. Presenta al operador:

- Lista de hallazgos por severidad (crítico / alto / medio / bajo).
- Plan de limpieza propuesto en orden de menor a mayor riesgo:
  1. Backup completo de BD (`wp_backup_database`) **siempre primero**.
  2. Quarantine de archivos infectados (`wp_quarantine_file`, mueve a `quarantine-{date}/` — no borra).
  3. Cleanup de core (`wp_clean_core_injections`).
  4. Limpieza de uploads (`wp_clean_uploads_php`).
  5. Limpieza de DB (`wp_clean_db_spam`, `wp_delete_malware_options`).
  6. Reinstall de core (`wp_reinstall_core`) si la verificación falló.
  7. Reinstall de plugins/themes comprometidos (`wp_reinstall_plugin`, `wp_reinstall_all_plugins`/`themes` solo si el operador confirma).
  8. Rotación de credenciales (`wp_reset_passwords`, `wp_revoke_app_passwords`, `wp_regenerate_salts`).
  9. Hardening (`wp_harden_wpconfig`, `wp_disable_file_editing`, `wp_add_security_htaccess`, `wp_fix_permissions`, `wp_install_security_mu_plugin`).
- Tiempo estimado, riesgo, qué se pierde si algo sale mal.
- **Espera confirmación explícita del operador** ("ok adelante" no es suficiente para destructive — pide *"confirmo cleanup, soy {nombre}"*).

### Fase 3 — Limpieza (gates por bloque)

Una acción destructiva por iteración. Tras cada una:
- `wp_backup_database` antes si toca DB.
- Ejecutar la herramienta del MCP con `confirm=True`.
- **Verificar inmediatamente** con escaneo dirigido a esa área.
- Reportar al operador qué cambió y esperar OK antes del siguiente bloque.

Las herramientas destructivas del MCP emiten **preview manifest** antes de ejecutar — siempre revísalo antes de pasar `confirm=True`.

### Fase 4 — Hardening (último paso, también con gate)

Solo después de limpieza confirmada y verificada:

1. `wp_harden_wpconfig` + `wp_disable_file_editing` — endurece config.
2. `wp_add_security_htaccess` — bloquea ejecución PHP en uploads.
3. `wp_fix_permissions` — permisos correctos en directorios sensibles.
4. `wp_install_security_mu_plugin` — mu-plugin de hardening.
5. `wp_full_harden` solo si el operador lo pide (acumula todo lo anterior).
6. Rotación final de credenciales **incluida la del operador** (avísale antes; no le rotes la contraseña sin avisar).

### Fase 5 — Verificación + cierre

1. `wp_full_scan` re-ejecutado — debe salir limpio.
2. `wp_generate_report` para tener un informe del incidente.
3. **Cierre con el operador**: qué se hizo, qué se rotó, qué quedó pendiente (revisar logs durante N días).
4. Si el sitio es de cliente: prepara el `wp_generate_case_study` (anonymizable) para registro interno; **no se entrega al cliente sin revisión humana**.

## Gates duros (sin excepción)

| Acción | Gate |
|---|---|
| Cualquier acción destructiva del MCP (`confirm=True`) | **Human Gate explícito por acción** |
| Reinstall masivo (all-plugins/all-themes/core) | Human Gate + backup BD previo |
| Reset de credenciales de admins | Human Gate + avisar a cada admin |
| `wp_complete_cleanup` orquestado | **Doble Human Gate** — esta es la herramienta más destructiva del MCP |
| Borrado de mu-plugin sospechoso si Kodavio está activo | Verificar que NO es un mu-plugin de Kodavio antes de borrar |

## Cruces con el resto del kit

- `wp-security-triage` (preexistente) cubre hardening proactivo de un sitio limpio. **Esta skill** cubre el caso de un sitio ya comprometido.
- Si durante la limpieza se descubre que el atacante explotó un plugin específico, registra la versión vulnerable en `Playbook/clients/{cliente}/HANDBOOK.md` (si SA) y en la NOTAS.md del sitio para evitar reincidencia.
- Acción sensible en producción → `Playbook/rules/sensitive-actions-log.md` SIEMPRE.

## Cierre

- `kodavio/memory-write` con `source=agent`, `type=incident`, key `security/incident-{fecha}`, con: vector de entrada (si lo deduces), alcance del compromiso, qué se limpió, qué se hardened, fecha del último escaneo limpio. Vinculante para futuras sesiones.
- Caveat de seguimiento con `tag=caveat`: *"Monitorizar este sitio durante 7 días tras incidente de {fecha}; cualquier write debe revisar memory antes."*. Así el `context-bootstrap` lo trae en cada arranque.
- `sites/{slug}/NOTAS.md` — sección **Incidentes** con detalle local del operador (hostname del servidor, hosting, credenciales rotadas, comunicación con el cliente, factura).

## Lo que NO hace esta skill (por ahora)

- **No abre tickets de policía / centros de cybercrime**. Si el incidente lo requiere (datos personales filtrados, ataque coordinado, ransomware), escala al humano.
- **No notifica a la lista de usuarios afectados** (RGPD breach notification). Esa decisión la toma el responsable del sitio, no el agente.
- **No restaura desde backups antiguos sin auditarlos antes** — el backup puede estar también infectado.
- **No promete que el sitio queda 100% limpio** después de la limpieza. Promete que pasó los escaneos disponibles y que se hizo lo razonable; el sitio queda en monitorización 7 días mínimo.
