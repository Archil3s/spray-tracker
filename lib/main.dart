import 'package:flutter/cupertino.dart';

void main() => runApp(const SprayTrackerApp());

class AppColor {
  static const bg = Color(0xFFFAF7F0);
  static const card = Color(0xFFFFFFFF);
  static const cream = Color(0xFFF6F1E7);
  static const green = Color(0xFF2F7D32);
  static const green2 = Color(0xFF5FA85F);
  static const greenSoft = Color(0xFFEAF6E7);
  static const orange = Color(0xFFE49A32);
  static const orangeSoft = Color(0xFFFFE9C8);
  static const red = Color(0xFFD64B45);
  static const redSoft = Color(0xFFFFE6E2);
  static const brown = Color(0xFF8B5A2B);
  static const path = Color(0xFFC9C4BA);
  static const text = Color(0xFF20251F);
  static const muted = Color(0xFF71756D);
  static const line = Color(0xFFE8DFD1);
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
        scaffoldBackgroundColor: AppColor.bg,
        textTheme: CupertinoTextThemeData(textStyle: TextStyle(color: AppColor.text, fontSize: 16)),
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
  const BedPlant({required this.name, required this.icon});
  final String name;
  final String icon;
}

class SprayProduct {
  const SprayProduct({required this.id, required this.name, required this.type, required this.icon, required this.withholdingDays});
  final int id;
  final String name;
  final String type;
  final String icon;
  final int withholdingDays;
}

class SprayRecord {
  const SprayRecord({required this.id, required this.bedNumbers, required this.product, required this.reason, required this.notes, required this.sprayedAt, required this.withholdingDays});
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
GardenBed bedByNumber(int number) => gardenBeds.firstWhere((bed) => bed.number == number);

class SprayTrackerHome extends StatefulWidget {
  const SprayTrackerHome({super.key});

  @override
  State<SprayTrackerHome> createState() => _SprayTrackerHomeState();
}

class _SprayTrackerHomeState extends State<SprayTrackerHome> {
  int currentTab = 0;
  int selectedBed = 4;
  int nextRecordId = 4;
  int nextProductId = 4;
  Set<int> selectedBeds = {4};
  String? actionMessage;

  late List<SprayProduct> products;
  late List<SprayRecord> records;
  final Map<int, BedPlant> plants = {};

  @override
  void initState() {
    super.initState();
    products = const [
      SprayProduct(id: 1, name: 'Neem Oil', type: 'Pest control', icon: '🌿', withholdingDays: 3),
      SprayProduct(id: 2, name: 'Copper Spray', type: 'Fungicide', icon: '🛡️', withholdingDays: 7),
      SprayProduct(id: 3, name: 'Seaweed Tonic', type: 'Plant tonic', icon: '🌵', withholdingDays: 1),
    ].toList();
    records = [];
  }

  BedStatus statusForBed(int bedNumber) {
    final latest = records.where((r) => r.bedNumbers.contains(bedNumber)).firstOrNull;
    if (latest == null) return const BedStatus(status: 'Safe', summary: 'No recent sprays', daysRemaining: 0);
    final remaining = latest.safeDate.difference(DateTime.now()).inDays + 1;
    final wait = latest.safeDate.isAfter(DateTime.now());
    return BedStatus(status: wait ? 'Wait' : 'Safe', summary: '${latest.product} · safe ${shortDate(latest.safeDate)}', daysRemaining: wait ? remaining.clamp(1, 999) : 0);
  }

