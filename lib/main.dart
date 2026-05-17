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
  static const blue = Color(0xFF2578D5);
  static const brown = Color(0xFF8B5A2B);
  static const path = Color(0xFFC9C4BA);
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

class BedZone {
  const BedZone(this.number, this.bounds, this.label);

  final int number;
  final Rect bounds;
  final String label;
}

class SprayProduct {
  const SprayProduct(this.name, this.type, this.withholdingDays);

  final String name;
  final String type;
  final int withholdingDays;
}

class SprayRecord {
  const SprayRecord({
    required this.bedNumbers,
    required this.product,
    required this.reason,
    required this.sprayedAt,
    required this.withholdingDays,
  });

  final List<int> bedNumbers;
  final String product;
  final String reason;
  final DateTime sprayedAt;
  final int withholdingDays;

  DateTime get safeDate => sprayedAt.add(Duration(days: withholdingDays));
}

class BedDisplayState {
  const BedDisplayState({required this.status, required this.lastSpray});

  final String status;
  final String lastSpray;
}

const bedZones = [
  BedZone(1, Rect.fromLTWH(.06, .08, .20, .12), 'Upper-left section'),
  BedZone(2, Rect.fromLTWH(.36, .08, .15, .31), 'Right-hand section'),
  BedZone(3, Rect.fromLTWH(.55, .08, .10, .085), 'Top small bed'),
  BedZone(4, Rect.fromLTWH(.70, .08, .25, .07), 'Strawberries'),
  BedZone(5, Rect.fromLTWH(.70, .18, .25, .07), 'Raspberries'),
  BedZone(6, Rect.fromLTWH(.70, .28, .25, .07), 'Bed 6'),
  BedZone(7, Rect.fromLTWH(.70, .38, .25, .07), 'Bed 7'),
  BedZone(8, Rect.fromLTWH(.70, .48, .25, .07), 'Berry bed'),
  BedZone(9, Rect.fromLTWH(.70, .58, .25, .07), 'Bed 9'),
  BedZone(10, Rect.fromLTWH(.70, .68, .25, .07), 'Bed 10'),
  BedZone(11, Rect.fromLTWH(.70, .78, .25, .08), 'Bed 11'),
  BedZone(12, Rect.fromLTWH(.04, .42, .46, .07), 'Bed 12'),
  BedZone(13, Rect.fromLTWH(.04, .53, .46, .07), 'Asparagus'),
  BedZone(14, Rect.fromLTWH(.04, .64, .46, .07), 'Bed 14'),
  BedZone(15, Rect.fromLTWH(.04, .75, .46, .07), 'Bed 15'),
  BedZone(16, Rect.fromLTWH(.04, .92, .91, .045), 'Long bottom bed'),
  BedZone(17, Rect.fromLTWH(.04, .01, .91, .04), 'Top cane bed'),
];

const products = [
  SprayProduct('Neem oil', 'Pest control', 3),
  SprayProduct('Copper spray', 'Fungicide', 7),
  SprayProduct('Seaweed tonic', 'Plant health', 0),
];

const compoundOuter = Rect.fromLTWH(.04, .07, .47, .33);
const compoundPath = Rect.fromLTWH(.275, .08, .045, .31);
const compoundLowerLeft = Rect.fromLTWH(.06, .24, .20, .15);
const mainPath = Rect.fromLTWH(.55, .17, .045, .72);

BedZone bedByNumber(int number) => bedZones.firstWhere((bed) => bed.number == number);
String dateLabel(DateTime date) => '${date.day}/${date.month}/${date.year}';

class SprayTrackerHome extends StatefulWidget {
  const SprayTrackerHome({super.key});

  @override
  State<SprayTrackerHome> createState() => _SprayTrackerHomeState();
}

class _SprayTrackerHomeState extends State<SprayTrackerHome> {
  late final CupertinoTabController tabController;
  int selectedBedNumber = 4;
  Set<int> selectedBeds = {4};
  late List<SprayRecord> records;

