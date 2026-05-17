import 'package:flutter/cupertino.dart';

void main() => runApp(const SprayTrackerApp());

class AppColor {
  static const background = Color(0xFFF6F5F0);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF1EFE8);
  static const ink = Color(0xFF1F241F);
  static const muted = Color(0xFF697067);
  static const line = Color(0xFFE0DDD4);
  static const primary = Color(0xFF315F3A);
  static const primarySoft = Color(0xFFE6EFE8);
  static const warning = Color(0xFFC9822B);
  static const warningSoft = Color(0xFFFFF0D8);
  static const danger = Color(0xFFB84B44);
  static const dangerSoft = Color(0xFFF9E6E3);
  static const earth = Color(0xFF7A5230);
  static const path = Color(0xFFB8B4AA);
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
        primaryColor: AppColor.primary,
        scaffoldBackgroundColor: AppColor.background,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(color: AppColor.ink, fontSize: 16),
        ),
      ),
      home: SprayTrackerHome(),
    );
  }
}

class GardenBed {
  const GardenBed(this.number, this.bounds, this.group);

  final int number;
  final Rect bounds;
  final String group;
}

class BedPlant {
  const BedPlant({required this.name});

  final String name;

  String get shortLabel {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return '';
    final words = cleaned.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
    return cleaned.length <= 3 ? cleaned.toUpperCase() : cleaned.substring(0, 3).toUpperCase();
  }
}

class SprayProduct {
  const SprayProduct({required this.id, required this.name, required this.type, required this.withholdingDays});

  final int id;
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
    required this.notes,
    required this.sprayedAt,
    required this.withholdingDays,
  });

  final int id;
  final List<int> bedNumbers;
  final String product;
  final String reason;
  final String notes;
  final DateTime sprayedAt;
  final int withholdingDays;

  DateTime get safeDate => sprayedAt.add(Duration(days: withholdingDays));
}

class BedStatus {
  const BedStatus({required this.status, required this.summary, required this.daysRemaining});

  final String status;
  final String summary;
  final int daysRemaining;
}

const gardenBeds = [
  GardenBed(1, Rect.fromLTWH(.06, .08, .20, .12), 'Compound Area'),
  GardenBed(2, Rect.fromLTWH(.36, .08, .15, .31), 'Compound Area'),
  GardenBed(3, Rect.fromLTWH(.55, .08, .10, .085), 'Top Beds'),
  GardenBed(4, Rect.fromLTWH(.70, .08, .25, .07), 'Right Side'),
  GardenBed(5, Rect.fromLTWH(.70, .18, .25, .07), 'Right Side'),
  GardenBed(6, Rect.fromLTWH(.70, .28, .25, .07), 'Right Side'),
  GardenBed(7, Rect.fromLTWH(.70, .38, .25, .07), 'Right Side'),
  GardenBed(8, Rect.fromLTWH(.70, .48, .25, .07), 'Right Side'),
  GardenBed(9, Rect.fromLTWH(.70, .58, .25, .07), 'Right Side'),
  GardenBed(10, Rect.fromLTWH(.70, .68, .25, .07), 'Right Side'),
  GardenBed(11, Rect.fromLTWH(.70, .78, .25, .08), 'Right Side'),
  GardenBed(12, Rect.fromLTWH(.04, .42, .46, .07), 'Left Side'),
  GardenBed(13, Rect.fromLTWH(.04, .53, .46, .07), 'Left Side'),
  GardenBed(14, Rect.fromLTWH(.04, .64, .46, .07), 'Left Side'),
  GardenBed(15, Rect.fromLTWH(.04, .75, .46, .07), 'Left Side'),
  GardenBed(16, Rect.fromLTWH(.04, .92, .91, .045), 'Long Beds'),
  GardenBed(17, Rect.fromLTWH(.04, .01, .91, .04), 'Long Beds'),
];

const compoundOuter = Rect.fromLTWH(.04, .07, .47, .33);
const compoundPath = Rect.fromLTWH(.275, .08, .045, .31);
const compoundLowerLeft = Rect.fromLTWH(.06, .24, .20, .15);
const mainPath = Rect.fromLTWH(.55, .17, .045, .72);

String dateLabel(DateTime date) => '${date.day}/${date.month}/${date.year}';
String shortDate(DateTime date) => '${date.day} ${monthName(date.month)}';
String monthName(int month) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month - 1];
Rect scaleRect(Rect r, Size size) => Rect.fromLTWH(r.left * size.width, r.top * size.height, r.width * size.width, r.height * size.height);

class SprayTrackerHome extends StatefulWidget {
  const SprayTrackerHome({super.key});

  @override
  State<SprayTrackerHome> createState() => _SprayTrackerHomeState();
}

