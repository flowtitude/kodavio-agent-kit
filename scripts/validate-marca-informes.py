#!/usr/bin/env python3
"""Valida registry/marca-informes.txt — marca del kit para informes de cliente.

Formato texto plano en castellano ("Clave: valor", comentarios con "#"),
decisión 2026-08-21 sobre la versión anterior en JSON (registry/report-
branding.json + .schema.json): un operador novel no debería tener que tocar
JSON para poner su logo y sus colores. El parser vive aquí, no hay
representación JSON intermedia versionada — si algo internamente necesita el
dict, lo deriva de este mismo fichero al vuelo (ver parse()).

Uso:  scripts/validate-marca-informes.py [registry/marca-informes.txt]
"""
import pathlib
import re
import sys
import unicodedata

ROOT = pathlib.Path(__file__).resolve().parent.parent

HEX_RE = re.compile(r"^#[0-9A-Fa-f]{6}$")
VAR_RE = re.compile(r"\{([a-zA-Z0-9_]*)\}")
KNOWN_VARS = {"emisor", "correo", "telefono", "web", "legal", "fecha", "sitio", "tipo_informe"}
BOOL_TRUE = {"si", "yes", "true", "1"}
BOOL_FALSE = {"no", "false", "0"}

# clave normalizada (sin acentos/comillas, minúscula, "-" ~ "·") -> (campo interno, tipo)
KEY_MAP = {
    "emisor": ("issuer_name", "text"),
    "correo": ("email", "text"),
    "telefono": ("phone", "text"),
    "web": ("web", "text"),
    "logo": ("logo", "text"),
    "texto legal": ("legal_footer", "text"),
    "mostrar generado con kodavio": ("show_powered_by", "bool"),
    "color principal": ("primary_color", "color"),
    "color de acento": ("accent_color", "color"),
    "color del texto": ("text_color", "color"),
    "color de portada": ("cover_color", "color"),
    "tipografia": ("font_family", "text"),
    "portada · antetitulo": ("cover_kicker", "text"),
    "portada · titulo": ("cover_title", "text"),
    "portada · mostrar fecha": ("cover_show_date", "bool"),
    "cabecera · izquierda": ("header_left", "template"),
    "cabecera · derecha": ("header_right", "template"),
    "pie · izquierda": ("footer_left", "template"),
    "pie · derecha": ("footer_right", "template"),
}
REQUIRED = {"issuer_name"}


def normalize_key(raw: str) -> str:
    key = raw.strip()
    key = key.replace('"', "").replace("'", "").replace(""", "").replace(""", "")
    key = re.sub(r"\s*-\s*", " · ", key)  # "-" como alternativa a "·" para quien no lo teclee
    key = unicodedata.normalize("NFKD", key)
    key = "".join(c for c in key if not unicodedata.combining(c))
    key = key.lower()
    key = re.sub(r"\s+", " ", key).strip()
    return key


def parse(text: str):
    """Devuelve (data: dict campo->valor, unknown: [(linea, clave_cruda)], dup: [clave])."""
    data = {}
    unknown = []
    seen_lines = {}
    for lineno, raw_line in enumerate(text.splitlines(), 1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if ":" not in line:
            unknown.append((lineno, line, "línea sin ':' — se ignora"))
            continue
        raw_key, raw_value = line.split(":", 1)
        value = raw_value.strip()
        norm = normalize_key(raw_key)
        if norm not in KEY_MAP:
            unknown.append((lineno, raw_key.strip(), None))
            continue
        field, kind = KEY_MAP[norm]
        seen_lines.setdefault(field, []).append(lineno)
        if value:  # una clave con valor vacío = "no fijado", usa el default de fábrica
            data[field] = (value, kind, lineno)
    dup = [f for f, lines in seen_lines.items() if len(lines) > 1]
    return data, unknown, dup


def main() -> int:
    target = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "registry" / "marca-informes.txt"
    if not target.exists():
        print(f"[marca-informes] {target} no existe", file=sys.stderr)
        return 1

    text = target.read_text(encoding="utf-8")
    data, unknown, dup = parse(text)

    errors: list[str] = []
    warnings: list[str] = []

    for field in REQUIRED:
        if field not in data:
            errors.append(f"falta 'Emisor' (obligatorio — el resto de campos son opcionales)")

    for field, (value, kind, lineno) in data.items():
        if kind == "color" and not HEX_RE.match(value):
            errors.append(f"línea {lineno}: color '{value}' no es #RRGGBB válido")
        elif kind == "bool" and normalize_key(value) not in (BOOL_TRUE | BOOL_FALSE):
            errors.append(f"línea {lineno}: '{value}' no es sí/no (usa 'sí' o 'no')")
        elif kind == "template":
            for var in VAR_RE.findall(value):
                if var not in KNOWN_VARS:
                    warnings.append(
                        f"línea {lineno}: variable desconocida '{{{var}}}' — se deja literal "
                        "en el texto (comportamiento intencional)"
                    )

    for lineno, key, reason in unknown:
        warnings.append(f"línea {lineno}: clave desconocida '{key}'" + (f" — {reason}" if reason else " — se ignora"))
    for field in dup:
        warnings.append(f"clave repetida para '{field}': se queda con el último valor")

    for w in warnings:
        print(f"  warn {w}")
    for e in errors:
        print(f"  FAIL {e}", file=sys.stderr)

    if errors:
        print(f"[marca-informes] {target.name}: {len(errors)} error(es).", file=sys.stderr)
        return 1
    print(
        f"  ok   {target.name}: marca válida"
        + (f", {len(warnings)} aviso(s)" if warnings else "")
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
