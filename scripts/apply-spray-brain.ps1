$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) {
  throw "Could not find lib/main.dart from $PSScriptRoot"
}

$src = Get-Content $mainPath -Raw

$brainBlock = @'
class SprayBrainRecommendation {
  const SprayBrainRecommendation({
    required this.action,
    required this.status,
    required this.targetId,
    required this.beds,
    required this.cropNames,
    required this.product,
    required this.bunningsProduct,
    required this.when,
    required this.why,
    required this.score,
    required this.color,
    required this.background,
    required this.canStartSpray,
  });

  final String action;
  final String status;
  final String targetId;
  final Set<int> beds;
  final Set<String> cropNames;
  final SprayProduct? product;
  final BunningsSprayProduct? bunningsProduct;
  final String when;
  final List<String> why;
  final int score;
  final Color color;
  final Color background;
  final bool canStartSpray;
}

int sprayScoreForWeather({required List<SprayRecord> activeRecords, required GardenWeatherSnapshot weather}) {
  var score = 100;
  if (weather.rainLikelyTonight) score -= 35;
  if (weather.windKph >= 24) {
    score -= 30;
  } else if (weather.windKph >= 16) {
    score -= 14;
  }
  if (weather.humidityPercent >= 88) {
    score -= 14;
  } else if (weather.humidityPercent >= 80) {
    score -= 8;
  }
  if (weather.temperatureC >= 27) score -= 12;
  if (activeRecords.length >= 4) score -= 8;
  return score.clamp(0, 100).toInt();
}

String bedListText(Iterable<int> beds) => beds.isEmpty ? 'no beds' : beds.map((bed) => 'Bed $bed').join(', ');

Set<String> cropNamesForBeds(Map<int, List<VegetableDefinition>> bedCrops, Iterable<int> beds) {
  final names = <String>{};
  for (final bed in beds) {
    for (final crop in bedCrops[bed] ?? const <VegetableDefinition>[]) {
      names.add(crop.name);
    }
  }
  return names.isEmpty ? {'Whole bed'} : names;
}

SprayProduct? bestSprayProductForTarget(List<SprayProduct> products, String targetId) {
  if (products.isEmpty) return null;
  final exact = products.where((product) => product.targets.contains(targetId)).toList();
  if (exact.isEmpty) return products.firstOrNull;
  if (targetId == 'fungus') {
    return exact.firstWhere((product) => product.name.toLowerCase().contains('copper'), orElse: () => exact.first);
  }
  if (targetId == 'pest') {
    return exact.firstWhere((product) {
      final name = product.name.toLowerCase();
      return name.contains('neem') || name.contains('pyreth');
    }, orElse: () => exact.first);
  }
  return exact.first;
}

BunningsSprayProduct? bestBunningsProductForTarget(String targetId, SprayProduct? product) {
  final productName = product?.name.toLowerCase() ?? '';
  if (targetId == 'fungus') {
    if (productName.contains('copper')) {
      return bunningsSprayProducts.firstWhere((item) => item.name.toLowerCase().contains('liquid copper'), orElse: () => bunningsSprayProducts.firstWhere((item) => item.target.contains('Fungus')));
    }
    return bunningsSprayProducts.firstWhere((item) => item.target.contains('Fungus'), orElse: () => bunningsSprayProducts.first);
  }
  if (targetId == 'pest') {
    if (productName.contains('neem') || productName.contains('oil')) {
      return bunningsSprayProducts.firstWhere((item) => item.name.toLowerCase().contains('eco-oil'), orElse: () => bunningsSprayProducts.firstWhere((item) => item.target.contains('Pest')));
    }
    return bunningsSprayProducts.firstWhere((item) => item.target.contains('Pest'), orElse: () => bunningsSprayProducts.first);
  }
  if (targetId == 'maintain') {
    return bunningsSprayProducts.firstWhere((item) => item.name.toLowerCase().contains('seasol'), orElse: () => bunningsSprayProducts.firstWhere((item) => item.target.contains('Maintenance')));
  }
  return bunningsSprayProducts.firstWhere((item) => item.target.contains('Pest') || item.target.contains('Fungus'), orElse: () => bunningsSprayProducts.firstOrNull ?? null as BunningsSprayProduct);
}