class _SprayTrackerHomeState extends State<SprayTrackerHome> {
  int currentTab = 0;
  int selectedBed = 4;
  int nextRecordId = 1;
  int nextProductId = 4;
  Set<int> selectedBeds = {4};
  String? actionMessage;

  final Map<int, BedPlant> plants = {};
  late List<SprayProduct> products;
  List<SprayRecord> records = [];

  @override
  void initState() {
    super.initState();
    products = const [
      SprayProduct(id: 1, name: 'Neem Oil', type: 'Pest control', withholdingDays: 3),
      SprayProduct(id: 2, name: 'Copper Spray', type: 'Fungicide', withholdingDays: 7),
      SprayProduct(id: 3, name: 'Seaweed Tonic', type: 'Plant tonic', withholdingDays: 1),
    ].toList();
  }

  BedStatus statusForBed(int bedNumber) {
    final latest = records.where((record) => record.bedNumbers.contains(bedNumber)).firstOrNull;
    if (latest == null) {
      return const BedStatus(status: 'Safe', summary: 'No recent spray', daysRemaining: 0);
    }

    final waiting = latest.safeDate.isAfter(DateTime.now());
    final remaining = latest.safeDate.difference(DateTime.now()).inDays + 1;
    return BedStatus(
      status: waiting ? 'Wait' : 'Safe',
      summary: '${latest.product} · safe ${shortDate(latest.safeDate)}',
      daysRemaining: waiting ? remaining.clamp(1, 999) : 0,
    );
  }

  int get waitCount => gardenBeds.where((bed) => statusForBed(bed.number).status == 'Wait').length;
  int get safeCount => gardenBeds.length - waitCount;
  List<SprayRecord> get waitingRecords => records.where((record) => record.safeDate.isAfter(DateTime.now())).toList();

  void changeTab(int index) => setState(() => currentTab = index);

  void selectBedOnMap(int bedNumber) {
    setState(() => selectedBed = bedNumber);
  }

  void openLog(Set<int> beds) {
    setState(() {
      selectedBeds = beds.isEmpty ? {selectedBed} : {...beds};
      currentTab = 2;
    });
  }

  void saveSpray({required Set<int> beds, required SprayProduct product, required String reason, required String notes, required int withholdingDays}) {
    if (beds.isEmpty) {
      setState(() => actionMessage = 'Choose at least one bed before saving.');
      return;
    }

    final sortedBeds = beds.toList()..sort();
    setState(() {
      records.insert(
        0,
        SprayRecord(
          id: nextRecordId++,
          bedNumbers: sortedBeds,
          product: product.name,
          reason: reason.trim().isEmpty ? 'General spray' : reason.trim(),
          notes: notes.trim(),
          sprayedAt: DateTime.now(),
          withholdingDays: withholdingDays,
        ),
      );
      selectedBeds = sortedBeds.toSet();
      selectedBed = sortedBeds.first;
      actionMessage = 'Spray saved for Bed ${sortedBeds.join(', ')}';
      currentTab = 0;
    });
  }

  void setPlantForBed(int bedNumber, BedPlant plant) {
    setState(() {
      plants[bedNumber] = plant;
      selectedBed = bedNumber;
      actionMessage = '${plant.name} added to Bed $bedNumber';
    });
  }

  void clearPlantForBed(int bedNumber) {
    setState(() {
      plants.remove(bedNumber);
      selectedBed = bedNumber;
      actionMessage = 'Planting cleared from Bed $bedNumber';
    });
  }

  void clearBedSprays(int bedNumber) {
    setState(() {
      final before = records.length;
      records = records.where((record) => !record.bedNumbers.contains(bedNumber)).toList();
      selectedBed = bedNumber;
      actionMessage = before == records.length ? 'Bed $bedNumber has no spray records' : 'Spray records cleared from Bed $bedNumber';
    });
  }

  void removeRecord(int id) {
    setState(() {
      records = records.where((record) => record.id != id).toList();
      actionMessage = 'Spray record removed';
    });
  }

  void clearAllHistory() {
    setState(() {
      records = [];
      actionMessage = 'All spray history cleared';
    });
  }

  void addProduct(SprayProduct product) {
    setState(() {
      products.add(SprayProduct(id: nextProductId++, name: product.name, type: product.type, withholdingDays: product.withholdingDays));
      actionMessage = '${product.name} added';
    });
  }

