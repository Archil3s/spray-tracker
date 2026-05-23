part of '../../../main.dart';

class SprayTrackerHome extends StatefulWidget {
  const SprayTrackerHome({super.key});

  @override
  State<SprayTrackerHome> createState() => _SprayTrackerHomeState();
}

class _SprayTrackerHomeState extends State<SprayTrackerHome> {
  int tab = 0;
  int selectedBed = 4;
  int nextRecordId = 1;
  int nextPlantId = 1;
  String message = '';

  List<SprayProduct> products = const [];
  bool productsLoading = true;
  final Map<int, List<VegetableDefinition>> bedCrops = {};
  final Map<int, List<GardenPlant>> bedPlants = {};
  GardenPlot gardenPlot = defaultGardenPlot;
  List<GardenBed> gardenLayout = [...defaultGardenBeds];
  List<SprayRecord> records = [];
  late final Future<List<SprayForecastHour>> forecastHours;
  late final Future<SprayConditionSummary> sprayConditions;
  late final Future<GardenRiskSummary> gardenRisks;

  @override
  void initState() {
    super.initState();
    forecastHours = OpenMeteoService.instance.getBlenheimForecastHours();
    sprayConditions = _loadSprayConditions(forecastHours);
    gardenRisks = forecastHours.then(summarizeGardenRisks);
    _seedBeds();
    _loadSavedGarden();
    _loadProducts();
  }

  Future<SprayConditionSummary> _loadSprayConditions(
    Future<List<SprayForecastHour>> forecast,
  ) async {
    final summary = summarizeSprayConditions(await forecast);
    unawaited(_scheduleSprayWindowReminder(summary));
    return summary;
  }

  Future<void> _scheduleSprayWindowReminder(
    SprayConditionSummary summary,
  ) async {
    try {
      await HarvestReminderService.instance.scheduleSprayWindow(
        planSprayWindowReminder(
          summary.nextGoodWindow,
          now: DateTime.now(),
        ),
      );
    } catch (_) {
      // Weather guidance remains useful when notification permission is denied.
    }
  }

  void _seedBeds() {
    VegetableDefinition byId(String id) => vegetableLibrary.firstWhere(
          (crop) => crop.id == id,
          orElse: () => vegetableLibrary.first,
        );
    bedCrops[4] = [byId('tomato'), byId('chilli'), byId('capsicum')];
    bedCrops[5] = [byId('onion'), byId('garlic')];
    bedCrops[9] = [byId('zucchini')];
    bedCrops[2] = [byId('lettuce')];
    final seeded = _defaultPlantingsForCrops(bedCrops);
    bedPlants
      ..clear()
      ..addAll(seeded);
    nextPlantId = _nextGardenPlantId(seeded);
  }

