#!/usr/bin/env bash
# wp-mcp-launch.sh — lanza el proxy MCP de un sitio leyendo la Application
# Password del almacén de secretos del SO, para que la config de tu agente
# no contenga credenciales en claro. Ver docs/credentials.md.
#
# Uso en la config MCP (cualquier herramienta):
#   command: /ruta/al/kit/scripts/wp-mcp-launch.sh
#   env:     WP_MCP_SLUG, WP_API_URL, WP_API_USERNAME (+ extras no secretos)
#
# Backends, en orden de detección:
#   macOS  → security (Keychain)
#   Linux  → secret-tool (libsecret/GNOME Keyring) → pass(1)
#   Cualquiera → python3 -m keyring (pip install keyring)
#
# --check: resuelve la credencial y sale (0 = OK) sin lanzar el proxy.
set -euo pipefail

slug="${WP_MCP_SLUG:?define WP_MCP_SLUG (slug del sitio en registry/sites.json)}"
service="wp-agent-${slug}"
proxy_version="${WP_MCP_PROXY_VERSION:-0.3.4}"

resolve_password() {
  if command -v security >/dev/null 2>&1; then
    security find-generic-password -s "$service" -w 2>/dev/null && return 0
  fi
  if command -v secret-tool >/dev/null 2>&1; then
    secret-tool lookup service "$service" 2>/dev/null && return 0
  fi
  if command -v pass >/dev/null 2>&1; then
    pass show "mcp/${service}" 2>/dev/null | head -1 && return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 -m keyring get "$service" "${WP_API_USERNAME:-agent}" 2>/dev/null && return 0
  fi
  return 1
}

if ! password="$(resolve_password)" || [ -z "$password" ]; then
  echo "✖ Credencial '$service' no encontrada en ningún almacén (security/secret-tool/pass/python-keyring)." >&2
  echo "  Guárdala primero — comandos por SO en docs/credentials.md." >&2
  exit 1
fi

if [ "${1:-}" = "--check" ]; then
  echo "✔ Credencial '$service' resuelta desde el almacén del SO."
  exit 0
fi

WP_API_PASSWORD="$password" exec npx -y "@automattic/mcp-wordpress-remote@${proxy_version}"
