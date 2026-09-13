$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
$env:APPDATA = Join-Path $projectRoot 'tools/userdata'
$env:LOCALAPPDATA = $env:APPDATA
$env:CRUSH_SAVE_PATH = Join-Path $env:APPDATA ("m4-build-test-"+[guid]::NewGuid()+".json")
$godotExe = Join-Path $PSScriptRoot 'godot/Godot_v4.7.2-stable_win64_console.exe'
$recordDir = Join-Path $projectRoot 'records/m4-review01'
New-Item -ItemType Directory -Force $recordDir | Out-Null
foreach ($test in @('solver_test','cardboard_test','controller_test','review02_test','aluminum_test','aluminum_controller_test','rubber_test','tire_test','progress_test','gameplay_test')) {
    $testLog = Join-Path $recordDir "$test.log"
    $materialArgs = @('--cardboard')
    if ($test.StartsWith('aluminum')) { $materialArgs = @('--aluminum') }
    if ($test -in @('rubber_test','tire_test','progress_test','gameplay_test')) { $materialArgs = @() }
    & $godotExe --headless --path $projectRoot --script "tests/$test.gd" --log-file $testLog -- @materialArgs 2>&1 | Tee-Object -FilePath "$testLog.console"
    if ($LASTEXITCODE -ne 0) { throw "Test failed: $test" }
    $testText = Get-Content -LiteralPath "$testLog.console" -Raw
    if ($testText -match 'ERROR:|WARNING:' -or $testText -notmatch 'PASS|Review02 tests: 0 failures') { throw "Invalid test log: $test" }
}
$buildDir = Join-Path $projectRoot 'builds/M4-review-01'
New-Item -ItemType Directory -Force $buildDir | Out-Null
& $godotExe --headless --path $projectRoot --export-release 'Windows Desktop' "$buildDir/CrushFactory.exe" --log-file "$recordDir/export.log"
if ($LASTEXITCODE -ne 0) { throw 'Export failed' }
Copy-Item -LiteralPath (Join-Path $projectRoot 'README_M4.md') -Destination "$buildDir/README.md"
Copy-Item -LiteralPath (Join-Path $projectRoot 'ASSET_LICENSES.md') -Destination $buildDir
Copy-Item -LiteralPath (Join-Path $projectRoot 'licenses') -Destination $buildDir -Recurse -Force
Get-FileHash -LiteralPath "$buildDir/CrushFactory.exe" -Algorithm SHA256 | Format-List
