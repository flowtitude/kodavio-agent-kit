# Changelog — kodavio-agent-kit

> Qué cambia en cada actualización del kit y, sobre todo, **si tienes que migrar algo local**
> (`registry/sites.json`, `sites/{slug}/`). Si una entrada no dice "migración", `git pull` basta.

## 2026-06-12

### Añadido
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