  void removeProduct(int id) {
    setState(() {
      final removed = products.where((product) => product.id == id).map((product) => product.name).firstOrNull;
      products = products.where((product) => product.id != id).toList();
      if (products.isEmpty) {
        products.add(SprayProduct(id: nextProductId++, name: 'General Spray', type: 'Custom product', withholdingDays: 1));
      }
      actionMessage = removed == null ? 'Product not found' : '$removed removed';
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        safeCount: safeCount,
        waitCount: waitCount,
        records: records,
        waitingRecords: waitingRecords,
        plants: plants,
        actionMessage: actionMessage,
        onOpenLog: () => openLog(selectedBeds),
      ),
      VisualMapScreen(
        selectedBed: selectedBed,
        plants: plants,
        actionMessage: actionMessage,
        bedStatus: statusForBed,
        onSelectBed: selectBedOnMap,
        onSetPlant: setPlantForBed,
        onClearPlant: clearPlantForBed,
        onLogBed: (bedNumber) => openLog({bedNumber}),
        onClearSprays: clearBedSprays,
      ),
      LogSprayScreen(
        key: ValueKey('${selectedBeds.join(',')}-${products.length}'),
        initialBeds: selectedBeds,
        products: products,
        plants: plants,
        onSave: saveSpray,
      ),
      HistoryScreen(records: records, actionMessage: actionMessage, onRemove: removeRecord, onClearAll: clearAllHistory),
      ProductsScreen(products: products, actionMessage: actionMessage, onAdd: addProduct, onRemove: removeProduct),
    ];

    return CupertinoPageScaffold(
      backgroundColor: AppColor.background,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(child: IndexedStack(index: currentTab, children: pages)),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xFCFFFFFF),
                border: Border(top: BorderSide(color: AppColor.line)),
              ),
              child: CupertinoTabBar(
                currentIndex: currentTab,
                onTap: changeTab,
                backgroundColor: const Color(0xFCFFFFFF),
                activeColor: AppColor.primary,
                inactiveColor: AppColor.muted,
                items: const [
                  BottomNavigationBarItem(icon: Icon(CupertinoIcons.house), label: 'Dashboard'),
                  BottomNavigationBarItem(icon: Icon(CupertinoIcons.map), label: 'Map'),
                  BottomNavigationBarItem(icon: Icon(CupertinoIcons.plus_circle_fill), label: 'Log'),
                  BottomNavigationBarItem(icon: Icon(CupertinoIcons.time), label: 'History'),
                  BottomNavigationBarItem(icon: Icon(CupertinoIcons.cube_box), label: 'Products'),
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
  const DashboardScreen({required this.safeCount, required this.waitCount, required this.records, required this.waitingRecords, required this.plants, required this.actionMessage, required this.onOpenLog, super.key});

  final int safeCount;
  final int waitCount;
  final List<SprayRecord> records;
  final List<SprayRecord> waitingRecords;
  final Map<int, BedPlant> plants;
  final String? actionMessage;
  final VoidCallback onOpenLog;

  @override
  Widget build(BuildContext context) {
    final nextSafe = waitingRecords.isEmpty ? null : waitingRecords.reduce((a, b) => a.safeDate.isBefore(b.safeDate) ? a : b);
    return AppPage(
      title: 'Spray Tracker',
      subtitle: 'Spray records, withholding periods, and bed status.',
      children: [
        if (actionMessage != null) ...[ActionBanner(message: actionMessage!), const SizedBox(height: 12)],
        DashboardHero(safeCount: safeCount, waitCount: waitCount, plantedCount: plants.length),
        const SizedBox(height: 18),
        NextSafeCard(record: nextSafe),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Recent sprays'),
        const SizedBox(height: 10),
        if (records.isEmpty) const EmptyCard('No spray records yet.') else ...records.take(3).map((record) => SprayRecordCard(record: record)),
        const SizedBox(height: 12),
        PrimaryButton(title: 'Log spray', onPressed: onOpenLog),
      ],
    );
  }
}

class DashboardHero extends StatelessWidget {
  const DashboardHero({required this.safeCount, required this.waitCount, required this.plantedCount, super.key});

  final int safeCount;
  final int waitCount;
  final int plantedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColor.primary, borderRadius: BorderRadius.circular(24), boxShadow: shadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Current status', style: TextStyle(color: CupertinoColors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: BigMetric(title: 'Safe', value: safeCount)),
          const SizedBox(width: 12),
          Expanded(child: BigMetric(title: 'Withholding', value: waitCount)),
        ]),
        const SizedBox(height: 14),
        Text('$plantedCount beds assigned', style: const TextStyle(color: Color(0xEFFFFFFF), fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class BigMetric extends StatelessWidget {
  const BigMetric({required this.title, required this.value, super.key});

  final String title;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Text(title, style: const TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('$value', style: const TextStyle(color: CupertinoColors.white, fontSize: 34, fontWeight: FontWeight.w900)),
        const Text('beds', style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class NextSafeCard extends StatelessWidget {
  const NextSafeCard({required this.record, super.key});

  final SprayRecord? record;

  @override
  Widget build(BuildContext context) {
    if (record == null) return const InfoCard(title: 'No active withholding period', subtitle: 'All spray records are currently safe.', icon: CupertinoIcons.check_mark_circled);
    final days = record!.safeDate.difference(DateTime.now()).inDays + 1;
    return InfoCard(title: 'Next safe harvest', subtitle: 'Bed ${record!.bedNumbers.join(', ')} · ${shortDate(record!.safeDate)}', trailing: '$days days', icon: CupertinoIcons.calendar);
  }
}

class VisualMapScreen extends StatelessWidget {
  const VisualMapScreen({required this.selectedBed, required this.plants, required this.actionMessage, required this.bedStatus, required this.onSelectBed, required this.onSetPlant, required this.onClearPlant, required this.onLogBed, required this.onClearSprays, super.key});

  final int selectedBed;
  final Map<int, BedPlant> plants;
  final String? actionMessage;
  final BedStatus Function(int) bedStatus;
  final ValueChanged<int> onSelectBed;
  final void Function(int bedNumber, BedPlant plant) onSetPlant;
  final ValueChanged<int> onClearPlant;
  final ValueChanged<int> onLogBed;
  final ValueChanged<int> onClearSprays;

  @override
  Widget build(BuildContext context) {
    final plant = plants[selectedBed];
    final status = bedStatus(selectedBed);
    return AppPage(
      title: 'Garden Map',
      subtitle: 'Assign crops and manage spray records by bed.',
      children: [
        if (actionMessage != null) ...[ActionBanner(message: actionMessage!), const SizedBox(height: 12)],
        GardenVisualMap(selectedBed: selectedBed, plants: plants, bedStatus: bedStatus, onSelectBed: onSelectBed),
        const SizedBox(height: 14),
        SelectedBedPanel(
          bedNumber: selectedBed,
          plant: plant,
          status: status,
          onAddPlant: () => showPlantDialog(context, selectedBed, plant, onSetPlant),
          onClearPlant: plant == null ? null : () => onClearPlant(selectedBed),
          onLog: () => onLogBed(selectedBed),
          onClearSprays: () => onClearSprays(selectedBed),
        ),
      ],
    );
  }
}

class GardenVisualMap extends StatelessWidget {
  const GardenVisualMap({required this.selectedBed, required this.plants, required this.bedStatus, required this.onSelectBed, super.key});

  final int selectedBed;
  final Map<int, BedPlant> plants;
  final BedStatus Function(int) bedStatus;
  final ValueChanged<int> onSelectBed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 560,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColor.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColor.line), boxShadow: subtleShadow),
      child: LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(children: [
          Positioned.fill(child: CustomPaint(painter: GridPainter())),
          MapOutline(rect: compoundOuter, size: size),
          MapOutline(rect: compoundLowerLeft, size: size),
          MapPath(rect: compoundPath, size: size),
          MapPath(rect: mainPath, size: size),
          ...gardenBeds.map((bed) => MapBedTile(bed: bed, rect: scaleRect(bed.bounds, size), selected: bed.number == selectedBed, plant: plants[bed.number], status: bedStatus(bed.number), onTap: () => onSelectBed(bed.number))),
        ]);
      }),
    );
  }
}

