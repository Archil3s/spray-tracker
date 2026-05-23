part of '../../../../main.dart';

void showCropPlanner(
  BuildContext context,
  GardenBed bed,
  List<VegetableDefinition> assigned,
  List<GardenPlant> plants,
  GardenPlant Function(
    int bed,
    VegetableDefinition crop,
    Offset position,
  ) onAdd,
  List<GardenPlant> Function(
    int bed,
    VegetableDefinition crop,
    List<Offset> positions,
  ) onAddMany,
  void Function(int bed, int plantId) onRemove,
) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => _BedCropPlannerSheet(
      bed: bed,
      assigned: assigned,
      plants: plants,
      onAdd: onAdd,
      onAddMany: onAddMany,
      onRemove: onRemove,
    ),
  );
}

class _BedCropPlannerSheet extends StatefulWidget {
  const _BedCropPlannerSheet({
    required this.bed,
    required this.assigned,
    required this.plants,
    required this.onAdd,
    required this.onAddMany,
    required this.onRemove,
  });

  final GardenBed bed;
  final List<VegetableDefinition> assigned;
  final List<GardenPlant> plants;
  final GardenPlant Function(
    int bed,
    VegetableDefinition crop,
    Offset position,
  ) onAdd;
  final List<GardenPlant> Function(
    int bed,
    VegetableDefinition crop,
    List<Offset> positions,
  ) onAddMany;
  final void Function(int bed, int plantId) onRemove;

  @override
  State<_BedCropPlannerSheet> createState() => _BedCropPlannerSheetState();
}

class _BedCropPlannerSheetState extends State<_BedCropPlannerSheet> {
  final search = TextEditingController();
  final plannerScroll = ScrollController();
  final Map<String, CropSpacing> cropSpacings = {};
  final Map<String, Future<CropSpacing>> cropSpacingLookups = {};
  late List<GardenPlant> plants = [...widget.plants];
  late VegetableDefinition selectedCrop =
      widget.assigned.isEmpty ? vegetableLibrary.first : widget.assigned.first;
  late CropSpacing spacing = cropSpacingFor(selectedCrop);
  Offset? rowPaintStart;
  List<Offset> rowPreview = const [];
  bool rowPaintCancelled = false;
  AutoBedFoodStyle generatorStyle = AutoBedFoodStyle.balanced;
  AutoBedPlanResult? lastAutoPlan;
  bool spacingLoading = false;
  bool erasing = false;
  String familyId = 'all';

  @override
  void initState() {
    super.initState();
    _preloadBedSpacings();
    _loadSpacing(selectedCrop);
  }

  @override
  void dispose() {
    search.dispose();
    plannerScroll.dispose();
    super.dispose();
  }

  List<VegetableDefinition> get crops {
    final query = search.text.trim().toLowerCase();
    return vegetableLibrary.where((crop) {
      final family = familyById(crop.familyId);
      final matchesFamily = familyId == 'all' || crop.familyId == familyId;
      final matchesQuery = query.isEmpty ||
          crop.name.toLowerCase().contains(query) ||
          family.name.toLowerCase().contains(query);
      return matchesFamily && matchesQuery;
    }).toList(growable: false);
  }

  int _plantCount(VegetableDefinition crop) =>
      plants.where((plant) => plant.crop.id == crop.id).length;

  List<Offset> get grid => plantingGridPositions(widget.bed, spacing);

  CropSpacing _knownSpacing(VegetableDefinition crop) =>
      cropSpacings[crop.id] ?? cropSpacingFor(crop);

  void _preloadBedSpacings() {
    final cropsById = {
      for (final crop in widget.assigned) crop.id: crop,
      for (final plant in plants) plant.crop.id: plant.crop,
      for (final item in companionAwareAutoBedCropMix(generatorStyle))
        item.cropId: vegetableLibrary.firstWhere(
          (crop) => crop.id == item.cropId,
          orElse: () => vegetableLibrary.first,
        ),
    };
    for (final crop in cropsById.values) {
      unawaited(_lookupSpacing(crop));
    }
  }

