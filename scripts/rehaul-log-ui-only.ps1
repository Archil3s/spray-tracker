$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }
$src = Get-Content $mainPath -Raw

$summary = @'
      Panel(
        color: C.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 50, height: 50, alignment: Alignment.center, decoration: BoxDecoration(color: C.forestSoft, borderRadius: BorderRadius.circular(18)), child: const Icon(CupertinoIcons.link_circle, color: C.forest, size: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Linked review', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: C.forest)),
                    const SizedBox(height: 3),
                    Text('Tap through the cards below, then save the record once everything matches.', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SprayProgressStrip(items: [
              SprayProgressItem(icon: CupertinoIcons.square_grid_2x2, label: 'Beds', done: beds.isNotEmpty),
              SprayProgressItem(icon: CupertinoIcons.leaf_arrow_circlepath, label: 'Crops', done: crops.isNotEmpty),
              SprayProgressItem(icon: targetById(targetId).icon, label: 'Target', done: targetId.isNotEmpty),
              SprayProgressItem(icon: CupertinoIcons.cube_box, label: 'Product', done: product.name.isNotEmpty),
              SprayProgressItem(icon: CupertinoIcons.check_mark_circled, label: 'Save', done: beds.isNotEmpty && product.name.isNotEmpty),
            ]),
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
            ProductReviewPanel(product: product, days: days, onOpenProducts: widget.onOpenProducts),
            const SizedBox(height: 10),
            const Text('Check the product label before use. This screen records what you applied after review.', style: TextStyle(fontWeight: FontWeight.w700, color: C.muted, fontSize: 12)),
          ],
        ),
      ),
      const SizedBox(height: 18),
'@

$reviewClasses = @'
class SprayProgressItem {
  const SprayProgressItem({required this.icon, required this.label, required this.done});
  final IconData icon;
  final String label;
  final bool done;
}

class SprayProgressStrip extends StatelessWidget {
  const SprayProgressStrip({required this.items, super.key});
  final List<SprayProgressItem> items;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items.map((item) => Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                decoration: BoxDecoration(color: item.done ? C.forest : C.soft, borderRadius: BorderRadius.circular(999), border: Border.all(color: item.done ? C.forest : C.line)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, size: 14, color: item.done ? CupertinoColors.white : C.muted),
                    const SizedBox(width: 5),
                    Text(item.label, style: TextStyle(color: item.done ? CupertinoColors.white : C.muted, fontWeight: FontWeight.w900, fontSize: 11)),
                  ],
                ),
              )).toList(),
        ),
      );
}

class ProductReviewPanel extends StatelessWidget {
  const ProductReviewPanel({required this.product, required this.days, required this.onOpenProducts, super.key});
  final SprayProduct product;
  final int days;
  final VoidCallback onOpenProducts;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: C.purpleSoft, borderRadius: BorderRadius.circular(20), border: Border.all(color: C.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(15)), child: const Icon(CupertinoIcons.cube_box, color: C.purple, size: 22)),
                const SizedBox(width: 11),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Linked product', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: C.purple, fontWeight: FontWeight.w900, fontSize: 12)),
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: C.ink)),
                  const SizedBox(height: 2),
                  Text(product.type, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(999)), child: Text('$days days', style: const TextStyle(color: C.purple, fontWeight: FontWeight.w900, fontSize: 12))),
              ],
            ),
            const SizedBox(height: 10),
            const Text('This is pulled from your Products tab. Use the product cards below to change the selected item, or open Products to edit the list.', style: TextStyle(fontWeight: FontWeight.w700, color: C.muted, fontSize: 12, height: 1.25)),
            const SizedBox(height: 10),
            SecondaryButton(label: 'Open Products tab', onPressed: onOpenProducts),
          ],
        ),
      );
}

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

