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
      home: GardenMapScreen(),
    );
  }
}

class BedZone {
  const BedZone(this.number, this.bounds, this.status, this.label);

  final int number;
  final Rect bounds;
  final String status;
  final String label;
}

const beds = [
  BedZone(1, Rect.fromLTWH(.06, .08, .20, .12), 'Safe', 'Upper-left section'),
  BedZone(2, Rect.fromLTWH(.36, .08, .15, .31), 'Safe', 'Right-hand section'),
  BedZone(3, Rect.fromLTWH(.55, .08, .10, .085), 'Safe', 'Top small bed'),
  BedZone(4, Rect.fromLTWH(.70, .08, .25, .07), 'Wait', 'Strawberries'),
  BedZone(5, Rect.fromLTWH(.70, .18, .25, .07), 'Wait', 'Raspberries'),
  BedZone(6, Rect.fromLTWH(.70, .28, .25, .07), 'Safe', 'Bed 6'),
  BedZone(7, Rect.fromLTWH(.70, .38, .25, .07), 'Safe', 'Bed 7'),
  BedZone(8, Rect.fromLTWH(.70, .48, .25, .07), 'Wait', 'Berry bed'),
  BedZone(9, Rect.fromLTWH(.70, .58, .25, .07), 'Safe', 'Bed 9'),
  BedZone(10, Rect.fromLTWH(.70, .68, .25, .07), 'Safe', 'Bed 10'),
  BedZone(11, Rect.fromLTWH(.70, .78, .25, .08), 'Safe', 'Bed 11'),
  BedZone(12, Rect.fromLTWH(.04, .42, .46, .07), 'Safe', 'Bed 12'),
  BedZone(13, Rect.fromLTWH(.04, .53, .46, .07), 'Safe', 'Asparagus'),
  BedZone(14, Rect.fromLTWH(.04, .64, .46, .07), 'Safe', 'Bed 14'),
  BedZone(15, Rect.fromLTWH(.04, .75, .46, .07), 'Safe', 'Bed 15'),
  BedZone(16, Rect.fromLTWH(.04, .92, .91, .045), 'Safe', 'Long bottom bed'),
  BedZone(17, Rect.fromLTWH(.04, .01, .91, .04), 'Wait', 'Top cane bed'),
];

const compoundOuter = Rect.fromLTWH(.04, .07, .47, .33);
const compoundPath = Rect.fromLTWH(.275, .08, .045, .31);
const compoundLowerLeft = Rect.fromLTWH(.06, .24, .20, .15);
const mainPath = Rect.fromLTWH(.55, .17, .045, .72);

BedZone bedByNumber(int number) => beds.firstWhere((bed) => bed.number == number);

class GardenMapScreen extends StatefulWidget {
  const GardenMapScreen({super.key});

  @override
  State<GardenMapScreen> createState() => _GardenMapScreenState();
}

class _GardenMapScreenState extends State<GardenMapScreen> {
  BedZone selected = bedByNumber(4);

  void selectBed(BedZone bed) => setState(() => selected = bed);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            const Text('Garden Map', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Tap a bed to mark spraying', style: TextStyle(fontSize: 16, color: CupertinoColors.secondaryLabel)),
            const SizedBox(height: 18),
            Container(
              height: 600,
              padding: const EdgeInsets.all(12),
              decoration: _cardDecoration,
              child: InteractiveGardenMap(selected: selected, onSelect: selectBed),
            ),
            const SizedBox(height: 14),
            BedDetailCard(bed: selected),
          ],
        ),
      ),
    );
  }
}

class InteractiveGardenMap extends StatelessWidget {
  const InteractiveGardenMap({required this.selected, required this.onSelect, super.key});

  final BedZone selected;
  final ValueChanged<BedZone> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            for (final bed in beds.reversed) {
              if (_scale(bed.bounds, size).inflate(6).contains(details.localPosition)) {
                onSelect(bed);
                return;
              }
            }
          },
          child: CustomPaint(painter: GardenMapPainter(selected), size: Size.infinite),
        );
      },
    );
  }
}

class GardenMapPainter extends CustomPainter {
  const GardenMapPainter(this.selected);

  final BedZone selected;

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawOutline(canvas, size, compoundOuter);
    _drawOutline(canvas, size, compoundLowerLeft);
    _drawPath(canvas, size, compoundPath);
    _drawPath(canvas, size, mainPath);

    for (final bed in beds) {
      _drawBed(canvas, size, bed);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFEDE8DE)..strokeWidth = .45;
    for (double x = 0; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawBed(Canvas canvas, Size size, BedZone bed) {
    final rect = _scale(bed.bounds, size);
    final selectedBed = bed.number == selected.number;
    final waiting = bed.status == 'Wait';
    final fill = selectedBed ? const Color(0xFFEAF3FF) : waiting ? const Color(0xFFFFF1D6) : const Color(0xFFFEFAF2);
    final border = selectedBed ? CupertinoColors.activeBlue : waiting ? CupertinoColors.systemOrange : const Color(0xFF7A3B12);
    _drawRoundedRect(canvas, rect, fill, border, selectedBed ? 4 : 2);
    _drawNumber(canvas, rect.center, bed.number, selectedBed);
  }

  void _drawOutline(Canvas canvas, Size size, Rect rect) {
    _drawRoundedRect(canvas, _scale(rect, size), const Color(0x00FFFFFF), const Color(0xFF7A3B12), 2);
  }

  void _drawPath(Canvas canvas, Size size, Rect rect) {
    final scaled = _scale(rect, size);
    canvas.drawRRect(RRect.fromRectAndRadius(scaled, const Radius.circular(3)), Paint()..color = const Color(0xFFC7C7C7));
    final tilePaint = Paint()..color = CupertinoColors.white..strokeWidth = .7;
    for (double y = scaled.top + 20; y < scaled.bottom; y += 24) {
      canvas.drawLine(Offset(scaled.left, y), Offset(scaled.right, y), tilePaint);
    }
  }

  void _drawRoundedRect(Canvas canvas, Rect rect, Color fill, Color border, double width) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(7));
    canvas.drawRRect(rrect, Paint()..color = fill);
    canvas.drawRRect(rrect, Paint()..color = border..style = PaintingStyle.stroke..strokeWidth = width);
  }

  void _drawNumber(Canvas canvas, Offset center, int number, bool selectedBed) {
    canvas.drawCircle(center, selectedBed ? 17 : 15, Paint()..color = selectedBed ? CupertinoColors.activeBlue : const Color(0xFF9A6A3A));
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
  bool shouldRepaint(GardenMapPainter oldDelegate) => oldDelegate.selected.number != selected.number;
}

class BedDetailCard extends StatelessWidget {
  const BedDetailCard({required this.bed, super.key});

  final BedZone bed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Bed ${bed.number}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
              StatusPill(status: bed.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(bed.label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          CupertinoButton.filled(
            padding: const EdgeInsets.symmetric(vertical: 12),
            borderRadius: BorderRadius.circular(14),
            onPressed: () {},
            child: Text('Log spray for Bed ${bed.number}'),
          ),
        ],
      ),
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

Rect _scale(Rect r, Size size) => Rect.fromLTWH(r.left * size.width, r.top * size.height, r.width * size.width, r.height * size.height);

final _cardDecoration = BoxDecoration(
  color: CupertinoColors.white,
  borderRadius: BorderRadius.circular(22),
  boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 8))],
);
