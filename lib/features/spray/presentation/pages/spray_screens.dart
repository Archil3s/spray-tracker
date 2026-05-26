part of '../../../../main.dart';

class SprayLogScreen extends StatefulWidget {
  const SprayLogScreen({
    required this.initialBeds,
    required this.plot,
    required this.gardenBeds,
    required this.bedCrops,
    required this.records,
    required this.pestSightings,
    required this.products,
    required this.productsLoading,
    required this.sprayConditions,
    required this.onSave,
    required this.onSavePestSighting,
    super.key,
  });
  final Set<int> initialBeds;
  final GardenPlot plot;
  final List<GardenBed> gardenBeds;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final List<SprayRecord> records;
  final List<PestSighting> pestSightings;
  final List<SprayProduct> products;
  final bool productsLoading;
  final Future<SprayConditionSummary> sprayConditions;
  final void Function({
    required Set<int> beds,
    required Set<String> crops,
    required Map<String, OpenFarmCrop> cropProfiles,
    required String targetId,
    required SprayProduct product,
    required String reason,
    required String notes,
    required int days,
  }) onSave;
  final void Function({
    required int bed,
    required String cropName,
    required String issueName,
    required PestSeverity severity,
    required String actionTaken,
    required DateTime recheckDate,
    required String notes,
  }) onSavePestSighting;

  @override
  State<SprayLogScreen> createState() => _SprayLogScreenState();
}

