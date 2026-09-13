$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
Set-Location $projectRoot
$env:APPDATA=Join-Path $projectRoot 'tools/userdata'
$env:LOCALAPPDATA=$env:APPDATA
$env:CRUSH_RECORD_DIR=Join-Path $projectRoot 'records/m6-review01'
$env:CRUSH_SAVE_PATH=Join-Path $env:APPDATA ('m6-final-demo-'+[guid]::NewGuid()+'.json')
& ./builds/M6-review-01/CrushFactory.exe --write-movie "$env:CRUSH_RECORD_DIR/gameplay-session.avi" --fixed-fps 30 --log-file "$env:CRUSH_RECORD_DIR/gameplay-session.log" -- --gameplay-demo | Out-Default
if ($LASTEXITCODE -ne 0) {throw 'Demo failed'}
& ./builds/M6-review-01/CrushFactory.exe --write-movie "$env:CRUSH_RECORD_DIR/gameplay-restart.avi" --fixed-fps 30 --log-file "$env:CRUSH_RECORD_DIR/gameplay-restart.log" -- --gameplay-resume | Out-Default
if ($LASTEXITCODE -ne 0) {throw 'Resume failed'}
$env:CRUSH_SAVE_PATH=Join-Path $env:APPDATA ('m6-final-verify-'+[guid]::NewGuid()+'.json')
& ./builds/M6-review-01/CrushFactory.exe --log-file "$env:CRUSH_RECORD_DIR/gameplay-verify.log" -- --gameplay-verify | Out-Default
if ($LASTEXITCODE -ne 0) {throw 'Verify process failed'}
foreach ($name in @('gameplay-session','gameplay-resume','gameplay-verify')) {
 $result=Get-Content "$env:CRUSH_RECORD_DIR/$name.json" -Raw | ConvertFrom-Json
 if ($result.failures.Count -gt 0) {throw ($result.failures -join ', ')}
}
& tools/ffmpeg/ffmpeg.exe -hide_banner -loglevel error -y -f concat -safe 0 -i records/m6-review01/concat.txt -c:v libx264 -preset fast -crf 20 -pix_fmt yuv420p -c:a aac -b:a 160k -movflags +faststart records/m6-review01/gameplay-full.mp4
if ($LASTEXITCODE -ne 0) {throw 'Video encode failed'}
