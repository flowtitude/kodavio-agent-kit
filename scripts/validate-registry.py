#!/usr/bin/env python3
"""Valida registry/sites.json contra registry/sites.schema.json.

Sin dependencias: implementa el subconjunto de JSON Schema que usa el registry
(required, type, enum, pattern, additionalProperties, items, minProperties…), para
que el kit siga clonándose sin `pip install`. Si jsonschema está instalado, lo usa.

Además comprueba invariantes que un schema no puede expresar y que sí rompen sesiones:
  - guardrails más laxo que env (escribiría en producción con permisos de dev)
  - slug con sufijo _staging/_dev pero env=production, y viceversa
  - notes que apunta a un NOTAS.md de otro slug
  - verified caducado (>180 días): el sitio pudo cambiar de builder o de versión

Uso:  scripts/validate-registry.py [registry/sites.json]
"""
import json
import pathlib
import re
import sys
from datetime import date, datetime

ROOT = pathlib.Path(__file__).resolve().parent.parent
SCHEMA_PATH = ROOT / "registry" / "sites.schema.json"
STALE_DAYS = 180
RANK = {"development": 0, "staging": 1, "production": 2}

errors: list[str] = []
warnings: list[str] = []


def fail(msg: str) -> None:
    errors.append(msg)


def check(instance, schema, path, defs):
    if "$ref" in schema:
        ref = schema["$ref"].split("/")[-1]
        return check(instance, defs[ref], path, defs)

    t = schema.get("type")
    if t:
        types = t if isinstance(t, list) else [t]
        py = {
            "object": dict, "array": list, "string": str,
            "boolean": bool, "number": (int, float), "null": type(None),
        }
        if not any(isinstance(instance, py[x]) for x in types):
            fail(f"{path}: se esperaba {'|'.join(types)}, hay {type(instance).__name__}")
            return

    if "enum" in schema and instance not in schema["enum"]:
        fail(f"{path}: '{instance}' no está en {schema['enum']}")

    if isinstance(instance, str):
        if "pattern" in schema and not re.search(schema["pattern"], instance):
            fail(f"{path}: '{instance}' no cumple el patrón {schema['pattern']}")
        if "minLength" in schema and len(instance) < schema["minLength"]:
            fail(f"{path}: cadena vacía o demasiado corta")

    if isinstance(instance, dict):
        for req in schema.get("required", []):
            if req not in instance:
                fail(f"{path}: falta el campo obligatorio '{req}'")
        props = schema.get("properties", {})
        if schema.get("additionalProperties") is False:
            for k in instance:
                if k not in props:
                    fail(f"{path}: campo desconocido '{k}' (¿typo?)")
        if "minProperties" in schema and len(instance) < schema["minProperties"]:
            fail(f"{path}: necesita al menos {schema['minProperties']} entrada(s)")
        for k, v in instance.items():
            if k in props:
                check(v, props[k], f"{path}.{k}", defs)
            elif isinstance(schema.get("additionalProperties"), dict):
                check(v, schema["additionalProperties"], f"{path}.{k}", defs)

    if isinstance(instance, list) and "items" in schema:
        for i, item in enumerate(instance):
            check(item, schema["items"], f"{path}[{i}]", defs)


def semantic_checks(sites):
    seen = set()
    for s in sites:
        slug = s.get("slug", "?")
        if slug in seen:
            fail(f"slug duplicado: '{slug}'")
        seen.add(slug)

        env, guard = s.get("env"), s.get("guardrails")
        if env in RANK and guard in RANK and RANK[guard] < RANK[env]:
            fail(f"{slug}: guardrails='{guard}' es más laxo que env='{env}' — "
                 f"escribirías en {env} con permisos de {guard}")

        # El nombre del server MCP == entorno (AGENTS.md, regla de oro 10).
        suffixed = slug.endswith("_staging") or slug.endswith("_dev")
        if suffixed and env == "production":
            fail(f"{slug}: el slug sugiere staging/dev pero env='production'")
        if not suffixed and env in ("staging", "development"):
            warnings.append(f"{slug}: env='{env}' pero el slug no lleva sufijo _staging/_dev "
                            f"(la regla de oro 10 dice que el nombre del server ES el entorno)")

        notes = s.get("notes", "")
        if notes and notes != f"sites/{slug}/NOTAS.md":
            fail(f"{slug}: notes='{notes}' no corresponde a su slug")

        if env == "production" and not s.get("caveats"):
            warnings.append(f"{slug}: producción sin caveats — ¿de verdad no hay ninguna limitación?")

        v = s.get("verified")
        if not v:
            warnings.append(f"{slug}: nunca verificado contra wp-get-config-summary")
        else:
            try:
                age = (date.today() - datetime.strptime(v, "%Y-%m-%d").date()).days
                if age > STALE_DAYS:
                    warnings.append(f"{slug}: verificado hace {age} días — "
                                    f"builder/versión pueden haber cambiado")
            except ValueError:
                fail(f"{slug}: verified='{v}' no es una fecha YYYY-MM-DD")

        if not s.get("kodavio_version"):
            warnings.append(f"{slug}: sin kodavio_version — el contrato de skill-get depende de ella")


def main() -> int:
    target = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "registry" / "sites.json"
    if not target.exists():
        print(f"[registry] {target} no existe", file=sys.stderr)
        return 1

    try:
        data = json.loads(target.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        print(f"[registry] {target} no es JSON válido: {e}", file=sys.stderr)
        return 1

    schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    try:
        import jsonschema  # type: ignore
        v = jsonschema.Draft202012Validator(schema)
        for e in sorted(v.iter_errors(data), key=lambda e: list(e.path)):
            fail("sites" + "".join(f"[{p}]" if isinstance(p, int) else f".{p}" for p in e.path) + f": {e.message}")
    except ImportError:
        check(data, schema, "sites.json", schema.get("$defs", {}))

    semantic_checks(data.get("sites", []))

    for w in warnings:
        print(f"  warn {w}")
    for e in errors:
        print(f"  FAIL {e}", file=sys.stderr)

    if errors:
        print(f"[registry] {target.name}: {len(errors)} error(es).", file=sys.stderr)
        return 1
    print(f"  ok   {target.name}: {len(data.get('sites', []))} sitio(s) válidos"
          + (f", {len(warnings)} aviso(s)" if warnings else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