class _SprayLogScreenState extends State<SprayLogScreen> {
  late Set<int> beds = {...widget.initialBeds};
  final Set<String> manualCrops = {};
  final Map<String, OpenFarmCrop> cropProfiles = {};
  String targetId = 'pest';
  String? selectedIssue;
  String selectedActionTaken = 'Sprayed selected product';
  SprayProduct? selectedProduct;
  int days = 0;
  final notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.products.isNotEmpty) {
      _selectProduct(_bestProductForCurrentTarget());
    }
  }

  @override
  void didUpdateWidget(covariant SprayLogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.products.isEmpty) {
      selectedProduct = null;
      return;
    }
    final productsLoaded =
        oldWidget.products.isEmpty && widget.products.isNotEmpty;
    final selectedStillExists = selectedProduct == null ||
        widget.products.any((product) => product.id == selectedProduct!.id);
    if (productsLoaded || !selectedStillExists) {
      _selectProduct(_bestProductForCurrentTarget());
    }
  }

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  List<VegetableDefinition> _selectedCropDefinitions() {
    final byId = <String, VegetableDefinition>{};
    for (final bed in beds) {
      for (final crop
          in widget.bedCrops[bed] ?? const <VegetableDefinition>[]) {
        byId[crop.id] = crop;
      }
    }
    for (final name in manualCrops) {
      final lower = name.toLowerCase();
      for (final crop in vegetableLibrary) {
        if (crop.name.toLowerCase() == lower) {
          byId[crop.id] = crop;
          break;
        }
      }
    }
    return byId.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  SprayProduct _bestProductForCurrentTarget({String issue = ''}) {
    assert(widget.products.isNotEmpty);
    final ranked = rankedSprayProductsForSpray(
      targetId: targetId,
      issue: issue,
      crops: _selectedCropDefinitions(),
      products: widget.products,
    );
    return ranked.isEmpty ? widget.products.first : ranked.first;
  }

  void _selectProduct(SprayProduct product) {
    selectedProduct = product;
    days = product.withholdingDays;
  }

  @override
  Widget build(BuildContext context) {
    final product = selectedProduct;
    final cropDefinitions = _selectedCropDefinitions();
    final crops = {
      ...cropNamesForBeds(widget.bedCrops, beds),
      ...manualCrops,
    }.toList()
      ..sort();
    final sortedBeds = beds.toList()..sort();
    final issueSuggestions = buildSprayAgainstSuggestions(
      crops: cropDefinitions,
      targetId: targetId,
      products: widget.products,
    );
    final issueOptions = _sprayIssueOptions(
      targetId: targetId,
      crops: cropDefinitions,
      suggestions: issueSuggestions,
    );
    final issue = selectedIssue != null && issueOptions.contains(selectedIssue)
        ? selectedIssue!
        : issueOptions.isNotEmpty
            ? issueOptions.first
            : '';
    final actionOptions = _sprayActionOptions(targetId);
    final actionTaken = actionOptions.contains(selectedActionTaken)
        ? selectedActionTaken
        : actionOptions.first;
    final rankedProducts = widget.products.isEmpty
        ? const <SprayProduct>[]
        : rankedSprayProductsForSpray(
            targetId: targetId,
            issue: issue,
            crops: cropDefinitions,
            products: widget.products,
          );
    final rankedIds = rankedProducts.map((product) => product.id).toSet();
    final productList = [
      ...rankedProducts,
      ...widget.products.where((product) => !rankedIds.contains(product.id)),
    ];
    final saveBlockedReason = beds.isEmpty
        ? 'Select at least one bed on the garden outline before saving.'
        : product == null
            ? 'Select a spray or feed product before saving.'
            : '';
    return AppPage(
      title: 'Spray Log',
      subtitle:
          'Choose product, then withholding and re-entry notes fill automatically.',
      children: [
        SprayConditionBanner(sprayConditions: widget.sprayConditions),
        const SizedBox(height: 18),
        _PestSightingQuickForm(
          gardenBeds: widget.gardenBeds,
          bedCrops: widget.bedCrops,
          pestSightings: widget.pestSightings,
          onSave: widget.onSavePestSighting,
        ),
        const SizedBox(height: 18),
        const SectionTitle('Beds sprayed'),
        const SizedBox(height: 8),
        GardenMapFrame(
          height: 380,
          child: GardenMap(
            selectedBed: beds.isEmpty ? -1 : beds.first,
            selectedBeds: beds,
            plot: widget.plot,
            gardenBeds: widget.gardenBeds,
            bedCrops: widget.bedCrops,
            records: widget.records,
            isHold: (bed) => widget.records.any(
              (record) => record.beds.contains(bed) && record.onHold,
            ),
            designing: false,
            onTap: (bed) => setState(
              () {
                if (beds.contains(bed)) {
                  beds.remove(bed);
                } else {
                  beds.add(bed);
                }
              },
            ),
            onMove: (_, __) {},
          ),
        ),
        const SizedBox(height: 8),
        if (beds.isEmpty)
          const EmptyCard('Tap beds on the garden outline to select them.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ProductTag(
                label:
                    '${beds.length} bed${beds.length == 1 ? '' : 's'} selected',
                color: C.forest,
                background: C.forestSoft,
              ),
              ...sortedBeds.map(
                (bed) => ProductTag(
                  label: 'Bed $bed',
                  color: C.forest,
                  background: C.card,
                ),
              ),
            ],
          ),
        const SizedBox(height: 18),
        const SectionTitle('Crops affected'),
        const SizedBox(height: 8),
        if (crops.isEmpty)
          const EmptyCard('No crops assigned to selected bed yet.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: crops.map((crop) => TextChip(label: crop)).toList(),
          ),
        const SizedBox(height: 8),
        CropLookupField(
          onCropChosen: (name, crop) => setState(() {
            manualCrops.add(name);
            if (crop != null) {
              cropProfiles[name] = crop;
            }
          }),
        ),
        if (crops.isNotEmpty) ...[
          const SizedBox(height: 8),
          OpenFarmCropInfoSection(cropName: crops.first),
        ],
        const SizedBox(height: 18),
        const SectionTitle('Spraying against'),
        const SizedBox(height: 8),
        TargetGrid(
          selected: targetId,
          onSelect: (id) => setState(() {
            targetId = id;
            selectedIssue = null;
            selectedActionTaken = _sprayActionOptions(id).first;
            if (widget.products.isNotEmpty) {
              _selectProduct(_bestProductForCurrentTarget());
            }
          }),
        ),
        const SizedBox(height: 10),
        _SprayAgainstSuggestionsPanel(
          suggestions: issueSuggestions,
          onUse: (suggestion) => setState(() {
            targetId = suggestion.targetId;
            selectedIssue = suggestion.issue;
            selectedActionTaken =
                _sprayActionOptions(suggestion.targetId).first;
            if (suggestion.product != null) {
              _selectProduct(suggestion.product!);
            } else if (widget.products.isNotEmpty) {
              _selectProduct(
                _bestProductForCurrentTarget(issue: suggestion.issue),
              );
            }
          }),
        ),
        const SizedBox(height: 18),
        const SectionTitle('NZ product library'),
        const SizedBox(height: 8),
        if (widget.productsLoading)
          const Center(child: CupertinoActivityIndicator())
        else if (widget.products.isEmpty)
          const EmptyCard('No products loaded.')
        else
          ...productList.map(
            (item) => ProductChoice(
              product: item,
              selected: product?.id == item.id,
              suggested:
                  rankedProducts.take(4).any((match) => match.id == item.id) ||
                      item.targets.contains(targetId),
              onTap: () {
                setState(() => _selectProduct(item));
                showSprayProductDetail(
                  context,
                  item,
                  gardenBeds: widget.gardenBeds,
                  bedCrops: widget.bedCrops,
                  records: widget.records,
                );
              },
            ),
          ),
        if (product != null) ...[
          const SizedBox(height: 10),
          _SprayDecisionPanel(
            product: product,
            targetId: targetId,
            crops: cropDefinitions,
            beds: sortedBeds,
            records: widget.records,
            products: widget.products,
          ),
        ],
        const SizedBox(height: 18),
        _SprayDropdownCard(
          title: 'Issue / reason',
          value: issue.isEmpty ? 'Select issue' : issue,
          icon: CupertinoIcons.exclamationmark_circle,
          options: issueOptions,
          emptyText:
              'Select planted beds first. The app will build choices from the crops in those beds.',
          onSelected: (value) {
            setState(() {
              selectedIssue = value;
              if (widget.products.isNotEmpty) {
                _selectProduct(_bestProductForCurrentTarget(issue: value));
              }
            });
          },
        ),
        const SizedBox(height: 8),
        _SprayDropdownCard(
          title: 'Action taken',
          value: actionTaken,
          icon: CupertinoIcons.checkmark_circle,
          options: actionOptions,
          emptyText: 'No actions available.',
          onSelected: (value) => setState(() => selectedActionTaken = value),
        ),
        const SizedBox(height: 8),
        Field(controller: notes, placeholder: 'Notes optional', maxLines: 3),
        const SizedBox(height: 12),
        Stepper(
          label: 'Withholding days',
          value: days,
          minus: days > 0 ? () => setState(() => days--) : null,
          plus: () => setState(() => days++),
        ),
        if (product != null) ...[
          const SizedBox(height: 8),
          SprayProductHelperNotes(product: product),
        ],
        if (saveBlockedReason.isNotEmpty) ...[
          const SizedBox(height: 12),
          EmptyInline(saveBlockedReason),
        ],
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Save spray record',
          onPressed: product == null || beds.isEmpty
              ? null
              : () => widget.onSave(
                    beds: beds,
                    crops: crops.toSet(),
                    cropProfiles: cropProfiles,
                    targetId: targetId,
                    product: product,
                    reason: issue,
                    notes: _sprayNotesWithAction(
                      actionTaken: actionTaken,
                      notes: notes.text,
                    ),
                    days: days,
                  ),
        ),
      ],
    );
  }
}

