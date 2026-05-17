import 'package:flutter/cupertino.dart';

void main() => runApp(const SprayTrackerApp());

class SprayTrackerApp extends StatelessWidget {
  const SprayTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Spray Tracker',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.activeGreen,
        scaffoldBackgroundColor: Color(0xFFF2F2F7),
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
      SprayRecord(
        bedNumbers: const [4, 5],
        product: 'Neem oil',
        reason: 'Aphids',
        sprayedAt: now.subtract(const Duration(days: 1)),
        withholdingDays: 3,
      ),
      SprayRecord(
        bedNumbers: const [8],
        product: 'Copper spray',
        reason: 'Blight prevention',
        sprayedAt: now.subtract(const Duration(days: 2)),
        withholdingDays: 7,
      ),
      SprayRecord(
        bedNumbers: const [17],
        product: 'Berry spray',
        reason: 'Cane check',
        sprayedAt: now.subtract(const Duration(days: 1)),
        withholdingDays: 4,
      ),
    ];
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  BedDisplayState stateForBed(int bedNumber) {
    final latest = records.where((record) => record.bedNumbers.contains(bedNumber)).firstOrNull;
    if (latest == null) {
      return const BedDisplayState(status: 'Safe', lastSpray: 'No recent spray');
    }
    final waiting = latest.safeDate.isAfter(DateTime.now());
    return BedDisplayState(
      status: waiting ? 'Wait' : 'Safe',
      lastSpray: '${latest.product} · safe ${dateLabel(latest.safeDate)}',
    );
  }

  Map<int, BedDisplayState> get bedStates => {
        for (final bed in bedZones) bed.number: stateForBed(bed.number),
      };

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
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.square_grid_2x2_fill), label: 'Dash'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.plus_circle_fill), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.map_fill), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.time), label: 'History'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.cube_box_fill), label: 'Products'),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (_) => switch (index) {
            0 => DashboardScreen(
                safeCount: safeCount,
                waitingCount: waitingCount,
                records: records,
                onOpenLog: () => tabController.index = 1,
              ),
            1 => LogSprayScreen(
                initialBeds: selectedBeds,
                onSubmit: logSpray,
              ),
            2 => GardenMapScreen(
                selectedBed: selectedBedNumber,
                bedStates: bedStates,
                onSelectBed: selectBed,
                onLogBed: openLogForBed,
              ),
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
      subtitle: 'Garden safety at a glance',
      children: [
        Row(
          children: [
            Expanded(child: MetricCard(label: 'Safe now', value: '$safeCount', detail: 'beds')),
            const SizedBox(width: 12),
            Expanded(child: MetricCard(label: 'Do not harvest', value: '$waitingCount', detail: 'beds')),
          ],
        ),
        const SizedBox(height: 16),
        PrimaryButton(title: 'Log a spray now', onPressed: onOpenLog),
        const SizedBox(height: 22),
        const SectionTitle('Recent sprays'),
        const SizedBox(height: 8),
        if (records.isEmpty)
          const EmptyCard('No spray records yet.')
        else
          ...records.take(3).map((record) => SprayRecordCard(record: record)),
      ],
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
      subtitle: 'Select beds and record product use',
      children: [
        const SectionTitle('Beds sprayed'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: bedZones.map((bed) {
            final selected = selectedBeds.contains(bed.number);
            return BedChip(
              number: bed.number,
              selected: selected,
              onTap: () {
                setState(() {
                  if (selected) {
                    selectedBeds.remove(bed.number);
                  } else {
                    selectedBeds.add(bed.number);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Product'),
        const SizedBox(height: 8),
        CupertinoSlidingSegmentedControl<String>(
          groupValue: selectedProduct.name,
          children: {
            for (final product in products)
              product.name: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(product.name, style: const TextStyle(fontSize: 12)),
              ),
          },
          onValueChanged: (value) {
            if (value == null) return;
            setState(() {
              selectedProduct = products.firstWhere((product) => product.name == value);
              withholdingDays = selectedProduct.withholdingDays;
            });
          },
        ),
        const SizedBox(height: 16),
        FormCard(
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Withholding days', style: TextStyle(fontWeight: FontWeight.w700))),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: withholdingDays > 0 ? () => setState(() => withholdingDays--) : null,
                    child: const Icon(CupertinoIcons.minus_circle),
                  ),
                  Text('$withholdingDays', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => withholdingDays++),
                    child: const Icon(CupertinoIcons.plus_circle),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CupertinoTextField(
                controller: reasonController,
                placeholder: 'Reason, e.g. aphids or mildew',
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(14),
                ),
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
  const GardenMapScreen({
    required this.selectedBed,
    required this.bedStates,
    required this.onSelectBed,
    required this.onLogBed,
    super.key,
  });

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
      subtitle: 'Tap a bed to mark spraying',
      children: [
        Container(
          height: 560,
          padding: const EdgeInsets.all(12),
          decoration: cardDecoration,
          child: InteractiveGardenMap(
            selectedBed: selectedBed,
            bedStates: bedStates,
            onSelect: onSelectBed,
          ),
        ),
        const SizedBox(height: 14),
        BedDetailCard(
          bed: bed,
          state: state,
          onLogSpray: () => onLogBed(bed.number),
        ),
      ],
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
          child: CustomPaint(
            painter: GardenMapPainter(selectedBed: selectedBed, bedStates: bedStates),
            size: Size.infinite,
          ),
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

    for (final bed in bedZones) {
      drawBed(canvas, size, bed);
    }
  }

  void drawGrid(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFEDE8DE)..strokeWidth = .45;
    for (double x = 0; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void drawBed(Canvas canvas, Size size, BedZone bed) {
    final rect = scaleRect(bed.bounds, size);
    final selected = bed.number == selectedBed;
    final waiting = bedStates[bed.number]!.status == 'Wait';
    final fill = selected ? const Color(0xFFEAF3FF) : waiting ? const Color(0xFFFFF1D6) : const Color(0xFFFEFAF2);
    final border = selected ? CupertinoColors.activeBlue : waiting ? CupertinoColors.systemOrange : const Color(0xFF7A3B12);
    roundedRect(canvas, rect, fill, border, selected ? 4 : 2);
    if (waiting) canvas.drawCircle(rect.topRight + const Offset(-12, 12), 5, Paint()..color = CupertinoColors.systemOrange);
    drawNumber(canvas, rect.center, bed.number, selected);
  }

  void drawOutline(Canvas canvas, Size size, Rect rect) {
    roundedRect(canvas, scaleRect(rect, size), const Color(0x00FFFFFF), const Color(0xFF7A3B12), 2);
  }

  void drawPath(Canvas canvas, Size size, Rect rect) {
    final scaled = scaleRect(rect, size);
    canvas.drawRRect(RRect.fromRectAndRadius(scaled, const Radius.circular(3)), Paint()..color = const Color(0xFFC7C7C7));
    final tilePaint = Paint()..color = CupertinoColors.white..strokeWidth = .7;
    for (double y = scaled.top + 20; y < scaled.bottom; y += 24) {
      canvas.drawLine(Offset(scaled.left, y), Offset(scaled.right, y), tilePaint);
    }
  }

  void roundedRect(Canvas canvas, Rect rect, Color fill, Color border, double width) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(7));
    canvas.drawRRect(rrect, Paint()..color = fill);
    canvas.drawRRect(rrect, Paint()..color = border..style = PaintingStyle.stroke..strokeWidth = width);
  }

  void drawNumber(Canvas canvas, Offset center, int number, bool selected) {
    canvas.drawCircle(center, selected ? 17 : 15, Paint()..color = selected ? CupertinoColors.activeBlue : const Color(0xFF9A6A3A));
    final text = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(color: CupertinoColors.white, fontSize: number > 9 ? 14 : 16, fontWeight: FontWeight.w800),
      ),
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
      children: records.isEmpty
          ? [const EmptyCard('No spray records yet.')]
          : records.map((record) => SprayRecordCard(record: record)).toList(),
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
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            Text(title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 16, color: CupertinoColors.secondaryLabel)),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({required this.label, required this.value, required this.detail, super.key});

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(CupertinoIcons.check_mark_circled_solid, color: CupertinoColors.activeGreen),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
          Text(detail, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
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
          color: selected ? CupertinoColors.activeBlue : CupertinoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? CupertinoColors.activeBlue : const Color(0xFFD1D1D6), width: 2),
        ),
        child: Text('$number', style: TextStyle(color: selected ? CupertinoColors.white : CupertinoColors.black, fontWeight: FontWeight.w800)),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Bed ${bed.number}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
              StatusPill(status: state.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(bed.label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(state.lastSpray, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
          const SizedBox(height: 12),
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
      decoration: cardDecoration,
      child: Row(
        children: [
          const Icon(CupertinoIcons.drop_fill, color: CupertinoColors.activeGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.product, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                Text('Beds ${record.bedNumbers.join(', ')} · ${record.reason}', style: const TextStyle(color: CupertinoColors.secondaryLabel)),
                Text('Safe ${dateLabel(record.safeDate)}', style: const TextStyle(fontSize: 13)),
              ],
            ),
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
      decoration: cardDecoration,
      child: Row(
        children: [
          const Icon(CupertinoIcons.cube_box_fill, color: CupertinoColors.activeGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                Text(product.type, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
              ],
            ),
          ),
          Text('${product.withholdingDays} days', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class FormCard extends StatelessWidget {
  const FormCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(16), decoration: cardDecoration, child: child);
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({required this.title, required this.onPressed, super.key});

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton.filled(
      padding: const EdgeInsets.symmetric(vertical: 13),
      borderRadius: BorderRadius.circular(16),
      onPressed: onPressed,
      child: Text(title),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: waiting ? const Color(0xFFFFF1D6) : const Color(0xFFE5F7E8), borderRadius: BorderRadius.circular(999)),
      child: Text(status, style: TextStyle(color: waiting ? CupertinoColors.systemOrange : CupertinoColors.activeGreen, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800));
}

class EmptyCard extends StatelessWidget {
  const EmptyCard(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration,
      child: Text(message, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
    );
  }
}

Rect scaleRect(Rect r, Size size) => Rect.fromLTWH(r.left * size.width, r.top * size.height, r.width * size.width, r.height * size.height);

const cardShadow = [BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 8))];
final cardDecoration = BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(22), boxShadow: cardShadow);
