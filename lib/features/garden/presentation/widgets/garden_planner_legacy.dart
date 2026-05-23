part of '../../../../main.dart';

class _BedPlantingCanvas extends StatelessWidget {
  const _BedPlantingCanvas({
    required this.bed,
    required this.crops,
    this.plants = const [],
    this.gridPositions = const [],
    this.previewPositions = const [],
    this.previewCrop,
    this.previewSpacing,
    this.spacingForPlant,
    this.height = 186,
    this.erasing = false,
    this.onPlace,
    this.onPlantTap,
    this.onPaintStart,
    this.onPaintUpdate,
    this.onPaintEnd,
    this.onPaintCancel,
  });

  final GardenBed bed;
  final List<VegetableDefinition> crops;
  final List<GardenPlant> plants;
  final List<Offset> gridPositions;
  final List<Offset> previewPositions;
  final VegetableDefinition? previewCrop;
  final CropSpacing? previewSpacing;
  final CropSpacing Function(GardenPlant plant)? spacingForPlant;
  final double height;
  final bool erasing;
  final ValueChanged<Offset>? onPlace;
  final ValueChanged<GardenPlant>? onPlantTap;
  final ValueChanged<Offset>? onPaintStart;
  final ValueChanged<Offset>? onPaintUpdate;
  final VoidCallback? onPaintEnd;
  final VoidCallback? onPaintCancel;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('bed-planting-canvas'),
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: C.line),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 34, 12, 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = fittedBedCanvasSize(
                      Size(constraints.maxWidth, constraints.maxHeight),
                      bed,
                    );
                    return Center(
                      child: SizedBox(
                        width: size.width,
                        height: size.height,
                        child: _buildBedSurface(size),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: ProductTag(
                label: bed.sizeLabel,
                color: C.forest,
                background: C.forestSoft,
              ),
            ),
          ],
        ),
      );

  Widget _buildBedSurface(Size size) => Container(
        key: const ValueKey('bed-planting-surface'),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: C.soft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.soil, width: 1.2),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _BedPlantingPainter(bed)),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: onPlace == null
                    ? null
                    : (details) => onPlace!(
                          Offset(
                            details.localPosition.dx / size.width,
                            details.localPosition.dy / size.height,
                          ),
                        ),
                onPanStart: onPaintStart == null
                    ? null
                    : (details) => _handlePaintPosition(
                          details.localPosition,
                          size,
                          onPaintStart!,
                        ),
                onPanUpdate: onPaintUpdate == null
                    ? null
                    : (details) => _handlePaintPosition(
                          details.localPosition,
                          size,
                          onPaintUpdate!,
                        ),
                onPanEnd: onPaintEnd == null ? null : (_) => onPaintEnd!(),
                onPanCancel: onPaintCancel,
                child: Stack(
                  children: [
                    if (gridPositions.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _PlantSpacingGridPainter(gridPositions),
                          ),
                        ),
                      ),
                    if (plants.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _PlantingBandPainter(
                              bed: bed,
                              plants: plants,
                              spacingForPlant: spacingForPlant,
                              drawLabels: false,
                            ),
                          ),
                        ),
                      ),
                    if (plants.isEmpty && crops.isEmpty)
                      const Center(
                        child: Icon(
                          CupertinoIcons.leaf_arrow_circlepath,
                          color: C.forest,
                          size: 42,
                        ),
                      ),
                    if (_displayPlants().isNotEmpty)
                      ..._displayPlants().map((plant) {
                        final spacing = spacingForPlant == null
                            ? cropSpacingFor(plant.crop)
                            : spacingForPlant!(plant);
                        final extent =
                            visualPlantIconExtent(size, bed, spacing);
                        final tapExtent =
                            erasing && extent < 44 ? 44.0 : extent;
                        return Positioned(
                          left: plant.position.dx * size.width - tapExtent / 2,
                          top: plant.position.dy * size.height - tapExtent / 2,
                          child: IgnorePointer(
                            ignoring: !erasing,
                            child: _PlacedPlantIcon(
                              plant: plant,
                              extent: extent,
                              tapExtent: tapExtent,
                              erasing: erasing,
                              onTap: onPlantTap == null
                                  ? null
                                  : () => onPlantTap!(plant),
                            ),
                          ),
                        );
                      })
                    else if (crops.isNotEmpty)
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          runAlignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: crops
                              .map(
                                (crop) => _PlantPatch(crop: crop),
                              )
                              .toList(),
                        ),
                      ),
                    if (plants.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _PlantingBandPainter(
                              bed: bed,
                              plants: plants,
                              spacingForPlant: spacingForPlant,
                              drawBands: false,
                            ),
                          ),
                        ),
                      ),
                    if (previewPositions.isNotEmpty &&
                        previewCrop != null &&
                        previewSpacing != null)
                      ...previewPositions.map((position) {
                        final extent =
                            visualPlantIconExtent(size, bed, previewSpacing!);
                        return Positioned(
                          left: position.dx * size.width - extent / 2,
                          top: position.dy * size.height - extent / 2,
                          child: IgnorePointer(
                            child: Opacity(
                              opacity: .42,
                              child: SizedBox(
                                width: extent,
                                height: extent,
                                child: CropIcon(
                                  previewCrop!.iconPath,
                                  size: extent,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  void _handlePaintPosition(
    Offset localPosition,
    Size size,
    ValueChanged<Offset> onInside,
  ) {
    final outside = localPosition.dx < 0 ||
        localPosition.dy < 0 ||
        localPosition.dx > size.width ||
        localPosition.dy > size.height;
    if (outside) {
      onPaintCancel?.call();
      return;
    }
    onInside(
      Offset(
        localPosition.dx / size.width,
        localPosition.dy / size.height,
      ),
    );
  }

  List<GardenPlant> _displayPlants() {
    if (erasing) return plants;
    final grouped = <String, List<GardenPlant>>{};
    for (final plant in plants) {
      grouped.putIfAbsent(plant.crop.id, () => []).add(plant);
    }
    final visible = <GardenPlant>[];
    for (final group in grouped.values) {
      if (group.isEmpty) continue;
      final spacing = spacingForPlant == null
          ? cropSpacingFor(group.first.crop)
          : spacingForPlant!(group.first);
      if (group.length > 12 && spacing.plantCm <= 25) {
        continue;
      }
      final maxVisible = spacing.plantCm <= 12
          ? 10
          : spacing.plantCm <= 20
              ? 12
              : spacing.plantCm <= 35
                  ? 16
                  : 24;
      if (group.length <= maxVisible) {
        visible.addAll(group);
        continue;
      }
      final ordered = [...group]..sort((a, b) {
          final row = a.position.dy.compareTo(b.position.dy);
          return row == 0 ? a.position.dx.compareTo(b.position.dx) : row;
        });
      final step = (ordered.length / maxVisible).ceil();
      for (var index = 0; index < ordered.length; index += step) {
        visible.add(ordered[index]);
      }
    }
    return visible;
  }
}

class _PlacedPlantIcon extends StatelessWidget {
  const _PlacedPlantIcon({
    required this.plant,
    required this.extent,
    required this.tapExtent,
    required this.erasing,
    this.onTap,
  });

  final GardenPlant plant;
  final double extent;
  final double tapExtent;
  final bool erasing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        label: plant.crop.name,
        button: onTap != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            key: ValueKey('placed-plant-${plant.id}'),
            width: tapExtent,
            height: tapExtent,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: extent,
                  height: extent,
                  child: CropIcon(plant.crop.iconPath, size: extent),
                ),
                if (erasing)
                  Positioned(
                    top: (tapExtent - extent) / 2 - 5,
                    right: (tapExtent - extent) / 2 - 5,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: C.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: C.card, width: 1.5),
                      ),
                      child: const Icon(
                        CupertinoIcons.clear,
                        color: CupertinoColors.white,
                        size: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

class _PlantSpacingGridPainter extends CustomPainter {
  const _PlantSpacingGridPainter(this.positions);

  final List<Offset> positions;

  @override
  void paint(Canvas canvas, Size size) {
    final axes = Paint()
      ..color = C.forest.withValues(alpha: .06)
      ..strokeWidth = .65;
    final dotFill = Paint()..color = C.forest.withValues(alpha: .09);
    final columns = positions.map((position) => position.dx).toSet();
    final rows = positions.map((position) => position.dy).toSet();
    for (final column in columns) {
      final x = column * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), axes);
    }
    for (final row in rows) {
      final y = row * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), axes);
    }
    if (positions.length <= 90) {
      for (final position in positions) {
        canvas.drawCircle(
          Offset(position.dx * size.width, position.dy * size.height),
          2,
          dotFill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PlantSpacingGridPainter oldDelegate) =>
      oldDelegate.positions != positions;
}

class _PlantingBandPainter extends CustomPainter {
  const _PlantingBandPainter({
    required this.bed,
    required this.plants,
    required this.spacingForPlant,
    this.drawBands = true,
    this.drawLabels = true,
  });

  final GardenBed bed;
  final List<GardenPlant> plants;
  final CropSpacing Function(GardenPlant plant)? spacingForPlant;
  final bool drawBands;
  final bool drawLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final plantsByCrop = <String, List<GardenPlant>>{};
    for (final plant in plants) {
      plantsByCrop.putIfAbsent(plant.crop.id, () => []).add(plant);
    }

    for (final cropPlants in plantsByCrop.values) {
      if (cropPlants.isEmpty) continue;
      final crop = cropPlants.first.crop;
      final spacing = spacingForPlant == null
          ? cropSpacingFor(crop)
          : spacingForPlant!(cropPlants.first);
      final band = _cropBandRect(cropPlants, spacing);
      final rect = Rect.fromLTRB(
        band.left * size.width,
        band.top * size.height,
        band.right * size.width,
        band.bottom * size.height,
      );
      if (rect.width < 10 || rect.height < 8) continue;

      final familyColor = _cropBandColor(crop);
      final fill = Paint()..color = familyColor.withValues(alpha: .18);
      final stroke = Paint()
        ..color = familyColor.withValues(alpha: .28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      final radius = Radius.circular(rect.height < 26 ? 8 : 13);
      final rounded = RRect.fromRectAndRadius(rect, radius);
      if (drawBands) {
        canvas.drawRRect(rounded, fill);
        canvas.drawRRect(rounded, stroke);
        _drawCropTexture(canvas, rect.deflate(3), crop, familyColor);
      }

      if (!drawLabels || rect.width < 56 || rect.height < 14) continue;
      final label = _shortCropLabel(crop.name);
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: C.ink.withValues(alpha: .78),
            fontSize: rect.height < 24 ? 9 : 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '',
      )..layout(maxWidth: rect.width - 10);
      final pill = Rect.fromCenter(
        center: rect.center,
        width: textPainter.width + 12,
        height: textPainter.height + 6,
      );
      if (pill.width < rect.width - 2 && pill.height < rect.height + 4) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(pill, const Radius.circular(999)),
          Paint()..color = C.card.withValues(alpha: .74),
        );
        textPainter.paint(
          canvas,
          Offset(
            pill.center.dx - textPainter.width / 2,
            pill.center.dy - textPainter.height / 2,
          ),
        );
      }
    }
  }

  Rect _cropBandRect(List<GardenPlant> cropPlants, CropSpacing spacing) {
    final plantHalfWidth =
        (spacing.plantCm / 100 / bed.widthMeters / 2).clamp(.018, .08);
    final rowHalfHeight =
        (spacing.rowCm / 100 / bed.lengthMeters / 2).clamp(.018, .08);
    var left = 1.0;
    var top = 1.0;
    var right = 0.0;
    var bottom = 0.0;
    for (final plant in cropPlants) {
      left = plant.position.dx - plantHalfWidth < left
          ? plant.position.dx - plantHalfWidth
          : left;
      top = plant.position.dy - rowHalfHeight < top
          ? plant.position.dy - rowHalfHeight
          : top;
      right = plant.position.dx + plantHalfWidth > right
          ? plant.position.dx + plantHalfWidth
          : right;
      bottom = plant.position.dy + rowHalfHeight > bottom
          ? plant.position.dy + rowHalfHeight
          : bottom;
    }
    return Rect.fromLTRB(
      left.clamp(.015, .985),
      top.clamp(.015, .985),
      right.clamp(.015, .985),
      bottom.clamp(.015, .985),
    );
  }

  Color _cropBandColor(VegetableDefinition crop) => switch (crop.familyId) {
        'root_vegetables' => const Color(0xFFE08D3C),
        'alliums' => const Color(0xFF8E8BC8),
        'brassicas' => const Color(0xFF4E9F55),
        'leafy_greens' => const Color(0xFF65A83F),
        'legumes' => const Color(0xFF2B8E73),
        'apiaceae' => const Color(0xFF9AAB4F),
        'berries' => const Color(0xFFC44D62),
        'solanaceae' => const Color(0xFFD65A3A),
        'cucurbits' => const Color(0xFFE3A93B),
        _ => C.forest,
      };

  void _drawCropTexture(
    Canvas canvas,
    Rect rect,
    VegetableDefinition crop,
    Color familyColor,
  ) {
    if (rect.width < 18 || rect.height < 10) return;
    final seed = crop.id.hashCode.abs();
    final columns = (rect.width / 38).floor().clamp(2, 12);
    final rows = (rect.height / 28).floor().clamp(1, 4);
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final jitter = ((seed + row * 7 + column * 11) % 9 - 4) * .7;
        final center = Offset(
          rect.left + (column + .5) * rect.width / columns + jitter,
          rect.top + (row + .5) * rect.height / rows,
        );
        _drawCropMark(canvas, center, crop, familyColor);
      }
    }
  }

  void _drawCropMark(
    Canvas canvas,
    Offset center,
    VegetableDefinition crop,
    Color familyColor,
  ) {
    final leaf = Paint()..color = familyColor.withValues(alpha: .58);
    final dark = Paint()
      ..color = C.forest.withValues(alpha: .45)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    final root = Paint()
      ..color = _cropRootColor(crop).withValues(alpha: .72)
      ..style = PaintingStyle.fill;

    if (crop.familyId == 'root_vegetables') {
      canvas.drawOval(
        Rect.fromCenter(
            center: center + const Offset(0, 3), width: 7, height: 12),
        root,
      );
      canvas.drawLine(center + const Offset(0, -4), center, dark);
      canvas.drawOval(
        Rect.fromCenter(
            center: center + const Offset(-3, -4), width: 8, height: 4),
        leaf,
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: center + const Offset(3, -4), width: 8, height: 4),
        leaf,
      );
      return;
    }

    if (crop.familyId == 'alliums' || crop.id == 'leek') {
      for (final offset in const [-4.0, 0.0, 4.0]) {
        canvas.drawLine(
          center + Offset(offset, 6),
          center + Offset(offset * .35, -7),
          dark,
        );
      }
      canvas.drawOval(
        Rect.fromCenter(
            center: center + const Offset(0, 6), width: 8, height: 5),
        root,
      );
      return;
    }

    if (crop.familyId == 'brassicas' || crop.familyId == 'leafy_greens') {
      for (var index = 0; index < 6; index++) {
        final angle = index * 1.047;
        final offset = Offset(
          6 * math.cos(angle),
          4 * math.sin(angle),
        );
        canvas.drawOval(
          Rect.fromCenter(center: center + offset, width: 10, height: 7),
          leaf,
        );
      }
      canvas.drawCircle(
          center, 3, Paint()..color = familyColor.withValues(alpha: .75));
      return;
    }

    canvas.drawCircle(
        center, 5, Paint()..color = familyColor.withValues(alpha: .62));
    canvas.drawLine(
        center + const Offset(-6, 4), center + const Offset(6, -4), dark);
  }

  Color _cropRootColor(VegetableDefinition crop) => switch (crop.id) {
        'carrot' => const Color(0xFFE8872F),
        'beetroot' => const Color(0xFF9E3152),
        'radish' => const Color(0xFFD94A68),
        'onion' => const Color(0xFFD08A32),
        'garlic' => const Color(0xFFE8D7A7),
        'leek' || 'spring_onion' => const Color(0xFF7AA95D),
        _ => const Color(0xFFC87A38),
      };

  String _shortCropLabel(String name) {
    final slash = name.split('/').first.trim();
    return slash.isEmpty ? name : slash;
  }

  @override
  bool shouldRepaint(covariant _PlantingBandPainter oldDelegate) =>
      oldDelegate.plants != plants || oldDelegate.bed != bed;
}