SprayBrainRecommendation buildSprayBrainRecommendation({
  required Map<int, List<VegetableDefinition>> bedCrops,
  required List<SprayRecord> activeRecords,
  required List<SprayProduct> products,
  required GardenWeatherSnapshot weather,
  required DateTime now,
}) {
  final score = sprayScoreForWeather(activeRecords: activeRecords, weather: weather);
  final activeHoldBeds = activeRecords.expand((record) => record.beds).toSet();
  final plantedBeds = bedCrops.keys.toSet();
  final diseaseBeds = <int>{};
  final pestBeds = <int>{};

  for (final entry in bedCrops.entries) {
    final crops = entry.value;
    final diseaseRisk = crops.any((crop) => isCropInMarlboroughSeason(crop, now) && hasDiseasePressureRisk(crop));
    final pestRisk = crops.any((crop) => isCropInMarlboroughSeason(crop, now) && crop.commonPests.isNotEmpty);
    if (diseaseRisk) diseaseBeds.add(entry.key);
    if (pestRisk) pestBeds.add(entry.key);
  }

  final blockedByWeather = weather.rainLikelyTonight || weather.windKph >= 24 || weather.temperatureC >= 28 || score < 55;
  final availableDiseaseBeds = diseaseBeds.difference(activeHoldBeds);
  final availablePestBeds = pestBeds.difference(activeHoldBeds);

  String targetId;
  Set<int> targetBeds;
  if (weather.humidityPercent >= 80 && availableDiseaseBeds.isNotEmpty) {
    targetId = 'fungus';
    targetBeds = availableDiseaseBeds;
  } else if (availablePestBeds.isNotEmpty) {
    targetId = 'pest';
    targetBeds = availablePestBeds;
  } else {
    targetId = 'prevent';
    targetBeds = plantedBeds.difference(activeHoldBeds);
  }

  final product = bestSprayProductForTarget(products, targetId);
  final bunnings = bestBunningsProductForTarget(targetId, product);
  final cropNames = cropNamesForBeds(bedCrops, targetBeds);
  final noUsableBeds = targetBeds.isEmpty;
  final cannotSpray = blockedByWeather || product == null || noUsableBeds;
  final color = cannotSpray ? C.red : score < 75 ? C.amber : C.forest;
  final background = cannotSpray ? C.redSoft : score < 75 ? C.amberSoft : C.forestSoft;

  final holdText = activeHoldBeds.isEmpty ? 'No active bed holds blocking the recommendation.' : 'Skipping held beds: ${bedListText(activeHoldBeds)}.';
  final pressureText = targetId == 'fungus'
      ? 'Main pressure: fungus risk from ${weather.humidityPercent}% humidity in ${bedListText(targetBeds)}.'
      : targetId == 'pest'
          ? 'Main pressure: inspect pest-prone current-season beds: ${bedListText(targetBeds)}.'
          : 'Main pressure: low; only preventative/support spray if plants need it.';
  final productText = product == null ? 'No matching spray product is configured.' : 'Use from your list: ${product.name} · ${product.days} day withholding.';
  final shopText = bunnings == null ? 'No Bunnings product card matched.' : 'Bunnings match: ${bunnings.name}.';

  if (cannotSpray) {
    final reasons = <String>[];
    if (weather.rainLikelyTonight) reasons.add('rain likely tonight');
    if (weather.windKph >= 24) reasons.add('wind ${weather.windKph} km/h');
    if (weather.temperatureC >= 28) reasons.add('temperature ${weather.temperatureC}°C');
    if (score < 55) reasons.add('spray score $score/100');
    if (product == null) reasons.add('no matching product');
    if (noUsableBeds) reasons.add('all suitable beds are on hold or empty');
    return SprayBrainRecommendation(
      action: 'Do not spray today',
      status: reasons.isEmpty ? 'Wait for better conditions' : 'Blocked: ${reasons.join(', ')}',
      targetId: targetId,
      beds: targetBeds,
      cropNames: cropNames,
      product: product,
      bunningsProduct: bunnings,
      when: 'Next action: wait until ${weather.bestSprayWindow}, then reassess.',
      why: [pressureText, productText, shopText, holdText, 'Label check still required before any edible-crop spray.'],
      score: score,
      color: color,
      background: background,
      canStartSpray: false,
    );
  }

  return SprayBrainRecommendation(
    action: 'Spray ${bedListText(targetBeds.take(4))}',
    status: targetId == 'fungus' ? 'Use fungus product if symptoms are present' : 'Inspect first, then spray only visible pressure',
    targetId: targetId,
    beds: targetBeds,
    cropNames: cropNames,
    product: product,
    bunningsProduct: bunnings,
    when: 'Best time: ${weather.bestSprayWindow}. Avoid heat, wind and bees.',
    why: [pressureText, productText, shopText, holdText, 'This is a recommendation, not a substitute for the product label.'],
    score: score,
    color: color,
    background: background,
    canStartSpray: true,
  );
}

'@

