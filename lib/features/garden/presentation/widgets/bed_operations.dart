part of '../../../../main.dart';

enum _VegetablePlantingFilter {
  all,
  season,
  direct,
  trays,
  plantOut,
}

void showVegetableLogger(
  BuildContext context,
  GardenBed bed,
  List<VegetableDefinition> assigned,
  ValueChanged<VegetableDefinition> onAdd,
  ValueChanged<VegetableDefinition> onRemove,
) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => _VegetableLoggerSheet(
      bed: bed,
      assigned: assigned,
      onAdd: onAdd,
      onRemove: onRemove,
    ),
  );
}

class _VegetableLoggerSheet extends StatefulWidget {
  const _VegetableLoggerSheet({
    required this.bed,
    required this.assigned,
    required this.onAdd,
    required this.onRemove,
  });

  final GardenBed bed;
  final List<VegetableDefinition> assigned;
  final ValueChanged<VegetableDefinition> onAdd;
  final ValueChanged<VegetableDefinition> onRemove;

  @override
  State<_VegetableLoggerSheet> createState() => _VegetableLoggerSheetState();
}

class _VegetableLoggerSheetState extends State<_VegetableLoggerSheet> {
  final search = TextEditingController();
  late final selectedIds = widget.assigned.map((crop) => crop.id).toSet();
  String familyId = 'all';
  _VegetablePlantingFilter plantingFilter = _VegetablePlantingFilter.season;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  List<VegetableDefinition> get crops {
    final query = search.text.trim().toLowerCase();
    final currentSeason = gardenSeasonForDate(DateTime.now());
    final filtered = vegetableLibrary.where((crop) {
      final family = familyById(crop.familyId);
      final matchesFamily = familyId == 'all' || crop.familyId == familyId;
      final matchesQuery = query.isEmpty ||
          crop.name.toLowerCase().contains(query) ||
          family.name.toLowerCase().contains(query);
      if (!matchesFamily || !matchesQuery) return false;
      final advice = seasonalPlantingAdviceFor(crop);
      return switch (plantingFilter) {
        _VegetablePlantingFilter.all => true,
        _VegetablePlantingFilter.season => cropIsInSeason(crop, currentSeason),
        _VegetablePlantingFilter.direct =>
          advice.method == PlantingMethod.directSow,
        _VegetablePlantingFilter.trays =>
          advice.method == PlantingMethod.startTrays,
        _VegetablePlantingFilter.plantOut =>
          advice.method == PlantingMethod.transplantSeedlings ||
              advice.method == PlantingMethod.plantSets,
      };
    }).toList(growable: false);
    filtered.sort((a, b) {
      final aAdvice = seasonalPlantingAdviceFor(a);
      final bAdvice = seasonalPlantingAdviceFor(b);
      final season = bAdvice.inSeason.toString().compareTo(
            aAdvice.inSeason.toString(),
          );
      if (season != 0) return season;
      return a.name.compareTo(b.name);
    });
    return filtered;
  }