class _PlantPatch extends StatelessWidget {
  const _PlantPatch({required this.crop});

  final VegetableDefinition crop;

  @override
  Widget build(BuildContext context) => Container(
        width: 86,
        height: 80,
        padding: const EdgeInsets.fromLTRB(7, 8, 7, 6),
        decoration: BoxDecoration(
          color: C.card.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line),
          boxShadow: softShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CropIcon(crop.iconPath, size: 39),
            const SizedBox(height: 4),
            Text(
              crop.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: C.ink,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _BedPlantingPainter extends CustomPainter {
  const _BedPlantingPainter(this.bed);

  final GardenBed bed;

  @override
  void paint(Canvas canvas, Size size) {
    final soil = Paint()
      ..color = const Color(0xFFB8946A).withValues(alpha: .10)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += 25) {
      canvas.drawLine(
        Offset(x.toDouble(), 0),
        Offset(x + size.height, size.height),
        soil,
      );
    }
    final minor = Paint()
      ..color = C.soil.withValues(alpha: .07)
      ..strokeWidth = .55;
    final major = Paint()
      ..color = C.soil.withValues(alpha: .16)
      ..strokeWidth = .9;
    _drawMeterGrid(canvas, size, bed.widthMeters, true, minor, major);
    _drawMeterGrid(canvas, size, bed.lengthMeters, false, minor, major);
  }

  void _drawMeterGrid(
    Canvas canvas,
    Size size,
    double meters,
    bool vertical,
    Paint minor,
    Paint major,
  ) {
    if (meters <= 0) return;
    const step = .25;
    final steps = (meters / step).floor();
    for (var index = 1; index < steps; index++) {
      final meter = index * step;
      final fraction = meter / meters;
      final paint = index % 4 == 0 ? major : minor;
      if (vertical) {
        final x = fraction * size.width;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      } else {
        final y = fraction * size.height;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BedPlantingPainter oldDelegate) =>
      bed.widthMeters != oldDelegate.bed.widthMeters ||
      bed.lengthMeters != oldDelegate.bed.lengthMeters;
}

class GardenMap extends StatefulWidget {
  const GardenMap({
    required this.selectedBed,
    required this.plot,
    required this.gardenBeds,
    required this.bedCrops,
    required this.isHold,
    required this.designing,
    required this.onTap,
    required this.onMove,
    this.records = const [],
    this.selectedBeds = const {},
    super.key,
  });
  final int selectedBed;
  final GardenPlot plot;
  final List<GardenBed> gardenBeds;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final List<SprayRecord> records;
  final Set<int> selectedBeds;
  final bool Function(int bed) isHold;
  final bool designing;
  final ValueChanged<int> onTap;
  final void Function(int bed, Offset delta) onMove;

  @override
  State<GardenMap> createState() => _GardenMapState();
}

class _GardenMapState extends State<GardenMap> {
  int? draggingBed;
  Offset dragDelta = Offset.zero;

  void _startDrag(GardenBed bed) {
    widget.onTap(bed.number);
    setState(() {
      draggingBed = bed.number;
      dragDelta = Offset.zero;
    });
  }

  void _updateDrag(DragUpdateDetails details, Size size) {
    setState(() {
      dragDelta += Offset(
        details.delta.dx / size.width,
        details.delta.dy / size.height,
      );
    });
  }

  void _finishDrag(GardenBed bed) {
    final delta = dragDelta;
    if (delta != Offset.zero) {
      widget.onMove(bed.number, delta);
    }
    setState(() {
      draggingBed = null;
      dragDelta = Offset.zero;
    });
  }

  void _cancelDrag() {
    setState(() {
      draggingBed = null;
      dragDelta = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: GridPainter(widget.plot)),
              ),
              ...widget.gardenBeds.map((bed) {
                final visibleBed =
                    draggingBed == bed.number ? bed.move(dragDelta) : bed;
                final rect = Rect.fromLTWH(
                  visibleBed.rect.left * size.width,
                  visibleBed.rect.top * size.height,
                  visibleBed.rect.width * size.width,
                  visibleBed.rect.height * size.height,
                );
                return Positioned.fromRect(
                  rect: rect,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart:
                        widget.designing ? (_) => _startDrag(bed) : null,
                    onPanUpdate: widget.designing
                        ? (details) => _updateDrag(details, size)
                        : null,
                    onPanEnd: widget.designing ? (_) => _finishDrag(bed) : null,
                    onPanCancel: widget.designing ? _cancelDrag : null,
                    child: BedButton(
                      bed: visibleBed,
                      selected: widget.selectedBed == bed.number ||
                          widget.selectedBeds.contains(bed.number),
                      hold: widget.isHold(bed.number),
                      crops: widget.bedCrops[bed.number] ??
                          const <VegetableDefinition>[],
                      activity: _bedMapActivity(widget.records, bed.number),
                      designing: widget.designing,
                      onTap: () => widget.onTap(bed.number),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      );
}

class BedButton extends StatelessWidget {
  const BedButton({
    required this.bed,
    required this.selected,
    required this.hold,
    required this.crops,
    required this.activity,
    required this.designing,
    required this.onTap,
    super.key,
  });
  final GardenBed bed;
  final bool selected;
  final bool hold;
  final bool designing;
  final List<VegetableDefinition> crops;
  final BedMapActivity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = hold
        ? const Color(0xFFFFF4DF)
        : crops.isEmpty
            ? const Color(0xFFF4E8D6)
            : const Color(0xFFE7F1DC);
    final border = selected
        ? C.forest
        : hold
            ? C.amber
            : C.soil.withValues(alpha: .42);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: border, width: selected ? 2.5 : 1.15),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: C.forest.withValues(alpha: .18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _BedSurfacePainter(
                    planted: crops.isNotEmpty,
                    hold: hold,
                  ),
                ),
              ),
              Positioned.fill(
                child: designing
                    ? _DesignBedMapContent(
                        bed: bed,
                        selected: selected,
                        crops: crops,
                        activity: activity,
                      )
                    : _OperationalBedMapContent(
                        bed: bed,
                        selected: selected,
                        crops: crops,
                        activity: activity,
                      ),
              ),
              if (selected)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: C.forest,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: C.card, width: 1.7),
                      boxShadow: [
                        BoxShadow(
                          color: C.forest.withValues(alpha: .20),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.check_mark,
                      color: CupertinoColors.white,
                      size: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesignBedMapContent extends StatelessWidget {
  const _DesignBedMapContent({
    required this.bed,
    required this.selected,
    required this.crops,
    required this.activity,
  });

  final GardenBed bed;
  final bool selected;
  final List<VegetableDefinition> crops;
  final BedMapActivity activity;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 46 || constraints.maxHeight < 38;
          return Stack(
            children: [
              Positioned(
                top: 5,
                left: 5,
                right: selected ? 27 : 5,
                child: Align(
                  alignment: compact || crops.isEmpty
                      ? Alignment.center
                      : Alignment.topLeft,
                  child: _BedMapTitle(
                    title: compact ? '${bed.number}' : bed.label,
                    selected: selected,
                  ),
                ),
              ),
              if (crops.isNotEmpty && !compact)
                Positioned.fill(
                  top: 27,
                  left: 5,
                  right: 5,
                  bottom: activity.hasActivity ? 30 : 5,
                  child: _BedCropGardenPreview(crops: crops),
                ),
              if (activity.hasActivity && constraints.maxHeight >= 42)
                Positioned(
                  left: 4,
                  bottom: 4,
                  right: 4,
                  child: _BedActivityIconStrip(activity: activity),
                ),
            ],
          );
        },
      );
}

class _OperationalBedMapContent extends StatelessWidget {
  const _OperationalBedMapContent({
    required this.bed,
    required this.selected,
    required this.crops,
    required this.activity,
  });

  final GardenBed bed;
  final bool selected;
  final List<VegetableDefinition> crops;
  final BedMapActivity activity;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 46 || constraints.maxHeight < 42;
          return Stack(
            children: [
              Positioned(
                top: 5,
                left: 5,
                right: selected ? 25 : 5,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: _BedMapTitle(
                    title: compact ? '${bed.number}' : bed.label,
                    selected: selected,
                  ),
                ),
              ),
              if (crops.isNotEmpty)
                Positioned.fill(
                  top: compact ? 20 : 28,
                  bottom: activity.hasActivity ? 28 : 5,
                  left: 5,
                  right: 5,
                  child: _BedCropGardenPreview(crops: crops),
                ),
              if (activity.hasActivity)
                Positioned(
                  left: 5,
                  right: 5,
                  bottom: 5,
                  child: _BedActivityIconStrip(activity: activity),
                ),
            ],
          );
        },
      );
}

class _BedSurfacePainter extends CustomPainter {
  const _BedSurfacePainter({required this.planted, required this.hold});

  final bool planted;
  final bool hold;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..color = hold
          ? const Color(0xFFFFEAC2)
          : planted
              ? const Color(0xFFD9E8C9)
              : const Color(0xFFE8D4B8);
    canvas.drawRect(Offset.zero & size, base);

    final rowPaint = Paint()
      ..color = (planted ? C.forest : C.soil).withValues(alpha: .10)
      ..strokeWidth = 1;
    final rowCount = (size.height / 13).clamp(2, 8).round();
    for (var index = 1; index < rowCount; index++) {
      final y = size.height * index / rowCount;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rowPaint);
    }

    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = C.soil.withValues(alpha: .18);
    canvas.drawRect(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      edge,
    );
  }

  @override
  bool shouldRepaint(covariant _BedSurfacePainter oldDelegate) =>
      planted != oldDelegate.planted || hold != oldDelegate.hold;
}

class _BedMapTitle extends StatelessWidget {
  const _BedMapTitle({required this.title, required this.selected});

