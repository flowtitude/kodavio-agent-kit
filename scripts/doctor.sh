#!/usr/bin/env bash
#
# doctor.sh — detector de deriva del kit. Falla con exit != 0.
#
# Un verde solo cuenta si el detector podía haber salido en rojo: cada check de aquí
# nació de una deriva real encontrada en la auditoría del 2026-08-03.
#
# Usage:  scripts/doctor.sh [--quiet]
#         Engánchalo al pre-commit:  scripts/doctor.sh --install-hook
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

QUIET=0
[[ "${1:-}" == "--quiet" ]] && QUIET=1

if [[ "${1:-}" == "--install-hook" ]]; then
  HOOK_DIR="$(git rev-parse --git-path hooks)"
  mkdir -p "$HOOK_DIR"
  cat > "$HOOK_DIR/pre-commit" <<'HOOK'
#!/usr/bin/env bash
# Bloquea el commit si el kit está en rojo. Saltar (excepcional): git commit --no-verify
exec "$(git rev-parse --show-toplevel)/scripts/doctor.sh" --quiet
HOOK
  chmod +x "$HOOK_DIR/pre-commit"
  echo "[doctor] hook pre-commit instalado en $HOOK_DIR/pre-commit"
  exit 0
fi

RED=0
SECTION_RED=0
say()  { [[ $QUIET -eq 1 ]] || echo "$@"; }
ok()   { say "  ok   $*"; }
fail() { echo "  FAIL $*" >&2; RED=1; SECTION_RED=1; }
warn() { say "  warn $*"; }
section() { say ""; say "▸ $*"; SECTION_RED=0; }
# Resumen de sección: solo si esa sección salió limpia (un fallo en otra no lo silencia).
ok_if_clean() { [[ $SECTION_RED -eq 0 ]] && ok "$*"; }

# ------------------------------------------------- capa personal del operador
# Las skills/subagentes propios del operador se listan en .sync-keep.local (gitignored)
# y NO son del kit compartido: no tienen por qué llevar fases canónicas, ni fila en
# WORKFLOWS, ni salir en el README. Un detector que sale rojo por ellas es un detector
# que se acaba ignorando — y eso es peor que no tenerlo.
is_personal() {  # $1 = slug de la skill
  [[ -f .sync-keep.local ]] || return 1
  grep -qE "^skills/$1/?[[:space:]]*$" .sync-keep.local
}

# ---------------------------------------------------------------- 1. symlinks
# Windows sin Developer Mode y los rsync mal hechos los convierten en copias:
# a partir de ahí cada herramienta lee un kit distinto.
section "Fuente única (symlinks)"
check_link() {  # $1=link  $2=destino esperado
  if [[ ! -L "$1" ]]; then
    fail "$1 no es symlink (debería apuntar a $2) — es una copia que derivará"
  elif [[ "$(readlink "$1")" != "$2" ]]; then
    fail "$1 apunta a $(readlink "$1"), se esperaba $2"
  else
    ok "$1 → $2"
  fi
}
check_link CLAUDE.md AGENTS.md
check_link .claude/skills ../skills
check_link .claude/agents ../agents
check_link .agents/skills ../skills

# --------------------------------------------------- 2. agentes de Codex al día
section "Agentes de Codex generados (.codex/agents)"
if out=$(scripts/gen-codex-agents.sh --check 2>&1); then
  ok "en sync con agents/*.md"
else
  echo "$out" >&2
  fail ".codex/agents desincronizado — corre scripts/gen-codex-agents.sh"
fi

