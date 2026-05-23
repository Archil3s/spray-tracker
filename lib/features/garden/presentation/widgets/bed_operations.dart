part of '../../../../main.dart';

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

  @override
  void dispose() {
    search.dispose();
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
  Widget build(BuildContext context) => CupertinoPopupSurface(
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
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: vegetableFamilies.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final id =
                          index == 0 ? 'all' : vegetableFamilies[index - 1].id;
                      final label = index == 0
                          ? 'All'
                          : vegetableFamilies[index - 1].name;
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
