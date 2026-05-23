part of '../../../main.dart';

enum _ProtectionView { calendar, pests, fungus, products }

class ProtectionScreen extends StatefulWidget {
  const ProtectionScreen({
    required this.gardenBeds,
    required this.bedCrops,
    required this.records,
    required this.products,
    required this.loading,
    required this.message,
    required this.gardenRisks,
    required this.onPlanSpray,
    super.key,
  });

  final List<GardenBed> gardenBeds;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final List<SprayRecord> records;
  final List<SprayProduct> products;
  final bool loading;
  final String message;
  final Future<GardenRiskSummary> gardenRisks;
  final VoidCallback onPlanSpray;

  @override
  State<ProtectionScreen> createState() => _ProtectionScreenState();
}

class _ProtectionScreenState extends State<ProtectionScreen> {
  _ProtectionView view = _ProtectionView.calendar;
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Protect',
        subtitle: 'Preventative calendar, pest pressure, fungus, and products.',
        message: widget.message,
        children: [
          CupertinoSlidingSegmentedControl<_ProtectionView>(
            groupValue: view,
            children: const {
              _ProtectionView.calendar: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Calendar'),
              ),
              _ProtectionView.pests: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Pests'),
              ),
              _ProtectionView.fungus: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Fungus'),
              ),
              _ProtectionView.products: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Products'),
              ),
            },
            onValueChanged: (value) {
              if (value == null) return;
              setState(() {
                view = value;
                search.clear();
              });
            },
          ),
          const SizedBox(height: 14),
          if (view == _ProtectionView.calendar)
            _ProtectionCalendarView(
              beds: widget.gardenBeds,
              bedCrops: widget.bedCrops,
              records: widget.records,
              products: widget.products,
              gardenRisks: widget.gardenRisks,
              onPlanSpray: widget.onPlanSpray,
            )
          else if (view == _ProtectionView.pests)
            _IssueLibraryView(
              target: ProtectionTarget.pest,
              products: widget.products,
              bedCrops: widget.bedCrops,
              search: search,
              onSearchChanged: () => setState(() {}),
            )
          else if (view == _ProtectionView.fungus)
            _IssueLibraryView(
              target: ProtectionTarget.fungus,
              products: widget.products,
              bedCrops: widget.bedCrops,
              search: search,
              onSearchChanged: () => setState(() {}),
            )
          else
            _ProtectionProductsView(
              products: widget.products,
              loading: widget.loading,
              search: search,
              onSearchChanged: () => setState(() {}),
            ),
        ],
      );
}

class _ProtectionCalendarView extends StatelessWidget {
  const _ProtectionCalendarView({
    required this.beds,
    required this.bedCrops,
    required this.records,
    required this.products,
    required this.gardenRisks,
    required this.onPlanSpray,
  });

  final List<GardenBed> beds;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final List<SprayRecord> records;
  final List<SprayProduct> products;
  final Future<GardenRiskSummary> gardenRisks;
  final VoidCallback onPlanSpray;