class MapBedTile extends StatelessWidget {
  const MapBedTile({required this.bed, required this.rect, required this.selected, required this.plant, required this.status, required this.onTap, super.key});

  final GardenBed bed;
  final Rect rect;
  final bool selected;
  final BedPlant? plant;
  final BedStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final waiting = status.status == 'Wait';
    return Positioned.fromRect(
      rect: rect,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: waiting ? AppColor.warningSoft : plant == null ? const Color(0xFFFCFBF7) : AppColor.primarySoft,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: selected ? CupertinoColors.activeBlue : waiting ? AppColor.warning : AppColor.earth, width: selected ? 3 : 1.7),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(plant?.shortLabel ?? '${bed.number}', style: const TextStyle(color: AppColor.ink, fontSize: 13, fontWeight: FontWeight.w900)),
                if (plant != null) Text(plant!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColor.muted, fontSize: 8, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class MapOutline extends StatelessWidget {
  const MapOutline({required this.rect, required this.size, super.key});

  final Rect rect;
  final Size size;

  @override
  Widget build(BuildContext context) => Positioned.fromRect(
        rect: scaleRect(rect, size),
        child: IgnorePointer(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), border: Border.all(color: AppColor.earth, width: 1.7)))),
      );
}

class MapPath extends StatelessWidget {
  const MapPath({required this.rect, required this.size, super.key});

  final Rect rect;
  final Size size;

