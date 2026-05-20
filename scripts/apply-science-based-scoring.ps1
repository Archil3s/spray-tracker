$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }
$src = Get-Content $mainPath -Raw

$helpers = @'

int weatherPenaltyForSpray({required int rainProbability, required int windKph, required int temperatureC, required int humidityPercent}) {
  var penalty = 0;
  if (rainProbability >= 70) {
    penalty += 45;
  } else if (rainProbability >= 50) {
    penalty += 34;
  } else if (rainProbability >= 35) {
    penalty += 22;
  } else if (rainProbability >= 20) {
    penalty += 10;
  }

  if (windKph >= 28) {
    penalty += 45;
  } else if (windKph >= 24) {
    penalty += 34;
  } else if (windKph >= 18) {
    penalty += 20;
  } else if (windKph >= 14) {
    penalty += 9;
  }

  if (temperatureC >= 30) {
    penalty += 26;
  } else if (temperatureC >= 28) {
    penalty += 18;
  } else if (temperatureC <= 4) {
    penalty += 16;
  } else if (temperatureC <= 8) {
    penalty += 8;
  }

  if (humidityPercent >= 94) {
    penalty += 16;
  } else if (humidityPercent >= 88) {
    penalty += 9;
  }
  return penalty.clamp(0, 100).toInt();
}

int fungalDiseasePressureScore({required List<VegetableDefinition> crops, required GardenWeatherSnapshot weather, required DateTime now}) {
  final susceptible = crops.where((crop) => isCropInMarlboroughSeason(crop, now) && hasDiseasePressureRisk(crop)).length;
  var score = susceptible == 0 ? 10 : 28 + (susceptible * 7).clamp(0, 24).toInt();

  if (weather.humidityPercent >= 92) {
    score += 30;
  } else if (weather.humidityPercent >= 85) {
    score += 22;
  } else if (weather.humidityPercent >= 78) {
    score += 12;
  }

  if (weather.rainLikelyTonight) score += 22;

  if (weather.temperatureC >= 12 && weather.temperatureC <= 26) {
    score += 14;
  } else if (weather.temperatureC >= 8 && weather.temperatureC <= 30) {
    score += 7;
  }
  return score.clamp(0, 100).toInt();
}

String scoreBand(int score, {required String high, required String medium, required String low}) {
  if (score >= 75) return high;
  if (score >= 55) return medium;
  return low;
}

Color scoreColor(int score) => score >= 75 ? C.forest : score >= 55 ? C.amber : C.red;
Color scoreBackground(int score) => score >= 75 ? C.forestSoft : score >= 55 ? C.amberSoft : C.redSoft;

int activeGrowthScore(DateTime now, GardenWeatherSnapshot weather) {
  final season = southernSeason(now);
  var score = 72;
  if (season == 'summer' || season == 'spring') score += 12;
  if (season == 'winter') score -= 24;
  if (season == 'autumn') score -= 4;

  if (weather.temperatureC >= 12 && weather.temperatureC <= 24) {
    score += 12;
  } else if (weather.temperatureC < 8) {
    score -= 24;
  } else if (weather.temperatureC > 28) {
    score -= 14;
  }

  if (weather.windKph >= 24) score -= 18;
  if (weather.rainLikelyTonight) score -= 10;
  if (weather.humidityPercent >= 92) score -= 8;
  return score.clamp(0, 100).toInt();
}
'@

if ($src -notmatch 'int weatherPenaltyForSpray') {
  $src = $src.Replace('GardenTodayReport buildGardenTodayReport', $helpers + "`r`nGardenTodayReport buildGardenTodayReport")
}

