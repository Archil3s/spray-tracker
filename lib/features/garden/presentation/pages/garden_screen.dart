part of '../../../../main.dart';

class GardenScreen extends StatefulWidget {
  const GardenScreen({
    required this.selectedBed,
    required this.plot,
    required this.gardenBeds,
    required this.bedCrops,
    required this.bedPlants,
    required this.records,
    required this.products,
    required this.gardenRisks,
    required this.isHold,
    required this.message,
    required this.onSelectBed,
    required this.onAddCrop,
    required this.onRemoveCrop,
    required this.onAddPlant,
    required this.onAddPlants,
    required this.onRemovePlant,
    required this.onAddBed,
    required this.onRenameBed,
    required this.onMoveBed,
    required this.onResizeBed,
    required this.onSizeBed,
    required this.onRotateBed,
    required this.onDuplicateBed,
    required this.onSizePlot,
    required this.onRemoveBed,
    required this.onResetLayout,
    required this.onStartSpray,
    super.key,
  });

  final int selectedBed;
  final GardenPlot plot;
  final List<GardenBed> gardenBeds;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final Map<int, List<GardenPlant>> bedPlants;
  final List<SprayRecord> records;
  final List<SprayProduct> products;
  final Future<GardenRiskSummary> gardenRisks;
  final bool Function(int bed) isHold;
  final String message;
  final ValueChanged<int> onSelectBed;
  final void Function(int bed, VegetableDefinition crop) onAddCrop;
  final void Function(int bed, VegetableDefinition crop) onRemoveCrop;
  final GardenPlant Function(
    int bed,
    VegetableDefinition crop,
    Offset position,
  ) onAddPlant;
  final List<GardenPlant> Function(
    int bed,
    VegetableDefinition crop,
    List<Offset> positions,
  ) onAddPlants;
  final void Function(int bed, int plantId) onRemovePlant;
  final VoidCallback onAddBed;
  final void Function(int bed, String name) onRenameBed;
  final void Function(int bed, Offset delta) onMoveBed;
  final void Function(int bed, Offset delta) onResizeBed;
  final void Function(int bed, double widthMeters, double lengthMeters)
      onSizeBed;
  final ValueChanged<int> onRotateBed;
  final ValueChanged<int> onDuplicateBed;
  final void Function(double widthMeters, double lengthMeters) onSizePlot;
  final ValueChanged<int> onRemoveBed;
  final VoidCallback onResetLayout;
  final VoidCallback onStartSpray;

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  bool outlineMode = false;

  @override
  Widget build(BuildContext context) {
    final bed = widget.gardenBeds.firstWhere(
      (item) => item.number == widget.selectedBed,
      orElse: () => widget.gardenBeds.first,
    );
    final crops = widget.bedCrops[bed.number] ?? const <VegetableDefinition>[];
    return AppPage(
      title: 'Garden',
      subtitle: 'Log bed crops, spray holds, feeding, and rotation actions.',
      message: widget.message,
      children: [
        GardenRiskPanel(gardenRisks: widget.gardenRisks),
        const SizedBox(height: 14),
        _GardenOutlinePanel(
          open: outlineMode,
          selectedBed: bed,
          plot: widget.plot,
          gardenBeds: widget.gardenBeds,
          bedCrops: widget.bedCrops,
          records: widget.records,
          isHold: widget.isHold,
          onToggle: () => setState(() => outlineMode = !outlineMode),
          onSelectBed: widget.onSelectBed,
          onAddBed: widget.onAddBed,
          onRenameBed: (targetBed) => showBedNameEditor(
            context,
            targetBed,
            (name) => widget.onRenameBed(targetBed.number, name),
          ),
          onMoveBed: widget.onMoveBed,
          onSizeBed: (targetBed) => showBedSizeEditor(
            context,
            targetBed,
            widget.plot,
            (width, length) => widget.onSizeBed(
              targetBed.number,
              width,
              length,
            ),
          ),
          onRotateBed: widget.onRotateBed,
          onDuplicateBed: widget.onDuplicateBed,
          onSizePlot: () => showGardenPlotEditor(
            context,
            widget.plot,
            widget.gardenBeds,
            widget.onSizePlot,
          ),
          onRemoveBed: widget.onRemoveBed,
          onResetLayout: widget.onResetLayout,
        ),
        const SizedBox(height: 14),
        _GardenBedSelector(
          beds: widget.gardenBeds,
          selectedBed: bed.number,
          bedCrops: widget.bedCrops,
          records: widget.records,
          onSelectBed: widget.onSelectBed,
        ),
        const SizedBox(height: 14),
        _GardenBedCropPanel(
          bed: bed,
          crops: crops,
          records: widget.records,
          products: widget.products,
          gardenRisks: widget.gardenRisks,
          spraySummary: bedSpraySummary(widget.records, bed.number),
          onAddCrop: () => showVegetableLogger(
            context,
            bed,
            crops,
            (crop) => widget.onAddCrop(bed.number, crop),
            (crop) => widget.onRemoveCrop(bed.number, crop),
          ),
          onOpenPlanner: () => showCropPlanner(
            context,
            bed,
            crops,
            widget.bedPlants[bed.number] ?? const <GardenPlant>[],
            widget.onAddPlant,
            widget.onAddPlants,
            widget.onRemovePlant,
          ),
          onRemoveCrop: (crop) => widget.onRemoveCrop(bed.number, crop),
          onStartSpray: widget.onStartSpray,
        ),
        if (crops.isNotEmpty) ...[
          const SizedBox(height: 14),
          const SectionTitle('OpenFarm growing data'),
          const SizedBox(height: 8),
          ...crops.take(2).map(
                (crop) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OpenFarmCropInfoSection(cropName: crop.name),
                ),
              ),
        ],
      ],
    );
  }
}