  @override
  Widget build(BuildContext context) => Positioned.fromRect(
        rect: scaleRect(rect, size),
        child: IgnorePointer(child: Container(decoration: BoxDecoration(color: AppColor.path, borderRadius: BorderRadius.circular(3)))),
      );
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEDEAE2)
      ..strokeWidth = .45;
    for (double x = 0; x < size.width; x += 12) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += 12) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SelectedBedPanel extends StatelessWidget {
  const SelectedBedPanel({required this.bedNumber, required this.plant, required this.status, required this.onAddPlant, required this.onClearPlant, required this.onLog, required this.onClearSprays, super.key});

  final int bedNumber;
  final BedPlant? plant;
  final BedStatus status;
  final VoidCallback onAddPlant;
  final VoidCallback? onClearPlant;
  final VoidCallback onLog;
  final VoidCallback onClearSprays;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('Bed $bedNumber', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))), StatusPill(status: status.status)]),
      const SizedBox(height: 8),
      Text(plant == null ? 'Empty bed' : plant!.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(status.summary, style: const TextStyle(color: AppColor.muted)),
      const SizedBox(height: 14),
      Row(children: [Expanded(child: PrimaryButton(title: plant == null ? 'Add crop' : 'Edit crop', onPressed: onAddPlant)), const SizedBox(width: 10), Expanded(child: SecondaryButton(title: 'Log spray', icon: CupertinoIcons.drop_fill, onPressed: onLog))]),
      const SizedBox(height: 10),
      Row(children: [Expanded(child: DestructiveButton(title: 'Clear spray', onPressed: onClearSprays)), const SizedBox(width: 10), Expanded(child: DestructiveButton(title: 'Clear crop', onPressed: onClearPlant))]),
    ]));
  }
}

void showPlantDialog(BuildContext context, int bedNumber, BedPlant? current, void Function(int, BedPlant) onSave) {
  final name = TextEditingController(text: current?.name ?? '');
  showCupertinoDialog<void>(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: Text(current == null ? 'Assign crop' : 'Edit crop'),
      content: Column(children: [
        const SizedBox(height: 12),
        Text('Bed $bedNumber', style: const TextStyle(color: AppColor.muted)),
        const SizedBox(height: 8),
        CupertinoTextField(controller: name, placeholder: 'Crop name, e.g. Tomatoes'),
      ]),
      actions: [
        CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
        CupertinoDialogAction(isDefaultAction: true, child: const Text('Save'), onPressed: () {
          if (name.text.trim().isNotEmpty) onSave(bedNumber, BedPlant(name: name.text.trim()));
          Navigator.pop(context);
        }),
      ],
    ),
  );
}

class LogSprayScreen extends StatefulWidget {
  const LogSprayScreen({required this.initialBeds, required this.products, required this.plants, required this.onSave, super.key});

  final Set<int> initialBeds;
  final List<SprayProduct> products;
  final Map<int, BedPlant> plants;
  final void Function({required Set<int> beds, required SprayProduct product, required String reason, required String notes, required int withholdingDays}) onSave;

  @override
  State<LogSprayScreen> createState() => _LogSprayScreenState();
}

class _LogSprayScreenState extends State<LogSprayScreen> {
  int step = 0;
  late Set<int> selectedBeds;
  late SprayProduct selectedProduct;
  late int withholdingDays;
  final reasonController = TextEditingController();
  final notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedBeds = {...widget.initialBeds};
    selectedProduct = widget.products.first;
    withholdingDays = selectedProduct.withholdingDays;
  }

  @override
  void dispose() {
    reasonController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void goNext() => setState(() => step = (step + 1).clamp(0, 3));
  void goBack() => setState(() => step = (step - 1).clamp(0, 3));
  void save() => widget.onSave(beds: selectedBeds, product: selectedProduct, reason: reasonController.text, notes: notesController.text, withholdingDays: withholdingDays);

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Log Spray',
      subtitle: ['Select beds', 'Select product', 'Add details', 'Review and save'][step],
      leading: step == 0 ? null : CupertinoButton(padding: EdgeInsets.zero, onPressed: goBack, child: const Icon(CupertinoIcons.back, color: AppColor.ink)),
      children: [
        StepProgress(step: step),
        const SizedBox(height: 22),
        if (step == 0) SelectBedsStep(selectedBeds: selectedBeds, plants: widget.plants, onChanged: (beds) => setState(() => selectedBeds = beds)),
        if (step == 1) SelectProductStep(products: widget.products, selected: selectedProduct, onSelected: (product) => setState(() { selectedProduct = product; withholdingDays = product.withholdingDays; })),
        if (step == 2) DetailsStep(reasonController: reasonController, notesController: notesController, withholdingDays: withholdingDays, onDecrease: withholdingDays > 0 ? () => setState(() => withholdingDays--) : null, onIncrease: () => setState(() => withholdingDays++)),
        if (step == 3) ReviewStep(beds: selectedBeds, product: selectedProduct, reason: reasonController.text, notes: notesController.text, withholdingDays: withholdingDays),
        const SizedBox(height: 20),
        Row(children: [
          if (step > 0) Expanded(child: SecondaryButton(title: 'Back', icon: CupertinoIcons.back, onPressed: goBack)),
          if (step > 0) const SizedBox(width: 12),
          Expanded(child: PrimaryButton(title: step == 3 ? 'Save Spray' : ['Next: Product', 'Next: Details', 'Next: Review'][step], onPressed: step == 3 ? save : goNext)),
        ]),
      ],
    );
  }
}

