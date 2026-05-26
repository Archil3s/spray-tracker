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
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth =
              constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
          final aspect = bed.widthMeters / bed.lengthMeters;
          var surfaceWidth = maxWidth;
          var surfaceHeight = surfaceWidth / aspect;
          if (surfaceHeight > height) {
            surfaceHeight = height;
            surfaceWidth = surfaceHeight * aspect;
          }
          final size = Size(surfaceWidth, surfaceHeight);
          return Align(
            alignment: Alignment.center,
            child: Container(
              key: const ValueKey('bed-planting-canvas'),
              width: surfaceWidth,
              height: surfaceHeight,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFDCEEB7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF8EC83A), width: 1),
              ),
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: _buildBedSurface(size),
              ),
            ),
          );
        },
      );

  Widget _buildBedSurface(Size size) => Container(
        key: const ValueKey('bed-planting-surface'),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFDCEEB7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: C.soil, width: 2),
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
                    if (plants.isEmpty && crops.isEmpty)
                      const Center(
                        child: Icon(
                          CupertinoIcons.leaf_arrow_circlepath,
                          color: C.forest,
                          size: 42,
                        ),
                      ),
                    if (plants.isNotEmpty)
                      ...plants.map((plant) {
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
                          child: _PlacedPlantIcon(
                            plant: plant,
                            extent: extent,
                            tapExtent: tapExtent,
                            erasing: erasing,
                            onTap: erasing
                                ? onPlantTap == null
                                    ? null
                                    : () => onPlantTap!(plant)
                                : onPlace == null
                                    ? null
                                    : () => onPlace!(plant.position),
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
    this.bedPlants = const {},
    this.records = const [],
    this.selectedBeds = const {},
    this.onPlanBed,
    super.key,
  });
  final int selectedBed;
  final GardenPlot plot;
  final List<GardenBed> gardenBeds;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final Map<int, List<GardenPlant>> bedPlants;
  final List<SprayRecord> records;
  final Set<int> selectedBeds;
  final bool Function(int bed) isHold;
  final bool designing;
  final ValueChanged<int> onTap;
  final ValueChanged<GardenBed>? onPlanBed;
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
                child: RepaintBoundary(
                  child: CustomPaint(painter: GridPainter(widget.plot)),
                ),
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
                final hitRect =
                    widget.designing ? rect : _expandedBedHitRect(rect, size);
                final childOffset = rect.topLeft - hitRect.topLeft;
                final bedButton = BedButton(
                  bed: visibleBed,
                  selected: widget.selectedBed == bed.number ||
                      widget.selectedBeds.contains(bed.number),
                  hold: widget.isHold(bed.number),
                  crops: widget.bedCrops[bed.number] ??
                      const <VegetableDefinition>[],
                  plants: widget.bedPlants[bed.number] ?? const <GardenPlant>[],
                  activity: _bedMapActivity(widget.records, bed.number),
                  designing: widget.designing,
                  onTap: () => widget.onTap(bed.number),
                  onPlanBed: widget.onPlanBed == null
                      ? null
                      : () => widget.onPlanBed!(bed),
                );
                return Positioned.fromRect(
                  rect: hitRect,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.designing
                        ? null
                        : () => widget.onTap(bed.number),
                    onPanStart:
                        widget.designing ? (_) => _startDrag(bed) : null,
                    onPanUpdate: widget.designing
                        ? (details) => _updateDrag(details, size)
                        : null,
                    onPanEnd: widget.designing ? (_) => _finishDrag(bed) : null,
                    onPanCancel: widget.designing ? _cancelDrag : null,
                    child: RepaintBoundary(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: childOffset.dx,
                            top: childOffset.dy,
                            width: rect.width,
                            height: rect.height,
                            child: widget.designing
                                ? bedButton
                                : IgnorePointer(child: bedButton),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      );
}

Rect _expandedBedHitRect(Rect visualRect, Size mapSize) {
  const minTarget = 48.0;
  final width = math.max(visualRect.width, minTarget);
  final height = math.max(visualRect.height, minTarget);
  final maxLeft = math.max(0.0, mapSize.width - width);
  final maxTop = math.max(0.0, mapSize.height - height);
  final left = (visualRect.center.dx - width / 2).clamp(0.0, maxLeft);
  final top = (visualRect.center.dy - height / 2).clamp(0.0, maxTop);
  return Rect.fromLTWH(left, top, width, height);
}

class BedButton extends StatelessWidget {
  const BedButton({
    required this.bed,
    required this.selected,
    required this.hold,
    required this.crops,
    required this.plants,
    required this.activity,
    required this.designing,
    required this.onTap,
    this.onPlanBed,
    super.key,
  });
  final GardenBed bed;
  final bool selected;
  final bool hold;
  final bool designing;
  final List<VegetableDefinition> crops;
  final List<GardenPlant> plants;
  final BedMapActivity activity;
  final VoidCallback onTap;
  final VoidCallback? onPlanBed;

  @override
  Widget build(BuildContext context) {
    final semanticLabel = _bedMapSemanticLabel(
      bed: bed,
      selected: selected,
      hold: hold,
      crops: crops,
      plants: plants,
      activity: activity,
    );
    final activityColor = _bedActivityPrimaryColor(activity);
    final fill = hold
        ? const Color(0xFFFFF4DF)
        : activity.latestSpray != null
            ? C.blueSoft
            : activity.latestFeed != null
                ? C.amberSoft
                : crops.isEmpty && plants.isEmpty
                    ? const Color(0xFFF4E8D6)
                    : const Color(0xFFE7F1DC);
    final border = selected
        ? C.forest
        : hold
            ? C.amber
            : activity.hasActivity
                ? activityColor
                : C.soil.withValues(alpha: .42);
    return Semantics(
      label: semanticLabel,
      button: true,
      selected: selected,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: border, width: selected ? 3.2 : 1.15),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: C.forest.withValues(alpha: .24),
                      blurRadius: 12,
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
                      planted: crops.isNotEmpty || plants.isNotEmpty,
                      hold: hold,
                      sprayed: activity.latestSpray != null,
                      fed: activity.latestFeed != null,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: designing
                      ? _DesignBedMapContent(
                          bed: bed,
                          selected: selected,
                          crops: crops,
                          plants: plants,
                          activity: activity,
                          onPlanBed: onPlanBed,
                        )
                      : _OperationalBedMapContent(
                          bed: bed,
                          selected: selected,
                          crops: crops,
                          plants: plants,
                          activity: activity,
                          onPlanBed: onPlanBed,
                        ),
                ),
                if (activity.hasActivity)
                  Positioned(
                    top: 4,
                    right: selected ? 26 : 4,
                    child: _BedActivityCornerMarkers(activity: activity),
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
      ),
    );
  }
}

