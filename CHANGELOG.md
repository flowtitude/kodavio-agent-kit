# Changelog — kodavio-agent-kit

> Qué cambia en cada actualización del kit y, sobre todo, **si tienes que migrar algo local**
> (`registry/sites.json`, `sites/{slug}/`). Si una entrada no dice "migración", `git pull` basta.

## 2026-06-26

### Cambiado
- **Orden canónico de llamadas alineado con plugin Kodavio 0.1.8**: ahora `kodavio/workflow-router` → **`kodavio/context-bootstrap`** → `kodavio/skill-get`. El bootstrap recupera scope + sistema de diseño activo + memoria vinculante + últimos cambios en una sola llamada (sustituye a llamar a `scope-read`, `design-read` y `memory-list` por separado). Cualquier entry de memoria con `source=human` + `tag=instruction|caveat` es **vinculante** durante toda la sesión. Antes de cualquier write destructivo, re-revisar `kodavio/memory-list tag=caveat`. Al cerrar la sesión, escribir decisiones load-bearing con `kodavio/memory-write source=agent`. Archivos actualizados: `AGENTS.md`, `rules/kodavio-protocol.md`, `workflows/WORKFLOWS.md`, `skills/wp-site-session/SKILL.md`, `skills/wp-page-build/SKILL.md`. Sin migración necesaria.

### Añadido
- **Skill `wp-copywriting`** — copy comercial de WordPress (landing, home, página de servicio, sobre nosotros, FAQ) en castellano perfecto, anclado al scope del sitio y al sistema de diseño activo. Cubre la voz comercial; el editorial sigue siendo `wp-content-publish`.
- **Skill `wp-marketing`** — plan de marketing digital sobre WordPress: diagnóstico del cuello de botella del embudo, plan accionable de captación/conversión/nutrición, integración con FluentCRM/FluentForms/WooCommerce. Genera lista de tareas concretas para el agente operativo, no campañas creativas.
- **Skill `wp-patterns-author`** — asistente para crear patterns propios para el catálogo de Kodavio (disponible desde el plugin 0.1.8 con la nueva pestaña `Kodavio › Diseño y memoria › Patterns`). Cubre anatomía del spec, tipos de nodos, roles vs literales, plantillas por categoría (hero, CTA, features, pricing, testimonial, FAQ), validación previa, packs import/export entre sitios.
- **Skill `wp-security-cleanup`** — respuesta a incidente de seguridad. Orquesta el MCP propio `wp-malware-cleanup-mcp` (escaneos, cleanup, hardening) junto con las abilities Kodavio de auditoría (admins, change log, plugins/themes) y los human gates del kit. Protocolo en 5 fases con confirmación humana explícita por acción destructiva. Distinto de `wp-security-triage`, que cubre hardening proactivo de un sitio limpio.

### Notas
- Las 4 skills nuevas son markdown puro (formato SKILL.md estándar). No necesitan release del plugin para usarse.
- El plugin 0.1.8 (memoria + pestaña Patterns) y este corte del kit están diseñados para trabajar juntos: probarlos en bloque.

## 2026-06-12

### Añadido
- **Credenciales sin texto plano** (`docs/credentials.md` + `scripts/wp-mcp-launch.sh|.ps1`): lanzador multiplataforma que lee la Application Password del almacén de secretos del SO (Keychain / libsecret / `pass` / Credential Manager / python-keyring) y la inyecta al proxy en el arranque — los archivos de config del agente dejan de contener secretos en macOS, Linux y Windows.
- **Soporte Kilo Code**: Kilo lee `AGENTS.md` y las skills (`.claude/skills/`, estándar Agent Skills) sin configuración. Plantilla MCP (`kilo.jsonc`) en `docs/mcp-config-examples.md`; `kilo.jsonc`/`.kilo/` en `.gitignore`.
- `sites/_template/PLAN.md`: plantilla de la cola de briefs que crea `wp-site-plan`.
- Este CHANGELOG (el README lo prometía para migraciones de esquema).

### Cambiado
- Proxy MCP **pineado a `@automattic/mcp-wordpress-remote@0.3.4`** en todas las plantillas y en `add-site.sh` (antes `@latest`: ese proceso recibe credenciales de los sitios; las subidas de versión se hacen a conciencia). *Recomendado actualizar los servers MCP ya registrados con `@latest` en tu herramienta.*
- `add-site.sh`: el slug por defecto respeta la convención de sufijos (`staging.example.com` → `example_com_staging`); acepta `http://` solo para desarrollo local; mensaje honesto en 401/403 (endpoint protegido ≠ Kodavio confirmado); sin líneas en blanco acumuladas al final de `sites.json`; cabecera aclara dónde acaban las credenciales con `claude mcp add`.
- `agents/wp-auditor.md`: eliminada la whitelist `tools:` — bloqueaba TODAS las herramientas MCP de Kodavio (verificado en vivo: el auditor no podía auditar). El read-only se garantiza por prompt, como en `wp-verifier`.
- `wp-onboard-site`: instalar Kodavio en producción pide confirmación explícita (el contexto del alta no aprueba el gate solo).
- Referencias a la capa SA (`Playbook/*`, skills globales `market-seo`) marcadas como opcionales para cloners.
- README: requisitos completos (python3, symlinks en Windows), conteo real de subagentes (10).

### Sin migración local
Ningún cambio de esquema en `sites.example.json`.

## 2026-06-10

- v1 inicial: AGENTS.md + punteros multi-agente, registro de sitios, 3 reglas duras, 12 skills, 10 subagentes, WORKFLOWS.md, onboarding interactivo (`/wp-onboard-site`) y por terminal (`add-site.sh`).
