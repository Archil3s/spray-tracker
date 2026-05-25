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
    required this.onOpenRecord,
    required this.onOpenPestProfiles,
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
  final ValueChanged<SprayRecord> onOpenRecord;
  final VoidCallback onOpenPestProfiles;
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
  @override
  Widget build(BuildContext context) {
    final bed = widget.gardenBeds.firstWhere(
      (item) => item.number == widget.selectedBed,
      orElse: () => widget.gardenBeds.first,
    );
    final crops = widget.bedCrops[bed.number] ?? const <VegetableDefinition>[];
    final plants = widget.bedPlants[bed.number] ?? const <GardenPlant>[];
    void openVegetableLogger() => showVegetableLogger(
          context,
          bed,
          crops,
          (crop) => widget.onAddCrop(bed.number, crop),
          (crop) => _removeCropAndPlants(bed.number, crop),
        );

    return AppPage(
      title: 'Garden',
      subtitle: 'Seasonal planting, bed crops, sprays, feeding, and rotation.',
      message: widget.message,
      children: [
        _GardenBedCropPanel(
          bed: bed,
          crops: crops,
          plants: plants,
          records: widget.records,
          products: widget.products,
          gardenRisks: widget.gardenRisks,
          spraySummary: bedSpraySummary(widget.records, bed.number),
          onAddCrop: openVegetableLogger,
          onRemoveCrop: (crop) => _removeCropAndPlants(bed.number, crop),
          onSetPlantCount: (crop, count) =>
              _setPlantCount(bed.number, crop, count),
          onOpenRecord: widget.onOpenRecord,
          onStartSpray: widget.onStartSpray,
        ),
        const SizedBox(height: 14),
        const SectionTitle('Switch bed'),
        const SizedBox(height: 8),
        _GardenBedSelector(
          beds: widget.gardenBeds,
          selectedBed: bed.number,
          bedCrops: widget.bedCrops,
          bedPlants: widget.bedPlants,
          records: widget.records,
          onSelectBed: widget.onSelectBed,
          onOpenRecord: widget.onOpenRecord,
        ),
        const SizedBox(height: 14),
        GardenRiskPanel(
          gardenRisks: widget.gardenRisks,
          onPestPressureTap: widget.onOpenPestProfiles,
        ),
        const SizedBox(height: 14),
        GardenOutlinePanel(
          selectedBed: bed.number,
          plot: widget.plot,
          gardenBeds: widget.gardenBeds,
          bedCrops: widget.bedCrops,
          bedPlants: widget.bedPlants,
          records: widget.records,
          isHold: widget.isHold,
          onSelectBed: widget.onSelectBed,
        ),
        const SizedBox(height: 14),
        SeasonalPlantingGuidePanel(
          selectedBed: bed,
          selectedCrops: crops,
          onLogVegetables: openVegetableLogger,
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

  void _removeCropAndPlants(int bed, VegetableDefinition crop) {
    final plants = widget.bedPlants[bed] ?? const <GardenPlant>[];
    final matching = plants
        .where((plant) => plant.crop.id == crop.id)
        .toList(growable: false);
    for (final plant in matching) {
      widget.onRemovePlant(bed, plant.id);
    }
    widget.onRemoveCrop(bed, crop);
  }

  void _setPlantCount(int bed, VegetableDefinition crop, int count) {
    final target = count.clamp(0, 999).toInt();
    final bedPlants = widget.bedPlants[bed] ?? const <GardenPlant>[];
    final matching = bedPlants
        .where((plant) => plant.crop.id == crop.id)
        .toList(growable: false);
    if (target == matching.length) return;

    if (target > matching.length) {
      final addCount = target - matching.length;
      final positions = List<Offset>.generate(
        addCount,
        (index) => defaultPlantPosition(bedPlants.length + index),
      );
      widget.onAddPlants(bed, crop, positions);
      return;
    }

    final removeCount = matching.length - target;
    for (final plant in matching.reversed.take(removeCount)) {
      widget.onRemovePlant(bed, plant.id);
    }
  }
}
