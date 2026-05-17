import 'package:flutter/cupertino.dart';

void main() => runApp(const SprayTrackerApp());

class AppColor {
  static const background = Color(0xFFF4F1EA);
  static const card = Color(0xFFFFFCF6);
  static const cardAlt = Color(0xFFF8F3E9);
  static const green = Color(0xFF2F8A4C);
  static const greenSoft = Color(0xFFE7F4EA);
  static const orange = Color(0xFFE48A2A);
  static const orangeSoft = Color(0xFFFFEEDB);
  static const red = Color(0xFFC84D42);
  static const redSoft = Color(0xFFFFE8E5);
  static const text = Color(0xFF1F241F);
  static const muted = Color(0xFF74786F);
}

class SprayTrackerApp extends StatelessWidget {
  const SprayTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Spray Tracker',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: AppColor.green,
        scaffoldBackgroundColor: AppColor.background,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(color: AppColor.text, fontSize: 16),
        ),
      ),
      home: SprayTrackerHome(),
    );
  }
}

class GardenBed {
  const GardenBed(this.number, this.name, this.group);

  final int number;
  final String name;
  final String group;
}

class SprayProduct {
  const SprayProduct(this.name, this.type, this.withholdingDays);

  final String name;
  final String type;
  final int withholdingDays;
}

class SprayRecord {
  const SprayRecord({
    required this.id,
    required this.bedNumbers,
    required this.product,
    required this.reason,
    required this.sprayedAt,
    required this.withholdingDays,
  });

  final int id;
  final List<int> bedNumbers;
  final String product;
  final String reason;
  final DateTime sprayedAt;
  final int withholdingDays;

  DateTime get safeDate => sprayedAt.add(Duration(days: withholdingDays));
}

class BedDisplayState {
  const BedDisplayState({
    required this.status,
    required this.lastSpray,
    required this.daysRemaining,
  });

  final String status;
  final String lastSpray;
  final int daysRemaining;
}

const gardenBeds = [
  GardenBed(1, 'Upper-left section', 'Compound area'),
  GardenBed(2, 'Right-hand section', 'Compound area'),
  GardenBed(3, 'Top small bed', 'Top beds'),
  GardenBed(4, 'Strawberries', 'Right side'),
  GardenBed(5, 'Raspberries', 'Right side'),
  GardenBed(6, 'Bed 6', 'Right side'),
  GardenBed(7, 'Bed 7', 'Right side'),
  GardenBed(8, 'Berry bed', 'Right side'),
  GardenBed(9, 'Bed 9', 'Right side'),
  GardenBed(10, 'Bed 10', 'Right side'),
  GardenBed(11, 'Lower-right bed', 'Right side'),
  GardenBed(12, 'Bed 12', 'Left side'),
  GardenBed(13, 'Asparagus', 'Left side'),
  GardenBed(14, 'Bed 14', 'Left side'),
  GardenBed(15, 'Bed 15', 'Left side'),
  GardenBed(16, 'Long bottom bed', 'Long beds'),
  GardenBed(17, 'Top cane bed', 'Long beds'),
];

const defaultProducts = [
  SprayProduct('Neem oil', 'Pest control', 3),
  SprayProduct('Copper spray', 'Fungicide', 7),
  SprayProduct('Seaweed tonic', 'Plant health', 0),
];

String dateLabel(DateTime date) => '${date.day}/${date.month}/${date.year}';

class SprayTrackerHome extends StatefulWidget {
  const SprayTrackerHome({super.key});

  @override
  State<SprayTrackerHome> createState() => _SprayTrackerHomeState();
}

