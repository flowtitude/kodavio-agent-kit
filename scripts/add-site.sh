#!/usr/bin/env bash
# add-site.sh — alta interactiva de un sitio WordPress en el kit.
# Crea la entrada en registry/sites.json, la memoria sites/{slug}/NOTAS.md
# y muestra (u opcionalmente registra) la config MCP. Sin credenciales en disco.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="$ROOT/registry/sites.json"
EXAMPLE="$ROOT/registry/sites.example.json"
TEMPLATE="$ROOT/sites/_template/NOTAS.md"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ask()  { local v; read -r -p "$1" v; echo "$v"; }

bold "── Kodavio Agent Kit · alta de sitio ──"

url=$(ask "URL del sitio (https://...): ")
url="${url%/}/"
case "$url" in https://*) ;; *) echo "✖ La URL debe empezar por https://"; exit 1;; esac

domain=$(echo "$url" | sed -E 's#https://([^/]+)/?.*#\1#')
slug_default=$(echo "$domain" | sed 's/^www\.//; s/[.-]/_/g')
slug=$(ask "Slug [${slug_default}]: "); slug="${slug:-$slug_default}"

name=$(ask "Nombre del sitio/cliente: ")

env=""
while [ -z "$env" ]; do
  e=$(ask "Entorno (1=production 2=staging 3=development): ")
  case "$e" in 1) env=production;; 2) env=staging;; 3) env=development;; *) echo "  elige 1, 2 o 3";; esac
done

client=$(ask "Identificador de cliente (vacío si no aplica): ")
builder=$(ask "Builder principal (bricks/elementor/gutenberg/desconocido) [desconocido]: ")
builder="${builder:-desconocido}"
language=$(ask "Idioma del sitio (es_ES, en_US...) [es_ES]: "); language="${language:-es_ES}"

echo
bold "Comprobando endpoint Kodavio..."
endpoint="${url}wp-json/mcp/kodavio"
http=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$endpoint" || echo "000")
case "$http" in
  200|401|403) echo "✔ Kodavio responde en $endpoint (HTTP $http)";;
  404) echo "⚠ HTTP 404 — Kodavio no parece instalado. Instálalo y reactiva las AI abilities (skill wp-onboard-site)."; ;;
  *)   echo "⚠ Sin respuesta válida (HTTP $http). Verifica la URL o la conectividad."; ;;
esac

[ -f "$REGISTRY" ] || { cp "$EXAMPLE" "$REGISTRY"; python3 - "$REGISTRY" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p)); d['sites']=[]
json.dump(d,open(p,'w'),indent=2,ensure_ascii=False)
PY
echo "✔ registry/sites.json creado desde la plantilla (vacío)"; }

SLUG="$slug" NAME="$name" URL="$url" ENV="$env" CLIENT="$client" BUILDER="$builder" LANG_SITE="$language" \
python3 - "$REGISTRY" <<'PY'
import json, os, sys
p = sys.argv[1]
d = json.load(open(p))
slug = os.environ['SLUG']
if any(s.get('slug') == slug for s in d.get('sites', [])):
    print(f"✖ Ya existe un sitio con slug '{slug}' en sites.json"); sys.exit(1)
client = os.environ['CLIENT'] or None
builder = os.environ['BUILDER']
d.setdefault('sites', []).append({
    "slug": slug,
    "name": os.environ['NAME'],
    "url": os.environ['URL'],
    "env": os.environ['ENV'],
    "guardrails": os.environ['ENV'],
    "client": client,
    "playbook": None,
    "mcp_servers": {"kodavio": slug},
    "builder": None if builder == 'desconocido' else builder,
    "theme": None,
    "stack": [],
    "language": os.environ['LANG_SITE'],
    "notes": f"sites/{slug}/NOTAS.md",
    "caveats": ["Completar tras el primer kodavio/wp-get-config-summary real"],
    "verified": None
})
json.dump(d, open(p, 'w'), indent=2, ensure_ascii=False)
open(p, 'a').write('\n')
print(f"✔ '{slug}' añadido a registry/sites.json (env={os.environ['ENV']})")
PY

if [ ! -d "$ROOT/sites/$slug" ]; then
  mkdir -p "$ROOT/sites/$slug"
  sed "s/{nombre del sitio}/$name/" "$TEMPLATE" > "$ROOT/sites/$slug/NOTAS.md"
  echo "✔ sites/$slug/NOTAS.md creado desde la plantilla"
fi

echo
bold "── Conexión MCP ──"
echo "Usuario de aplicación dedicado + Application Password desde wp-admin → Kodavio → Setup."
echo "Plantillas para Cursor/Codex/OpenCode: docs/mcp-config-examples.md"
echo
reg=$(ask "¿Registrar ahora en Claude Code con 'claude mcp add'? (s/N): ")
if [ "${reg:-n}" = "s" ] || [ "${reg:-n}" = "S" ]; then
  wpuser=$(ask "Usuario WP del agente: ")
  read -r -s -p "Application Password (no se mostrará): " wppass; echo
  claude mcp add "$slug" --scope user \
    --env WP_API_URL="$endpoint" \
    --env WP_API_USERNAME="$wpuser" \
    --env WP_API_PASSWORD="$wppass" \
    -- npx -y @automattic/mcp-wordpress-remote@latest \
    && echo "✔ MCP '$slug' registrado. Reinicia el agente para que lo cargue."
else
  cat <<EOF
Comando para cuando tengas la credencial:

  claude mcp add $slug --scope user \\
    --env WP_API_URL="$endpoint" \\
    --env WP_API_USERNAME="<usuario>" \\
    --env WP_API_PASSWORD="<app-password>" \\
    -- npx -y @automattic/mcp-wordpress-remote@latest
EOF
fi

echo
bold "── Siguientes pasos ──"
echo "1. Reinicia el agente y verifica: kodavio/wp-get-config-summary del server '$slug'."
echo "2. Completa builder/theme/stack/caveats en registry/sites.json con los datos reales."
echo "3. Rellena la ficha de sites/$slug/NOTAS.md (backups del hosting incluidos)."
echo "4. Checklist de seguridad del alta: skill wp-onboard-site, sección 4."
