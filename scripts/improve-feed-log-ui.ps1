$ErrorActionPreference = 'Stop'

$mainPath = Join-Path $PSScriptRoot '..\lib\main.dart'
if (-not (Test-Path $mainPath)) { throw 'Could not find lib/main.dart' }
$src = Get-Content $mainPath -Raw

# Wire Feed Log to bed crop data so the feed bed selector can show crop context.
$src = $src.Replace(
  'FeedLogScreen(initialBeds: {selectedBed}, onSave: saveFeed)',
  'FeedLogScreen(initialBeds: {selectedBed}, bedCrops: bedCrops, onSave: saveFeed)'
)

$newFeedBlock = @'
class FeedLogScreen extends StatefulWidget {
  const FeedLogScreen({required this.initialBeds, required this.bedCrops, required this.onSave, super.key});
  final Set<int> initialBeds;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final void Function({required Set<int> beds, required FeedProductPreset preset, required String note}) onSave;

  @override
  State<FeedLogScreen> createState() => _FeedLogScreenState();
}

class _FeedLogScreenState extends State<FeedLogScreen> {
  late Set<int> beds = {...widget.initialBeds};
  var preset = feedProductPresets.first;
  final note = TextEditingController();

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  List<VegetableDefinition> selectedCrops() => beds.expand((bed) => widget.bedCrops[bed] ?? const <VegetableDefinition>[]).toSet().toList();

  @override
  Widget build(BuildContext context) {
    final crops = selectedCrops();
    return AppPage(
      title: 'Feed Log',
      subtitle: 'Visual feed review: beds, crops, feed product, timing and notes.',
      children: [
        FeedReviewHero(beds: beds, crops: crops, preset: preset),
        const SizedBox(height: 14),
        FeedBedSelector(
          selectedBeds: beds,
          bedCrops: widget.bedCrops,
          onToggle: (bed) => setState(() => beds.contains(bed) ? beds.remove(bed) : beds.add(bed)),
          onClear: () => setState(() => beds.clear()),
          onSelectPlanted: () => setState(() => beds = widget.bedCrops.keys.toSet()),
        ),
        const SizedBox(height: 14),
        FeedProductSelector(
          selected: preset,
          onSelect: (next) => setState(() => preset = next),
        ),
        const SizedBox(height: 14),
        FeedSavePanel(
          beds: beds,
          crops: crops,
          preset: preset,
          note: note,
          onSave: beds.isEmpty ? null : () => widget.onSave(beds: beds, preset: preset, note: note.text),
        ),
      ],
    );
  }
}

class FeedReviewHero extends StatelessWidget {
  const FeedReviewHero({required this.beds, required this.crops, required this.preset, super.key});
  final Set<int> beds;
  final List<VegetableDefinition> crops;
  final FeedProductPreset preset;

  @override
  Widget build(BuildContext context) {
    final sortedBeds = beds.toList()..sort();
    final bedText = sortedBeds.isEmpty ? 'No beds selected' : sortedBeds.map((bed) => 'Bed $bed').join(', ');
    final cropText = crops.isEmpty ? 'Whole bed / no crops assigned' : crops.take(5).map((crop) => crop.name).join(' · ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: preset.background, borderRadius: BorderRadius.circular(26), border: Border.all(color: C.line), boxShadow: softShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 50, height: 50, alignment: Alignment.center, decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(18)), child: Icon(CupertinoIcons.leaf_arrow_circlepath, color: preset.color, size: 26)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Feed review', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: C.forest)),
                Text(preset.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: preset.color)),
                const SizedBox(height: 3),
                Text('${preset.method} · every ${preset.intervalDays} days', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.ink, fontWeight: FontWeight.w800, fontSize: 12)),
              ])),
            ],
          ),
          const SizedBox(height: 14),
          FeedProgressStrip(items: [
            FeedProgressItem(icon: CupertinoIcons.square_grid_2x2, label: 'Beds', done: beds.isNotEmpty),
            FeedProgressItem(icon: CupertinoIcons.leaf_arrow_circlepath, label: 'Crops', done: crops.isNotEmpty),
            FeedProgressItem(icon: CupertinoIcons.cube_box, label: 'Feed', done: preset.name.isNotEmpty),
            FeedProgressItem(icon: CupertinoIcons.pencil, label: 'Notes', done: true),
            FeedProgressItem(icon: CupertinoIcons.check_mark_circled, label: 'Save', done: beds.isNotEmpty),
          ]),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ReviewChip(icon: CupertinoIcons.square_grid_2x2, label: 'Beds fed', value: bedText, color: C.forest, background: C.forestSoft),
              ReviewChip(icon: CupertinoIcons.leaf_arrow_circlepath, label: 'Crops linked', value: cropText, color: C.forest, background: C.forestSoft),
              ReviewChip(icon: CupertinoIcons.timer, label: 'Repeat guide', value: '${preset.intervalDays} days', color: preset.color, background: preset.background),
            ],
          ),
        ],
      ),
    );
  }
}