  int get waitCount => gardenBeds.where((b) => statusForBed(b.number).status == 'Wait').length;
  int get safeCount => gardenBeds.length - waitCount;
  List<SprayRecord> get waitingRecords => records.where((r) => r.safeDate.isAfter(DateTime.now())).toList();

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
      records.insert(0, SprayRecord(id: nextRecordId++, bedNumbers: sortedBeds, product: product.name, reason: reason.trim().isEmpty ? 'General spray' : reason.trim(), notes: notes.trim(), sprayedAt: DateTime.now(), withholdingDays: withholdingDays));
      selectedBeds = sortedBeds.toSet();
      selectedBed = sortedBeds.first;
      actionMessage = 'Saved spray for Bed ${sortedBeds.join(', ')}';
      currentTab = 0;
    });
  }

  void setPlantForBed(int bedNumber, BedPlant plant) {
    setState(() {
      plants[bedNumber] = plant;
      selectedBed = bedNumber;
      actionMessage = 'Added ${plant.name} to Bed $bedNumber';
    });
  }

  void clearPlantForBed(int bedNumber) {
    setState(() {
      plants.remove(bedNumber);
      selectedBed = bedNumber;
      actionMessage = 'Cleared veg from Bed $bedNumber';
    });
  }

  void clearBedSprays(int bedNumber) {
    setState(() {
      final before = records.length;
      records = records.where((r) => !r.bedNumbers.contains(bedNumber)).toList();
      selectedBed = bedNumber;
      actionMessage = before == records.length ? 'Bed $bedNumber already has no sprays' : 'Cleared spray records for Bed $bedNumber';
    });
  }

  void removeRecord(int id) {
    setState(() {
      records = records.where((r) => r.id != id).toList();
      actionMessage = 'Removed spray record';
    });
  }

  void clearAllHistory() {
    setState(() {
      records = [];
      actionMessage = 'Cleared all spray history';
    });
  }

  void addProduct(SprayProduct product) {
    setState(() {
      products.add(SprayProduct(id: nextProductId++, name: product.name, type: product.type, icon: product.icon, withholdingDays: product.withholdingDays));
      actionMessage = 'Added ${product.name}';
    });
  }

  void removeProduct(int id) {
    setState(() {
      final removed = products.where((p) => p.id == id).map((p) => p.name).firstOrNull;
      products = products.where((p) => p.id != id).toList();
      if (products.isEmpty) products.add(SprayProduct(id: nextProductId++, name: 'General Spray', type: 'Custom product', icon: '🧪', withholdingDays: 1));
      actionMessage = removed == null ? 'Product not found' : 'Removed $removed';
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(safeCount: safeCount, waitCount: waitCount, records: records, waitingRecords: waitingRecords, plants: plants, actionMessage: actionMessage, onOpenLog: () => openLog(selectedBeds)),
      VisualMapScreen(selectedBed: selectedBed, plants: plants, actionMessage: actionMessage, bedStatus: statusForBed, onSelectBed: selectBedOnMap, onSetPlant: setPlantForBed, onClearPlant: clearPlantForBed, onLogBed: (n) => openLog({n}), onClearSprays: clearBedSprays),
      LogSprayScreen(key: ValueKey('${selectedBeds.join(',')}-${products.length}'), initialBeds: selectedBeds, products: products, plants: plants, onSave: saveSpray),
      HistoryScreen(records: records, actionMessage: actionMessage, onRemove: removeRecord, onClearAll: clearAllHistory),
      ProductsScreen(products: products, actionMessage: actionMessage, onAdd: addProduct, onRemove: removeProduct),
    ];

    return CupertinoPageScaffold(
      backgroundColor: AppColor.bg,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(child: IndexedStack(index: currentTab, children: pages)),
            DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xFCFFFFFF), border: Border(top: BorderSide(color: AppColor.line))),
              child: CupertinoTabBar(
                currentIndex: currentTab,
                onTap: changeTab,
                backgroundColor: const Color(0xFCFFFFFF),
                activeColor: AppColor.green,
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
    final plantedCount = plants.length;
    return AppPage(
      title: 'Dashboard',
      subtitle: 'Your spray safety at a glance.',
      children: [
        if (actionMessage != null) ...[ActionBanner(message: actionMessage!), const SizedBox(height: 12)],
        DashboardHero(safeCount: safeCount, waitCount: waitCount, plantedCount: plantedCount),
        const SizedBox(height: 18),
        NextSafeCard(record: nextSafe),
        const SizedBox(height: 22),
        SectionHeader(title: 'Recent Sprays', action: records.isEmpty ? null : 'View all'),
        const SizedBox(height: 10),
        if (records.isEmpty) const EmptyCard('No spray records yet.') else ...records.take(3).map((r) => SprayRecordCard(record: r)),
        const SizedBox(height: 12),
        PrimaryButton(title: 'Log a spray', onPressed: onOpenLog),
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: const LinearGradient(colors: [Color(0xFF2D7D32), Color(0xFF5F9F50)], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: shadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Today’s Overview', style: TextStyle(color: CupertinoColors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: BigMetric(title: 'Safe to Harvest', value: safeCount)),
          const SizedBox(width: 12),
          Expanded(child: BigMetric(title: 'Do Not Harvest', value: waitCount)),
        ]),
        const SizedBox(height: 12),
        Text('$plantedCount beds have veg assigned', style: const TextStyle(color: Color(0xEFFFFFFF), fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class BigMetric extends StatelessWidget {
  const BigMetric({required this.title, required this.value, super.key});
  final String title;
  final int value;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(18)), child: Column(children: [Text(title, textAlign: TextAlign.center, style: const TextStyle(color: CupertinoColors.white, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 10), Text('$value', style: const TextStyle(color: CupertinoColors.white, fontSize: 36, fontWeight: FontWeight.w900)), const Text('beds', style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.w700))]));
}

class NextSafeCard extends StatelessWidget {
  const NextSafeCard({required this.record, super.key});
  final SprayRecord? record;
  @override
  Widget build(BuildContext context) {
    if (record == null) return const SoftInfoCard(icon: '✅', title: 'All sprayed beds are safe', subtitle: 'No active withholding periods.');
    final days = record!.safeDate.difference(DateTime.now()).inDays + 1;
    return SoftInfoCard(icon: '🌱', title: 'Next Bed Safe', subtitle: 'Bed ${record!.bedNumbers.join(', ')} · safe ${shortDate(record!.safeDate)}', trailing: 'In $days days');
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
      subtitle: 'Tap a bed to add what is planted.',
      children: [
        if (actionMessage != null) ...[ActionBanner(message: actionMessage!), const SizedBox(height: 12)],
        GardenVisualMap(selectedBed: selectedBed, plants: plants, bedStatus: bedStatus, onSelectBed: onSelectBed),
        const SizedBox(height: 14),
        SelectedBedPanel(bedNumber: selectedBed, plant: plant, status: status, onAddPlant: () => showPlantDialog(context, selectedBed, plant, onSetPlant), onClearPlant: plant == null ? null : () => onClearPlant(selectedBed), onLog: () => onLogBed(selectedBed), onClearSprays: () => onClearSprays(selectedBed)),
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
      decoration: BoxDecoration(color: const Color(0xFFFFFBF3), borderRadius: BorderRadius.circular(26), border: Border.all(color: AppColor.line), boxShadow: subtleShadow),
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
    final wait = status.status == 'Wait';
    return Positioned.fromRect(
      rect: rect,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE6F1FF) : wait ? AppColor.orangeSoft : AppColor.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? CupertinoColors.activeBlue : wait ? AppColor.orange : AppColor.brown, width: selected ? 3 : 2),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(plant?.icon ?? '${bed.number}', style: TextStyle(fontSize: plant == null ? 14 : 18, fontWeight: FontWeight.w900, color: plant == null ? AppColor.text : null)),
                if (plant != null) Text(plant!.name, maxLines: 1, style: const TextStyle(color: AppColor.text, fontSize: 9, fontWeight: FontWeight.w700)),
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
  Widget build(BuildContext context) => Positioned.fromRect(rect: scaleRect(rect, size), child: IgnorePointer(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColor.brown, width: 2)))));
}

class MapPath extends StatelessWidget {
  const MapPath({required this.rect, required this.size, super.key});
  final Rect rect;
  final Size size;
  @override
  Widget build(BuildContext context) => Positioned.fromRect(rect: scaleRect(rect, size), child: IgnorePointer(child: Container(decoration: BoxDecoration(color: AppColor.path, borderRadius: BorderRadius.circular(4)))));
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFEFE5D8)..strokeWidth = .5;
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
      Text(plant == null ? 'Empty bed' : '${plant!.icon} ${plant!.name}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(status.summary, style: const TextStyle(color: AppColor.muted)),
      const SizedBox(height: 14),
      Row(children: [Expanded(child: PrimaryButton(title: plant == null ? 'Add veg' : 'Edit veg', onPressed: onAddPlant)), const SizedBox(width: 10), Expanded(child: SecondaryButton(title: 'Log spray', icon: CupertinoIcons.drop_fill, onPressed: onLog))]),
      const SizedBox(height: 10),
      Row(children: [Expanded(child: DestructiveButton(title: 'Clear spray', onPressed: onClearSprays)), const SizedBox(width: 10), Expanded(child: DestructiveButton(title: 'Clear veg', onPressed: onClearPlant ?? () {}))]),
    ]));
  }
}