  final String title;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 120),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: C.card.withValues(alpha: selected ? .92 : .76),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: C.ink,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            height: 1.05,
          ),
        ),
      );
}

class _BedCropGardenPreview extends StatelessWidget {
  const _BedCropGardenPreview({required this.crops});

  final List<VegetableDefinition> crops;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width =
              constraints.maxWidth.isFinite ? constraints.maxWidth : 100.0;
          final height =
              constraints.maxHeight.isFinite ? constraints.maxHeight : 70.0;
          final iconSize = math.min(
              46.0, math.max(30.0, math.min(width / 2.8, height / 1.7)));
          final visible = crops.take(width < 86 ? 3 : 5).toList();
          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 7,
                runSpacing: 6,
                children: [
                  ...visible.map(
                    (crop) => _GardenCropIconBadge(
                      crop: crop,
                      size: iconSize,
                    ),
                  ),
                  if (crops.length > visible.length)
                    _GardenMoreCropBadge(
                      count: crops.length - visible.length,
                      size: iconSize,
                    ),
                ],
              ),
            ),
          );
        },
      );
}

class _GardenCropIconBadge extends StatelessWidget {
  const _GardenCropIconBadge({required this.crop, required this.size});

  final VegetableDefinition crop;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(math.max(3, size * .09)),
        decoration: BoxDecoration(
          color: C.card.withValues(alpha: .90),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: C.forest.withValues(alpha: .12)),
          boxShadow: [
            BoxShadow(
              color: C.forest.withValues(alpha: .12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: CropIcon(crop.iconPath, size: size),
      );
}

class _GardenMoreCropBadge extends StatelessWidget {
  const _GardenMoreCropBadge({required this.count, required this.size});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: C.forest.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: C.card, width: 1.5),
        ),
        child: Text(
          '+$count',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: math.max(11, size * .32),
            fontWeight: FontWeight.w900,
          ),
        ),
      );
}