class _PestSightingQuickForm extends StatefulWidget {
  const _PestSightingQuickForm({
    required this.gardenBeds,
    required this.bedCrops,
    required this.pestSightings,
    required this.onSave,
  });

  final List<GardenBed> gardenBeds;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final List<PestSighting> pestSightings;
  final void Function({
    required int bed,
    required String cropName,
    required String issueName,
    required PestSeverity severity,
    required String actionTaken,
    required DateTime recheckDate,
    required String notes,
  }) onSave;

  @override
  State<_PestSightingQuickForm> createState() => _PestSightingQuickFormState();
}

class _PestSightingQuickFormState extends State<_PestSightingQuickForm> {
  int? selectedBed;
  String? selectedCropName;
  String? selectedIssueName;
  PestSeverity severity = PestSeverity.medium;
  String actionTaken = 'Observed only';
  int recheckDays = 3;
  final notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedBed =
        widget.gardenBeds.isEmpty ? null : widget.gardenBeds.first.number;
  }

  @override
  void didUpdateWidget(covariant _PestSightingQuickForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (selectedBed != null &&
        !widget.gardenBeds.any((bed) => bed.number == selectedBed)) {
      selectedBed =
          widget.gardenBeds.isEmpty ? null : widget.gardenBeds.first.number;
      selectedCropName = null;
      selectedIssueName = null;
    }
  }

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bedOptions = widget.gardenBeds.map((bed) => bed.label).toList();
    final bed = selectedBed;
    final cropOptions = _cropOptionsForBed(bed);
    final cropName = cropOptions.contains(selectedCropName)
        ? selectedCropName!
        : cropOptions.first;
    final issueOptions = _pestIssueOptions(bed, cropName);
    final issueName = issueOptions.contains(selectedIssueName)
        ? selectedIssueName!
        : issueOptions.first;
    final severityOptions =
        PestSeverity.values.map(pestSeverityLabel).toList(growable: false);
    final actionOptions = const [
      'Observed only',
      'Removed affected leaves',
      'Hand removed pests',
      'Hosed pests off',
      'Set trap / barrier',
      'Sprayed selected product',
    ];
    final recheckOptions = const ['Tomorrow', '2 days', '3 days', '1 week'];

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            'Pest sighting log',
            trailing: ProductTag(
              label: '${widget.pestSightings.length}',
              color: widget.pestSightings.isEmpty ? C.muted : C.red,
              background: widget.pestSightings.isEmpty ? C.greySoft : C.redSoft,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Record what you saw before deciding whether to spray.',
            style: TextStyle(
              color: C.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _SprayDropdownCard(
            title: 'Bed',
            value: bed == null ? 'No beds available' : _bedLabel(bed),
            icon: CupertinoIcons.square_grid_2x2,
            options: bedOptions,
            emptyText: 'Add a garden bed first.',
            onSelected: (value) => setState(() {
              selectedBed = _bedNumberForLabel(value);
              selectedCropName = null;
              selectedIssueName = null;
            }),
          ),
          const SizedBox(height: 8),
          _SprayDropdownCard(
            title: 'Crop',
            value: cropName,
            icon: CupertinoIcons.leaf_arrow_circlepath,
            options: cropOptions,
            emptyText: 'No crop choices available.',
            onSelected: (value) => setState(() {
              selectedCropName = value;
              selectedIssueName = null;
            }),
          ),
          const SizedBox(height: 8),
          _SprayDropdownCard(
            title: 'Issue',
            value: issueName,
            icon: CupertinoIcons.ant,
            options: issueOptions,
            emptyText: 'No issues available.',
            onSelected: (value) => setState(() => selectedIssueName = value),
          ),
          const SizedBox(height: 8),
          _SprayDropdownCard(
            title: 'Severity',
            value: pestSeverityLabel(severity),
            icon: CupertinoIcons.chart_bar,
            options: severityOptions,
            emptyText: 'No severity choices available.',
            onSelected: (value) => setState(() {
              severity = PestSeverity.values.firstWhere(
                (item) => pestSeverityLabel(item) == value,
                orElse: () => PestSeverity.medium,
              );
            }),
          ),
          const SizedBox(height: 8),
          _SprayDropdownCard(
            title: 'Action taken',
            value: actionTaken,
            icon: CupertinoIcons.checkmark_circle,
            options: actionOptions,
            emptyText: 'No action choices available.',
            onSelected: (value) => setState(() => actionTaken = value),
          ),
          const SizedBox(height: 8),
          _SprayDropdownCard(
            title: 'Recheck',
            value: _recheckLabel(recheckDays),
            icon: CupertinoIcons.time,
            options: recheckOptions,
            emptyText: 'No recheck choices available.',
            onSelected: (value) => setState(() {
              recheckDays = switch (value) {
                'Tomorrow' => 1,
                '2 days' => 2,
                '1 week' => 7,
                _ => 3,
              };
            }),
          ),
          const SizedBox(height: 8),
          Field(controller: notes, placeholder: 'Notes optional', maxLines: 2),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Save pest sighting',
            onPressed: bed == null
                ? null
                : () {
                    widget.onSave(
                      bed: bed,
                      cropName: cropName,
                      issueName: issueName,
                      severity: severity,
                      actionTaken: actionTaken,
                      recheckDate: DateTime.now().add(
                        Duration(days: recheckDays),
                      ),
                      notes: notes.text,
                    );
                    notes.clear();
                  },
          ),
        ],
      ),
    );
  }

  List<String> _cropOptionsForBed(int? bed) {
    if (bed == null) return const ['Whole bed'];
    final crops = widget.bedCrops[bed] ?? const <VegetableDefinition>[];
    if (crops.isEmpty) return const ['Whole bed'];
    return crops.map((crop) => crop.name).toList(growable: false);
  }

  List<String> _pestIssueOptions(int? bed, String cropName) {
    final values = <String>{};
    final crops = bed == null
        ? const <VegetableDefinition>[]
        : widget.bedCrops[bed] ?? const <VegetableDefinition>[];
    for (final crop in crops) {
      if (cropName != 'Whole bed' && crop.name != cropName) continue;
      values.addAll(crop.commonPests);
      values.addAll(crop.commonDiseases.take(3));
    }
    if (values.isEmpty) {
      values.addAll(const [
        'Aphids',
        'Whitefly',
        'Thrips',
        'Mites',
        'Caterpillars',
        'Slugs / snails',
        'Leaf spots',
        'Powdery mildew',
      ]);
    }
    return values.where((value) => value.trim().isNotEmpty).toList()..sort();
  }

  String _bedLabel(int bedNumber) {
    for (final bed in widget.gardenBeds) {
      if (bed.number == bedNumber) return bed.label;
    }
    return 'Bed $bedNumber';
  }

  int? _bedNumberForLabel(String value) {
    for (final bed in widget.gardenBeds) {
      if (bed.label == value) return bed.number;
    }
    return widget.gardenBeds.isEmpty ? null : widget.gardenBeds.first.number;
  }

  String _recheckLabel(int days) => switch (days) {
        1 => 'Tomorrow',
        2 => '2 days',
        7 => '1 week',
        _ => '3 days',
      };
}