# ------------------------------------------------------- 3. skills bien formadas
section "Skills"
SKILLS=()
PERSONAL=0
for d in skills/*/; do
  slug="$(basename "$d")"
  if is_personal "$slug"; then PERSONAL=$((PERSONAL + 1)); continue; fi
  SKILLS+=("$slug")
  f="$d/SKILL.md"

  [[ -f "$f" ]] || { fail "$slug: falta SKILL.md"; continue; }

  name="$(awk 'NR==1&&$0=="---"{i=1;next} i&&$0=="---"{exit} i&&index($0,"name: ")==1{print substr($0,7);exit}' "$f")"
  desc="$(awk 'NR==1&&$0=="---"{i=1;next} i&&$0=="---"{exit} i&&index($0,"description: ")==1{print substr($0,14);exit}' "$f")"

  [[ -n "$name" ]] || fail "$slug: SKILL.md sin 'name' en el frontmatter"
  [[ -n "$desc" ]] || fail "$slug: SKILL.md sin 'description' (sin ella el modelo no sabe cuándo invocarla)"
  [[ "$name" == "$slug" ]] || fail "$slug: frontmatter name='$name' ≠ nombre del directorio"

  grep -q "skill-phases" "$f" || fail "$slug: no declara las fases canónicas (rules/skill-phases.md)"
  grep -q "$slug" workflows/WORKFLOWS.md || fail "$slug: sin fila en workflows/WORKFLOWS.md — no se enruta"
  grep -q "$slug" AGENTS.md || fail "$slug: no aparece en la tabla de AGENTS.md"
done
ok_if_clean "${#SKILLS[@]} skills del kit con frontmatter, fases, enrutado y puerta de entrada$([[ $PERSONAL -gt 0 ]] && echo " (+$PERSONAL personales, fuera del alcance)")"

# ------------------------------------------------------------ 4. subagentes
section "Subagentes"
for f in agents/*.md; do
  slug="$(basename "$f" .md)"
  awk 'NR==1&&$0=="---"{i=1} i&&index($0,"description: ")==1{found=1} END{exit !found}' "$f" \
    || fail "$slug: sin 'description' en el frontmatter"
  # Un subagente arranca con contexto propio: la regla que no está en su prompt no existe.
  grep -q "production-guardrails" "$f" || fail "$slug: no cita rules/production-guardrails.md"
  grep -q "ability-source-agnostic" "$f" || fail "$slug: no cita rules/ability-source-agnostic.md"
  grep -q "credentials" "$f" || fail "$slug: no cita la regla de no filtrar datos sensibles (docs/credentials.md)"
  grep -q "$slug" AGENTS.md || fail "$slug: no aparece en la tabla de subagentes de AGENTS.md"
done
ok_if_clean "$(ls agents/*.md | wc -l | tr -d ' ') subagentes con reglas duras cableadas"

# ------------------------------------------------- 5. enlaces internos vivos
# Una regla que apunta a un fichero que no existe es peor que no tenerla: el modelo
# la cita, no la puede leer, y sigue como si la hubiera aplicado.
section "Enlaces internos"
if python3 - <<'PY'
import pathlib, re, sys

ROOT = pathlib.Path(".")
DIRS = ("rules", "docs", "skills", "agents", "workflows", "registry", "scripts")
# `rules/x.md` en backticks o [texto](rules/x.md) en markdown
PAT = re.compile(r"`((?:%s)/[\w./-]+)`|\]\(((?:%s)/[\w./-]+)\)" % ("|".join(DIRS), "|".join(DIRS)))
# Plantillas ({slug}), globs, y los ficheros que por diseño solo existen en la copia
# del operador (datos locales, gitignored): referenciarlos es correcto.
SKIP = re.compile(r"\{slug\}|\{cliente\}|\{client\}|<|\*")
LOCAL_BY_DESIGN = {"registry/sites.json", "registry/report-branding.json", "state.md"}

targets = ["AGENTS.md", "README.md", *DIRS]
files = []
for t in targets:
    p = ROOT / t
    files.extend(sorted(p.rglob("*.md")) if p.is_dir() else ([p] if p.is_file() else []))

broken = []
for f in files:
    for n, line in enumerate(f.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        for m in PAT.finditer(line):
            ref = m.group(1) or m.group(2)
            if SKIP.search(ref) or ref in LOCAL_BY_DESIGN or (ROOT / ref).exists():
                continue
            if ref.startswith("sites/") and not ref.startswith("sites/_template/"):
                continue
            broken.append(f"{f}:{n} → {ref}")

for b in broken:
    print(f"  FAIL enlace roto: {b}", file=sys.stderr)
sys.exit(1 if broken else 0)
PY
then
  ok "sin referencias a ficheros inexistentes"
else
  fail "hay enlaces internos rotos (arriba)"
fi

# ----------------------------------------------- 6. basura de escritura del modelo
section "Higiene del markdown"
if grep -rn '</content>\|</SKILL\|</document>' rules skills agents workflows docs AGENTS.md README.md >/dev/null 2>&1; then
  grep -rn '</content>\|</SKILL\|</document>' rules skills agents workflows docs AGENTS.md README.md >&2
  fail "tags XML colgando (residuo de escritura del modelo)"
else
  ok "sin tags colgando"
fi

# ------------------------------------------- 7. el README no puede mentir
section "README coherente"
real_skills=${#SKILLS[@]}   # solo las del kit; las personales no salen en el README
real_agents=$(ls agents/*.md | wc -l | tr -d ' ')
if grep -qE "^├── skills/ +${real_skills} skills|${real_skills} skills" README.md; then
  ok "README declara $real_skills skills"
else
  fail "README no declara las $real_skills skills reales (busca el conteo en el árbol y en el texto)"
fi
if grep -qE "${real_agents} subagentes" README.md; then
  ok "README declara $real_agents subagentes"
else
  fail "README no declara los $real_agents subagentes reales"
fi
for s in "${SKILLS[@]}"; do
  grep -q "$s" README.md || fail "README no lista la skill $s"
done

# ------------------------------------------------- 8. el kit sigue siendo clonable
section "Kit clonable (sin datos locales versionados)"
leaked=0
for p in registry/sites.json registry/report-branding.json state.md .claude/settings.local.json; do
  git ls-files --error-unmatch "$p" >/dev/null 2>&1 && { fail "$p está versionado y es dato local"; leaked=1; }
done
while read -r tracked; do
  case "$tracked" in
    sites/_template/*) ;;
    sites/*) fail "$tracked está versionado: solo sites/_template/ puede estarlo"; leaked=1 ;;
  esac
done < <(git ls-files sites 2>/dev/null)
[[ $leaked -eq 0 ]] && ok "sin datos locales en el índice de git"

# Ningún archivo versionado puede nombrar un sitio real del registry local.
if [[ -f registry/sites.json ]] && command -v python3 >/dev/null; then
  slugs=$(python3 -c "
import json,sys
try: d=json.load(open('registry/sites.json'))
except Exception: sys.exit(0)
print('\n'.join(s.get('slug','') for s in d.get('sites',[]) if s.get('slug')))
")
  hits=0
  while read -r slug; do
    [[ -z "$slug" || "$slug" == example_com* ]] && continue
    if git grep -l -F "$slug" -- ':!sites' ':!registry/sites.json' >/dev/null 2>&1; then
      fail "el slug real '$slug' aparece en archivos versionados (debe vivir solo en sites.json / sites/)"
      hits=1
    fi
  done <<< "$slugs"
  [[ $hits -eq 0 ]] && ok "ningún sitio real filtrado a archivos versionados"
fi

# --------------------------------------------------- 9. registry contra el schema
section "Registry"
if [[ -f registry/sites.json ]]; then
  if command -v python3 >/dev/null; then
    python3 scripts/validate-registry.py registry/sites.json || fail "registry/sites.json no valida"
  else
    warn "sin python3: no se valida el registry"
  fi
else
  warn "registry/sites.json no existe (kit recién clonado: cp registry/sites.example.json registry/sites.json)"
fi
python3 scripts/validate-registry.py registry/sites.example.json >/dev/null 2>&1 \
  && ok "sites.example.json valida contra el schema" \
  || fail "sites.example.json no valida contra su propio schema"

# Marca del kit para informes de cliente — mismo patrón real/gitignored + example + schema.
if [[ -f registry/report-branding.json ]]; then
  python3 scripts/validate-report-branding.py registry/report-branding.json || fail "registry/report-branding.json no valida"
else
  warn "registry/report-branding.json no existe (cp registry/report-branding.example.json registry/report-branding.json y rellena tu marca)"
fi
python3 scripts/validate-report-branding.py registry/report-branding.example.json >/dev/null 2>&1 \
  && ok "report-branding.example.json valida contra el schema" \
  || fail "report-branding.example.json no valida contra su propio schema"

# --------------------------------- 10. contrato con el plugin: no prometer lo que no hay
section "Contrato con el plugin"
MANIFEST="registry/abilities-kodavio.json"
if [[ ! -f "$MANIFEST" ]]; then
  warn "sin $MANIFEST — no se puede comprobar qué capacidades existen de verdad"
  warn "regenéralo desde el plugin: php scripts/export-abilities-manifest.php <ruta-a-este-fichero>"
else
  # El kit llegó a vender kodavio/report-get-branding como «requiere Kodavio 0.3»
  # cuando esa capacidad vivía en una rama sin fusionar, y este doctor salía verde
  # igual: comprobaba enlaces y markdown, pero ni una sola capacidad contra el
  # plugin. Esto cierra la clase de fallo entera, no el caso de aquel día.
  # La lookahead descarta rutas de repo (kodavio/docs/design/...) y comodines
  # escritos a medias (kodavio/bricks-node-), que no son capacidades.
  citadas="$(grep -rhoP 'kodavio/[a-z0-9]+(?:-[a-z0-9]+)*(?![a-z0-9/-])' skills/ rules/ agents/ workflows/ docs/ *.md 2>/dev/null \
    | sort -u)"
  reales="$(python3 -c "
import json, sys
d = json.load(open('$MANIFEST', encoding='utf-8'))
print('\n'.join(d['abilities']))
")"
  version="$(python3 -c "import json;print(json.load(open('$MANIFEST', encoding='utf-8'))['version'])")"
  fantasmas="$(comm -23 <(echo "$citadas") <(echo "$reales"))"
  if [[ -n "$fantasmas" ]]; then
    while IFS= read -r a; do
      [[ -z "$a" ]] && continue
      donde="$(grep -rlE "${a//\//\\/}" skills/ rules/ agents/ workflows/ docs/ *.md 2>/dev/null | head -1)"
      fail "$a no existe en el plugin $version — citada en ${donde:-?}"
    done <<< "$fantasmas"
  fi
  n_citadas="$(echo "$citadas" | grep -c . || true)"
  ok_if_clean "$n_citadas capacidades citadas, todas existen en el plugin $version"
fi

# ---------------------------------------------------------------- veredicto
say ""
if [[ $RED -eq 0 ]]; then
  say "VERDE — el kit está sano."
  exit 0
fi
echo "" >&2
echo "ROJO — arréglalo hoy o quita lo que lo causa (AGENTS.md › Mantenimiento del sistema)." >&2
exit 1
