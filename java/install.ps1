# =============================================
# Install script
# App: Java 8 Update 503 (Oracle JRE, x64)
#
# ADVERTENCIA DE LICENCIAMIENTO: Oracle Java SE 8 (8u211+) requiere una
# suscripcion "Oracle Java SE Universal Subscription" (o soporte Oracle
# vigente) para uso comercial/de produccion. No usar en despliegue masivo
# sin confirmar que la organizacion tiene esa suscripcion activa.
#
# NOTA: A diferencia de otras apps de este repo, esta URL NO es un
# permalink de "siempre ultima version" -- Oracle no ofrece uno. Es una
# version fija (8u503). Cuando salga una nueva actualizacion hay que
# regenerar $downloadUrl visitando https://www.java.com/en/download/manual.jsp
# y actualizar tambien detect.ps1 y uninstall.ps1. Ver notes en metadata.json.
# =============================================

$ErrorActionPreference = "Stop"
$logDir = "C:\ProgramData\IntuneLogs"
$logFile = Join-Path $logDir "java.log"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append -Encoding utf8
}

try {
    Write-Log "Iniciando instalacion de Java 8 Update 503 (Oracle JRE x64)"

    # 1. Forzar TLS 1.2+ (evita fallos de descarga en equipos con PowerShell viejo)
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # 2. URL de descarga (version fija 8u503, offline x64 - BundleId 253608)
    $downloadUrl = "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=253608_2fde65a2208f40a5b5f4c844b0dff092"
    $installerPath = Join-Path $env:TEMP "jre-8u503-windows-x64.exe"

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

    # 5. Oracle no publica un hash SHA256 verificable en la pagina de descarga
    #    para este build; se omite verificacion de hash (ver notes en metadata.json).

    # 6. Ejecutar instalacion silenciosa
    #    Argumentos segun documentacion oficial de Oracle (Table 20-1,
    #    Configuration File Options):
    #    INSTALL_SILENT=1  -> instalacion no interactiva
    #    NOSTARTMENU=1     -> sin accesos directos en el menu inicio
    #    WEB_JAVA=0        -> deshabilita el plugin de Java en navegadores
    #    WEB_ANALYTICS=0   -> no envia estadisticas de instalacion a Oracle
    #    STATIC=1          -> evita que auto-update sobrescriba esta version
    #    REBOOT=0          -> no reiniciar automaticamente
    $installArgs = "/s INSTALL_SILENT=1 NOSTARTMENU=1 WEB_JAVA=0 WEB_ANALYTICS=0 STATIC=1 REBOOT=0"
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