$productChoiceClass = @'
class ProductChoice extends StatelessWidget {
  const ProductChoice({required this.product, required this.selected, required this.suggested, required this.onTap, super.key});
  final SprayProduct product;
  final bool selected;
  final bool suggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected ? C.forestSoft : C.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? C.forest : C.line, width: selected ? 2 : 1),
            boxShadow: selected ? softShadow : null,
          ),
          child: Row(
            children: [
              Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: selected ? C.forest : C.soft, borderRadius: BorderRadius.circular(15)), child: Icon(CupertinoIcons.cube_box, color: selected ? CupertinoColors.white : C.muted, size: 21)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: C.ink)),
                    const SizedBox(height: 3),
                    Text(product.type, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ProductTag(label: '${product.days} day hold', color: C.purple, background: C.purpleSoft),
                        if (suggested) const ProductTag(label: 'Target match', color: C.forest, background: C.forestSoft),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(selected ? '✓' : '○', style: TextStyle(color: selected ? C.forest : C.muted, fontSize: 25, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      );
}

'@

# Page subtitle and call site.
$src = $src.Replace("return AppPage(title: 'Spray Log', subtitle: 'Sprays link to beds, crops, products and withholding.', children: [", "return AppPage(title: 'Spray Log', subtitle: 'Guided review: bed, crop, target, product and Products link.', children: [")
$src = $src.Replace("return AppPage(title: 'Spray Log', subtitle: 'Guided review: bed, crop, target, product and Bunnings link.', children: [", "return AppPage(title: 'Spray Log', subtitle: 'Guided review: bed, crop, target, product and Products link.', children: [")

if ($src -notmatch 'onOpenProducts: \(\) => setState\(\(\) => tab = 4\)') {
  $src = $src.Replace("SprayLogScreen(initialBeds: sprayBeds, initialCrops: sprayCrops, initialTarget: sprayTarget, bedCrops: bedCrops, products: products, onSave: saveSpray)", "SprayLogScreen(initialBeds: sprayBeds, initialCrops: sprayCrops, initialTarget: sprayTarget, bedCrops: bedCrops, products: products, onOpenProducts: () => setState(() => tab = 4), onSave: saveSpray)")
  $src = $src.Replace("SprayLogScreen(initialBeds: sprayBeds, initialCrops: sprayCrops, initialTarget: sprayTarget, bedCrops: bedCrops, products: products, activeRecords: activeSprays, weather: weather, onSave: saveSpray)", "SprayLogScreen(initialBeds: sprayBeds, initialCrops: sprayCrops, initialTarget: sprayTarget, bedCrops: bedCrops, products: products, activeRecords: activeSprays, weather: weather, onOpenProducts: () => setState(() => tab = 4), onSave: saveSpray)")
}

# Constructor parameter.
$src = $src.Replace("const SprayLogScreen({required this.initialBeds, required this.initialCrops, required this.initialTarget, required this.bedCrops, required this.products, required this.onSave, super.key});", "const SprayLogScreen({required this.initialBeds, required this.initialCrops, required this.initialTarget, required this.bedCrops, required this.products, required this.onOpenProducts, required this.onSave, super.key});")
$src = $src.Replace("const SprayLogScreen({required this.initialBeds, required this.initialCrops, required this.initialTarget, required this.bedCrops, required this.products, required this.activeRecords, required this.weather, required this.onSave, super.key});", "const SprayLogScreen({required this.initialBeds, required this.initialCrops, required this.initialTarget, required this.bedCrops, required this.products, required this.activeRecords, required this.weather, required this.onOpenProducts, required this.onSave, super.key});")

# Widget field. This repairs the current broken state where the constructor exists but the field is missing.
if ($src -notmatch 'final VoidCallback onOpenProducts;') {
  $sprayBlockPattern = '(class SprayLogScreen extends StatefulWidget \{[\s\S]*?\r?\n\s*final List<SprayProduct> products;\r?\n)'
  if ($src -match $sprayBlockPattern) {
    $src = [regex]::Replace($src, $sprayBlockPattern, "`$1  final VoidCallback onOpenProducts;`r`n", 1)
  } else {
    throw 'Could not find SprayLogScreen products field to insert onOpenProducts.'
  }
}

# Remove any previously inserted helper blocks and insert a single clean copy.
if ($src -match 'class SprayProgressItem \{') {
  $src = [regex]::Replace($src, 'class SprayProgressItem \{[\s\S]*?class FeedLogScreen extends StatefulWidget \{', $reviewClasses + 'class FeedLogScreen extends StatefulWidget {', 1)
} elseif ($src -match 'class ReviewChip extends StatelessWidget \{') {
  $src = [regex]::Replace($src, 'class ReviewChip extends StatelessWidget \{[\s\S]*?class FeedLogScreen extends StatefulWidget \{', $reviewClasses + 'class FeedLogScreen extends StatefulWidget {', 1)
} else {
  $src = $src.Replace('class FeedLogScreen extends StatefulWidget {', $reviewClasses + 'class FeedLogScreen extends StatefulWidget {')
}

# Replace or insert the top linked review panel.
$linkedPanelPattern = '      Panel\(\r?\n        color: C\.card,\r?\n        child: Column\(\r?\n          crossAxisAlignment: CrossAxisAlignment\.start,\r?\n          children: \[\r?\n            Row\([\s\S]*?      const SizedBox\(height: 18\),\r?\n'
$forestPanelPattern = '      Panel\(\r?\n        color: C\.forestSoft,[\s\S]*?      const SizedBox\(height: 18\),\r?\n'
if ($src -match $linkedPanelPattern -and $src -match 'Linked review') {
  $src = [regex]::Replace($src, $linkedPanelPattern, $summary, 1)
} elseif ($src -match $forestPanelPattern -and $src -match 'Linked review') {
  $src = [regex]::Replace($src, $forestPanelPattern, $summary, 1)
} elseif ($src -notmatch 'ProductReviewPanel\(product: product') {
  $src = $src.Replace("return AppPage(title: 'Spray Log', subtitle: 'Guided review: bed, crop, target, product and Products link.', children: [", "return AppPage(title: 'Spray Log', subtitle: 'Guided review: bed, crop, target, product and Products link.', children: [`r`n$summary")
}

# Replace ProductChoice with visual card once.
$productPattern = 'class ProductChoice extends StatelessWidget \{[\s\S]*?\r?\nclass CropWrap extends StatelessWidget \{'
if ($src -match $productPattern) {
  $src = [regex]::Replace($src, $productPattern, $productChoiceClass + 'class CropWrap extends StatelessWidget {', 1)
}

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
foreach ($marker in @('SprayProgressStrip', 'ProductReviewPanel', 'Open Products tab', 'Target match', 'Tap through the cards below', 'final VoidCallback onOpenProducts;')) {
  if ($check -notmatch [regex]::Escape($marker)) { throw "Missing marker after visual polish: $marker" }
}

$dupNames = @('class SprayProgressItem', 'class SprayProgressStrip', 'class ProductReviewPanel')
foreach ($name in $dupNames) {
  $count = ([regex]::Matches($check, [regex]::Escape($name))).Count
  if ($count -ne 1) { throw "Duplicate check failed for $name. Found $count copies." }
}

Write-Host 'Applied visual and interactive Spray Log polish.'
Write-Host 'Verified: one helper copy, onOpenProducts field present, and visual markers inserted.'
Write-Host 'Next: flutter clean; flutter pub get; flutter analyze; flutter run'
