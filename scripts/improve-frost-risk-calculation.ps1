$ErrorActionPreference = 'Stop'

$repo = Resolve-Path (Join-Path $PSScriptRoot '..')
$mainPath = Join-Path $repo 'lib\main.dart'
$manifestPath = Join-Path $repo 'android\app\src\main\AndroidManifest.xml'

if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }
if (-not (Test-Path $manifestPath)) { throw 'Could not find AndroidManifest.xml' }

Write-Host 'Ensuring Android internet permission...'
$manifest = Get-Content $manifestPath -Raw
if ($manifest -notmatch 'android.permission.INTERNET') {
  $manifest = $manifest -replace '(<manifest[^>]*>)', "`$1`r`n    <uses-permission android:name=`"android.permission.INTERNET`" />"
  Set-Content -Path $manifestPath -Value $manifest -NoNewline
}

$src = Get-Content $mainPath -Raw

# Add a clearer frost label helper.
if ($src -notmatch 'String frostRiskBand') {
$frostLabel = @'

String frostRiskBand(int risk) {
  if (risk >= 80) return 'Severe';
  if (risk >= 60) return 'High';
  if (risk >= 35) return 'Watch';
  if (risk >= 15) return 'Low';
  return 'Very low';
}

'@
  $src = $src.Replace('FrostMeterReport buildFrostMeterReport', $frostLabel + 'FrostMeterReport buildFrostMeterReport')
}

# Replace the frost calculation with a stronger horticultural heuristic.
$newFrostFunction = @'
FrostMeterReport buildFrostMeterReport({
  required List<DateTime> times,
  required List<int> temp,
  required List<int> humidity,
  required List<int> wind,
  List<int> apparentTemp = const [],
  List<int> dewPoint = const [],
  List<int> cloudCover = const [],
}) {
  final now = DateTime.now();
  final sampleIndexes = <int>[];
  final count = [times.length, temp.length, humidity.length, wind.length].reduce((a, b) => a < b ? a : b);
  for (var i = 0; i < count; i++) {
    final time = times[i];
    if (time.isBefore(now)) continue;
    final isOvernight = time.hour >= 17 || time.hour <= 8;
    if (!isOvernight) continue;
    sampleIndexes.add(i);
    if (sampleIndexes.length >= 18) break;
  }

  if (sampleIndexes.isEmpty) {
    return const FrostMeterReport(risk: 0, lowC: 0, title: 'Frost risk unavailable', detail: 'No overnight forecast hours were returned.', window: 'Tonight', color: C.muted, background: C.soft, source: 'Forecast loaded but no overnight data found');
  }

  var lowIndex = sampleIndexes.first;
  for (final i in sampleIndexes) {
    final comparisonTemp = apparentTemp.length > i ? apparentTemp[i] : temp[i];
    final currentLow = apparentTemp.length > lowIndex ? apparentTemp[lowIndex] : temp[lowIndex];
    if (comparisonTemp < currentLow) lowIndex = i;
  }

  final lowAir = temp[lowIndex];
  final feelsLikeLow = apparentTemp.length > lowIndex ? apparentTemp[lowIndex] : lowAir;
  final lowForRisk = feelsLikeLow < lowAir ? feelsLikeLow : lowAir;
  final highHumidity = sampleIndexes.map((i) => humidity[i]).fold<int>(0, (a, b) => a > b ? a : b);
  final avgWind = (sampleIndexes.map((i) => wind[i]).fold<int>(0, (a, b) => a + b) / sampleIndexes.length).round();
  final lowestDew = dewPoint.length > lowIndex ? dewPoint[lowIndex] : null;
  final cloud = cloudCover.length > lowIndex ? cloudCover[lowIndex] : null;

  var risk = 0;
  if (lowForRisk <= -2) {
    risk = 98;
  } else if (lowForRisk <= -1) {
    risk = 92;
  } else if (lowForRisk <= 0) {
    risk = 82;
  } else if (lowForRisk <= 1) {
    risk = 70;
  } else if (lowForRisk <= 2) {
    risk = 58;
  } else if (lowForRisk <= 3) {
    risk = 42;
  } else if (lowForRisk <= 4) {
    risk = 28;
  } else if (lowForRisk <= 6) {
    risk = 12;
  } else {
    risk = 3;
  }

  if (highHumidity >= 95) {
    risk += 10;
  } else if (highHumidity >= 88) {
    risk += 6;
  }

  if (avgWind <= 4) {
    risk += 12;
  } else if (avgWind <= 8) {
    risk += 6;
  } else if (avgWind >= 18) {
    risk -= 12;
  }

  if (cloud != null) {
    if (cloud <= 25) risk += 10;
    if (cloud >= 80) risk -= 8;
  }

  if (lowestDew != null && lowestDew <= 1 && lowAir <= 4) risk += 8;

  risk = risk.clamp(0, 100).toInt();
  final time = times[lowIndex];
  final band = frostRiskBand(risk);
  final color = risk >= 60 ? C.red : risk >= 35 ? C.amber : C.forest;
  final background = risk >= 60 ? C.redSoft : risk >= 35 ? C.amberSoft : C.forestSoft;
  final extra = <String>[
    'air ${lowAir}°C',
    'feels ${feelsLikeLow}°C',
    'humidity ${highHumidity}%',
    'wind ${avgWind} km/h',
    if (cloud != null) 'cloud $cloud%',
    if (lowestDew != null) 'dew $lowestDew°C',
  ].join(' · ');

  return FrostMeterReport(
    risk: risk,
    lowC: lowForRisk,
    title: 'Frost risk: $band ($risk%)',
    detail: extra,
    window: timingLabel(time),
    color: color,
    background: background,
    source: 'Live frost calculation · forecast inputs from Marlborough / Blenheim',
  );
}
'@

if ($src -match 'FrostMeterReport buildFrostMeterReport\(') {
  $src = [regex]::Replace($src, 'FrostMeterReport buildFrostMeterReport\([\s\S]*?\r?\n\}\r?\n\r?\nFrostMeterReport fallbackFrostMeter', $newFrostFunction + "`r`nFrostMeterReport fallbackFrostMeter", 1)
} else {
  throw 'Could not find buildFrostMeterReport to replace. Apply add-automatic-actions-frost-meter.ps1 first.'
}

# Improve fallback to also show a clear risk percentage.
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
    window: weather.bestSprayWindow,
    color: color,
    background: background,
    source: 'Fallback frost estimate · live forecast did not return full frost inputs',
  );
}
'@
$src = [regex]::Replace($src, 'FrostMeterReport fallbackFrostMeter\([\s\S]*?\r?\n\}\r?\n\r?\nAutomaticActionReport buildAutomaticActionReport', $newFallback + "`r`nAutomaticActionReport buildAutomaticActionReport", 1)

# Upgrade the Open-Meteo request with better frost variables and parse them.
$src = $src.Replace(
  "'hourly': 'precipitation_probability,relative_humidity_2m,wind_speed_10m,temperature_2m'",
  "'hourly': 'precipitation_probability,relative_humidity_2m,wind_speed_10m,temperature_2m,apparent_temperature,dew_point_2m,cloud_cover'"
)

if ($src -notmatch "hourly\['apparent_temperature'\]") {
  $src = $src.Replace(
    "final temp = (hourly['temperature_2m'] as List).whereType<num>().map((v) => v.round()).toList();",
    "final temp = (hourly['temperature_2m'] as List).whereType<num>().map((v) => v.round()).toList();`r`n      final apparentTemp = (hourly['apparent_temperature'] as List? ?? const []).whereType<num>().map((v) => v.round()).toList();`r`n      final dewPoint = (hourly['dew_point_2m'] as List? ?? const []).whereType<num>().map((v) => v.round()).toList();`r`n      final cloudCover = (hourly['cloud_cover'] as List? ?? const []).whereType<num>().map((v) => v.round()).toList();"
  )
}

$src = $src.Replace(
  'final frost = buildFrostMeterReport(times: times, temp: temp, humidity: humidity, wind: wind);',
  'final frost = buildFrostMeterReport(times: times, temp: temp, humidity: humidity, wind: wind, apparentTemp: apparentTemp, dewPoint: dewPoint, cloudCover: cloudCover);'
)

# Make card wording impossible to miss.
$src = $src.Replace(
  "const Text('Frost live meter', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: C.forest))",
  "const Text('Frost risk meter', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: C.forest))"
)

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
$manifestCheck = Get-Content $manifestPath -Raw
foreach ($marker in @('frostRiskBand', 'apparent_temperature', 'dew_point_2m', 'cloud_cover', 'Frost risk:', 'fallback estimate')) {
  if ($check -notmatch [regex]::Escape($marker)) { throw "Missing improved frost marker: $marker" }
}
if ($manifestCheck -notmatch 'android.permission.INTERNET') { throw 'Missing INTERNET permission in manifest.' }

Write-Host 'Improved frost risk calculation applied.'
Write-Host 'The frost meter now calculates a visible risk percentage using overnight low/feels-like temp, humidity, wind, cloud cover and dew point when available.'
Write-Host 'Next: flutter clean; flutter pub get; flutter analyze; flutter run'
