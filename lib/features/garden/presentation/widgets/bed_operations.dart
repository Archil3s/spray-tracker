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

class SeasonalPlantingGuidePanel extends StatelessWidget {
  const SeasonalPlantingGuidePanel({
    required this.selectedBed,
    required this.selectedCrops,
    required this.onLogVegetables,
    super.key,
  });

  final GardenBed selectedBed;
  final List<VegetableDefinition> selectedCrops;
  final VoidCallback onLogVegetables;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final season = gardenSeasonForDate(now);
    final nextSeason = _nextGardenSeason(season);
    final loggedIds = selectedCrops.map((crop) => crop.id).toSet();
    final currentAdvice = vegetableLibrary
        .map((crop) => seasonalPlantingAdviceFor(crop, date: now))
        .where((advice) => advice.inSeason)
        .toList(growable: false);
    final nextAdvice = vegetableLibrary
        .map(
          (crop) => seasonalPlantingAdviceFor(
            crop,
            date: _representativeDateForSeason(nextSeason, now),
          ),
        )
        .where(
          (advice) =>
              advice.inSeason &&
              !cropIsInSeason(advice.crop, season) &&
              advice.method != PlantingMethod.wait,
        )
        .toList(growable: false);

    List<SeasonalPlantingAdvice> pick(
      Iterable<SeasonalPlantingAdvice> source,
      bool Function(SeasonalPlantingAdvice advice) test,
    ) {
      final items = source.where(test).toList(growable: false)
        ..sort((a, b) {
          final logged = loggedIds.contains(a.crop.id).toString().compareTo(
                loggedIds.contains(b.crop.id).toString(),
              );
          if (logged != 0) return logged;
          return a.crop.name.compareTo(b.crop.name);
        });
      return items.take(5).toList(growable: false);
    }

