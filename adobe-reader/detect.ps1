# =============================================
# Detection script
# App: Adobe Acrobat Reader DC 26.001.21789 (x64)
#
# Metodo: busca en el registro de Windows (Uninstall, vistas de 64 y
# 32 bits) una entrada cuyo DisplayName coincida con "Adobe Acrobat Reader*"
# y cuya DisplayVersion sea igual o mayor a la version fija instalada por
# install.ps1. Se compara por version (no solo presencia) porque, a
# diferencia de Firefox, esta app no se auto-actualiza a la ultima
# version disponible.
#
# Debe devolver exit code 0 + algo en stdout si la app esta instalada
# en la version esperada o superior, o exit code 1 (sin output) si no.
# =============================================

$ErrorActionPreference = "SilentlyContinue"

$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$expectedDisplayName = "Adobe Acrobat Reader*"
$expectedVersion = [version]"26.1.21789.0"

$found = $null
foreach ($path in $uninstallPaths) {
    $found = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like $expectedDisplayName } |
        Select-Object -First 1
    if ($found) { break }
}

if (-not $found) {
    exit 1
}

$installedVersion = $null
try { $installedVersion = [version]$found.DisplayVersion } catch { $installedVersion = $null }

if ($installedVersion -and $installedVersion -ge $expectedVersion) {
    Write-Output "Detectado: $($found.DisplayName) (version $($found.DisplayVersion))"
    exit 0
} elseif (-not $installedVersion) {
    # DisplayVersion con formato no parseable: se reporta presencia igualmente
    Write-Output "Detectado: $($found.DisplayName) (version $($found.DisplayVersion), no parseable)"
    exit 0
} else {
    exit 1
}
