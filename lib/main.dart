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
      home: MainShell(),
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.square_grid_2x2_fill), label: 'Dash'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.plus_circle_fill), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.map_fill), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.time), label: 'History'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.cube_box_fill), label: 'Products'),
        ],
      ),
      tabBuilder: (context, index) => CupertinoTabView(
        builder: (_) => switch (index) {
          0 => const DashboardScreen(),
          1 => const LogSprayScreen(),
          2 => const GardenMapScreen(),
          3 => const HistoryScreen(),
          _ => const ProductsScreen(),
        },
      ),
    );
  }
}

class BedZone {
  const BedZone(this.number, this.bounds, this.status, this.crop, this.lastSpray);

  final int number;
  final Rect bounds;
  final String status;
  final String crop;
  final String lastSpray;
}

const beds = [
  // Bed 1 is intentionally nested inside Bed 2, matching the GrowVeg reference.
  BedZone(1, Rect.fromLTWH(.10, .08, .09, .08), 'Safe', 'Fruit corner inset', 'No recent spray'),
  // Bed 2 is the large left compound plot. It has an internal split line on the right side.
  BedZone(2, Rect.fromLTWH(.08, .06, .40, .30), 'Safe', 'Large compound bed', 'No recent spray'),
  BedZone(3, Rect.fromLTWH(.53, .07, .11, .09), 'Safe', 'Top small bed', 'No recent spray'),
  BedZone(4, Rect.fromLTWH(.69, .05, .27, .08), 'Wait', 'Strawberries', 'Neem oil · safe 20 May'),
  BedZone(5, Rect.fromLTWH(.69, .16, .27, .08), 'Wait', 'Raspberries / strawberries', 'Neem oil · safe 20 May'),
  BedZone(6, Rect.fromLTWH(.69, .27, .27, .08), 'Safe', 'Empty bed', 'No recent spray'),
  BedZone(7, Rect.fromLTWH(.69, .38, .27, .08), 'Safe', 'Empty bed', 'No recent spray'),
  BedZone(8, Rect.fromLTWH(.69, .49, .27, .07), 'Wait', 'Raspberries / fruit tree', 'Copper spray · safe 23 May'),
  BedZone(9, Rect.fromLTWH(.69, .59, .27, .08), 'Safe', 'Empty bed', 'No recent spray'),
  BedZone(10, Rect.fromLTWH(.69, .70, .27, .08), 'Safe', 'Empty bed', 'No recent spray'),
  BedZone(11, Rect.fromLTWH(.69, .81, .27, .08), 'Safe', 'Lower-right bed', 'No recent spray'),
  BedZone(12, Rect.fromLTWH(.08, .40, .40, .07), 'Safe', 'Left middle bed', 'No recent spray'),
  BedZone(13, Rect.fromLTWH(.08, .52, .40, .07), 'Safe', 'Asparagus', 'Seaweed tonic · safe now'),
  BedZone(14, Rect.fromLTWH(.08, .64, .40, .07), 'Safe', 'Left lower bed', 'No recent spray'),
  BedZone(15, Rect.fromLTWH(.08, .76, .40, .07), 'Safe', 'Lower-left bed', 'No recent spray'),
  BedZone(16, Rect.fromLTWH(.08, .92, .88, .035), 'Safe', 'Long bottom bed', 'No recent spray'),
  BedZone(17, Rect.fromLTWH(.08, .00, .88, .035), 'Wait', 'First year fruiting canes', 'Berry spray · safe 22 May'),
];

BedZone bedByNumber(int number) => beds.firstWhere((bed) => bed.number == number);

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const AppPage(
        title: 'Spray Tracker',
        subtitle: 'Garden safety at a glance',
        children: [
          Row(children: [
            Expanded(child: MetricCard(label: 'Safe now', value: '13', detail: 'beds')),
            SizedBox(width: 12),
            Expanded(child: MetricCard(label: 'Do not harvest', value: '4', detail: 'beds')),
          ]),
          SizedBox(height: 16),
          PrimaryAction(title: 'Log a spray now'),
          SizedBox(height: 20),
          SectionHeader('Recent sprays'),
          SprayCard(product: 'Neem oil', crop: 'Tomatoes', area: 'Beds 4, 5', status: 'Wait', safe: 'Safe from 20 May'),
          SprayCard(product: 'Seaweed tonic', crop: 'Asparagus', area: 'Bed 13', status: 'Safe', safe: 'Safe now'),
          SprayCard(product: 'Copper spray', crop: 'Raspberries', area: 'Bed 8', status: 'Wait', safe: 'Safe from 23 May'),
        ],
      );
}

class LogSprayScreen extends StatelessWidget {
  const LogSprayScreen({super.key});