String _bedMapSemanticLabel({
  required GardenBed bed,
  required bool selected,
  required bool hold,
  required List<VegetableDefinition> crops,
  required List<GardenPlant> plants,
  required BedMapActivity activity,
}) {
  final cropCounts = _bedCropCounts(crops, plants);
  final cropText = cropCounts.isEmpty
      ? 'no vegetables logged'
      : cropCounts
          .map(
            (item) =>
                '${item.crop.name}, ${item.count} plant${item.count == 1 ? '' : 's'}',
          )
          .join('; ');
  final status = hold ? 'on withholding hold' : 'not on hold';
  final activityText = activity.hasActivity
      ? ', recent ${activity.latestSpray != null ? 'spray' : 'feed'} logged'
      : '';
  return '${selected ? 'Selected. ' : ''}${bed.label}, $cropText, $status$activityText.';
}

Color _bedActivityPrimaryColor(BedMapActivity activity) {
  if (activity.latestSpray != null) {
    return targetById(activity.latestSpray!.targetId).color;
  }
  if (activity.latestFeed != null) {
    return targetById(activity.latestFeed!.targetId).color;
  }
  return C.soil;
}

class _BedActivityCornerMarkers extends StatelessWidget {
  const _BedActivityCornerMarkers({required this.activity});

