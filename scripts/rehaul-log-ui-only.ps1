$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }
$src = Get-Content $mainPath -Raw

# Make the Spray Log page visibly different and able to open the Products tab.
$src = $src.Replace(
"return AppPage(title: 'Spray Log', subtitle: 'Sprays link to beds, crops, products and withholding.', children: [",
"return AppPage(title: 'Spray Log', subtitle: 'Guided review: bed, crop, target, product and Products link.', children: ["
)
$src = $src.Replace(
"return AppPage(title: 'Spray Log', subtitle: 'Guided review: bed, crop, target, product and Bunnings link.', children: [",
"return AppPage(title: 'Spray Log', subtitle: 'Guided review: bed, crop, target, product and Products link.', children: ["
)

# Add a Products-tab callback to the SprayLogScreen constructor and call site.
$src = $src.Replace(
"SprayLogScreen(initialBeds: sprayBeds, initialCrops: sprayCrops, initialTarget: sprayTarget, bedCrops: bedCrops, products: products, onSave: saveSpray)",
"SprayLogScreen(initialBeds: sprayBeds, initialCrops: sprayCrops, initialTarget: sprayTarget, bedCrops: bedCrops, products: products, onOpenProducts: () => setState(() => tab = 4), onSave: saveSpray)"
)
$src = $src.Replace(
"SprayLogScreen(initialBeds: sprayBeds, initialCrops: sprayCrops, initialTarget: sprayTarget, bedCrops: bedCrops, products: products, activeRecords: activeSprays, weather: weather, onSave: saveSpray)",
"SprayLogScreen(initialBeds: sprayBeds, initialCrops: sprayCrops, initialTarget: sprayTarget, bedCrops: bedCrops, products: products, activeRecords: activeSprays, weather: weather, onOpenProducts: () => setState(() => tab = 4), onSave: saveSpray)"
)
$src = $src.Replace(
"const SprayLogScreen({required this.initialBeds, required this.initialCrops, required this.initialTarget, required this.bedCrops, required this.products, required this.onSave, super.key});",
"const SprayLogScreen({required this.initialBeds, required this.initialCrops, required this.initialTarget, required this.bedCrops, required this.products, required this.onOpenProducts, required this.onSave, super.key});"
)
$src = $src.Replace(
"const SprayLogScreen({required this.initialBeds, required this.initialCrops, required this.initialTarget, required this.bedCrops, required this.products, required this.activeRecords, required this.weather, required this.onSave, super.key});",
"const SprayLogScreen({required this.initialBeds, required this.initialCrops, required this.initialTarget, required this.bedCrops, required this.products, required this.activeRecords, required this.weather, required this.onOpenProducts, required this.onSave, super.key});"
)
if ($src -notmatch 'final VoidCallback onOpenProducts;') {
  $src = $src.Replace("  final List<SprayProduct> products;`r`n  final void Function", "  final List<SprayProduct> products;`r`n  final VoidCallback onOpenProducts;`r`n  final void Function")
  $src = $src.Replace("  final GardenWeatherSnapshot weather;`r`n  final void Function", "  final GardenWeatherSnapshot weather;`r`n  final VoidCallback onOpenProducts;`r`n  final void Function")
}

$summary = @'
      Panel(
        color: C.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 46, height: 46, alignment: Alignment.center, decoration: BoxDecoration(color: C.forestSoft, borderRadius: BorderRadius.circular(16)), child: const Icon(CupertinoIcons.link_circle, color: C.forest, size: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Linked review', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: C.forest)),
                    const SizedBox(height: 3),
                    Text('Everything below is connected to this record before you save it.', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ReviewChip(icon: CupertinoIcons.square_grid_2x2, label: 'Bed sprayed', value: beds.isEmpty ? 'None' : beds.map((b) => 'Bed $b').join(', '), color: C.forest, background: C.forestSoft),
                ReviewChip(icon: CupertinoIcons.leaf_arrow_circlepath, label: 'Crops affected', value: crops.isEmpty ? 'Whole bed' : crops.join(' · '), color: C.forest, background: C.forestSoft),
                ReviewChip(icon: targetById(targetId).icon, label: 'Spraying against', value: targetById(targetId).short, color: targetById(targetId).color, background: targetById(targetId).softColor),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: C.purpleSoft, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 38, height: 38, alignment: Alignment.center, decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(13)), child: const Icon(CupertinoIcons.cube_box, color: C.purple, size: 20)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: C.ink)),
                        Text('${product.type} · $days day withholding', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)),
                      ])),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Product comes from your Products tab. Edit or add products there, then return here to log the record.', style: TextStyle(fontWeight: FontWeight.w700, color: C.muted, fontSize: 12, height: 1.25)),
                  const SizedBox(height: 10),
                  SecondaryButton(label: 'Open Products tab', onPressed: widget.onOpenProducts),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text('Check the product label before use. This screen records what you applied after review.', style: TextStyle(fontWeight: FontWeight.w700, color: C.muted, fontSize: 12)),
          ],
        ),
      ),
      const SizedBox(height: 18),
'@

# Replace previous basic Linked review block if present; otherwise insert the polished block.
$oldPattern = '      Panel\(\r?\n        color: C\.forestSoft,[\s\S]*?      const SizedBox\(height: 18\),\r?\n'
if ($src -match $oldPattern) {
  $src = [regex]::Replace($src, $oldPattern, $summary, 1)
} elseif ($src -notmatch 'ReviewChip\(') {
  $src = $src.Replace(
"return AppPage(title: 'Spray Log', subtitle: 'Guided review: bed, crop, target, product and Products link.', children: [",
"return AppPage(title: 'Spray Log', subtitle: 'Guided review: bed, crop, target, product and Products link.', children: [`r`n$summary"
  )
}

$reviewChipClass = @'
class ReviewChip extends StatelessWidget {
  const ReviewChip({required this.icon, required this.label, required this.value, required this.color, required this.background, super.key});
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 132, maxWidth: 260),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(17), border: Border.all(color: C.line)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink, fontSize: 12, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      );
}

'@

if ($src -notmatch 'class ReviewChip extends StatelessWidget') {
  $src = $src.Replace('class FeedLogScreen extends StatefulWidget {', $reviewChipClass + 'class FeedLogScreen extends StatefulWidget {')
}

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
foreach ($marker in @('ReviewChip', 'Open Products tab', 'Everything below is connected', 'Guided review: bed, crop, target, product and Products link')) {
  if ($check -notmatch [regex]::Escape($marker)) { throw "Missing marker after UI polish: $marker" }
}

Write-Host 'Applied polished Spray Log linked-review UI.'
Write-Host 'Verified markers: ReviewChip, Open Products tab, Everything below is connected.'
Write-Host 'Next: flutter clean; flutter pub get; flutter analyze; flutter run'
