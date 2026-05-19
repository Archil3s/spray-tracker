$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
$repairFeedScript = Join-Path $PSScriptRoot 'repair-feeding-tracker-state.ps1'

if (-not (Test-Path $mainPath)) {
  throw "Could not find lib/main.dart from $PSScriptRoot"
}

$src = Get-Content $mainPath -Raw

# Repair the common Feeding Tracker partial-apply state before adding feed icons.
if ($src -match 'class FeedRecord' -and $src -notmatch 'List<FeedRecord> feedRecords' -and (Test-Path $repairFeedScript)) {
  & $repairFeedScript
  $src = Get-Content $mainPath -Raw
}

$hasFeedTracker = $src -match 'List<FeedRecord> feedRecords'

# -----------------------------
# Testing reset methods
# -----------------------------
if ($src -notmatch 'void resetToDemoData') {
  $feedDemoReset = if ($hasFeedTracker) "`r`n        feedRecords.clear();`r`n        nextFeedId = 1;" else ''
  $feedClearReset = if ($hasFeedTracker) "`r`n        feedRecords.clear();`r`n        nextFeedId = 1;" else ''

  $methodBlock = @"

  void resetToDemoData() => setState(() {
        bedCrops.clear();
        records.clear();$feedDemoReset
        nextRecordId = 1;
        nextProductId = 5;
        selectedBed = 4;
        sprayBeds = {4};
        sprayCrops = {'Tomato', 'Chilli'};
        sprayTarget = 'pest';
        products = const [
          SprayProduct(id: 1, name: 'Neem Oil', type: 'Pest control', days: 3, targets: ['pest', 'prevent']),
          SprayProduct(id: 2, name: 'Copper Hydroxide', type: 'Fungicide', days: 7, targets: ['fungus', 'prevent']),
          SprayProduct(id: 3, name: 'Seaweed Tonic', type: 'Plant tonic', days: 1, targets: ['maintain', 'prevent']),
          SprayProduct(id: 4, name: 'Pyrethrin', type: 'Insecticide', days: 3, targets: ['pest']),
        ].toList();
        seedDemoData();
        message = 'Test data reset to demo garden';
        tab = 0;
      });

  void clearAllTestingData() => setState(() {
        bedCrops.clear();
        records.clear();$feedClearReset
        products.clear();
        nextRecordId = 1;
        nextProductId = 1;
        selectedBed = 1;
        sprayBeds = {1};
        sprayCrops = {'Whole bed'};
        sprayTarget = 'pest';
        message = 'All test data cleared';
        tab = 0;
      });
"@

  if ($src -match '\s+void removeProduct\(int id\) => setState\(\(\) \{') {
    $src = [regex]::Replace($src, '(\s+void removeProduct\(int id\) => setState\(\(\) \{)', $methodBlock + '$1', 1)
  } else {
    throw 'Could not find removeProduct() insertion point for testing reset methods.'
  }
}

# -----------------------------
# Testing reset UI card
# -----------------------------
$testingCardBlock = @'
class TestingToolsCard extends StatelessWidget {
  const TestingToolsCard({required this.onResetDemo, required this.onClearAll, super.key});
  final VoidCallback onResetDemo;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: cardDecoration(radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Testing tools', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: C.forest)),
            const SizedBox(height: 4),
            const Text('Reset local demo data while testing screens, sprays, feeds and bed badges.', style: TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: SecondaryButton(label: 'Reset demo', onPressed: onResetDemo)),
                const SizedBox(width: 10),
                Expanded(child: DangerButton(label: 'Clear all', onPressed: onClearAll)),
              ],
            ),
          ],
        ),
      );
}

'@

if ($src -notmatch 'class TestingToolsCard') {
  $src = $src.Replace('class ProductsScreen extends StatelessWidget {', $testingCardBlock + 'class ProductsScreen extends StatelessWidget {')
}

