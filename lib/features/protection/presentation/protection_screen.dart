part of '../../../main.dart';

enum ProtectionView { calendar, pests, fungus, products }

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
    this.initialView = ProtectionView.calendar,
    this.initialSearch = '',
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
  final ProtectionView initialView;
  final String initialSearch;

  @override
  State<ProtectionScreen> createState() => _ProtectionScreenState();
}

class _ProtectionScreenState extends State<ProtectionScreen> {
  late ProtectionView view = widget.initialView;
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();
    search.text = widget.initialSearch;
  }

  @override
  void didUpdateWidget(covariant ProtectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialView != oldWidget.initialView ||
        widget.initialSearch != oldWidget.initialSearch) {
      view = widget.initialView;
      search.text = widget.initialSearch;
    }
  }

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
          CupertinoSlidingSegmentedControl<ProtectionView>(
            groupValue: view,
            children: const {
              ProtectionView.calendar: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Calendar'),
              ),
              ProtectionView.pests: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Pests'),
              ),
              ProtectionView.fungus: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Fungus'),
              ),
              ProtectionView.products: Padding(
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
          if (view == ProtectionView.calendar)
            _ProtectionCalendarView(
              beds: widget.gardenBeds,
              bedCrops: widget.bedCrops,
              records: widget.records,
              products: widget.products,
              gardenRisks: widget.gardenRisks,
              onPlanSpray: widget.onPlanSpray,
            )
          else if (view == ProtectionView.pests)
            _IssueLibraryView(
              target: ProtectionTarget.pest,
              products: widget.products,
              bedCrops: widget.bedCrops,
              search: search,
              onSearchChanged: () => setState(() {}),
            )
          else if (view == ProtectionView.fungus)
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
        final feedDue = items
            .where(
              (item) =>
                  item.target == ProtectionTarget.feed &&
                  item.status == ProtectionStatus.due,
            )
            .length;
        final schedules = groupProtectionCalendarByBed(items);
        final requiredSchedules = schedules
            .where((schedule) => schedule.actionCount > 0)
            .toList(growable: false);
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
                      label: 'FEED DUE',
                      value: '$feedDue',
                      color: feedDue > 0 ? C.amber : C.forest,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionTitle(
              'Spray and feed calendar',
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
            else ...[
              _CalendarSummaryStrip(
                bedCount: schedules.length,
                sprayDue: due - feedDue,
                feedDue: feedDue,
                blocked: blocked,
              ),
              const SizedBox(height: 14),
              SectionTitle(
                'Required by bed',
                trailing: Text(
                  '${requiredSchedules.length}',
                  style: const TextStyle(
                    color: C.muted,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (requiredSchedules.isEmpty)
                const EmptyCard(
                  'Nothing needs action right now. Upcoming checks are listed below.',
                )
              else
                ...requiredSchedules.map(
                  (schedule) => _BedScheduleCard(
                    schedule: schedule,
                    onPlanSpray: onPlanSpray,
                    requiredOnly: true,
                  ),
                ),
              const SizedBox(height: 14),
              const SectionTitle('Upcoming by bed'),
              const SizedBox(height: 8),
              ...schedules.map(
                (schedule) => _BedScheduleCard(
                  schedule: schedule,
                  onPlanSpray: onPlanSpray,
                  requiredOnly: false,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CalendarSummaryStrip extends StatelessWidget {
  const _CalendarSummaryStrip({
    required this.bedCount,
    required this.sprayDue,
    required this.feedDue,
    required this.blocked,
  });

  final int bedCount;
  final int sprayDue;
  final int feedDue;
  final int blocked;

  @override
  Widget build(BuildContext context) => Panel(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ProductTag(
              label: '$bedCount planted bed${bedCount == 1 ? '' : 's'}',
              color: C.forest,
              background: C.forestSoft,
            ),
            ProductTag(
              label: '$sprayDue spray due',
              color: sprayDue > 0 ? C.red : C.muted,
              background: sprayDue > 0 ? C.redSoft : C.greySoft,
            ),
            ProductTag(
              label: '$feedDue feed due',
              color: feedDue > 0 ? C.amber : C.muted,
              background: feedDue > 0 ? C.amberSoft : C.greySoft,
            ),
            if (blocked > 0)
              ProductTag(
                label: '$blocked on hold',
                color: C.red,
                background: C.redSoft,
              ),
          ],
        ),
      );
}

class _BedScheduleCard extends StatelessWidget {
  const _BedScheduleCard({
    required this.schedule,
    required this.onPlanSpray,
    required this.requiredOnly,
  });

  final BedProtectionSchedule schedule;
  final VoidCallback onPlanSpray;
  final bool requiredOnly;

  @override
  Widget build(BuildContext context) {
    final visibleItems =
        requiredOnly ? schedule.requiredItems : schedule.items.take(8).toList();
    final hiddenCount = requiredOnly
        ? 0
        : schedule.items.length > visibleItems.length
            ? schedule.items.length - visibleItems.length
            : 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(
        color: schedule.actionCount > 0 ? C.card : C.soft,
      ),
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
                  color: C.forestSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${schedule.bed.number}',
                  style: const TextStyle(
                    color: C.forest,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.bed.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: C.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Next check ${shortDate(schedule.nextDueDate)}',
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
                label: schedule.actionCount == 0
                    ? 'Scheduled'
                    : '${schedule.actionCount} action',
                color: schedule.actionCount == 0 ? C.muted : C.amber,
                background:
                    schedule.actionCount == 0 ? C.greySoft : C.amberSoft,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              ProductTag(
                label: '${schedule.sprayActionCount} spray',
                color: schedule.sprayActionCount > 0 ? C.red : C.muted,
                background:
                    schedule.sprayActionCount > 0 ? C.redSoft : C.greySoft,
              ),
              ProductTag(
                label: '${schedule.feedActionCount} feed',
                color: schedule.feedActionCount > 0 ? C.amber : C.muted,
                background:
                    schedule.feedActionCount > 0 ? C.amberSoft : C.greySoft,
              ),
              if (schedule.blockedCount > 0)
                ProductTag(
                  label: '${schedule.blockedCount} hold',
                  color: C.red,
                  background: C.redSoft,
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (visibleItems.isEmpty)
            const EmptyInline('No due items for this bed.')
          else
            ...visibleItems.map(
              (item) => _CalendarItemRow(
                item: item,
                onPlanSpray: onPlanSpray,
              ),
            ),
          if (hiddenCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              '+$hiddenCount later checks',
              style: const TextStyle(
                color: C.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CalendarItemRow extends StatelessWidget {
  const _CalendarItemRow({
    required this.item,
    required this.onPlanSpray,
  });

  final PreventativeCalendarItem item;
  final VoidCallback onPlanSpray;

  @override
  Widget build(BuildContext context) {
    final target = targetById(_targetId(item.target));
    final canPlan = item.status == ProtectionStatus.due ||
        item.status == ProtectionStatus.soon;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _statusBackground(item.status),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.line),
      ),
      child: Row(
        children: [
          CropIcon(item.crop.iconPath, size: 30),
          const SizedBox(width: 9),
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: target.softColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(target.icon, size: 16, color: target.color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.crop.name} | ${protectionTargetLabel(item.target)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: C.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${_statusLabel(item.status)} | due ${shortDate(item.dueDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: C.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (canPlan)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(34, 34),
              onPressed: onPlanSpray,
              child: const Icon(
                CupertinoIcons.plus_circle_fill,
                color: C.forest,
                size: 24,
              ),
            ),
        ],
      ),
    );
  }
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
    }).toList(growable: true)
      ..sort((a, b) {
        final aPlanted = a.crops.any((crop) => plantedIds.contains(crop.id));
        final bPlanted = b.crops.any((crop) => plantedIds.contains(crop.id));
        final plantedRank = bPlanted.toString().compareTo(aPlanted.toString());
        if (plantedRank != 0) return plantedRank;
        return a.name.compareTo(b.name);
      });
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
                    (product) => CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: () => showSprayProductDetail(
                        context,
                        product,
                      ),
                      child: ProductTag(
                        label: product.name,
                        color: C.forest,
                        background: C.forestSoft,
                      ),
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