class StepProgress extends StatelessWidget {
  const StepProgress({required this.step, super.key});

  final int step;

  @override
  Widget build(BuildContext context) => Row(children: List.generate(4, (index) => Expanded(child: Row(children: [
        Expanded(child: Container(height: 3, color: index <= step ? AppColor.primary : AppColor.line)),
        Container(width: 26, height: 26, alignment: Alignment.center, decoration: BoxDecoration(color: index <= step ? AppColor.primary : AppColor.surfaceSoft, shape: BoxShape.circle), child: Text('${index + 1}', style: TextStyle(color: index <= step ? CupertinoColors.white : AppColor.muted, fontWeight: FontWeight.w900, fontSize: 12))),
      ]))));
}

class SelectBedsStep extends StatelessWidget {
  const SelectBedsStep({required this.selectedBeds, required this.plants, required this.onChanged, super.key});

  final Set<int> selectedBeds;
  final Map<int, BedPlant> plants;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Select beds'),
        const SizedBox(height: 6),
        Text('${selectedBeds.length} selected', style: const TextStyle(color: AppColor.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: gardenBeds.map((bed) => BedChip(number: bed.number, selected: selectedBeds.contains(bed.number), label: plants[bed.number]?.shortLabel, onTap: () { final next = {...selectedBeds}; next.contains(bed.number) ? next.remove(bed.number) : next.add(bed.number); onChanged(next); })).toList()),
      ]);
}

class SelectProductStep extends StatelessWidget {
  const SelectProductStep({required this.products, required this.selected, required this.onSelected, super.key});

  final List<SprayProduct> products;
  final SprayProduct selected;
  final ValueChanged<SprayProduct> onSelected;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Select product'),
        const SizedBox(height: 12),
        ...products.map((product) => ProductSelectCard(product: product, selected: product.id == selected.id, onTap: () => onSelected(product))),
      ]);
}

class ProductSelectCard extends StatelessWidget {
  const ProductSelectCard({required this.product, required this.selected, required this.onTap, super.key});

  final SprayProduct product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: selected ? AppColor.primarySoft : AppColor.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? AppColor.primary : AppColor.line), boxShadow: subtleShadow),
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColor.surfaceSoft, borderRadius: BorderRadius.circular(12)), child: const Icon(CupertinoIcons.drop, color: AppColor.primary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, style: const TextStyle(color: AppColor.ink, fontWeight: FontWeight.w900)), Text('${product.type} · ${product.withholdingDays} days', style: const TextStyle(color: AppColor.muted, fontSize: 12))])),
            if (selected) const Icon(CupertinoIcons.check_mark_circled_solid, color: AppColor.primary),
          ]),
        ),
      );
}

class DetailsStep extends StatelessWidget {
  const DetailsStep({required this.reasonController, required this.notesController, required this.withholdingDays, required this.onDecrease, required this.onIncrease, super.key});

  final TextEditingController reasonController;
  final TextEditingController notesController;
  final int withholdingDays;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Add details'),
        const SizedBox(height: 14),
        FieldLabel(label: 'Reason', child: CupertinoTextField(controller: reasonController, placeholder: 'Aphids, mildew, tonic, etc.', padding: const EdgeInsets.all(14), decoration: inputDecoration)),
        const SizedBox(height: 14),
        PremiumCard(child: Row(children: [const Expanded(child: Text('Withholding period', style: TextStyle(fontWeight: FontWeight.w900))), StepButton(icon: CupertinoIcons.minus, onPressed: onDecrease), Text('$withholdingDays', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), StepButton(icon: CupertinoIcons.plus, onPressed: onIncrease)])),
        const SizedBox(height: 14),
        FieldLabel(label: 'Notes optional', child: CupertinoTextField(controller: notesController, placeholder: 'Application notes', maxLines: 4, padding: const EdgeInsets.all(14), decoration: inputDecoration)),
      ]);
}

class ReviewStep extends StatelessWidget {
  const ReviewStep({required this.beds, required this.product, required this.reason, required this.notes, required this.withholdingDays, super.key});

  final Set<int> beds;
  final SprayProduct product;
  final String reason;
  final String notes;
  final int withholdingDays;