if ($src -notmatch 'required this.onResetDemo') {
  $src = $src.Replace('const ProductsScreen({required this.products, required this.message, required this.onAdd, required this.onDelete, super.key});', 'const ProductsScreen({required this.products, required this.message, required this.onAdd, required this.onDelete, required this.onResetDemo, required this.onClearAll, super.key});')
}

if ($src -notmatch 'final VoidCallback onResetDemo;') {
  $src = $src.Replace('  final ValueChanged<int> onDelete;', "  final ValueChanged<int> onDelete;`r`n  final VoidCallback onResetDemo;`r`n  final VoidCallback onClearAll;")
}

if ($src -notmatch 'TestingToolsCard\(') {
  if ($src.Contains("children: [const BunningsSprayProductsPanel(),")) {
    $src = $src.Replace("children: [const BunningsSprayProductsPanel(),", "children: [TestingToolsCard(onResetDemo: onResetDemo, onClearAll: onClearAll), const BunningsSprayProductsPanel(),")
  } elseif ($src.Contains("children: products.map((p) => ProductTile(product: p, onDelete: () => onDelete(p.id))).toList()")) {
    $src = $src.Replace("children: products.map((p) => ProductTile(product: p, onDelete: () => onDelete(p.id))).toList()", "children: [TestingToolsCard(onResetDemo: onResetDemo, onClearAll: onClearAll), ...products.map((p) => ProductTile(product: p, onDelete: () => onDelete(p.id)))]")
  } else {
    throw 'Could not find ProductsScreen children insertion point for TestingToolsCard.'
  }
}

if ($src -notmatch 'onResetDemo: resetToDemoData') {
  $src = $src.Replace('ProductsScreen(products: products, message: message, onAdd: addProduct, onDelete: removeProduct)', 'ProductsScreen(products: products, message: message, onAdd: addProduct, onDelete: removeProduct, onResetDemo: resetToDemoData, onClearAll: clearAllTestingData)')
}

# -----------------------------
# Bed activity icons/badges
# -----------------------------
$activityBlock = @'
class BedActivityBadges extends StatelessWidget {
  const BedActivityBadges({required this.sprayCount, required this.feedCount, super.key});
  final int sprayCount;
  final int feedCount;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(999), border: Border.all(color: C.line), boxShadow: softShadow),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sprayCount > 0) BedActivityDot(icon: CupertinoIcons.drop, count: sprayCount, color: C.blue, background: C.blueSoft),
            if (sprayCount > 0 && feedCount > 0) const SizedBox(width: 3),
            if (feedCount > 0) BedActivityDot(icon: CupertinoIcons.leaf_arrow_circlepath, count: feedCount, color: C.purple, background: C.purpleSoft),
          ],
        ),
      );
}