List<String> _sprayIssueOptions({
  required String targetId,
  required List<VegetableDefinition> crops,
  required List<SprayIssueSuggestion> suggestions,
}) {
  final values = <String>{};

  for (final suggestion in suggestions) {
    final issue = suggestion.issue.trim();
    if (issue.isNotEmpty) values.add(issue);
  }

  for (final crop in crops) {
    final source = switch (targetId) {
      'fungus' => crop.commonDiseases,
      'maintain' => crop.maintenanceTips,
      'prevent' => [
          ...crop.commonPests.take(3),
          ...crop.commonDiseases.take(3),
          ...crop.preventativeTips.take(3),
        ],
      _ => crop.commonPests,
    };

    for (final item in source) {
      final clean = item.trim();
      if (clean.isNotEmpty) values.add(clean);
    }
  }

  if (values.isEmpty) {
    values.addAll(
      switch (targetId) {
        'fungus' => const [
            'Powdery mildew',
            'Leaf spot',
            'Blight',
            'Botrytis',
            'Damping off',
          ],
        'maintain' => const [
            'General plant health',
            'Plant stress',
            'Feeding support',
            'Growth support',
          ],
        'prevent' => const [
            'Preventative spray',
            'Routine protection',
            'Before disease pressure',
            'Before pest pressure',
          ],
        _ => const [
            'Aphids',
            'Whitefly',
            'Thrips',
            'Mites',
            'Caterpillars',
            'Slugs / snails',
          ],
      },
    );
  }

  final result = values.toList()..sort();
  return result;
}

