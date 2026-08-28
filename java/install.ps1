# =============================================
# Install script - PENDIENTE (a llenar por la skill)
# App: 
# =============================================

# 1. Forzar TLS 1.2+ (evita fallos de descarga en equipos con PowerShell viejo)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 2. URL de descarga (permalink "siempre última versión")
# $downloadUrl = ""

# 3. Descargar instalador
# $installerPath = "$env:TEMP\installer.exe"
# Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath

# 4. Quitar Mark of the Web (evita bloqueo de SmartScreen)
# Unblock-File -Path $installerPath

# 5. (Opcional recomendado) Verificar hash SHA256 antes de ejecutar

# 6. Ejecutar instalación silenciosa
# Start-Process -FilePath $installerPath -ArgumentList "" -Wait

# 7. Log de resultado
