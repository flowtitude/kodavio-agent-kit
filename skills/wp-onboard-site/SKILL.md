---
name: wp-onboard-site
description: Alta de un sitio WordPress nuevo en el sistema - instalar/verificar Kodavio, registrar el MCP en Claude/Cursor/Codex/OpenCode, crear entrada en sites.json y memoria del sitio.
---

# wp-onboard-site — Conectar un sitio nuevo

Entrada necesaria: URL del sitio, entorno real (production/staging/development), cliente (si aplica) y acceso wp-admin o credencial de aplicación.

## 1. Plugin Kodavio en el sitio

1. Verificar si Kodavio ya está instalado: probar `{url}/wp-json/mcp/kodavio` (401/200 = existe; 404 = falta).
2. Si falta: instalarlo desde el ZIP de release oficial de Kodavio (GitHub Release / canal de distribución de la beta). Instalar plugin en producción = **Human Gate**.
3. En wp-admin → Kodavio: activar AI abilities y generar **Application Password** dedicada (usuario propio para el agente, no el admin personal). PHP editing: dejar OFF salvo necesidad.
4. La credencial va al **access store** del proyecto/cliente. Nunca a disco ni a este repo.

## 2. Registrar el MCP en cada agente

Slug = dominio con underscores (`example_com`, sufijo `_staging`/`_dev` si aplica). Server tipo HTTP vía proxy npx (mismo patrón que los sitios existentes — copiar la forma exacta de una entrada viva de `~/.claude.json` antes de inventar argumentos):

- **Claude Code**: `claude mcp add {slug} ...` (scope user) o editar `~/.claude.json`.
- **Cursor**: `.cursor/mcp.json` del workspace.
- **Codex**: `~/.codex/config.toml` → `[mcp_servers.{slug}]`.
- **OpenCode**: `opencode.json` → bloque `mcp`.

Registrar solo en las herramientas que el usuario use para ese sitio; mínimo Claude Code. Tras añadir: reiniciar el agente y verificar con `kodavio/wp-get-config-summary`.

## 3. Registro y memoria

1. Añadir entrada en `registry/sites.json` (esquema en `_meta`): env, guardrails, builder, theme, language, caveats. Rellenar con datos del config-summary real, no de memoria.
2. Crear `sites/{slug}/NOTAS.md` desde `sites/_template/NOTAS.md`.
3. Si es cliente nuevo sin Playbook → avisar: falta `Playbook/clients/{cliente}/HANDBOOK.md`.
4. Smoke test read-only: `kodavio/capability-map` + `kodavio/skill-list` + listar 3 páginas. Anotar resultado en NOTAS.md.

## 4. Checklist de seguridad del alta

- [ ] Usuario de aplicación dedicado con rol mínimo viable (editor si solo contenido).
- [ ] `php_lint_available` comprobado → si false, caveat "no PHP" en sites.json.
- [ ] Backups del hosting verificados ANTES de la primera escritura (¿hay snapshot diario? ¿restore probado?).
- [ ] Si producción: confirmar con el humano qué operaciones quedan permitidas por defecto.