class _SprayTrackerHomeState extends State<SprayTrackerHome> {
  int currentTab = 0;
  int nextRecordId = 4;
  Set<int> selectedBeds = {4};
  List<SprayRecord> records = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    records = [
      SprayRecord(
        id: 1,
        bedNumbers: const [4, 5],
        product: 'Neem oil',
        reason: 'Aphids',
        sprayedAt: now.subtract(const Duration(days: 1)),
        withholdingDays: 3,
      ),
      SprayRecord(
        id: 2,
        bedNumbers: const [8],
        product: 'Copper spray',
        reason: 'Blight prevention',
        sprayedAt: now.subtract(const Duration(days: 2)),
        withholdingDays: 7,
      ),
      SprayRecord(
        id: 3,
        bedNumbers: const [17],
        product: 'Berry spray',
        reason: 'Cane check',
        sprayedAt: now.subtract(const Duration(days: 1)),
        withholdingDays: 4,
      ),
    ];
  }

  BedDisplayState stateForBed(int bedNumber) {
    final latest = records.where((record) => record.bedNumbers.contains(bedNumber)).firstOrNull;
    if (latest == null) {
      return const BedDisplayState(
        status: 'Safe',
        lastSpray: 'No recent spray',
        daysRemaining: 0,
      );
    }

    final now = DateTime.now();
    final waiting = latest.safeDate.isAfter(now);
    final daysRemaining = waiting ? latest.safeDate.difference(now).inDays + 1 : 0;
    return BedDisplayState(
      status: waiting ? 'Wait' : 'Safe',
      lastSpray: '${latest.product} · safe ${dateLabel(latest.safeDate)}',
      daysRemaining: daysRemaining,
    );
  }

  int get waitingCount => gardenBeds.where((bed) => stateForBed(bed.number).status == 'Wait').length;
  int get safeCount => gardenBeds.length - waitingCount;

  void setTab(int index) {
    setState(() => currentTab = index);
  }

  void openLogForBeds(Set<int> beds) {
    setState(() {
      selectedBeds = beds.isEmpty ? {4} : {...beds};
      currentTab = 1;
    });
  }

  void logSpray({
    required Set<int> bedNumbers,
    required SprayProduct product,
    required String reason,
    required int withholdingDays,
  }) {
    if (bedNumbers.isEmpty) return;
    setState(() {
      records.insert(
        0,
        SprayRecord(
          id: nextRecordId++,
          bedNumbers: bedNumbers.toList()..sort(),
          product: product.name,
          reason: reason.trim().isEmpty ? 'General spray' : reason.trim(),
          sprayedAt: DateTime.now(),
          withholdingDays: withholdingDays,
        ),
      );
      selectedBeds = {...bedNumbers};
      currentTab = 0;
    });
  }

  void removeRecord(int recordId) {
    setState(() {
      records = records.where((record) => record.id != recordId).toList();
    });
  }

  void clearBed(int bedNumber) {
    setState(() {
      records = records
          .map((record) {
            if (!record.bedNumbers.contains(bedNumber)) return record;
            final remainingBeds = record.bedNumbers.where((number) => number != bedNumber).toList();
            if (remainingBeds.isEmpty) return null;
            return SprayRecord(
              id: record.id,
              bedNumbers: remainingBeds,
              product: record.product,
              reason: record.reason,
              sprayedAt: record.sprayedAt,
              withholdingDays: record.withholdingDays,
            );
          })
          .whereType<SprayRecord>()
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        safeCount: safeCount,
        waitingCount: waitingCount,
        records: records,
        onOpenLog: () => openLogForBeds(selectedBeds),
      ),
      LogSprayScreen(
        key: ValueKey(selectedBeds.join(',')),
        initialBeds: selectedBeds,
        onSubmit: logSpray,
      ),
      BedsScreen(
        bedState: stateForBed,
        onLogBed: (bedNumber) => openLogForBeds({bedNumber}),
        onClearBed: clearBed,
      ),
      HistoryScreen(records: records, onRemove: removeRecord),
      const ProductsScreen(),
    ];

    return CupertinoPageScaffold(
      backgroundColor: AppColor.background,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(index: currentTab, children: pages),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xF8FFFCF6),
                border: Border(top: BorderSide(color: Color(0xFFE9DECD))),
              ),
              child: CupertinoTabBar(
                currentIndex: currentTab,
                onTap: setTab,
                backgroundColor: const Color(0xF8FFFCF6),
                activeColor: AppColor.green,
                inactiveColor: AppColor.muted,
                items: const [
                  BottomNavigationBarItem(icon: Icon(CupertinoIcons.house_fill), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(CupertinoIcons.plus_circle_fill), label: 'Log'),
                  BottomNavigationBarItem(icon: Icon(CupertinoIcons.square_grid_2x2_fill), label: 'Beds'),
                  BottomNavigationBarItem(icon: Icon(CupertinoIcons.time), label: 'History'),
                  BottomNavigationBarItem(icon: Icon(CupertinoIcons.cube_box_fill), label: 'Products'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.safeCount,
    required this.waitingCount,
    required this.records,
    required this.onOpenLog,
    super.key,
  });

  final int safeCount;
  final int waitingCount;
  final List<SprayRecord> records;
  final VoidCallback onOpenLog;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Spray Tracker',
      subtitle: 'Simple spray safety for your veg garden',
      children: [
        HeroPanel(safeCount: safeCount, waitingCount: waitingCount, onOpenLog: onOpenLog),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Safe now',
                value: '$safeCount',
                detail: 'beds',
                color: AppColor.green,
                icon: CupertinoIcons.check_mark_circled_solid,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                label: 'Wait',
                value: '$waitingCount',
                detail: 'beds',
                color: AppColor.orange,
                icon: CupertinoIcons.exclamationmark_triangle_fill,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Recent sprays'),
        const SizedBox(height: 10),
        if (records.isEmpty)
          const EmptyCard('No spray records yet.')
        else
          ...records.take(3).map((record) => SprayRecordCard(record: record)),
      ],
    );
  }
}

