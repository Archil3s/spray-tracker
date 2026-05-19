$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
$gardenTodayScript = Join-Path $PSScriptRoot 'apply-garden-today.ps1'
$liveWeatherScript = Join-Path $PSScriptRoot 'apply-live-weather.ps1'
$seasonAdvisorScript = Join-Path $PSScriptRoot 'apply-season-advisor.ps1'

if (-not (Test-Path $mainPath)) {
  throw "Could not find lib/main.dart from $PSScriptRoot"
}

$src = Get-Content $mainPath -Raw

# Apply dependencies only when missing. This avoids duplicate helper blocks in local files.
if ($src -notmatch 'class GardenTodayReport') {
  if (-not (Test-Path $gardenTodayScript)) { throw 'Missing apply-garden-today.ps1. Run git pull origin main first.' }
  & $gardenTodayScript
  $src = Get-Content $mainPath -Raw
}

if ($src -notmatch 'Future<void> fetchLiveWeather') {
  if (-not (Test-Path $liveWeatherScript)) { throw 'Missing apply-live-weather.ps1. Run git pull origin main first.' }
  & $liveWeatherScript
  $src = Get-Content $mainPath -Raw
}

if ($src -notmatch 'String southernSeason\(DateTime date\)') {
  if (-not (Test-Path $seasonAdvisorScript)) { throw 'Missing apply-season-advisor.ps1. Run git pull origin main first.' }
  & $seasonAdvisorScript
  $src = Get-Content $mainPath -Raw
}

$modelBlock = @'
class SprayAdvisorReport {
  const SprayAdvisorReport({
    required this.score,
    required this.status,
    required this.doNotSprayWarning,
    required this.bestWindow,
    required this.pressure,
    required this.productSuggestion,
    required this.harvestWarning,
    required this.bedsToCheck,
    required this.statusColor,
    required this.statusBackground,
  });

  final int score;
  final String status;
  final String doNotSprayWarning;
  final String bestWindow;
  final String pressure;
  final String productSuggestion;
  final String harvestWarning;
  final String bedsToCheck;
  final Color statusColor;
  final Color statusBackground;
}

SprayAdvisorReport buildSprayAdvisorReport({
  required Map<int, List<VegetableDefinition>> bedCrops,
  required List<SprayRecord> activeRecords,
  required List<SprayProduct> products,
  required GardenWeatherSnapshot weather,
  required DateTime now,
}) {
  var score = 100;
  final reasons = <String>[];

  if (weather.rainLikelyTonight) {
    score -= 35;
    reasons.add('rain likely tonight');
  }
  if (weather.windKph >= 24) {
    score -= 30;
    reasons.add('wind too high');
  } else if (weather.windKph >= 16) {
    score -= 14;
    reasons.add('wind borderline');
  }
  if (weather.humidityPercent >= 88) {
    score -= 14;
    reasons.add('very high humidity');
  } else if (weather.humidityPercent >= 80) {
    score -= 8;
    reasons.add('high humidity');
  }
  if (activeRecords.length >= 4) {
    score -= 8;
    reasons.add('several beds on harvest hold');
  }

  score = score.clamp(0, 100).toInt();
  final blocked = score < 55 || weather.rainLikelyTonight || weather.windKph >= 24;
  final status = blocked ? 'Do not spray' : score < 75 ? 'Spray only if needed' : 'Good spray window';
  final warning = blocked
      ? 'Do not spray: ${reasons.isEmpty ? 'conditions are not suitable' : reasons.join(', ')}.'
      : 'No hard weather block. Inspect plants first and only spray if pressure is visible.';

  final crops = bedCrops.values.expand((items) => items).toList();
  final target = seasonalDiseaseTarget(crops, now);
  final pressure = weather.humidityPercent >= 80
      ? 'Disease pressure: fungal risk in $target.'
      : 'Pest/disease pressure: inspect current planted beds before choosing a product.';

  final fungalProduct = products.where((product) => product.targets.contains('fungus')).firstOrNull;
  final pestProduct = products.where((product) => product.targets.contains('pest')).firstOrNull;
  final productSuggestion = blocked
      ? 'Product suggestion: none today — delay until ${weather.bestSprayWindow}.'
      : weather.humidityPercent >= 80 && fungalProduct != null
          ? 'Product suggestion: ${fungalProduct.name} only if disease signs are present.'
          : pestProduct != null
              ? 'Product suggestion: ${pestProduct.name} only if insect pressure is visible.'
              : 'Product suggestion: no matching product configured.';

  final sortedHolds = [...activeRecords]..sort((a, b) => a.safeDate.compareTo(b.safeDate));
  final harvestWarning = sortedHolds.isEmpty
      ? 'Harvest holds: no active withholding periods.'
      : 'Harvest holds: ${sortedHolds.take(3).map((record) {
          final remaining = dayOnly(record.safeDate).difference(dayOnly(now)).inDays.clamp(0, 999).toInt();
          return 'Bed ${record.beds.join('/')} safe in ${daysLabel(remaining)}';
        }).join(' · ')}';

  final checkBeds = <int>{};
  for (final entry in bedCrops.entries) {
    final hasSeasonalRisk = entry.value.any((crop) => isCropInAucklandSeason(crop, now) && hasDiseasePressureRisk(crop));
    if (hasSeasonalRisk) checkBeds.add(entry.key);
  }
  final bedsToCheck = checkBeds.isEmpty
      ? 'Beds to check: inspect any bed with visible pest or disease pressure.'
      : 'Beds to check: ${checkBeds.take(5).map((bed) => 'Bed $bed').join(', ')}.';

  return SprayAdvisorReport(
    score: score,
    status: status,
    doNotSprayWarning: warning,
    bestWindow: 'Best spray window: ${weather.bestSprayWindow}',
    pressure: pressure,
    productSuggestion: productSuggestion,
    harvestWarning: harvestWarning,
    bedsToCheck: bedsToCheck,
    statusColor: blocked ? C.red : score < 75 ? C.amber : C.forest,
    statusBackground: blocked ? C.redSoft : score < 75 ? C.amberSoft : C.forestSoft,
  );
}

