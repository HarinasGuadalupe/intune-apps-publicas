# =============================================
# Uninstall script
# App: Synology Drive Client
#
# El instalador usa Windows Installer (MSI) por debajo. El ProductCode
# (GUID) cambia en cada actualizacion, asi que se busca dinamicamente
# en el registro por DisplayName en vez de tener el GUID fijo aqui.
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
    Write-Log "Iniciando desinstalacion de Synology Drive Client"

    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $expectedDisplayName = "Synology Drive Client*"

    $entry = $null
    foreach ($path in $uninstallPaths) {
        $entry = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like $expectedDisplayName } |
            Select-Object -First 1
        if ($entry) { break }
    }

    if (-not $entry) {
        Write-Log "No se encontro una instalacion de Synology Drive Client para desinstalar."
        exit 0
    }

    $productCode = $entry.PSChildName
    Write-Log "Encontrado: $($entry.DisplayName) - ProductCode $productCode"

    $arguments = "/x $productCode /qn /norestart"
    Write-Log "Ejecutando: msiexec $arguments"
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -PassThru
    $exitCode = $process.ExitCode
    Write-Log "msiexec finalizo con exit code $exitCode"

    if ($exitCode -ne 0) {
        exit $exitCode
    }

    Write-Log "Desinstalacion completada exitosamente"
    exit 0
} catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