class HeroPanel extends StatelessWidget {
  const HeroPanel({required this.safeCount, required this.waitingCount, required this.onOpenLog, super.key});

  final int safeCount;
  final int waitingCount;
  final VoidCallback onOpenLog;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF2F8A4C), Color(0xFF76B96B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: appShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Garden safety', style: TextStyle(color: CupertinoColors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('$safeCount beds safe · $waitingCount waiting', style: const TextStyle(color: Color(0xEFFFFFFF), fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(18),
            onPressed: onOpenLog,
            child: const Text('Log a spray', style: TextStyle(color: AppColor.green, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class LogSprayScreen extends StatefulWidget {
  const LogSprayScreen({required this.initialBeds, required this.onSubmit, super.key});

  final Set<int> initialBeds;
  final void Function({
    required Set<int> bedNumbers,
    required SprayProduct product,
    required String reason,
    required int withholdingDays,
  }) onSubmit;

  @override
  State<LogSprayScreen> createState() => _LogSprayScreenState();
}

class _LogSprayScreenState extends State<LogSprayScreen> {
  late Set<int> selectedBeds;
  SprayProduct selectedProduct = defaultProducts.first;
  late int withholdingDays;
  final reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedBeds = {...widget.initialBeds};
    withholdingDays = selectedProduct.withholdingDays;
  }

  @override
  void didUpdateWidget(covariant LogSprayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialBeds.join(',') != widget.initialBeds.join(',')) {
      selectedBeds = {...widget.initialBeds};
    }
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  void submit() {
    widget.onSubmit(
      bedNumbers: selectedBeds,
      product: selectedProduct,
      reason: reasonController.text,
      withholdingDays: withholdingDays,
    );
    reasonController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Log Spray',
      subtitle: 'Pick beds, product, and withholding period',
      children: [
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Beds sprayed'),
              const SizedBox(height: 6),
              Text('${selectedBeds.length} selected', style: const TextStyle(color: AppColor.muted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: gardenBeds.map((bed) {
                  final selected = selectedBeds.contains(bed.number);
                  return BedChip(
                    number: bed.number,
                    selected: selected,
                    onTap: () => setState(() => selected ? selectedBeds.remove(bed.number) : selectedBeds.add(bed.number)),
                  );
                }).toList(),
              ),
              if (selectedBeds.isNotEmpty) ...[
                const SizedBox(height: 12),
                SecondaryButton(
                  title: 'Clear selected beds',
                  icon: CupertinoIcons.xmark_circle,
                  onPressed: () => setState(selectedBeds.clear),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Product'),
              const SizedBox(height: 12),
              CupertinoSlidingSegmentedControl<String>(
                groupValue: selectedProduct.name,
                children: {
                  for (final product in defaultProducts)
                    product.name: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      child: Text(product.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                },
                onValueChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedProduct = defaultProducts.firstWhere((product) => product.name == value);
                    withholdingDays = selectedProduct.withholdingDays;
                  });
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(child: Text('Withholding', style: TextStyle(fontWeight: FontWeight.w800))),
                  StepperButton(icon: CupertinoIcons.minus, onPressed: withholdingDays > 0 ? () => setState(() => withholdingDays--) : null),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('$withholdingDays days', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                  StepperButton(icon: CupertinoIcons.plus, onPressed: () => setState(() => withholdingDays++)),
                ],
              ),
              const SizedBox(height: 14),
              CupertinoTextField(
                controller: reasonController,
                placeholder: 'Reason, e.g. aphids or mildew',
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: AppColor.cardAlt, borderRadius: BorderRadius.circular(18)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        PrimaryButton(title: 'Save spray record', onPressed: submit),
      ],
    );
  }
}

class BedsScreen extends StatelessWidget {
  const BedsScreen({required this.bedState, required this.onLogBed, required this.onClearBed, super.key});

  final BedDisplayState Function(int bedNumber) bedState;
  final ValueChanged<int> onLogBed;
  final ValueChanged<int> onClearBed;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Beds',
      subtitle: 'Simple cards instead of an interactive map',
      children: [
        const InfoPanel(
          title: 'Bed cards are easier to use',
          body: 'Tap Log to record a spray. Use Clear to remove spray status from that bed.',
          icon: CupertinoIcons.square_grid_2x2_fill,
        ),
        const SizedBox(height: 16),
        ...groupBeds().entries.map((entry) => BedGroupSection(
              groupName: entry.key,
              beds: entry.value,
              bedState: bedState,
              onLogBed: onLogBed,
              onClearBed: onClearBed,
            )),
      ],
    );
  }

  Map<String, List<GardenBed>> groupBeds() {
    final map = <String, List<GardenBed>>{};
    for (final bed in gardenBeds) {
      map.putIfAbsent(bed.group, () => []).add(bed);
    }
    return map;
  }
}

class BedGroupSection extends StatelessWidget {
  const BedGroupSection({required this.groupName, required this.beds, required this.bedState, required this.onLogBed, required this.onClearBed, super.key});

  final String groupName;
  final List<GardenBed> beds;
  final BedDisplayState Function(int bedNumber) bedState;
  final ValueChanged<int> onLogBed;
  final ValueChanged<int> onClearBed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: groupName),
          const SizedBox(height: 10),
          ...beds.map((bed) => BedStatusCard(
                bed: bed,
                state: bedState(bed.number),
                onLog: () => onLogBed(bed.number),
                onClear: () => onClearBed(bed.number),
              )),
        ],
      ),
    );
  }
}

