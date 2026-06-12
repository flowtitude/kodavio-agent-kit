# wp-mcp-launch.ps1 — equivalente Windows de wp-mcp-launch.sh.
# Lee la Application Password del Credential Manager (módulo CredentialManager)
# o de python-keyring, y lanza el proxy MCP sin credenciales en la config.
# Ver docs/credentials.md. Uso: command = powershell, args = ["-File", ".../wp-mcp-launch.ps1"]
param([switch]$Check)

$slug = $env:WP_MCP_SLUG
if (-not $slug) { Write-Error "define WP_MCP_SLUG (slug del sitio en registry/sites.json)"; exit 1 }
$service = "wp-agent-$slug"
$proxyVersion = if ($env:WP_MCP_PROXY_VERSION) { $env:WP_MCP_PROXY_VERSION } else { "0.3.4" }

$pass = $null
if (Get-Command Get-StoredCredential -ErrorAction SilentlyContinue) {
  $cred = Get-StoredCredential -Target $service
  if ($cred) { $pass = $cred.GetNetworkCredential().Password }
}
if (-not $pass) {
  foreach ($py in @("python", "python3")) {
    if (Get-Command $py -ErrorAction SilentlyContinue) {
      $user = if ($env:WP_API_USERNAME) { $env:WP_API_USERNAME } else { "agent" }
      $pass = & $py -m keyring get $service $user 2>$null
      if ($pass) { break }
    }
  }
}
if (-not $pass) {
  Write-Error "Credencial '$service' no encontrada (CredentialManager o python-keyring). Guárdala primero — docs/credentials.md."
  exit 1
}

if ($Check) { Write-Output "OK Credencial '$service' resuelta."; exit 0 }

$env:WP_API_PASSWORD = $pass
npx -y "@automattic/mcp-wordpress-remote@$proxyVersion"