  @override
  void initState() {
    super.initState();
    tabController = CupertinoTabController();
    final now = DateTime.now();
    records = [
      SprayRecord(bedNumbers: const [4, 5], product: 'Neem oil', reason: 'Aphids', sprayedAt: now.subtract(const Duration(days: 1)), withholdingDays: 3),
      SprayRecord(bedNumbers: const [8], product: 'Copper spray', reason: 'Blight prevention', sprayedAt: now.subtract(const Duration(days: 2)), withholdingDays: 7),
      SprayRecord(bedNumbers: const [17], product: 'Berry spray', reason: 'Cane check', sprayedAt: now.subtract(const Duration(days: 1)), withholdingDays: 4),
    ];
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  BedDisplayState stateForBed(int bedNumber) {
    final latest = records.where((record) => record.bedNumbers.contains(bedNumber)).firstOrNull;
    if (latest == null) return const BedDisplayState(status: 'Safe', lastSpray: 'No recent spray');
    final waiting = latest.safeDate.isAfter(DateTime.now());
    return BedDisplayState(
      status: waiting ? 'Wait' : 'Safe',
      lastSpray: '${latest.product} · safe ${dateLabel(latest.safeDate)}',
    );
  }

  Map<int, BedDisplayState> get bedStates => {for (final bed in bedZones) bed.number: stateForBed(bed.number)};
  int get waitingCount => bedZones.where((bed) => stateForBed(bed.number).status == 'Wait').length;
  int get safeCount => bedZones.length - waitingCount;

  void selectBed(int bedNumber) {
    setState(() {
      selectedBedNumber = bedNumber;
      selectedBeds = {bedNumber};
    });
  }

  void openLogForBed(int bedNumber) {
    setState(() {
      selectedBedNumber = bedNumber;
      selectedBeds = {bedNumber};
      tabController.index = 1;
    });
  }

  void logSpray({required Set<int> bedNumbers, required SprayProduct product, required String reason, required int withholdingDays}) {
    if (bedNumbers.isEmpty) return;
    setState(() {
      records.insert(
        0,
        SprayRecord(
          bedNumbers: bedNumbers.toList()..sort(),
          product: product.name,
          reason: reason.trim().isEmpty ? 'General spray' : reason.trim(),
          sprayedAt: DateTime.now(),
          withholdingDays: withholdingDays,
        ),
      );
      selectedBedNumber = bedNumbers.first;
      selectedBeds = {...bedNumbers};
      tabController.index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      controller: tabController,
      tabBar: CupertinoTabBar(
        backgroundColor: const Color(0xF8FFFCF6),
        activeColor: AppColor.green,
        inactiveColor: AppColor.muted,
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.house_fill), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.plus_circle_fill), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.map_fill), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.time), label: 'History'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.cube_box_fill), label: 'Products'),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (_) => switch (index) {
            0 => DashboardScreen(safeCount: safeCount, waitingCount: waitingCount, records: records, onOpenLog: () => tabController.index = 1),
            1 => LogSprayScreen(initialBeds: selectedBeds, onSubmit: logSpray),
            2 => GardenMapScreen(selectedBed: selectedBedNumber, bedStates: bedStates, onSelectBed: selectBed, onLogBed: openLogForBed),
            3 => HistoryScreen(records: records),
            _ => const ProductsScreen(),
          },
        );
      },
    );
  }
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({required this.safeCount, required this.waitingCount, required this.records, required this.onOpenLog, super.key});

  final int safeCount;
  final int waitingCount;
  final List<SprayRecord> records;
  final VoidCallback onOpenLog;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Spray Tracker',
      subtitle: 'Today in your veg garden',
      children: [
        HeroPanel(safeCount: safeCount, waitingCount: waitingCount, onOpenLog: onOpenLog),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: MetricCard(label: 'Safe now', value: '$safeCount', detail: 'beds', color: AppColor.green, icon: CupertinoIcons.check_mark_circled_solid)),
            const SizedBox(width: 12),
            Expanded(child: MetricCard(label: 'Wait', value: '$waitingCount', detail: 'beds', color: AppColor.orange, icon: CupertinoIcons.exclamationmark_triangle_fill)),
          ],
        ),
        const SizedBox(height: 24),
        SectionHeader(title: 'Recent sprays', action: 'View all'),
        const SizedBox(height: 10),
        if (records.isEmpty) const EmptyCard('No spray records yet.') else ...records.take(3).map((record) => SprayRecordCard(record: record)),
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
  final void Function({required Set<int> bedNumbers, required SprayProduct product, required String reason, required int withholdingDays}) onSubmit;

  @override
  State<LogSprayScreen> createState() => _LogSprayScreenState();
}