class BedStatusCard extends StatelessWidget {
  const BedStatusCard({required this.bed, required this.state, required this.onLog, required this.onClear, super.key});

  final GardenBed bed;
  final BedDisplayState state;
  final VoidCallback onLog;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final waiting = state.status == 'Wait';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: premiumDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BedNumberBadge(number: bed.number, selected: waiting),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(bed.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  Text(state.lastSpray, style: const TextStyle(color: AppColor.muted)),
                ]),
              ),
              StatusPill(status: state.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SecondaryButton(title: 'Log', icon: CupertinoIcons.drop_fill, onPressed: onLog)),
              const SizedBox(width: 10),
              Expanded(child: DestructiveButton(title: 'Clear', onPressed: onClear)),
            ],
          ),
        ],
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({required this.records, required this.onRemove, super.key});

  final List<SprayRecord> records;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'History',
      subtitle: 'Remove mistakes or review recent sprays',
      children: records.isEmpty
          ? [const EmptyCard('No spray records yet.')]
          : records.map((record) => SprayRecordCard(record: record, onRemove: () => onRemove(record.id))).toList(),
    );
  }
}

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Products',
      subtitle: 'Sprays and withholding defaults',
      children: [
        ProductCard(product: SprayProduct('Neem oil', 'Pest control', 3)),
        ProductCard(product: SprayProduct('Copper spray', 'Fungicide', 7)),
        ProductCard(product: SprayProduct('Seaweed tonic', 'Plant health', 0)),
      ],
    );
  }
}

class AppPage extends StatelessWidget {
  const AppPage({required this.title, required this.subtitle, required this.children, super.key});

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
      children: [
        Text(title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColor.text)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 16, color: AppColor.muted, fontWeight: FontWeight.w500)),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }
}

