# =============================================
# Detection script
# App: Google Chrome
# Exit 0 + stdout = instalado. Exit 1 sin output = no instalado.
#
# Nota: install.ps1 siempre instala la ultima version publicada por
# Google, asi que esta deteccion es de presencia (no fija un numero
# de version esperado) para no tener que tocar Intune en cada release
# de Chrome. Chrome se mantiene actualizado por su propio updater
# (Google Update).
# =============================================

$candidatePaths = @(
    (Join-Path $env:ProgramFiles "Google\Chrome\Application\chrome.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "Google\Chrome\Application\chrome.exe")
)

$chromeExe = $candidatePaths | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if (-not $chromeExe) {
    exit 1
}

$version = (Get-Item $chromeExe).VersionInfo.ProductVersion
Write-Output "Google Chrome $version detectado."
exit 0
