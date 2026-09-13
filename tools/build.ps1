$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
$env:APPDATA = Join-Path $projectRoot 'tools/userdata'
$env:LOCALAPPDATA = $env:APPDATA
$godotExe = Join-Path $PSScriptRoot 'godot/Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $godotExe)) { throw 'Godot 4.7.2 standard missing; see README.md' }
& $godotExe --headless --path $projectRoot --editor --import --quit --log-file records/review02/import-final.log
if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
foreach ($test in @('solver_test','cardboard_test','controller_test','review02_test')) {
    & $godotExe --headless --path $projectRoot --script "tests/$test.gd" --log-file "records/review02/$test.log"
    if ($LASTEXITCODE -ne 0) { throw "Test failed: $test" }
}
$buildDir = Join-Path $projectRoot 'builds/M1-review-02'
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
& $godotExe --headless --path $projectRoot --export-release 'Windows Desktop' "$buildDir/CrushFactory.exe" --log-file records/review02/export-final.log
if ($LASTEXITCODE -ne 0) { throw 'Export failed' }
Copy-Item -LiteralPath (Join-Path $projectRoot 'README.md') -Destination $buildDir
Copy-Item -LiteralPath (Join-Path $projectRoot 'ASSET_LICENSES.md') -Destination $buildDir
Copy-Item -LiteralPath (Join-Path $projectRoot 'licenses') -Destination $buildDir -Recurse -Force
Get-FileHash -LiteralPath "$buildDir/CrushFactory.exe" -Algorithm SHA256 | Format-List