    final direct = pick(
      currentAdvice,
      (advice) => advice.method == PlantingMethod.directSow,
    );
    final trays = pick(
      currentAdvice,
      (advice) => advice.method == PlantingMethod.startTrays,
    );
    final plantOut = pick(
      currentAdvice,
      (advice) =>
          advice.method == PlantingMethod.transplantSeedlings ||
          advice.method == PlantingMethod.plantSets,
    );
    final next = pick(
      nextAdvice,
      (advice) => advice.method != PlantingMethod.wait,
    );

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            'Planting guide',
            trailing: ProductTag(
              label: '${season.label} Blenheim',
              color: C.forest,
              background: C.forestSoft,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Selected bed: ${selectedBed.label}',
                  style: const TextStyle(
                    color: C.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _CompactActionButton(
                label: 'Add veg',
                icon: CupertinoIcons.add,
                onPressed: onLogVegetables,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Guide only. Use Add veg to log crops into the selected bed.',
            style: TextStyle(
              color: C.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _PlantingGuideGroupCard(
            title: 'Direct sow now',
            subtitle: 'Seed straight into prepared soil.',
            icon: CupertinoIcons.arrow_down_circle,
            advices: direct,
            loggedIds: loggedIds,
          ),
          const SizedBox(height: 8),
          _PlantingGuideGroupCard(
            title: 'Plant out now',
            subtitle: 'Use seedlings, sets, cloves, or divisions.',
            icon: CupertinoIcons.leaf_arrow_circlepath,
            advices: plantOut,
            loggedIds: loggedIds,
          ),
          const SizedBox(height: 8),
          _PlantingGuideGroupCard(
            title: 'Start in trays now',
            subtitle: 'Raise seedlings under cover before transplanting.',
            icon: CupertinoIcons.tray,
            advices: trays,
            loggedIds: loggedIds,
          ),
          if (next.isNotEmpty) ...[
            const SizedBox(height: 8),
            _PlantingGuideGroupCard(
              title: 'Start for ${nextSeason.label}',
              subtitle: 'Plan these next so beds stay productive.',
              icon: CupertinoIcons.forward,
              advices: next,
              loggedIds: loggedIds,
              showMethod: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: C.forestSoft,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: C.forest.withValues(alpha: .18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: C.forest, size: 15),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: C.forest,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      );
}

class _PlantingGuideGroupCard extends StatelessWidget {
  const _PlantingGuideGroupCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.advices,
    required this.loggedIds,
    this.showMethod = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<SeasonalPlantingAdvice> advices;
  final Set<String> loggedIds;
  final bool showMethod;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: C.forest, size: 21),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: C.forest,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
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
              ],
            ),
            const SizedBox(height: 10),
            if (advices.isEmpty)
              const EmptyInline('No strong matches for this window.')
            else
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: advices
                    .map(
                      (advice) => _PlantingGuideCropPill(
                        advice: advice,
                        logged: loggedIds.contains(advice.crop.id),
                        showMethod: showMethod,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      );
}

class _PlantingGuideCropPill extends StatelessWidget {
  const _PlantingGuideCropPill({
    required this.advice,
    required this.logged,
    required this.showMethod,
  });

  final SeasonalPlantingAdvice advice;
  final bool logged;
  final bool showMethod;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: logged ? C.forestSoft : _plantingMethodBackground(advice),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: logged ? C.forest.withValues(alpha: .24) : C.line,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CropIcon(advice.crop.iconPath, size: 22),
            const SizedBox(width: 6),
            Text(
              advice.crop.name,
              style: TextStyle(
                color: logged ? C.forest : C.ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (showMethod) ...[
              const SizedBox(width: 6),
              Text(
                advice.method.label,
                style: TextStyle(
                  color: _plantingMethodColor(advice),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            if (logged) ...[
              const SizedBox(width: 5),
              const Icon(
                CupertinoIcons.check_mark_circled_solid,
                color: C.forest,
                size: 14,
              ),
            ],
          ],
        ),
      );
}

GardenSeason _nextGardenSeason(GardenSeason season) => switch (season) {
      GardenSeason.spring => GardenSeason.summer,
      GardenSeason.summer => GardenSeason.autumn,
      GardenSeason.autumn => GardenSeason.winter,
      GardenSeason.winter => GardenSeason.spring,
    };

DateTime _representativeDateForSeason(GardenSeason season, DateTime from) {
  final month = switch (season) {
    GardenSeason.spring => 9,
    GardenSeason.summer => 12,
    GardenSeason.autumn => 3,
    GardenSeason.winter => 6,
  };
  var date = DateTime(from.year, month, 15);
  while (!date.isAfter(from)) {
    date = DateTime(date.year + 1, month, 15);
  }
  return date;
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

class GardenOutlinePanel extends StatelessWidget {
  const GardenOutlinePanel({
    required this.selectedBed,
    required this.plot,
    required this.gardenBeds,
    required this.bedCrops,
    required this.bedPlants,
    required this.records,
    required this.isHold,
    required this.onSelectBed,
    super.key,
  });

  final int selectedBed;
  final GardenPlot plot;
  final List<GardenBed> gardenBeds;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final Map<int, List<GardenPlant>> bedPlants;
  final List<SprayRecord> records;
  final bool Function(int bed) isHold;
  final ValueChanged<int> onSelectBed;

  @override
  Widget build(BuildContext context) {
    final selected = gardenBeds.firstWhere(
      (bed) => bed.number == selectedBed,
      orElse: () => gardenBeds.first,
    );
    final selectedCrops =
        bedCrops[selected.number] ?? const <VegetableDefinition>[];
    final selectedPlants = bedPlants[selected.number] ?? const <GardenPlant>[];
    final selectedSummary = bedSpraySummary(records, selected.number);
    final plantedBeds = gardenBeds
        .where(
          (bed) =>
              (bedCrops[bed.number]?.isNotEmpty ?? false) ||
              (bedPlants[bed.number]?.isNotEmpty ?? false),
        )
        .length;
    final holdBeds = gardenBeds.where((bed) => isHold(bed.number)).length;
    final emptyBeds = gardenBeds.length - plantedBeds;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            'Garden map',
            trailing: ProductTag(
              label:
                  '${meterLabel(plot.widthMeters)} x ${meterLabel(plot.lengthMeters)} m',
              color: C.soil,
              background: C.soft,
            ),
          ),
          const SizedBox(height: 10),
          _GardenMapFocusBar(
            bed: selected,
            crops: selectedCrops,
            plantCount: selectedPlants.length,
            summary: selectedSummary,
          ),
          const SizedBox(height: 8),
          _GardenMapContentsStrip(
            crops: selectedCrops,
            plants: selectedPlants,
          ),
          const SizedBox(height: 10),
          _GardenMapStatusLegend(
            plantedBeds: plantedBeds,
            emptyBeds: emptyBeds,
            holdBeds: holdBeds,
          ),
          const SizedBox(height: 10),
          _CompactActionButton(
            label: 'Large map',
            icon: CupertinoIcons.fullscreen,
            onPressed: () => _showLargeGardenMap(
              context: context,
              selectedBed: selectedBed,
              plot: plot,
              gardenBeds: gardenBeds,
              bedCrops: bedCrops,
              bedPlants: bedPlants,
              records: records,
              isHold: isHold,
              onSelectBed: onSelectBed,
            ),
          ),
          const SizedBox(height: 12),
          GardenMapFrame(
            height: 360,
            showLegend: false,
            child: GardenMap(
              selectedBed: selectedBed,
              plot: plot,
              gardenBeds: gardenBeds,
              bedCrops: bedCrops,
              bedPlants: bedPlants,
              records: records,
              isHold: isHold,
              designing: false,
              onTap: onSelectBed,
              onMove: (_, __) {},
            ),
          ),
        ],
      ),
    );
  }
}

void _showLargeGardenMap({
  required BuildContext context,
  required int selectedBed,
  required GardenPlot plot,
  required List<GardenBed> gardenBeds,
  required Map<int, List<VegetableDefinition>> bedCrops,
  required Map<int, List<GardenPlant>> bedPlants,
  required List<SprayRecord> records,
  required bool Function(int bed) isHold,
  required ValueChanged<int> onSelectBed,
}) {
  var activeBed = selectedBed;
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setSheetState) {
        final selected = gardenBeds.firstWhere(
          (bed) => bed.number == activeBed,
          orElse: () => gardenBeds.first,
        );
        final selectedCrops =
            bedCrops[selected.number] ?? const <VegetableDefinition>[];
        final selectedPlants =
            bedPlants[selected.number] ?? const <GardenPlant>[];
        final selectedSummary = bedSpraySummary(records, selected.number);

        return Sheet(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              children: [
                SheetHeader(
                  title: 'Garden map',
                  subtitle:
                      '${meterLabel(plot.widthMeters)} x ${meterLabel(plot.lengthMeters)} m',
                ),
                const SizedBox(height: 12),
                _GardenMapFocusBar(
                  bed: selected,
                  crops: selectedCrops,
                  plantCount: selectedPlants.length,
                  summary: selectedSummary,
                ),
                const SizedBox(height: 8),
                _GardenMapContentsStrip(
                  crops: selectedCrops,
                  plants: selectedPlants,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap beds to switch selection. Pinch or drag the map to inspect your layout.',
                  style: TextStyle(
                    color: C.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _LargeGardenMapViewport(
                    selectedBed: activeBed,
                    plot: plot,
                    gardenBeds: gardenBeds,
                    bedCrops: bedCrops,
                    bedPlants: bedPlants,
                    records: records,
                    isHold: isHold,
                    onSelectBed: (bed) {
                      setSheetState(() => activeBed = bed);
                      onSelectBed(bed);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _LargeGardenMapViewport extends StatelessWidget {
  const _LargeGardenMapViewport({
    required this.selectedBed,
    required this.plot,
    required this.gardenBeds,
    required this.bedCrops,
    required this.bedPlants,
    required this.records,
    required this.isHold,
    required this.onSelectBed,
  });

  final int selectedBed;
  final GardenPlot plot;
  final List<GardenBed> gardenBeds;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final Map<int, List<GardenPlant>> bedPlants;
  final List<SprayRecord> records;
  final bool Function(int bed) isHold;
  final ValueChanged<int> onSelectBed;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final mapWidth = math.max(360.0, constraints.maxWidth);
          final mapHeight = math.max(
            constraints.maxHeight,
            mapWidth * plot.lengthMeters / plot.widthMeters,
          );
          return ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: InteractiveViewer(
              constrained: false,
              minScale: .55,
              maxScale: 3,
              boundaryMargin: const EdgeInsets.all(140),
              child: SizedBox(
                width: mapWidth,
                height: mapHeight,
                child: GardenMapFrame(
                  height: mapHeight,
                  showLegend: false,
                  child: GardenMap(
                    selectedBed: selectedBed,
                    plot: plot,
                    gardenBeds: gardenBeds,
                    bedCrops: bedCrops,
                    bedPlants: bedPlants,
                    records: records,
                    isHold: isHold,
                    designing: false,
                    onTap: onSelectBed,
                    onMove: (_, __) {},
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class _GardenMapFocusBar extends StatelessWidget {
  const _GardenMapFocusBar({
    required this.bed,
    required this.crops,
    required this.plantCount,
    required this.summary,
  });

  final GardenBed bed;
  final List<VegetableDefinition> crops;
  final int plantCount;
  final BedSpraySummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: C.forestSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.forest.withValues(alpha: .14)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: C.forest.withValues(alpha: .12)),
            ),
            child: crops.isEmpty
                ? const Icon(
                    CupertinoIcons.square_grid_2x2,
                    color: C.forest,
                    size: 24,
                  )
                : Center(child: CropIcon(crops.first.iconPath, size: 27)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${bed.label} selected',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: C.forest,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$plantCount plant${plantCount == 1 ? '' : 's'} | '
                  '${crops.length} veg logged',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: C.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ProductTag(
            label: _bedSprayStatusLabel(summary.state),
            color: _bedSprayStatusColor(summary.state),
            background: _bedSprayStatusBackground(summary.state),
          ),
        ],
      ),
    );
  }
}

class _GardenMapContentsStrip extends StatelessWidget {
  const _GardenMapContentsStrip({
    required this.crops,
    required this.plants,
  });

  final List<VegetableDefinition> crops;
  final List<GardenPlant> plants;

  @override
  Widget build(BuildContext context) {
    final items = _bedCropCounts(crops, plants);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.line),
      ),
      child: items.isEmpty
          ? const Text(
              'No vegetables logged in this bed.',
              style: TextStyle(
                color: C.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in items) _GardenMapContentChip(item: item),
              ],
            ),
    );
  }
}

class _GardenMapContentChip extends StatelessWidget {
  const _GardenMapContentChip({required this.item});

  final _GardenCropCount item;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 9, 6),
        decoration: BoxDecoration(
          color: C.forestSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: C.forest.withValues(alpha: .14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CropIcon(item.crop.iconPath, size: 18),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 132),
              child: Text(
                item.crop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: C.forest,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'x${item.count}',
              style: const TextStyle(
                color: C.forest,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _GardenMapStatusLegend extends StatelessWidget {
  const _GardenMapStatusLegend({
    required this.plantedBeds,
    required this.emptyBeds,
    required this.holdBeds,
  });

  final int plantedBeds;
  final int emptyBeds;
  final int holdBeds;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _GardenMapLegendChip(
            label: 'Planted $plantedBeds',
            color: C.forest,
            background: C.forestSoft,
          ),
          _GardenMapLegendChip(
            label: 'Empty $emptyBeds',
            color: C.soil,
            background: C.soft,
          ),
          _GardenMapLegendChip(
            label: 'Hold $holdBeds',
            color: C.amber,
            background: C.amberSoft,
          ),
        ],
      );
}

class _GardenMapLegendChip extends StatelessWidget {
  const _GardenMapLegendChip({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: .18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _GardenBedSelector extends StatelessWidget {
  const _GardenBedSelector({
    required this.beds,
    required this.selectedBed,
    required this.bedCrops,
    required this.bedPlants,
    required this.records,
    required this.onSelectBed,
    required this.onOpenRecord,
  });

  final List<GardenBed> beds;
  final int selectedBed;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final Map<int, List<GardenPlant>> bedPlants;
  final List<SprayRecord> records;
  final ValueChanged<int> onSelectBed;
  final ValueChanged<SprayRecord> onOpenRecord;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 112,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: beds.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final bed = beds[index];
            final crops = bedCrops[bed.number] ?? const <VegetableDefinition>[];
            final plantCount = bedPlants[bed.number]?.length ?? 0;
            final summary = bedSpraySummary(records, bed.number);
            final selected = bed.number == selectedBed;
            return CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => onSelectBed(bed.number),
              child: Container(
                width: 158,
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
                      crops.isEmpty && plantCount == 0
                          ? 'No veg logged'
                          : '$plantCount plants | ${crops.length} veg',
                      style: TextStyle(
                        color: selected ? const Color(0xCCFFFFFF) : C.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    FittedBox(
                      alignment: Alignment.centerLeft,
                      child: _LinkedStatusPill(
                        summary: summary,
                        onOpenRecord: onOpenRecord,
                      ),
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
    required this.plants,
    required this.records,
    required this.products,
    required this.gardenRisks,
    required this.spraySummary,
    required this.onAddCrop,
    required this.onRemoveCrop,
    required this.onSetPlantCount,
    required this.onOpenRecord,
    required this.onStartSpray,
  });

  final GardenBed bed;
  final List<VegetableDefinition> crops;
  final List<GardenPlant> plants;
  final List<SprayRecord> records;
  final List<SprayProduct> products;
  final Future<GardenRiskSummary> gardenRisks;
  final BedSpraySummary spraySummary;
  final VoidCallback onAddCrop;
  final ValueChanged<VegetableDefinition> onRemoveCrop;
  final void Function(VegetableDefinition crop, int count) onSetPlantCount;
  final ValueChanged<SprayRecord> onOpenRecord;
  final VoidCallback onStartSpray;

  @override
  Widget build(BuildContext context) {
    final hasCrops = crops.isNotEmpty;
    final plantSummary =
        '${plants.length} plant${plants.length == 1 ? '' : 's'} | '
        '${crops.length} veg logged';
    return Panel(
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
              _LinkedStatusPill(
                summary: spraySummary,
                onOpenRecord: onOpenRecord,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _friendlyBedSizeLabel(bed),
            style: const TextStyle(
              color: C.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ProductTag(
            label: hasCrops ? plantSummary : 'No vegetables logged',
            color: hasCrops ? C.forest : C.amber,
            background: hasCrops ? C.forestSoft : C.amberSoft,
          ),
          const SizedBox(height: 14),
          const SectionTitle('Current vegetables'),
          const SizedBox(height: 8),
          if (crops.isNotEmpty) ...[
            ...crops.map(
              (crop) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CropPlantCountRow(
                  bed: bed,
                  crop: crop,
                  count: _plantCountForCrop(plants, crop),
                  plants: plants,
                  records: records,
                  products: products,
                  onRemove: () => onRemoveCrop(crop),
                  onSetCount: (count) => onSetPlantCount(crop, count),
                ),
              ),
            ),
          ] else
            const EmptyCard(
              'No vegetables logged in this bed. Add what is growing before planning sprays.',
            ),
          if (hasCrops || spraySummary.record != null) ...[
            const SizedBox(height: 14),
            _BedSprayStatusCard(
              summary: spraySummary,
              onOpenRecord: onOpenRecord,
            ),
          ],
          const SizedBox(height: 14),
          _BedSuggestionsPanel(
            bed: bed,
            crops: crops,
            records: records,
            products: products,
            gardenRisks: gardenRisks,
          ),
          const SizedBox(height: 14),
          if (!hasCrops)
            PrimaryButton(label: 'Log vegetables', onPressed: onAddCrop)
          else
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Edit veg list',
                    onPressed: onAddCrop,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'Log spray',
                    onPressed: onStartSpray,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

int _plantCountForCrop(List<GardenPlant> plants, VegetableDefinition crop) =>
    plants.where((plant) => plant.crop.id == crop.id).length;

String _friendlyBedSizeLabel(GardenBed bed) =>
    '${_friendlyMeters(bed.widthMeters)} m wide x '
    '${_friendlyMeters(bed.lengthMeters)} m long';

String _friendlyMeters(double value) => value.toStringAsFixed(1);

class _CropPlantCountRow extends StatelessWidget {
  const _CropPlantCountRow({
    required this.bed,
    required this.crop,
    required this.count,
    required this.plants,
    required this.records,
    required this.products,
    required this.onRemove,
    required this.onSetCount,
  });

  final GardenBed bed;
  final VegetableDefinition crop;
  final int count;
  final List<GardenPlant> plants;
  final List<SprayRecord> records;
  final List<SprayProduct> products;
  final VoidCallback onRemove;
  final ValueChanged<int> onSetCount;

  @override
  Widget build(BuildContext context) {
    final spacing = cropSpacingFor(crop);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () => showGardenCropDetail(
                context,
                bed: bed,
                crop: crop,
                plants: plants,
                records: records,
                products: products,
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: C.forestSoft,
                      borderRadius: BorderRadius.circular(999),
                      border:
                          Border.all(color: C.forest.withValues(alpha: .18)),
                    ),
                    child: CropIcon(crop.iconPath, size: 34),
                  ),
                  const SizedBox(width: 10),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${familyById(crop.familyId).name} | ${spacing.label}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: C.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _PlantCountControl(
            count: count,
            onDecrease: count == 0 ? null : () => onSetCount(count - 1),
            onIncrease: () => onSetCount(count + 1),
            onEdit: () => showPlantCountEditor(
              context,
              crop: crop,
              count: count,
              onSetCount: onSetCount,
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(28, 28),
            onPressed: onRemove,
            child: const Icon(
              CupertinoIcons.clear,
              color: C.muted,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantCountControl extends StatelessWidget {
  const _PlantCountControl({
    required this.count,
    required this.onDecrease,
    required this.onIncrease,
    required this.onEdit,
  });

  final int count;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Container(
        height: 36,
        decoration: BoxDecoration(
          color: C.canvas,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: C.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CountIconButton(
              icon: CupertinoIcons.minus,
              onPressed: onDecrease,
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(42, 34),
              onPressed: onEdit,
              child: Text(
                '$count',
                style: const TextStyle(
                  color: C.forest,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _CountIconButton(
              icon: CupertinoIcons.plus,
              onPressed: onIncrease,
            ),
          ],
        ),
      );
}

class _CountIconButton extends StatelessWidget {
  const _CountIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(30, 34),
        onPressed: onPressed,
        child: Icon(
          icon,
          color: onPressed == null ? C.muted.withValues(alpha: .38) : C.forest,
          size: 15,
        ),
      );
}

void showPlantCountEditor(
  BuildContext context, {
  required VegetableDefinition crop,
  required int count,
  required ValueChanged<int> onSetCount,
}) {
  final controller = TextEditingController(text: '$count');
  showCupertinoDialog<void>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text('${crop.name} plants'),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: CupertinoTextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          placeholder: 'Plant count',
          textAlign: TextAlign.center,
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            final value = int.tryParse(controller.text.trim());
            if (value != null && value >= 0) {
              onSetCount(value);
            }
            Navigator.of(dialogContext).pop();
          },
          child: const Text('Set'),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

void showGardenCropDetail(
  BuildContext context, {
  required GardenBed bed,
  required VegetableDefinition crop,
  required List<GardenPlant> plants,
  required List<SprayRecord> records,
  required List<SprayProduct> products,
}) {
  final count = _plantCountForCrop(plants, crop);
  final spacing = cropSpacingFor(crop);
  final advice = seasonalPlantingAdviceFor(crop);
  final history = records
      .where((record) => _recordCoversCropInBed(record, bed.number, crop))
      .toList(growable: false);
  final suggestedProducts = _productsForCropDetail(products, crop);
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => Sheet(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SheetHeader(
            title: crop.name,
            subtitle: '${bed.label} | $count logged plants',
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailLine('Family', familyById(crop.familyId).name),
                DetailLine('Plant count', '$count'),
                DetailLine('Spacing', spacing.label),
                DetailLine(
                  'Planting guide',
                  '${advice.title} | ${advice.body}',
                ),
                DetailLine(
                  'Maintenance',
                  crop.maintenanceTips.take(4).join(', '),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const SectionTitle('Pest and fungus watch'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              ...crop.commonPests.take(6).map(
                    (item) => ProductTag(
                      label: item,
                      color: C.red,
                      background: C.redSoft,
                    ),
                  ),
              ...crop.commonDiseases.take(6).map(
                    (item) => ProductTag(
                      label: item,
                      color: C.blue,
                      background: C.blueSoft,
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 14),
          const SectionTitle('Spray history'),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const EmptyCard('No spray records linked to this crop yet.')
          else
            ...history.map(
              (record) => RecordCard(
                record: record,
                onTap: () => showSprayRecordDetail(context, record),
              ),
            ),
          const SizedBox(height: 14),
          const SectionTitle('Suggested products'),
          const SizedBox(height: 8),
          if (suggestedProducts.isEmpty)
            const EmptyCard('No matching products found for this crop.')
          else
            ...suggestedProducts.map(
              (product) => ProductTile(product: product),
            ),
        ],
      ),
    ),
  );
}

bool _recordCoversCropInBed(
  SprayRecord record,
  int bed,
  VegetableDefinition crop,
) {
  if (!record.beds.contains(bed)) return false;
  final cropName = crop.name.toLowerCase();
  final familyName = familyById(crop.familyId).name.toLowerCase();
  return record.crops.any((item) {
    final value = item.toLowerCase();
    return value == 'whole bed' ||
        cropName.contains(value) ||
        value.contains(cropName) ||
        value.contains(familyName);
  });
}

List<SprayProduct> _productsForCropDetail(
  List<SprayProduct> products,
  VegetableDefinition crop,
) {
  final cropName = crop.name.toLowerCase();
  final familyName = familyById(crop.familyId).name.toLowerCase();
  final issues = [...crop.commonPests, ...crop.commonDiseases]
      .map((item) => item.toLowerCase())
      .toList(growable: false);
  return products
      .where((product) {
        final text = product.searchText;
        if (text.contains(cropName) || text.contains(familyName)) return true;
        return issues.any((issue) => text.contains(issue));
      })
      .take(5)
      .toList(growable: false);
}

class _BedSprayStatusCard extends StatelessWidget {
  const _BedSprayStatusCard({
    required this.summary,
    required this.onOpenRecord,
  });

  final BedSpraySummary summary;
  final ValueChanged<SprayRecord> onOpenRecord;

  @override
  Widget build(BuildContext context) {
    final record = summary.record;
    final card = Container(
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
                      const ProductTag(
                        label: 'Tap for record',
                        color: C.muted,
                        background: C.greySoft,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (record != null) ...[
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_forward,
              color: C.muted,
              size: 16,
            ),
          ],
        ],
      ),
    );
    if (record == null) return card;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: () => onOpenRecord(record),
      child: card,
    );
  }
}

class _LinkedStatusPill extends StatelessWidget {
  const _LinkedStatusPill({
    required this.summary,
    required this.onOpenRecord,
  });

  final BedSpraySummary summary;
  final ValueChanged<SprayRecord> onOpenRecord;

  @override
  Widget build(BuildContext context) {
    final pill = StatusPill(
      _bedSprayStatusLabel(summary.state),
      hold: summary.onHold,
    );
    final record = summary.record;
    if (record == null) return pill;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: () => onOpenRecord(record),
      child: pill,
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
