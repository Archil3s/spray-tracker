$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }
$src = Get-Content $mainPath -Raw

$newGardenBlock = @'
class GardenScreen extends StatelessWidget {
  const GardenScreen({required this.selectedBed, required this.bedCrops, required this.sprayRecords, required this.feedRecords, required this.message, required this.onSelectBed, required this.onAddCrop, required this.onRemoveCrop, required this.onStartSpray, required this.onStartFeed, super.key});
  final int selectedBed;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final List<SprayRecord> sprayRecords;
  final List<FeedRecord> feedRecords;
  final String message;
  final ValueChanged<int> onSelectBed;
  final void Function(int bed, VegetableDefinition crop) onAddCrop;
  final void Function(int bed, VegetableDefinition crop) onRemoveCrop;
  final void Function(int bed, String target, Set<String> crops) onStartSpray;
  final ValueChanged<int> onStartFeed;

  bool bedOnHold(int bed) => sprayRecords.any((r) => r.beds.contains(bed) && r.safeDate.isAfter(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final crops = bedCrops[selectedBed] ?? const <VegetableDefinition>[];
    final bedSprays = sprayRecords.where((r) => r.beds.contains(selectedBed)).toList();
    final bedFeeds = feedRecords.where((r) => r.beds.contains(selectedBed)).toList();
    final plantedCount = bedCrops.values.where((items) => items.isNotEmpty).length;
    final holdCount = gardenBeds.where((bed) => bedOnHold(bed.number)).length;
    final clearCount = gardenBeds.length - holdCount;
    final mapHeight = clampDouble(MediaQuery.of(context).size.height * .42, 285, 430);

    return AppPage(
      title: 'Garden',
      subtitle: 'Tap a bed. Everything links back to crops, sprays and feeds.',
      message: message,
      children: [
        GardenOverviewStrip(planted: plantedCount, clear: clearCount, hold: holdCount, selectedBed: selectedBed),
        const SizedBox(height: 14),
        Panel(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 4, 4, 10),
                child: Text('Bed map', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: C.forest)),
              ),
              SizedBox(height: mapHeight, child: GardenMap(selectedBed: selectedBed, bedCrops: bedCrops, sprayRecords: sprayRecords, feedRecords: feedRecords, isHold: bedOnHold, onTap: onSelectBed)),
              const SizedBox(height: 10),
              const GardenMapLegend(),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SelectedBedHero(
          bed: selectedBed,
          crops: crops,
          sprayCount: bedSprays.length,
          feedCount: bedFeeds.length,
          hold: bedOnHold(selectedBed),
          onAddCrop: () => showCropPicker(context, selectedBed, crops, onAddCrop),
          onSpray: () => onStartSpray(selectedBed, 'pest', crops.map((c) => c.name).toSet()),
          onFeed: () => onStartFeed(selectedBed),
        ),
        const SizedBox(height: 14),
        BedCropPanel(
          bed: selectedBed,
          crops: crops,
          onAddCrop: () => showCropPicker(context, selectedBed, crops, onAddCrop),
          onRemoveCrop: (crop) => onRemoveCrop(selectedBed, crop),
        ),
        const SizedBox(height: 14),
        VisualBedActivityPanel(bed: selectedBed, sprayRecords: bedSprays, feedRecords: bedFeeds),
      ],
    );
  }
}

class GardenOverviewStrip extends StatelessWidget {
  const GardenOverviewStrip({required this.planted, required this.clear, required this.hold, required this.selectedBed, super.key});
  final int planted;
  final int clear;
  final int hold;
  final int selectedBed;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: GardenMetricTile(icon: CupertinoIcons.leaf_arrow_circlepath, label: 'Planted', value: '$planted', color: C.forest, background: C.forestSoft)),
          const SizedBox(width: 8),
          Expanded(child: GardenMetricTile(icon: CupertinoIcons.check_mark_circled, label: 'Clear', value: '$clear', color: C.blue, background: C.blueSoft)),
          const SizedBox(width: 8),
          Expanded(child: GardenMetricTile(icon: CupertinoIcons.hand_raised, label: 'Hold', value: '$hold', color: C.amber, background: C.amberSoft)),
          const SizedBox(width: 8),
          Expanded(child: GardenMetricTile(icon: CupertinoIcons.location, label: 'Bed', value: '$selectedBed', color: C.purple, background: C.purpleSoft)),
        ],
      );
}

class GardenMetricTile extends StatelessWidget {
  const GardenMetricTile({required this.icon, required this.label, required this.value, required this.color, required this.background, super.key});
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(height: 7),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 24, height: .95, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 10.5, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class GardenMapLegend extends StatelessWidget {
  const GardenMapLegend({super.key});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: const [
          GardenLegendChip(label: 'Selected', color: C.forest, background: C.forestSoft),
          GardenLegendChip(label: 'Harvest hold', color: C.amber, background: C.amberSoft),
          GardenLegendChip(label: 'Has crops', color: C.forest, background: C.forestSoft),
          GardenLegendChip(label: 'Spray/feed dots', color: C.purple, background: C.purpleSoft),
        ],
      );
}

class GardenLegendChip extends StatelessWidget {
  const GardenLegendChip({required this.label, required this.color, required this.background, super.key});
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999), border: Border.all(color: C.line)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(CupertinoIcons.circle_fill, color: color, size: 8), const SizedBox(width: 6), Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w900))]),
      );
}

