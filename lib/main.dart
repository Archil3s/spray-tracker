import 'package:flutter/cupertino.dart';

void main() {
  runApp(const SprayTrackerApp());
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
        primaryColor: CupertinoColors.activeGreen,
        scaffoldBackgroundColor: Color(0xFFF2F2F7),
        barBackgroundColor: Color(0xFFF9F9F9),
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
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.square_grid_2x2_fill),
            label: 'Dash',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.plus_circle_fill),
            label: 'Log',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.map_fill),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.time),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.cube_box_fill),
            label: 'Products',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            return switch (index) {
              0 => const DashboardScreen(),
              1 => const LogSprayScreen(),
              2 => const GardenMapScreen(),
              3 => const SprayHistoryScreen(),
              _ => const ProductLibraryScreen(),
            };
          },
        );
      },
    );
  }
}

class SprayRecord {
  const SprayRecord({
    required this.product,
    required this.crop,
    required this.location,
    required this.dateLabel,
    required this.safeDateLabel,
    required this.status,
    required this.reason,
  });

  final String product;
  final String crop;
  final String location;
  final String dateLabel;
  final String safeDateLabel;
  final String status;
  final String reason;
}

class GardenBedZone {
  const GardenBedZone({
    required this.number,
    required this.bounds,
    required this.status,
    required this.cropSummary,
    required this.lastSpray,
  });

  final int number;
  final Rect bounds;
  final String status;
  final String cropSummary;
  final String lastSpray;
}

const demoRecords = [
  SprayRecord(
    product: 'Neem oil',
    crop: 'Tomatoes',
    location: 'Greenhouse',
    dateLabel: 'Today',
    safeDateLabel: 'Safe from 20 May',
    status: 'Wait',
    reason: 'Aphids',
  ),
  SprayRecord(
    product: 'Seaweed tonic',
    crop: 'Silverbeet',
    location: 'Main patch',
    dateLabel: 'Yesterday',
    safeDateLabel: 'Safe now',
    status: 'Safe',
    reason: 'Plant health',
  ),
  SprayRecord(
    product: 'Copper spray',
    crop: 'Potatoes',
    location: 'Back bed',
    dateLabel: '4 days ago',
    safeDateLabel: 'Safe from 23 May',
    status: 'Wait',
    reason: 'Blight prevention',
  ),
];

