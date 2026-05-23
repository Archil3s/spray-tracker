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
