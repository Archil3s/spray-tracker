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
    required this.records,
    required this.products,
    required this.message,
    required this.sprayConditions,
    required this.gardenRisks,
    required this.onPlanSpray,
    required this.onOpenProducts,
    super.key,
  });

  final int clearBeds;
  final int holdBeds;
  final int plantedBeds;
  final int cropPlacements;
  final List<SprayRecord> records;
  final List<SprayProduct> products;
  final String message;
  final Future<SprayConditionSummary> sprayConditions;
  final Future<GardenRiskSummary> gardenRisks;
  final VoidCallback onPlanSpray;
  final VoidCallback onOpenProducts;

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
        GardenRiskPanel(gardenRisks: gardenRisks),
        const SizedBox(height: 18),
        const SectionTitle('Next safe harvest'),
        const SizedBox(height: 8),
        if (nextActiveRecord == null)
          const EmptyCard('No active withholding periods.')
        else
          RecordCard(record: nextActiveRecord),
        const SizedBox(height: 18),
        const SectionTitle('Recent activity'),
        const SizedBox(height: 8),
        if (records.isEmpty)
          const EmptyCard(
            'No spray records yet. Use Spray Log to test the new product library.',
          )
        else
          ...records.take(3).map((record) => RecordCard(record: record)),
      ],
    );
  }
}
