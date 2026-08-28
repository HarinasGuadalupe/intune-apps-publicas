# =============================================
# Detection script
# App: Adobe Acrobat Reader DC 26.001.21789 (x64)
#
# Metodo: busca en el registro de Windows (Uninstall, vistas de 64 y
# 32 bits) una entrada cuyo DisplayName coincida con "Adobe Acrobat
# (*-bit)" -- verificado en un equipo real: la build 2026 se registra
# como "Adobe Acrobat (64-bit)", NO como "Adobe Acrobat Reader..." (ese
# era el supuesto original, incorrecto, que causaba falsos negativos de
# deteccion aunque la app SI estuviera instalada). Se deja tambien
# "Adobe Acrobat Reader*" como fallback por si una version futura
# regresa a ese naming.
#
# Comparacion de version: DisplayVersion viene como "26.001.21789" (3
# partes) y [version] deja Revision=-1 en ese caso, mientras que la
# version esperada se definia con 4 partes (Revision=0) -- eso hacia
# que la comparacion -ge fallara SIEMPRE (-1 < 0) aunque el resto
# coincidiera. Se normalizan ambas versiones (reemplazando -1 por 0)
# antes de comparar.
#
# Debe devolver exit code 0 + algo en stdout si la app esta instalada
# en la version esperada o superior, o exit code 1 (sin output) si no.
# =============================================

$ErrorActionPreference = "SilentlyContinue"

function Get-NormalizedVersion {
    param([version]$Version)
    return [version]::new(
        [Math]::Max($Version.Major, 0),
        [Math]::Max($Version.Minor, 0),
        [Math]::Max($Version.Build, 0),
        [Math]::Max($Version.Revision, 0)
    )
}

$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$expectedDisplayNames = @("Adobe Acrobat (*-bit)", "Adobe Acrobat Reader*")
$expectedVersion = Get-NormalizedVersion ([version]"26.1.21789.0")

$found = $null
foreach ($path in $uninstallPaths) {
    foreach ($namePattern in $expectedDisplayNames) {
        $found = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like $namePattern } |
            Select-Object -First 1
        if ($found) { break }
    }
    if ($found) { break }
}

if (-not $found) {
    exit 1
}

$installedVersion = $null
try { $installedVersion = Get-NormalizedVersion ([version]$found.DisplayVersion) } catch { $installedVersion = $null }

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
