# =============================================
# Detection script
# App: Mozilla Firefox
# Exit 0 + stdout = instalado. Exit 1 sin output = no instalado.
#
# Nota: install.ps1 siempre instala la ultima version publicada por
# Mozilla, asi que esta deteccion es de presencia (no fija un numero
# de version esperado) para no tener que tocar Intune en cada release
# de Firefox. Firefox se mantiene actualizado por su propio updater.
# =============================================

$candidatePaths = @(
    (Join-Path $env:ProgramFiles "Mozilla Firefox\firefox.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "Mozilla Firefox\firefox.exe")
)

$firefoxExe = $candidatePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $firefoxExe) {
    exit 1
}

$version = (Get-Item $firefoxExe).VersionInfo.ProductVersion
Write-Output "Mozilla Firefox $version detectado."
exit 0
