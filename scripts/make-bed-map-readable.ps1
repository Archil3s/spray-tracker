$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }
$src = Get-Content $mainPath -Raw

# Make the Garden tab map area taller if the improved Garden tab has already been applied.
$src = $src.Replace(
  'final mapHeight = clampDouble(MediaQuery.of(context).size.height * .42, 285, 430);',
  'final mapHeight = clampDouble(MediaQuery.of(context).size.height * .55, 430, 620);'
)
$src = $src.Replace(
  'final mapHeight = clampDouble(MediaQuery.of(context).size.height * .50, 330, 500);',
  'final mapHeight = clampDouble(MediaQuery.of(context).size.height * .55, 430, 620);'
)

$newGardenMap = @'
class GardenMap extends StatelessWidget {
  const GardenMap({required this.selectedBed, required this.bedCrops, required this.sprayRecords, required this.feedRecords, required this.isHold, required this.onTap, super.key});
  final int selectedBed;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final List<SprayRecord> sprayRecords;
  final List<FeedRecord> feedRecords;
  final bool Function(int bed) isHold;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width < 360 ? 2 : width < 520 ? 3 : 4;
        final spacing = 10.0;
        final tileWidth = (width - (spacing * (columns - 1))) / columns;
        return SingleChildScrollView(
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: gardenBeds.map((bed) {
              final crops = bedCrops[bed.number] ?? const <VegetableDefinition>[];
              final sprayCount = sprayRecords.where((record) => record.beds.contains(bed.number)).length;
              final feedCount = feedRecords.where((record) => record.beds.contains(bed.number)).length;
              return SizedBox(
                width: tileWidth,
                child: ReadableGardenBedCard(
                  number: bed.number,
                  selected: selectedBed == bed.number,
                  hold: isHold(bed.number),
                  crops: crops,
                  sprayCount: sprayCount,
                  feedCount: feedCount,
                  onTap: () => onTap(bed.number),
                ),
              );
            }).toList(),
          ),
        );
      });
}

class ReadableGardenBedCard extends StatelessWidget {
  const ReadableGardenBedCard({required this.number, required this.selected, required this.hold, required this.crops, required this.sprayCount, required this.feedCount, required this.onTap, super.key});
  final int number;
  final bool selected;
  final bool hold;
  final List<VegetableDefinition> crops;
  final int sprayCount;
  final int feedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = hold ? C.amber : selected ? C.forest : crops.isEmpty ? C.muted : C.forest;
    final background = hold ? C.amberSoft : selected ? C.forest : crops.isEmpty ? C.card : C.forestSoft;
    final textColor = selected ? CupertinoColors.white : C.ink;
    final mutedColor = selected ? CupertinoColors.white.withValues(alpha: .78) : C.muted;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        constraints: const BoxConstraints(minHeight: 126),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? C.forest : hold ? C.amber : C.line, width: selected ? 2.4 : 1),
          boxShadow: selected ? softShadow : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text('BED', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: mutedColor, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: .6))),
                Icon(selected ? CupertinoIcons.check_mark_circled_solid : hold ? CupertinoIcons.hand_raised_fill : CupertinoIcons.circle, size: 18, color: selected ? CupertinoColors.white : color),
              ],
            ),
            const SizedBox(height: 3),
            Text('$number', style: TextStyle(color: selected ? CupertinoColors.white : color, fontSize: 32, height: .95, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: BedStatusMiniPill(label: hold ? 'HOLD' : crops.isEmpty ? 'EMPTY' : 'PLANTED', color: selected ? CupertinoColors.white : color, selected: selected)),
                if (sprayCount > 0 || feedCount > 0) ...[
                  const SizedBox(width: 5),
                  BedActivityBadges(sprayCount: sprayCount, feedCount: feedCount),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (crops.isEmpty)
              Text('Tap to select', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: mutedColor, fontSize: 11, fontWeight: FontWeight.w700))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(spacing: 3, runSpacing: 3, children: crops.take(4).map((crop) => CropIcon(crop.iconPath, size: 22)).toList()),
                  const SizedBox(height: 5),
                  Text(crops.take(2).map((crop) => crop.name).join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? CupertinoColors.white.withValues(alpha: .84) : C.muted, fontSize: 10.5, fontWeight: FontWeight.w800)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class BedStatusMiniPill extends StatelessWidget {
  const BedStatusMiniPill({required this.label, required this.color, required this.selected, super.key});
  final String label;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(color: selected ? CupertinoColors.white.withValues(alpha: .16) : C.card, borderRadius: BorderRadius.circular(999), border: Border.all(color: selected ? CupertinoColors.white.withValues(alpha: .18) : C.line)),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? CupertinoColors.white : color, fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: .4)),
      );
}

'@

$pattern = 'class GardenMap extends StatelessWidget \{[\s\S]*?\r?\nclass BedButton extends StatelessWidget \{'
if ($src -notmatch $pattern) { throw 'Could not find GardenMap block to replace.' }
$src = [regex]::Replace($src, $pattern, $newGardenMap + 'class BedButton extends StatelessWidget {', 1)

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
foreach ($marker in @('ReadableGardenBedCard', 'BedStatusMiniPill', 'minHeight: 126', 'SingleChildScrollView', 'MediaQuery.of(context).size.height * .55')) {
  if ($check -notmatch [regex]::Escape($marker)) { throw "Missing readable bed map marker: $marker" }
}

Write-Host 'Applied readable Garden bed map.'
Write-Host 'The compressed coordinate map is replaced by large readable bed cards with crop icons and activity badges.'
Write-Host 'Next: flutter analyze; flutter run'