  @override
  Widget build(BuildContext context) => PremiumCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Summary'),
        const SizedBox(height: 16),
        SummaryRow('Beds', beds.toList()..sort()),
        SummaryRow('Product', product.name),
        SummaryRow('Date sprayed', dateLabel(DateTime.now())),
        SummaryRow('Reason', reason.trim().isEmpty ? 'General spray' : reason.trim()),
        SummaryRow('Withholding', '$withholdingDays days'),
        SummaryRow('Safe from', dateLabel(DateTime.now().add(Duration(days: withholdingDays)))),
        if (notes.trim().isNotEmpty) SummaryRow('Notes', notes.trim()),
      ]));
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({required this.records, required this.actionMessage, required this.onRemove, required this.onClearAll, super.key});

  final List<SprayRecord> records;
  final String? actionMessage;
  final ValueChanged<int> onRemove;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) => AppPage(title: 'History', subtitle: 'All spray records.', trailing: const Icon(CupertinoIcons.slider_horizontal_3, color: AppColor.ink), children: [
        if (actionMessage != null) ...[ActionBanner(message: actionMessage!), const SizedBox(height: 12)],
        if (records.isNotEmpty) ...[DestructiveButton(title: 'Clear all history', onPressed: onClearAll), const SizedBox(height: 14)],
        if (records.isEmpty) const EmptyCard('No spray records yet.') else ...records.map((record) => SprayRecordCard(record: record, onRemove: () => onRemove(record.id))),
      ]);
}

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({required this.products, required this.actionMessage, required this.onAdd, required this.onRemove, super.key});

  final List<SprayProduct> products;
  final String? actionMessage;
  final ValueChanged<SprayProduct> onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) => AppPage(title: 'Products', subtitle: 'Spray product library.', trailing: CupertinoButton(padding: EdgeInsets.zero, onPressed: () => showAddProductDialog(context, onAdd), child: const Icon(CupertinoIcons.plus, color: AppColor.ink)), children: [
        if (actionMessage != null) ...[ActionBanner(message: actionMessage!), const SizedBox(height: 12)],
        ...products.map((product) => ProductLibraryCard(product: product, onRemove: () => onRemove(product.id))),
      ]);
}

void showAddProductDialog(BuildContext context, ValueChanged<SprayProduct> onAdd) {
  final name = TextEditingController();
  final type = TextEditingController(text: 'Custom product');
  final days = TextEditingController(text: '1');
  showCupertinoDialog<void>(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: const Text('Add product'),
      content: Column(children: [const SizedBox(height: 12), CupertinoTextField(controller: name, placeholder: 'Name'), const SizedBox(height: 8), CupertinoTextField(controller: type, placeholder: 'Type'), const SizedBox(height: 8), CupertinoTextField(controller: days, placeholder: 'Withholding days', keyboardType: TextInputType.number)]),
      actions: [
        CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
        CupertinoDialogAction(isDefaultAction: true, child: const Text('Add'), onPressed: () { final parsedDays = int.tryParse(days.text) ?? 1; if (name.text.trim().isNotEmpty) onAdd(SprayProduct(id: 0, name: name.text.trim(), type: type.text.trim().isEmpty ? 'Custom product' : type.text.trim(), withholdingDays: parsedDays)); Navigator.pop(context); }),
      ],
    ),
  );
}

class AppPage extends StatelessWidget {
  const AppPage({required this.title, required this.subtitle, required this.children, this.leading, this.trailing, super.key});

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 34), children: [
        Row(children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColor.ink)), Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColor.muted))])),
          if (trailing != null) trailing!,
        ]),
        const SizedBox(height: 24),
        ...children,
      ]);
}

class ActionBanner extends StatelessWidget {
  const ActionBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColor.primarySoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColor.primary.withOpacity(.25))), child: Row(children: [const Icon(CupertinoIcons.check_mark_circled_solid, color: AppColor.primary), const SizedBox(width: 10), Expanded(child: Text(message, style: const TextStyle(color: AppColor.primary, fontWeight: FontWeight.w800)))]));
}

class InfoCard extends StatelessWidget {
  const InfoCard({required this.title, required this.subtitle, required this.icon, this.trailing, super.key});

  final String title;
  final String subtitle;
  final IconData icon;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColor.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColor.line), boxShadow: subtleShadow), child: Row(children: [Icon(icon, color: AppColor.primary), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(subtitle, style: const TextStyle(color: AppColor.muted, fontSize: 12))])), if (trailing != null) StatusChip(text: trailing!, color: AppColor.primary, bg: AppColor.primarySoft)]));
}

class PremiumCard extends StatelessWidget {
  const PremiumCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: cardDecoration, child: child);
}

class EmptyCard extends StatelessWidget {
  const EmptyCard(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => PremiumCard(child: Text(message, style: const TextStyle(color: AppColor.muted)));
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.action, super.key});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))), if (action != null) Text(action!, style: const TextStyle(color: AppColor.primary, fontWeight: FontWeight.w800))]);
}

