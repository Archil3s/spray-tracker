$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }
$src = Get-Content $mainPath -Raw

$old = @'
const SectionTitle('Beds sprayed'), const SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 8, children: gardenBeds.map((b) => NumberChip(label: '${b.number}', selected: beds.contains(b.number), onTap: () => setState(() { beds.contains(b.number) ? beds.remove(b.number) : beds.add(b.number); final names = currentCrops().map((c) => c.name).toSet(); crops = names.isEmpty ? {'Whole bed'} : names; }))).toList()),
'@

$new = @'
BedSprayedSelector(
        selectedBeds: beds,
        bedCrops: widget.bedCrops,
        onToggle: (bed) => setState(() {
          beds.contains(bed) ? beds.remove(bed) : beds.add(bed);
          syncSprayCropsFromBeds();
        }),
        onClear: () => setState(() {
          beds.clear();
          syncSprayCropsFromBeds();
        }),
        onSelectPlanted: () => setState(() {
          beds = widget.bedCrops.keys.toSet();
          syncSprayCropsFromBeds();
        }),
      ),
'@

if ($src.Contains($old)) {
  $src = $src.Replace($old, $new)
} elseif ($src -notmatch 'BedSprayedSelector\(') {
  throw 'Could not find the old Beds sprayed chip row. Apply rehaul-log-ui-only.ps1 first, then run this script.'
}

# Add helper method inside _SprayLogScreenState if missing.
if ($src -notmatch 'void syncSprayCropsFromBeds\(\)') {
  $src = $src.Replace(
    "List<VegetableDefinition> currentCrops() => beds.expand((bed) => widget.bedCrops[bed] ?? const <VegetableDefinition>[]).toSet().toList();",
    "List<VegetableDefinition> currentCrops() => beds.expand((bed) => widget.bedCrops[bed] ?? const <VegetableDefinition>[]).toSet().toList();`r`n`r`n  void syncSprayCropsFromBeds() {`r`n    final names = currentCrops().map((crop) => crop.name).toSet();`r`n    crops = names.isEmpty ? {'Whole bed'} : names;`r`n  }"
  )
}

$bedClasses = @'
class BedSprayedSelector extends StatelessWidget {
  const BedSprayedSelector({required this.selectedBeds, required this.bedCrops, required this.onToggle, required this.onClear, required this.onSelectPlanted, super.key});
  final Set<int> selectedBeds;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final ValueChanged<int> onToggle;
  final VoidCallback onClear;
  final VoidCallback onSelectPlanted;

  @override
  Widget build(BuildContext context) {
    final selectedList = selectedBeds.toList()..sort();
    final selectedLabel = selectedList.isEmpty ? 'No beds selected' : 'Selected: ${selectedList.map((bed) => 'Bed $bed').join(', ')}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: C.forestSoft, borderRadius: BorderRadius.circular(15)), child: const Icon(CupertinoIcons.square_grid_2x2, color: C.forest, size: 22)),
              const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Beds sprayed', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: C.forest)),
                Text(selectedLabel, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)),
              ])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SecondaryButton(label: 'Planted beds', onPressed: onSelectPlanted)),
              const SizedBox(width: 10),
              Expanded(child: DangerButton(label: 'Clear beds', onPressed: selectedBeds.isEmpty ? null : onClear)),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width < 360 ? 3 : 4;
            final spacing = 8.0;
            final tileWidth = (width - (spacing * (columns - 1))) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: gardenBeds.map((bed) {
                final crops = bedCrops[bed.number] ?? const <VegetableDefinition>[];
                return SizedBox(
                  width: tileWidth,
                  child: SprayBedCard(
                    bed: bed.number,
                    selected: selectedBeds.contains(bed.number),
                    cropCount: crops.length,
                    crops: crops,
                    onTap: () => onToggle(bed.number),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class SprayBedCard extends StatelessWidget {
  const SprayBedCard({required this.bed, required this.selected, required this.cropCount, required this.crops, required this.onTap, super.key});
  final int bed;
  final bool selected;
  final int cropCount;
  final List<VegetableDefinition> crops;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? C.forest : cropCount > 0 ? C.forestSoft : C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? C.forest : C.line, width: selected ? 2 : 1),
            boxShadow: selected ? softShadow : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Bed', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? CupertinoColors.white.withValues(alpha: .82) : C.muted, fontSize: 10, fontWeight: FontWeight.w900))),
                  Icon(selected ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle, size: 16, color: selected ? CupertinoColors.white : C.muted),
                ],
              ),
              const SizedBox(height: 3),
              Text('$bed', style: TextStyle(color: selected ? CupertinoColors.white : C.forest, fontSize: 25, height: 1, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(color: selected ? CupertinoColors.white.withValues(alpha: .16) : C.card, borderRadius: BorderRadius.circular(999), border: Border.all(color: selected ? CupertinoColors.white.withValues(alpha: .20) : C.line)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.leaf_arrow_circlepath, size: 11, color: selected ? CupertinoColors.white : C.forest),
                    const SizedBox(width: 3),
                    Flexible(child: Text(cropCount == 0 ? 'Empty' : '$cropCount crop${cropCount == 1 ? '' : 's'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? CupertinoColors.white : C.ink, fontSize: 10, fontWeight: FontWeight.w900))),
                  ],
                ),
              ),
              if (crops.isNotEmpty) ...[
                const SizedBox(height: 7),
                Text(crops.take(2).map((crop) => crop.name).join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? CupertinoColors.white.withValues(alpha: .82) : C.muted, fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ),
      );
}

'@

# Replace existing BedSprayedSelector block if it exists, otherwise insert.
if ($src -match 'class BedSprayedSelector extends StatelessWidget \{') {
  if ($src -match 'class BedSprayedSelector extends StatelessWidget \{[\s\S]*?class SprayProgressItem \{') {
    $src = [regex]::Replace($src, 'class BedSprayedSelector extends StatelessWidget \{[\s\S]*?class SprayProgressItem \{', $bedClasses + 'class SprayProgressItem {', 1)
  } elseif ($src -match 'class BedSprayedSelector extends StatelessWidget \{[\s\S]*?class FeedLogScreen extends StatefulWidget \{') {
    $src = [regex]::Replace($src, 'class BedSprayedSelector extends StatelessWidget \{[\s\S]*?class FeedLogScreen extends StatefulWidget \{', $bedClasses + 'class FeedLogScreen extends StatefulWidget {', 1)
  }
} else {
  if ($src -match 'class SprayProgressItem \{') {
    $src = $src.Replace('class SprayProgressItem {', $bedClasses + 'class SprayProgressItem {')
  } elseif ($src -match 'class FeedLogScreen extends StatefulWidget') {
    $src = $src.Replace('class FeedLogScreen extends StatefulWidget {', $bedClasses + 'class FeedLogScreen extends StatefulWidget {')
  } else {
    throw 'Could not find helper class insertion point.'
  }
}

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
foreach ($marker in @('BedSprayedSelector', 'SprayBedCard', 'Planted beds', 'Clear beds', 'syncSprayCropsFromBeds', 'final selectedList = selectedBeds.toList()..sort();')) {
  if ($check -notmatch [regex]::Escape($marker)) { throw "Missing bed UI marker: $marker" }
}
if ($check -match "final selectedText = selectedBeds.isEmpty") { throw 'Old selectedText bug still exists.' }

Write-Host 'Applied improved Beds sprayed selector UI.'
Write-Host 'Verified markers: BedSprayedSelector, SprayBedCard, Planted beds, Clear beds.'
Write-Host 'Next: flutter analyze; flutter run'