  final BedMapActivity activity;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (activity.latestSpray != null)
            _BedActivityCornerDot(record: activity.latestSpray!),
          if (activity.latestFeed != null) ...[
            const SizedBox(width: 3),
            _BedActivityCornerDot(record: activity.latestFeed!),
          ],
        ],
      );
}

class _BedActivityCornerDot extends StatelessWidget {
  const _BedActivityCornerDot({required this.record});

  final SprayRecord record;

  @override
  Widget build(BuildContext context) {
    final target = targetById(record.targetId);
    final hold = record.onHold;
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hold ? C.amber : target.color,
        shape: BoxShape.circle,
        border: Border.all(color: C.card, width: 1.7),
        boxShadow: [
          BoxShadow(
            color: (hold ? C.amber : target.color).withValues(alpha: .22),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        hold ? CupertinoIcons.hand_raised_fill : target.icon,
        color: CupertinoColors.white,
        size: 12,
      ),
    );
  }
}

class _DesignBedMapContent extends StatelessWidget {
  const _DesignBedMapContent({
    required this.bed,
    required this.selected,
    required this.crops,
    required this.plants,
    required this.activity,
    required this.onPlanBed,
  });

  final GardenBed bed;
  final bool selected;
  final List<VegetableDefinition> crops;
  final List<GardenPlant> plants;
  final BedMapActivity activity;
  final VoidCallback? onPlanBed;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 46 || constraints.maxHeight < 14;
          final thin = !compact && constraints.maxHeight < 42;
          final title = _BedMapTitle(
            title: compact || thin ? '${bed.number}' : bed.label,
            selected: selected,
            compact: compact || thin,
          );
          return Stack(
            children: [
              if (compact)
                Positioned.fill(child: Center(child: title))
              else if (thin)
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(5, 3, selected ? 27 : 5, 3),
                    child: Row(
                      children: [
                        title,
                        if (crops.isNotEmpty || plants.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Expanded(
                            child: _BedCropIconMarkers(
                              crops: crops,
                              plants: plants,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                Positioned(
                  top: 5,
                  left: 5,
                  right: selected ? 27 : 5,
                  child: Align(
                    alignment:
                        crops.isEmpty ? Alignment.center : Alignment.topLeft,
                    child: title,
                  ),
                ),
              if (!compact && !thin && (crops.isNotEmpty || plants.isNotEmpty))
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      8,
                      constraints.maxHeight < 54 ? 6 : 26,
                      8,
                      activity.hasActivity ? 31 : 6,
                    ),
                    child: _BedCropIconMarkers(crops: crops, plants: plants),
                  ),
                ),
              if (!compact && !thin && activity.hasActivity)
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
    required this.plants,
    required this.activity,
    required this.onPlanBed,
  });

  final GardenBed bed;
  final bool selected;
  final List<VegetableDefinition> crops;
  final List<GardenPlant> plants;
  final BedMapActivity activity;
  final VoidCallback? onPlanBed;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 46 || constraints.maxHeight < 14;
          final thin = !compact && constraints.maxHeight < 42;
          final title = _BedMapTitle(
            title: compact || thin ? '${bed.number}' : bed.label,
            selected: selected,
            compact: compact || thin,
          );
          return Stack(
            children: [
              if (compact)
                Positioned.fill(child: Center(child: title))
              else if (thin)
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(5, 3, selected ? 25 : 5, 3),
                    child: Row(
                      children: [
                        title,
                        if (crops.isNotEmpty || plants.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Expanded(
                            child: _BedCropIconMarkers(
                              crops: crops,
                              plants: plants,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                Positioned(
                  top: 5,
                  left: 5,
                  right: selected ? 25 : 5,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: title,
                  ),
                ),
              if (!compact && !thin && (crops.isNotEmpty || plants.isNotEmpty))
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      8,
                      constraints.maxHeight < 54 ? 6 : 26,
                      8,
                      activity.hasActivity ? 31 : 6,
                    ),
                    child: _BedCropIconMarkers(crops: crops, plants: plants),
                  ),
                ),
              if (!compact && !thin && activity.hasActivity)
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
  const _BedSurfacePainter({
    required this.planted,
    required this.hold,
    required this.sprayed,
    required this.fed,
  });

  final bool planted;
  final bool hold;
  final bool sprayed;
  final bool fed;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..color = hold
          ? const Color(0xFFFFEAC2)
          : sprayed
              ? C.blueSoft
              : fed
                  ? C.amberSoft
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
      planted != oldDelegate.planted ||
      hold != oldDelegate.hold ||
      sprayed != oldDelegate.sprayed ||
      fed != oldDelegate.fed;
}

class _BedMapTitle extends StatelessWidget {
  const _BedMapTitle({
    required this.title,
    required this.selected,
    this.compact = false,
  });

  final String title;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints(maxWidth: compact ? 34 : 96, minWidth: 22),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 5 : 6,
          vertical: compact ? 1 : 3,
        ),
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
            height: 1.05,
          ).copyWith(fontSize: compact ? 9 : 10),
        ),
      );
}

class _BedCropIconMarkers extends StatelessWidget {
  const _BedCropIconMarkers({required this.crops, required this.plants});