  @override
  Widget build(BuildContext context) {
    final plantedCount =
        bedCrops.values.fold<int>(0, (total, crops) => total + crops.length);
    return FutureBuilder<GardenRiskSummary>(
      future: gardenRisks,
      builder: (context, snapshot) {
        final risks = snapshot.data;
        final items = generatePreventativeCalendar(
          beds: beds,
          bedCrops: bedCrops,
          records: records,
          products: products,
          risks: risks,
        );
        final due =
            items.where((item) => item.status == ProtectionStatus.due).length;
        final blocked = items
            .where((item) => item.status == ProtectionStatus.blocked)
            .length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Panel(
              child: Row(
                children: [
                  Expanded(
                    child: HeroMetric(
                      label: 'PLANTS TRACKED',
                      value: '$plantedCount',
                      color: C.forest,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HeroMetric(
                      label: 'DUE NOW',
                      value: '$due',
                      color: due > 0 ? C.amber : C.forest,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HeroMetric(
                      label: 'ON HOLD',
                      value: '$blocked',
                      color: blocked > 0 ? C.red : C.forest,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionTitle(
              'Preventative spray calendar',
              trailing: ProductTag(
                label: risks == null
                    ? 'Weather loading'
                    : 'Risk ${_riskShortLabel(risks.pestPressureRisk)}',
                color: risks == null
                    ? C.muted
                    : _gardenRiskColor(risks.pestPressureRisk),
                background: risks == null
                    ? C.greySoft
                    : _gardenRiskBackground(risks.pestPressureRisk),
              ),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const EmptyCard(
                'Log vegetables in Garden first. The calendar is generated from what is actually planted.',
              )
            else
              ...items.take(28).map(
                    (item) => _CalendarItemCard(
                      item: item,
                      onPlanSpray: onPlanSpray,
                    ),
                  ),
          ],
        );
      },
    );
  }
}

class _CalendarItemCard extends StatelessWidget {
  const _CalendarItemCard({
    required this.item,
    required this.onPlanSpray,
  });

  final PreventativeCalendarItem item;
  final VoidCallback onPlanSpray;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _statusBackground(item.status),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CropIcon(item.crop.iconPath, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.bed.label} | ${item.crop.name}',
                        style: const TextStyle(
                          color: C.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${protectionTargetLabel(item.target)} | every ${item.intervalDays} days | due ${shortDate(item.dueDate)}',
                        style: const TextStyle(
                          color: C.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                ProductTag(
                  label: _statusLabel(item.status),
                  color: _statusColor(item.status),
                  background: C.card,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.body,
              style: const TextStyle(
                color: C.ink,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...item.issues.take(4).map((issue) => TextChip(label: issue)),
                if (item.product != null)
                  ProductTag(
                    label: item.product!.name,
                    color: C.forest,
                    background: C.forestSoft,
                  ),
              ],
            ),
            if (item.status == ProtectionStatus.due ||
                item.status == ProtectionStatus.soon) ...[
              const SizedBox(height: 10),
              SecondaryButton(label: 'Open spray log', onPressed: onPlanSpray),
            ],
          ],
        ),
      );
}

class _IssueLibraryView extends StatelessWidget {
  const _IssueLibraryView({
    required this.target,
    required this.products,
    required this.bedCrops,
    required this.search,
    required this.onSearchChanged,
  });

  final ProtectionTarget target;
  final List<SprayProduct> products;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final TextEditingController search;
  final VoidCallback onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final plantedIds =
        bedCrops.values.expand((crops) => crops).map((crop) => crop.id).toSet();
    final profiles = buildCropIssueProfiles(
      target: target,
      crops: vegetableLibrary,
      products: products,
    );
    final query = search.text.trim().toLowerCase();
    final filtered = profiles.where((profile) {
      if (query.isEmpty) return true;
      return profile.name.toLowerCase().contains(query) ||
          profile.crops.any((crop) => crop.name.toLowerCase().contains(query));
    }).toList(growable: false);
    final planted = filtered
        .where((profile) =>
            profile.crops.any((crop) => plantedIds.contains(crop.id)))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProtectionSearchField(
          controller: search,
          placeholder:
              'Search ${target == ProtectionTarget.fungus ? 'fungus' : 'pests'} or crop',
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 12),
        SectionTitle(
          target == ProtectionTarget.fungus
              ? 'Fungus and disease pressure'
              : 'Pest pressure',
          trailing: Text(
            '${filtered.length}',
            style: const TextStyle(color: C.muted, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 8),
        if (planted.isNotEmpty) ...[
          ProductTag(
            label: '${planted.length} affecting planted crops',
            color: C.amber,
            background: C.amberSoft,
          ),
          const SizedBox(height: 8),
        ],
        ...filtered.map(
          (profile) => _IssueProfileCard(
            profile: profile,
            plantedIds: plantedIds,
          ),
        ),
      ],
    );
  }
}

class _IssueProfileCard extends StatelessWidget {
  const _IssueProfileCard({
    required this.profile,
    required this.plantedIds,
  });

  final CropIssueProfile profile;
  final Set<String> plantedIds;

  @override
  Widget build(BuildContext context) {
    final planted = profile.crops.where((crop) => plantedIds.contains(crop.id));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                profile.target == ProtectionTarget.fungus
                    ? CupertinoIcons.drop_triangle
                    : CupertinoIcons.ant,
                color:
                    profile.target == ProtectionTarget.fungus ? C.blue : C.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  profile.name,
                  style: const TextStyle(
                    color: C.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (planted.isNotEmpty)
                const ProductTag(
                  label: 'In garden',
                  color: C.amber,
                  background: C.amberSoft,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.crops
                .take(8)
                .map(
                  (crop) => ProductTag(
                    label: crop.name,
                    color: plantedIds.contains(crop.id) ? C.forest : C.muted,
                    background: plantedIds.contains(crop.id)
                        ? C.forestSoft
                        : C.greySoft,
                  ),
                )
                .toList(),
          ),
          if (profile.preventativeTips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              profile.preventativeTips.join(' | '),
              style: const TextStyle(
                color: C.ink,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (profile.products.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.products
                  .map(
                    (product) => ProductTag(
                      label: product.name,
                      color: C.forest,
                      background: C.forestSoft,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProtectionProductsView extends StatelessWidget {
  const _ProtectionProductsView({
    required this.products,
    required this.loading,
    required this.search,
    required this.onSearchChanged,
  });

  final List<SprayProduct> products;
  final bool loading;
  final TextEditingController search;
  final VoidCallback onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final filtered =
        products.where((product) => product.matchesQuery(search.text)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProtectionSearchField(
          controller: search,
          placeholder: 'Search product, pest, crop, active ingredient',
          onChanged: onSearchChanged,
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
        if (loading)
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

class _ProtectionSearchField extends StatelessWidget {
  const _ProtectionSearchField({
    required this.controller,
    required this.placeholder,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String placeholder;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        prefix: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(CupertinoIcons.search, color: C.muted, size: 19),
        ),
        padding: const EdgeInsets.all(13),
        onChanged: (_) => onChanged(),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line),
        ),
      );
}

String _statusLabel(ProtectionStatus status) => switch (status) {
      ProtectionStatus.due => 'Due',
      ProtectionStatus.soon => 'Soon',
      ProtectionStatus.scheduled => 'Later',
      ProtectionStatus.blocked => 'Hold',
    };

Color _statusColor(ProtectionStatus status) => switch (status) {
      ProtectionStatus.due => C.amber,
      ProtectionStatus.soon => C.blue,
      ProtectionStatus.scheduled => C.forest,
      ProtectionStatus.blocked => C.red,
    };

Color _statusBackground(ProtectionStatus status) => switch (status) {
      ProtectionStatus.due => C.amberSoft,
      ProtectionStatus.soon => C.blueSoft,
      ProtectionStatus.scheduled => C.card,
      ProtectionStatus.blocked => C.redSoft,
    };

String _riskShortLabel(GardenRiskLevel risk) => switch (risk) {
      GardenRiskLevel.low => 'low',
      GardenRiskLevel.moderate => 'mod',
      GardenRiskLevel.high => 'high',
    };