class GardenMapLegend extends StatelessWidget {
  const GardenMapLegend({super.key});

  @override
  Widget build(BuildContext context) => const Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _MapLegendItem(color: C.forest, label: 'Planted'),
          _MapLegendItem(color: C.amber, label: 'Hold'),
          _MapLegendIcon(icon: CupertinoIcons.drop, label: 'Spray'),
          _MapLegendIcon(
            icon: CupertinoIcons.leaf_arrow_circlepath,
            label: 'Feed',
          ),
        ],
      );
}

class _MapLegendItem extends StatelessWidget {
  const _MapLegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: C.card.withValues(alpha: .86),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: C.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: C.muted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _MapLegendIcon extends StatelessWidget {
  const _MapLegendIcon({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: C.card.withValues(alpha: .86),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: C.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: C.forest),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: C.muted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class GardenMapFrame extends StatelessWidget {
  const GardenMapFrame({required this.child, this.height = 380, super.key});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFEFE7D8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: C.line),
          boxShadow: softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(child: child),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: BoxDecoration(
                color: C.card.withValues(alpha: .62),
                border: const Border(top: BorderSide(color: C.line)),
              ),
              child: const GardenMapLegend(),
            ),
          ],
        ),
      );
}

class BedMapActivity {
  const BedMapActivity({
    required this.latestSpray,
    required this.latestFeed,
  });

