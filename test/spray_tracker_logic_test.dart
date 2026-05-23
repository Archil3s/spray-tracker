import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spray_tracker/crop_library.dart';
import 'package:spray_tracker/main.dart';
import 'package:spray_tracker/models/garden_snapshot.dart';
import 'package:spray_tracker/models/openfarm_crop.dart';
import 'package:spray_tracker/models/spray_condition.dart';

void main() {
  group('cropNamesForBeds', () {
    test('collects sorted unique crops for selected beds', () {
      final lettuce = _crop('lettuce');
      final onion = _crop('onion');
      final tomato = _crop('tomato');

      final cropNames = cropNamesForBeds(
        {
          2: [lettuce, tomato],
          4: [tomato, onion],
        },
        [4, 99, 2],
      );

      expect(cropNames, ['Lettuce', 'Onion', 'Tomato']);
    });
  });

  group('nextActiveSprayRecord', () {
    test('returns the active record with the next safe harvest', () {
      final now = DateTime(2026, 5, 22);
      final laterHold = _record(
        id: 1,
        date: now.subtract(const Duration(days: 1)),
        withholdingDays: 5,
      );
      final safeRecord = _record(
        id: 2,
        date: now.subtract(const Duration(days: 5)),
        withholdingDays: 1,
      );
      final nextHold = _record(
        id: 3,
        date: now.subtract(const Duration(days: 1)),
        withholdingDays: 2,
      );

      expect(
        nextActiveSprayRecord([laterHold, safeRecord, nextHold], now: now),
        same(nextHold),
      );
    });

    test('returns null when every record is safe', () {
      final now = DateTime(2026, 5, 22);

      expect(
        nextActiveSprayRecord([
          _record(
            id: 1,
            date: now.subtract(const Duration(days: 4)),
            withholdingDays: 1,
          ),
        ], now: now),
        isNull,
      );
    });
  });

  group('bedSpraySummary', () {
    test('returns unsprayed when no record targets the bed', () {
      final summary = bedSpraySummary(
        [
          _record(
            id: 1,
            beds: const [2],
            date: DateTime(2026, 5, 20),
            withholdingDays: 7,
          ),
        ],
        1,
        now: DateTime(2026, 5, 22),
      );

      expect(summary.state, BedSprayState.neverSprayed);
      expect(summary.record, isNull);
    });

    test('uses the latest spray record for the selected bed', () {
      final now = DateTime(2026, 5, 22);
      final older = _record(
        id: 1,
        beds: const [1],
        date: now.subtract(const Duration(days: 5)),
        withholdingDays: 7,
      );
      final latest = _record(
        id: 2,
        beds: const [1, 2],
        date: now.subtract(const Duration(days: 1)),
        withholdingDays: 7,
      );

      final summary = bedSpraySummary([older, latest], 1, now: now);

      expect(summary.state, BedSprayState.hold);
      expect(summary.record, same(latest));
    });

    test('marks a sprayed bed clear after withholding has passed', () {
      final now = DateTime(2026, 5, 22);
      final record = _record(
        id: 1,
        beds: const [1],
        date: now.subtract(const Duration(days: 10)),
        withholdingDays: 7,
      );

      expect(
        bedSpraySummary([record], 1, now: now).state,
        BedSprayState.clear,
      );
    });
  });

  group('summarizeSprayConditions', () {
    test('marks a calm dry mild forecast as good', () {
      final summary = summarizeSprayConditions([
        for (var index = 0; index < 8; index++)
          _forecastHour(index, temperature: 18, wind: 9),
      ]);

      expect(summary.kind, SprayConditionKind.good);
      expect(summary.nextGoodWindow?.start, DateTime(2026, 5, 22, 7));
    });

    test('prioritizes rain within six hours over heat', () {
      final summary = summarizeSprayConditions([
        _forecastHour(0, temperature: 31, wind: 8),
        _forecastHour(1, temperature: 20, wind: 8),
        _forecastHour(2, temperature: 20, wind: 8, rain: 0.4),
      ]);

      expect(summary.kind, SprayConditionKind.rain);
    });

    test('uses wind warning before other warnings', () {
      final summary = summarizeSprayConditions([
        _forecastHour(0, temperature: 31, wind: 18, rain: 0.2),
      ]);

      expect(summary.kind, SprayConditionKind.wind);
    });
  });

  group('summarizeGardenRisks', () {
    test('flags high frost risk below freezing', () {
      final summary = summarizeGardenRisks([
        _forecastHour(0, temperature: -1, wind: 4),
        _forecastHour(1, temperature: 4, wind: 5),
      ]);

      expect(summary.frostRisk, GardenRiskLevel.high);
      expect(summary.lowestTemperatureC, -1);
    });

    test('flags high soil evaporation in hot dry wind', () {
      final summary = summarizeGardenRisks([
        for (var index = 0; index < 24; index++)
          _forecastHour(index, temperature: 25, wind: 21),
      ]);

      expect(summary.soilEvaporationRisk, GardenRiskLevel.high);
      expect(summary.rainNext24HoursMm, 0);
    });

    test('flags high pest pressure when mild and wet', () {
      final summary = summarizeGardenRisks([
        for (var index = 0; index < 24; index++)
          _forecastHour(index, temperature: 18, wind: 6, rain: 0.3),
      ]);

      expect(summary.pestPressureRisk, GardenRiskLevel.high);
    });
  });

  group('planSprayWindowReminder', () {
    test('uses an evening heads-up for tomorrow', () {
      final now = DateTime(2026, 5, 22, 18);
      final window = SprayWindow(
        start: DateTime(2026, 5, 23, 7),
        end: DateTime(2026, 5, 23, 9),
      );

      expect(
        planSprayWindowReminder(window, now: now)?.notifyAt,
        DateTime(2026, 5, 22, 19),
      );
    });

    test('uses a lead reminder for a same-day future window', () {
      final now = DateTime(2026, 5, 22, 7);
      final window = SprayWindow(
        start: DateTime(2026, 5, 22, 9),
        end: DateTime(2026, 5, 22, 11),
      );

      expect(
        planSprayWindowReminder(window, now: now)?.notifyAt,
        DateTime(2026, 5, 22, 8, 30),
      );
    });

    test('skips windows that already started', () {
      final now = DateTime(2026, 5, 22, 9);
      final window = SprayWindow(
        start: DateTime(2026, 5, 22, 8),
        end: DateTime(2026, 5, 22, 10),
      );

      expect(planSprayWindowReminder(window, now: now), isNull);
    });
  });

  group('GardenSnapshot', () {
    test('round-trips local garden data', () {
      final snapshot = GardenSnapshot(
        nextRecordId: 9,
        bedCropIds: const {
          4: ['tomato', 'chilli'],
          5: ['onion'],
        },
        records: [
          StoredSprayRecord(
            id: 8,
            beds: const [4, 5],
            crops: const ['Chilli', 'Onion'],
            targetId: 'fungus',
            product: 'Copper',
            productId: 'copper',
            reason: 'Mildew risk',
            notes: 'Evening spray',
            date: DateTime(2026, 5, 22, 18, 30),
            days: 7,
          ),
        ],
        beds: const [
          StoredGardenBed(
            number: 12,
            name: 'Herb strip',
            left: .14,
            top: .26,
            width: .31,
            height: .09,
            widthMeters: 1.25,
            lengthMeters: 2.4,
          ),
        ],
        plants: const [
          StoredGardenPlant(
            id: 31,
            bed: 12,
            cropId: 'strawberry',
            x: .24,
            y: .62,
          ),
        ],
        plotWidthMeters: 10.5,
        plotLengthMeters: 14,
      );

      final restored = GardenSnapshot.fromJson(snapshot.toJson());

      expect(restored.nextRecordId, 9);
      expect(restored.bedCropIds[4], ['tomato', 'chilli']);
      expect(restored.records.single.product, 'Copper');
      expect(restored.records.single.beds, [4, 5]);
      expect(restored.records.single.date, DateTime(2026, 5, 22, 18, 30));
      expect(restored.beds.single.name, 'Herb strip');
      expect(restored.beds.single.left, .14);
      expect(restored.beds.single.widthMeters, 1.25);
      expect(restored.beds.single.lengthMeters, 2.4);
      expect(restored.plants.single.cropId, 'strawberry');
      expect(restored.plants.single.x, .24);
      expect(restored.plotWidthMeters, 10.5);
      expect(restored.plotLengthMeters, 14);
    });
  });

  group('GardenBed', () {
    test('keeps moved and resized beds inside the map', () {
      const bed = GardenBed(3, Rect.fromLTWH(.70, .80, .24, .16));

      final moved = bed.move(const Offset(.20, .20));
      final resized = moved.resize(const Offset(.20, .20));

      expect(moved.rect.right, lessThanOrEqualTo(.99));
      expect(moved.rect.bottom, lessThanOrEqualTo(.99));
      expect(resized.rect.right, lessThanOrEqualTo(.99));
      expect(resized.rect.bottom, lessThanOrEqualTo(.99));
    });

    test('uses metre dimensions for its map footprint', () {
      const bed = GardenBed(4, Rect.fromLTWH(.20, .20, .10, .10));

      final sized = bed.sizeToMeters(1, 2);

      expect(sized.widthMeters, 1);
      expect(sized.lengthMeters, 2);
      expect(sized.rect.width, closeTo(1 / gardenMapWidthMeters, .001));
      expect(sized.rect.height, closeTo(2 / gardenMapLengthMeters, .001));
      expect(sized.sizeLabel, '1 x 2 m');
    });

    test('rotates physical size inside a custom plot', () {
      const plot = GardenPlot(widthMeters: 4, lengthMeters: 6);
      const bed = GardenBed(
        5,
        Rect.fromLTWH(.20, .20, .25, .33),
        widthMeters: 1,
        lengthMeters: 2,
      );

      final rotated = bed.rotate(plot: plot);

      expect(rotated.widthMeters, 2);
      expect(rotated.lengthMeters, 1);
      expect(rotated.rect.width, closeTo(.5, .001));
      expect(rotated.rect.height, closeTo(1 / 6, .001));
    });
  });

  group('GardenMap', () {
    testWidgets('commits a bed move after the drag ends', (tester) async {
      final moves = <Offset>[];
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              width: 320,
              height: 480,
              child: GardenMap(
                selectedBed: 1,
                plot: defaultGardenPlot,
                gardenBeds: const [
                  GardenBed(1, Rect.fromLTWH(.10, .10, .25, .20)),
                ],
                bedCrops: const {},
                isHold: (_) => false,
                designing: true,
                onTap: (_) {},
                onMove: (_, delta) => moves.add(delta),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(BedButton)),
      );
      await gesture.moveBy(const Offset(24, 18));
      await tester.pump();
      expect(moves, isEmpty);

      await gesture.moveBy(const Offset(16, 6));
      await tester.pump();
      expect(moves, isEmpty);

      await gesture.up();
      await tester.pump();
      expect(moves, hasLength(1));
      expect(moves.single.dx, greaterThan(0));
      expect(moves.single.dy, greaterThan(0));
    });
  });

  group('Planting grid', () {
    test('uses crop spacing to build centered bed grid positions', () {
      const bed = GardenBed(
        1,
        Rect.fromLTWH(.10, .10, .10, .10),
        widthMeters: 1,
        lengthMeters: 2,
      );
      const spacing = CropSpacing(
        plantCm: 50,
        rowCm: 100,
        source: 'Test',
      );

      final grid = plantingGridPositions(bed, spacing);

      expect(grid, hasLength(4));
      expect(grid.first.dx, closeTo(.25, .001));
      expect(grid.first.dy, closeTo(.25, .001));
    });

    test('snaps a bed tap to its nearest spacing grid point', () {
      final position = snapPlantPosition(
        const Offset(.62, .31),
        const [Offset(.25, .25), Offset(.75, .25), Offset(.25, .75)],
      );

      expect(position, const Offset(.75, .25));
    });

    test('scales plant footprint against the real bed size', () {
      const bed = GardenBed(
        1,
        Rect.fromLTWH(.10, .10, .10, .10),
        widthMeters: 1,
        lengthMeters: 2,
      );
      const carrot = CropSpacing(plantCm: 8, rowCm: 20, source: 'Test');
      const tomato = CropSpacing(plantCm: 50, rowCm: 70, source: 'Test');

      expect(plantFootprintFractions(bed, carrot).width, closeTo(.08, .001));
      expect(plantFootprintFractions(bed, carrot).height, closeTo(.04, .001));
      expect(
        plantIconExtent(const Size(100, 200), bed, carrot),
        lessThan(plantIconExtent(const Size(100, 200), bed, tomato)),
      );
      expect(
        plantIconExtent(const Size(100, 200), bed, carrot),
        closeTo(8, .001),
      );
      expect(
        visualPlantIconExtent(const Size(100, 200), bed, carrot),
        closeTo(8, .001),
      );
    });

    test('clamps unrealistically tight OpenFarm spacing to garden guide', () {
      const profile = OpenFarmCrop(
        name: 'Spring onion',
        description: '',
        sunRequirements: '',
        sowingMethod: '',
        spread: 3,
        rowSpacing: 5,
        height: null,
        imageUrl: '',
        tags: [],
        slug: 'spring-onion',
      );

      final spacing = cropSpacingFor(_crop('spring_onion'), profile);

      expect(spacing.plantCm, 12);
      expect(spacing.rowCm, 25);
    });

    test('fits bed previews to their physical aspect ratio', () {
      const bed = GardenBed(
        1,
        Rect.fromLTWH(.10, .10, .10, .10),
        widthMeters: 1,
        lengthMeters: 2,
      );

      final size = fittedBedCanvasSize(const Size(300, 200), bed);

      expect(size.width, closeTo(100, .001));
      expect(size.height, closeTo(200, .001));
    });

    test('keeps new plants out of existing plant footprints', () {
      const bed = GardenBed(
        1,
        Rect.fromLTWH(.10, .10, .10, .10),
        widthMeters: 2,
        lengthMeters: 2,
      );
      const spacing = CropSpacing(plantCm: 60, rowCm: 90, source: 'Test');
      final tomato = GardenPlant(
        id: 1,
        bed: 1,
        crop: _crop('tomato'),
        position: const Offset(.5, .5),
      );

      expect(
        plantSpotIsOpen(
          bed,
          const Offset(.65, .5),
          spacing,
          [tomato],
          (_) => spacing,
        ),
        isFalse,
      );
      expect(
        plantSpotIsOpen(
          bed,
          const Offset(.85, .5),
          spacing,
          [tomato],
          (_) => spacing,
        ),
        isTrue,
      );
    });

    test('uses the nearest open grid spot when a tap lands on a plant', () {
      const bed = GardenBed(
        1,
        Rect.fromLTWH(.10, .10, .10, .10),
        widthMeters: 2,
        lengthMeters: 2,
      );
      const spacing = CropSpacing(plantCm: 40, rowCm: 40, source: 'Test');
      final existing = GardenPlant(
        id: 1,
        bed: 1,
        crop: _crop('lettuce'),
        position: const Offset(.5, .5),
      );

      final open = nearestOpenPlantSpot(
        bed,
        const Offset(.5, .5),
        const [Offset(.5, .5), Offset(.69, .5), Offset(.74, .5)],
        spacing,
        [existing],
        (_) => spacing,
      );

      expect(open, const Offset(.74, .5));
    });

    test('builds a horizontal row preview from a drag path', () {
      const bed = GardenBed(
        1,
        Rect.fromLTWH(.10, .10, .10, .10),
        widthMeters: 2,
        lengthMeters: 2,
      );
      const spacing = CropSpacing(plantCm: 50, rowCm: 50, source: 'Test');
      final grid = plantingGridPositions(bed, spacing);

      final preview = rowPlantPreviewSpots(
        bed,
        grid,
        const Offset(.125, .125),
        const Offset(.70, .18),
        spacing,
        const <GardenPlant>[],
        (_) => spacing,
      );

      expect(preview, hasLength(3));
      expect(preview.map((spot) => spot.dy).toSet(), hasLength(1));
    });

    test('builds a vertical row preview from a drag path', () {
      const bed = GardenBed(
        1,
        Rect.fromLTWH(.10, .10, .10, .10),
        widthMeters: 2,
        lengthMeters: 2,
      );
      const spacing = CropSpacing(plantCm: 50, rowCm: 50, source: 'Test');
      final grid = plantingGridPositions(bed, spacing);

      final preview = rowPlantPreviewSpots(
        bed,
        grid,
        const Offset(.125, .125),
        const Offset(.18, .70),
        spacing,
        const <GardenPlant>[],
        (_) => spacing,
      );

      expect(preview, hasLength(3));
      expect(preview.map((spot) => spot.dx).toSet(), hasLength(1));
    });

    test('generates a mixed auto bed plan for quick turnover', () {
      const bed = GardenBed(
        1,
        Rect.fromLTWH(.10, .10, .10, .10),
        widthMeters: 2,
        lengthMeters: 3,
      );

      final plan = generateAutoBedPlan(
        bed: bed,
        style: AutoBedFoodStyle.quick,
        existingPlants: const <GardenPlant>[],
        spacingForCrop: cropSpacingFor,
        spacingForPlant: (plant) => cropSpacingFor(plant.crop),
      );

      expect(plan.totalPlants, greaterThan(0));
      expect(plan.placements.keys.length, greaterThan(1));
      expect(
        plan.placements.keys.map((crop) => crop.id),
        contains('lettuce'),
      );
    });

    test('companion-aware mix adds useful companion crops', () {
      final mix = companionAwareAutoBedCropMix(AutoBedFoodStyle.salad);
      final cropIds = mix.map((item) => item.cropId).toSet();

      expect(cropIds, contains('tomato'));
      expect(cropIds, contains('chives'));
      expect(cropIds, contains('parsley'));
    });

    test('auto bed plan fills a bed without household sizing', () {
      const bed = GardenBed(
        1,
        Rect.fromLTWH(.10, .10, .10, .10),
        widthMeters: 2,
        lengthMeters: 3,
      );

      final plan = generateAutoBedPlan(
        bed: bed,
        style: AutoBedFoodStyle.salad,
        existingPlants: const <GardenPlant>[],
        spacingForCrop: cropSpacingFor,
        spacingForPlant: (plant) => cropSpacingFor(plant.crop),
        seasonDate: DateTime(2026, 5, 23),
      );

      expect(plan.totalPlants, greaterThan(12));
      final cropIds = plan.placements.keys.map((crop) => crop.id).toSet();
      expect(
        cropIds.intersection({'chives', 'parsley', 'onion', 'leek'}),
        isNotEmpty,
      );
    });

    test('auto bed plan filters warm-season crops out in autumn', () {
      const bed = GardenBed(
        1,
        Rect.fromLTWH(.10, .10, .10, .10),
        widthMeters: 2,
        lengthMeters: 3,
      );

      final plan = generateAutoBedPlan(
        bed: bed,
        style: AutoBedFoodStyle.salad,
        existingPlants: const <GardenPlant>[],
        spacingForCrop: cropSpacingFor,
        spacingForPlant: (plant) => cropSpacingFor(plant.crop),
        seasonDate: DateTime(2026, 5, 23),
      );
      final cropIds = plan.placements.keys.map((crop) => crop.id).toSet();

      expect(cropIds, isNot(contains('tomato')));
      expect(cropIds, isNot(contains('cucumber')));
      expect(cropIds, contains('lettuce'));
    });

    test('auto bed plan avoids existing plant footprints', () {
      const bed = GardenBed(
        1,
        Rect.fromLTWH(.10, .10, .10, .10),
        widthMeters: 2,
        lengthMeters: 2,
      );
      final existing = GardenPlant(
        id: 1,
        bed: 1,
        crop: _crop('tomato'),
        position: const Offset(.5, .5),
      );

      final plan = generateAutoBedPlan(
        bed: bed,
        style: AutoBedFoodStyle.balanced,
        existingPlants: [existing],
        spacingForCrop: cropSpacingFor,
        spacingForPlant: (plant) => cropSpacingFor(plant.crop),
      );

      for (final entry in plan.placements.entries) {
        for (final position in entry.value) {
          expect(
            plantFootprintsOverlap(
              bed,
              existing.position,
              cropSpacingFor(existing.crop),
              position,
              cropSpacingFor(entry.key),
            ),
            isFalse,
          );
        }
      }
    });

    test('auto bed plan groups crops into plantable bed sections', () {
      const bed = GardenBed(
        1,
        Rect.fromLTWH(.10, .10, .10, .10),
        widthMeters: 2,
        lengthMeters: 5,
      );

      final plan = generateAutoBedPlan(
        bed: bed,
        style: AutoBedFoodStyle.quick,
        existingPlants: const <GardenPlant>[],
        spacingForCrop: cropSpacingFor,
        spacingForPlant: (plant) => cropSpacingFor(plant.crop),
      );
      final ranges = [
        for (final positions in plan.placements.values)
          if (positions.isNotEmpty)
            (
              minY: positions.map((position) => position.dy).reduce(
                    (a, b) => a < b ? a : b,
                  ),
              maxY: positions.map((position) => position.dy).reduce(
                    (a, b) => a > b ? a : b,
                  ),
            ),
      ];

      expect(ranges.length, greaterThan(2));
      for (var index = 1; index < ranges.length; index++) {
        expect(
            ranges[index].minY, greaterThanOrEqualTo(ranges[index - 1].minY));
      }
    });

    test('auto bed plan orders crop bands by plant height', () {
      const bed = GardenBed(
        1,
        Rect.fromLTWH(.10, .10, .10, .10),
        widthMeters: 2,
        lengthMeters: 5,
      );

      final plan = generateAutoBedPlan(
        bed: bed,
        style: AutoBedFoodStyle.balanced,
        existingPlants: const <GardenPlant>[],
        spacingForCrop: cropSpacingFor,
        spacingForPlant: (plant) => cropSpacingFor(plant.crop),
        seasonDate: DateTime(2026, 10, 1),
      );
      final bandHeights = [
        for (final entry in plan.placements.entries)
          if (entry.value.isNotEmpty) cropHeightScore(entry.key),
      ];

      for (var index = 1; index < bandHeights.length; index++) {
        expect(
            bandHeights[index], greaterThanOrEqualTo(bandHeights[index - 1]));
      }
    });
  });

  group('Crop planner', () {
    testWidgets('stays open while a crop is planted and removed',
        (tester) async {
      final added = <String>[];
      final removed = <int>[];
      var nextPlantId = 1;
      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoButton(
              onPressed: () => showCropPlanner(
                context,
                const GardenBed(1, Rect.fromLTWH(.10, .10, .25, .20)),
                const [],
                const [],
                (bed, crop, position) {
                  added.add(crop.id);
                  return GardenPlant(
                    id: nextPlantId++,
                    bed: bed,
                    crop: crop,
                    position: position,
                  );
                },
                (bed, crop, positions) => [
                  for (final position in positions)
                    GardenPlant(
                      id: nextPlantId++,
                      bed: bed,
                      crop: crop,
                      position: position,
                    ),
                ],
                (_, plantId) => removed.add(plantId),
              ),
              child: const Text('Open planner'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open planner'));
      await tester.pumpAndSettle();
      expect(find.text('Plant bed'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('bed-planting-canvas')));
      await tester.pump();
      expect(added, ['tomato']);
      expect(find.byType(Sheet), findsOneWidget);

      await tester.tap(find.text('Erase'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Tomato'));
      await tester.pump();
      expect(removed, [1]);
      expect(find.byType(Sheet), findsOneWidget);
    });

    testWidgets('keeps painting when a tap lands on an existing plant',
        (tester) async {
      final added = <String>[];
      final removed = <int>[];
      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoButton(
              onPressed: () => showCropPlanner(
                context,
                const GardenBed(1, Rect.fromLTWH(.10, .10, .25, .20)),
                [_crop('tomato'), _crop('carrot')],
                [
                  GardenPlant(
                    id: 7,
                    bed: 1,
                    crop: _crop('carrot'),
                    position: const Offset(.5, .5),
                  ),
                ],
                (bed, crop, position) {
                  added.add(crop.id);
                  return GardenPlant(
                    id: 8,
                    bed: bed,
                    crop: crop,
                    position: position,
                  );
                },
                (_, __, ___) => const <GardenPlant>[],
                (_, plantId) => removed.add(plantId),
              ),
              child: const Text('Open planner'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open planner'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('selected-crop-tomato')),
        findsOneWidget,
      );

      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('placed-plant-7'))),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('selected-crop-tomato')),
        findsOneWidget,
      );
      expect(added, ['tomato']);
      expect(removed, isEmpty);
    });

    testWidgets('sizes each planted crop from its OpenFarm profile',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoButton(
              onPressed: () => showCropPlanner(
                context,
                const GardenBed(
                  1,
                  Rect.fromLTWH(.10, .10, .25, .20),
                  widthMeters: 2,
                  lengthMeters: 2,
                ),
                [_crop('lettuce'), _crop('tomato'), _crop('capsicum')],
                [
                  GardenPlant(
                    id: 21,
                    bed: 1,
                    crop: _crop('tomato'),
                    position: const Offset(.32, .5),
                  ),
                  GardenPlant(
                    id: 22,
                    bed: 1,
                    crop: _crop('capsicum'),
                    position: const Offset(.68, .5),
                  ),
                ],
                (bed, crop, position) => GardenPlant(
                  id: 23,
                  bed: bed,
                  crop: crop,
                  position: position,
                ),
                (_, __, ___) => const <GardenPlant>[],
                (_, __) {},
              ),
              child: const Text('Open planner'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open planner'));
      await tester.pumpAndSettle();

      final tomato = tester.getSize(
        find.byKey(const ValueKey('placed-plant-21')),
      );
      final capsicum = tester.getSize(
        find.byKey(const ValueKey('placed-plant-22')),
      );
      expect(tomato.width, greaterThan(capsicum.width));
    });

    testWidgets('drag paints a row of the selected crop', (tester) async {
      final rows = <List<Offset>>[];
      var nextPlantId = 31;
      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoButton(
              onPressed: () => showCropPlanner(
                context,
                const GardenBed(
                  1,
                  Rect.fromLTWH(.10, .10, .25, .20),
                  widthMeters: 2,
                  lengthMeters: 1,
                ),
                [_crop('carrot')],
                const [],
                (bed, crop, position) => GardenPlant(
                  id: nextPlantId++,
                  bed: bed,
                  crop: crop,
                  position: position,
                ),
                (bed, crop, positions) {
                  rows.add(positions);
                  return [
                    for (final position in positions)
                      GardenPlant(
                        id: nextPlantId++,
                        bed: bed,
                        crop: crop,
                        position: position,
                      ),
                  ];
                },
                (_, __) {},
              ),
              child: const Text('Open planner'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open planner'));
      await tester.pumpAndSettle();

      final surface = tester.getRect(find.byKey(const ValueKey(
        'bed-planting-surface',
      )));
      final start = Offset(surface.left + 24, surface.center.dy);
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(Offset((surface.width - 48) / 2, 0));
      await tester.pump();
      await gesture.moveBy(Offset((surface.width - 48) / 2, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(rows, isNotEmpty);
      expect(rows.single.length, greaterThan(1));
    });

    testWidgets('auto generator adds a mixed bed layout', (tester) async {
      final added = <String>[];
      var nextPlantId = 50;
      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoButton(
              onPressed: () => showCropPlanner(
                context,
                const GardenBed(
                  1,
                  Rect.fromLTWH(.10, .10, .25, .20),
                  widthMeters: 2,
                  lengthMeters: 2,
                ),
                [_crop('lettuce'), _crop('carrot')],
                const [],
                (bed, crop, position) => GardenPlant(
                  id: nextPlantId++,
                  bed: bed,
                  crop: crop,
                  position: position,
                ),
                (bed, crop, positions) {
                  added.add(crop.id);
                  return [
                    for (final position in positions)
                      GardenPlant(
                        id: nextPlantId++,
                        bed: bed,
                        crop: crop,
                        position: position,
                      ),
                  ];
                },
                (_, __) {},
              ),
              child: const Text('Open planner'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open planner'));
      await tester.pumpAndSettle();
      final generateButton = find.text(
        'Generate bed layout',
        skipOffstage: false,
      );
      await tester.ensureVisible(generateButton);
      await tester.pumpAndSettle();
      await tester.tap(generateButton);
      await tester.pump();

      expect(added, isNotEmpty);
      expect(added.toSet().length, greaterThan(1));
      expect(find.textContaining('crops'), findsOneWidget);
    });

    testWidgets('clear all removes every planted crop from the bed',
        (tester) async {
      final removed = <int>[];
      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoButton(
              onPressed: () => showCropPlanner(
                context,
                const GardenBed(
                  1,
                  Rect.fromLTWH(.10, .10, .25, .20),
                  widthMeters: 2,
                  lengthMeters: 2,
                ),
                [_crop('lettuce')],
                [
                  GardenPlant(
                    id: 71,
                    bed: 1,
                    crop: _crop('lettuce'),
                    position: const Offset(.35, .35),
                  ),
                  GardenPlant(
                    id: 72,
                    bed: 1,
                    crop: _crop('carrot'),
                    position: const Offset(.65, .65),
                  ),
                ],
                (bed, crop, position) => GardenPlant(
                  id: 73,
                  bed: bed,
                  crop: crop,
                  position: position,
                ),
                (_, __, ___) => const <GardenPlant>[],
                (_, plantId) => removed.add(plantId),
              ),
              child: const Text('Open planner'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open planner'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pump();

      expect(removed, [71, 72]);
      expect(find.byKey(const ValueKey('placed-plant-71')), findsNothing);
      expect(find.byKey(const ValueKey('placed-plant-72')), findsNothing);
    });
  });
}

VegetableDefinition _crop(String id) =>
    vegetableLibrary.firstWhere((crop) => crop.id == id);

SprayRecord _record({
  required int id,
  required DateTime date,
  required int withholdingDays,
  List<int> beds = const [1],
}) =>
    SprayRecord(
      id: id,
      beds: beds,
      crops: const ['Tomato'],
      cropProfiles: const {},
      targetId: 'pest',
      product: 'Test spray',
      productId: 'test',
      reason: '',
      notes: '',
      date: date,
      days: withholdingDays,
    );

SprayForecastHour _forecastHour(
  int index, {
  required double temperature,
  required double wind,
  double rain = 0,
}) =>
    SprayForecastHour(
      time: DateTime(2026, 5, 22, 7).add(Duration(hours: index)),
      temperatureC: temperature,
      windKph: wind,
      precipitationMm: rain,
      precipitationProbability: rain > 0 ? 80 : 0,
    );