const gardenBeds = [
  GardenBedZone(number: 1, bounds: Rect.fromLTWH(0.12, 0.05, 0.16, 0.06), status: 'Safe', cropSummary: 'Fruit corner', lastSpray: 'No recent spray'),
  GardenBedZone(number: 2, bounds: Rect.fromLTWH(0.12, 0.12, 0.36, 0.24), status: 'Safe', cropSummary: 'Large left bed', lastSpray: 'No recent spray'),
  GardenBedZone(number: 3, bounds: Rect.fromLTWH(0.50, 0.05, 0.09, 0.06), status: 'Safe', cropSummary: 'Top small bed', lastSpray: 'No recent spray'),
  GardenBedZone(number: 4, bounds: Rect.fromLTWH(0.60, 0.05, 0.32, 0.08), status: 'Wait', cropSummary: 'Strawberries', lastSpray: 'Neem oil · safe 20 May'),
  GardenBedZone(number: 5, bounds: Rect.fromLTWH(0.60, 0.15, 0.32, 0.08), status: 'Wait', cropSummary: 'Raspberries / strawberries', lastSpray: 'Neem oil · safe 20 May'),
  GardenBedZone(number: 6, bounds: Rect.fromLTWH(0.60, 0.25, 0.32, 0.08), status: 'Safe', cropSummary: 'Empty bed', lastSpray: 'No recent spray'),
  GardenBedZone(number: 7, bounds: Rect.fromLTWH(0.60, 0.35, 0.32, 0.08), status: 'Safe', cropSummary: 'Empty bed', lastSpray: 'No recent spray'),
  GardenBedZone(number: 8, bounds: Rect.fromLTWH(0.60, 0.47, 0.32, 0.06), status: 'Wait', cropSummary: 'Raspberries / fruit tree', lastSpray: 'Copper spray · safe 23 May'),
  GardenBedZone(number: 9, bounds: Rect.fromLTWH(0.60, 0.55, 0.32, 0.08), status: 'Safe', cropSummary: 'Empty bed', lastSpray: 'No recent spray'),
  GardenBedZone(number: 10, bounds: Rect.fromLTWH(0.60, 0.65, 0.32, 0.08), status: 'Safe', cropSummary: 'Empty bed', lastSpray: 'No recent spray'),
  GardenBedZone(number: 11, bounds: Rect.fromLTWH(0.60, 0.76, 0.32, 0.08), status: 'Safe', cropSummary: 'Lower-right bed', lastSpray: 'No recent spray'),
  GardenBedZone(number: 12, bounds: Rect.fromLTWH(0.11, 0.45, 0.34, 0.08), status: 'Safe', cropSummary: 'Left middle bed', lastSpray: 'No recent spray'),
  GardenBedZone(number: 13, bounds: Rect.fromLTWH(0.11, 0.56, 0.34, 0.08), status: 'Safe', cropSummary: 'Asparagus', lastSpray: 'Seaweed tonic · safe now'),
  GardenBedZone(number: 14, bounds: Rect.fromLTWH(0.11, 0.67, 0.34, 0.08), status: 'Safe', cropSummary: 'Left lower bed', lastSpray: 'No recent spray'),
  GardenBedZone(number: 15, bounds: Rect.fromLTWH(0.01, 0.79, 0.45, 0.08), status: 'Safe', cropSummary: 'Lower-left bed', lastSpray: 'No recent spray'),
  GardenBedZone(number: 16, bounds: Rect.fromLTWH(0.01, 0.91, 0.91, 0.035), status: 'Safe', cropSummary: 'Long bottom bed', lastSpray: 'No recent spray'),
  GardenBedZone(number: 17, bounds: Rect.fromLTWH(0.06, 0.00, 0.86, 0.035), status: 'Wait', cropSummary: 'First year fruiting canes', lastSpray: 'Berry spray · safe 22 May'),
];

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Spray Tracker',
      subtitle: 'Garden safety at a glance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafetySummaryCard(),
          SizedBox(height: 16),
          QuickActionCard(),
          SizedBox(height: 20),
          SectionHeader(title: 'Recent sprays'),
          SizedBox(height: 8),
          RecentSprayList(),
          SizedBox(height: 20),
          SectionHeader(title: 'Next checks'),
          SizedBox(height: 8),
          InfoCard(
            title: 'Inspect tomatoes tomorrow',
            body: 'Check aphids before repeating neem oil.',
            icon: CupertinoIcons.eye_fill,
          ),
        ],
      ),
    );
  }
}

class SafetySummaryCard extends StatelessWidget {
  const SafetySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: MetricCard(
            label: 'Safe now',
            value: '13',
            detail: 'beds',
            icon: CupertinoIcons.check_mark_circled_solid,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: MetricCard(
            label: 'Do not harvest',
            value: '4',
            detail: 'beds',
            icon: CupertinoIcons.exclamationmark_triangle_fill,
          ),
        ),
      ],
    );
  }
}

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {},
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: CupertinoColors.activeGreen,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          children: [
            Icon(CupertinoIcons.plus_circle_fill, color: CupertinoColors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Log a spray now',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(CupertinoIcons.chevron_forward, color: CupertinoColors.white),
          ],
        ),
      ),
    );
  }
}

class RecentSprayList extends StatelessWidget {
  const RecentSprayList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: demoRecords
          .map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SprayRecordCard(record: record),
            ),
          )
          .toList(),
    );
  }
}

