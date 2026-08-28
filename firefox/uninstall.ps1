# =============================================
# Uninstall script
# App: Mozilla Firefox
# =============================================

$ErrorActionPreference = "Stop"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# El ProductCode del MSI de Firefox cambia en cada release, asi que se
# resuelve el comando de desinstalacion desde el registro Uninstall en
# lugar de fijar un GUID.
$uninstallKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$app = Get-ItemProperty -Path $uninstallKeys -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like "Mozilla Firefox*" } |
    Select-Object -First 1

if (-not $app) {
    Write-Output "Firefox no esta instalado. Nada que desinstalar."
    exit 0
}

$uninstallString = $app.QuietUninstallString
if (-not $uninstallString) { $uninstallString = $app.UninstallString }

if ($uninstallString -match "msiexec") {
    $productCode = [regex]::Match($uninstallString, "\{[0-9A-Fa-f\-]{36}\}").Value
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $productCode /qn /norestart" -Wait -PassThru
} else {
    # Instalador clasico NSIS (fallback si en algun momento se instalo con el .exe en vez del MSI)
    if ($uninstallString -match '^"([^"]+)"\s*(.*)$') {
        $exePath = $Matches[1]
        $exeArgs = $Matches[2]
    } else {
        $exePath, $exeArgs = $uninstallString -split ' ', 2
    }
    $process = Start-Process -FilePath $exePath -ArgumentList "$exeArgs -ms" -Wait -PassThru
}

$exitCode = $process.ExitCode
if ($exitCode -ne 0) {
    Write-Error "La desinstalacion de Firefox finalizo con codigo $exitCode"
    exit $exitCode
}

Write-Output "Firefox desinstalado correctamente."
exit 0
