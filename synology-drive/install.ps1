# =============================================
# Install script
# App: Synology Drive Client 4.2.0-20058 (x64)
#
# NOTA: A diferencia de Firefox/Chrome, esta URL NO es un permalink de
# "siempre ultima version" -- Synology no ofrece uno. Es una version
# fija (4.2.0-20058). Cuando salga una nueva actualizacion hay que
# regenerar $downloadUrl revisando https://archive.synology.com/download/Utility/SynologyDriveClient/
# y actualizar tambien detect.ps1 y uninstall.ps1. Ver notes en metadata.json.
# =============================================

$ErrorActionPreference = "Stop"
$logDir = "C:\ProgramData\IntuneLogs"
$logFile = Join-Path $logDir "synology-drive.log"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append -Encoding utf8
}

try {
    Write-Log "Iniciando instalacion de Synology Drive Client 4.2.0-20058 (x64)"

    # 1. Forzar TLS 1.2+ (evita fallos de descarga en equipos con PowerShell viejo)
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # 2. URL de descarga (version fija 4.2.0-20058, x64 MSI)
    $downloadUrl = "https://global.synologydownload.com/download/Utility/SynologyDriveClient/4.2.0-20058/Windows/Installer/x86_64/Synology%20Drive%20Client-4.2.0-20058-x64.msi"
    $installerPath = Join-Path $env:TEMP "SynologyDriveClient-4.2.0-20058-x64.msi"

    # 3. Descargar instalador (con reintentos basicos)
    #    -TimeoutSec limita cada intento a 2 minutos -- sin esto, un intento
    #    con problemas de red puede colgarse muchos minutos antes de fallar,
    #    consumiendo los 3 intentos disponibles con muy poco margen real.
    $maxRetries = 3
    $attempt = 0
    $downloaded = $false
    while (-not $downloaded -and $attempt -lt $maxRetries) {
        $attempt++
        try {
            Write-Log "Intento de descarga $attempt de $maxRetries"
            Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing -TimeoutSec 120
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

    # 5. Verificar la firma digital del instalador (Synology no publica un
    #    hash SHA256 verificable para este build)
    $signature = Get-AuthenticodeSignature -FilePath $installerPath
    if ($signature.Status -ne "Valid" -or $signature.SignerCertificate.Subject -notmatch "O=Synology") {
        Write-Log "ERROR: firma digital invalida o no corresponde a Synology. Abortando instalacion."
        Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
        exit 1
    }

    # 6. Ejecutar instalacion silenciosa
    #    Si otro MSI se esta instalando al mismo tiempo en el equipo (ej. otra
    #    app Win32 de Intune asignada al mismo grupo piloto), msiexec devuelve
    #    1618 (ERROR_INSTALL_ALREADY_RUNNING) en vez de instalar. Se reintenta
    #    unas cuantas veces con espera antes de darlo por fallido, en lugar de
    #    depender unicamente del reintento externo (mas lento) de Intune.
    $installArgs = "/i `"$installerPath`" /qn /norestart"
    $maxMsiRetries = 5
    $msiRetryDelaySeconds = 30
    $msiAttempt = 0
    do {
        $msiAttempt++
        Write-Log "Ejecutando msiexec (intento $msiAttempt de $maxMsiRetries): $installArgs"
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $installArgs -Wait -PassThru
        $exitCode = $process.ExitCode
        Write-Log "msiexec finalizo con exit code $exitCode"
        if ($exitCode -eq 1618 -and $msiAttempt -lt $maxMsiRetries) {
            Write-Log "1618 = otra instalacion de Windows Installer en curso; esperando $msiRetryDelaySeconds s antes de reintentar"
            Start-Sleep -Seconds $msiRetryDelaySeconds
        }
    } while ($exitCode -eq 1618 -and $msiAttempt -lt $maxMsiRetries)

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