class LogSprayScreen extends StatelessWidget {
  const LogSprayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Log Spray',
      subtitle: 'Fast entry first. Beds can be selected from the map.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormPreviewTile(label: 'Product', value: 'Neem oil'),
          FormPreviewTile(label: 'Crop', value: 'Tomatoes'),
          FormPreviewTile(label: 'Beds', value: '4, 5'),
          FormPreviewTile(label: 'Reason', value: 'Aphids'),
          FormPreviewTile(label: 'Withholding', value: '3 days'),
          FormPreviewTile(label: 'Safe harvest date', value: '20 May 2026'),
          SizedBox(height: 20),
          SaveSprayButton(),
        ],
      ),
    );
  }
}

class GardenMapScreen extends StatefulWidget {
  const GardenMapScreen({super.key});

  @override
  State<GardenMapScreen> createState() => _GardenMapScreenState();
}

class _GardenMapScreenState extends State<GardenMapScreen> {
  GardenBedZone selectedBed = gardenBeds.first;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Garden Map',
      subtitle: 'Tap a bed to inspect spray status',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 470,
            padding: const EdgeInsets.all(12),
            decoration: cardDecoration,
            child: InteractiveGardenMap(
              selectedBed: selectedBed,
              onBedSelected: (bed) => setState(() => selectedBed = bed),
            ),
          ),
          const SizedBox(height: 16),
          BedDetailCard(bed: selectedBed),
          const SizedBox(height: 12),
          const InfoCard(
            title: '17 beds mapped',
            body: 'This first pass uses tappable coordinate zones based on the GrowVeg screenshots.',
            icon: CupertinoIcons.map_fill,
          ),
        ],
      ),
    );
  }
}

class InteractiveGardenMap extends StatelessWidget {
  const InteractiveGardenMap({
    required this.selectedBed,
    required this.onBedSelected,
    super.key,
  });

  final GardenBedZone selectedBed;
  final ValueChanged<GardenBedZone> onBedSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final point = details.localPosition;
            for (final bed in gardenBeds.reversed) {
              final rect = _scaleRect(bed.bounds, size);
              if (rect.contains(point)) {
                onBedSelected(bed);
                return;
              }
            }
          },
          child: CustomPaint(
            painter: GardenMapPainter(selectedBed: selectedBed),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class GardenMapPainter extends CustomPainter {
  const GardenMapPainter({required this.selectedBed});

  final GardenBedZone selectedBed;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE5E5EA)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    _drawPath(canvas, size, Rect.fromLTWH(0.27, 0.08, 0.035, 0.30));
    _drawPath(canvas, size, Rect.fromLTWH(0.53, 0.08, 0.035, 0.64));

    for (final bed in gardenBeds) {
      final rect = _scaleRect(bed.bounds, size);
      final isSelected = bed.number == selectedBed.number;
      final isWaiting = bed.status == 'Wait';
      final fill = isWaiting ? const Color(0xFFFFF1D6) : const Color(0xFFFFFFFF);
      final border = isSelected
          ? CupertinoColors.activeBlue
          : isWaiting
              ? CupertinoColors.systemOrange
              : const Color(0xFF7A3B12);
      final bedPaint = Paint()..color = fill;
      final borderPaint = Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 4 : 2;
      final radius = Radius.circular(isSelected ? 12 : 7);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), bedPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), borderPaint);
      _drawBedNumber(canvas, rect.center, bed.number, isSelected: isSelected);
    }
  }

  void _drawPath(Canvas canvas, Size size, Rect normalizedRect) {
    final rect = _scaleRect(normalizedRect, size);
    final paint = Paint()..color = const Color(0xFF9A9AA0);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), paint);
  }

  void _drawBedNumber(Canvas canvas, Offset center, int number, {required bool isSelected}) {
    final circlePaint = Paint()..color = CupertinoColors.white;
    final outlinePaint = Paint()
      ..color = isSelected ? CupertinoColors.activeBlue : CupertinoColors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3 : 2;
    canvas.drawCircle(center, 15, circlePaint);
    canvas.drawCircle(center, 15, outlinePaint);
    final textPainter = TextPainter(
      text: TextSpan(
        text: number.toString(),
        style: TextStyle(
          color: CupertinoColors.black,
          fontWeight: FontWeight.w800,
          fontSize: number >= 10 ? 14 : 16,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant GardenMapPainter oldDelegate) {
    return oldDelegate.selectedBed.number != selectedBed.number;
  }
}

Rect _scaleRect(Rect normalizedRect, Size size) {
  return Rect.fromLTWH(
    normalizedRect.left * size.width,
    normalizedRect.top * size.height,
    normalizedRect.width * size.width,
    normalizedRect.height * size.height,
  );
}

class BedDetailCard extends StatelessWidget {
  const BedDetailCard({required this.bed, super.key});

  final GardenBedZone bed;

  @override
  Widget build(BuildContext context) {
    final isWaiting = bed.status == 'Wait';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bed ${bed.number}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isWaiting ? const Color(0xFFFFF1D6) : const Color(0xFFE5F7E8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  bed.status,
                  style: TextStyle(
                    color: isWaiting ? CupertinoColors.systemOrange : CupertinoColors.activeGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(bed.cropSummary, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(bed.lastSpray, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
          const SizedBox(height: 14),
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

class SprayHistoryScreen extends StatelessWidget {
  const SprayHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'History',
      subtitle: 'Recent spray records',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchBarMock(),
          SizedBox(height: 14),
          RecentSprayList(),
        ],
      ),
    );
  }
}

class ProductLibraryScreen extends StatelessWidget {
  const ProductLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Products',
      subtitle: 'Sprays and withholding defaults',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProductCard(name: 'Neem oil', type: 'Pest control', withholding: '3 days'),
          ProductCard(name: 'Copper spray', type: 'Fungicide', withholding: '7 days'),
          ProductCard(name: 'Seaweed tonic', type: 'Plant health', withholding: '0 days'),
          SizedBox(height: 12),
          InfoCard(
            title: 'Manual beds later',
            body: 'The MVP accepts bed selection now. Full bed editing will become its own feature.',
            icon: CupertinoIcons.square_grid_3x2_fill,
          ),
        ],
      ),
    );
  }
}