'@

$cardBlock = @'
class SprayAdvisorCard extends StatelessWidget {
  const SprayAdvisorCard({required this.report, super.key});
  final SprayAdvisorReport report;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration(radius: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: report.statusBackground, borderRadius: BorderRadius.circular(15)), child: Icon(CupertinoIcons.gauge, color: report.statusColor, size: 22)),
                const SizedBox(width: 11),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Spray Advisor', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: C.forest)),
                  Text(report.status, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: report.statusColor, fontWeight: FontWeight.w900, fontSize: 13)),
                ])),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8), decoration: BoxDecoration(color: report.statusBackground, borderRadius: BorderRadius.circular(999)), child: Text('${report.score}/100', style: TextStyle(color: report.statusColor, fontWeight: FontWeight.w900, fontSize: 13))),
              ],
            ),
            const SizedBox(height: 14),
            SprayAdvisorRow(icon: CupertinoIcons.xmark_shield, text: report.doNotSprayWarning, color: report.statusColor, background: report.statusBackground),
            SprayAdvisorRow(icon: CupertinoIcons.clock, text: report.bestWindow, color: C.forest, background: C.forestSoft),
            SprayAdvisorRow(icon: CupertinoIcons.drop, text: report.pressure, color: C.blue, background: C.blueSoft),
            SprayAdvisorRow(icon: CupertinoIcons.cube_box, text: report.productSuggestion, color: C.purple, background: C.purpleSoft),
            SprayAdvisorRow(icon: CupertinoIcons.hand_raised, text: report.harvestWarning, color: C.amber, background: C.amberSoft),
            SprayAdvisorRow(icon: CupertinoIcons.eye, text: report.bedsToCheck, color: C.soil, background: C.soft),
          ],
        ),
      );
}

class SprayAdvisorRow extends StatelessWidget {
  const SprayAdvisorRow({required this.icon, required this.text, required this.color, required this.background, super.key});
  final IconData icon;
  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(17), border: Border.all(color: C.line)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 9),
            Expanded(child: Text(text, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink, fontWeight: FontWeight.w800, fontSize: 12.5, height: 1.25))),
          ],
        ),
      );
}