  final SprayRecord? latestSpray;
  final SprayRecord? latestFeed;

  bool get hasActivity => latestSpray != null || latestFeed != null;
}

BedMapActivity _bedMapActivity(List<SprayRecord> records, int bed) {
  SprayRecord? latestSpray;
  SprayRecord? latestFeed;
  for (final record in records) {
    if (!record.beds.contains(bed)) continue;
    final feed = record.targetId == 'maintain';
    if (feed) {
      if (latestFeed == null ||
          record.date.isAfter(latestFeed.date) ||
          (record.date.isAtSameMomentAs(latestFeed.date) &&
              record.id > latestFeed.id)) {
        latestFeed = record;
      }
    } else if (latestSpray == null ||
        record.date.isAfter(latestSpray.date) ||
        (record.date.isAtSameMomentAs(latestSpray.date) &&
            record.id > latestSpray.id)) {
      latestSpray = record;
    }
  }
  return BedMapActivity(latestSpray: latestSpray, latestFeed: latestFeed);
}

class _BedActivityIconStrip extends StatelessWidget {
  const _BedActivityIconStrip({required this.activity});

  final BedMapActivity activity;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.bottomLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (activity.latestSpray != null)
              _BedActivityBadge(record: activity.latestSpray!),
            if (activity.latestFeed != null) ...[
              const SizedBox(width: 4),
              _BedActivityBadge(record: activity.latestFeed!),
            ],
          ],
        ),
      );
}

