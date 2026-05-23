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
    super.key,
  });
  final int selectedBed;
  final GardenPlot plot;
  final List<GardenBed> gardenBeds;
  final Map<int, List<VegetableDefinition>> bedCrops;
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
                      selected: widget.selectedBed == bed.number,
                      hold: widget.isHold(bed.number),
                      crops: widget.bedCrops[bed.number] ??
                          const <VegetableDefinition>[],
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
    required this.designing,
    required this.onTap,
    super.key,
  });
  final GardenBed bed;
  final bool selected;
  final bool hold;
  final bool designing;
  final List<VegetableDefinition> crops;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: hold
                ? C.amberSoft
                : crops.isEmpty
                    ? C.card
                    : C.forestSoft,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? C.forest : C.soil,
              width: selected ? 2.4 : 1.2,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      designing
                          ? '${bed.label}\n${bed.sizeLabel}'
                          : '${bed.number}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: C.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              if (crops.isNotEmpty && !designing)
                Positioned(
                    top: -12, right: -12, child: IconCluster(crops: crops)),
            ],
          ),
        ),
      );
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
