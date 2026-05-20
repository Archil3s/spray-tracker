$ErrorActionPreference = 'Stop'

$repo = Resolve-Path (Join-Path $PSScriptRoot '..')
$mainPath = Join-Path $repo 'lib\main.dart'
$manifestPath = Join-Path $repo 'android\app\src\main\AndroidManifest.xml'

if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }
if (-not (Test-Path $manifestPath)) { throw 'Could not find AndroidManifest.xml' }

Write-Host 'Repairing Android internet permission...'
$manifest = Get-Content $manifestPath -Raw
if ($manifest -notmatch 'android.permission.INTERNET') {
  $manifest = $manifest.Replace('<manifest ', '<manifest ')
  $manifest = $manifest -replace '(<manifest[^>]*>)', "`$1`r`n    <uses-permission android:name=`"android.permission.INTERNET`" />"
  Set-Content -Path $manifestPath -Value $manifest -NoNewline
}

Write-Host 'Repairing frost/weather fallback UI update...'
$src = Get-Content $mainPath -Raw

# Make the catch block update UI instead of silently leaving the loading card.
$src = $src.Replace(
"    } catch (_) {
      frostMeter = fallbackFrostMeter(weather);
    }
  }",
"    } catch (_) {
      if (!mounted) return;
      setState(() {
        frostMeter = fallbackFrostMeter(weather);
        message = 'Live frost forecast could not load — using fallback weather';
      });
    }
  }"
)

# Also repair older catch style if still present.
$src = $src.Replace(
"    } catch (_) {
      // Keep offline fallback.
    }
  }",
"    } catch (_) {
      if (!mounted) return;
      setState(() {
        frostMeter = fallbackFrostMeter(weather);
        message = 'Live frost forecast could not load — using fallback weather';
      });
    }
  }"
)

# If FrostMeterReport exists, make the initial card say loading live forecast but ensure fallback can overwrite.
$src = $src.Replace(
"FrostMeterReport frostMeter = const FrostMeterReport(risk: 0, lowC: 0, title: 'Frost meter loading', detail: 'Waiting for live overnight forecast.', window: 'Tonight', color: C.muted, background: C.soft, source: 'Waiting for live forecast');",
"FrostMeterReport frostMeter = const FrostMeterReport(risk: 0, lowC: 0, title: 'Loading frost forecast', detail: 'Checking live Marlborough overnight forecast.', window: 'Tonight', color: C.muted, background: C.soft, source: 'Connecting to live forecast');"
)

# Make sure the Open-Meteo URI uses current_weather-safe HTTPS and the forecast_days is present.
if ($src -match "'forecast_days': '2'") {
  $src = $src.Replace("'forecast_days': '2'", "'forecast_days': '3'")
}

Set-Content -Path $mainPath -Value $src -NoNewline

$manifestCheck = Get-Content $manifestPath -Raw
$mainCheck = Get-Content $mainPath -Raw
if ($manifestCheck -notmatch 'android.permission.INTERNET') { throw 'Repair failed: INTERNET permission missing.' }
if ($mainCheck -notmatch 'Live frost forecast could not load') { throw 'Repair failed: fallback UI message missing.' }
if ($mainCheck -notmatch 'fallbackFrostMeter\(weather\)') { throw 'Repair failed: fallback frost meter call missing.' }

Write-Host 'Frost live loading repair applied.'
Write-Host 'Added Android INTERNET permission and UI fallback update.'
Write-Host 'Next: flutter clean; flutter pub get; flutter analyze; flutter run'