class FeedProgressItem {
  const FeedProgressItem({required this.icon, required this.label, required this.done});
  final IconData icon;
  final String label;
  final bool done;
}

class FeedProgressStrip extends StatelessWidget {
  const FeedProgressStrip({required this.items, super.key});
  final List<FeedProgressItem> items;

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

class FeedBedSelector extends StatelessWidget {
  const FeedBedSelector({required this.selectedBeds, required this.bedCrops, required this.onToggle, required this.onClear, required this.onSelectPlanted, super.key});
  final Set<int> selectedBeds;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final ValueChanged<int> onToggle;
  final VoidCallback onClear;
  final VoidCallback onSelectPlanted;

  @override
  Widget build(BuildContext context) {
    final selectedList = selectedBeds.toList()..sort();
    final label = selectedList.isEmpty ? 'No beds selected' : 'Selected: ${selectedList.map((bed) => 'Bed $bed').join(', ')}';
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
                const Text('Beds fed', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: C.forest)),
                Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)),
              ])),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: SecondaryButton(label: 'Planted beds', onPressed: onSelectPlanted)),
            const SizedBox(width: 10),
            Expanded(child: DangerButton(label: 'Clear beds', onPressed: selectedBeds.isEmpty ? null : onClear)),
          ]),
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
                  child: FeedBedCard(bed: bed.number, selected: selectedBeds.contains(bed.number), crops: crops, onTap: () => onToggle(bed.number)),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class FeedBedCard extends StatelessWidget {
  const FeedBedCard({required this.bed, required this.selected, required this.crops, required this.onTap, super.key});
  final int bed;
  final bool selected;
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
          decoration: BoxDecoration(color: selected ? C.forest : crops.isEmpty ? C.card : C.forestSoft, borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? C.forest : C.line, width: selected ? 2 : 1), boxShadow: selected ? softShadow : null),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(child: Text('Bed', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? CupertinoColors.white.withValues(alpha: .82) : C.muted, fontSize: 10, fontWeight: FontWeight.w900))),
              Icon(selected ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle, size: 16, color: selected ? CupertinoColors.white : C.muted),
            ]),
            const SizedBox(height: 3),
            Text('$bed', style: TextStyle(color: selected ? CupertinoColors.white : C.forest, fontSize: 25, height: 1, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(color: selected ? CupertinoColors.white.withValues(alpha: .16) : C.card, borderRadius: BorderRadius.circular(999), border: Border.all(color: selected ? CupertinoColors.white.withValues(alpha: .20) : C.line)),
              child: Text(crops.isEmpty ? 'Empty' : '${crops.length} crop${crops.length == 1 ? '' : 's'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? CupertinoColors.white : C.ink, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
            if (crops.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(crops.take(2).map((crop) => crop.name).join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? CupertinoColors.white.withValues(alpha: .82) : C.muted, fontSize: 10, fontWeight: FontWeight.w700)),
            ],
          ]),
        ),
      );
}