List<String> _sprayActionOptions(String targetId) => switch (targetId) {
      'fungus' => const [
          'Sprayed selected product',
          'Removed affected leaves',
          'Improved airflow',
          'Stopped overhead watering',
          'Observed only',
        ],
      'maintain' => const [
          'Fed plants',
          'Watered deeply',
          'Mulched bed',
          'Pruned / tidied plants',
          'Observed only',
        ],
      'prevent' => const [
          'Preventative spray applied',
          'Checked leaves',
          'Removed risky leaves',
          'Improved airflow',
          'Observed only',
        ],
      _ => const [
          'Sprayed selected product',
          'Hosed pests off',
          'Hand removed pests',
          'Removed affected leaves',
          'Set trap / barrier',
          'Observed only',
        ],
    };

String _sprayNotesWithAction({
  required String actionTaken,
  required String notes,
}) {
  final cleanNotes = notes.trim();
  if (cleanNotes.isEmpty) return 'Action: $actionTaken';
  return 'Action: $actionTaken\n$cleanNotes';
}

class _SprayDropdownCard extends StatelessWidget {
  const _SprayDropdownCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.options,
    required this.emptyText,
    required this.onSelected,
  });

  final String title;
  final String value;
  final IconData icon;
  final List<String> options;
  final String emptyText;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SmoothTap(
      onTap: options.isEmpty ? null : () => _showOptions(context),
      semanticsLabel: title,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: C.forestSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: C.forest, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: C.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    options.isEmpty ? emptyText : value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: options.isEmpty ? C.muted : C.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.chevron_down, color: C.muted, size: 18),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(title),
        message: Text('${options.length} choices available'),
        actions: [
          for (final option in options)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                onSelected(option);
              },
              child: Text(option),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({
    required this.products,
    required this.loading,
    required this.message,
    super.key,
  });
  final List<SprayProduct> products;
  final bool loading;
  final String message;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim();
    final filtered = widget.products
        .where((product) => product.matchesQuery(query))
        .toList();
    return AppPage(
      title: 'Products',
      subtitle:
          'Bundled NZ spray products. Verify labels and ACVM details before use.',
      message: widget.message,
      children: [
        CupertinoTextField(
          controller: search,
          placeholder: 'Search product, pest, crop, active ingredient...',
          prefix: const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(CupertinoIcons.search, color: C.muted, size: 19),
          ),
          padding: const EdgeInsets.all(13),
          onChanged: (_) => setState(() {}),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: C.line),
          ),
        ),
        const SizedBox(height: 12),
        SectionTitle(
          'NZ spray product library',
          trailing: Text(
            '${filtered.length}',
            style: const TextStyle(color: C.muted, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CupertinoActivityIndicator(),
            ),
          )
        else if (filtered.isEmpty)
          const EmptyCard('No products match that search.')
        else
          ...filtered.map((product) => ProductTile(product: product)),
      ],
    );
  }
}

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({
    required this.records,
    required this.message,
    required this.highlightedRecordId,
    required this.onDelete,
    super.key,
  });
  final List<SprayRecord> records;
  final String message;
  final int? highlightedRecordId;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Records',
        subtitle: 'Saved sprays, target, product, and safe harvest date.',
        message: message,
        children: [
          if (records.isEmpty)
            const EmptyCard('No spray records yet.')
          else
            ...records.map(
              (record) => RecordCard(
                record: record,
                highlighted: record.id == highlightedRecordId,
                onTap: () => showSprayRecordDetail(context, record),
                onDelete: () => onDelete(record.id),
              ),
            ),
        ],
      );
}

