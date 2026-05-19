$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) {
  throw "Could not find lib/main.dart from $PSScriptRoot"
}

$src = Get-Content $mainPath -Raw

$easyBlock = @'
class EasySprayPlan {
  const EasySprayPlan({
    required this.title,
    required this.status,
    required this.targetId,
    required this.beds,
    required this.cropNames,
    required this.product,
    required this.bunningsProduct,
    required this.when,
    required this.reason,
    required this.notes,
    required this.canSave,
    required this.color,
    required this.background,
  });

  final String title;
  final String status;
  final String targetId;
  final Set<int> beds;
  final Set<String> cropNames;
  final SprayProduct? product;
  final BunningsSprayProduct? bunningsProduct;
  final String when;
  final String reason;
  final List<String> notes;
  final bool canSave;
  final Color color;
  final Color background;
}

String bedsText(Iterable<int> beds) => beds.isEmpty ? 'no beds' : beds.map((bed) => 'Bed $bed').join(', ');

BunningsSprayProduct? firstBunningsMatch(bool Function(BunningsSprayProduct product) test) {
  for (final product in bunningsSprayProducts) {
    if (test(product)) return product;
  }
  return null;
}

SprayProduct? bestProductForEasySpray(List<SprayProduct> products, String targetId) {
  final matches = products.where((product) => product.targets.contains(targetId)).toList();
  if (matches.isEmpty) return products.firstOrNull;
  if (targetId == 'fungus') {
    for (final product in matches) {
      if (product.name.toLowerCase().contains('copper')) return product;
    }
  }
  if (targetId == 'pest') {
    for (final product in matches) {
      final name = product.name.toLowerCase();
      if (name.contains('neem') || name.contains('pyreth')) return product;
    }
  }
  return matches.first;
}

BunningsSprayProduct? bestBunningsForEasySpray(String targetId, SprayProduct? product) {
  final name = product?.name.toLowerCase() ?? '';
  if (targetId == 'fungus') {
    if (name.contains('copper')) return firstBunningsMatch((item) => item.name.toLowerCase().contains('liquid copper')) ?? firstBunningsMatch((item) => item.target.contains('Fungus'));
    return firstBunningsMatch((item) => item.target.contains('Fungus'));
  }
  if (targetId == 'pest') {
    if (name.contains('neem') || name.contains('oil')) return firstBunningsMatch((item) => item.name.toLowerCase().contains('eco-oil')) ?? firstBunningsMatch((item) => item.target.contains('Pest'));
    return firstBunningsMatch((item) => item.target.contains('Pest'));
  }
  if (targetId == 'maintain') return firstBunningsMatch((item) => item.name.toLowerCase().contains('seasol')) ?? firstBunningsMatch((item) => item.target.contains('Maintenance'));
  return firstBunningsMatch((item) => item.target.contains('Fungus')) ?? firstBunningsMatch((item) => item.target.contains('Pest'));
}