class FeedProductSelector extends StatelessWidget {
  const FeedProductSelector({required this.selected, required this.onSelect, super.key});
  final FeedProductPreset selected;
  final ValueChanged<FeedProductPreset> onSelect;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: cardDecoration(radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Feed used'),
            const SizedBox(height: 4),
            const Text('Choose what was used. This links to the bed feed history after saving.', style: TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 12),
            ...feedProductPresets.map((preset) => FeedProductCard(preset: preset, selected: selected.name == preset.name, onTap: () => onSelect(preset))),
          ],
        ),
      );
}

class FeedProductCard extends StatelessWidget {
  const FeedProductCard({required this.preset, required this.selected, required this.onTap, super.key});
  final FeedProductPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: selected ? preset.background : C.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? preset.color : C.line, width: selected ? 2 : 1), boxShadow: selected ? softShadow : null),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: selected ? preset.color : preset.background, borderRadius: BorderRadius.circular(15)), child: Icon(CupertinoIcons.cube_box, color: selected ? CupertinoColors.white : preset.color, size: 21)),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(preset.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: C.ink)),
              const SizedBox(height: 3),
              Text('${preset.method} · every ${preset.intervalDays} days', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(preset.note, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.2)),
            ])),
            const SizedBox(width: 8),
            Icon(selected ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle, color: selected ? preset.color : C.muted, size: 23),
          ]),
        ),
      );
}

class FeedSavePanel extends StatelessWidget {
  const FeedSavePanel({required this.beds, required this.crops, required this.preset, required this.note, required this.onSave, super.key});
  final Set<int> beds;
  final List<VegetableDefinition> crops;
  final FeedProductPreset preset;
  final TextEditingController note;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final sortedBeds = beds.toList()..sort();
    final bedText = sortedBeds.isEmpty ? 'No beds selected' : sortedBeds.map((bed) => 'Bed $bed').join(', ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: preset.background, borderRadius: BorderRadius.circular(15)), child: Icon(CupertinoIcons.check_mark_circled, color: preset.color, size: 22)),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Save feed record', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: C.forest)),
              Text('$bedText · ${preset.name}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700, fontSize: 12)),
            ])),
          ]),
          const SizedBox(height: 12),
          Field(controller: note, placeholder: 'Notes optional, e.g. light feed after rain', maxLines: 3),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: preset.background, borderRadius: BorderRadius.circular(17), border: Border.all(color: C.line)),
            child: Text('Next guide: review again in about ${preset.intervalDays} days. Bed history will show this feed after saving.', maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: preset.color, fontWeight: FontWeight.w900, fontSize: 12, height: 1.25)),
          ),
          const SizedBox(height: 12),
          PrimaryButton(label: beds.isEmpty ? 'Select beds first' : 'Save feed record', onPressed: onSave),
        ],
      ),
    );
  }
}

'@

$pattern = 'class FeedLogScreen extends StatefulWidget \{[\s\S]*?\r?\nclass ProductsScreen extends StatelessWidget \{'
if ($src -notmatch $pattern) { throw 'Could not find FeedLogScreen block to replace.' }
$src = [regex]::Replace($src, $pattern, $newFeedBlock + "`r`nclass ProductsScreen extends StatelessWidget {", 1)

Set-Content -Path $mainPath -Value $src -NoNewline

$check = Get-Content $mainPath -Raw
foreach ($marker in @('FeedReviewHero', 'FeedBedSelector', 'FeedProductSelector', 'FeedSavePanel', 'Visual feed review', 'Next guide')) {
  if ($check -notmatch [regex]::Escape($marker)) { throw "Missing feed UI marker: $marker" }
}

Write-Host 'Applied improved Feed Log UI.'
Write-Host 'Verified markers: FeedReviewHero, FeedBedSelector, FeedProductSelector, FeedSavePanel.'
Write-Host 'Next: flutter analyze; flutter run'
