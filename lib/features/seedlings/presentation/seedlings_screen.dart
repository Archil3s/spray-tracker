part of '../../../main.dart';

class SeedlingsScreen extends StatefulWidget {
  const SeedlingsScreen({
    required this.batches,
    required this.gardenBeds,
    required this.onAddBatch,
    required this.onUpdateStatus,
    required this.onPlantOut,
    required this.message,
    super.key,
  });

  final List<SeedlingBatch> batches;
  final List<GardenBed> gardenBeds;
  final void Function({
    required VegetableDefinition crop,
    required String varietyName,
    required int quantityStarted,
    required DateTime dateStarted,
    required String location,
    required String method,
    required String notes,
  }) onAddBatch;
  final void Function(int id, SeedlingStatus status) onUpdateStatus;
  final void Function(int id, int bed) onPlantOut;
  final String message;

  @override
  State<SeedlingsScreen> createState() => _SeedlingsScreenState();
}

class _SeedlingsScreenState extends State<SeedlingsScreen> {
  bool adding = false;
  PlantingRecommendationType? calendarFilter;
  VegetableDefinition? preselectedCrop;

  @override
  Widget build(BuildContext context) {
    final active = widget.batches.where((batch) => batch.active).toList();
    final readySoon = active.where(_seedlingReadySoon).toList();
    final finished = widget.batches.where((batch) => !batch.active).take(4);

    return AppPage(
      title: 'Seedlings',
      subtitle: 'Start trays, track germination, and move plants into beds.',
      message: widget.message,
      children: [
        const SectionTitle(
          'What can I start now?',
          trailing: ProductTag(
            label: 'Blenheim timing',
            color: C.forest,
            background: C.forestSoft,
          ),
        ),
        const SizedBox(height: 8),
        _PlantingCalendarFilterRow(
          selected: calendarFilter,
          onChanged: (value) => setState(() => calendarFilter = value),
        ),
        const SizedBox(height: 10),
        Builder(
          builder: (context) {
            final recommendations = plantingRecommendationsForNow(
              now: DateTime.now(),
              frostRisk: DateTime.now().month >= 5 && DateTime.now().month <= 9,
            )
                .where((item) {
                  return calendarFilter == null || item.type == calendarFilter;
                })
                .take(8)
                .toList(growable: false);
            if (recommendations.isEmpty) {
              return const EmptyCard('No crops match this filter right now.');
            }
            return Column(
              children: [
                for (final recommendation in recommendations)
                  _PlantingRecommendationCard(
                    recommendation: recommendation,
                    onStartBatch: (crop) => setState(() {
                      preselectedCrop = crop;
                      adding = true;
                    }),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        SectionTitle(
          'Ready soon',
          trailing: ProductTag(
            label: '${readySoon.length}',
            color: readySoon.isEmpty ? C.muted : C.amber,
            background: readySoon.isEmpty ? C.greySoft : C.amberSoft,
          ),
        ),
        const SizedBox(height: 8),
        if (readySoon.isEmpty)
          const EmptyCard('No seedling batches need urgent action yet.')
        else
          ...readySoon.map(
            (batch) => SeedlingBatchCard(
              batch: batch,
              gardenBeds: widget.gardenBeds,
              onUpdateStatus: widget.onUpdateStatus,
              onPlantOut: widget.onPlantOut,
            ),
          ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: adding ? 'Close seedling form' : 'Add seedling batch',
          onPressed: () => setState(() => adding = !adding),
        ),
        if (adding) ...[
          const SizedBox(height: 12),
          _AddSeedlingBatchPanel(
            initialCrop: preselectedCrop,
            onSave: (args) {
              widget.onAddBatch(
                crop: args.crop,
                varietyName: args.varietyName,
                quantityStarted: args.quantityStarted,
                dateStarted: args.dateStarted,
                location: args.location,
                method: args.method,
                notes: args.notes,
              );
              setState(() {
                adding = false;
                preselectedCrop = null;
              });
            },
          ),
        ],
        const SizedBox(height: 18),
        SectionTitle(
          'Active seedlings',
          trailing: ProductTag(
            label: '${active.length}',
            color: C.forest,
            background: C.forestSoft,
          ),
        ),
        const SizedBox(height: 8),
        if (active.isEmpty)
          const EmptyCard('No active seedlings yet. Add a batch to begin.')
        else
          ...active.map(
            (batch) => SeedlingBatchCard(
              batch: batch,
              gardenBeds: widget.gardenBeds,
              onUpdateStatus: widget.onUpdateStatus,
              onPlantOut: widget.onPlantOut,
            ),
          ),
        if (finished.isNotEmpty) ...[
          const SizedBox(height: 18),
          const SectionTitle('Finished batches'),
          const SizedBox(height: 8),
          ...finished.map(
            (batch) => SeedlingBatchCard(
              batch: batch,
              gardenBeds: widget.gardenBeds,
              onUpdateStatus: widget.onUpdateStatus,
              onPlantOut: widget.onPlantOut,
            ),
          ),
        ],
      ],
    );
  }

  bool _seedlingReadySoon(SeedlingBatch batch) {
    final now = DateTime.now();
    if (batch.status == SeedlingStatus.readyToPlantOut ||
        batch.status == SeedlingStatus.hardeningOff) {
      return true;
    }
    if (batch.status == SeedlingStatus.started &&
        !batch.germinationStart.isAfter(now.add(const Duration(days: 2)))) {
      return true;
    }
    return !batch.targetPlantOutDate.isAfter(now.add(const Duration(days: 7)));
  }
}

class SeedlingBatchCard extends StatelessWidget {
  const SeedlingBatchCard({
    required this.batch,
    required this.gardenBeds,
    required this.onUpdateStatus,
    required this.onPlantOut,
    super.key,
  });

  final SeedlingBatch batch;
  final List<GardenBed> gardenBeds;
  final void Function(int id, SeedlingStatus status) onUpdateStatus;
  final void Function(int id, int bed) onPlantOut;

  @override
  Widget build(BuildContext context) {
    final crop = vegetableLibrary.firstWhere(
      (item) => item.id == batch.cropId,
      orElse: () => vegetableLibrary.first,
    );
    final status = seedlingStatusLabel(batch.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: cardDecoration(
        color: batch.status == SeedlingStatus.failed ? C.redSoft : C.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CropIcon(crop.iconPath, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch.varietyName.isEmpty
                          ? batch.cropName
                          : '${batch.cropName} | ${batch.varietyName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: C.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${batch.quantityAlive}/${batch.quantityStarted} alive | ${batch.method} | ${batch.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: C.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(status.toUpperCase(),
                  hold: batch.status == SeedlingStatus.failed),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              ProductTag(
                label: 'Started ${shortDate(batch.dateStarted)}',
                color: C.forest,
                background: C.forestSoft,
              ),
              ProductTag(
                label:
                    'Germ ${shortDate(batch.germinationStart)}-${shortDate(batch.germinationEnd)}',
                color: C.blue,
                background: C.blueSoft,
              ),
              ProductTag(
                label: 'Plant out ${shortDate(batch.targetPlantOutDate)}',
                color: C.amber,
                background: C.amberSoft,
              ),
              ProductTag(
                label: _harvestEstimateLabel(crop, batch.dateStarted),
                color: C.forest,
                background: C.forestSoft,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _seedlingNextAction(batch),
            style: const TextStyle(
              color: C.ink,
              height: 1.25,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Update status',
                  onPressed: () => _showStatusSheet(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  label: 'Plant into bed',
                  onPressed: batch.active && gardenBeds.isNotEmpty
                      ? () => _showPlantOutSheet(context)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _seedlingNextAction(SeedlingBatch batch) {
    final now = DateTime.now();
    return switch (batch.status) {
      SeedlingStatus.started => now.isBefore(batch.germinationStart)
          ? 'Next: keep evenly moist and check germination from ${shortDate(batch.germinationStart)}.'
          : 'Next: check for germination and update status when seedlings emerge.',
      SeedlingStatus.germinated =>
        'Next: watch for true leaves, then prick out or pot up.',
      SeedlingStatus.prickedOut => 'Next: keep sheltered while roots recover.',
      SeedlingStatus.pottedUp =>
        'Next: feed lightly and prepare for hardening off.',
      SeedlingStatus.hardeningOff =>
        'Next: increase outdoor time, then plant out when sturdy.',
      SeedlingStatus.readyToPlantOut => 'Next: choose a bed and plant out.',
      SeedlingStatus.plantedOut => batch.plantedOutBed == null
          ? 'Planted out.'
          : 'Planted into Bed ${batch.plantedOutBed} on ${shortDate(batch.plantedOutDate ?? now)}.',
      SeedlingStatus.failed =>
        'Batch marked failed. Start a replacement batch if needed.',
    };
  }

  String _harvestEstimateLabel(VegetableDefinition crop, DateTime started) {
    final harvest = GrowTimeDefaults.harvestWindowFor(crop);
    final early = started.add(Duration(days: harvest.min));
    final late = started.add(Duration(days: harvest.max));
    return 'Harvest ${shortDate(early)}-${shortDate(late)}';
  }

  void _showStatusSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Update seedling status'),
        message: Text(batch.cropName),
        actions: [
          for (final status in SeedlingStatus.values)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                onUpdateStatus(batch.id, status);
              },
              child: Text(seedlingStatusLabel(status)),
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

  void _showPlantOutSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Plant into bed'),
        message: Text(batch.cropName),
        actions: [
          for (final bed in gardenBeds)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                onPlantOut(batch.id, bed.number);
              },
              child: Text(bed.label),
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

class _PlantingCalendarFilterRow extends StatelessWidget {
  const _PlantingCalendarFilterRow({
    required this.selected,
    required this.onChanged,
  });

  final PlantingRecommendationType? selected;
  final ValueChanged<PlantingRecommendationType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, PlantingRecommendationType? value})>[
      (label: 'All', value: null),
      (label: 'Start indoors', value: PlantingRecommendationType.startIndoors),
      (label: 'Direct sow', value: PlantingRecommendationType.directSow),
      (label: 'Plant out', value: PlantingRecommendationType.plantOut),
      (label: 'Too early', value: PlantingRecommendationType.wait),
      (label: 'Late', value: PlantingRecommendationType.late),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: NumberChip(
                label: item.label,
                selected: selected == item.value,
                onTap: () => onChanged(item.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlantingRecommendationCard extends StatelessWidget {
  const _PlantingRecommendationCard({
    required this.recommendation,
    required this.onStartBatch,
  });

  final CropPlantingRecommendation recommendation;
  final ValueChanged<VegetableDefinition> onStartBatch;

  @override
  Widget build(BuildContext context) {
    final crop = recommendation.crop;
    final grow = GrowTimeDefaults.harvestWindowFor(crop);
    final type = recommendation.type;
    final isHold = type == PlantingRecommendationType.wait ||
        type == PlantingRecommendationType.late;
    final color = switch (type) {
      PlantingRecommendationType.startIndoors => C.blue,
      PlantingRecommendationType.directSow => C.forest,
      PlantingRecommendationType.plantOut => C.amber,
      PlantingRecommendationType.wait => C.muted,
      PlantingRecommendationType.late => C.red,
    };
    final background = switch (type) {
      PlantingRecommendationType.startIndoors => C.blueSoft,
      PlantingRecommendationType.directSow => C.forestSoft,
      PlantingRecommendationType.plantOut => C.amberSoft,
      PlantingRecommendationType.wait => C.greySoft,
      PlantingRecommendationType.late => C.redSoft,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CropIcon(crop.iconPath, size: 42),
              const SizedBox(width: 12),
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
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      recommendation.detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: C.muted,
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(recommendation.action.toUpperCase(), hold: isHold),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              ProductTag(
                label: recommendation.rule.preferredStartMethod,
                color: color,
                background: background,
              ),
              ProductTag(
                label: 'Harvest ${grow.min}-${grow.max} days',
                color: C.forest,
                background: C.forestSoft,
              ),
              if (recommendation.rule.frostSensitive)
                const ProductTag(
                  label: 'Frost sensitive',
                  color: C.amber,
                  background: C.amberSoft,
                ),
            ],
          ),
          if (recommendation.frostWarning.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              recommendation.frostWarning,
              style: const TextStyle(
                color: C.amber,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Start batch',
            onPressed: isHold ? null : () => onStartBatch(crop),
          ),
        ],
      ),
    );
  }
}

class _AddSeedlingBatchPanel extends StatefulWidget {
  const _AddSeedlingBatchPanel({required this.onSave, this.initialCrop});

  final ValueChanged<_SeedlingFormResult> onSave;
  final VegetableDefinition? initialCrop;

  @override
  State<_AddSeedlingBatchPanel> createState() => _AddSeedlingBatchPanelState();
}

class _AddSeedlingBatchPanelState extends State<_AddSeedlingBatchPanel> {
  late VegetableDefinition crop = widget.initialCrop ?? vegetableLibrary.first;
  String varietyName = '';
  String method = 'Tray';
  String location = 'Windowsill';
  int quantity = 12;
  int startOffsetDays = 0;
  late Future<GrowTimeEstimate> growTimeEstimate =
      GrowTimeService.instance.estimateFor(crop);
  final notes = TextEditingController();

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final varieties = crop.varieties.map((item) => item.name).toList();
    final dateStarted =
        DateTime.now().subtract(Duration(days: startOffsetDays));
    final germination = seedlingGerminationWindowFor(crop);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('New seedling batch'),
          const SizedBox(height: 10),
          _SeedlingPickerCard(
            title: 'Crop',
            value: crop.name,
            icon: CupertinoIcons.leaf_arrow_circlepath,
            options: vegetableLibrary.map((item) => item.name).toList(),
            onSelected: (value) => setState(() {
              crop = vegetableLibrary.firstWhere((item) => item.name == value);
              varietyName = '';
              growTimeEstimate = GrowTimeService.instance.estimateFor(crop);
            }),
          ),
          const SizedBox(height: 8),
          _SeedlingPickerCard(
            title: 'Variety',
            value: varietyName.isEmpty ? 'No variety selected' : varietyName,
            icon: CupertinoIcons.tag,
            options: varieties.isEmpty
                ? const ['No variety selected']
                : ['No variety selected', ...varieties],
            onSelected: (value) => setState(() {
              varietyName = value == 'No variety selected' ? '' : value;
            }),
          ),
          const SizedBox(height: 8),
          _SeedlingPickerCard(
            title: 'Method',
            value: method,
            icon: CupertinoIcons.tray,
            options: const [
              'Tray',
              'Pot',
              'Cell tray',
              'Paper towel',
              'Direct sow'
            ],
            onSelected: (value) => setState(() => method = value),
          ),
          const SizedBox(height: 8),
          _SeedlingPickerCard(
            title: 'Location',
            value: location,
            icon: CupertinoIcons.house,
            options: const [
              'Indoors',
              'Greenhouse',
              'Windowsill',
              'Heat mat',
              'Outside'
            ],
            onSelected: (value) => setState(() => location = value),
          ),
          const SizedBox(height: 8),
          _SeedlingPickerCard(
            title: 'Date started',
            value: _startDateLabel(startOffsetDays),
            icon: CupertinoIcons.calendar,
            options: const ['Today', 'Yesterday', '3 days ago', '1 week ago'],
            onSelected: (value) =>
                setState(() => startOffsetDays = _startOffset(value)),
          ),
          const SizedBox(height: 8),
          Stepper(
            label: 'Quantity started',
            value: quantity,
            minus: quantity > 1 ? () => setState(() => quantity--) : null,
            plus: () => setState(() => quantity++),
          ),
          const SizedBox(height: 8),
          FutureBuilder<GrowTimeEstimate>(
            future: growTimeEstimate,
            builder: (context, snapshot) {
              final estimate = snapshot.data;
              final harvestLabel = estimate == null
                  ? 'Harvest estimate loading'
                  : 'Harvest ${estimate.harvestDaysMin}-${estimate.harvestDaysMax} days';
              final sourceLabel = estimate?.source ?? 'Loading grow time';
              return Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  ProductTag(
                    label: estimate == null
                        ? 'Expected germination ${germination.min}-${germination.max} days'
                        : 'Germination ${estimate.germinationDaysMin}-${estimate.germinationDaysMax} days',
                    color: C.blue,
                    background: C.blueSoft,
                  ),
                  ProductTag(
                    label: harvestLabel,
                    color: C.forest,
                    background: C.forestSoft,
                  ),
                  ProductTag(
                    label: sourceLabel,
                    color: estimate?.source.contains('Perenual') == true
                        ? C.amber
                        : C.muted,
                    background: estimate?.source.contains('Perenual') == true
                        ? C.amberSoft
                        : C.greySoft,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          FutureBuilder<GrowTimeEstimate>(
            future: growTimeEstimate,
            builder: (context, snapshot) {
              final estimate = snapshot.data;
              if (estimate == null) return const SizedBox.shrink();
              return Text(
                estimate.note,
                style: const TextStyle(
                  color: C.muted,
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Field(controller: notes, placeholder: 'Notes optional', maxLines: 2),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Save seedling batch',
            onPressed: () => widget.onSave(
              _SeedlingFormResult(
                crop: crop,
                varietyName: varietyName,
                quantityStarted: quantity,
                dateStarted: dateStarted,
                location: location,
                method: method,
                notes: notes.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _startDateLabel(int offset) => switch (offset) {
        0 => 'Today',
        1 => 'Yesterday',
        3 => '3 days ago',
        _ => '1 week ago',
      };

  int _startOffset(String value) => switch (value) {
        'Today' => 0,
        'Yesterday' => 1,
        '3 days ago' => 3,
        _ => 7,
      };
}

class _SeedlingFormResult {
  const _SeedlingFormResult({
    required this.crop,
    required this.varietyName,
    required this.quantityStarted,
    required this.dateStarted,
    required this.location,
    required this.method,
    required this.notes,
  });

  final VegetableDefinition crop;
  final String varietyName;
  final int quantityStarted;
  final DateTime dateStarted;
  final String location;
  final String method;
  final String notes;
}

class _SeedlingPickerCard extends StatelessWidget {
  const _SeedlingPickerCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.options,
    required this.onSelected,
  });

  final String title;
  final String value;
  final IconData icon;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SmoothTap(
        onTap: () => _showOptions(context),
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
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: C.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_down, color: C.muted, size: 18),
            ],
          ),
        ),
      );

  void _showOptions(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(title),
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