class _GardenOutlinePanel extends StatelessWidget {
  const _GardenOutlinePanel({
    required this.open,
    required this.selectedBed,
    required this.plot,
    required this.gardenBeds,
    required this.bedCrops,
    required this.records,
    required this.isHold,
    required this.onToggle,
    required this.onSelectBed,
    required this.onAddBed,
    required this.onRenameBed,
    required this.onMoveBed,
    required this.onSizeBed,
    required this.onRotateBed,
    required this.onDuplicateBed,
    required this.onSizePlot,
    required this.onRemoveBed,
    required this.onResetLayout,
  });

  final bool open;
  final GardenBed selectedBed;
  final GardenPlot plot;
  final List<GardenBed> gardenBeds;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final List<SprayRecord> records;
  final bool Function(int bed) isHold;
  final VoidCallback onToggle;
  final ValueChanged<int> onSelectBed;
  final VoidCallback onAddBed;
  final ValueChanged<GardenBed> onRenameBed;
  final void Function(int bed, Offset delta) onMoveBed;
  final ValueChanged<GardenBed> onSizeBed;
  final ValueChanged<int> onRotateBed;
  final ValueChanged<int> onDuplicateBed;
  final VoidCallback onSizePlot;
  final ValueChanged<int> onRemoveBed;
  final VoidCallback onResetLayout;

  @override
  Widget build(BuildContext context) => Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: SectionTitle('Garden outline'),
                ),
                CupertinoSwitch(
                  value: open,
                  activeTrackColor: C.forest,
                  onChanged: (_) => onToggle(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              open
                  ? 'Drag beds to match the real garden. Use size controls for true metre dimensions.'
                  : '${plot.sizeLabel} plot | ${gardenBeds.length} beds mapped',
              style: const TextStyle(
                color: C.muted,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (open) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ProductTag(
                      label: 'Plot ${plot.sizeLabel}',
                      color: C.forest,
                      background: C.forestSoft,
                    ),
                  ),
                  _GardenIconButton(
                    label: 'Edit plot size',
                    icon: CupertinoIcons.square_grid_2x2,
                    onPressed: onSizePlot,
                  ),
                  const SizedBox(width: 8),
                  _GardenIconButton(
                    label: 'Add bed',
                    icon: CupertinoIcons.add_circled,
                    onPressed: onAddBed,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GardenMapFrame(
                height: 430,
                child: GardenMap(
                  selectedBed: selectedBed.number,
                  plot: plot,
                  gardenBeds: gardenBeds,
                  bedCrops: bedCrops,
                  records: records,
                  isHold: isHold,
                  designing: true,
                  onTap: onSelectBed,
                  onMove: onMoveBed,
                ),
              ),
              const SizedBox(height: 12),
              _SelectedBedOutlineTools(
                bed: selectedBed,
                canRemove: gardenBeds.length > 1,
                onRename: () => onRenameBed(selectedBed),
                onSize: () => onSizeBed(selectedBed),
                onRotate: () => onRotateBed(selectedBed.number),
                onDuplicate: () => onDuplicateBed(selectedBed.number),
                onRemove: () => onRemoveBed(selectedBed.number),
                onReset: onResetLayout,
              ),
            ],
          ],
        ),
      );
}

class _SelectedBedOutlineTools extends StatelessWidget {
  const _SelectedBedOutlineTools({
    required this.bed,
    required this.canRemove,
    required this.onRename,
    required this.onSize,
    required this.onRotate,
    required this.onDuplicate,
    required this.onRemove,
    required this.onReset,
  });

  final GardenBed bed;
  final bool canRemove;
  final VoidCallback onRename;
  final VoidCallback onSize;
  final VoidCallback onRotate;
  final VoidCallback onDuplicate;
  final VoidCallback onRemove;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${bed.label} | ${bed.sizeLabel}',
            style: const TextStyle(
              color: C.forest,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _GardenToolButton(
                label: 'Name',
                icon: CupertinoIcons.square_pencil,
                onPressed: onRename,
              ),
              _GardenToolButton(
                label: 'Size',
                icon: CupertinoIcons.square_grid_2x2,
                onPressed: onSize,
              ),
              _GardenToolButton(
                label: 'Rotate',
                icon: CupertinoIcons.arrow_2_circlepath,
                onPressed: onRotate,
              ),
              _GardenToolButton(
                label: 'Copy',
                icon: CupertinoIcons.add_circled,
                onPressed: onDuplicate,
              ),
              _GardenToolButton(
                label: 'Delete',
                icon: CupertinoIcons.delete,
                onPressed: canRemove ? onRemove : null,
                danger: true,
              ),
              _GardenToolButton(
                label: 'Reset',
                icon: CupertinoIcons.clear,
                onPressed: onReset,
              ),
            ],
          ),
        ],
      );
}

class _GardenToolButton extends StatelessWidget {
  const _GardenToolButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        minimumSize: Size.zero,
        color: C.card,
        disabledColor: C.greySoft,
        borderRadius: BorderRadius.circular(12),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: onPressed == null
                  ? C.muted
                  : danger
                      ? C.red
                      : C.forest,
              size: 16,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: onPressed == null
                    ? C.muted
                    : danger
                        ? C.red
                        : C.forest,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
}
