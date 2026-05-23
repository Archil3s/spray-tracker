part of '../../main.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({required this.tab, required this.onTap, super.key});
  final int tab;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = const [
      NavSpec('Home', CupertinoIcons.home),
      NavSpec('Garden', CupertinoIcons.square_grid_2x2),
      NavSpec('Spray', CupertinoIcons.drop),
      NavSpec('Records', CupertinoIcons.list_bullet),
      NavSpec('Products', CupertinoIcons.cube_box),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(31),
        border: Border.all(color: C.line),
        boxShadow: softShadow,
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final selected = index == tab;
          return Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: () => onTap(index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 38,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? C.forest : CupertinoColors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(
                      items[index].icon,
                      size: 18,
                      color: selected ? CupertinoColors.white : C.muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    child: Text(
                      items[index].label,
                      style: TextStyle(
                        color: selected ? C.forest : C.muted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class NavSpec {
  const NavSpec(this.label, this.icon);
  final String label;
  final IconData icon;
}

class RecordCard extends StatelessWidget {
  const RecordCard({required this.record, this.onDelete, super.key});
  final SprayRecord record;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final target = targetById(record.targetId);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: target.softColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(target.icon, color: target.color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bed ${record.beds.join(', ')} | ${target.short}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: C.ink,
                  ),
                ),
                Text(
                  record.crops.join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: C.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${record.product} | sprayed ${shortDate(record.date)} | safe ${shortDate(record.safeDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: C.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          StatusPill(record.onHold ? 'HOLD' : 'SAFE', hold: record.onHold),
          if (onDelete != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
              onPressed: onDelete,
              child: const Icon(CupertinoIcons.delete, color: C.red, size: 20),
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
    required this.children,
    this.message = '',
    super.key,
  });
  final String title;
  final String subtitle;
  final List<Widget> children;
  final String message;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.1,
              color: C.forest,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: C.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          if (message.isNotEmpty) ...[
            MessageBanner(message),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      );
}

class MessageBanner extends StatelessWidget {
  const MessageBanner(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.forestSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line),
        ),
        child: Text(
          message,
          style: const TextStyle(color: C.forest, fontWeight: FontWeight.w900),
        ),
      );
}

class Panel extends StatelessWidget {
  const Panel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) =>
      Container(padding: padding, decoration: cardDecoration(), child: child);
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {this.trailing, super.key});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: C.forest,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      );
}

class EmptyCard extends StatelessWidget {
  const EmptyCard(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Panel(
        child: Text(
          text,
          style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700),
        ),
      );
}

class EmptyInline extends StatelessWidget {
  const EmptyInline(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.soft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line),
        ),
        child: Text(
          text,
          style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700),
        ),
      );
}

class Sheet extends StatelessWidget {
  const Sheet({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => CupertinoPopupSurface(
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .86,
            child: Container(color: C.canvas, child: child),
          ),
        ),
      );
}

class SheetHeader extends StatelessWidget {
  const SheetHeader({required this.title, required this.subtitle, super.key});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: C.ink,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: C.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child: const Icon(CupertinoIcons.clear, color: C.muted, size: 24),
          ),
        ],
      );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => CupertinoButton(
        color: C.forest,
        disabledColor: C.line,
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            color: CupertinoColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => CupertinoButton(
        color: C.forestSoft,
        disabledColor: C.soft,
        borderRadius: BorderRadius.circular(16),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            color: onPressed == null ? C.muted : C.forest,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

class NumberChip extends StatelessWidget {
  const NumberChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? C.forest : C.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? C.forest : C.line),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? CupertinoColors.white : C.ink,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {required this.hold, super.key});
  final String label;
  final bool hold;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hold ? C.amberSoft : C.forestSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: hold ? C.amber : C.forest,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .5,
          ),
        ),
      );
}

class ProductTag extends StatelessWidget {
  const ProductTag({
    required this.label,
    required this.color,
    required this.background,
    super.key,
  });
  final String label;
  final Color color;
  final Color background;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 10.5,
          ),
        ),
      );
}