class ProductTile extends StatelessWidget {
  const ProductTile({required this.product, super.key});
  final SprayProduct product;

  @override
  Widget build(BuildContext context) => SmoothTap(
        onTap: () => showSprayProductDetail(context, product),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: C.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  CategoryPill(category: product.category),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${product.brand} | ${product.type}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: C.muted, fontWeight: FontWeight.w700),
              ),
              Text(
                product.activeIngredient,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: C.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ProductTag(
                    label: '${product.withholdingDays} day WHP',
                    color: C.forest,
                    background: C.forestSoft,
                  ),
                  ProductTag(
                    label: 'Re-entry: ${product.reEntryHours} hr',
                    color: C.blue,
                    background: C.blueSoft,
                  ),
                  if (product.reSprayIntervalDays > 0)
                    ProductTag(
                      label: 'Re-spray: ${product.reSprayIntervalDays} days',
                      color: C.amber,
                      background: C.amberSoft,
                    ),
                ],
              ),
              if (product.commonUses.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Uses: ${product.commonUses.take(5).join(', ')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: C.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

class ProductChoice extends StatelessWidget {
  const ProductChoice({
    required this.product,
    required this.selected,
    required this.suggested,
    required this.onTap,
    super.key,
  });
  final SprayProduct product;
  final bool selected;
  final bool suggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final target = targetById(
      product.targets.isEmpty ? 'prevent' : product.targets.first,
    );
    return SmoothTap(
      onTap: onTap,
      semanticsLabel: product.name,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? C.forestSoft : C.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? C.forest : C.line),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: target.softColor,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(target.icon, color: target.color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: C.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.type} | ${product.withholdingDays} day WHP | Re-entry ${product.reEntryHours} hr',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: C.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (product.activeIngredient.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      product.activeIngredient,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: C.forest,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (suggested) ...[
              const SizedBox(width: 8),
              const StatusPill('MATCH', hold: false),
            ],
            const SizedBox(width: 8),
            Icon(
              selected
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              color: selected ? C.forest : C.muted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _SprayAgainstSuggestionsPanel extends StatelessWidget {
  const _SprayAgainstSuggestionsPanel({
    required this.suggestions,
    required this.onUse,
  });

  final List<SprayIssueSuggestion> suggestions;
  final ValueChanged<SprayIssueSuggestion> onUse;

  @override
  Widget build(BuildContext context) => Panel(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              'Likely issues',
              trailing: ProductTag(
                label: '${suggestions.length}',
                color: C.forest,
                background: C.forestSoft,
              ),
            ),
            const SizedBox(height: 10),
            if (suggestions.isEmpty)
              const EmptyInline(
                'Select planted beds first. The app will suggest likely pests, fungus, or support jobs from those crops.',
              )
            else
              ...suggestions.take(6).map(
                    (suggestion) => _SprayIssueSuggestionTile(
                      suggestion: suggestion,
                      onUse: () => onUse(suggestion),
                    ),
                  ),
          ],
        ),
      );
}

class _SprayIssueSuggestionTile extends StatelessWidget {
  const _SprayIssueSuggestionTile({
    required this.suggestion,
    required this.onUse,
  });

  final SprayIssueSuggestion suggestion;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final target = targetById(suggestion.targetId);
    return SmoothTap(
      onTap: onUse,
      semanticsLabel: suggestion.issue,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: target.color.withValues(alpha: .12)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: target.softColor,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: target.color.withValues(alpha: .12)),
              ),
              child: Icon(target.icon, color: target.color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.issue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: C.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    suggestion.cropSummary,
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
            if (suggestion.product != null) ...[
              const SizedBox(width: 8),
              const ProductTag(
                label: 'MATCH',
                color: C.forest,
                background: C.forestSoft,
              ),
            ],
            const SizedBox(width: 6),
            const Icon(CupertinoIcons.chevron_right, color: C.muted, size: 15),
          ],
        ),
      ),
    );
  }
}