class AppPage extends StatelessWidget {
  const AppPage({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    super.key,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: CupertinoColors.activeGreen),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
          Text(detail, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
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
    final isSafe = record.status == 'Safe';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F7E8),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(CupertinoIcons.drop_fill, color: CupertinoColors.activeGreen),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.product, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                const SizedBox(height: 3),
                Text('${record.crop} · ${record.location}', style: const TextStyle(color: CupertinoColors.secondaryLabel)),
                const SizedBox(height: 3),
                Text(record.safeDateLabel, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSafe ? const Color(0xFFE5F7E8) : const Color(0xFFFFF1D6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              record.status,
              style: TextStyle(
                color: isSafe ? CupertinoColors.activeGreen : CupertinoColors.systemOrange,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FormPreviewTile extends StatelessWidget {
  const FormPreviewTile({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration,
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          const Icon(CupertinoIcons.chevron_forward, size: 16, color: CupertinoColors.tertiaryLabel),
        ],
      ),
    );
  }
}

class SaveSprayButton extends StatelessWidget {
  const SaveSprayButton({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton.filled(
      borderRadius: BorderRadius.circular(16),
      onPressed: () {},
      child: const Text('Save spray record'),
    );
  }
}

class SearchBarMock extends StatelessWidget {
  const SearchBarMock({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(CupertinoIcons.search, color: CupertinoColors.secondaryLabel),
          SizedBox(width: 8),
          Text('Search crops, sprays, reasons', style: TextStyle(color: CupertinoColors.secondaryLabel)),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({required this.name, required this.type, required this.withholding, super.key});

  final String name;
  final String type;
  final String withholding;

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
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                Text(type, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
              ],
            ),
          ),
          Text(withholding, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({required this.title, required this.body, required this.icon, super.key});

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration,
      child: Row(
        children: [
          Icon(icon, color: CupertinoColors.activeGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(body, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

final cardDecoration = BoxDecoration(
  color: CupertinoColors.white,
  borderRadius: BorderRadius.circular(22),
  boxShadow: const [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ],
);