class FieldLabel extends StatelessWidget {
  const FieldLabel({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 8), child]);
}

class SummaryRow extends StatelessWidget {
  const SummaryRow(this.label, this.value, {super.key});

  final String label;
  final Object value;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(label, style: const TextStyle(color: AppColor.muted, fontWeight: FontWeight.w700))), Expanded(child: Text('$value', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800)))]));
}

class BedChip extends StatelessWidget {
  const BedChip({required this.number, required this.selected, required this.onTap, this.label, super.key});

  final int number;
  final bool selected;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, onPressed: onTap, child: Container(width: 46, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: selected ? AppColor.primary : AppColor.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppColor.primary : AppColor.line)), child: Text(label ?? '$number', style: TextStyle(color: selected ? CupertinoColors.white : AppColor.ink, fontWeight: FontWeight.w900, fontSize: label == null ? 14 : 12))));
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final waiting = status == 'Wait';
    return StatusChip(text: status.toUpperCase(), color: waiting ? AppColor.warning : AppColor.primary, bg: waiting ? AppColor.warningSoft : AppColor.primarySoft);
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({required this.text, required this.color, required this.bg, super.key});

  final String text;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)), child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)));
}

class StepButton extends StatelessWidget {
  const StepButton({required this.icon, required this.onPressed, super.key});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, onPressed: onPressed, child: Icon(icon, color: onPressed == null ? AppColor.muted : AppColor.primary));
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({required this.title, required this.onPressed, super.key});

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(color: AppColor.primary, borderRadius: BorderRadius.circular(14), padding: const EdgeInsets.symmetric(vertical: 14), onPressed: onPressed, child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)));
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({required this.title, required this.icon, required this.onPressed, super.key});

  final String title;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(color: AppColor.surfaceSoft, borderRadius: BorderRadius.circular(14), padding: const EdgeInsets.symmetric(vertical: 10), onPressed: onPressed, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 16, color: AppColor.primary), const SizedBox(width: 6), Text(title, style: const TextStyle(color: AppColor.ink, fontWeight: FontWeight.w800))]));
}

class DestructiveButton extends StatelessWidget {
  const DestructiveButton({required this.title, required this.onPressed, super.key});

  final String title;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(color: AppColor.dangerSoft, borderRadius: BorderRadius.circular(14), padding: const EdgeInsets.symmetric(vertical: 10), onPressed: onPressed, child: Text(title, style: TextStyle(color: onPressed == null ? AppColor.muted : AppColor.danger, fontWeight: FontWeight.w800)));
}

class SprayRecordCard extends StatelessWidget {
  const SprayRecordCard({required this.record, this.onRemove, super.key});

  final SprayRecord record;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final waiting = record.safeDate.isAfter(DateTime.now());
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: cardDecoration, child: Row(children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColor.primarySoft, borderRadius: BorderRadius.circular(14)), child: const Icon(CupertinoIcons.drop, color: AppColor.primary)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Bed ${record.bedNumbers.join(', ')}', style: const TextStyle(fontWeight: FontWeight.w900)), Text(record.product, style: const TextStyle(color: AppColor.ink)), Text('${record.withholdingDays} days · ${shortDate(record.sprayedAt)}', style: const TextStyle(color: AppColor.muted, fontSize: 12))])),
      Column(children: [StatusPill(status: waiting ? 'Wait' : 'Safe'), if (onRemove != null) CupertinoButton(padding: EdgeInsets.zero, minSize: 30, onPressed: onRemove, child: const Icon(CupertinoIcons.trash, color: AppColor.danger, size: 20))]),
    ]));
  }
}

class ProductLibraryCard extends StatelessWidget {
  const ProductLibraryCard({required this.product, required this.onRemove, super.key});

  final SprayProduct product;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: cardDecoration, child: Row(children: [
        Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColor.primarySoft, borderRadius: BorderRadius.circular(15)), child: const Icon(CupertinoIcons.cube_box, color: AppColor.primary)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, style: const TextStyle(fontWeight: FontWeight.w900)), Text(product.type, style: const TextStyle(color: AppColor.muted)), Text('Withholding: ${product.withholdingDays} days', style: const TextStyle(color: AppColor.ink, fontSize: 12))])),
        CupertinoButton(padding: EdgeInsets.zero, onPressed: onRemove, child: const Icon(CupertinoIcons.trash, color: AppColor.danger, size: 20)),
      ]));
}

const shadow = [BoxShadow(color: Color(0x16000000), blurRadius: 18, offset: Offset(0, 8))];
const subtleShadow = [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4))];
final cardDecoration = BoxDecoration(color: AppColor.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColor.line), boxShadow: subtleShadow);
final inputDecoration = BoxDecoration(color: AppColor.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColor.line));
