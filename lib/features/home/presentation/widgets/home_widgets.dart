part of '../../../../main.dart';

class HeroMetric extends StatelessWidget {
  const HeroMetric({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x12FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x28FFFFFF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      );
}