EasySprayPlan buildEasySprayPlan({
  required Set<int> selectedBeds,
  required Set<String> selectedCrops,
  required List<VegetableDefinition> activeCrops,
  required String selectedTargetId,
  required List<SprayProduct> products,
  required List<SprayRecord> activeRecords,
  required GardenWeatherSnapshot weather,
  required DateTime now,
}) {
  final heldBeds = activeRecords.where((record) => record.safeDate.isAfter(now)).expand((record) => record.beds).toSet();
  final usableBeds = selectedBeds.difference(heldBeds);
  final hasDiseaseRisk = activeCrops.any((crop) => isCropInMarlboroughSeason(crop, now) && hasDiseasePressureRisk(crop));
  final hasPestRisk = activeCrops.any((crop) => isCropInMarlboroughSeason(crop, now) && crop.commonPests.isNotEmpty);
  final weatherBlocked = weather.rainLikelyTonight || weather.windKph >= 24 || weather.temperatureC >= 28;

  var targetId = selectedTargetId;
  if (weather.humidityPercent >= 80 && hasDiseaseRisk) {
    targetId = 'fungus';
  } else if (targetId == 'prevent' && hasPestRisk) {
    targetId = 'pest';
  }

  final product = bestProductForEasySpray(products, targetId);
  final bunnings = bestBunningsForEasySpray(targetId, product);
  final cropNames = selectedCrops.isEmpty ? {'Whole bed'} : selectedCrops;
  final canSave = !weatherBlocked && usableBeds.isNotEmpty && product != null;
  final color = canSave ? C.forest : C.red;
  final background = canSave ? C.forestSoft : C.redSoft;

  final notes = <String>[
    if (usableBeds.isEmpty) 'Selected beds are all on harvest hold or no bed is selected.',
    if (heldBeds.isNotEmpty) 'Held beds skipped: ${bedsText(heldBeds)}.',
    if (weather.rainLikelyTonight) 'Rain likely tonight: spray will not stick well.',
    if (weather.windKph >= 24) 'Wind is too high: ${weather.windKph} km/h.',
    if (weather.temperatureC >= 28) 'Temperature is too high: ${weather.temperatureC}°C.',
    if (weather.humidityPercent >= 80 && hasDiseaseRisk) 'Humidity is ${weather.humidityPercent}%: fungal pressure is prioritised.',
    if (product == null) 'No matching product exists in your product list.',
    if (product != null) 'Use product: ${product.name} · ${product.days} day withholding.',
    if (bunnings != null) 'Bunnings match: ${bunnings.name}.',
    'Always check the product label before edible-crop spraying.',
  ];

  final target = targetById(targetId);
  return EasySprayPlan(
    title: canSave ? 'Use ${product.name}' : 'Do not spray now',
    status: canSave ? 'Spray ${bedsText(usableBeds)} for ${target.short.toLowerCase()}' : 'Wait — conditions or holds block this spray',
    targetId: targetId,
    beds: usableBeds.isEmpty ? selectedBeds : usableBeds,
    cropNames: cropNames,
    product: product,
    bunningsProduct: bunnings,
    when: canSave ? 'Best time: ${weather.bestSprayWindow}' : 'Next action: wait until ${weather.bestSprayWindow}, then re-check.',
    reason: targetId == 'fungus'
        ? 'Fungal pressure / ${weather.humidityPercent}% humidity'
        : targetId == 'pest'
            ? 'Visible pest pressure check'
            : targetId == 'prevent'
                ? 'Preventative spray window'
                : 'Plant support spray',
    notes: notes,
    canSave: canSave,
    color: color,
    background: background,
  );
}

class EasySprayPlanCard extends StatelessWidget {
  const EasySprayPlanCard({required this.plan, required this.onUsePlan, required this.onOpenProduct, super.key});
  final EasySprayPlan plan;
  final VoidCallback onUsePlan;
  final VoidCallback? onOpenProduct;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: plan.background, borderRadius: BorderRadius.circular(24), border: Border.all(color: C.line), boxShadow: softShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 46, height: 46, alignment: Alignment.center, decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(16)), child: Icon(CupertinoIcons.wand_stars, color: plan.color, size: 23)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Easy spray plan', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: C.forest)),
                      Text(plan.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: plan.color)),
                      const SizedBox(height: 3),
                      Text(plan.status, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink, fontWeight: FontWeight.w800, fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AdvisorRow(text: plan.when, color: plan.color, background: C.card),
            AdvisorRow(text: 'Reason: ${plan.reason}', color: plan.color, background: C.card),
            ...plan.notes.take(5).map((line) => AdvisorRow(text: line, color: plan.color, background: C.card)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: PrimaryButton(label: 'Use plan', onPressed: plan.product == null ? null : onUsePlan)),
                const SizedBox(width: 10),
                Expanded(child: SecondaryButton(label: 'Bunnings', onPressed: onOpenProduct)),
              ],
            ),
          ],
        ),
      );
}

'@

if ($src -notmatch 'class EasySprayPlan') {
  $src = $src.Replace('class SprayLogScreen extends StatefulWidget {', $easyBlock + 'class SprayLogScreen extends StatefulWidget {')
}

$oldCtor = 'const SprayLogScreen({required this.initialBeds, required this.initialCrops, required this.initialTarget, required this.bedCrops, required this.products, required this.onSave, super.key});'
$newCtor = 'const SprayLogScreen({required this.initialBeds, required this.initialCrops, required this.initialTarget, required this.bedCrops, required this.products, required this.activeRecords, required this.weather, required this.onSave, super.key});'
if ($src.Contains($oldCtor)) {
  $src = $src.Replace($oldCtor, $newCtor)
}

