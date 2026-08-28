# =============================================
# Uninstall script
# App: TeamViewer
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
    Write-Log "Iniciando desinstalacion de TeamViewer"

    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $entry = $null
    foreach ($path in $uninstallPaths) {
        $entry = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -eq "TeamViewer" } |
            Select-Object -First 1
        if ($entry) { break }
    }

    if (-not $entry) {
        Write-Log "TeamViewer no esta instalado. Nada que desinstalar."
        exit 0
    }

    Write-Log "Encontrado: $($entry.DisplayName) (version $($entry.DisplayVersion))"

    $uninstallString = $entry.QuietUninstallString
    if (-not $uninstallString) { $uninstallString = $entry.UninstallString }

    if ($uninstallString -match '^"([^"]+)"\s*(.*)$') {
        $exePath = $Matches[1]
        $exeArgs = $Matches[2]
    } else {
        $exePath, $exeArgs = $uninstallString -split ' ', 2
    }

    if ($exeArgs -notmatch "/S") { $exeArgs = "$exeArgs /S" }

    Write-Log "Ejecutando: `"$exePath`" $exeArgs"
    $process = Start-Process -FilePath $exePath -ArgumentList $exeArgs -Wait -PassThru
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