class PremiumCard extends StatelessWidget {
  const PremiumCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(18), decoration: premiumDecoration, child: child);
}

class InfoPanel extends StatelessWidget {
  const InfoPanel({required this.title, required this.body, required this.icon, super.key});

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        children: [
          Icon(icon, color: AppColor.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(color: AppColor.muted)),
            ]),
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({required this.label, required this.value, required this.detail, required this.color, required this.icon, super.key});

  final String label;
  final String value;
  final String detail;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: premiumDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
          Text(detail, style: const TextStyle(color: AppColor.muted)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class BedChip extends StatelessWidget {
  const BedChip({required this.number, required this.selected, required this.onTap, super.key});

  final int number;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: 46,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColor.green : CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColor.green : const Color(0xFFE2D8C8), width: 2),
        ),
        child: Text('$number', style: TextStyle(color: selected ? CupertinoColors.white : AppColor.text, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class BedNumberBadge extends StatelessWidget {
  const BedNumberBadge({required this.number, required this.selected, super.key});

  final int number;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: selected ? AppColor.orange : AppColor.green, borderRadius: BorderRadius.circular(16)),
      child: Text('$number', style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w900, fontSize: 17)),
    );
  }
}

class SprayRecordCard extends StatelessWidget {
  const SprayRecordCard({required this.record, this.onRemove, super.key});

  final SprayRecord record;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final waiting = record.safeDate.isAfter(DateTime.now());
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: premiumDecoration,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: AppColor.greenSoft, borderRadius: BorderRadius.circular(15)),
            child: const Icon(CupertinoIcons.drop_fill, color: AppColor.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(record.product, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              Text('Beds ${record.bedNumbers.join(', ')} · ${record.reason}', style: const TextStyle(color: AppColor.muted)),
              Text('Safe ${dateLabel(record.safeDate)}', style: const TextStyle(fontSize: 13, color: AppColor.text)),
            ]),
          ),
          Column(
            children: [
              StatusPill(status: waiting ? 'Wait' : 'Safe'),
              if (onRemove != null)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 30,
                  onPressed: onRemove,
                  child: const Icon(CupertinoIcons.trash, color: AppColor.red, size: 20),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, super.key});

  final SprayProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: premiumDecoration,
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: AppColor.greenSoft, borderRadius: BorderRadius.circular(15)),
          child: const Icon(CupertinoIcons.cube_box_fill, color: AppColor.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            Text(product.type, style: const TextStyle(color: AppColor.muted)),
          ]),
        ),
        Text('${product.withholdingDays} days', style: const TextStyle(fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class StepperButton extends StatelessWidget {
  const StepperButton({required this.icon, required this.onPressed, super.key});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Icon(icon, color: onPressed == null ? AppColor.muted : AppColor.green),
      );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({required this.title, required this.onPressed, super.key});

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 14),
      color: AppColor.green,
      borderRadius: BorderRadius.circular(18),
      onPressed: onPressed,
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({required this.title, required this.icon, required this.onPressed, super.key});

  final String title;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: AppColor.cardAlt,
      borderRadius: BorderRadius.circular(16),
      onPressed: onPressed,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 16, color: AppColor.green),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(color: AppColor.text, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class DestructiveButton extends StatelessWidget {
  const DestructiveButton({required this.title, required this.onPressed, super.key});

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: AppColor.redSoft,
      borderRadius: BorderRadius.circular(16),
      onPressed: onPressed,
      child: Text(title, style: const TextStyle(color: AppColor.red, fontWeight: FontWeight.w800)),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final waiting = status == 'Wait';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(color: waiting ? AppColor.orangeSoft : AppColor.greenSoft, borderRadius: BorderRadius.circular(999)),
      child: Text(status, style: TextStyle(color: waiting ? AppColor.orange : AppColor.green, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900));
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900));
}

class EmptyCard extends StatelessWidget {
  const EmptyCard(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: premiumDecoration, child: Text(message, style: const TextStyle(color: AppColor.muted)));
}

const appShadow = [BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, 8))];
final premiumDecoration = BoxDecoration(
  color: AppColor.card,
  borderRadius: BorderRadius.circular(24),
  border: Border.all(color: const Color(0xFFE9DECD)),
  boxShadow: appShadow,
);
