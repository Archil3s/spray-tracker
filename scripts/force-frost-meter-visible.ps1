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

$src = Get-Content $mainPath -Raw

# Ensure a clear frost risk label helper exists.
if ($src -notmatch 'String frostRiskBand') {
$frostBand = @'

String frostRiskBand(int risk) {
  if (risk >= 80) return 'Severe';
  if (risk >= 60) return 'High';
  if (risk >= 35) return 'Watch';
  if (risk >= 15) return 'Low';
  return 'Very low';
}

'@
  if ($src -match 'FrostMeterReport buildFrostMeterReport') {
    $src = $src.Replace('FrostMeterReport buildFrostMeterReport', $frostBand + 'FrostMeterReport buildFrostMeterReport')
  } else {
    $src = $src.Replace('GardenTodayReport buildGardenTodayReport', $frostBand + 'GardenTodayReport buildGardenTodayReport')
  }
}

# Replace any waiting initial FrostMeterReport with a visible fallback estimate.
$src = [regex]::Replace(
  $src,
  "FrostMeterReport frostMeter = const FrostMeterReport\([^;]*source: '[^']*'\);",
  "FrostMeterReport frostMeter = const FrostMeterReport(risk: 25, lowC: 4, title: 'Frost risk: estimating (25%)', detail: 'Fallback estimate until live overnight forecast loads.', window: 'Tonight', color: C.amber, background: C.amberSoft, source: 'Fallback frost estimate');"
)

# Make fallbackFrostMeter always produce a clear risk percentage.
$newFallback = @'
FrostMeterReport fallbackFrostMeter(GardenWeatherSnapshot weather) {
  var risk = 0;
  if (weather.temperatureC <= -1) {
    risk = 92;
  } else if (weather.temperatureC <= 0) {
    risk = 82;
  } else if (weather.temperatureC <= 2) {
    risk = 62;
  } else if (weather.temperatureC <= 4) {
    risk = 38;
  } else if (weather.temperatureC <= 6) {
    risk = 16;
  } else {
    risk = 4;
  }
  if (weather.humidityPercent >= 88) risk += 6;
  if (weather.windKph <= 6) risk += 8;
  if (weather.windKph >= 18) risk -= 8;
  risk = risk.clamp(0, 100).toInt();
  final band = frostRiskBand(risk);
  final color = risk >= 60 ? C.red : risk >= 35 ? C.amber : C.forest;
  final background = risk >= 60 ? C.redSoft : risk >= 35 ? C.amberSoft : C.forestSoft;
  return FrostMeterReport(
    risk: risk,
    lowC: weather.temperatureC,
    title: 'Frost risk: $band ($risk%)',
    detail: '${weather.temperatureC}°C · humidity ${weather.humidityPercent}% · wind ${weather.windKph} km/h · fallback estimate',
    window: 'Tonight',
    color: color,
    background: background,
    source: 'Fallback frost estimate · live forecast not loaded yet',
  );
}
'@

if ($src -match 'FrostMeterReport fallbackFrostMeter\(') {
  $src = [regex]::Replace($src, 'FrostMeterReport fallbackFrostMeter\([\s\S]*?\r?\n\}\r?\n\r?\nAutomaticActionReport buildAutomaticActionReport', $newFallback + "`r`nAutomaticActionReport buildAutomaticActionReport", 1)
} else {
  throw 'Could not find fallbackFrostMeter. Apply add-automatic-actions-frost-meter.ps1 first.'
}

# Force initState to set visible fallback immediately before live fetch.
$src = $src.Replace(
  '    fetchLiveWeather();',
  "    frostMeter = fallbackFrostMeter(weather);`r`n    fetchLiveWeather();"
)
# Remove duplicates if script run more than once.
$src = $src.Replace(
  "    frostMeter = fallbackFrostMeter(weather);`r`n    frostMeter = fallbackFrostMeter(weather);`r`n    fetchLiveWeather();",
  "    frostMeter = fallbackFrostMeter(weather);`r`n    fetchLiveWeather();"
)

# Ensure fetch catch updates state and cannot leave waiting text visible.
$src = [regex]::Replace(
  $src,
  "\s*\} catch \(_\) \{\r?\n\s*frostMeter = fallbackFrostMeter\(weather\);\r?\n\s*\}\r?\n\s*\}",
  "    } catch (_) {`r`n      if (!mounted) return;`r`n      setState(() {`r`n        frostMeter = fallbackFrostMeter(weather);`r`n        message = 'Live frost forecast did not load — showing fallback frost risk';`r`n      });`r`n    }`r`n  }",
  1
)
$src = [regex]::Replace(
  $src,
  "\s*\} catch \(_\) \{\r?\n\s*// Keep offline fallback\.\r?\n\s*\}\r?\n\s*\}",
  "    } catch (_) {`r`n      if (!mounted) return;`r`n      setState(() {`r`n        frostMeter = fallbackFrostMeter(weather);`r`n        message = 'Live frost forecast did not load — showing fallback frost risk';`r`n      });`r`n    }`r`n  }",
  1
)

# Make sure visible card wording does not say waiting.
$src = $src.Replace('Waiting for live forecast', 'Fallback frost estimate')
$src = $src.Replace('Frost meter loading', 'Frost risk: estimating')
$src = $src.Replace('Loading frost forecast', 'Frost risk: estimating')
$src = $src.Replace('Waiting for live overnight forecast.', 'Fallback estimate until live forecast loads.')
$src = $src.Replace('Checking live Marlborough overnight forecast.', 'Fallback estimate until live forecast loads.')
$src = $src.Replace('Connecting to live forecast', 'Fallback frost estimate')

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
$manifestCheck = Get-Content $manifestPath -Raw
if ($manifestCheck -notmatch 'android.permission.INTERNET') { throw 'INTERNET permission missing.' }
foreach ($marker in @('Frost risk: estimating', 'fallbackFrostMeter(weather)', 'Live frost forecast did not load', 'Fallback frost estimate')) {
  if ($check -notmatch [regex]::Escape($marker)) { throw "Missing force-visible frost marker: $marker" }
}
if ($check -match 'Waiting for live forecast') { throw 'Waiting text still exists in lib/main.dart.' }

Write-Host 'Forced frost meter visible state.'
Write-Host 'It will show fallback risk immediately, then update to live risk if forecast loads.'
Write-Host 'Next: flutter clean; flutter pub get; flutter analyze; flutter run'
