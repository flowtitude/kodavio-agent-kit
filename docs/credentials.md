# Credenciales sin texto plano — `wp-mcp-launch`

> Por defecto, todas las herramientas (Claude, Cursor, Codex, OpenCode, Kilo) guardan los `env` de
> los servers MCP **en claro** en sus archivos de config. Este patrón lo evita: la Application
> Password vive en el **almacén de secretos del SO** y el lanzador del kit la inyecta al proxy en
> el arranque. La config de tu agente deja de contener secretos — en macOS, Linux y Windows.

## Cómo funciona

```
config del agente (sin secreto)          almacén del SO                proxy MCP
command: scripts/wp-mcp-launch.sh   →    wp-agent-{slug}          →    WP_API_PASSWORD en el
env: WP_MCP_SLUG, WP_API_URL,            (Keychain / libsecret /       entorno SOLO del proceso
     WP_API_USERNAME                      pass / Credential Mgr)        del proxy
```

El lanzador detecta el backend disponible: `security` (macOS) → `secret-tool` (Linux, GNOME
Keyring/KWallet vía libsecret) → `pass` → `python3 -m keyring` (cualquier SO, `pip install keyring`).
En Windows se usa `wp-mcp-launch.ps1` (Credential Manager o python-keyring).

## 1. Guardar la credencial (una vez por sitio)

El nombre del item es siempre `wp-agent-{slug}` (mismo slug que `registry/sites.json`).
La credencial es **por máquina**: nunca viaja con el repo ni se copia al clonar — quien clona
guarda la suya en su propio almacén.

**Recomendado — mismo comando en macOS, Linux y Windows (python-keyring):**
```bash
pip install keyring          # una vez
python3 -m keyring set "wp-agent-example_com" "agente-ia"   # pide la password en oculto
```
keyring usa por debajo el almacén nativo de cada SO (Keychain / Secret Service / Credential
Locker), pero el comando es idéntico en los tres. Alternativas nativas si prefieres no instalar nada:

**macOS (Keychain):**
```bash
security add-generic-password -U -s "wp-agent-example_com" -a "agente-ia" -w
# (-w sin valor: la pide en oculto; -U actualiza si ya existe)
```

**Linux (libsecret / GNOME Keyring):**
```bash
secret-tool store --label="WP agente example_com" service "wp-agent-example_com"
```

**Linux (pass):**
```bash
pass insert "mcp/wp-agent-example_com"
```

**Windows (PowerShell, módulo CredentialManager):**
```powershell
Install-Module CredentialManager -Scope CurrentUser   # una vez
New-StoredCredential -Target "wp-agent-example_com" -UserName "agente-ia" `
  -Password (Read-Host -AsSecureString | ConvertFrom-SecureString -AsPlainText) -Persist LocalMachine
```

## 2. Configurar el server MCP con el lanzador

La forma es idéntica en todas las herramientas: `command` = el script, y en `env` solo lo no
secreto (`WP_MCP_SLUG`, `WP_API_URL`, `WP_API_USERNAME`). Ejemplo Claude Code (`~/.claude.json`):

```json
"example_com": {
  "type": "stdio",
  "command": "/ruta/al/kit/scripts/wp-mcp-launch.sh",
  "args": [],
  "env": {
    "WP_MCP_SLUG": "example_com",
    "WP_API_URL": "https://example.com/wp-json/mcp/kodavio",
    "WP_API_USERNAME": "agente-ia"
  }
}
```

Para Cursor/Codex/OpenCode/Kilo: misma sustitución sobre las plantillas de
[mcp-config-examples.md](mcp-config-examples.md) (cambia `npx -y …` por el script y elimina
`WP_API_PASSWORD` del `env`). En Windows: `command` = `powershell`,
`args` = `["-ExecutionPolicy","Bypass","-File","C:\\ruta\\wp-mcp-launch.ps1"]`.

## 3. Verificar

```bash
WP_MCP_SLUG=example_com WP_API_USERNAME=agente-ia ./scripts/wp-mcp-launch.sh --check
# → ✔ Credencial 'wp-agent-example_com' resuelta desde el almacén del SO.
```

Después reinicia el agente y pide un `kodavio/wp-get-config-summary` del sitio.

## Notas

- La versión del proxy va pineada en el lanzador (`0.3.4`); se puede forzar otra con
  `WP_MCP_PROXY_VERSION` en el `env` del server.
- Esto protege los **archivos de config**. El secreto sigue existiendo en RAM del proxy y en el
  almacén del SO: cifra el disco igualmente (FileVault/LUKS/BitLocker) y usa Application Passwords
  de usuario dedicado con rol mínimo, revocables por sitio.
- Rotación: regenera la Application Password en wp-admin → vuelve a ejecutar el comando de guardado
  del paso 1 (sobrescribe) → reinicia el agente. La config no se toca.
