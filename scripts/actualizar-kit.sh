#!/usr/bin/env bash
#
# actualizar-kit.sh — actualiza una copia instalada del kit SIN perder lo tuyo.
#
# Tres capas:
#   1. El kit          — se actualiza siempre.
#   2. Lo personal     — sitios, registro, secretos, skills propias, *.local*: no se toca.
#   3. Tus ajustes     — ficheros `*.local.md` junto al original: no se tocan ni se pisan.
#
# Y una red de seguridad: si editaste un fichero DEL KIT (que es lo que la capa 3 existe
# para evitar), no se pisa. La version nueva se deja al lado como `<fichero>.nuevo` y se
# avisa. El rsync --delete de la version anterior de este script se llevaba por delante
# esos cambios sin decir nada — paso de verdad con 88 cambios en sitekit el 17-09-2026.
#
# Uso:
#   scripts/actualizar-kit.sh                      # desde la ultima version publicada en GitHub
#   scripts/actualizar-kit.sh --desde /ruta/kit    # desde un clon local del kit (fuente)
#   scripts/actualizar-kit.sh --ensayo             # dice que haria, sin tocar nada
#   scripts/actualizar-kit.sh --destino /ruta      # copia instalada (por defecto: la del script)
#
# Requiere: bash, rsync, shasum (o sha256sum), y curl+tar si actualizas desde GitHub.

set -euo pipefail

REPO_TARBALL="https://api.github.com/repos/flowtitude/kodavio-agent-kit/tarball"
ORIGEN=""
ENSAYO=0
DESTINO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --desde)   ORIGEN="${2:-}"; shift 2 ;;
    --destino) DESTINO="${2:-}"; shift 2 ;;
    --ensayo)  ENSAYO=1; shift ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    *) echo "[kit] opción desconocida: $1" >&2; exit 2 ;;
  esac
done

[[ -d "$DESTINO" ]] || { echo "[kit] ERROR: no existe el destino $DESTINO" >&2; exit 1; }
DESTINO="$(cd "$DESTINO" && pwd)"

hash_de() {  # $1 = fichero
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
  else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

TEMP="$(mktemp -d)"
trap 'rm -rf "$TEMP"' EXIT

if [[ -n "$ORIGEN" ]]; then
  [[ -d "$ORIGEN" ]] || { echo "[kit] ERROR: no existe el origen $ORIGEN" >&2; exit 1; }
  FUENTE="$(cd "$ORIGEN" && pwd)"
  VERSION="local:$(git -C "$FUENTE" rev-parse --short HEAD 2>/dev/null || echo 'sin git')"
else
  echo "[kit] Descargando la última versión publicada…"
  curl -fsSL "$REPO_TARBALL" -o "$TEMP/kit.tar.gz" || {
    echo "[kit] ERROR: no he podido descargar el kit. ¿Sin conexión? Usa --desde /ruta/al/kit" >&2
    exit 1
  }
  mkdir -p "$TEMP/kit"
  tar -xzf "$TEMP/kit.tar.gz" -C "$TEMP/kit" --strip-components=1
  FUENTE="$TEMP/kit"
  VERSION="publicada"
fi

[[ -f "$FUENTE/AGENTS.md" ]] || { echo "[kit] ERROR: $FUENTE no parece el kit (sin AGENTS.md)" >&2; exit 1; }
[[ "$FUENTE" != "$DESTINO" ]] || { echo "[kit] ERROR: origen y destino son el mismo directorio" >&2; exit 1; }

# --------------------------------------------------- capa 2: lo que nunca se toca
EXCLUIDOS=(
  '.git/' '.komandesk/' 'sites/' 'registry/sites.json' 'registry/marca-informes.txt'
  'state.md' '.claude/settings.local.json' '.cursor/mcp.json' 'kilo.jsonc' '.kilo/'
  'secrets.local.env' 'exports/'
)
excluido() {  # $1 = ruta relativa
  local ruta="$1" patron
  case "$ruta" in *.local|*.local.*) return 0 ;; esac
  for patron in "${EXCLUIDOS[@]}"; do
    case "$patron" in
      */) [[ "$ruta" == "${patron}"* ]] && return 0 ;;
      *)  [[ "$ruta" == "$patron" ]] && return 0 ;;
    esac
  done
  if [[ -f "$DESTINO/.sync-keep.local" ]]; then
    while IFS= read -r linea; do
      linea="${linea%%#*}"; linea="${linea## }"; linea="${linea%% }"
      [[ -z "$linea" ]] && continue
      case "$linea" in
        */) [[ "$ruta" == "${linea}"* ]] && return 0 ;;
        *)  [[ "$ruta" == $linea ]] && return 0 ;;
      esac
    done < "$DESTINO/.sync-keep.local"
  fi

  return 1
}