class _LogSprayScreenState extends State<LogSprayScreen> {
  late Set<int> selectedBeds;
  SprayProduct selectedProduct = products.first;
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
    if (oldWidget.initialBeds.join(',') != widget.initialBeds.join(',')) selectedBeds = {...widget.initialBeds};
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  void submit() {
    widget.onSubmit(bedNumbers: selectedBeds, product: selectedProduct, reason: reasonController.text, withholdingDays: withholdingDays);
    reasonController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Log Spray',
      subtitle: 'Record product use quickly',
      children: [
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Beds sprayed'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: bedZones.map((bed) {
                  final selected = selectedBeds.contains(bed.number);
                  return BedChip(number: bed.number, selected: selected, onTap: () => setState(() => selected ? selectedBeds.remove(bed.number) : selectedBeds.add(bed.number)));
                }).toList(),
              ),
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
                children: {for (final product in products) product.name: Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8), child: Text(product.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))},
                onValueChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedProduct = products.firstWhere((product) => product.name == value);
                    withholdingDays = selectedProduct.withholdingDays;
                  });
                },
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(child: Text('Withholding period', style: TextStyle(fontWeight: FontWeight.w800))),
                  StepperButton(icon: CupertinoIcons.minus, onPressed: withholdingDays > 0 ? () => setState(() => withholdingDays--) : null),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('$withholdingDays days', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
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

class GardenMapScreen extends StatelessWidget {
  const GardenMapScreen({required this.selectedBed, required this.bedStates, required this.onSelectBed, required this.onLogBed, super.key});

  final int selectedBed;
  final Map<int, BedDisplayState> bedStates;
  final ValueChanged<int> onSelectBed;
  final ValueChanged<int> onLogBed;

  @override
  Widget build(BuildContext context) {
    final bed = bedByNumber(selectedBed);
    final state = bedStates[selectedBed]!;
    return AppPage(
      title: 'Garden Map',
      subtitle: 'Tap a bed to inspect or spray',
      children: [
        MapShell(child: InteractiveGardenMap(selectedBed: selectedBed, bedStates: bedStates, onSelect: onSelectBed)),
        const SizedBox(height: 16),
        BedDetailCard(bed: bed, state: state, onLogSpray: () => onLogBed(bed.number)),
      ],
    );
  }
}

class MapShell extends StatelessWidget {
  const MapShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 560,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE5D9C7)),
        boxShadow: appShadow,
      ),
      child: child,
    );
  }
}

class InteractiveGardenMap extends StatelessWidget {
  const InteractiveGardenMap({required this.selectedBed, required this.bedStates, required this.onSelect, super.key});

  final int selectedBed;
  final Map<int, BedDisplayState> bedStates;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            for (final bed in bedZones.reversed) {
              if (scaleRect(bed.bounds, size).inflate(6).contains(details.localPosition)) {
                onSelect(bed.number);
                return;
              }
            }
          },
          child: CustomPaint(painter: GardenMapPainter(selectedBed: selectedBed, bedStates: bedStates), size: Size.infinite),
        );
      },
    );
  }
}

class GardenMapPainter extends CustomPainter {
  const GardenMapPainter({required this.selectedBed, required this.bedStates});

  final int selectedBed;
  final Map<int, BedDisplayState> bedStates;

  @override
  void paint(Canvas canvas, Size size) {
    drawGrid(canvas, size);
    drawOutline(canvas, size, compoundOuter);
    drawOutline(canvas, size, compoundLowerLeft);
    drawPath(canvas, size, compoundPath);
    drawPath(canvas, size, mainPath);
    for (final bed in bedZones) drawBed(canvas, size, bed);
  }