  Future<void> _loadSavedGarden() async {
    try {
      final snapshot = await LocalGardenRepository.instance.load();
      if (!mounted || snapshot == null) return;

      final restoredBedCrops = _restoreBedCrops(snapshot.bedCropIds);
      final restoredPlants = snapshot.plants.isEmpty
          ? _defaultPlantingsForCrops(restoredBedCrops)
          : _restoreGardenPlants(snapshot.plants);
      _addPlantCrops(restoredBedCrops, restoredPlants);
      final restoredRecords =
          snapshot.records.map(_recordFromStorage).toList(growable: false);
      final restoredLayout = _restoreGardenLayout(snapshot.beds);
      final restoredPlot = GardenPlot(
        widthMeters: snapshot.plotWidthMeters > 0
            ? snapshot.plotWidthMeters
            : defaultGardenPlot.widthMeters,
        lengthMeters: snapshot.plotLengthMeters > 0
            ? snapshot.plotLengthMeters
            : defaultGardenPlot.lengthMeters,
      );
      setState(() {
        bedCrops
          ..clear()
          ..addAll(restoredBedCrops);
        bedPlants
          ..clear()
          ..addAll(restoredPlants);
        if (restoredLayout.isNotEmpty) {
          gardenLayout = restoredLayout;
        }
        gardenPlot = restoredPlot;
        records = restoredRecords;
        nextRecordId = _nextRecordId(snapshot, restoredRecords);
        nextPlantId = _nextGardenPlantId(restoredPlants);
        message = 'Garden loaded from this phone';
      });
      unawaited(_restoreHarvestReminders(restoredRecords));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        message = 'Saved garden could not be loaded';
      });
    }
  }

  Map<int, List<VegetableDefinition>> _restoreBedCrops(
    Map<int, List<String>> bedCropIds,
  ) {
    final cropsById = {for (final crop in vegetableLibrary) crop.id: crop};
    return {
      for (final entry in bedCropIds.entries)
        entry.key: entry.value
            .map((id) => cropsById[id])
            .whereType<VegetableDefinition>()
            .toList(growable: false),
    }..removeWhere((_, crops) => crops.isEmpty);
  }

  Map<int, List<GardenPlant>> _defaultPlantingsForCrops(
    Map<int, List<VegetableDefinition>> cropsByBed,
  ) {
    var id = 1;
    return {
      for (final entry in cropsByBed.entries)
        entry.key: [
          for (var index = 0; index < entry.value.length; index++)
            GardenPlant(
              id: id++,
              bed: entry.key,
              crop: entry.value[index],
              position: defaultPlantPosition(index),
            ),
        ],
    };
  }

  Map<int, List<GardenPlant>> _restoreGardenPlants(
    List<StoredGardenPlant> storedPlants,
  ) {
    final cropsById = {for (final crop in vegetableLibrary) crop.id: crop};
    final plants = <int, List<GardenPlant>>{};
    for (final plant in storedPlants) {
      final crop = cropsById[plant.cropId];
      if (crop == null) continue;
      plants.putIfAbsent(plant.bed, () => []).add(
            GardenPlant(
              id: plant.id,
              bed: plant.bed,
              crop: crop,
              position: _boundedPlantPosition(Offset(plant.x, plant.y)),
            ),
          );
    }
    return plants;
  }

  void _addPlantCrops(
    Map<int, List<VegetableDefinition>> cropsByBed,
    Map<int, List<GardenPlant>> plantsByBed,
  ) {
    for (final entry in plantsByBed.entries) {
      final crops = [...cropsByBed[entry.key] ?? <VegetableDefinition>[]];
      for (final plant in entry.value) {
        if (!crops.any((crop) => crop.id == plant.crop.id)) {
          crops.add(plant.crop);
        }
      }
      if (crops.isNotEmpty) cropsByBed[entry.key] = crops;
    }
  }

  int _nextGardenPlantId(Map<int, List<GardenPlant>> plantsByBed) {
    var next = 1;
    for (final plants in plantsByBed.values) {
      for (final plant in plants) {
        if (plant.id >= next) next = plant.id + 1;
      }
    }
    return next;
  }

  List<GardenBed> _restoreGardenLayout(List<StoredGardenBed> beds) => beds
      .map(
        (bed) => GardenBed(
          bed.number,
          Rect.fromLTWH(bed.left, bed.top, bed.width, bed.height),
          name: bed.name,
          widthMeters: bed.widthMeters > 0 ? bed.widthMeters : null,
          lengthMeters: bed.lengthMeters > 0 ? bed.lengthMeters : null,
        ),
      )
      .where((bed) => bed.rect.width > 0 && bed.rect.height > 0)
      .toList(growable: false);

  int _nextRecordId(GardenSnapshot snapshot, List<SprayRecord> records) {
    final nextFromRecords = records.fold(
      1,
      (next, record) => record.id >= next ? record.id + 1 : next,
    );
    return snapshot.nextRecordId > nextFromRecords
        ? snapshot.nextRecordId
        : nextFromRecords;
  }

  SprayRecord _recordFromStorage(StoredSprayRecord record) => SprayRecord(
        id: record.id,
        beds: record.beds,
        crops: record.crops.isEmpty ? const ['Whole bed'] : record.crops,
        cropProfiles: const {},
        targetId: record.targetId,
        product: record.product,
        productId: record.productId,
        reason: record.reason,
        notes: record.notes,
        date: record.date,
        days: record.days,
      );

  Future<void> _restoreHarvestReminders(List<SprayRecord> savedRecords) async {
    for (final record in savedRecords) {
      await _scheduleHarvestReminder(record);
    }
  }

  Future<void> _loadProducts() async {
    try {
      final loaded = await AcvmProductRepository.instance.getAll();
      if (!mounted) return;
      setState(() {
        products = loaded;
        productsLoading = false;
        message = 'Loaded ${loaded.length} NZ spray products';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        products = fallbackProducts();
        productsLoading = false;
        message = 'Using fallback products - asset failed to load';
      });
    }
  }

  void addCrop(int bed, VegetableDefinition crop) {
    final next = [...bedCrops[bed] ?? <VegetableDefinition>[]];
    if (!next.any((item) => item.id == crop.id)) next.add(crop);
    setState(() {
      bedCrops[bed] = next;
      selectedBed = bed;
      message = '${crop.name} added to Bed $bed';
    });
    unawaited(_saveGarden());
  }

  void removeCrop(int bed, VegetableDefinition crop) {
    final next = [...bedCrops[bed] ?? <VegetableDefinition>[]]
      ..removeWhere((item) => item.id == crop.id);
    final nextPlants = [...bedPlants[bed] ?? <GardenPlant>[]]
      ..removeWhere((plant) => plant.crop.id == crop.id);
    setState(() {
      if (next.isEmpty) {
        bedCrops.remove(bed);
      } else {
        bedCrops[bed] = next;
      }
      if (nextPlants.isEmpty) {
        bedPlants.remove(bed);
      } else {
        bedPlants[bed] = nextPlants;
      }
      message = '${crop.name} removed from Bed $bed';
    });
    unawaited(_saveGarden());
  }

  GardenPlant addGardenPlant(
    int bed,
    VegetableDefinition crop,
    Offset position,
  ) =>
      addGardenPlants(bed, crop, [position]).single;

  List<GardenPlant> addGardenPlants(
    int bed,
    VegetableDefinition crop,
    List<Offset> positions,
  ) {
    if (positions.isEmpty) return const [];
    final plants = [
      for (var index = 0; index < positions.length; index++)
        GardenPlant(
          id: nextPlantId + index,
          bed: bed,
          crop: crop,
          position: _boundedPlantPosition(positions[index]),
        ),
    ];
    final nextCrops = [...bedCrops[bed] ?? <VegetableDefinition>[]];
    if (!nextCrops.any((item) => item.id == crop.id)) nextCrops.add(crop);
    setState(() {
      nextPlantId += plants.length;
      bedPlants[bed] = [...bedPlants[bed] ?? <GardenPlant>[], ...plants];
      bedCrops[bed] = nextCrops;
      selectedBed = bed;
      message = plants.length == 1
          ? '${crop.name} planted in Bed $bed'
          : '${plants.length} ${crop.name} plants added to Bed $bed';
    });
    unawaited(_saveGarden());
    return plants;
  }

  void removeGardenPlant(int bed, int plantId) {
    final plants = bedPlants[bed] ?? const <GardenPlant>[];
    GardenPlant? removed;
    for (final plant in plants) {
      if (plant.id == plantId) {
        removed = plant;
        break;
      }
    }
    if (removed == null) return;
    final removedPlant = removed;
    final nextPlants = plants.where((plant) => plant.id != plantId).toList();
    final cropStillPlanted =
        nextPlants.any((plant) => plant.crop.id == removedPlant.crop.id);
    final nextCrops = [...bedCrops[bed] ?? <VegetableDefinition>[]];
    if (!cropStillPlanted) {
      nextCrops.removeWhere((crop) => crop.id == removedPlant.crop.id);
    }
    setState(() {
      if (nextPlants.isEmpty) {
        bedPlants.remove(bed);
      } else {
        bedPlants[bed] = nextPlants;
      }
      if (nextCrops.isEmpty) {
        bedCrops.remove(bed);
      } else {
        bedCrops[bed] = nextCrops;
      }
      message = '${removedPlant.crop.name} removed from Bed $bed';
    });
    unawaited(_saveGarden());
  }

  void addGardenBed() {
    final number = gardenLayout.fold(
          0,
          (largest, bed) => bed.number > largest ? bed.number : largest,
        ) +
        1;
    final offset = ((number - 1) % 5) * .045;
    final bed = GardenBed(
      number,
      Rect.fromLTWH(
        .10 + offset,
        .12 + offset,
        1 / gardenPlot.widthMeters,
        2 / gardenPlot.lengthMeters,
      ),
      widthMeters: 1,
      lengthMeters: 2,
    ).sizeToMeters(1, 2, plot: gardenPlot);
    setState(() {
      gardenLayout = [...gardenLayout, bed];
      selectedBed = bed.number;
      message = '${bed.label} added';
    });
    unawaited(_saveGarden());
  }

  void renameGardenBed(int bedNumber, String name) {
    final current = _bedByNumber(bedNumber);
    _updateGardenBed(
      bedNumber,
      (bed) => bed.copyWith(name: name.trim()),
      '${current.label} renamed',
    );
  }

  void moveGardenBed(int bedNumber, Offset delta) {
    _updateGardenBed(bedNumber, (bed) => bed.move(delta));
  }

  void resizeGardenBed(int bedNumber, Offset delta) {
    _updateGardenBed(bedNumber, (bed) => bed.resize(delta, plot: gardenPlot));
  }

  void sizeGardenBed(int bedNumber, double widthMeters, double lengthMeters) {
    _updateGardenBed(
      bedNumber,
      (bed) => bed.sizeToMeters(widthMeters, lengthMeters, plot: gardenPlot),
      'Bed size updated',
    );
  }

  void rotateGardenBed(int bedNumber) {
    _updateGardenBed(
      bedNumber,
      (bed) => bed.rotate(plot: gardenPlot),
      'Bed rotated',
    );
  }

  void duplicateGardenBed(int bedNumber) {
    final source = _bedByNumber(bedNumber);
    final number = gardenLayout.fold(
          0,
          (largest, bed) => bed.number > largest ? bed.number : largest,
        ) +
        1;
    final copy = GardenBed(
      number,
      source.rect,
      name: source.name.isEmpty ? '' : '${source.name} copy',
      widthMeters: source.widthMeters,
      lengthMeters: source.lengthMeters,
    ).move(const Offset(.04, .04));
    setState(() {
      gardenLayout = [...gardenLayout, copy];
      selectedBed = copy.number;
      message = '${copy.label} added';
    });
    unawaited(_saveGarden());
  }

  void sizeGardenPlot(double widthMeters, double lengthMeters) {
    final nextPlot = GardenPlot(
      widthMeters: widthMeters,
      lengthMeters: lengthMeters,
    );
    setState(() {
      gardenPlot = nextPlot;
      gardenLayout = [
        for (final bed in gardenLayout)
          bed.sizeToMeters(bed.widthMeters, bed.lengthMeters, plot: nextPlot),
      ];
      message = 'Garden plot size updated';
    });
    unawaited(_saveGarden());
  }

  void removeGardenBed(int bedNumber) {
    if (gardenLayout.length <= 1) return;
    setState(() {
      gardenLayout =
          gardenLayout.where((bed) => bed.number != bedNumber).toList();
      bedCrops.remove(bedNumber);
      bedPlants.remove(bedNumber);
      selectedBed = gardenLayout.first.number;
      message = 'Bed removed';
    });
    unawaited(_saveGarden());
  }

  void resetGardenLayout() {
    setState(() {
      gardenLayout = [...defaultGardenBeds];
      selectedBed = gardenLayout.first.number;
      message = 'Garden layout reset';
    });
    unawaited(_saveGarden());
  }

  GardenBed _bedByNumber(int number) => gardenLayout.firstWhere(
        (bed) => bed.number == number,
        orElse: () => gardenLayout.first,
      );

  void _updateGardenBed(
    int bedNumber,
    GardenBed Function(GardenBed bed) update, [
    String? nextMessage,
  ]) {
    setState(() {
      gardenLayout = [
        for (final bed in gardenLayout)
          if (bed.number == bedNumber) update(bed) else bed,
      ];
      if (nextMessage != null) {
        message = nextMessage;
      }
    });
    unawaited(_saveGarden());
  }

  void saveSpray({
    required Set<int> beds,
    required Set<String> crops,
    required Map<String, OpenFarmCrop> cropProfiles,
    required String targetId,
    required SprayProduct product,
    required String reason,
    required String notes,
    required int days,
  }) {
    if (beds.isEmpty) return;
    final sortedBeds = beds.toList()..sort();
    final sortedCrops = crops.toList()..sort();
    final record = SprayRecord(
      id: nextRecordId,
      beds: sortedBeds,
      crops: sortedCrops.isEmpty ? ['Whole bed'] : sortedCrops,
      cropProfiles: Map.unmodifiable(cropProfiles),
      targetId: targetId,
      product: product.name,
      productId: product.id,
      reason: reason.trim(),
      notes: notes.trim(),
      date: DateTime.now(),
      days: days,
    );
    setState(() {
      nextRecordId++;
      records.insert(0, record);
      selectedBed = sortedBeds.first;
      message = 'Spray record saved';
      tab = 0;
    });
    unawaited(_saveGarden());
    unawaited(_scheduleHarvestReminder(record));
  }

  Future<void> _scheduleHarvestReminder(SprayRecord record) async {
    if (record.days <= 0) return;

    try {
      await HarvestReminderService.instance.schedule(
        HarvestReminder(
          id: record.id,
          safeAt: record.safeDate,
          beds: record.beds,
          crops: record.crops,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        message = 'Spray record saved. Harvest reminder was not scheduled.';
      });
    }
  }

  void deleteRecord(int id) {
    unawaited(HarvestReminderService.instance.cancel(id));
    setState(() {
      records = records.where((record) => record.id != id).toList();
      message = 'Record removed';
    });
    unawaited(_saveGarden());
  }

  Future<void> _saveGarden() async {
    try {
      await LocalGardenRepository.instance.save(
        GardenSnapshot(
          nextRecordId: nextRecordId,
          bedCropIds: {
            for (final entry in bedCrops.entries)
              entry.key: entry.value.map((crop) => crop.id).toList(),
          },
          records: records.map(_recordToStorage).toList(growable: false),
          beds: gardenLayout.map(_bedToStorage).toList(growable: false),
          plants: bedPlants.values
              .expand((plants) => plants)
              .map(_plantToStorage)
              .toList(growable: false),
          plotWidthMeters: gardenPlot.widthMeters,
          plotLengthMeters: gardenPlot.lengthMeters,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        message = 'Garden change saved for now, but local storage failed';
      });
    }
  }

  StoredSprayRecord _recordToStorage(SprayRecord record) => StoredSprayRecord(
        id: record.id,
        beds: record.beds,
        crops: record.crops,
        targetId: record.targetId,
        product: record.product,
        productId: record.productId,
        reason: record.reason,
        notes: record.notes,
        date: record.date,
        days: record.days,
      );

  StoredGardenBed _bedToStorage(GardenBed bed) => StoredGardenBed(
        number: bed.number,
        name: bed.name,
        left: bed.rect.left,
        top: bed.rect.top,
        width: bed.rect.width,
        height: bed.rect.height,
        widthMeters: bed.widthMeters,
        lengthMeters: bed.lengthMeters,
      );

  StoredGardenPlant _plantToStorage(GardenPlant plant) => StoredGardenPlant(
        id: plant.id,
        bed: plant.bed,
        cropId: plant.crop.id,
        x: plant.position.dx,
        y: plant.position.dy,
      );

  bool bedOnHold(int bed) =>
      records.any((record) => record.beds.contains(bed) && record.onHold);

  int get clearBeds =>
      gardenLayout.where((bed) => !bedOnHold(bed.number)).length;
  int get holdBeds => gardenLayout.length - clearBeds;
  int get plantedBeds =>
      bedCrops.values.where((items) => items.isNotEmpty).length;
  int get cropPlacements =>
      bedCrops.values.fold(0, (sum, list) => sum + list.length);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        clearBeds: clearBeds,
        holdBeds: holdBeds,
        plantedBeds: plantedBeds,
        cropPlacements: cropPlacements,
        records: records,
        products: products,
        message: message,
        sprayConditions: sprayConditions,
        gardenRisks: gardenRisks,
        onPlanSpray: () => setState(() => tab = 2),
        onOpenProducts: () => setState(() => tab = 4),
      ),
      GardenScreen(
        selectedBed: selectedBed,
        plot: gardenPlot,
        gardenBeds: gardenLayout,
        bedCrops: bedCrops,
        bedPlants: bedPlants,
        records: records,
        products: products,
        gardenRisks: gardenRisks,
        isHold: bedOnHold,
        message: message,
        onSelectBed: (bed) => setState(() => selectedBed = bed),
        onAddCrop: addCrop,
        onRemoveCrop: removeCrop,
        onAddPlant: addGardenPlant,
        onAddPlants: addGardenPlants,
        onRemovePlant: removeGardenPlant,
        onAddBed: addGardenBed,
        onRenameBed: renameGardenBed,
        onMoveBed: moveGardenBed,
        onResizeBed: resizeGardenBed,
        onSizeBed: sizeGardenBed,
        onRotateBed: rotateGardenBed,
        onDuplicateBed: duplicateGardenBed,
        onSizePlot: sizeGardenPlot,
        onRemoveBed: removeGardenBed,
        onResetLayout: resetGardenLayout,
        onStartSpray: () => setState(() => tab = 2),
      ),
      SprayLogScreen(
        key: ValueKey('${products.length}-${records.length}'),
        initialBeds: {selectedBed},
        gardenBeds: gardenLayout,
        bedCrops: bedCrops,
        products: products,
        productsLoading: productsLoading,
        sprayConditions: sprayConditions,
        onSave: saveSpray,
      ),
      RecordsScreen(records: records, message: message, onDelete: deleteRecord),
      ProductsScreen(
        products: products,
        loading: productsLoading,
        message: message,
      ),
    ];

    return CupertinoPageScaffold(
      backgroundColor: C.canvas,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(index: tab, children: pages),
            ),
            BottomNav(tab: tab, onTap: (value) => setState(() => tab = value)),
          ],
        ),
      ),
    );
  }
}
