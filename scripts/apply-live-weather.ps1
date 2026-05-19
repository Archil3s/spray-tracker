$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
$gardenTodayScript = Join-Path $PSScriptRoot 'apply-garden-today.ps1'

if (-not (Test-Path $mainPath)) {
  throw "Could not find lib/main.dart from $PSScriptRoot"
}

$src = Get-Content $mainPath -Raw
if ($src -notmatch 'class GardenTodayReport') {
  if (-not (Test-Path $gardenTodayScript)) {
    throw 'Garden Today script is missing. Run git pull origin main first.'
  }
  & $gardenTodayScript
  $src = Get-Content $mainPath -Raw
}

if ($src -notmatch "import 'dart:convert';") {
  $src = $src.Replace("import 'package:flutter/cupertino.dart';", "import 'dart:convert';`r`n`r`nimport 'package:flutter/cupertino.dart';")
}

if ($src -notmatch "package:http/http.dart") {
  $src = $src.Replace("import 'package:flutter_svg/flutter_svg.dart';", "import 'package:flutter_svg/flutter_svg.dart';`r`nimport 'package:http/http.dart' as http;")
}

if ($src -match 'static const weather = GardenWeatherSnapshot') {
  $src = $src.Replace("  static const weather = GardenWeatherSnapshot(rainLikelyTonight: true, humidityPercent: 86, windKph: 18, bestSprayWindow: 'tomorrow morning');", "  GardenWeatherSnapshot weather = const GardenWeatherSnapshot(rainLikelyTonight: true, humidityPercent: 86, windKph: 18, bestSprayWindow: 'tomorrow morning');`r`n  String weatherSource = 'Using offline fallback until live weather loads';")
}

if ($src -notmatch 'Future<void> fetchLiveWeather') {
  $method = @'

  Future<void> fetchLiveWeather() async {
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '-36.8485',
        'longitude': '174.7633',
        'hourly': 'precipitation_probability,relative_humidity_2m,wind_speed_10m,temperature_2m',
        'forecast_days': '2',
        'timezone': 'Pacific/Auckland',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final hourly = data['hourly'] as Map<String, dynamic>;
      final rain = (hourly['precipitation_probability'] as List).whereType<num>().map((v) => v.toInt()).toList();
      final humidity = (hourly['relative_humidity_2m'] as List).whereType<num>().map((v) => v.toInt()).toList();
      final wind = (hourly['wind_speed_10m'] as List).whereType<num>().map((v) => v.round()).toList();

      int maxOf(List<int> values, int count) {
        final window = values.take(count).toList();
        if (window.isEmpty) return 0;
        return window.reduce((a, b) => a > b ? a : b);
      }

      final rainTonight = maxOf(rain, 18) >= 40;
      final maxHumidity = maxOf(humidity, 24);
      final maxWind = maxOf(wind, 12);
      final bestWindow = rainTonight || maxWind > 22 ? 'tomorrow morning' : 'this evening';

      if (!mounted) return;
      setState(() {
        weather = GardenWeatherSnapshot(
          rainLikelyTonight: rainTonight,
          humidityPercent: maxHumidity,
          windKph: maxWind,
          bestSprayWindow: bestWindow,
        );
        weatherSource = 'Live weather: Auckland region · Open-Meteo forecast';
      });
    } catch (_) {
      // Keep offline fallback guidance.
    }
  }
'@
  $src = $src.Replace("  int get holdBeds => gardenBeds.where((b) => bedOnHold(b.number)).length;", $method + "`r`n`r`n  int get holdBeds => gardenBeds.where((b) => bedOnHold(b.number)).length;")
}

if ($src -notmatch 'fetchLiveWeather\(\);') {
  $src = $src.Replace("    seedDemoData();`r`n  }", "    seedDemoData();`r`n    fetchLiveWeather();`r`n  }")
}

if ($src -match "source: 'Using local garden records \+ forecast placeholder'") {
  $src = $src.Replace("GardenTodayReport buildGardenTodayReport({required Map<int, List<VegetableDefinition>> bedCrops, required List<SprayRecord> activeRecords, required GardenWeatherSnapshot weather, required DateTime now})", "GardenTodayReport buildGardenTodayReport({required Map<int, List<VegetableDefinition>> bedCrops, required List<SprayRecord> activeRecords, required GardenWeatherSnapshot weather, required DateTime now, String source = 'Using local garden records + forecast placeholder'})")
  $src = $src.Replace("source: 'Using local garden records + forecast placeholder',", "source: source,")
}

$src = $src.Replace("final report = buildGardenTodayReport(bedCrops: bedCrops, activeRecords: activeRecords, weather: weather, now: DateTime.now());", "final report = buildGardenTodayReport(bedCrops: bedCrops, activeRecords: activeRecords, weather: weather, now: DateTime.now(), source: weatherSource);")

Set-Content -Path $mainPath -Value $src -NoNewline
Write-Host 'Applied live weather integration for the Auckland region.'
Write-Host 'Next: flutter pub get; flutter analyze; flutter run'