'@

if ($src -notmatch 'class SprayAdvisorReport') {
  if ($src -match 'class FieldbookHome extends StatefulWidget') {
    $src = $src.Replace('class FieldbookHome extends StatefulWidget', $modelBlock + 'class FieldbookHome extends StatefulWidget')
  } else {
    throw 'Could not find FieldbookHome insertion point.'
  }
}

if ($src -notmatch 'class SprayAdvisorCard') {
  if ($src -match 'class GardenTodayCard extends StatelessWidget') {
    $src = $src.Replace('class GardenTodayCard extends StatelessWidget', $cardBlock + 'class GardenTodayCard extends StatelessWidget')
  } elseif ($src -match 'class SafeHarvestCard extends StatelessWidget') {
    $src = $src.Replace('class SafeHarvestCard extends StatelessWidget', $cardBlock + 'class SafeHarvestCard extends StatelessWidget')
  } else {
    throw 'Could not find card insertion point.'
  }
}

if ($src -notmatch 'final sprayAdvisor = buildSprayAdvisorReport') {
  $src = $src.Replace('final report = buildGardenTodayReport(bedCrops: bedCrops, activeRecords: activeRecords, weather: weather, now: DateTime.now(), source: weatherSource);', "final report = buildGardenTodayReport(bedCrops: bedCrops, activeRecords: activeRecords, weather: weather, now: DateTime.now(), source: weatherSource);`r`n    final sprayAdvisor = buildSprayAdvisorReport(bedCrops: bedCrops, activeRecords: activeRecords, products: products, weather: weather, now: DateTime.now());")
  $src = $src.Replace('final report = buildGardenTodayReport(bedCrops: bedCrops, activeRecords: activeRecords, weather: weather, now: DateTime.now());', "final report = buildGardenTodayReport(bedCrops: bedCrops, activeRecords: activeRecords, weather: weather, now: DateTime.now());`r`n    final sprayAdvisor = buildSprayAdvisorReport(bedCrops: bedCrops, activeRecords: activeRecords, products: products, weather: weather, now: DateTime.now());")
}

if ($src -notmatch 'sprayAdvisor: sprayAdvisor') {
  $src = $src.Replace('HomeScreen(clearBeds: clearBeds, holdBeds: holdBeds, plantedBeds: plantedBeds, cropPlacements: cropPlacements, records: records, activeRecords: activeRecords, report: report, message: message, onPlanSpray:', 'HomeScreen(clearBeds: clearBeds, holdBeds: holdBeds, plantedBeds: plantedBeds, cropPlacements: cropPlacements, records: records, activeRecords: activeRecords, report: report, sprayAdvisor: sprayAdvisor, message: message, onPlanSpray:')
}

if ($src -notmatch 'required this.sprayAdvisor') {
  $src = $src.Replace('const HomeScreen({required this.clearBeds, required this.holdBeds, required this.plantedBeds, required this.cropPlacements, required this.records, required this.activeRecords, required this.report, required this.message,', 'const HomeScreen({required this.clearBeds, required this.holdBeds, required this.plantedBeds, required this.cropPlacements, required this.records, required this.activeRecords, required this.report, required this.sprayAdvisor, required this.message,')
}

if ($src -notmatch 'final SprayAdvisorReport sprayAdvisor;') {
  $src = $src.Replace("  final GardenTodayReport report;`r`n  final String message;", "  final GardenTodayReport report;`r`n  final SprayAdvisorReport sprayAdvisor;`r`n  final String message;")
}

if ($src -notmatch 'SprayAdvisorCard\(report: sprayAdvisor\)') {
  $src = $src.Replace('GardenTodayCard(report: report),', "SprayAdvisorCard(report: sprayAdvisor),`r`n        const SizedBox(height: 14),`r`n        GardenTodayCard(report: report),")
}

Set-Content -Path $mainPath -Value $src -NoNewline
Write-Host 'Applied Spray Advisor v1.'
Write-Host 'Features: live weather score, do-not-spray warning, best spray window, bed pressure, product suggestion, harvest holds.'
Write-Host 'Next: flutter pub get; flutter analyze; flutter run'
