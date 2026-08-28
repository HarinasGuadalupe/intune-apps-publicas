# =============================================
# Detection script
# App: TeamViewer
# Exit 0 + stdout = instalado. Exit 1 sin output = no instalado.
#
# Nota: install.ps1 siempre instala la ultima version publicada por
# TeamViewer, asi que esta deteccion es de presencia (no fija un numero
# de version esperado).
# =============================================

$candidatePaths = @(
    (Join-Path $env:ProgramFiles "TeamViewer\TeamViewer.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "TeamViewer\TeamViewer.exe")
)

$tvExe = $candidatePaths | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if (-not $tvExe) {
    exit 1
}

$version = (Get-Item $tvExe).VersionInfo.ProductVersion
Write-Output "TeamViewer $version detectado."
exit 0