  void _toggle(VegetableDefinition crop) {
    setState(() {
      if (selectedIds.remove(crop.id)) {
        widget.onRemove(crop);
      } else {
        selectedIds.add(crop.id);
        widget.onAdd(crop);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final season = gardenSeasonForDate(DateTime.now());
    return CupertinoPopupSurface(
      child: SafeArea(
        top: false,
        child: Container(
          height: MediaQuery.of(context).size.height * .82,
          color: C.canvas,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Log vegetables in ${widget.bed.label}',
                      style: const TextStyle(
                        color: C.forest,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _GardenIconButton(
                    label: 'Done',
                    icon: CupertinoIcons.check_mark,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CupertinoSearchTextField(
                controller: search,
                placeholder: 'Search vegetables',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              CupertinoSlidingSegmentedControl<_VegetablePlantingFilter>(
                groupValue: plantingFilter,
                children: const {
                  _VegetablePlantingFilter.season: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Now'),
                  ),
                  _VegetablePlantingFilter.direct: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Direct'),
                  ),
                  _VegetablePlantingFilter.trays: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Trays'),
                  ),
                  _VegetablePlantingFilter.plantOut: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Plant out'),
                  ),
                  _VegetablePlantingFilter.all: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('All'),
                  ),
                },
                onValueChanged: (value) {
                  if (value == null) return;
                  setState(() => plantingFilter = value);
                },
              ),
              const SizedBox(height: 8),
              ProductTag(
                label: '${season.label} planting - Blenheim',
                color: C.forest,
                background: C.forestSoft,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: vegetableFamilies.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final id =
                        index == 0 ? 'all' : vegetableFamilies[index - 1].id;
                    final label =
                        index == 0 ? 'All' : vegetableFamilies[index - 1].name;
                    return NumberChip(
                      label: label,
                      selected: familyId == id,
                      onTap: () => setState(() => familyId = id),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (selectedIds.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: vegetableLibrary
                      .where((crop) => selectedIds.contains(crop.id))
                      .map(
                        (crop) => CropChip(
                          crop: crop,
                          onRemove: () => _toggle(crop),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: ListView.separated(
                  itemCount: crops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final crop = crops[index];
                    final selected = selectedIds.contains(crop.id);
                    final advice = seasonalPlantingAdviceFor(crop);
                    return CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _toggle(crop),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected ? C.forestSoft : C.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected ? C.forest : C.line,
                          ),
                        ),
                        child: Row(
                          children: [
                            CropIcon(crop.iconPath, size: 34),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    crop.name,
                                    style: const TextStyle(
                                      color: C.ink,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    familyById(crop.familyId).name,
                                    style: const TextStyle(
                                      color: C.muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      ProductTag(
                                        label: advice.title,
                                        color: _plantingMethodColor(advice),
                                        background:
                                            _plantingMethodBackground(advice),
                                      ),
                                      ProductTag(
                                        label: advice.inSeason
                                            ? advice.season.label
                                            : 'Out of season',
                                        color: advice.inSeason
                                            ? C.forest
                                            : C.muted,
                                        background: advice.inSeason
                                            ? C.forestSoft
                                            : C.greySoft,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    advice.body,
                                    style: const TextStyle(
                                      color: C.muted,
                                      fontSize: 12,
                                      height: 1.25,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              selected
                                  ? CupertinoIcons.check_mark_circled_solid
                                  : CupertinoIcons.add_circled,
                              color: selected ? C.forest : C.muted,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _plantingMethodColor(SeasonalPlantingAdvice advice) {
  if (!advice.inSeason) return C.muted;
  return switch (advice.method) {
    PlantingMethod.directSow => C.forest,
    PlantingMethod.startTrays => C.blue,
    PlantingMethod.transplantSeedlings => C.amber,
    PlantingMethod.plantSets => C.soil,
    PlantingMethod.wait => C.muted,
  };
}

Color _plantingMethodBackground(SeasonalPlantingAdvice advice) {
  if (!advice.inSeason) return C.greySoft;
  return switch (advice.method) {
    PlantingMethod.directSow => C.forestSoft,
    PlantingMethod.startTrays => C.blueSoft,
    PlantingMethod.transplantSeedlings => C.amberSoft,
    PlantingMethod.plantSets => C.soft,
    PlantingMethod.wait => C.greySoft,
  };
}

class _BedSuggestionsPanel extends StatelessWidget {
  const _BedSuggestionsPanel({
    required this.bed,
    required this.crops,
    required this.records,
    required this.products,
    required this.gardenRisks,
  });

  final GardenBed bed;
  final List<VegetableDefinition> crops;
  final List<SprayRecord> records;
  final List<SprayProduct> products;
  final Future<GardenRiskSummary> gardenRisks;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GardenRiskSummary>(
      future: gardenRisks,
      builder: (context, snapshot) {
        final suggestions = bedActionSuggestions(
          bed: bed,
          crops: crops,
          records: records,
          products: products,
          risks: snapshot.data,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Suggested actions'),
            const SizedBox(height: 8),
            ...suggestions.map(
              (suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BedSuggestionCard(suggestion: suggestion),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BedSuggestionCard extends StatelessWidget {
  const _BedSuggestionCard({required this.suggestion});

  final BedSuggestion suggestion;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: _suggestionBackground(suggestion.level),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _suggestionIcon(suggestion.kind),
              color: _suggestionColor(suggestion.level),
              size: 21,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.title,
                    style: TextStyle(
                      color: _suggestionColor(suggestion.level),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    suggestion.body,
                    style: const TextStyle(
                      color: C.ink,
                      height: 1.3,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (suggestion.product != null) ...[
                    const SizedBox(height: 8),
                    ProductTag(
                      label: suggestion.product!.name,
                      color: C.forest,
                      background: C.forestSoft,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

IconData _suggestionIcon(BedSuggestionKind kind) => switch (kind) {
      BedSuggestionKind.log => CupertinoIcons.square_pencil,
      BedSuggestionKind.spray => CupertinoIcons.drop,
      BedSuggestionKind.feed => CupertinoIcons.leaf_arrow_circlepath,
      BedSuggestionKind.rotate => CupertinoIcons.arrow_2_circlepath,
      BedSuggestionKind.protect => CupertinoIcons.snow,
    };

Color _suggestionColor(BedSuggestionLevel level) => switch (level) {
      BedSuggestionLevel.info => C.forest,
      BedSuggestionLevel.due => C.amber,
      BedSuggestionLevel.warning => C.red,
    };

Color _suggestionBackground(BedSuggestionLevel level) => switch (level) {
      BedSuggestionLevel.info => C.forestSoft,
      BedSuggestionLevel.due => C.amberSoft,
      BedSuggestionLevel.warning => C.redSoft,
    };

class _GardenBedSelector extends StatelessWidget {
  const _GardenBedSelector({
    required this.beds,
    required this.selectedBed,
    required this.bedCrops,
    required this.records,
    required this.onSelectBed,
  });

  final List<GardenBed> beds;
  final int selectedBed;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final List<SprayRecord> records;
  final ValueChanged<int> onSelectBed;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: beds.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final bed = beds[index];
            final crops = bedCrops[bed.number] ?? const <VegetableDefinition>[];
            final summary = bedSpraySummary(records, bed.number);
            final selected = bed.number == selectedBed;
            return CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => onSelectBed(bed.number),
              child: Container(
                width: 138,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected ? C.forest : C.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected ? C.forest : C.line,
                    width: selected ? 1.8 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      bed.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? CupertinoColors.white : C.forest,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      crops.isEmpty
                          ? 'No veg logged'
                          : '${crops.length} veg logged',
                      style: TextStyle(
                        color: selected ? const Color(0xCCFFFFFF) : C.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    StatusPill(
                      _bedSprayStatusLabel(summary.state),
                      hold: summary.onHold,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
}

class _GardenBedCropPanel extends StatelessWidget {
  const _GardenBedCropPanel({
    required this.bed,
    required this.crops,
    required this.records,
    required this.products,
    required this.gardenRisks,
    required this.spraySummary,
    required this.onAddCrop,
    required this.onRemoveCrop,
    required this.onStartSpray,
  });

  final GardenBed bed;
  final List<VegetableDefinition> crops;
  final List<SprayRecord> records;
  final List<SprayProduct> products;
  final Future<GardenRiskSummary> gardenRisks;
  final BedSpraySummary spraySummary;
  final VoidCallback onAddCrop;
  final ValueChanged<VegetableDefinition> onRemoveCrop;
  final VoidCallback onStartSpray;

  @override
  Widget build(BuildContext context) => Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bed.label,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: C.forest,
                    ),
                  ),
                ),
                StatusPill(
                  _bedSprayStatusLabel(spraySummary.state),
                  hold: spraySummary.onHold,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              bed.sizeLabel,
              style:
                  const TextStyle(color: C.muted, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _BedSprayStatusCard(summary: spraySummary),
            const SizedBox(height: 14),
            const SectionTitle('Current vegetables'),
            const SizedBox(height: 8),
            if (crops.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: crops
                    .map(
                      (crop) => CropChip(
                          crop: crop, onRemove: () => onRemoveCrop(crop)),
                    )
                    .toList(),
              ),
            ] else
              const EmptyCard('No vegetables logged in this bed.'),
            const SizedBox(height: 14),
            _BedSuggestionsPanel(
              bed: bed,
              crops: crops,
              records: records,
              products: products,
              gardenRisks: gardenRisks,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: crops.isEmpty ? 'Log vegetables' : 'Edit veg list',
                    onPressed: onAddCrop,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                      label: 'Log spray', onPressed: onStartSpray),
                ),
              ],
            ),
          ],
        ),
      );
}

class _BedSprayStatusCard extends StatelessWidget {
  const _BedSprayStatusCard({required this.summary});

  final BedSpraySummary summary;

  @override
  Widget build(BuildContext context) {
    final record = summary.record;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bedSprayStatusBackground(summary.state),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _bedSprayStatusIcon(summary.state),
            color: _bedSprayStatusColor(summary.state),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bedSprayStatusTitle(summary),
                  style: TextStyle(
                    color: _bedSprayStatusColor(summary.state),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _bedSprayStatusBody(summary),
                  style: const TextStyle(
                    color: C.ink,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (record != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ProductTag(
                        label: record.product,
                        color: C.forest,
                        background: C.forestSoft,
                      ),
                      ProductTag(
                        label: targetById(record.targetId).short,
                        color: targetById(record.targetId).color,
                        background: targetById(record.targetId).softColor,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _bedSprayStatusLabel(BedSprayState state) => switch (state) {
      BedSprayState.neverSprayed => 'UNSPRAYED',
      BedSprayState.clear => 'CLEAR',
      BedSprayState.hold => 'HOLD',
    };

String _bedSprayStatusTitle(BedSpraySummary summary) => switch (summary.state) {
      BedSprayState.neverSprayed => 'No spray logged for this bed',
      BedSprayState.clear => 'Sprayed and harvest clear',
      BedSprayState.hold => 'Sprayed and still on withholding hold',
    };

String _bedSprayStatusBody(BedSpraySummary summary) {
  final record = summary.record;
  if (record == null) {
    return 'Use Log spray when you apply a product so this bed can track harvest safety.';
  }

  final sprayed = shortDate(record.date);
  final safe = shortDate(record.safeDate);
  if (summary.onHold) {
    return 'Sprayed $sprayed. Safe harvest starts $safe after ${record.days} withholding days.';
  }

  return 'Last sprayed $sprayed. Withholding period ended $safe.';
}

IconData _bedSprayStatusIcon(BedSprayState state) => switch (state) {
      BedSprayState.neverSprayed => CupertinoIcons.circle,
      BedSprayState.clear => CupertinoIcons.check_mark_circled_solid,
      BedSprayState.hold => CupertinoIcons.exclamationmark_triangle_fill,
    };

Color _bedSprayStatusColor(BedSprayState state) => switch (state) {
      BedSprayState.neverSprayed => C.muted,
      BedSprayState.clear => C.forest,
      BedSprayState.hold => C.amber,
    };

Color _bedSprayStatusBackground(BedSprayState state) => switch (state) {
      BedSprayState.neverSprayed => C.greySoft,
      BedSprayState.clear => C.forestSoft,
      BedSprayState.hold => C.amberSoft,
    };