class BedActivityDot extends StatelessWidget {
  const BedActivityDot({required this.icon, required this.count, required this.color, required this.background, super.key});
  final IconData icon;
  final int count;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 2),
            Text('$count', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

'@

if ($src -notmatch 'class BedActivityBadges') {
  $src = $src.Replace('class IconCluster extends StatelessWidget {', $activityBlock + 'class IconCluster extends StatelessWidget {')
}

if ($hasFeedTracker) {
  if ($src -notmatch 'required this.feedRecords') {
    $src = $src.Replace('const GardenScreen({required this.selectedBed, required this.bedCrops, required this.records, required this.message,', 'const GardenScreen({required this.selectedBed, required this.bedCrops, required this.records, required this.feedRecords, required this.message,')
    $src = $src.Replace('  final List<SprayRecord> records;', "  final List<SprayRecord> records;`r`n  final List<FeedRecord> feedRecords;")
  }

  if ($src -notmatch 'feedRecords: feedRecords, message') {
    $src = $src.Replace('GardenScreen(selectedBed: selectedBed, bedCrops: bedCrops, records: records, message:', 'GardenScreen(selectedBed: selectedBed, bedCrops: bedCrops, records: records, feedRecords: feedRecords, message:')
  }

  if ($src -notmatch 'GardenMap\(selectedBed: selectedBed, bedCrops: bedCrops, records: records') {
    $src = $src.Replace('GardenMap(selectedBed: selectedBed, bedCrops: bedCrops, isHold: bedOnHold, onTap: onSelectBed)', 'GardenMap(selectedBed: selectedBed, bedCrops: bedCrops, records: records, feedRecords: feedRecords, isHold: bedOnHold, onTap: onSelectBed)')
  }

  if ($src -notmatch 'required this.records, required this.feedRecords') {
    $src = $src.Replace('const GardenMap({required this.selectedBed, required this.bedCrops, required this.isHold, required this.onTap, super.key});', 'const GardenMap({required this.selectedBed, required this.bedCrops, required this.records, required this.feedRecords, required this.isHold, required this.onTap, super.key});')
    $src = $src.Replace('  final Map<int, List<VegetableDefinition>> bedCrops;', "  final Map<int, List<VegetableDefinition>> bedCrops;`r`n  final List<SprayRecord> records;`r`n  final List<FeedRecord> feedRecords;")
  }

  if ($src -notmatch 'sprayCount: records.where') {
    $src = $src.Replace('BedButton(number: bed.number, selected: selectedBed == bed.number, hold: isHold(bed.number), crops: bedCrops[bed.number] ?? const <VegetableDefinition>[], onTap: () => onTap(bed.number))', 'BedButton(number: bed.number, selected: selectedBed == bed.number, hold: isHold(bed.number), crops: bedCrops[bed.number] ?? const <VegetableDefinition>[], sprayCount: records.where((record) => record.beds.contains(bed.number)).length, feedCount: feedRecords.where((record) => record.beds.contains(bed.number)).length, onTap: () => onTap(bed.number))')
  }

  if ($src -notmatch 'required this.sprayCount') {
    $src = $src.Replace('const BedButton({required this.number, required this.selected, required this.hold, required this.crops, required this.onTap, super.key});', 'const BedButton({required this.number, required this.selected, required this.hold, required this.crops, required this.sprayCount, required this.feedCount, required this.onTap, super.key});')
    $src = $src.Replace('  final List<VegetableDefinition> crops;', "  final List<VegetableDefinition> crops;`r`n  final int sprayCount;`r`n  final int feedCount;")
  }

  if ($src -notmatch 'BedActivityBadges\(sprayCount: sprayCount') {
    $badgeLine = "            if (sprayCount > 0 || feedCount > 0) Positioned(left: -8, bottom: -10, child: BedActivityBadges(sprayCount: sprayCount, feedCount: feedCount)),"
    if ($src.Contains('if (crops.isNotEmpty) Positioned(top: -10, right: -10, child: IconCluster(crops: crops)),')) {
      $src = $src.Replace('if (crops.isNotEmpty) Positioned(top: -10, right: -10, child: IconCluster(crops: crops)),', "if (crops.isNotEmpty) Positioned(top: -10, right: -10, child: IconCluster(crops: crops)),`r`n$badgeLine")
    } elseif ($src.Contains('if (crops.isNotEmpty) Positioned(top: -12, right: -12, child: IconCluster(crops: crops)),')) {
      $src = $src.Replace('if (crops.isNotEmpty) Positioned(top: -12, right: -12, child: IconCluster(crops: crops)),', "if (crops.isNotEmpty) Positioned(top: -12, right: -12, child: IconCluster(crops: crops)),`r`n$badgeLine")
    } else {
      throw 'Could not find BedButton icon cluster insertion point.'
    }
  }
} else {
  Write-Host 'Feed tracker state was not found; testing reset was added, but feed bed badges require apply-feeding-tracker.ps1 first.'
}

Set-Content -Path $mainPath -Value $src -NoNewline
Write-Host 'Applied testing reset controls and bed activity badges.'
Write-Host 'Spray badges use drop icons. Feed badges use leaf icons. Counts are linked to logged bed records.'
Write-Host 'Next: flutter analyze; flutter run'