$cardBlock = @'
class SprayBrainCard extends StatelessWidget {
  const SprayBrainCard({required this.recommendation, required this.onStartSpray, required this.onOpenProduct, super.key});
  final SprayBrainRecommendation recommendation;
  final VoidCallback onStartSpray;
  final VoidCallback onOpenProduct;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: recommendation.background,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: C.line),
          boxShadow: softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 46, height: 46, alignment: Alignment.center, decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(16)), child: Icon(CupertinoIcons.wand_stars, color: recommendation.color, size: 23)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Spray Brain', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: C.forest)),
                      Text(recommendation.action, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: recommendation.color)),
                      const SizedBox(height: 3),
                      Text(recommendation.status, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink, fontWeight: FontWeight.w800, fontSize: 12.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(999)), child: Text('${recommendation.score}/100', style: TextStyle(color: recommendation.color, fontWeight: FontWeight.w900, fontSize: 13))),
              ],
            ),
            const SizedBox(height: 12),
            AdvisorRow(text: recommendation.when, color: recommendation.color, background: C.card),
            ...recommendation.why.map((line) => AdvisorRow(text: line, color: recommendation.color, background: C.card)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: PrimaryButton(label: recommendation.canStartSpray ? 'Use this spray' : 'Wait', onPressed: recommendation.canStartSpray ? onStartSpray : null)),
                const SizedBox(width: 10),
                Expanded(child: SecondaryButton(label: recommendation.bunningsProduct == null ? 'Products' : 'Open product', onPressed: recommendation.bunningsProduct == null ? null : onOpenProduct)),
              ],
            ),
          ],
        ),
      );
}

'@

if ($src -notmatch 'class SprayBrainRecommendation') {
  $src = $src.Replace('FeedProductPreset feedingPresetForSeason(DateTime now, GardenWeatherSnapshot weather) {', $brainBlock + 'FeedProductPreset feedingPresetForSeason(DateTime now, GardenWeatherSnapshot weather) {')
}

if ($src -notmatch 'class SprayBrainCard') {
  $src = $src.Replace('class SprayAdvisorCard extends StatelessWidget {', $cardBlock + 'class SprayAdvisorCard extends StatelessWidget {')
}

if ($src -notmatch 'final sprayBrain = buildSprayBrainRecommendation') {
  $src = $src.Replace('final sprayAdvisor = buildSprayAdvisorReport(bedCrops: bedCrops, activeRecords: activeSprays, products: products, weather: weather, now: DateTime.now());', "final sprayAdvisor = buildSprayAdvisorReport(bedCrops: bedCrops, activeRecords: activeSprays, products: products, weather: weather, now: DateTime.now());`r`n    final sprayBrain = buildSprayBrainRecommendation(bedCrops: bedCrops, activeRecords: activeSprays, products: products, weather: weather, now: DateTime.now());")
}

if ($src -notmatch 'sprayBrain: sprayBrain') {
  $src = $src.Replace('sprayAdvisor: sprayAdvisor, feedingAdvisor: feedingAdvisor, message: message, onPlanSpray:', 'sprayAdvisor: sprayAdvisor, sprayBrain: sprayBrain, feedingAdvisor: feedingAdvisor, message: message, onUseBrainSpray: () => startSpray(beds: sprayBrain.beds, targetId: sprayBrain.targetId, crops: sprayBrain.cropNames), onOpenBrainProduct: () { final item = sprayBrain.bunningsProduct; if (item != null) openBunningsUrl(item.url, item.fallbackUrl); }, onPlanSpray:')
}

if ($src -notmatch 'required this.sprayBrain') {
  $src = $src.Replace('required this.today, required this.sprayAdvisor, required this.feedingAdvisor, required this.message,', 'required this.today, required this.sprayAdvisor, required this.sprayBrain, required this.feedingAdvisor, required this.message, required this.onUseBrainSpray, required this.onOpenBrainProduct,')
}

if ($src -notmatch 'final SprayBrainRecommendation sprayBrain;') {
  $src = $src.Replace('  final SprayAdvisorReport sprayAdvisor;', '  final SprayAdvisorReport sprayAdvisor;`r`n  final SprayBrainRecommendation sprayBrain;')
  $src = $src.Replace('  final VoidCallback onPlanSpray;', '  final VoidCallback onUseBrainSpray;`r`n  final VoidCallback onOpenBrainProduct;`r`n  final VoidCallback onPlanSpray;')
}

if ($src -notmatch 'SprayBrainCard\(') {
  $src = $src.Replace('SprayAdvisorCard(report: sprayAdvisor, onPlanSpray: onPlanSpray, onOpenProducts: onOpenProducts),', 'SprayBrainCard(recommendation: sprayBrain, onStartSpray: onUseBrainSpray, onOpenProduct: onOpenBrainProduct),`r`n        const SizedBox(height: 14),`r`n        SprayAdvisorCard(report: sprayAdvisor, onPlanSpray: onPlanSpray, onOpenProducts: onOpenProducts),')
}

Set-Content -Path $mainPath -Value $src -NoNewline
Write-Host 'Applied Spray Brain recommendation engine.'
Write-Host 'The Home screen now chooses when to spray, which beds, which configured product, and which Bunnings product card to open.'
Write-Host 'Next: flutter analyze; flutter run'