class _SprayDecisionPanel extends StatelessWidget {
  const _SprayDecisionPanel({
    required this.product,
    required this.targetId,
    required this.crops,
    required this.beds,
    required this.records,
    required this.products,
  });

  final SprayProduct product;
  final String targetId;
  final List<VegetableDefinition> crops;
  final List<int> beds;
  final List<SprayRecord> records;
  final List<SprayProduct> products;

  @override
  Widget build(BuildContext context) {
    final target = targetById(targetId);
    final coverage = summarizeSprayCoverage(
      product: product,
      targetId: targetId,
      crops: crops,
    );
    final rotation = sprayRotationAdvice(
      product: product,
      records: records,
      products: products,
      beds: beds,
    );
    final followUp = product.reSprayIntervalDays > 0
        ? DateTime.now().add(Duration(days: product.reSprayIntervalDays))
        : null;

    return Panel(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            'Spray check',
            trailing: ProductTag(
              label: coverage.targetMatched ? 'MATCH' : 'CHECK LABEL',
              color: coverage.targetMatched ? C.forest : C.amber,
              background: coverage.targetMatched ? C.forestSoft : C.amberSoft,
            ),
          ),
          const SizedBox(height: 8),
          _SprayInfoRow(
            icon: target.icon,
            color: target.color,
            title: target.title,
            body: coverage.targetMatched
                ? '${product.name} is tagged for ${target.short.toLowerCase()} work.'
                : 'This product is not clearly tagged for ${target.short.toLowerCase()} work.',
          ),
          _SprayInfoRow(
            icon: CupertinoIcons.checkmark_shield,
            color: coverage.coversAllCrops ? C.forest : C.amber,
            title: 'Crop coverage',
            body: crops.isEmpty
                ? 'No planted crop data selected yet.'
                : coverage.coversAllCrops
                    ? 'Likely covers all ${crops.length} selected crop${crops.length == 1 ? '' : 's'}.'
                    : 'Check label for ${coverage.unmatchedCrops.map((crop) => crop.name).join(', ')}.',
          ),
          _SprayInfoRow(
            icon: CupertinoIcons.time,
            color: C.blue,
            title: 'After spraying',
            body: followUp == null
                ? 'No repeat interval set. Use observation before repeating.'
                : 'Next check from ${shortDate(followUp)}. Re-entry ${product.reEntryHours} hr. WHP ${product.withholdingDays} day${product.withholdingDays == 1 ? '' : 's'}.',
          ),
          if (rotation != null)
            _SprayInfoRow(
              icon: rotation.caution
                  ? CupertinoIcons.exclamationmark_triangle_fill
                  : CupertinoIcons.arrow_2_circlepath,
              color: rotation.caution ? C.red : C.amber,
              title: rotation.title,
              body: rotation.body,
            ),
        ],
      ),
    );
  }
}

class _SprayInfoRow extends StatelessWidget {
  const _SprayInfoRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: C.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    body,
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
      );
}