# El manifiesto guarda cómo entregamos cada fichero la última vez: lo que no coincide
# con él es que lo tocaste tú.
MANIFIESTO="$DESTINO/.kit-manifest.local"
[[ -f "$MANIFIESTO" ]] || : > "$MANIFIESTO"

# Sin arrays asociativos a propósito: macOS trae bash 3.2 y con `declare -A` este script
# no arrancaba en el Mac donde se usa.
entregado() {  # $1 = ruta relativa -> el hash con el que lo entregamos, o vacío
  awk -v r="$1" '$2 == r { print $1; exit }' "$MANIFIESTO"
}

# Sin manifiesto (primera actualización) todo lo que difiera parecería editado a mano, y una
# copia simplemente vieja se quedaría congelada con un «.nuevo» al lado. Si la copia instalada
# es un repositorio, su propio git ya sabe la respuesta: un fichero sin cambios respecto a su
# último commit no lo has tocado tú.
DESTINO_ES_REPO=0
git -C "$DESTINO" rev-parse --is-inside-work-tree >/dev/null 2>&1 && DESTINO_ES_REPO=1

lo_tocaste() {  # $1 = ruta relativa; 0 = sí, lo tocó el operador
  local rel="$1"
  [[ $DESTINO_ES_REPO -eq 1 ]] || return 0
  git -C "$DESTINO" ls-files --error-unmatch "$rel" >/dev/null 2>&1 || return 0
  [[ -n "$(git -C "$DESTINO" status --porcelain -- "$rel" 2>/dev/null)" ]]
}

actualizados=0; nuevos=0; conservados=0; iguales=0; retirados=0
CONSERVADOS=(); RETIRADOS=()
NUEVO_MANIFIESTO="$TEMP/manifiesto"
: > "$NUEVO_MANIFIESTO"

while IFS= read -r origen; do
  rel="${origen#"$FUENTE"/}"
  excluido "$rel" && continue

  destino="$DESTINO/$rel"
  h_origen="$(hash_de "$origen")"

  if [[ ! -e "$destino" ]]; then
    if [[ $ENSAYO -eq 0 ]]; then
      mkdir -p "$(dirname "$destino")"
      cp -p "$origen" "$destino"
    fi
    nuevos=$((nuevos + 1))
    echo "$h_origen $rel" >> "$NUEVO_MANIFIESTO"
    continue
  fi

  h_destino="$(hash_de "$destino")"
  if [[ "$h_destino" == "$h_origen" ]]; then
    iguales=$((iguales + 1))
    echo "$h_origen $rel" >> "$NUEVO_MANIFIESTO"
    continue
  fi

  # Editado aquí: el fichero instalado no es el que entregamos la última vez.
  esperado="$(entregado "$rel")"
  if [[ -z "$esperado" ]]; then
    # Sin manifiesto: decide el git de la copia instalada, si lo hay.
    if lo_tocaste "$rel"; then
      esperado_editado=1
    else
      esperado_editado=0
    fi
  elif [[ "$esperado" != "$h_destino" ]]; then
    esperado_editado=1
  else
    esperado_editado=0
  fi

  if [[ $esperado_editado -eq 1 ]]; then
    conservados=$((conservados + 1))
    CONSERVADOS+=("$rel")
    [[ $ENSAYO -eq 0 ]] && cp -p "$origen" "$destino.nuevo"
    # El manifiesto sigue apuntando a lo último entregado: si luego deshaces tu cambio,
    # la próxima actualización vuelve a tomar el control de ese fichero.
    [[ -n "$esperado" ]] && echo "$esperado $rel" >> "$NUEVO_MANIFIESTO"
    continue
  fi

  [[ $ENSAYO -eq 0 ]] && cp -p "$origen" "$destino"
  actualizados=$((actualizados + 1))
  echo "$h_origen $rel" >> "$NUEVO_MANIFIESTO"