# Add fields only inside SprayLogScreen, not ProductsScreen.
if ($src -notmatch 'final List<SprayRecord> activeRecords;') {
  $fieldPattern = '(class SprayLogScreen extends StatefulWidget \{[\s\S]*?\r?\n\s+final List<SprayProduct> products;)'
  if ($src -match $fieldPattern) {
    $src = [regex]::Replace($src, $fieldPattern, "`$1`r`n  final List<SprayRecord> activeRecords;`r`n  final GardenWeatherSnapshot weather;", 1)
  } else {
    throw 'Could not find SprayLogScreen product field insertion point.'
  }
}

$oldPage = 'SprayLogScreen(initialBeds: sprayBeds, initialCrops: sprayCrops, initialTarget: sprayTarget, bedCrops: bedCrops, products: products, onSave: saveSpray)'
$newPage = 'SprayLogScreen(initialBeds: sprayBeds, initialCrops: sprayCrops, initialTarget: sprayTarget, bedCrops: bedCrops, products: products, activeRecords: activeSprays, weather: weather, onSave: saveSpray)'
if ($src.Contains($oldPage)) {
  $src = $src.Replace($oldPage, $newPage)
}

$oldBuildStart = "    final activeCrops = currentCrops();`r`n    return AppPage(title: 'Spray Log', subtitle: 'Sprays link to beds, crops, products and withholding.', children: ["
$newBuildStart = "    final activeCrops = currentCrops();`r`n    final plan = buildEasySprayPlan(selectedBeds: beds, selectedCrops: crops, activeCrops: activeCrops, selectedTargetId: targetId, products: widget.products, activeRecords: widget.activeRecords, weather: widget.weather, now: DateTime.now());`r`n    return AppPage(title: 'Spray Log', subtitle: 'One recommendation. One product. One save button.', children: [`r`n      EasySprayPlanCard(plan: plan, onUsePlan: () => setState(() { targetId = plan.targetId; if (plan.product != null) { product = plan.product!; days = plan.product!.days; } beds = plan.beds; crops = plan.cropNames; if (reason.text.trim().isEmpty) reason.text = plan.reason; }), onOpenProduct: plan.bunningsProduct == null ? null : () => openBunningsUrl(plan.bunningsProduct!.url, plan.bunningsProduct!.fallbackUrl)),`r`n      const SizedBox(height: 18),"
if ($src.Contains($oldBuildStart)) {
  $src = $src.Replace($oldBuildStart, $newBuildStart)
} elseif ($src -notmatch 'EasySprayPlanCard\(plan: plan') {
  throw 'Could not find SprayLogScreen build insertion point.'
}

$oldSave = "PrimaryButton(label: 'Save spray record', onPressed: beds.isEmpty || widget.products.isEmpty ? null : () => widget.onSave(beds: beds, crops: crops, targetId: targetId, product: product, reason: reason.text, notes: notes.text, days: days))"
$newSave = "PrimaryButton(label: plan.canSave ? 'Save recommended spray' : 'Blocked — do not spray', onPressed: plan.canSave && widget.products.isNotEmpty ? () => widget.onSave(beds: plan.beds, crops: plan.cropNames, targetId: plan.targetId, product: plan.product ?? product, reason: reason.text.trim().isEmpty ? plan.reason : reason.text, notes: notes.text, days: plan.product?.days ?? days) : null)"
if ($src.Contains($oldSave)) {
  $src = $src.Replace($oldSave, $newSave)
}

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
if ($check -notmatch 'EasySprayPlanCard\(plan: plan') {
  throw 'Patch finished but EasySprayPlanCard was not found in SprayLogScreen.'
}
if ($check -notmatch 'One recommendation\. One product\. One save button\.') {
  throw 'Patch finished but Spray Log subtitle was not updated.'
}

Write-Host 'Applied easy Spray tab workflow.'
Write-Host 'Verified: Spray tab subtitle now says One recommendation. One product. One save button.'
Write-Host 'Next: flutter analyze; flutter run, then fully stop/restart the app on phone.'