$newSpray = @'
SprayAdvisorReport buildSprayAdvisorReport({required Map<int, List<VegetableDefinition>> bedCrops, required List<SprayRecord> activeRecords, required List<SprayProduct> products, required GardenWeatherSnapshot weather, required DateTime now}) {
  final crops = bedCrops.values.expand((items) => items).toList();
  final target = seasonalDiseaseTarget(crops, now);
  final diseasePressure = fungalDiseasePressureScore(crops: crops, weather: weather, now: now);
  final weatherPenalty = weatherPenaltyForSpray(rainProbability: weather.rainLikelyTonight ? 55 : 15, windKph: weather.windKph, temperatureC: weather.temperatureC, humidityPercent: weather.humidityPercent);
  final holdPenalty = (activeRecords.length * 5).clamp(0, 18).toInt();
  final spraySuitability = (100 - weatherPenalty - holdPenalty).clamp(0, 100).toInt();
  final hardBlocked = weather.rainLikelyTonight || weather.windKph >= 24 || weather.temperatureC >= 30;

  final fungal = products.where((product) => product.targets.contains('fungus')).firstOrNull;
  final pest = products.where((product) => product.targets.contains('pest')).firstOrNull;
  final sortedHolds = [...activeRecords]..sort((a, b) => a.safeDate.compareTo(b.safeDate));
  final checkBeds = <int>{};
  for (final entry in bedCrops.entries) {
    if (entry.value.any((crop) => isCropInMarlboroughSeason(crop, now) && hasDiseasePressureRisk(crop))) checkBeds.add(entry.key);
  }

  final status = hardBlocked
      ? 'Do not spray'
      : scoreBand(spraySuitability, high: 'Good review window', medium: 'Borderline review window', low: 'Poor review window');
  final color = hardBlocked ? C.red : scoreColor(spraySuitability);
  final background = hardBlocked ? C.redSoft : scoreBackground(spraySuitability);

  final conditionBits = <String>[
    if (weather.rainLikelyTonight) 'rain likely',
    if (weather.windKph >= 24) 'wind too high',
    if (weather.temperatureC >= 30) 'too hot',
    if (weather.humidityPercent >= 88) 'very humid',
    if (activeRecords.isNotEmpty) '${activeRecords.length} active hold${activeRecords.length == 1 ? '' : 's'}',
  ];

  return SprayAdvisorReport(
    score: spraySuitability,
    status: status,
    warning: hardBlocked
        ? 'Weather block: ${conditionBits.isEmpty ? 'conditions are unsuitable' : conditionBits.join(', ')}.'
        : 'Spray suitability: $spraySuitability/100. Inspect plants first; use this as a review score, not an automatic spray instruction.',
    bestWindow: 'Weather window: ${weather.bestSprayWindow} · wind ${weather.windKph} km/h · ${weather.temperatureC}°C.',
    pressure: 'Disease pressure: $diseasePressure/100 for $target · humidity ${weather.humidityPercent}%.',
    productSuggestion: hardBlocked
        ? 'Product review: none today — wait for a calmer dry window.'
        : diseasePressure >= 70 && fungal != null
            ? 'Product review: ${fungal.name} only if matching symptoms are present and the label fits the crop.'
            : pest != null
                ? 'Product review: ${pest.name} only if visible insect pressure is present and the label fits the crop.'
                : 'Product review: no matching product configured.',
    harvestWarning: sortedHolds.isEmpty
        ? 'Harvest holds: no active withholding periods.'
        : 'Harvest holds: ${sortedHolds.take(3).map((record) => 'Bed ${record.beds.join('/')} safe in ${daysLabel(dayOnly(record.safeDate).difference(dayOnly(now)).inDays.clamp(0, 999).toInt())}').join(' · ')}',
    bedsToCheck: checkBeds.isEmpty ? 'Beds to check: inspect planted beds with visible pest or disease signs.' : 'Beds to check: ${checkBeds.take(5).map((bed) => 'Bed $bed').join(', ')}.',
    color: color,
    background: background,
  );
}
'@

$src = [regex]::Replace($src, 'SprayAdvisorReport buildSprayAdvisorReport\([\s\S]*?\r?\n\}\r?\n\r?\nFeedProductPreset feedingPresetForSeason', $newSpray + "`r`nFeedProductPreset feedingPresetForSeason", 1)

