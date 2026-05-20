$ErrorActionPreference = 'Stop'

$repo = Resolve-Path (Join-Path $PSScriptRoot '..')
$mainPath = Join-Path $repo 'lib\main.dart'
$manifestPath = Join-Path $repo 'android\app\src\main\AndroidManifest.xml'

if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }
if (-not (Test-Path $manifestPath)) { throw 'Could not find AndroidManifest.xml' }

Write-Host 'Ensuring Android INTERNET permission...'
$manifest = Get-Content $manifestPath -Raw
if ($manifest -notmatch 'android.permission.INTERNET') {
  $manifest = $manifest -replace '(<manifest[^>]*>)', "`$1`r`n    <uses-permission android:name=`"android.permission.INTERNET`" />"
  Set-Content -Path $manifestPath -Value $manifest -NoNewline
}

Write-Host 'Replacing old frost waiting initializer...'
$src = Get-Content $mainPath -Raw

$oldInitializer = "FrostMeterReport frostMeter = const FrostMeterReport(risk: 0, lowC: 0, title: 'Frost meter loading', detail: 'Waiting for live overnight forecast.', window: 'Tonight', color: C.muted, background: C.soft, source: 'Waiting for live forecast');"
$newInitializer = "FrostMeterReport frostMeter = const FrostMeterReport(risk: 25, lowC: 4, title: 'Frost risk: estimating (25%)', detail: 'Fallback estimate until live overnight forecast loads.', window: 'Tonight', color: C.amber, background: C.amberSoft, source: 'Fallback frost estimate');"

if ($src.Contains($oldInitializer)) {
  $src = $src.Replace($oldInitializer, $newInitializer)
} else {
  $src = [regex]::Replace(
    $src,
    "FrostMeterReport frostMeter = const FrostMeterReport\(risk: 0, lowC: 0, title: 'Frost meter loading',[^;]*source: 'Waiting for live forecast'\);",
    $newInitializer,
    1
  )
}

# Replace any remaining user-visible waiting phrases.
$src = $src.Replace('Waiting for live forecast', 'Fallback frost estimate')
$src = $src.Replace('Waiting for live overnight forecast.', 'Fallback estimate until live overnight forecast loads.')
$src = $src.Replace('Frost meter loading', 'Frost risk: estimating')
$src = $src.Replace('Loading frost forecast', 'Frost risk: estimating')
$src = $src.Replace('Connecting to live forecast', 'Fallback frost estimate')

# Make sure initState sets a fallback before trying live weather, when fallbackFrostMeter exists.
if ($src -match 'fallbackFrostMeter\(weather\)' -and $src -notmatch 'frostMeter = fallbackFrostMeter\(weather\);\r?\n\s*fetchLiveWeather\(\);') {
  $src = $src.Replace('    fetchLiveWeather();', "    frostMeter = fallbackFrostMeter(weather);`r`n    fetchLiveWeather();")
}

# Make failed weather fetch update the card visibly if the catch is still silent.
$src = [regex]::Replace(
  $src,
  "\} catch \(_\) \{\s*// Keep offline fallback\.\s*\}",
  "} catch (_) {`r`n      if (!mounted) return;`r`n      setState(() {`r`n        frostMeter = fallbackFrostMeter(weather);`r`n        message = 'Live frost forecast did not load — showing fallback frost risk';`r`n      });`r`n    }",
  1
)

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
$manifestCheck = Get-Content $manifestPath -Raw
if ($manifestCheck -notmatch 'android.permission.INTERNET') { throw 'INTERNET permission is still missing.' }
if ($check -match 'Waiting for live forecast') { throw 'Fix failed: Waiting for live forecast still exists.' }
if ($check -match 'Frost meter loading') { throw 'Fix failed: Frost meter loading still exists.' }
if ($check -notmatch 'Frost risk: estimating') { throw 'Fix failed: visible frost risk fallback missing.' }
if ($check -notmatch 'Fallback frost estimate') { throw 'Fix failed: fallback source missing.' }

Write-Host 'Fixed frost waiting state.' -ForegroundColor Green
Write-Host 'The frost card now starts with Frost risk: estimating and should update if live forecast loads.'
Write-Host 'Next: flutter clean; flutter pub get; flutter analyze; flutter run'