void showPlantDialog(BuildContext context, int bedNumber, BedPlant? current, void Function(int, BedPlant) onSave) {
  final name = TextEditingController(text: current?.name ?? '');
  final icon = TextEditingController(text: current?.icon ?? '🌱');
  showCupertinoDialog<void>(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: Text(current == null ? 'Add veg to Bed $bedNumber' : 'Edit Bed $bedNumber'),
      content: Column(children: [
        const SizedBox(height: 12),
        CupertinoTextField(controller: name, placeholder: 'Veg name, e.g. Tomatoes'),
        const SizedBox(height: 8),
        CupertinoTextField(controller: icon, placeholder: 'Icon, e.g. 🍅'),
      ]),
      actions: [
        CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
        CupertinoDialogAction(isDefaultAction: true, child: const Text('Save'), onPressed: () { if (name.text.trim().isNotEmpty) onSave(bedNumber, BedPlant(name: name.text.trim(), icon: icon.text.trim().isEmpty ? '🌱' : icon.text.trim())); Navigator.pop(context); }),
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
      subtitle: ['Select beds', 'Select product', 'Add details', 'Review & save'][step],
      leading: step == 0 ? null : CupertinoButton(padding: EdgeInsets.zero, onPressed: goBack, child: const Icon(CupertinoIcons.back, color: AppColor.text)),
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
  Widget build(BuildContext context) => Row(children: List.generate(4, (index) => Expanded(child: Row(children: [Expanded(child: Container(height: 3, color: index <= step ? AppColor.green : AppColor.line)), Container(width: 26, height: 26, alignment: Alignment.center, decoration: BoxDecoration(color: index <= step ? AppColor.green : const Color(0xFFE8E8E8), shape: BoxShape.circle), child: Text('${index + 1}', style: TextStyle(color: index <= step ? CupertinoColors.white : AppColor.muted, fontWeight: FontWeight.w900, fontSize: 12)))]))));
}

class SelectBedsStep extends StatelessWidget {
  const SelectBedsStep({required this.selectedBeds, required this.plants, required this.onChanged, super.key});
  final Set<int> selectedBeds;
  final Map<int, BedPlant> plants;
  final ValueChanged<Set<int>> onChanged;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Select Beds'),
        const SizedBox(height: 6),
        Text('Selected (${selectedBeds.length})', style: const TextStyle(color: AppColor.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: gardenBeds.map((bed) => BedChip(number: bed.number, selected: selectedBeds.contains(bed.number), label: plants[bed.number]?.icon, onTap: () { final next = {...selectedBeds}; next.contains(bed.number) ? next.remove(bed.number) : next.add(bed.number); onChanged(next); })).toList()),
      ]);
}

class SelectProductStep extends StatelessWidget {
  const SelectProductStep({required this.products, required this.selected, required this.onSelected, super.key});
  final List<SprayProduct> products;
  final SprayProduct selected;
  final ValueChanged<SprayProduct> onSelected;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Select Product'),
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
  Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, onPressed: onTap, child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: selected ? AppColor.greenSoft : AppColor.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? AppColor.green : AppColor.line), boxShadow: subtleShadow), child: Row(children: [Text(product.icon, style: const TextStyle(fontSize: 28)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, style: const TextStyle(color: AppColor.text, fontWeight: FontWeight.w900)), Text('${product.type} · ${product.withholdingDays} days', style: const TextStyle(color: AppColor.muted, fontSize: 12))])), if (selected) const Icon(CupertinoIcons.check_mark_circled_solid, color: AppColor.green)])));
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
        const SectionHeader(title: 'Add Details'),
        const SizedBox(height: 14),
        FieldLabel(label: 'Reason', child: CupertinoTextField(controller: reasonController, placeholder: 'Aphids, mildew, tonic, etc.', padding: const EdgeInsets.all(14), decoration: inputDecoration)),
        const SizedBox(height: 14),
        PremiumCard(child: Row(children: [const Expanded(child: Text('Withholding Period', style: TextStyle(fontWeight: FontWeight.w900))), StepButton(icon: CupertinoIcons.minus, onPressed: onDecrease), Text('$withholdingDays', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), StepButton(icon: CupertinoIcons.plus, onPressed: onIncrease)])),
        const SizedBox(height: 14),
        FieldLabel(label: 'Notes optional', child: CupertinoTextField(controller: notesController, placeholder: 'Light spray, focused on undersides...', maxLines: 4, padding: const EdgeInsets.all(14), decoration: inputDecoration)),
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
        SummaryRow('Date Sprayed', dateLabel(DateTime.now())),
        SummaryRow('Reason', reason.trim().isEmpty ? 'General spray' : reason.trim()),
        SummaryRow('Withholding', '$withholdingDays days'),
        SummaryRow('Safe From', dateLabel(DateTime.now().add(Duration(days: withholdingDays)))),
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
  Widget build(BuildContext context) => AppPage(title: 'History', subtitle: 'All your spray records.', trailing: const Icon(CupertinoIcons.slider_horizontal_3, color: AppColor.text), children: [
        if (actionMessage != null) ...[ActionBanner(message: actionMessage!), const SizedBox(height: 12)],
        if (records.isNotEmpty) ...[DestructiveButton(title: 'Clear all history', onPressed: onClearAll), const SizedBox(height: 14)],
        if (records.isEmpty) const EmptyCard('No spray records yet.') else ...records.map((r) => SprayRecordCard(record: r, onRemove: () => onRemove(r.id))),
      ]);
}

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({required this.products, required this.actionMessage, required this.onAdd, required this.onRemove, super.key});
  final List<SprayProduct> products;
  final String? actionMessage;
  final ValueChanged<SprayProduct> onAdd;
  final ValueChanged<int> onRemove;
  @override
  Widget build(BuildContext context) => AppPage(title: 'Products', subtitle: 'Your spray product library.', trailing: CupertinoButton(padding: EdgeInsets.zero, onPressed: () => showAddProductDialog(context, onAdd), child: const Icon(CupertinoIcons.plus, color: AppColor.text)), children: [
        if (actionMessage != null) ...[ActionBanner(message: actionMessage!), const SizedBox(height: 12)],
        ...products.map((p) => ProductLibraryCard(product: p, onRemove: () => onRemove(p.id))),
      ]);
}

