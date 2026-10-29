$ErrorActionPreference = 'Stop'
$bundledPython = Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
if (Test-Path -LiteralPath $bundledPython) {
  $pythonRuntime = $bundledPython
} else {
  $pythonRuntime = (Get-Command python -ErrorAction Stop).Source
}
Write-Host 'AURYA - previa local de desenvolvimento'
Write-Host 'Abra http://127.0.0.1:8765/preview/ no navegador.'
Write-Host 'Mantenha esta janela aberta. Ctrl+C encerra a previa.'
& $pythonRuntime -m http.server 8765 --bind 127.0.0.1 --directory $PSScriptRoot