$newFeed = @'
FeedingAdvisorReport buildFeedingAdvisorReport({required Map<int, List<VegetableDefinition>> bedCrops, required List<FeedRecord> feedRecords, required GardenWeatherSnapshot weather, required DateTime now}) {
  final season = southernSeason(now);
  final preset = feedingPresetForSeason(now, weather);
  final growthScore = activeGrowthScore(now, weather);
  var score = growthScore;

  final lastFeedByBed = <int, FeedRecord>{};
  for (final record in feedRecords) {
    for (final bed in record.beds) {
      final current = lastFeedByBed[bed];
      if (current == null || record.date.isAfter(current.date)) lastFeedByBed[bed] = record;
    }
  }

  final due = <int>[];
  final almostDue = <int>[];
  for (final bed in bedCrops.keys) {
    final last = lastFeedByBed[bed];
    if (last == null) {
      due.add(bed);
      continue;
    }
    final age = dayOnly(now).difference(dayOnly(last.date)).inDays;
    if (age >= preset.intervalDays) {
      due.add(bed);
    } else if (age >= (preset.intervalDays * .75).round()) {
      almostDue.add(bed);
    }
  }
  due.sort();
  almostDue.sort();

  if (due.isEmpty) score -= 18;
  if (weather.rainLikelyTonight && preset.method.toLowerCase().contains('liquid')) score -= 14;
  if (weather.windKph >= 24 && preset.method.toLowerCase().contains('liquid')) score -= 20;
  score = score.clamp(0, 100).toInt();

  final sortedFeeds = [...feedRecords]..sort((a, b) => b.date.compareTo(a.date));
  final status = scoreBand(score, high: 'Good feed window', medium: 'Feed lightly if needed', low: 'Delay feeding');
  final color = scoreColor(score);
  final background = scoreBackground(score);
  final dueLine = due.isNotEmpty
      ? 'Due beds: ${due.take(6).map((bed) => 'Bed $bed').join(', ')}.'
      : almostDue.isNotEmpty
          ? 'Almost due: ${almostDue.take(6).map((bed) => 'Bed $bed').join(', ')}.'
          : 'Due beds: no planted beds are clearly due.';

  return FeedingAdvisorReport(
    score: score,
    status: status,
    feedWindow: score < 55
        ? 'Feed window: wait for active growth and calmer weather.'
        : weather.rainLikelyTonight
            ? 'Feed window: soil feed after rain, foliar/liquid feed after leaves dry.'
            : weather.windKph >= 24
                ? 'Feed window: next calm morning for liquid or foliar feeds.'
                : season == 'winter'
                    ? 'Feed window: mild morning, light rate only because growth is slow.'
                    : 'Feed window: morning or late afternoon, avoid heat and wind.',
    productSuggestion: 'Feed review: ${preset.name} · ${preset.note}',
    dueBeds: dueLine,
    recentFeed: sortedFeeds.isEmpty ? 'Recent feed: none logged yet.' : 'Recent feed: ${sortedFeeds.first.product} on Bed ${sortedFeeds.first.beds.join('/')} · ${daysLabel(dayOnly(now).difference(dayOnly(sortedFeeds.first.date)).inDays)} ago.',
    weatherNote: 'Growth score: $growthScore/100 · season $season · ${weather.temperatureC}°C · wind ${weather.windKph} km/h.',
    color: color,
    background: background,
  );
}
'@

$src = [regex]::Replace($src, 'FeedingAdvisorReport buildFeedingAdvisorReport\([\s\S]*?\r?\n\}\r?\n\r?\nclass BunningsSprayProduct', $newFeed + "`r`nclass BunningsSprayProduct", 1)

# Improve online timing scoring if the online advisor has been applied locally.
if ($src -match 'WeatherHourCandidate\? bestForecastWindow') {
$newBest = @'
WeatherHourCandidate? bestForecastWindow({required List<DateTime> times, required List<int> rain, required List<int> humidity, required List<int> wind, required List<int> temp, required bool spray}) {
  final now = DateTime.now();
  final candidates = <WeatherHourCandidate>[];
  final count = [times.length, rain.length, humidity.length, wind.length, temp.length].reduce((a, b) => a < b ? a : b);
  for (var i = 0; i < count; i++) {
    final time = times[i];
    if (time.isBefore(now.add(const Duration(hours: 1)))) continue;
    if (time.hour < 6 || time.hour > 20) continue;
    final penalty = weatherPenaltyForSpray(rainProbability: rain[i], windKph: wind[i], temperatureC: temp[i], humidityPercent: humidity[i]);
    var score = spray ? 100 - penalty : activeGrowthScore(time, GardenWeatherSnapshot(rainLikelyTonight: rain[i] >= 45, humidityPercent: humidity[i], windKph: wind[i], temperatureC: temp[i], bestSprayWindow: '', source: 'forecast hour'));
    if (!spray && rain[i] >= 70) score -= 14;
    candidates.add(WeatherHourCandidate(time: time, rain: rain[i], humidity: humidity[i], wind: wind[i], temp: temp[i], score: score.clamp(0, 100).toInt()));
  }
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) => b.score.compareTo(a.score));
  return candidates.first;
}
'@
  $src = [regex]::Replace($src, 'WeatherHourCandidate\? bestForecastWindow\([\s\S]*?\r?\n\}\r?\n\r?\nOnlineTimingAdvice buildOnlineTimingAdviceFromForecast', $newBest + "`r`nOnlineTimingAdvice buildOnlineTimingAdviceFromForecast", 1)
}

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
foreach ($marker in @('weatherPenaltyForSpray', 'fungalDiseasePressureScore', 'activeGrowthScore', 'Spray suitability:', 'Disease pressure:', 'Growth score:')) {
  if ($check -notmatch [regex]::Escape($marker)) { throw "Missing science scoring marker: $marker" }
}

Write-Host 'Applied science-based scoring heuristics.'
Write-Host 'Scores now separate spray weather suitability, fungal disease pressure, harvest holds, active growth and feed due intervals.'
Write-Host 'Next: flutter analyze; flutter run'
