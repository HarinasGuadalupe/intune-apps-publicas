# =============================================
# Install script
# App: Adobe Acrobat Reader DC 26.001.21789 (x64)
#
# NOTA: A diferencia de Firefox, esta URL NO es un permalink de
# "siempre ultima version" -- Adobe no ofrece uno para Acrobat Reader.
# Es una version fija (26.001.21789). Cuando salga una nueva actualizacion
# hay que regenerar $downloadUrl revisando las release notes en
# https://www.adobe.com/devnet-docs/acrobatetk/tools/ReleaseNotesDC/index.html
# y actualizar tambien detect.ps1 y uninstall.ps1. Ver notes en metadata.json.
# =============================================

$ErrorActionPreference = "Stop"
$logDir = "C:\ProgramData\IntuneLogs"
$logFile = Join-Path $logDir "adobe-reader.log"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append -Encoding utf8
}

try {
    Write-Log "Iniciando instalacion de Adobe Acrobat Reader DC 26.001.21789 (x64)"

    # 1. Forzar TLS 1.2+ (evita fallos de descarga en equipos con PowerShell viejo)
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # 2. URL de descarga (version fija 26.001.21789, build 2600121789, x64 en_US)
    $downloadUrl = "https://ardownload2.adobe.com/pub/adobe/acrobat/win/AcrobatDC/2600121789/AcroRdrDCx642600121789_en_US.exe"
    $installerPath = Join-Path $env:TEMP "AcroRdrDCx642600121789_en_US.exe"

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

    # 5. Adobe no publica un hash SHA256 verificable para este build; en su
    #    lugar se valida la firma digital del instalador (Authenticode).
    $signature = Get-AuthenticodeSignature -FilePath $installerPath
    if ($signature.Status -ne "Valid" -or $signature.SignerCertificate.Subject -notmatch "O=Adobe") {
        Write-Log "ERROR: firma digital invalida o no corresponde a Adobe. Abortando instalacion."
        Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
        exit 1
    }

    # 6. Ejecutar instalacion silenciosa
    #    Argumentos segun documentacion oficial de Adobe
    #    (adobe.com/devnet-docs/acrobatetk/tools/DesktopDeployment/cmdline.html):
    #    /sAll             -> suprime toda la interfaz del bootstrapper
    #    /rs                -> suprime el reinicio automatico
    #    /msi EULA_ACCEPT=YES /qn -> acepta el EULA y pasa instalacion silenciosa al MSI interno
    $installArgs = "/sAll /rs /msi EULA_ACCEPT=YES /qn"
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
