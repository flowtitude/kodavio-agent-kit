#!/usr/bin/env bash
#
# skills-externas.sh — instala y actualiza los paquetes de skills de terceros que usa el kit.
#
# Hoy solo el de Bricks (github.com/codeerhq/bricks-skills). NO se copian dentro del kit:
# se instalan desde su fuente y se enlazan, para que la versión sea la suya y se actualice
# con un comando. Las skills que un plugin trae dentro del sitio (CrocoBuilder) no pasan por
# aquí: las sirve Kodavio con skill-get, y así siempre coinciden con el plugin instalado.
#
# Uso:
#   scripts/skills-externas.sh estado        # qué hay instalado y en qué versión
#   scripts/skills-externas.sh instalar      # clona lo que falte y lo enlaza
#   scripts/skills-externas.sh actualizar    # pasa el actualizador propio de cada paquete
#
# Un paquete solo se instala si algún sitio de registry/sites.json usa su stack (bricks).
# Con --forzar se instala igual.

set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFIESTO="$KIT/registry/skills-externas.json"
ACCION="${1:-estado}"
FORZAR=0
[[ "${2:-}" == "--forzar" || "${1:-}" == "--forzar" ]] && FORZAR=1
[[ "$ACCION" == "--forzar" ]] && ACCION="estado"

[[ -f "$MANIFIESTO" ]] || { echo "[skills] ERROR: falta $MANIFIESTO" >&2; exit 1; }
command -v python3 >/dev/null || { echo "[skills] ERROR: hace falta python3 para leer el manifiesto" >&2; exit 1; }

campos() {  # $1 = id del paquete -> una línea por campo, en orden
  python3 - "$MANIFIESTO" "$1" <<'PY'
import json, sys
manifiesto, buscado = sys.argv[1], sys.argv[2]
for p in json.load(open(manifiesto))['paquetes']:
    if p['id'] == buscado:
        for clave in ('nombre', 'repo', 'requiere_stack', 'instalar_en', 'script_actualizar', 'carpeta_skills', 'prefijo', 'enlazar_en'):
            print(p.get(clave, ''))
PY
}

ids() {
  python3 - "$MANIFIESTO" <<'PY'
import json, sys
for p in json.load(open(sys.argv[1]))['paquetes']:
    print(p['id'])
PY
}

stack_en_uso() {  # $1 = stack
  local sitios="$KIT/registry/sites.json"
  [[ -f "$sitios" ]] || return 1
  python3 - "$sitios" "$1" <<'PY'
import json, sys
try:
    datos = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
sitios = datos.get('sites', datos if isinstance(datos, list) else [])
sys.exit(0 if any(sys.argv[2] in (s.get('stack') or []) or s.get('builder') == sys.argv[2] for s in sitios) else 1)
PY
}

expandir() { echo "${1/#\~/$HOME}"; }

for id in $(ids); do
  IFS=$'\n' read -r -d '' nombre repo stack destino actualizador carpeta prefijo enlaces < <(campos "$id"; printf '\0')
  destino="$(expandir "$destino")"
  enlaces="$(expandir "$enlaces")"

  instalado="no"
  version="—"
  if [[ -d "$destino" ]]; then
    instalado="sí"
    version="$(git -C "$destino" describe --tags --always 2>/dev/null || echo '?')"
  fi
  cuantas=0
  [[ -d "$destino/$carpeta" ]] && cuantas=$(find "$destino/$carpeta" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')

  case "$ACCION" in
    estado)
      echo "▸ $nombre ($id)"
      echo "   instalado: $instalado · versión: $version · skills: $cuantas"
      echo "   origen:    $repo"
      echo "   ruta:      $destino"
      if stack_en_uso "$stack"; then
        echo "   lo usas:   sí (algún sitio del registro usa $stack)"
      else
        echo "   lo usas:   no hay ningún sitio con $stack en el registro"
      fi
      ;;

    instalar|actualizar)
      if ! stack_en_uso "$stack" && [[ $FORZAR -eq 0 ]]; then
        echo "[skills] $id: ningún sitio del registro usa $stack — me lo salto (--forzar para instalarlo igual)"
        continue
      fi
      command -v git >/dev/null || { echo "[skills] ERROR: hace falta git" >&2; exit 1; }

      if [[ ! -d "$destino" ]]; then
        echo "[skills] $id: clonando en $destino"
        mkdir -p "$(dirname "$destino")"
        git clone --quiet "$repo" "$destino"
      fi

      if [[ -x "$destino/$actualizador" ]]; then
        echo "[skills] $id: pasando su actualizador ($actualizador)"
        "$destino/$actualizador"
      else
        echo "[skills] $id: sin actualizador propio ejecutable; dejo el clon como está" >&2
      fi

      mkdir -p "$enlaces"
      puestos=0
      for skill in "$destino/$carpeta/$prefijo"*; do
        [[ -d "$skill" ]] || continue
        ln -sfn "$skill" "$enlaces/$(basename "$skill")"
        puestos=$((puestos + 1))
      done
      echo "[skills] $id: $puestos skills enlazadas en $enlaces · versión $(git -C "$destino" describe --tags --always 2>/dev/null || echo '?')"
      echo "[skills] Las reglas de este kit mandan sobre lo que digan estas skills (rules/ability-source-agnostic.md)."
      ;;

    *)
      echo "[skills] acción desconocida: $ACCION (estado | instalar | actualizar)" >&2
      exit 2
      ;;
  esac
done