  @override
  Widget build(BuildContext context) => const AppPage(
        title: 'Log Spray',
        subtitle: 'Fast entry first. Beds can be selected from the map.',
        children: [
          FormRow(label: 'Product', value: 'Neem oil'),
          FormRow(label: 'Crop', value: 'Tomatoes'),
          FormRow(label: 'Beds', value: '4, 5'),
          FormRow(label: 'Reason', value: 'Aphids'),
          FormRow(label: 'Withholding', value: '3 days'),
          FormRow(label: 'Safe harvest', value: '20 May 2026'),
          SizedBox(height: 18),
          PrimaryAction(title: 'Save spray record'),
        ],
      );
}

class GardenMapScreen extends StatefulWidget {
  const GardenMapScreen({super.key});

  @override
  State<GardenMapScreen> createState() => _GardenMapScreenState();
}

class _GardenMapScreenState extends State<GardenMapScreen> {
  BedZone selected = bedByNumber(4);

  void select(BedZone bed) => setState(() => selected = bed);
  void previous() => select(bedByNumber(selected.number == 1 ? beds.length : selected.number - 1));
  void next() => select(bedByNumber(selected.number == beds.length ? 1 : selected.number + 1));

  @override
  Widget build(BuildContext context) => AppPage(
        title: 'Garden Map',
        subtitle: 'Tap a bed, or use the bed picker below',
        children: [
          const InfoCard(
            title: 'How to use the map',
            body: 'Tap a bed to inspect it. Orange means wait before harvest. Blue means selected.',
            icon: CupertinoIcons.hand_tap_fill,
          ),
          const SizedBox(height: 12),
          const LegendCard(),
          const SizedBox(height: 12),
          Container(
            height: 500,
            padding: const EdgeInsets.all(12),
            decoration: cardDecoration,
            child: GardenMap(selected: selected, onSelect: select),
          ),
          const SizedBox(height: 12),
          BedPicker(selected: selected, onSelect: select),
          const SizedBox(height: 12),
          BedControls(selected: selected, onPrevious: previous, onNext: next),
          const SizedBox(height: 16),
          BedDetailCard(bed: selected),
        ],
      );
}

class GardenMap extends StatelessWidget {
  const GardenMap({required this.selected, required this.onSelect, super.key});

  final BedZone selected;
  final ValueChanged<BedZone> onSelect;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              // Bed 1 lives inside Bed 2, so it must be hit-tested first.
              final hitOrder = [bedByNumber(1), ...beds.reversed.where((bed) => bed.number != 1)];
              for (final bed in hitOrder) {
                if (_scale(bed.bounds, size).inflate(5).contains(details.localPosition)) {
                  onSelect(bed);
                  return;
                }
              }
            },
            child: CustomPaint(
              painter: GardenMapPainter(selected),
              size: Size.infinite,
            ),
          );
        },
      );
}

class GardenMapPainter extends CustomPainter {
  const GardenMapPainter(this.selected);

  final BedZone selected;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = const Color(0xFFE5E5EA)..strokeWidth = .5;
    for (double x = 0; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    _path(canvas, size, const Rect.fromLTWH(.50, .10, .045, .74));
    _path(canvas, size, const Rect.fromLTWH(.48, .16, .19, .035));
    _path(canvas, size, const Rect.fromLTWH(.48, .80, .19, .035));

    final drawOrder = [...beds.where((bed) => bed.number != 1), bedByNumber(1)];
    for (final bed in drawOrder) {
      _drawBed(canvas, size, bed);
    }
  }

  void _drawBed(Canvas canvas, Size size, BedZone bed) {
    final rect = _scale(bed.bounds, size);
    final isSelected = bed.number == selected.number;
    final isWait = bed.status == 'Wait';
    final fill = isSelected ? const Color(0xFFEAF3FF) : isWait ? const Color(0xFFFFF1D6) : CupertinoColors.white;
    final stroke = isSelected ? CupertinoColors.activeBlue : isWait ? CupertinoColors.systemOrange : const Color(0xFF7A3B12);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(isSelected ? 12 : 7));
    canvas.drawRRect(rrect, Paint()..color = fill);

