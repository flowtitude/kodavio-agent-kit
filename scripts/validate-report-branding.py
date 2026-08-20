#!/usr/bin/env python3
"""Valida registry/report-branding.json contra registry/report-branding.schema.json.

Reutiliza el checker genérico de scripts/validate-registry.py (`check()`, sin
dependencias) en vez de duplicarlo — es el mismo subconjunto de JSON Schema, misma
regla del kit: cada hecho vive en un solo sitio. Añade una semántica propia que un
schema no puede expresar: avisar de variables desconocidas en footer_left/footer_right
(no es error — la plantilla las deja tal cual a propósito, ver §5.1 de la especificación).

Uso:  scripts/validate-report-branding.py [registry/report-branding.json]
"""
import importlib.util
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SCHEMA_PATH = ROOT / "registry" / "report-branding.schema.json"

_spec = importlib.util.spec_from_file_location("validate_registry", ROOT / "scripts" / "validate-registry.py")
_validate_registry = importlib.util.module_from_spec(_spec)
sys.modules["validate_registry"] = _validate_registry
_spec.loader.exec_module(_validate_registry)
generic_check = _validate_registry.check

KNOWN_VARS = {"emisor", "correo", "telefono", "web", "legal", "fecha", "sitio"}
VAR_RE = re.compile(r"\{([a-zA-Z0-9_]*)\}")

errors: list[str] = []
warnings: list[str] = []


def semantic_checks(data: dict) -> None:
    for field in ("footer_left", "footer_right"):
        tpl = data.get(field)
        if not tpl:
            continue
        for var in VAR_RE.findall(tpl):
            if var not in KNOWN_VARS:
                warnings.append(
                    f"{field}: variable desconocida '{{{var}}}' — se deja literal en el "
                    "pie (comportamiento intencional, §5.1)"
                )
    if data.get("show_powered_by") is True and "issuer_name" not in data:
        warnings.append("show_powered_by=true pero falta issuer_name")


def main() -> int:
    target = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "registry" / "report-branding.json"
    if not target.exists():
        print(f"[report-branding] {target} no existe", file=sys.stderr)
        return 1

    try:
        data = json.loads(target.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"[report-branding] {target} no es JSON válido: {e}", file=sys.stderr)
        return 1

    schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    _validate_registry.errors.clear()
    generic_check(data, schema, "report-branding.json", schema.get("$defs", {}))
    errors.extend(_validate_registry.errors)

    semantic_checks(data)

    for w in warnings:
        print(f"  warn {w}")
    for e in errors:
        print(f"  FAIL {e}", file=sys.stderr)

    if errors:
        print(f"[report-branding] {target.name}: {len(errors)} error(es).", file=sys.stderr)
        return 1
    print(
        f"  ok   {target.name}: marca válida"
        + (f", {len(warnings)} aviso(s)" if warnings else "")
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
