part of '../../../main.dart';

List<SprayProduct> fallbackProducts() => const [
      SprayProduct(
        id: 'fallback_neem_oil',
        name: 'Neem Oil',
        brand: 'Fallback',
        type: 'Pest control',
        activeIngredient: 'Neem oil / Azadirachtin',
        withholdingDays: 0,
        withholdingNote: 'Fallback only - check label before harvest',
        reEntryHours: 1,
        category: 'organic',
        commonUses: ['aphids', 'mites', 'whitefly', 'scale'],
        suitableCrops: ['vegetables', 'herbs', 'fruit trees'],
        reSprayIntervalDays: 7,
        acvmRegistrationNumber: '',
        source: 'Fallback sample',
        notes: 'ACVM product dataset did not load.',
      ),
    ];

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.clearBeds,
    required this.holdBeds,
    required this.plantedBeds,
    required this.cropPlacements,
    required this.gardenBeds,
    required this.bedCrops,
    required this.records,
    required this.pestSightings,
    required this.products,
    required this.message,
    required this.sprayConditions,
    required this.gardenRisks,
    required this.onPlanSpray,
    required this.onOpenProducts,
    required this.onOpenBed,
    required this.onOpenRecord,
    required this.onOpenPestProfiles,
    required this.onPestFollowUp,
    required this.onSaveBackup,
    required this.onRestoreBackup,
    required this.onReloadBackup,
    super.key,
  });

  final int clearBeds;
  final int holdBeds;
  final int plantedBeds;
  final int cropPlacements;
  final List<GardenBed> gardenBeds;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final List<SprayRecord> records;
  final List<PestSighting> pestSightings;
  final List<SprayProduct> products;
  final String message;
  final Future<SprayConditionSummary> sprayConditions;
  final Future<GardenRiskSummary> gardenRisks;
  final VoidCallback onPlanSpray;
  final VoidCallback onOpenProducts;
  final ValueChanged<int> onOpenBed;
  final ValueChanged<SprayRecord> onOpenRecord;
  final VoidCallback onOpenPestProfiles;
  final void Function({required int id, required String result}) onPestFollowUp;
  final VoidCallback onSaveBackup;
  final VoidCallback onRestoreBackup;
  final VoidCallback onReloadBackup;

  @override
  Widget build(BuildContext context) {
    final nextActiveRecord = nextActiveSprayRecord(records);
    return AppPage(
      title: 'Fieldbook',
      subtitle: 'Spray records, product safety, and harvest holds.',
      message: message,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: C.forest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Today',
                style: TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Spray status',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: HeroMetric(
                      label: 'CLEAR BEDS',
                      value: '$clearBeds',
                      color: CupertinoColors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HeroMetric(
                      label: 'ON HOLD',
                      value: '$holdBeds',
                      color: C.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '$plantedBeds beds planted | $cropPlacements crop placements | ${products.length} NZ products',
                style: const TextStyle(
                  color: Color(0xDFFFFFFF),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                      onPressed: onPlanSpray,
                      child: const Text(
                        'Plan a spray',
                        style: TextStyle(
                          color: C.forest,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CupertinoButton(
                      color: const Color(0x18FFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      onPressed: onOpenProducts,
                      child: const Text(
                        'Protect',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SprayConditionBanner(sprayConditions: sprayConditions),
        const SizedBox(height: 10),
        GardenRiskPanel(
          gardenRisks: gardenRisks,
          onPestPressureTap: onOpenPestProfiles,
        ),
        const SizedBox(height: 18),
        SectionTitle(
          'Beds',
          trailing: Text(
            '${gardenBeds.length}',
            style: const TextStyle(color: C.muted, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 8),
        _HomeBedOverview(
          beds: gardenBeds,
          bedCrops: bedCrops,
          records: records,
          onOpenBed: onOpenBed,
          onOpenRecord: onOpenRecord,
        ),
        const SizedBox(height: 18),
        const SectionTitle('Next safe harvest'),
        const SizedBox(height: 8),
        if (nextActiveRecord == null)
          const EmptyCard('No active withholding periods.')
        else
          RecordCard(
            record: nextActiveRecord,
            onTap: () => onOpenRecord(nextActiveRecord),
          ),
        const SizedBox(height: 18),
        const SectionTitle('Due to recheck'),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final due = pestSightings
                .where((sighting) => pestSightingNeedsRecheck(sighting))
                .toList(growable: false);
            if (due.isEmpty) {
              return const EmptyCard('No pest rechecks due today.');
            }
            return Column(
              children: [
                for (final sighting in due.take(4))
                  _PestRecheckDueCard(
                    sighting: sighting,
                    onFollowUp: onPestFollowUp,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        const SectionTitle('Recent pest sightings'),
        const SizedBox(height: 8),
        if (pestSightings.isEmpty)
          const EmptyCard('No pest sightings logged yet.')
        else
          ...pestSightings.take(3).map(
                (sighting) => _PestSightingHomeCard(sighting: sighting),
              ),
        const SizedBox(height: 18),
        const SectionTitle('Recent activity'),
        const SizedBox(height: 8),
        if (records.isEmpty)
          const EmptyCard(
            'No spray records yet. Use Spray Log to test the new product library.',
          )
        else
          ...records.take(3).map(
                (record) => RecordCard(
                  record: record,
                  onTap: () => onOpenRecord(record),
                ),
              ),
        const SizedBox(height: 18),
        _GardenBackupPanel(
          onSaveBackup: onSaveBackup,
          onRestoreBackup: onRestoreBackup,
          onReloadBackup: onReloadBackup,
        ),
      ],
    );
  }
}

class _PestRecheckDueCard extends StatelessWidget {
  const _PestRecheckDueCard({
    required this.sighting,
    required this.onFollowUp,
  });

  final PestSighting sighting;
  final void Function({required int id, required String result}) onFollowUp;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: cardDecoration(color: C.amberSoft),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: C.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: C.line),
                  ),
                  child: const Icon(
                    CupertinoIcons.time,
                    color: C.amber,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${sighting.issueName} | Bed ${sighting.bed}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: C.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${sighting.cropName} | '
                        '${pestSeverityLabel(sighting.severity)} severity',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: C.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Original action: ${sighting.actionTaken}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: C.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                StatusPill(
                  pestSightingStatusLabel(sighting.status).toUpperCase(),
                  hold: true,
                ),
              ],
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Record follow-up',
              onPressed: () => _showFollowUpMenu(context),
            ),
          ],
        ),
      );

  void _showFollowUpMenu(BuildContext context) {
    const options = [
      'Pest gone',
      'Less pest pressure',
      'Same as before',
      'Worse',
      'Crop damaged',
    ];
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Recheck result'),
        message: Text(
          '${sighting.issueName} on ${sighting.cropName}, Bed ${sighting.bed}',
        ),
        actions: [
          for (final option in options)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                onFollowUp(id: sighting.id, result: option);
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

class _PestSightingHomeCard extends StatelessWidget {
  const _PestSightingHomeCard({required this.sighting});

  final PestSighting sighting;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: C.redSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: C.red,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${sighting.issueName} | Bed ${sighting.bed}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: C.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${sighting.cropName} | '
                    '${pestSeverityLabel(sighting.severity)} | '
                    '${pestSightingStatusLabel(sighting.status)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: C.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    sighting.followUpResult == null
                        ? 'Action: ${sighting.actionTaken} | '
                            'recheck ${shortDate(sighting.recheckDate)}'
                        : 'Follow-up: ${sighting.followUpResult} | '
                            'next ${shortDate(sighting.recheckDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: C.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            StatusPill(
              pestSightingStatusLabel(sighting.status).toUpperCase(),
              hold: sighting.status != PestSightingStatus.resolved,
            ),
          ],
        ),
      );
}

class _GardenBackupPanel extends StatelessWidget {
  const _GardenBackupPanel({
    required this.onSaveBackup,
    required this.onRestoreBackup,
    required this.onReloadBackup,
  });

  final VoidCallback onSaveBackup;
  final VoidCallback onRestoreBackup;
  final VoidCallback onReloadBackup;

  @override
  Widget build(BuildContext context) => Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(CupertinoIcons.archivebox, color: C.forest, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Save / load',
                    style: TextStyle(
                      color: C.forest,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Saves the full garden, beds, crops, spray records, and layout to a portable .spraygarden file.',
              style: TextStyle(
                color: C.muted,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Save file',
                    onPressed: onSaveBackup,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SecondaryButton(
                    label: 'Load file',
                    onPressed: onRestoreBackup,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'Reload phone save',
              onPressed: onReloadBackup,
            ),
          ],
        ),
      );
}

class _HomeBedOverview extends StatelessWidget {
  const _HomeBedOverview({
    required this.beds,
    required this.bedCrops,
    required this.records,
    required this.onOpenBed,
    required this.onOpenRecord,
  });

  final List<GardenBed> beds;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final List<SprayRecord> records;
  final ValueChanged<int> onOpenBed;
  final ValueChanged<SprayRecord> onOpenRecord;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 118,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: beds.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final bed = beds[index];
            final crops = bedCrops[bed.number] ?? const <VegetableDefinition>[];
            final summary = bedSpraySummary(records, bed.number);
            return CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => onOpenBed(bed.number),
              child: Container(
                width: 148,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: C.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: summary.onHold ? C.amber : C.line,
                    width: summary.onHold ? 1.6 : 1,
                  ),
                  boxShadow: softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            bed.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: C.forest,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _HomeBedStatusLink(
                          summary: summary,
                          onOpenRecord: onOpenRecord,
                        ),
                      ],
                    ),
                    Text(
                      crops.isEmpty
                          ? 'No vegetables'
                          : crops.map((crop) => crop.name).take(2).join(', '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: C.ink,
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${crops.length} crop${crops.length == 1 ? '' : 's'} logged',
                      style: const TextStyle(
                        color: C.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
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

class _HomeBedStatusLink extends StatelessWidget {
  const _HomeBedStatusLink({
    required this.summary,
    required this.onOpenRecord,
  });

  final BedSpraySummary summary;
  final ValueChanged<SprayRecord> onOpenRecord;

  @override
  Widget build(BuildContext context) {
    final pill = StatusPill(
      summary.onHold ? 'HOLD' : 'SAFE',
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