    if (isSelected) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(4), const Radius.circular(14)),
        Paint()..color = const Color(0x553A8BFF)..style = PaintingStyle.stroke..strokeWidth = 8,
      );
    }

    canvas.drawRRect(rrect, Paint()..color = stroke..style = PaintingStyle.stroke..strokeWidth = isSelected ? 4 : 2);

    if (bed.number == 2) {
      // GrowVeg reference: Bed 2 is a large compound bed with a right-side split.
      final splitX = rect.left + rect.width * .70;
      final splitPaint = Paint()..color = const Color(0x557A3B12)..strokeWidth = 1.4;
      canvas.drawLine(Offset(splitX, rect.top + 4), Offset(splitX, rect.bottom - 4), splitPaint);
    }

    _number(canvas, rect.center, bed.number, isSelected);
  }

  void _path(Canvas canvas, Size size, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(_scale(rect, size), const Radius.circular(4)),
      Paint()..color = const Color(0xFF9A9AA0),
    );
  }

  void _number(Canvas canvas, Offset center, int number, bool selected) {
    final radius = selected ? 17.0 : 15.0;
    canvas.drawCircle(center, radius, Paint()..color = selected ? CupertinoColors.activeBlue : CupertinoColors.white);
    canvas.drawCircle(center, radius, Paint()..color = selected ? CupertinoColors.activeBlue : CupertinoColors.black..style = PaintingStyle.stroke..strokeWidth = 2);
    final tp = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(color: selected ? CupertinoColors.white : CupertinoColors.black, fontSize: number > 9 ? 14 : 16, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(GardenMapPainter oldDelegate) => oldDelegate.selected.number != selected.number;
}

Rect _scale(Rect r, Size size) => Rect.fromLTWH(r.left * size.width, r.top * size.height, r.width * size.width, r.height * size.height);

class BedPicker extends StatelessWidget {
  const BedPicker({required this.selected, required this.onSelect, super.key});

  final BedZone selected;
  final ValueChanged<BedZone> onSelect;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: beds.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final bed = beds[index];
            final isSelected = bed.number == selected.number;
            final isWait = bed.status == 'Wait';
            return CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => onSelect(bed),
              child: Container(
                width: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? CupertinoColors.activeBlue : isWait ? const Color(0xFFFFF1D6) : CupertinoColors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: isSelected ? CupertinoColors.activeBlue : isWait ? CupertinoColors.systemOrange : const Color(0xFFD1D1D6), width: 2),
                ),
                child: Text('${bed.number}', style: TextStyle(color: isSelected ? CupertinoColors.white : CupertinoColors.black, fontWeight: FontWeight.w800)),
              ),
            );
          },
        ),
      );
}

class BedControls extends StatelessWidget {
  const BedControls({required this.selected, required this.onPrevious, required this.onNext, super.key});

  final BedZone selected;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: cardDecoration,
        child: Row(children: [
          Expanded(child: SecondaryButton(title: 'Previous', onPressed: onPrevious)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('Bed ${selected.number}', style: const TextStyle(fontWeight: FontWeight.w800))),
          Expanded(child: SecondaryButton(title: 'Next', onPressed: onNext)),
        ]),
      );
}

class BedDetailCard extends StatelessWidget {
  const BedDetailCard({required this.bed, super.key});

  final BedZone bed;

  @override
  Widget build(BuildContext context) {
    final isWait = bed.status == 'Wait';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: CupertinoColors.activeBlue, width: 2), boxShadow: cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: CupertinoColors.activeBlue, borderRadius: BorderRadius.circular(15)), child: Text('${bed.number}', style: const TextStyle(color: CupertinoColors.white, fontSize: 19, fontWeight: FontWeight.w800))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Bed ${bed.number}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), Text(bed.crop, style: const TextStyle(color: CupertinoColors.secondaryLabel))])),
          StatusPill(status: bed.status),
        ]),
        const SizedBox(height: 14),
        Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(16)), child: Text(bed.lastSpray, style: const TextStyle(fontWeight: FontWeight.w700))),
        const SizedBox(height: 14),
        if (isWait) const Text('Do not harvest from this bed until the safe date.', style: TextStyle(color: CupertinoColors.systemOrange, fontWeight: FontWeight.w700)),
        if (isWait) const SizedBox(height: 14),
        Row(children: const [Expanded(child: PrimaryAction(title: 'Log spray')), SizedBox(width: 10), Expanded(child: SecondaryButton(title: 'View history'))]),
      ]),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => const AppPage(title: 'History', subtitle: 'Recent spray records', children: [SearchMock(), SizedBox(height: 14), SprayCard(product: 'Neem oil', crop: 'Tomatoes', area: 'Beds 4, 5', status: 'Wait', safe: 'Safe from 20 May'), SprayCard(product: 'Copper spray', crop: 'Raspberries', area: 'Bed 8', status: 'Wait', safe: 'Safe from 23 May')]);
}

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) => const AppPage(title: 'Products', subtitle: 'Sprays and withholding defaults', children: [ProductCard('Neem oil', 'Pest control', '3 days'), ProductCard('Copper spray', 'Fungicide', '7 days'), ProductCard('Seaweed tonic', 'Plant health', '0 days')]);
}

