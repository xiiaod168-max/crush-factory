$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
Set-Location $projectRoot
$env:APPDATA=Join-Path $projectRoot 'tools/userdata'
$env:LOCALAPPDATA=$env:APPDATA
$env:CRUSH_SAVE_PATH=Join-Path $env:APPDATA ('m4-verify-'+[guid]::NewGuid()+'.json')
$env:CRUSH_RECORD_DIR=Join-Path $projectRoot 'records/m4-review01'
& ./builds/M4-review-01/CrushFactory.exe --log-file "$env:CRUSH_RECORD_DIR/gameplay-verify.log" -- --gameplay-verify | Out-Default
if ($LASTEXITCODE -ne 0) {throw 'Gameplay process failed'}
$result=Get-Content "$env:CRUSH_RECORD_DIR/gameplay-verify.json" -Raw | ConvertFrom-Json
if ($result.failures.Count -gt 0) {throw ($result.failures -join ', ')}
foreach ($material in @('cardboard','aluminum','tire')) {
 $env:CRUSH_RECORD_DIR=Join-Path $projectRoot "records/m4-review01/$material-regression"
 New-Item -ItemType Directory -Force $env:CRUSH_RECORD_DIR | Out-Null
 foreach ($view in @('front','side')) {
  $extra=@("--$material",'--demo')
  if ($view -eq 'side') {$extra+='--side'}
  & ./tools/godot/Godot_v4.7.2-stable_win64_console.exe --path . res://scenes/main.tscn --fixed-fps 30 --log-file "$env:CRUSH_RECORD_DIR/$view.log" -- @extra | Out-Default
  if ($LASTEXITCODE -ne 0) {throw "Regression $material $view failed"}
 }
}