class _BedActivityBadge extends StatelessWidget {
  const _BedActivityBadge({required this.record});

  final SprayRecord record;

  @override
  Widget build(BuildContext context) {
    final target = targetById(record.targetId);
    final hold = record.onHold;
    final label = hold ? 'HOLD' : target.short.toUpperCase();
    return Container(
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: hold ? C.amber : target.softColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (hold ? C.amber : target.color).withValues(alpha: .40),
        ),
        boxShadow: [
          BoxShadow(
            color: C.ink.withValues(alpha: .08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hold ? CupertinoIcons.exclamationmark_triangle_fill : target.icon,
            color: hold ? CupertinoColors.white : target.color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: hold ? CupertinoColors.white : target.color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GardenIconButton extends StatelessWidget {
  const _GardenIconButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        button: true,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(36, 36),
          color: C.card,
          disabledColor: C.greySoft,
          borderRadius: BorderRadius.circular(12),
          onPressed: onPressed,
          child: Icon(icon,
              color: onPressed == null ? C.muted : C.forest, size: 18),
        ),
      );
}

void showBedNameEditor(
  BuildContext context,
  GardenBed bed,
  ValueChanged<String> onSave,
) {
  final controller = TextEditingController(text: bed.name);
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => Sheet(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SheetHeader(title: 'Bed name', subtitle: 'Bed ${bed.number}'),
          const SizedBox(height: 12),
          Panel(
            child: Column(
              children: [
                Field(controller: controller, placeholder: bed.label),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Save name',
                  onPressed: () {
                    onSave(controller.text);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ).whenComplete(controller.dispose);
}

void showBedSizeEditor(
  BuildContext context,
  GardenBed bed,
  GardenPlot plot,
  void Function(double widthMeters, double lengthMeters) onSave,
) {
  final width = TextEditingController(text: meterLabel(bed.widthMeters));
  final length = TextEditingController(text: meterLabel(bed.lengthMeters));
  String? error;
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setSheetState) => Sheet(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SheetHeader(title: 'Bed size', subtitle: bed.label),
            const SizedBox(height: 12),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MeterField(
                          label: 'Width',
                          controller: width,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MeterField(
                          label: 'Length',
                          controller: length,
                        ),
                      ),
                    ],
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: C.red,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Save size',
                    onPressed: () {
                      final widthMeters = _readMeterInput(width.text);
                      final lengthMeters = _readMeterInput(length.text);
                      if (widthMeters == null || lengthMeters == null) {
                        setSheetState(
                          () => error = 'Enter width and length in metres.',
                        );
                        return;
                      }
                      if (widthMeters > plot.widthMeters ||
                          lengthMeters > plot.lengthMeters) {
                        setSheetState(
                          () => error = 'Bed must fit inside this plot.',
                        );
                        return;
                      }
                      onSave(widthMeters, lengthMeters);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ).whenComplete(() {
    width.dispose();
    length.dispose();
  });
}

void showGardenPlotEditor(
  BuildContext context,
  GardenPlot plot,
  List<GardenBed> beds,
  void Function(double widthMeters, double lengthMeters) onSave,
) {
  final width = TextEditingController(text: meterLabel(plot.widthMeters));
  final length = TextEditingController(text: meterLabel(plot.lengthMeters));
  String? error;
  showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setSheetState) => Sheet(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SheetHeader(title: 'Plot size', subtitle: 'Garden boundary'),
            const SizedBox(height: 12),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MeterField(
                          label: 'Width',
                          controller: width,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MeterField(
                          label: 'Length',
                          controller: length,
                        ),
                      ),
                    ],
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: C.red,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Save plot',
                    onPressed: () {
                      final widthMeters = _readMeterInput(width.text);
                      final lengthMeters = _readMeterInput(length.text);
                      if (widthMeters == null || lengthMeters == null) {
                        setSheetState(
                          () => error = 'Enter width and length in metres.',
                        );
                        return;
                      }
                      final widestBed = beds.fold(
                        0.0,
                        (widest, bed) =>
                            bed.widthMeters > widest ? bed.widthMeters : widest,
                      );
                      final longestBed = beds.fold(
                        0.0,
                        (longest, bed) => bed.lengthMeters > longest
                            ? bed.lengthMeters
                            : longest,
                      );
                      if (widthMeters < widestBed ||
                          lengthMeters < longestBed) {
                        setSheetState(
                          () => error = 'Plot must fit the largest bed.',
                        );
                        return;
                      }
                      onSave(widthMeters, lengthMeters);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ).whenComplete(() {
    width.dispose();
    length.dispose();
  });
}

double? _readMeterInput(String value) {
  final metres = double.tryParse(value.trim().replaceAll(',', '.'));
  return metres != null && metres > 0 ? metres : null;
}

class _MeterField extends StatelessWidget {
  const _MeterField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label (m)',
            style: const TextStyle(
              color: C.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          CupertinoTextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: C.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: C.line),
            ),
          ),
        ],
      );
}

class IconCluster extends StatelessWidget {
  const IconCluster({required this.crops, super.key});
  final List<VegetableDefinition> crops;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 104),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: C.line),
          boxShadow: softShadow,
        ),
        child: Wrap(
          spacing: 2,
          runSpacing: 2,
          children: [
            ...crops.take(3).map((crop) => CropIcon(crop.iconPath, size: 20)),
            if (crops.length > 3) CountDot(crops.length - 3),
          ],
        ),
      );
}
