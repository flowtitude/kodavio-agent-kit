#!/usr/bin/env bash
#
# Simulacro de actualizar-kit.sh sobre copias de mentira.
#
# Existe porque el detector de deriva no puede comprobar esto mirando ficheros: hay que
# actualizar de verdad y ver qué sobrevive. Cada caso de aquí es una forma real de perder
# trabajo — la que pasó el 17-09-2026 (88 cambios en sitekit) es el caso 3.

set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEMP="$(mktemp -d)"
trap 'rm -rf "$TEMP"' EXIT

FUENTE="$TEMP/fuente"
COPIA="$TEMP/instalada"
fallos=0

comprobar() {  # $1 = qué se esperaba  $2 = condición ya evaluada (0 = bien)
  if [[ "$2" -eq 0 ]]; then
    echo "  ok   $1"
  else
    echo "  FALLO $1" >&2
    fallos=$((fallos + 1))
  fi
}

# ------------------------------------------------------------------ el montaje
mkdir -p "$FUENTE/rules" "$FUENTE/skills/una" "$FUENTE/.claude"
printf 'kit v1\n' > "$FUENTE/AGENTS.md"
printf 'regla v1\n' > "$FUENTE/rules/regla.md"
printf 'skill v1\n' > "$FUENTE/skills/una/SKILL.md"
printf 'se retira\n' > "$FUENTE/rules/se-retira.md"
printf 'la tocas y se retira\n' > "$FUENTE/rules/retirada-tocada.md"
ln -s ../skills "$FUENTE/.claude/skills"
ln -s AGENTS.md "$FUENTE/CLAUDE.md"

mkdir -p "$COPIA"

# === 1) primera actualización: llega todo, con sus enlaces ==================
bash "$KIT/scripts/actualizar-kit.sh" --desde "$FUENTE" --destino "$COPIA" >/dev/null
[[ -f "$COPIA/AGENTS.md" && -f "$COPIA/skills/una/SKILL.md" ]]; comprobar "1: la primera actualización trae el kit" $?
[[ -L "$COPIA/CLAUDE.md" && "$(readlink "$COPIA/CLAUDE.md")" == "AGENTS.md" ]]; comprobar "1b: los enlaces llegan como enlaces, no como copias" $?
[[ -f "$COPIA/.kit-manifest.local" ]]; comprobar "1c: queda el manifiesto de lo entregado" $?

# ------------------------------------------ lo personal y los ajustes del operador
mkdir -p "$COPIA/sites/uncliente" "$COPIA/skills/mia"
printf 'notas del cliente\n' > "$COPIA/sites/uncliente/NOTAS.md"
printf 'mi skill\n' > "$COPIA/skills/mia/SKILL.md"
printf 'skills/mia/\n' > "$COPIA/.sync-keep.local"
printf 'mi ajuste sobre la regla\n' > "$COPIA/rules/regla.local.md"
mkdir -p "$COPIA/registry"
printf 'sitios reales\n' > "$COPIA/registry/sites.json"

# ------------------------------------------------- el operador toca un fichero del kit
printf 'skill v1 + mi parrafo\n' > "$COPIA/skills/una/SKILL.md"
printf 'la tocas y se retira + mi cambio\n' > "$COPIA/rules/retirada-tocada.md"

# -------------------------------------------------------- sale una versión nueva
printf 'kit v2\n' > "$FUENTE/AGENTS.md"
printf 'regla v2\n' > "$FUENTE/rules/regla.md"
printf 'skill v2\n' > "$FUENTE/skills/una/SKILL.md"
printf 'nueva del kit\n' > "$FUENTE/rules/nueva.md"
rm "$FUENTE/rules/se-retira.md" "$FUENTE/rules/retirada-tocada.md"

SALIDA="$(bash "$KIT/scripts/actualizar-kit.sh" --desde "$FUENTE" --destino "$COPIA")"

# === 2) lo que no tocaste se actualiza =====================================
[[ "$(cat "$COPIA/AGENTS.md")" == "kit v2" && "$(cat "$COPIA/rules/regla.md")" == "regla v2" ]]; comprobar "2: lo que no tocaste se actualiza" $?
[[ -f "$COPIA/rules/nueva.md" ]]; comprobar "2b: lo que es nuevo en el kit llega" $?

# === 3) lo que tocaste NO se pisa, y la versión nueva queda al lado =========
[[ "$(cat "$COPIA/skills/una/SKILL.md")" == "skill v1 + mi parrafo" ]]; comprobar "3: tu cambio en un fichero del kit sigue ahí" $?
[[ "$(cat "$COPIA/skills/una/SKILL.md.nuevo")" == "skill v2" ]]; comprobar "3b: la versión nueva queda como «.nuevo»" $?
grep -q "skills/una/SKILL.md" <<< "$SALIDA"; comprobar "3c: y se avisa por pantalla" $?

# === 4) lo personal y los ajustes no se tocan ==============================
[[ "$(cat "$COPIA/sites/uncliente/NOTAS.md")" == "notas del cliente" ]]; comprobar "4: los sitios no se tocan" $?
[[ "$(cat "$COPIA/registry/sites.json")" == "sitios reales" ]]; comprobar "4b: tu registro de sitios no se toca" $?
[[ "$(cat "$COPIA/skills/mia/SKILL.md")" == "mi skill" ]]; comprobar "4c: tus skills propias siguen" $?
[[ "$(cat "$COPIA/rules/regla.local.md")" == "mi ajuste sobre la regla" ]]; comprobar "4d: tus ajustes «.local.md» siguen" $?

# === 5) lo retirado del kit: se va si no lo tocaste, se queda si sí =========
[[ ! -f "$COPIA/rules/se-retira.md" ]]; comprobar "5: lo retirado del kit desaparece" $?
[[ -f "$COPIA/rules/retirada-tocada.md" ]]; comprobar "5b: salvo si lo habías tocado" $?

# === 6) el ensayo no toca nada =============================================
printf 'regla v3\n' > "$FUENTE/rules/regla.md"
bash "$KIT/scripts/actualizar-kit.sh" --desde "$FUENTE" --destino "$COPIA" --ensayo >/dev/null
[[ "$(cat "$COPIA/rules/regla.md")" == "regla v2" ]]; comprobar "6: el ensayo no escribe" $?

if [[ $fallos -gt 0 ]]; then
  echo "actualizar-kit-prueba: $fallos FALLOS" >&2
  exit 1
fi

echo "actualizar-kit-prueba: OK (6 casos)"
