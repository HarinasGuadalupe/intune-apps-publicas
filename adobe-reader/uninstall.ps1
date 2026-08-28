# =============================================
# Uninstall script
# App: Adobe Acrobat Reader DC 26.001.21789 (x64)
#
# El instalador de Adobe Reader usa Windows Installer (MSI) por debajo.
# El ProductCode (GUID) cambia en cada actualizacion, asi que se resuelve
# el comando de desinstalacion dinamicamente desde el registro en vez de
# tener el GUID fijo en este script.
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
    Write-Log "Iniciando desinstalacion de Adobe Acrobat Reader DC"

    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $expectedDisplayName = "Adobe Acrobat Reader*"

    $entry = $null
    foreach ($path in $uninstallPaths) {
        $entry = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like $expectedDisplayName } |
            Select-Object -First 1
        if ($entry) { break }
    }

    if (-not $entry) {
        Write-Log "No se encontro una instalacion de Adobe Acrobat Reader para desinstalar."
        exit 0
    }

    Write-Log "Encontrado: $($entry.DisplayName) (version $($entry.DisplayVersion))"

    $uninstallString = $entry.QuietUninstallString
    if (-not $uninstallString) { $uninstallString = $entry.UninstallString }

    if ($uninstallString -match "msiexec") {
        $productCode = [regex]::Match($uninstallString, "\{[0-9A-Fa-f\-]{36}\}").Value
        Write-Log "Desinstalando via msiexec, ProductCode $productCode"
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $productCode /qn /norestart" -Wait -PassThru
    } else {
        if ($uninstallString -match '^"([^"]+)"\s*(.*)$') {
            $exePath = $Matches[1]
            $exeArgs = $Matches[2]
        } else {
            $exePath, $exeArgs = $uninstallString -split ' ', 2
        }
        Write-Log "Desinstalando via ejecutable: $exePath $exeArgs"
        $process = Start-Process -FilePath $exePath -ArgumentList "$exeArgs /qn /norestart" -Wait -PassThru
    }

    $exitCode = $process.ExitCode
    Write-Log "Desinstalador finalizo con exit code $exitCode"

    if ($exitCode -ne 0) {
        exit $exitCode
    }

    Write-Log "Desinstalacion completada exitosamente"
    exit 0
} catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}