class SprayProductHelperNotes extends StatelessWidget {
  const SprayProductHelperNotes({required this.product, super.key});
  final SprayProduct product;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.soft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.withholdingNote.isNotEmpty)
              Text(
                product.withholdingNote,
                style: const TextStyle(
                  color: C.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            Text(
              'Re-entry: ${product.reEntryHours} hr',
              style: const TextStyle(
                color: C.muted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            if (product.reSprayIntervalDays > 0)
              Text(
                'Re-spray interval: ${product.reSprayIntervalDays} days',
                style: const TextStyle(
                  color: C.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      );
}

void showSprayProductDetail(
  BuildContext context,
  SprayProduct product, {
  List<GardenBed> gardenBeds = const [],
  Map<int, List<VegetableDefinition>> bedCrops = const {},
  List<SprayRecord> records = const [],
}) {
  final usedRecords = records
      .where(
        (record) =>
            record.productId == product.id || record.product == product.name,
      )
      .toList(growable: false);
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => Sheet(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SheetHeader(
            title: product.name,
            subtitle: '${product.brand} | ${product.type}',
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailLine('Category', product.category),
                DetailLine('Active ingredient', product.activeIngredient),
                DetailLine('Withholding days', '${product.withholdingDays}'),
                DetailLine('Withholding note', product.withholdingNote),
                DetailLine('Re-entry hours', '${product.reEntryHours}'),
                DetailLine(
                  'Re-spray interval',
                  product.reSprayIntervalDays > 0
                      ? '${product.reSprayIntervalDays} days'
                      : 'Not set',
                ),
                DetailLine('Common uses', product.commonUses.join(', ')),
                DetailLine('Suitable crops', product.suitableCrops.join(', ')),
                DetailLine(
                  'ACVM number',
                  product.acvmRegistrationNumber.isEmpty
                      ? 'Not filled yet'
                      : product.acvmRegistrationNumber,
                ),
                DetailLine('Source', product.source),
                DetailLine(
                  'Notes',
                  product.notes.isEmpty ? 'None' : product.notes,
                ),
              ],
            ),
          ),
          if (bedCrops.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ProductCoveragePanel(
              product: product,
              gardenBeds: gardenBeds,
              bedCrops: bedCrops,
              records: records,
            ),
          ],
          if (usedRecords.isNotEmpty) ...[
            const SizedBox(height: 14),
            const SectionTitle('Spray records using this product'),
            const SizedBox(height: 8),
            ...usedRecords.map(
              (record) => RecordCard(
                record: record,
                onTap: () => showSprayRecordDetail(context, record),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

void showSprayRecordDetail(BuildContext context, SprayRecord record) {
  final target = targetById(record.targetId);
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => Sheet(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SheetHeader(
            title: 'Spray record ${record.id}',
            subtitle: '${target.short} | ${shortDate(record.date)}',
          ),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailLine(
                  'Beds',
                  record.beds.map((bed) => 'Bed $bed').join(', '),
                ),
                DetailLine('Crops', record.crops.join(', ')),
                DetailLine('Product', record.product),
                DetailLine('Target', target.title),
                DetailLine(
                  'Reason',
                  record.reason.isEmpty ? '-' : record.reason,
                ),
                DetailLine('Notes', record.notes.isEmpty ? '-' : record.notes),
                DetailLine('Sprayed', shortDate(record.date)),
                DetailLine('Safe harvest', shortDate(record.safeDate)),
                DetailLine(
                  'Withholding status',
                  record.onHold
                      ? _recordRemainingHoldLabel(record)
                      : 'Safe now',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProductCoveragePanel extends StatelessWidget {
  const _ProductCoveragePanel({
    required this.product,
    required this.gardenBeds,
    required this.bedCrops,
    required this.records,
  });

  final SprayProduct product;
  final List<GardenBed> gardenBeds;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final List<SprayRecord> records;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (final bed in gardenBeds) {
      final crops = bedCrops[bed.number] ?? const <VegetableDefinition>[];
      for (final crop in crops) {
        if (!_productLikelyCoversCrop(product, crop)) continue;
        final summary = bedSpraySummary(records, bed.number);
        rows.add(
          _ProductCoverageRow(
            bed: bed,
            crop: crop,
            summary: summary,
            product: product,
          ),
        );
      }
    }

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            'Likely bed coverage',
            trailing: ProductTag(
              label: '${product.withholdingDays} day WHP',
              color: C.forest,
              background: C.forestSoft,
            ),
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            const EmptyInline(
              'No logged crops clearly match this product label text.',
            )
          else
            ...rows,
        ],
      ),
    );
  }
}

class _ProductCoverageRow extends StatelessWidget {
  const _ProductCoverageRow({
    required this.bed,
    required this.crop,
    required this.summary,
    required this.product,
  });

  final GardenBed bed;
  final VegetableDefinition crop;
  final BedSpraySummary summary;
  final SprayProduct product;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: C.canvas,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.line),
        ),
        child: Row(
          children: [
            CropIcon(crop.iconPath, size: 28),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${bed.label} | ${crop.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: C.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    product.targets
                        .map(targetById)
                        .map((target) => target.short)
                        .join(', '),
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
            StatusPill(
              summary.onHold ? 'HOLD' : 'SAFE',
              hold: summary.onHold,
            ),
          ],
        ),
      );
}

String _recordRemainingHoldLabel(SprayRecord record) {
  final remaining = record.safeDate.difference(DateTime.now()).inDays + 1;
  final days = remaining < 1 ? 1 : remaining;
  return 'On hold for $days more day${days == 1 ? '' : 's'}';
}

bool _productLikelyCoversCrop(SprayProduct product, VegetableDefinition crop) {
  final text = product.searchText;
  if (text.contains(crop.name.toLowerCase())) return true;
  if (text.contains(familyById(crop.familyId).name.toLowerCase())) return true;
  if (text.contains('vegetable') || text.contains('edible')) return true;
  final issues = [...crop.commonPests, ...crop.commonDiseases];
  return issues.any((issue) => text.contains(issue.toLowerCase()));
}
