# =============================================
# Install script
# App: TeamViewer (cliente publico generico, x64)
#
# NOTA: esta es la variante generica sin Company ID/Assignment ID -- los
# equipos NO se agruparan automaticamente en la Management Console de la
# organizacion. Ver notes en metadata.json si se necesita la variante
# empresarial personalizada.
# =============================================

$ErrorActionPreference = "Stop"
$logDir = "C:\ProgramData\IntuneLogs"
$logFile = Join-Path $logDir "teamviewer.log"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append -Encoding utf8
}

try {
    Write-Log "Iniciando instalacion de TeamViewer (cliente generico x64)"

    # 1. Forzar TLS 1.2+ (evita fallos de descarga en equipos con PowerShell viejo)
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # 2. URL de descarga (permalink publico generico "siempre ultima version")
    $downloadUrl = "https://download.teamviewer.com/download/TeamViewer_Setup_x64.exe"
    $installerPath = Join-Path $env:TEMP "TeamViewer_Setup_x64.exe"

    # 3. Descargar instalador (con reintentos basicos)
    $maxRetries = 3
    $attempt = 0
    $downloaded = $false
    while (-not $downloaded -and $attempt -lt $maxRetries) {
        $attempt++
        try {
            Write-Log "Intento de descarga $attempt de $maxRetries"
            Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
            $downloaded = $true
        } catch {
            Write-Log "Fallo el intento $attempt : $($_.Exception.Message)"
            Start-Sleep -Seconds 5
        }
    }
    if (-not $downloaded) {
        throw "No se pudo descargar el instalador tras $maxRetries intentos."
    }
    Write-Log "Descarga completada: $installerPath"

    # 4. Quitar Mark of the Web (evita bloqueo de SmartScreen)
    Unblock-File -Path $installerPath

    # 5. Verificar la firma digital del instalador (en vez de un hash SHA256 fijo,
    #    porque el archivo cambia en cada release al ser siempre la ultima version)
    $signature = Get-AuthenticodeSignature -FilePath $installerPath
    if ($signature.Status -ne "Valid" -or $signature.SignerCertificate.Subject -notmatch "O=TeamViewer") {
        Write-Log "ERROR: firma digital invalida o no corresponde a TeamViewer. Abortando instalacion."
        Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
        exit 1
    }

    # 6. Ejecutar instalacion silenciosa
    $installArgs = "/S /ACCEPTEULA=1"
    Write-Log "Ejecutando instalador con argumentos: $installArgs"
    $process = Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait -PassThru
    $exitCode = $process.ExitCode
    Write-Log "Instalador finalizo con exit code $exitCode"

    # 7. Limpieza
    Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue

    if ($exitCode -ne 0) {
        Write-Log "ERROR: instalacion fallo con exit code $exitCode"
        exit $exitCode
    }

    Write-Log "Instalacion completada exitosamente"
    exit 0
} catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
