# =============================================
# Install script
# App: Mozilla Firefox
# =============================================

$ErrorActionPreference = "Stop"

# 1. Forzar TLS 1.2+ (evita fallos de descarga en equipos con PowerShell viejo)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 2. URL de descarga (permalink oficial "siempre ultima version" de Mozilla - MSI empresarial)
$downloadUrl = "https://download.mozilla.org/?product=firefox-msi-latest-ssl&os=win64&lang=es-MX"

# 3. Descargar instalador
$installerPath = Join-Path $env:TEMP "FirefoxSetup.msi"
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
} catch {
    Write-Error "No se pudo descargar el instalador de Firefox: $_"
    exit 1
}

# 4. Quitar Mark of the Web (evita bloqueo de SmartScreen)
Unblock-File -Path $installerPath

# 5. Verificar la firma digital del instalador (en vez de un hash SHA256 fijo,
#    porque el archivo cambia en cada release al ser siempre la ultima version)
$signature = Get-AuthenticodeSignature -FilePath $installerPath
if ($signature.Status -ne "Valid" -or $signature.SignerCertificate.Subject -notmatch "O=Mozilla Corporation") {
    Write-Error "La firma digital del instalador no es valida o no corresponde a Mozilla Corporation. Abortando instalacion."
    Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
    exit 1
}

# 6. Ejecutar instalacion silenciosa
$process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$installerPath`" /qn /norestart" -Wait -PassThru
$exitCode = $process.ExitCode

# 7. Log de resultado
Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue

if ($exitCode -ne 0) {
    Write-Error "La instalacion de Firefox finalizo con codigo $exitCode"
    exit $exitCode
}

Write-Output "Firefox instalado correctamente."
exit 0