class AppPage extends StatelessWidget {
  const AppPage({required this.title, required this.subtitle, required this.children, super.key});
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 18, 20, 32), children: [Text(title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 16, color: CupertinoColors.secondaryLabel)), const SizedBox(height: 24), ...children]),
        ),
      );
}

class MetricCard extends StatelessWidget {
  const MetricCard({required this.label, required this.value, required this.detail, super.key});
  final String label;
  final String value;
  final String detail;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: cardDecoration, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(CupertinoIcons.check_mark_circled_solid, color: CupertinoColors.activeGreen), const SizedBox(height: 16), Text(value, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)), Text(detail, style: const TextStyle(color: CupertinoColors.secondaryLabel)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w600))]));
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction({required this.title, super.key});
  final String title;
  @override
  Widget build(BuildContext context) => CupertinoButton.filled(borderRadius: BorderRadius.circular(16), padding: const EdgeInsets.symmetric(vertical: 13), onPressed: () {}, child: Text(title));
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({required this.title, this.onPressed, super.key});
  final String title;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => CupertinoButton(color: const Color(0xFFE5E5EA), borderRadius: BorderRadius.circular(14), padding: const EdgeInsets.symmetric(vertical: 11), onPressed: onPressed ?? () {}, child: Text(title, style: const TextStyle(color: CupertinoColors.black, fontWeight: FontWeight.w700)));
}

class InfoCard extends StatelessWidget {
  const InfoCard({required this.title, required this.body, required this.icon, super.key});
  final String title;
  final String body;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: cardDecoration, child: Row(children: [Icon(icon, color: CupertinoColors.activeGreen), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(body, style: const TextStyle(color: CupertinoColors.secondaryLabel))]))]));
}

class LegendCard extends StatelessWidget {
  const LegendCard({super.key});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(14), decoration: cardDecoration, child: const Row(children: [LegendPill('Selected', CupertinoColors.activeBlue), SizedBox(width: 8), LegendPill('Wait', CupertinoColors.systemOrange), SizedBox(width: 8), LegendPill('Safe', CupertinoColors.activeGreen)]));
}

class LegendPill extends StatelessWidget {
  const LegendPill(this.label, this.color, {super.key});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(999)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 5), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))])));
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.status, super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final wait = status == 'Wait';
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: wait ? const Color(0xFFFFF1D6) : const Color(0xFFE5F7E8), borderRadius: BorderRadius.circular(999)), child: Text(status, style: TextStyle(color: wait ? CupertinoColors.systemOrange : CupertinoColors.activeGreen, fontWeight: FontWeight.w800, fontSize: 12)));
  }
}

class SprayCard extends StatelessWidget {
  const SprayCard({required this.product, required this.crop, required this.area, required this.status, required this.safe, super.key});
  final String product;
  final String crop;
  final String area;
  final String status;
  final String safe;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(16), decoration: cardDecoration, child: Row(children: [const Icon(CupertinoIcons.drop_fill, color: CupertinoColors.activeGreen), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)), Text('$crop · $area', style: const TextStyle(color: CupertinoColors.secondaryLabel)), Text(safe, style: const TextStyle(fontSize: 13))])), StatusPill(status: status)]));
}

class FormRow extends StatelessWidget {
  const FormRow({required this.label, required this.value, super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: cardDecoration, child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: CupertinoColors.secondaryLabel))), Text(value, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(width: 8), const Icon(CupertinoIcons.chevron_forward, size: 16, color: CupertinoColors.tertiaryLabel)]));
}

class ProductCard extends StatelessWidget {
  const ProductCard(this.name, this.type, this.withholding, {super.key});
  final String name;
  final String type;
  final String withholding;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: cardDecoration, child: Row(children: [const Icon(CupertinoIcons.cube_box_fill, color: CupertinoColors.activeGreen), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)), Text(type, style: const TextStyle(color: CupertinoColors.secondaryLabel))])), Text(withholding, style: const TextStyle(fontWeight: FontWeight.w700))]));
}

class SearchMock extends StatelessWidget {
  const SearchMock({super.key});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: CupertinoColors.systemGrey5, borderRadius: BorderRadius.circular(14)), child: const Row(children: [Icon(CupertinoIcons.search, color: CupertinoColors.secondaryLabel), SizedBox(width: 8), Text('Search crops, sprays, reasons', style: TextStyle(color: CupertinoColors.secondaryLabel))]));
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 4), child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)));
}

const cardShadow = [BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 8))];
final cardDecoration = BoxDecoration(color: CupertinoColors.white, borderRadius: BorderRadius.circular(22), boxShadow: cardShadow);
