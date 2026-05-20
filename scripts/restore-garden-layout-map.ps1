$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }
$src = Get-Content $mainPath -Raw

# Keep the original physical garden layout, but make the map taller and easier to read.
$src = $src.Replace(
  'final mapHeight = clampDouble(MediaQuery.of(context).size.height * .42, 285, 430);',
  'final mapHeight = clampDouble(MediaQuery.of(context).size.height * .58, 460, 680);'
)
$src = $src.Replace(
  'final mapHeight = clampDouble(MediaQuery.of(context).size.height * .50, 330, 500);',
  'final mapHeight = clampDouble(MediaQuery.of(context).size.height * .58, 460, 680);'
)
$src = $src.Replace(
  'final mapHeight = clampDouble(MediaQuery.of(context).size.height * .55, 430, 620);',
  'final mapHeight = clampDouble(MediaQuery.of(context).size.height * .58, 460, 680);'
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
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: CustomPaint(painter: GridPainter())),
            ...gardenBeds.map((bed) {
              final r = Rect.fromLTWH(
                bed.rect.left * size.width,
                bed.rect.top * size.height,
                bed.rect.width * size.width,
                bed.rect.height * size.height,
              );
              return Positioned.fromRect(
                rect: r,
                child: LayoutGardenBedButton(
                  number: bed.number,
                  selected: selectedBed == bed.number,
                  hold: isHold(bed.number),
                  crops: bedCrops[bed.number] ?? const <VegetableDefinition>[],
                  sprayCount: sprayRecords.where((record) => record.beds.contains(bed.number)).length,
                  feedCount: feedRecords.where((record) => record.beds.contains(bed.number)).length,
                  onTap: () => onTap(bed.number),
                ),
              );
            }),
          ],
        );
      });
}

class LayoutGardenBedButton extends StatelessWidget {
  const LayoutGardenBedButton({required this.number, required this.selected, required this.hold, required this.crops, required this.sprayCount, required this.feedCount, required this.onTap, super.key});
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
    final labelColor = selected ? CupertinoColors.white : color;
    final isSmall = crops.isEmpty && !selected && !hold;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(selected ? 13 : 10),
          border: Border.all(color: selected ? C.forest : hold ? C.amber : C.soil, width: selected ? 2.5 : 1.1),
          boxShadow: selected ? softShadow : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: labelColor,
                      fontSize: isSmall ? 18 : 22,
                      height: .95,
                    ),
                  ),
                ),
              ),
            ),
            if (selected || hold)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: selected ? C.forest : C.amber, shape: BoxShape.circle, border: Border.all(color: C.card, width: 2), boxShadow: softShadow),
                  child: Icon(selected ? CupertinoIcons.check_mark : CupertinoIcons.hand_raised_fill, color: CupertinoColors.white, size: 12),
                ),
              ),
            if (crops.isNotEmpty)
              Positioned(
                left: -7,
                top: -9,
                child: LayoutCropMiniCluster(crops: crops, selected: selected),
              ),
            if (sprayCount > 0 || feedCount > 0)
              Positioned(
                left: -7,
                bottom: -9,
                child: BedActivityBadges(sprayCount: sprayCount, feedCount: feedCount),
              ),
          ],
        ),
      ),
    );
  }
}

class LayoutCropMiniCluster extends StatelessWidget {
  const LayoutCropMiniCluster({required this.crops, required this.selected, super.key});
  final List<VegetableDefinition> crops;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 92),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(999), border: Border.all(color: selected ? C.forest : C.line), boxShadow: softShadow),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...crops.take(3).map((crop) => Padding(padding: const EdgeInsets.only(right: 2), child: CropIcon(crop.iconPath, size: 18))),
            if (crops.length > 3) Text('+${crops.length - 3}', style: const TextStyle(color: C.forest, fontSize: 9, fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

'@

$pattern = 'class GardenMap extends StatelessWidget \{[\s\S]*?\r?\nclass BedButton extends StatelessWidget \{'
if ($src -notmatch $pattern) { throw 'Could not find GardenMap block to replace.' }
$src = [regex]::Replace($src, $pattern, $newGardenMap + 'class BedButton extends StatelessWidget {', 1)

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
foreach ($marker in @('LayoutGardenBedButton', 'LayoutCropMiniCluster', 'Rect.fromLTWH', 'bed.rect.left', 'MediaQuery.of(context).size.height * .58')) {
  if ($check -notmatch [regex]::Escape($marker)) { throw "Missing original-layout map marker: $marker" }
}
if ($check -match 'ReadableGardenBedCard') { throw 'Readable grid map still exists. Original layout was not restored.' }

Write-Host 'Restored the original physical garden layout with clearer bed buttons.'
Write-Host 'The map keeps bed positions but uses larger labels, clearer selected/hold badges, crop icons and activity badges.'
Write-Host 'Next: flutter analyze; flutter run'