  Future<CropSpacing> _lookupSpacing(VegetableDefinition crop) =>
      cropSpacingLookups.putIfAbsent(crop.id, () async {
        final profile = await OpenFarmService.instance.getCropByName(crop.name);
        final resolved = cropSpacingFor(crop, profile);
        if (!mounted) return resolved;
        setState(() {
          cropSpacings[crop.id] = resolved;
        });
        return resolved;
      });

  Future<void> _loadSpacing(VegetableDefinition crop) async {
    setState(() {
      spacing = _knownSpacing(crop);
      spacingLoading = true;
    });
    final resolved = await _lookupSpacing(crop);
    if (!mounted || selectedCrop.id != crop.id) return;
    setState(() {
      spacing = resolved;
      spacingLoading = false;
    });
  }

  void _place(Offset position) {
    if (erasing || spacingLoading) return;
    final openSpot = nearestOpenPlantSpot(
      widget.bed,
      position,
      grid,
      spacing,
      plants,
      (plant) => _knownSpacing(plant.crop),
    );
    if (openSpot == null) return;
    final plant = widget.onAdd(widget.bed.number, selectedCrop, openSpot);
    setState(() {
      plants = [...plants, plant];
    });
  }

  void _startRowPaint(Offset position) {
    if (erasing || spacingLoading) return;
    rowPaintStart = position;
    rowPaintCancelled = false;
    _updateRowPreview(position);
  }

  void _updateRowPreview(Offset position) {
    final start = rowPaintStart;
    if (start == null || erasing || spacingLoading || rowPaintCancelled) return;
    setState(() {
      rowPreview = rowPlantPreviewSpots(
        widget.bed,
        grid,
        start,
        position,
        spacing,
        plants,
        (plant) => _knownSpacing(plant.crop),
      );
    });
  }

  void _cancelRowPaint() {
    if (rowPaintStart == null && rowPreview.isEmpty && !rowPaintCancelled) {
      return;
    }
    setState(() {
      rowPaintStart = null;
      rowPreview = const [];
      rowPaintCancelled = true;
    });
  }

  void _commitRowPaint() {
    if (rowPaintCancelled || rowPreview.isEmpty) {
      _cancelRowPaint();
      return;
    }
    final positions = [...rowPreview];
    final added = widget.onAddMany(widget.bed.number, selectedCrop, positions);
    setState(() {
      plants = [...plants, ...added];
      rowPaintStart = null;
      rowPreview = const [];
      rowPaintCancelled = false;
    });
  }

  void _erase(GardenPlant plant) {
    if (!erasing) return;
    setState(() {
      plants = plants.where((item) => item.id != plant.id).toList();
    });
    widget.onRemove(widget.bed.number, plant.id);
  }

