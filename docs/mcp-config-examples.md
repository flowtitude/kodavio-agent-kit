# Plantillas de conexión MCP por agente

> Cómo registrar un sitio WordPress con Kodavio como server MCP en cada herramienta.
> Convención de slug: dominio con underscores (`example_com`), sufijo `_staging` / `_dev` si aplica.
> Endpoint preferido: `https://{dominio}/wp-json/mcp/kodavio` (alias legacy: `/wp-json/mcp/mcp-adapter-default-server`).
> Proxy stdio→HTTP: [`@automattic/mcp-wordpress-remote`](https://www.npmjs.com/package/@automattic/mcp-wordpress-remote). Versión **pineada** (`@0.3.4`), no `@latest`: este proceso recibe las credenciales de tus sitios — actualiza la versión a conciencia, no automáticamente.

⚠ **Credenciales**: usuario de aplicación dedicado al agente + Application Password generada desde Kodavio (wp-admin → Kodavio → Setup). Estas configs viven en tu máquina, fuera de este repo. No las pegues en ningún archivo versionado.

> 🔐 Las plantillas de abajo dejan la password **en claro** en el archivo de config de tu herramienta. Para evitarlo (recomendado), usa el lanzador multiplataforma del kit con el almacén de secretos del SO: [credentials.md](credentials.md).

## Claude Code

CLI (scope user — disponible en todos los proyectos):

```bash
claude mcp add example_com --scope user \
  --env WP_API_URL="https://example.com/wp-json/mcp/kodavio" \
  --env WP_API_USERNAME="agente-ia" \
  --env WP_API_PASSWORD="xxxx xxxx xxxx xxxx xxxx xxxx" \
  -- npx -y @automattic/mcp-wordpress-remote@0.3.4
```

O a mano en `~/.claude.json` → `mcpServers`:

```json
"example_com": {
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@automattic/mcp-wordpress-remote@0.3.4"],
  "env": {
    "WP_API_URL": "https://example.com/wp-json/mcp/kodavio",
    "WP_API_USERNAME": "agente-ia",
    "WP_API_PASSWORD": "xxxx xxxx xxxx xxxx xxxx xxxx"
  }
}
```

## Cursor

`.cursor/mcp.json` (este archivo está en `.gitignore`) o `~/.cursor/mcp.json` (global):

```json
{
  "mcpServers": {
    "example_com": {
      "command": "npx",
      "args": ["-y", "@automattic/mcp-wordpress-remote@0.3.4"],
      "env": {
        "WP_API_URL": "https://example.com/wp-json/mcp/kodavio",
        "WP_API_USERNAME": "agente-ia",
        "WP_API_PASSWORD": "xxxx xxxx xxxx xxxx xxxx xxxx"
      }
    }
  }
}
```

## Codex

`~/.codex/config.toml`:

```toml
[mcp_servers.example_com]
command = "npx"
args = ["-y", "@automattic/mcp-wordpress-remote@0.3.4"]

[mcp_servers.example_com.env]
WP_API_URL = "https://example.com/wp-json/mcp/kodavio"
WP_API_USERNAME = "agente-ia"
WP_API_PASSWORD = "xxxx xxxx xxxx xxxx xxxx xxxx"
```

## OpenCode

`opencode.json` (global en `~/.config/opencode/` o del proyecto):

```json
{
  "mcp": {
    "example_com": {
      "type": "local",
      "command": ["npx", "-y", "@automattic/mcp-wordpress-remote@0.3.4"],
      "environment": {
        "WP_API_URL": "https://example.com/wp-json/mcp/kodavio",
        "WP_API_USERNAME": "agente-ia",
        "WP_API_PASSWORD": "xxxx xxxx xxxx xxxx xxxx xxxx"
      }
    }
  }
}
```

## Kilo Code

Kilo lee `AGENTS.md` y las skills (`.claude/skills/`, estándar Agent Skills) sin configuración extra. Los servers MCP van bajo la clave `mcp` de `kilo.jsonc` — **usa el global** `~/.config/kilo/kilo.jsonc` para que la credencial no caiga en el árbol del proyecto (el de proyecto, `kilo.jsonc`/`.kilo/`, está en `.gitignore` por si acaso):

```jsonc
// ~/.config/kilo/kilo.jsonc
{
  "mcp": {
    "example_com": {
      "type": "local",
      "command": ["npx", "-y", "@automattic/mcp-wordpress-remote@0.3.4"],
      "environment": {
        "WP_API_URL": "https://example.com/wp-json/mcp/kodavio",
        "WP_API_USERNAME": "agente-ia",
        "WP_API_PASSWORD": "xxxx xxxx xxxx xxxx xxxx xxxx"
      }
    }
  }
}
```

## Verificación (cualquier agente)

Tras añadir el server, **reinicia el agente** y pide:

> Llama a `kodavio/wp-get-config-summary` del server `example_com` y dime versión de WP, builder activo y si `php_lint_available` es true.

Si responde con datos del sitio, la conexión está viva. Completa entonces la entrada en `registry/sites.json` con esos datos reales (skill `wp-onboard-site`).