done < <(find "$FUENTE" -type f -not -path "$FUENTE/.git/*" | sort)

# Los enlaces del kit (CLAUDE.md, .claude/skills…) son fuente única: se rehacen si faltan
# o apuntan a otro sitio. Una copia en su lugar es justo lo que doctor.sh saca en rojo.
enlaces=0
while IFS= read -r origen; do
  rel="${origen#"$FUENTE"/}"
  excluido "$rel" && continue
  objetivo="$(readlink "$origen")"
  destino="$DESTINO/$rel"
  if [[ -L "$destino" && "$(readlink "$destino")" == "$objetivo" ]]; then
    continue
  fi
  if [[ $ENSAYO -eq 0 ]]; then
    mkdir -p "$(dirname "$destino")"
    rm -rf "$destino"
    ln -s "$objetivo" "$destino"
  fi
  enlaces=$((enlaces + 1))
done < <(find "$FUENTE" -type l -not -path "$FUENTE/.git/*" | sort)

# Lo que desapareció del kit: se borra solo si estaba tal como lo entregamos.
while IFS=' ' read -r h_entregado rel; do
  [[ -n "${rel:-}" ]] || continue
  [[ -e "$FUENTE/$rel" ]] && continue
  destino="$DESTINO/$rel"
  [[ -f "$destino" ]] || continue
  if [[ "$(hash_de "$destino")" == "$h_entregado" ]]; then
    [[ $ENSAYO -eq 0 ]] && rm -f "$destino"
    retirados=$((retirados + 1))
  else
    conservados=$((conservados + 1))
    CONSERVADOS+=("$rel (retirado del kit, pero lo habías tocado)")
    echo "$h_entregado $rel" >> "$NUEVO_MANIFIESTO"
  fi
done < "$MANIFIESTO"

if [[ $ENSAYO -eq 0 ]]; then
  sort -k2 "$NUEVO_MANIFIESTO" > "$MANIFIESTO"
fi

echo
echo "[kit] Kit $VERSION → $DESTINO"
[[ $ENSAYO -eq 1 ]] && echo "[kit] ENSAYO: no se ha tocado nada."
echo "[kit]   $actualizados actualizados · $nuevos nuevos · $iguales sin cambios · $retirados retirados · $enlaces enlaces rehechos"
if [[ ${#CONSERVADOS[@]} -gt 0 ]]; then
  echo "[kit]   $conservados conservados porque los habías editado (versión nueva en «.nuevo»):"
  for rel in "${CONSERVADOS[@]}"; do echo "[kit]     - $rel"; done
  echo "[kit]   Mira el «.nuevo», lleva tu cambio a un fichero «.local.md» y borra el «.nuevo»."
  if [[ $DESTINO_ES_REPO -eq 1 && ! -s "$MANIFIESTO" ]]; then
    echo "[kit]   (Primera actualización: aquí cuentan como tuyos los ficheros que tengas sin"
    echo "[kit]    confirmar en git. Confírmalos o descártalos y la próxima ya no los marcará.)"
  fi
fi
echo "[kit] Tus sitios, tu registro, tus secretos y tus ficheros «.local» no se han tocado."