class SelectedBedHero extends StatelessWidget {
  const SelectedBedHero({required this.bed, required this.crops, required this.sprayCount, required this.feedCount, required this.hold, required this.onAddCrop, required this.onSpray, required this.onFeed, super.key});
  final int bed;
  final List<VegetableDefinition> crops;
  final int sprayCount;
  final int feedCount;
  final bool hold;
  final VoidCallback onAddCrop;
  final VoidCallback onSpray;
  final VoidCallback onFeed;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(gradient: LinearGradient(colors: hold ? const [C.amber, Color(0xFF8D5B10)] : const [C.forest, C.forestDark], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(28), boxShadow: softShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 58, height: 58, alignment: Alignment.center, decoration: BoxDecoration(color: CupertinoColors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(20)), child: Text('$bed', style: const TextStyle(color: CupertinoColors.white, fontSize: 30, fontWeight: FontWeight.w900))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(hold ? 'Bed $bed is on hold' : 'Bed $bed is active', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CupertinoColors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(crops.isEmpty ? 'No crops assigned yet' : crops.map((crop) => crop.name).join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: CupertinoColors.white.withValues(alpha: .82), fontWeight: FontWeight.w700, fontSize: 13)),
              ])),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: WhiteMetric(label: 'Crops', value: '${crops.length}')),
              const SizedBox(width: 8),
              Expanded(child: WhiteMetric(label: 'Sprays', value: '$sprayCount')),
              const SizedBox(width: 8),
              Expanded(child: WhiteMetric(label: 'Feeds', value: '$feedCount')),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: PrimaryButton(label: 'Spray', icon: CupertinoIcons.drop, inverted: true, onPressed: onSpray)),
              const SizedBox(width: 10),
              Expanded(child: PrimaryButton(label: 'Feed', icon: CupertinoIcons.leaf_arrow_circlepath, inverted: true, onPressed: onFeed)),
            ]),
            const SizedBox(height: 10),
            SecondaryButton(label: 'Add crop to bed', onPressed: onAddCrop),
          ],
        ),
      );
}

class WhiteMetric extends StatelessWidget {
  const WhiteMetric({required this.label, required this.value, super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: CupertinoColors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(17), border: Border.all(color: CupertinoColors.white.withValues(alpha: .12))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(color: CupertinoColors.white, fontSize: 23, height: .95, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: CupertinoColors.white.withValues(alpha: .78), fontSize: 10.5, fontWeight: FontWeight.w800)),
        ]),
      );
}

class BedCropPanel extends StatelessWidget {
  const BedCropPanel({required this.bed, required this.crops, required this.onAddCrop, required this.onRemoveCrop, super.key});
  final int bed;
  final List<VegetableDefinition> crops;
  final VoidCallback onAddCrop;
  final ValueChanged<VegetableDefinition> onRemoveCrop;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: cardDecoration(radius: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: C.forestSoft, borderRadius: BorderRadius.circular(15)), child: const Icon(CupertinoIcons.leaf_arrow_circlepath, color: C.forest, size: 21)),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bed $bed crops', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: C.forest)),
              Text(crops.isEmpty ? 'Add crops so spray/feed logs know what is affected.' : '${crops.length} linked crop${crops.length == 1 ? '' : 's'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)),
            ])),
            CupertinoButton(padding: EdgeInsets.zero, minimumSize: Size.zero, onPressed: onAddCrop, child: const Text('+', style: TextStyle(color: C.forest, fontWeight: FontWeight.w900, fontSize: 28))),
          ]),
          const SizedBox(height: 12),
          if (crops.isEmpty) const EmptyInline('No crops assigned. Tap + to add what is growing here.') else Wrap(spacing: 8, runSpacing: 8, children: crops.map((crop) => CropChip(crop: crop, onRemove: () => onRemoveCrop(crop))).toList()),
        ]),
      );
}

class VisualBedActivityPanel extends StatelessWidget {
  const VisualBedActivityPanel({required this.bed, required this.sprayRecords, required this.feedRecords, super.key});
  final int bed;
  final List<SprayRecord> sprayRecords;
  final List<FeedRecord> feedRecords;

  @override
  Widget build(BuildContext context) {
    final items = <ActivityCard>[
      ...sprayRecords.take(4).map((r) => ActivityCard(icon: CupertinoIcons.drop, color: targetById(r.targetId).color, background: targetById(r.targetId).softColor, title: 'Spray · ${r.product}', detail: '${shortDate(r.date)} · safe ${shortDate(r.safeDate)}')),
      ...feedRecords.take(4).map((r) => ActivityCard(icon: CupertinoIcons.leaf_arrow_circlepath, color: C.purple, background: C.purpleSoft, title: 'Feed · ${r.product}', detail: '${shortDate(r.date)} · ${r.method}')),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(radius: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: C.purpleSoft, borderRadius: BorderRadius.circular(15)), child: const Icon(CupertinoIcons.clock, color: C.purple, size: 21)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bed $bed timeline', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: C.forest)),
            const Text('Sprays and feeds linked to this bed', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 12),
        if (items.isEmpty) const EmptyInline('No sprays or feeds linked to this bed yet.') else ...items.take(5),
      ]),
    );
  }
}

'@

$pattern = 'class GardenScreen extends StatelessWidget \{[\s\S]*?\r?\nclass GardenMap extends StatelessWidget \{'
if ($src -notmatch $pattern) { throw 'Could not find GardenScreen block to replace.' }
$src = [regex]::Replace($src, $pattern, $newGardenBlock + 'class GardenMap extends StatelessWidget {', 1)

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
foreach ($marker in @('GardenOverviewStrip', 'SelectedBedHero', 'BedCropPanel', 'VisualBedActivityPanel', 'GardenMapLegend', 'Tap a bed')) {
  if ($check -notmatch [regex]::Escape($marker)) { throw "Missing garden UI marker: $marker" }
}

Write-Host 'Applied improved Garden tab UI.'
Write-Host 'Verified markers: GardenOverviewStrip, SelectedBedHero, BedCropPanel, VisualBedActivityPanel.'
Write-Host 'Next: flutter analyze; flutter run'