  void _selectCrop(VegetableDefinition crop, {bool returnToBed = false}) {
    setState(() {
      selectedCrop = crop;
      erasing = false;
      rowPaintStart = null;
      rowPreview = const [];
      rowPaintCancelled = false;
    });
    _loadSpacing(crop);
    if (!returnToBed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !plannerScroll.hasClients) return;
      plannerScroll.animateTo(
        0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _fillGrid() {
    if (erasing || spacingLoading) return;
    final positions = openPlantGridSpots(
      widget.bed,
      grid,
      spacing,
      plants,
      (plant) => _knownSpacing(plant.crop),
    );
    if (positions.isEmpty) return;
    final added = widget.onAddMany(widget.bed.number, selectedCrop, positions);
    setState(() {
      plants = [...plants, ...added];
    });
  }

  void _clearBed() {
    if (plants.isEmpty) return;
    final removedPlants = [...plants];
    setState(() {
      plants = const [];
      lastAutoPlan = null;
      rowPaintStart = null;
      rowPreview = const [];
      rowPaintCancelled = false;
    });
    for (final plant in removedPlants) {
      widget.onRemove(widget.bed.number, plant.id);
    }
  }

  void _selectGeneratorStyle(AutoBedFoodStyle style) {
    setState(() {
      generatorStyle = style;
      lastAutoPlan = null;
    });
    for (final item in companionAwareAutoBedCropMix(style)) {
      final crop = vegetableLibrary.firstWhere(
        (crop) => crop.id == item.cropId,
        orElse: () => vegetableLibrary.first,
      );
      unawaited(_lookupSpacing(crop));
    }
  }

  void _generateAutoBed() {
    if (erasing || spacingLoading) return;
    final replacedPlants = [...plants];
    final plan = generateAutoBedPlan(
      bed: widget.bed,
      style: generatorStyle,
      existingPlants: const <GardenPlant>[],
      spacingForCrop: _knownSpacing,
      spacingForPlant: (plant) => _knownSpacing(plant.crop),
    );
    if (plan.totalPlants == 0) {
      setState(() => lastAutoPlan = plan);
      return;
    }

    for (final plant in replacedPlants) {
      widget.onRemove(widget.bed.number, plant.id);
    }
    final added = <GardenPlant>[];
    for (final entry in plan.placements.entries) {
      added.addAll(
        widget.onAddMany(widget.bed.number, entry.key, entry.value),
      );
    }
    setState(() {
      plants = added;
      selectedCrop = plan.crops.first;
      spacing = _knownSpacing(selectedCrop);
      lastAutoPlan = plan;
      erasing = false;
      rowPaintStart = null;
      rowPreview = const [];
      rowPaintCancelled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = crops;
    final season = gardenSeasonForDate(DateTime.now());
    final openSpots = openPlantGridSpots(
      widget.bed,
      grid,
      spacing,
      plants,
      (plant) => _knownSpacing(plant.crop),
    ).length;
    return Sheet(
      child: ListView(
        controller: plannerScroll,
        padding: const EdgeInsets.all(20),
        children: [
          SheetHeader(title: 'Plant bed', subtitle: widget.bed.label),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  'Spacing planner',
                  trailing: ProductTag(
                    label: widget.bed.sizeLabel,
                    color: C.forest,
                    background: C.forestSoft,
                  ),
                ),
                const SizedBox(height: 10),
                _PlannerToolStrip(
                  erasing: erasing,
                  loading: spacingLoading,
                  canClear: plants.isNotEmpty,
                  onPaint: () => setState(() => erasing = false),
                  onRow: () => setState(() => erasing = false),
                  onFill: _fillGrid,
                  onErase: () => setState(() => erasing = true),
                  onClear: _clearBed,
                ),
                const SizedBox(height: 12),
                _PlannerStatsPanel(
                  bed: widget.bed,
                  plants: plants,
                  openSpots: openSpots,
                ),
                const SizedBox(height: 10),
                _CropSpacingBanner(
                  crop: selectedCrop,
                  spacing: spacing,
                  count: _plantCount(selectedCrop),
                  loading: spacingLoading,
                ),
                const SizedBox(height: 10),
                _BedPlantingCanvas(
                  bed: widget.bed,
                  crops: widget.assigned,
                  plants: plants,
                  gridPositions: grid,
                  previewPositions: rowPreview,
                  previewCrop: selectedCrop,
                  previewSpacing: spacing,
                  height: 286,
                  erasing: erasing,
                  spacingForPlant: (plant) => _knownSpacing(plant.crop),
                  onPlace: spacingLoading ? null : _place,
                  onPlantTap: erasing ? _erase : null,
                  onPaintStart:
                      erasing || spacingLoading ? null : _startRowPaint,
                  onPaintUpdate:
                      erasing || spacingLoading ? null : _updateRowPreview,
                  onPaintEnd:
                      erasing || spacingLoading ? null : _commitRowPaint,
                  onPaintCancel: _cancelRowPaint,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  'Auto design',
                  trailing: ProductTag(
                    label: '${season.label} Blenheim',
                    color: C.forest,
                    background: C.forestSoft,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final style in AutoBedFoodStyle.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _AutoBedStyleButton(
                            style: style,
                            selected: generatorStyle == style,
                            onTap: () => _selectGeneratorStyle(style),
                          ),
                        ),
                    ],
                  ),
                ),
                if (lastAutoPlan != null) ...[
                  const SizedBox(height: 10),
                  _AutoBedResultSummary(plan: lastAutoPlan!),
                ],
                const SizedBox(height: 10),
                PrimaryButton(
                  label:
                      plants.isEmpty ? 'Generate bed layout' : 'Regenerate bed',
                  onPressed:
                      erasing || spacingLoading ? null : _generateAutoBed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CupertinoSearchTextField(
            controller: search,
            placeholder: 'Search vegetables',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CropFamilyButton(
                  label: 'All',
                  selected: familyId == 'all',
                  onTap: () => setState(() => familyId = 'all'),
                ),
                ...vegetableFamilies.map(
                  (family) => Padding(
                    padding: const EdgeInsets.only(left: 7),
                    child: _CropFamilyButton(
                      label: family.name,
                      iconPath: family.iconPath,
                      selected: familyId == family.id,
                      onTap: () => setState(() => familyId = family.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: .94,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final crop = filtered[index];
              final spacing = _knownSpacing(crop);
              final advice = seasonalPlantingAdviceFor(crop);
              return _CropPaletteCard(
                crop: crop,
                spacing: spacing,
                advice: advice,
                selected: selectedCrop.id == crop.id && !erasing,
                count: _plantCount(crop),
                onTap: () => _selectCrop(crop, returnToBed: true),
              );
            },
          ),
          if (filtered.isEmpty)
            const EmptyInline('No vegetables match this filter.'),
        ],
      ),
    );
  }
}

class _PlannerToolStrip extends StatelessWidget {
  const _PlannerToolStrip({
    required this.erasing,
    required this.loading,
    required this.canClear,
    required this.onPaint,
    required this.onRow,
    required this.onFill,
    required this.onErase,
    required this.onClear,
  });

  final bool erasing;
  final bool loading;
  final bool canClear;
  final VoidCallback onPaint;
  final VoidCallback onRow;
  final VoidCallback onFill;
  final VoidCallback onErase;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _PlannerActionPill(
              label: 'Paint',
              icon: CupertinoIcons.pencil,
              selected: !erasing,
              onPressed: loading ? null : onPaint,
            ),
            const SizedBox(width: 8),
            _PlannerActionPill(
              label: 'Row',
              icon: CupertinoIcons.arrow_right,
              selected: false,
              onPressed: loading ? null : onRow,
            ),
            const SizedBox(width: 8),
            _PlannerActionPill(
              label: 'Fill',
              icon: CupertinoIcons.square_grid_2x2,
              selected: false,
              onPressed: erasing || loading ? null : onFill,
            ),
            const SizedBox(width: 8),
            _PlannerActionPill(
              label: 'Erase',
              icon: CupertinoIcons.delete,
              selected: erasing,
              onPressed: loading ? null : onErase,
            ),
            const SizedBox(width: 8),
            _PlannerActionPill(
              label: 'Clear',
              icon: CupertinoIcons.clear,
              selected: false,
              onPressed: canClear ? onClear : null,
            ),
          ],
        ),
      );
}

class _PlannerStatsPanel extends StatelessWidget {
  const _PlannerStatsPanel({
    required this.bed,
    required this.plants,
    required this.openSpots,
  });

  final GardenBed bed;
  final List<GardenPlant> plants;
  final int openSpots;

  @override
  Widget build(BuildContext context) {
    final cropCount = plants.map((plant) => plant.crop.id).toSet().length;
    final area = bed.widthMeters * bed.lengthMeters;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4D6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD2E3B0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PlannerStat(
              label: 'Plants',
              value: '${plants.length}',
            ),
          ),
          Expanded(
            child: _PlannerStat(
              label: 'Varieties',
              value: '$cropCount',
            ),
          ),
          Expanded(
            child: _PlannerStat(
              label: 'Open spots',
              value: '$openSpots',
            ),
          ),
          Expanded(
            child: _PlannerStat(
              label: 'Area',
              value: '${meterLabel(area)} m2',
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannerStat extends StatelessWidget {
  const _PlannerStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: C.forest,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: C.muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
}

class _CropSpacingBanner extends StatelessWidget {
  const _CropSpacingBanner({
    required this.crop,
    required this.spacing,
    required this.count,
    required this.loading,
  });

  final VegetableDefinition crop;
  final CropSpacing spacing;
  final int count;
  final bool loading;

  @override
  Widget build(BuildContext context) => Container(
        key: ValueKey('selected-crop-${crop.id}'),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.line),
        ),
        child: Row(
          children: [
            CropIcon(crop.iconPath, size: 34),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: C.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${spacing.label} | ${spacing.source}',
                    style: const TextStyle(
                      color: C.muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (loading)
              const CupertinoActivityIndicator(radius: 8)
            else
              ProductTag(
                label: '$count planted',
                color: C.forest,
                background: C.forestSoft,
              ),
          ],
        ),
      );
}

class _PlannerActionPill extends StatelessWidget {
  const _PlannerActionPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: selected
                ? C.forest
                : onPressed == null
                    ? C.soft
                    : C.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? C.forest : C.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected
                    ? CupertinoColors.white
                    : onPressed == null
                        ? C.muted
                        : C.forest,
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? CupertinoColors.white
                      : onPressed == null
                          ? C.muted
                          : C.forest,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
}

class _AutoBedStyleButton extends StatelessWidget {
  const _AutoBedStyleButton({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final AutoBedFoodStyle style;
  final bool selected;
  final VoidCallback onTap;

  IconData get icon => switch (style) {
        AutoBedFoodStyle.quick => CupertinoIcons.timer,
        AutoBedFoodStyle.balanced => CupertinoIcons.square_grid_2x2,
        AutoBedFoodStyle.longHold => CupertinoIcons.archivebox,
        AutoBedFoodStyle.salad => CupertinoIcons.leaf_arrow_circlepath,
      };

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? C.forest : C.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? C.forest : C.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? CupertinoColors.white : C.muted,
                size: 18,
              ),
              const SizedBox(width: 7),
              Text(
                style.shortLabel,
                style: TextStyle(
                  color: selected ? CupertinoColors.white : C.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
}

class _AutoBedResultSummary extends StatelessWidget {
  const _AutoBedResultSummary({required this.plan});

  final AutoBedPlanResult plan;

  @override
  Widget build(BuildContext context) {
    if (plan.totalPlants == 0) {
      return const EmptyInline('No open planting spots in this bed.');
    }
    final crops = plan.placements.entries.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: C.soft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${plan.totalPlants} plants | ${plan.placements.length} crops',
              style: const TextStyle(
                color: C.forest,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final entry in crops)
                  ProductTag(
                    label: entry.key.name,
                    color: C.forest,
                    background: C.card,
                  ),
                if (plan.placements.length > crops.length)
                  ProductTag(
                    label: '+${plan.placements.length - crops.length}',
                    color: C.muted,
                    background: C.card,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CropFamilyButton extends StatelessWidget {
  const _CropFamilyButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.iconPath,
  });

  final String label;
  final String? iconPath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: selected ? C.forest : C.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? C.forest : C.line),
          ),
          child: Row(
            children: [
              if (iconPath != null) ...[
                CropIcon(iconPath!, size: 24),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? CupertinoColors.white : C.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
}

class _CropPaletteCard extends StatelessWidget {
  const _CropPaletteCard({
    required this.crop,
    required this.spacing,
    required this.advice,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  final VegetableDefinition crop;
  final CropSpacing spacing;
  final SeasonalPlantingAdvice advice;
  final bool selected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEAF4D6) : C.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? C.forest : C.line,
              width: selected ? 1.7 : 1,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  selected
                      ? CupertinoIcons.check_mark_circled_solid
                      : CupertinoIcons.add_circled,
                  color: selected ? C.forest : C.muted,
                  size: 20,
                ),
              ),
              if (count > 0)
                Positioned(
                  left: 0,
                  top: 0,
                  child: ProductTag(
                    label: '$count',
                    color: C.forest,
                    background: C.card,
                  ),
                ),
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CropIcon(crop.iconPath, size: 50),
                    const SizedBox(height: 8),
                    Text(
                      crop.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: C.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${meterLabel(spacing.plantCm)}cm x ${meterLabel(spacing.rowCm)}cm',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: C.muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    ProductTag(
                      label: advice.inSeason ? advice.method.label : 'Later',
                      color: advice.inSeason ? C.forest : C.amber,
                      background: advice.inSeason ? C.forestSoft : C.amberSoft,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