  final List<VegetableDefinition> crops;
  final List<GardenPlant> plants;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final items = _bedCropCounts(crops, plants);
          if (items.isEmpty) return const SizedBox.shrink();

          final width =
              constraints.maxWidth.isFinite ? constraints.maxWidth : 120.0;
          final height =
              constraints.maxHeight.isFinite ? constraints.maxHeight : 28.0;
          final shortestSide = math.min(width, height);
          final iconSize = math.min(
            20.0,
            math.max(10.0, shortestSide * .72),
          );
          final markerSize = iconSize + 2;
          final columns = math.max(1, (width / (markerSize + 2)).floor());
          final rows = math.max(1, (height / (markerSize + 2)).floor());
          final maxIcons = math.max(1, columns * rows);
          final visible = items.take(maxIcons).toList(growable: false);
          final hidden = items.length - visible.length;

          return Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              spacing: 2,
              runSpacing: 1,
              children: [
                for (final item in visible)
                  _BedCropIconDot(
                    crop: item.crop,
                    markerSize: markerSize,
                    iconSize: iconSize,
                  ),
                if (hidden > 0)
                  _BedHiddenCropCount(count: hidden, size: markerSize),
              ],
            ),
          );
        },
      );
}

class _BedCropIconDot extends StatelessWidget {
  const _BedCropIconDot({
    required this.crop,
    required this.markerSize,
    required this.iconSize,
  });

  final VegetableDefinition crop;
  final double markerSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: markerSize,
        height: markerSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: C.ink.withValues(alpha: .10),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(child: CropIcon(crop.iconPath, size: iconSize)),
        ),
      );
}

class _BedHiddenCropCount extends StatelessWidget {
  const _BedHiddenCropCount({required this.count, required this.size});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: C.forest.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          child: Text(
            '+$count',
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      );
}

class _GardenCropCount {
  const _GardenCropCount({required this.crop, required this.count});

  final VegetableDefinition crop;
  final int count;
}

List<_GardenCropCount> _bedCropCounts(
  List<VegetableDefinition> crops,
  List<GardenPlant> plants,
) {
  final counts = <String, int>{};
  for (final plant in plants) {
    counts[plant.crop.id] = (counts[plant.crop.id] ?? 0) + 1;
  }

  final seen = <String>{};
  final result = <_GardenCropCount>[];
  for (final crop in crops) {
    seen.add(crop.id);
    result.add(_GardenCropCount(crop: crop, count: counts[crop.id] ?? 0));
  }
  for (final plant in plants) {
    if (seen.add(plant.crop.id)) {
      result.add(
        _GardenCropCount(
          crop: plant.crop,
          count: counts[plant.crop.id] ?? 0,
        ),
      );
    }
  }
  return result;
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
  const GardenMapFrame({
    required this.child,
    this.height = 380,
    this.showLegend = true,
    super.key,
  });

  final Widget child;
  final double height;
  final bool showLegend;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE8D8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: C.line),
          boxShadow: softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(child: child),
            if (showLegend)
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