void showAddProductDialog(BuildContext context, ValueChanged<SprayProduct> onAdd) {
  final name = TextEditingController();
  final type = TextEditingController(text: 'Custom product');
  final days = TextEditingController(text: '1');
  showCupertinoDialog<void>(
    context: context,
    builder: (_) => CupertinoAlertDialog(
      title: const Text('Add Product'),
      content: Column(children: [const SizedBox(height: 12), CupertinoTextField(controller: name, placeholder: 'Name'), const SizedBox(height: 8), CupertinoTextField(controller: type, placeholder: 'Type'), const SizedBox(height: 8), CupertinoTextField(controller: days, placeholder: 'Withholding days', keyboardType: TextInputType.number)]),
      actions: [
        CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
        CupertinoDialogAction(isDefaultAction: true, child: const Text('Add'), onPressed: () { final parsedDays = int.tryParse(days.text) ?? 1; if (name.text.trim().isNotEmpty) onAdd(SprayProduct(id: 0, name: name.text.trim(), type: type.text.trim().isEmpty ? 'Custom product' : type.text.trim(), icon: '🧪', withholdingDays: parsedDays)); Navigator.pop(context); }),
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
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 34), children: [Row(children: [if (leading != null) ...[leading!, const SizedBox(width: 8)], Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColor.text)), Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColor.muted))])), if (trailing != null) trailing!]), const SizedBox(height: 24), ...children]);
}

