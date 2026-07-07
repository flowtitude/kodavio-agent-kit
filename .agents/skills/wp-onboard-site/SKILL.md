---
name: wp-onboard-site
description: Comando interactivo de alta de un sitio WordPress - el agente entrevista al usuario, verifica Kodavio, registra el MCP en su herramienta, crea la entrada en sites.json con datos reales y la memoria del sitio. Invocable como /wp-onboard-site.
---

# wp-onboard-site — Conectar un sitio (comando interactivo)

Este skill ES el comando de alta: el usuario lo invoca (`/wp-onboard-site` en Codex, o "da de alta un sitio" en cualquier agente) y tú lo guías de principio a fin. La alternativa por terminal puro (sin agente) es `scripts/add-site.sh`.

## Fase 1 — Entrevista (una sola tanda de preguntas)

Pregunta TODO junto, no por goteo:

1. URL del sitio.
2. Entorno **operativo**: production / staging / development (explica que esto decide los guardarraíles, no lo que diga WP).
3. Cliente/propietario (o "propio").
4. ¿Kodavio ya instalado, o hay que instalarlo? (si hay que instalarlo: ¿tiene el ZIP y acceso wp-admin?)
5. ¿En qué herramientas registrar el MCP? (Codex / Cursor / Codex / OpenCode / Kilo Code)

## Fase 2 — Verificación del plugin

1. Comprueba el endpoint: `{url}/wp-json/mcp/kodavio` → 200/401/403 = instalado; 404 = falta.
2. Si falta: guía la instalación (Plugins → subir ZIP → activar). En producción, instalar el plugin es **Human Gate**: confirma explícitamente ("¿instalo Kodavio en ESTE production?") antes de guiar — el contexto del alta no lo aprueba solo. Luego: wp-admin → Kodavio → Setup → activar AI abilities. PHP editing: OFF salvo necesidad.
3. Pide al usuario que genere la **Application Password** (usuario dedicado al agente, rol mínimo viable) y recuérdale: la credencial va a su gestor de secretos, nunca a un archivo del kit.

## Fase 3 — Registro MCP

1. Slug = dominio con underscores (+ `_staging`/`_dev`). Plantillas exactas por herramienta: `docs/mcp-config-examples.md`. Ofrece el modo **sin credencial en la config** (`docs/credentials.md`): la password va al almacén de secretos del SO y el server usa `scripts/wp-mcp-launch.sh` — recomendado, multiplataforma.
2. Para Codex puedes ejecutar tú el comando `Codex mcp add {slug} ...` (el usuario pega la credencial cuando se le pida, o la pasa por variable de entorno — nunca la escribas tú en un archivo).
3. Avisa: hay que **reiniciar el agente** para que cargue el server nuevo. Si es esta misma sesión, pide al usuario reiniciar y retomar con `/wp-onboard-site` indicando "continuar alta de {slug}".

## Fase 4 — Alta con datos REALES (tras reinicio)

1. Llama a `kodavio/wp-get-config-summary` del server nuevo. Si responde:
2. Crea/actualiza la entrada en `registry/sites.json` (esquema en `sites.example.json`) **con los datos del config-summary**, no con suposiciones: builder activo, theme, idioma, versión WP/PHP, y caveats detectados (`php_lint_available=false` → caveat "no PHP"; `WP_DEBUG` en prod → caveat).
3. Crea `sites/{slug}/NOTAS.md` desde `sites/_template/` y rellena la ficha con lo aprendido.
4. Marca `verified` con la fecha de hoy.

## Fase 5 — Checklist de cierre (preséntala rellenada)

- [ ] Endpoint Kodavio vivo y MCP respondiendo.
- [ ] Usuario de aplicación dedicado, rol mínimo viable.
- [ ] `env` confirmado por el humano (manda sobre el `environment_type` de WP).
- [ ] `php_lint_available` anotado; si false → caveat "no PHP".
- [ ] Backups del hosting: ¿existen? ¿restore probado? → a NOTAS.md.
- [ ] Acordado con el usuario qué puede hacer el agente sin preguntar en este sitio.
- [ ] Smoke test read-only: `kodavio/capability-map` + listar 3 páginas.

Termina mostrando el resumen del sitio (slug, env, builder, caveats) y el primer paso sugerido: una tarea pequeña con `wp-site-session`.
