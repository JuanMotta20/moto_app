<#
  setup.ps1 - Script de ayuda para preparar el entorno de desarrollo

  - Ejecuta checks básicos (flutter doctor, pub get, analyze, test)
  - Lista emuladores disponibles
  - Si se define la variable $Env:EMULATOR_NAME intenta lanzar ese emulador

  Uso:
    .\setup.ps1            # correr checks
    $env:EMULATOR_NAME='Pixel_3a_API_30'; .\setup.ps1  # intentar lanzar emulador especificado
#>

Write-Host "== Chequeo de Flutter/Dart y dependencias =="
flutter --version
flutter doctor -v

Write-Host "== Obtener dependencias =="
flutter pub get

Write-Host "== Formatear y analizar =="
dart format .
flutter analyze

Write-Host "== Ejecutar tests =="
flutter test

Write-Host "== Emuladores disponibles =="
flutter emulators

if ($Env:EMULATOR_NAME) {
  Write-Host "Intentando lanzar emulador: $Env:EMULATOR_NAME"
  flutter emulators --launch $Env:EMULATOR_NAME
  if ($LASTEXITCODE -ne 0) {
    Write-Host "No se pudo lanzar el emulador. Asegúrate de que exista un AVD con ese nombre."
  }
} else {
  Write-Host "Si quieres lanzar un emulador automáticamente, exporta la variable EMULATOR_NAME."
  Write-Host "Ejemplo (PowerShell): $env:EMULATOR_NAME='Pixel_3a_API_30'; .\\setup.ps1"
}