  void drawGrid(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFEDE4D5)..strokeWidth = .45;
    for (double x = 0; x < size.width; x += 12) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += 12) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  void drawBed(Canvas canvas, Size size, BedZone bed) {
    final rect = scaleRect(bed.bounds, size);
    final selected = bed.number == selectedBed;
    final waiting = bedStates[bed.number]!.status == 'Wait';
    final fill = selected ? const Color(0xFFEAF3FF) : waiting ? AppColor.orangeSoft : const Color(0xFFFFF8EA);
    final border = selected ? AppColor.blue : waiting ? AppColor.orange : AppColor.brown;
    roundedRect(canvas, rect, fill, border, selected ? 4 : 2);
    if (waiting) canvas.drawCircle(rect.topRight + const Offset(-12, 12), 5, Paint()..color = AppColor.orange);
    drawNumber(canvas, rect.center, bed.number, selected);
  }

  void drawOutline(Canvas canvas, Size size, Rect rect) => roundedRect(canvas, scaleRect(rect, size), const Color(0x00FFFFFF), AppColor.brown, 2);

  void drawPath(Canvas canvas, Size size, Rect rect) {
    final scaled = scaleRect(rect, size);
    canvas.drawRRect(RRect.fromRectAndRadius(scaled, const Radius.circular(4)), Paint()..color = AppColor.path);
    final tilePaint = Paint()..color = const Color(0xFFFFFFFF)..strokeWidth = .7;
    for (double y = scaled.top + 20; y < scaled.bottom; y += 24) canvas.drawLine(Offset(scaled.left, y), Offset(scaled.right, y), tilePaint);
  }

  void roundedRect(Canvas canvas, Rect rect, Color fill, Color border, double width) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(9));
    canvas.drawRRect(rrect, Paint()..color = fill);
    canvas.drawRRect(rrect, Paint()..color = border..style = PaintingStyle.stroke..strokeWidth = width);
  }

  void drawNumber(Canvas canvas, Offset center, int number, bool selected) {
    canvas.drawCircle(center, selected ? 17 : 15, Paint()..color = selected ? AppColor.blue : AppColor.brown);
    final text = TextPainter(
      text: TextSpan(text: '$number', style: TextStyle(color: CupertinoColors.white, fontSize: number > 9 ? 14 : 16, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
  }

  @override
  bool shouldRepaint(covariant GardenMapPainter oldDelegate) => true;
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({required this.records, super.key});

  final List<SprayRecord> records;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'History',
      subtitle: 'Spray records for this session',
      children: records.isEmpty ? [const EmptyCard('No spray records yet.')] : records.map((record) => SprayRecordCard(record: record)).toList(),
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
    return CupertinoPageScaffold(
      backgroundColor: AppColor.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
          children: [
            Text(title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppColor.text)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 16, color: AppColor.muted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class PremiumCard extends StatelessWidget {
  const PremiumCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(18), decoration: premiumDecoration, child: child);
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
          boxShadow: selected ? appShadow : null,
        ),
        child: Text('$number', style: TextStyle(color: selected ? CupertinoColors.white : AppColor.text, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class BedDetailCard extends StatelessWidget {
  const BedDetailCard({required this.bed, required this.state, required this.onLogSpray, super.key});

  final BedZone bed;
  final BedDisplayState state;
  final VoidCallback onLogSpray;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Expanded(child: Text('Bed ${bed.number}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))), StatusPill(status: state.status)]),
          const SizedBox(height: 8),
          Text(bed.label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(state.lastSpray, style: const TextStyle(color: AppColor.muted)),
          const SizedBox(height: 14),
          PrimaryButton(title: 'Log spray for Bed ${bed.number}', onPressed: onLogSpray),
        ],
      ),
    );
  }
}

class SprayRecordCard extends StatelessWidget {
  const SprayRecordCard({required this.record, super.key});

  final SprayRecord record;

  @override
  Widget build(BuildContext context) {
    final waiting = record.safeDate.isAfter(DateTime.now());
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: premiumDecoration,
      child: Row(
        children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColor.greenSoft, borderRadius: BorderRadius.circular(15)), child: const Icon(CupertinoIcons.drop_fill, color: AppColor.green)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(record.product, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              Text('Beds ${record.bedNumbers.join(', ')} · ${record.reason}', style: const TextStyle(color: AppColor.muted)),
              Text('Safe ${dateLabel(record.safeDate)}', style: const TextStyle(fontSize: 13, color: AppColor.text)),
            ]),
          ),
          StatusPill(status: waiting ? 'Wait' : 'Safe'),
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
        Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColor.greenSoft, borderRadius: BorderRadius.circular(15)), child: const Icon(CupertinoIcons.cube_box_fill, color: AppColor.green)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), Text(product.type, style: const TextStyle(color: AppColor.muted))])),
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
  Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, onPressed: onPressed, child: Icon(icon, color: onPressed == null ? AppColor.muted : AppColor.green));
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
  const SectionHeader({required this.title, this.action, super.key});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))), if (action != null) Text(action!, style: const TextStyle(color: AppColor.green, fontWeight: FontWeight.w800))]);
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

Rect scaleRect(Rect r, Size size) => Rect.fromLTWH(r.left * size.width, r.top * size.height, r.width * size.width, r.height * size.height);

const appShadow = [BoxShadow(color: Color(0x16000000), blurRadius: 24, offset: Offset(0, 12))];
final premiumDecoration = BoxDecoration(color: AppColor.card, borderRadius: BorderRadius.circular(26), border: Border.all(color: const Color(0xFFE9DECD)), boxShadow: appShadow);
final cardDecoration = BoxDecoration(color: AppColor.card, borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFFE9DECD)), boxShadow: appShadow);