class CategoryPill extends StatelessWidget {
  const CategoryPill({required this.category, super.key});
  final String category;
  @override
  Widget build(BuildContext context) {
    final lower = category.toLowerCase();
    final color = lower == 'organic'
        ? C.forest
        : lower == 'chemical'
            ? C.amber
            : C.muted;
    final background = lower == 'organic'
        ? C.forestSoft
        : lower == 'chemical'
            ? C.amberSoft
            : C.greySoft;
    return ProductTag(
      label: category.isEmpty ? 'unknown' : category,
      color: color,
      background: background,
    );
  }
}

class Field extends StatelessWidget {
  const Field({
    required this.controller,
    required this.placeholder,
    this.maxLines = 1,
    super.key,
  });
  final TextEditingController controller;
  final String placeholder;
  final int maxLines;
  @override
  Widget build(BuildContext context) => CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        maxLines: maxLines,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.line),
        ),
      );
}

class Stepper extends StatelessWidget {
  const Stepper({
    required this.label,
    required this.value,
    required this.minus,
    required this.plus,
    super.key,
  });
  final String label;
  final int value;
  final VoidCallback? minus;
  final VoidCallback? plus;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.soft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            SmallButton('-', minus),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                '$value',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
            SmallButton('+', plus),
          ],
        ),
      );
}

class SmallButton extends StatelessWidget {
  const SmallButton(this.label, this.onPressed, {super.key});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(34, 34),
        color: C.card,
        borderRadius: BorderRadius.circular(999),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            color: C.forest,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

class TextChip extends StatelessWidget {
  const TextChip({required this.label, super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: C.line),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: C.ink,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      );
}

class CropChip extends StatelessWidget {
  const CropChip({required this.crop, required this.onRemove, super.key});
  final VegetableDefinition crop;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: C.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CropIcon(crop.iconPath, size: 22),
            const SizedBox(width: 7),
            Text(
              crop.name,
              style: const TextStyle(
                color: C.ink,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: onRemove,
              child: const Icon(CupertinoIcons.clear, color: C.muted, size: 16),
            ),
          ],
        ),
      );
}

class CountDot extends StatelessWidget {
  const CountDot(this.count, {super.key});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 20),
        height: 20,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: C.forest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: C.card, width: 2),
        ),
        child: Text(
          '+$count',
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

class DetailLine extends StatelessWidget {
  const DetailLine(this.label, this.value, {super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: C.forest,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: C.ink,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
        ),
      );
}

class TargetGrid extends StatelessWidget {
  const TargetGrid({required this.selected, required this.onSelect, super.key});
  final String selected;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: .98,
        children: sprayTargets
            .map(
              (target) => TargetButton(
                target: target,
                selected: selected == target.id,
                onTap: () => onSelect(target.id),
              ),
            )
            .toList(),
      );
}

class TargetButton extends StatelessWidget {
  const TargetButton({
    required this.target,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final SprayTarget target;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? target.softColor : C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? target.color : C.line,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(target.icon, color: target.color, size: 22),
              const SizedBox(height: 5),
              FittedBox(
                child: Text(
                  target.short,
                  style: const TextStyle(
                    color: C.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class CropIcon extends StatelessWidget {
  const CropIcon(this.path, {this.size = 28, super.key});
  final String path;
  final double size;
  @override
  Widget build(BuildContext context) => path.toLowerCase().endsWith('.svg')
      ? SvgPicture.asset(path, width: size, height: size, fit: BoxFit.contain)
      : Image.asset(
          path,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        );
}

class GridPainter extends CustomPainter {
  const GridPainter(this.plot);

  final GardenPlot plot;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE9E4D8)
      ..strokeWidth = .55;
    for (var meter = 0; meter <= plot.widthMeters.floor(); meter++) {
      final x = meter * size.width / plot.widthMeters;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var meter = 0; meter <= plot.lengthMeters.floor(); meter++) {
      final y = meter * size.height / plot.lengthMeters;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) =>
      plot.widthMeters != oldDelegate.plot.widthMeters ||
      plot.lengthMeters != oldDelegate.plot.lengthMeters;
}