class ActionBanner extends StatelessWidget { const ActionBanner({required this.message, super.key}); final String message; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColor.greenSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFBBDDB8))), child: Row(children: [const Icon(CupertinoIcons.check_mark_circled_solid, color: AppColor.green), const SizedBox(width: 10), Expanded(child: Text(message, style: const TextStyle(color: AppColor.green, fontWeight: FontWeight.w800)))])); }
class SoftInfoCard extends StatelessWidget { const SoftInfoCard({required this.icon, required this.title, required this.subtitle, this.trailing, super.key}); final String icon; final String title; final String subtitle; final String? trailing; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColor.greenSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFD2EACF))), child: Row(children: [Text(icon, style: const TextStyle(fontSize: 24)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), Text(subtitle, style: const TextStyle(color: AppColor.muted, fontSize: 12))])), if (trailing != null) StatusChip(text: trailing!, color: AppColor.green, bg: AppColor.card)])); }
class PremiumCard extends StatelessWidget { const PremiumCard({required this.child, super.key}); final Widget child; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: cardDecoration, child: child); }
class EmptyCard extends StatelessWidget { const EmptyCard(this.message, {super.key}); final String message; @override Widget build(BuildContext context) => PremiumCard(child: Text(message, style: const TextStyle(color: AppColor.muted))); }
class SectionHeader extends StatelessWidget { const SectionHeader({required this.title, this.action, super.key}); final String title; final String? action; @override Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))), if (action != null) Text(action!, style: const TextStyle(color: AppColor.green, fontWeight: FontWeight.w800))]); }
class FieldLabel extends StatelessWidget { const FieldLabel({required this.label, required this.child, super.key}); final String label; final Widget child; @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 8), child]); }
class SummaryRow extends StatelessWidget { const SummaryRow(this.label, this.value, {super.key}); final String label; final Object value; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(label, style: const TextStyle(color: AppColor.muted, fontWeight: FontWeight.w700))), Expanded(child: Text('$value', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800)))])); }
class BedChip extends StatelessWidget { const BedChip({required this.number, required this.selected, required this.onTap, this.label, super.key}); final int number; final bool selected; final String? label; final VoidCallback onTap; @override Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, onPressed: onTap, child: Container(width: 46, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: selected ? AppColor.green : AppColor.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? AppColor.green : AppColor.line)), child: Text(label ?? '$number', style: TextStyle(color: selected ? CupertinoColors.white : AppColor.text, fontWeight: FontWeight.w900)))); }
class StatusPill extends StatelessWidget { const StatusPill({required this.status, super.key}); final String status; @override Widget build(BuildContext context) { final wait = status == 'Wait'; return StatusChip(text: status.toUpperCase(), color: wait ? AppColor.orange : AppColor.green, bg: wait ? AppColor.orangeSoft : AppColor.greenSoft); } }
class StatusChip extends StatelessWidget { const StatusChip({required this.text, required this.color, required this.bg, super.key}); final String text; final Color color; final Color bg; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)), child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900))); }
class StepButton extends StatelessWidget { const StepButton({required this.icon, required this.onPressed, super.key}); final IconData icon; final VoidCallback? onPressed; @override Widget build(BuildContext context) => CupertinoButton(padding: EdgeInsets.zero, onPressed: onPressed, child: Icon(icon, color: onPressed == null ? AppColor.muted : AppColor.green)); }
class PrimaryButton extends StatelessWidget { const PrimaryButton({required this.title, required this.onPressed, super.key}); final String title; final VoidCallback onPressed; @override Widget build(BuildContext context) => CupertinoButton(color: AppColor.green, borderRadius: BorderRadius.circular(14), padding: const EdgeInsets.symmetric(vertical: 14), onPressed: onPressed, child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))); }
class SecondaryButton extends StatelessWidget { const SecondaryButton({required this.title, required this.icon, required this.onPressed, super.key}); final String title; final IconData icon; final VoidCallback onPressed; @override Widget build(BuildContext context) => CupertinoButton(color: AppColor.cream, borderRadius: BorderRadius.circular(14), padding: const EdgeInsets.symmetric(vertical: 10), onPressed: onPressed, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 16, color: AppColor.green), const SizedBox(width: 6), Text(title, style: const TextStyle(color: AppColor.text, fontWeight: FontWeight.w800))])); }
class DestructiveButton extends StatelessWidget { const DestructiveButton({required this.title, required this.onPressed, super.key}); final String title; final VoidCallback onPressed; @override Widget build(BuildContext context) => CupertinoButton(color: AppColor.redSoft, borderRadius: BorderRadius.circular(14), padding: const EdgeInsets.symmetric(vertical: 10), onPressed: onPressed, child: Text(title, style: const TextStyle(color: AppColor.red, fontWeight: FontWeight.w800))); }
class SprayRecordCard extends StatelessWidget { const SprayRecordCard({required this.record, this.onRemove, super.key}); final SprayRecord record; final VoidCallback? onRemove; @override Widget build(BuildContext context) { final wait = record.safeDate.isAfter(DateTime.now()); return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: cardDecoration, child: Row(children: [Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: AppColor.greenSoft, borderRadius: BorderRadius.circular(14)), child: const Text('🌿', style: TextStyle(fontSize: 22))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Bed ${record.bedNumbers.join(', ')}', style: const TextStyle(fontWeight: FontWeight.w900)), Text(record.product, style: const TextStyle(color: AppColor.text)), Text('${record.withholdingDays} days · ${shortDate(record.sprayedAt)}', style: const TextStyle(color: AppColor.muted, fontSize: 12))])), Column(children: [StatusPill(status: wait ? 'Wait' : 'Safe'), if (onRemove != null) CupertinoButton(padding: EdgeInsets.zero, minSize: 30, onPressed: onRemove, child: const Icon(CupertinoIcons.trash, color: AppColor.red, size: 20))]) ])); } }
class ProductLibraryCard extends StatelessWidget { const ProductLibraryCard({required this.product, required this.onRemove, super.key}); final SprayProduct product; final VoidCallback onRemove; @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: cardDecoration, child: Row(children: [Container(width: 46, height: 46, alignment: Alignment.center, decoration: BoxDecoration(color: AppColor.greenSoft, borderRadius: BorderRadius.circular(15)), child: Text(product.icon, style: const TextStyle(fontSize: 24))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.name, style: const TextStyle(fontWeight: FontWeight.w900)), Text(product.type, style: const TextStyle(color: AppColor.muted)), Text('Withholding: ${product.withholdingDays} days', style: const TextStyle(color: AppColor.text, fontSize: 12))])), CupertinoButton(padding: EdgeInsets.zero, onPressed: onRemove, child: const Icon(CupertinoIcons.ellipsis_vertical, color: AppColor.muted))])); }

Rect scaleRect(Rect r, Size size) => Rect.fromLTWH(r.left * size.width, r.top * size.height, r.width * size.width, r.height * size.height);
const shadow = [BoxShadow(color: Color(0x18000000), blurRadius: 24, offset: Offset(0, 10))];
const subtleShadow = [BoxShadow(color: Color(0x0D000000), blurRadius: 14, offset: Offset(0, 5))];
final cardDecoration = BoxDecoration(color: AppColor.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColor.line), boxShadow: subtleShadow);
final inputDecoration = BoxDecoration(color: AppColor.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColor.line));
