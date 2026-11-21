# Builds the signed release AAB for Google Play.
#
# Before running, set these environment variables (never commit them):
#   $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH     = "C:\secure\kavaryn-upload.keystore"
#   $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER     = "kavaryn-upload"
#   $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = "<your password>"
# and create release_config\ads_release.json (see release_config.example).
#
# Usage:  powershell -ExecutionPolicy Bypass -File tools\build_release.ps1

param(
    [string]$Godot = ".tools\Godot_v4.7.2-stable_win64_console.exe",
    [string]$Preset = "Android Release",
    [string]$Output = "build\kavaryn-release.aab"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

foreach ($name in "GODOT_ANDROID_KEYSTORE_RELEASE_PATH", "GODOT_ANDROID_KEYSTORE_RELEASE_USER", "GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD") {
    if (-not [Environment]::GetEnvironmentVariable($name)) { throw "Environment variable $name is not set." }
}
if (-not (Test-Path $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH)) { throw "Keystore not found: $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH" }

$adsConfig = "release_config\ads_release.json"
if (-not (Test-Path $adsConfig)) { throw "$adsConfig is missing. Copy release_config.example\ads_release.json and fill in your real AdMob ids." }
$ads = Get-Content $adsConfig -Raw | ConvertFrom-Json
if ($ads.android_app_id -notmatch '^ca-app-pub-\d+~\d+$') { throw "android_app_id in $adsConfig does not look like an AdMob app id." }
if ($ads.android_app_id -like "ca-app-pub-3940256099942544*" -or $ads.rewarded_unit_id -like "ca-app-pub-3940256099942544*") {
    throw "$adsConfig still contains Google's TEST ids. Put your real ids there for a release build."
}

if ((Select-String -Path "export_presets.cfg" -Pattern "com.yourstudio.kaaval" -Quiet)) {
    throw "export_presets.cfg still uses the placeholder package name com.yourstudio.kaaval. Choose your final package name first (it can never be changed after publishing)."
}

Write-Host "Running tests..."
& $Godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
if ($LASTEXITCODE -ne 0) { throw "Tests failed; not building." }

# The AdMob app id goes into AndroidManifest.xml at export time from a project
# setting. Inject the real one for this export only, then restore the file.
$projectFile = "project.godot"
$original = [System.IO.File]::ReadAllText((Resolve-Path $projectFile))
try {
    $patched = $original.TrimEnd() + "`n`n[admob]`n`ngeneral/android/app_id=`"$($ads.android_app_id)`"`n"
    [System.IO.File]::WriteAllText((Resolve-Path $projectFile), $patched)
    New-Item -ItemType Directory -Force (Split-Path $Output) | Out-Null
    Write-Host "Exporting $Preset -> $Output"
    & $Godot --headless --path . --export-release $Preset $Output
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $Output)) { throw "Export failed." }
}
finally {
    [System.IO.File]::WriteAllText((Resolve-Path $projectFile), $original)
}
Write-Host "Done: $Output"
