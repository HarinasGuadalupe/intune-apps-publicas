# =============================================
# Detection script
# App: Java 8 Update 503 (Oracle JRE, x64)
#
# Metodo: busca en el registro de Windows (Uninstall, vistas de 64 y
# 32 bits) una entrada cuyo DisplayName coincida con "Java 8 Update 503*".
# El instalador de Oracle JRE registra este DisplayName de forma
# consistente independientemente de la ruta de instalacion.
#
# Debe devolver exit code 0 + algo en stdout si la app esta instalada
# en la version esperada, o exit code 1 (sin output) si no lo esta.
# =============================================

$ErrorActionPreference = "SilentlyContinue"

$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$expectedDisplayName = "Java 8 Update 503*"

$found = $null
foreach ($path in $uninstallPaths) {
    $found = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like $expectedDisplayName } |
        Select-Object -First 1
    if ($found) { break }
}

if ($found) {
    Write-Output "Detectado: $($found.DisplayName) (version $($found.DisplayVersion))"
    exit 0
} else {
    exit 1
}
