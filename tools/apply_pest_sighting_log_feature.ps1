Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "`n== Spray Tracker: Pest Sighting Log feature patch =="

if (!(Test-Path ".\pubspec.yaml")) {
  throw "Run this from the spray-tracker repo root."
}

$files = @(
  ".\lib\models\garden_snapshot.dart",
  ".\lib\features\home\presentation\home_controller.dart",
  ".\lib\features\home\presentation\home_screen.dart",
  ".\lib\features\spray\domain\spray_records.dart",
  ".\lib\features\spray\presentation\pages\spray_screens.dart"
)

Write-Host "`n== Backup files =="
foreach ($file in $files) {
  Copy-Item $file "$file.before-pest-sightings.bak" -Force
}

$py = @'
from pathlib import Path


def replace_once(text, old, new, label):
    if old not in text:
        raise SystemExit(f"Missing patch target: {label}")
    return text.replace(old, new, 1)


def add_once(text, marker, insert, label):
    if insert.strip() in text:
        return text
    if marker not in text:
        raise SystemExit(f"Missing insert marker: {label}")
    return text.replace(marker, insert + marker, 1)

# ---------------------------------------------------------------------------
# spray_records.dart: runtime PestSighting model
# ---------------------------------------------------------------------------
path = Path('lib/features/spray/domain/spray_records.dart')
text = path.read_text(encoding='utf-8')
insert = r'''
enum PestSeverity { low, medium, high }

String pestSeverityLabel(PestSeverity severity) => switch (severity) {
      PestSeverity.low => 'Low',
      PestSeverity.medium => 'Medium',
      PestSeverity.high => 'High',
    };

class PestSighting {
  const PestSighting({
    required this.id,
    required this.bed,
    required this.cropName,
    required this.issueName,
    required this.severity,
    required this.actionTaken,
    required this.date,
    required this.recheckDate,
    required this.notes,
  });

  final int id;
  final int bed;
  final String cropName;
  final String issueName;
  final PestSeverity severity;
  final String actionTaken;
  final DateTime date;
  final DateTime recheckDate;
  final String notes;

  bool get recheckDue => !recheckDate.isAfter(DateTime.now());
}

'''
text = add_once(text, 'enum BedSprayState { neverSprayed, clear, hold }', insert, 'PestSighting model')
path.write_text(text, encoding='utf-8')

# ---------------------------------------------------------------------------
# garden_snapshot.dart: persist pest sightings in backup/local storage
# ---------------------------------------------------------------------------
path = Path('lib/models/garden_snapshot.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(text,
"""    this.beds = const [],
    this.plants = const [],
    this.plotWidthMeters = 8,
    this.plotLengthMeters = 12,
  });
""",
"""    this.beds = const [],
    this.plants = const [],
    this.pestSightings = const [],
    this.plotWidthMeters = 8,
    this.plotLengthMeters = 12,
  });
""", 'GardenSnapshot constructor')
text = replace_once(text,
"""  final List<StoredGardenBed> beds;
  final List<StoredGardenPlant> plants;
  final double plotWidthMeters;
""",
"""  final List<StoredGardenBed> beds;
  final List<StoredGardenPlant> plants;
  final List<StoredPestSighting> pestSightings;
  final double plotWidthMeters;
""", 'GardenSnapshot fields')
text = replace_once(text,
"""    final bedJson = json['beds'];
    final plantJson = json['plants'];
    return GardenSnapshot(
""",
"""    final bedJson = json['beds'];
    final plantJson = json['plants'];
    final pestSightingJson = json['pestSightings'];
    return GardenSnapshot(
""", 'fromJson pest json')
text = replace_once(text,
"""      plants: plantJson is List
          ? plantJson
              .whereType<Map>()
              .map((item) => StoredGardenPlant.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((plant) => plant.id > 0 && plant.bed > 0)
              .toList(growable: false)
          : const [],
    );
""",
"""      plants: plantJson is List
          ? plantJson
              .whereType<Map>()
              .map((item) => StoredGardenPlant.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((plant) => plant.id > 0 && plant.bed > 0)
              .toList(growable: false)
          : const [],
      pestSightings: pestSightingJson is List
          ? pestSightingJson
              .whereType<Map>()
              .map((item) => StoredPestSighting.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((sighting) => sighting.id > 0 && sighting.bed > 0)
              .toList(growable: false)
          : const [],
    );
""", 'fromJson pest sightings')
text = replace_once(text,
"""        'records': records.map((record) => record.toJson()).toList(),
        'beds': beds.map((bed) => bed.toJson()).toList(),
        'plants': plants.map((plant) => plant.toJson()).toList(),
      };
}
""",
"""        'records': records.map((record) => record.toJson()).toList(),
        'beds': beds.map((bed) => bed.toJson()).toList(),
        'plants': plants.map((plant) => plant.toJson()).toList(),
        'pestSightings': pestSightings.map((sighting) => sighting.toJson()).toList(),
      };
}
""", 'toJson pest sightings')
insert = r'''
class StoredPestSighting {
  const StoredPestSighting({
    required this.id,
    required this.bed,
    required this.cropName,
    required this.issueName,
    required this.severity,
    required this.actionTaken,
    required this.date,
    required this.recheckDate,
    required this.notes,
  });

  final int id;
  final int bed;
  final String cropName;
  final String issueName;
  final String severity;
  final String actionTaken;
  final DateTime date;
  final DateTime recheckDate;
  final String notes;

  factory StoredPestSighting.fromJson(Map<String, dynamic> json) =>
      StoredPestSighting(
        id: _int(json['id']),
        bed: _int(json['bed']),
        cropName: _string(json['cropName']),
        issueName: _string(json['issueName']),
        severity: _string(json['severity']),
        actionTaken: _string(json['actionTaken']),
        date: DateTime.tryParse(_string(json['date'])) ?? DateTime(1970),
        recheckDate:
            DateTime.tryParse(_string(json['recheckDate'])) ?? DateTime(1970),
        notes: _string(json['notes']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bed': bed,
        'cropName': cropName,
        'issueName': issueName,
        'severity': severity,
        'actionTaken': actionTaken,
        'date': date.toIso8601String(),
        'recheckDate': recheckDate.toIso8601String(),
        'notes': notes,
      };
}

'''
text = add_once(text, 'String _string(Object? value)', insert, 'StoredPestSighting class')
path.write_text(text, encoding='utf-8')

# ---------------------------------------------------------------------------
# home_controller.dart: state, saving/restoring, callback wiring
# ---------------------------------------------------------------------------
path = Path('lib/features/home/presentation/home_controller.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(text,
"""  int nextRecordId = 1;
  int nextPlantId = 1;
""",
"""  int nextRecordId = 1;
  int nextPlantId = 1;
  int nextPestSightingId = 1;
""", 'nextPestSightingId')
text = replace_once(text,
"""  List<GardenBed> gardenLayout = [...defaultGardenBeds];
  List<SprayRecord> records = [];
""",
"""  List<GardenBed> gardenLayout = [...defaultGardenBeds];
  List<SprayRecord> records = [];
  List<PestSighting> pestSightings = [];
""", 'pestSightings state')
text = replace_once(text,
"""    final restoredRecords =
        snapshot.records.map(_recordFromStorage).toList(growable: false);
    final restoredLayout = _restoreGardenLayout(snapshot.beds);
""",
"""    final restoredRecords =
        snapshot.records.map(_recordFromStorage).toList(growable: false);
    final restoredPestSightings = snapshot.pestSightings
        .map(_pestSightingFromStorage)
        .toList(growable: false);
    final restoredLayout = _restoreGardenLayout(snapshot.beds);
""", 'restore pest sightings')
text = replace_once(text,
"""      records = restoredRecords;
      nextRecordId = _nextRecordId(snapshot, restoredRecords);
      nextPlantId = _nextGardenPlantId(restoredPlants);
""",
"""      records = restoredRecords;
      pestSightings = restoredPestSightings;
      nextRecordId = _nextRecordId(snapshot, restoredRecords);
      nextPlantId = _nextGardenPlantId(restoredPlants);
      nextPestSightingId = _nextPestSightingId(restoredPestSightings);
""", 'set pest sightings')
insert = r'''
  int _nextPestSightingId(List<PestSighting> sightings) {
    var next = 1;
    for (final sighting in sightings) {
      if (sighting.id >= next) next = sighting.id + 1;
    }
    return next;
  }

'''
text = add_once(text, '  SprayRecord _recordFromStorage(StoredSprayRecord record) =>', insert, 'next pest sighting id method')
insert = r'''
  PestSighting _pestSightingFromStorage(StoredPestSighting sighting) =>
      PestSighting(
        id: sighting.id,
        bed: sighting.bed,
        cropName: sighting.cropName,
        issueName: sighting.issueName,
        severity: _pestSeverityFromStorage(sighting.severity),
        actionTaken: sighting.actionTaken,
        date: sighting.date,
        recheckDate: sighting.recheckDate,
        notes: sighting.notes,
      );

  PestSeverity _pestSeverityFromStorage(String value) =>
      PestSeverity.values.firstWhere(
        (severity) => severity.name == value,
        orElse: () => PestSeverity.medium,
      );

'''
text = add_once(text, '  Future<void> _restoreHarvestReminders', insert, 'pest sighting from storage')
insert = r'''
  void savePestSighting({
    required int bed,
    required String cropName,
    required String issueName,
    required PestSeverity severity,
    required String actionTaken,
    required DateTime recheckDate,
    required String notes,
  }) {
    final sighting = PestSighting(
      id: nextPestSightingId,
      bed: bed,
      cropName: cropName,
      issueName: issueName,
      severity: severity,
      actionTaken: actionTaken,
      date: DateTime.now(),
      recheckDate: recheckDate,
      notes: notes.trim(),
    );
    setState(() {
      nextPestSightingId++;
      pestSightings.insert(0, sighting);
      selectedBed = bed;
      message = 'Pest sighting saved';
      tab = 0;
    });
    unawaited(_saveGarden());
  }

'''
text = add_once(text, '  Future<void> _scheduleHarvestReminder', insert, 'save pest sighting method')
text = replace_once(text,
"""        records: records.map(_recordToStorage).toList(growable: false),
        beds: gardenLayout.map(_bedToStorage).toList(growable: false),
""",
"""        records: records.map(_recordToStorage).toList(growable: false),
        pestSightings:
            pestSightings.map(_pestSightingToStorage).toList(growable: false),
        beds: gardenLayout.map(_bedToStorage).toList(growable: false),
""", 'snapshot pest sightings')
insert = r'''
  StoredPestSighting _pestSightingToStorage(PestSighting sighting) =>
      StoredPestSighting(
        id: sighting.id,
        bed: sighting.bed,
        cropName: sighting.cropName,
        issueName: sighting.issueName,
        severity: sighting.severity.name,
        actionTaken: sighting.actionTaken,
        date: sighting.date,
        recheckDate: sighting.recheckDate,
        notes: sighting.notes,
      );

'''
text = add_once(text, '  StoredGardenBed _bedToStorage', insert, 'pest sighting to storage')
text = replace_once(text,
"""        records: records,
        products: products,
""",
"""        records: records,
        pestSightings: pestSightings,
        products: products,
""", 'HomeScreen pest sightings prop')
text = replace_once(text,
"""        records: records,
        products: products,
        productsLoading: productsLoading,
        sprayConditions: sprayConditions,
        onSave: saveSpray,
""",
"""        records: records,
        pestSightings: pestSightings,
        products: products,
        productsLoading: productsLoading,
        sprayConditions: sprayConditions,
        onSave: saveSpray,
        onSavePestSighting: savePestSighting,
""", 'SprayLogScreen pest sightings props')
path.write_text(text, encoding='utf-8')

# ---------------------------------------------------------------------------
# home_screen.dart: recent pest sightings
# ---------------------------------------------------------------------------
path = Path('lib/features/home/presentation/home_screen.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(text,
"""    required this.records,
    required this.products,
""",
"""    required this.records,
    required this.pestSightings,
    required this.products,
""", 'HomeScreen constructor pest sightings')
text = replace_once(text,
"""  final List<SprayRecord> records;
  final List<SprayProduct> products;
""",
"""  final List<SprayRecord> records;
  final List<PestSighting> pestSightings;
  final List<SprayProduct> products;
""", 'HomeScreen field pest sightings')
text = replace_once(text,
"""        const SizedBox(height: 18),
        const SectionTitle('Recent activity'),
""",
"""        const SizedBox(height: 18),
        const SectionTitle('Recent pest sightings'),
        const SizedBox(height: 8),
        if (pestSightings.isEmpty)
          const EmptyCard('No pest sightings logged yet.')
        else
          ...pestSightings.take(3).map(
                (sighting) => _PestSightingHomeCard(sighting: sighting),
              ),
        const SizedBox(height: 18),
        const SectionTitle('Recent activity'),
""", 'recent pest sightings section')
insert = r'''
class _PestSightingHomeCard extends StatelessWidget {
  const _PestSightingHomeCard({required this.sighting});

  final PestSighting sighting;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: cardDecoration(
          color: sighting.recheckDue ? C.amberSoft : C.card,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: C.redSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(CupertinoIcons.ant, color: C.red, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${sighting.issueName} | Bed ${sighting.bed}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: C.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${sighting.cropName} | ${pestSeverityLabel(sighting.severity)} severity',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: C.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Action: ${sighting.actionTaken} | recheck ${shortDate(sighting.recheckDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: C.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            StatusPill(sighting.recheckDue ? 'RECHECK' : 'WATCH', hold: sighting.recheckDue),
          ],
        ),
      );
}

'''
text = add_once(text, 'class _GardenBackupPanel extends StatelessWidget', insert, 'Pest sighting home card')
path.write_text(text, encoding='utf-8')

# ---------------------------------------------------------------------------
# spray_screens.dart: add Pest Sighting Quick Form above existing spray flow
# ---------------------------------------------------------------------------
path = Path('lib/features/spray/presentation/pages/spray_screens.dart')
text = path.read_text(encoding='utf-8')
text = replace_once(text,
"""    required this.records,
    required this.products,
""",
"""    required this.records,
    required this.pestSightings,
    required this.products,
""", 'SprayLogScreen constructor pest sightings')
text = replace_once(text,
"""  final List<SprayRecord> records;
  final List<SprayProduct> products;
""",
"""  final List<SprayRecord> records;
  final List<PestSighting> pestSightings;
  final List<SprayProduct> products;
""", 'SprayLogScreen field pest sightings')
text = replace_once(text,
"""    required int days,
  }) onSave;
""",
"""    required int days,
  }) onSave;
  final void Function({
    required int bed,
    required String cropName,
    required String issueName,
    required PestSeverity severity,
    required String actionTaken,
    required DateTime recheckDate,
    required String notes,
  }) onSavePestSighting;
""", 'SprayLogScreen callback')
# Add quick form after weather banner. This avoids disrupting existing spray workflow.
text = replace_once(text,
"""        SprayConditionBanner(sprayConditions: widget.sprayConditions),
        const SizedBox(height: 18),
        const SectionTitle('Beds sprayed'),
""",
"""        SprayConditionBanner(sprayConditions: widget.sprayConditions),
        const SizedBox(height: 18),
        _PestSightingQuickForm(
          gardenBeds: widget.gardenBeds,
          bedCrops: widget.bedCrops,
          pestSightings: widget.pestSightings,
          onSave: widget.onSavePestSighting,
        ),
        const SizedBox(height: 18),
        const SectionTitle('Beds sprayed'),
""", 'pest sighting form placement')
insert = r'''
class _PestSightingQuickForm extends StatefulWidget {
  const _PestSightingQuickForm({
    required this.gardenBeds,
    required this.bedCrops,
    required this.pestSightings,
    required this.onSave,
  });

  final List<GardenBed> gardenBeds;
  final Map<int, List<VegetableDefinition>> bedCrops;
  final List<PestSighting> pestSightings;
  final void Function({
    required int bed,
    required String cropName,
    required String issueName,
    required PestSeverity severity,
    required String actionTaken,
    required DateTime recheckDate,
    required String notes,
  }) onSave;

  @override
  State<_PestSightingQuickForm> createState() => _PestSightingQuickFormState();
}

class _PestSightingQuickFormState extends State<_PestSightingQuickForm> {
  int? selectedBed;
  String? selectedCropName;
  String? selectedIssueName;
  PestSeverity severity = PestSeverity.medium;
  String actionTaken = 'Observed only';
  int recheckDays = 3;
  bool expanded = false;
  final notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedBed = widget.gardenBeds.isEmpty ? null : widget.gardenBeds.first.number;
  }

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  List<VegetableDefinition> get selectedCrops =>
      selectedBed == null ? const [] : widget.bedCrops[selectedBed] ?? const [];

  VegetableDefinition? get selectedCrop {
    for (final crop in selectedCrops) {
      if (crop.name == selectedCropName) return crop;
    }
    return selectedCrops.isEmpty ? null : selectedCrops.first;
  }

  List<String> get issueOptions {
    final crop = selectedCrop;
    if (crop == null) {
      return const [
        'Aphids',
        'Whitefly',
        'Thrips',
        'Mites',
        'Caterpillars',
        'Powdery mildew',
      ];
    }
    final values = <String>{...crop.commonPests, ...crop.commonDiseases};
    final result = values.where((value) => value.trim().isNotEmpty).toList()
      ..sort();
    return result;
  }

  List<String> get cropOptions => selectedCrops.map((crop) => crop.name).toList();

  @override
  Widget build(BuildContext context) {
    final bedOptions = widget.gardenBeds.map((bed) => '${bed.number}').toList();
    final crop = selectedCrop;
    final issue = selectedIssueName != null && issueOptions.contains(selectedIssueName)
        ? selectedIssueName!
        : issueOptions.first;
    final cropName = selectedCropName != null && cropOptions.contains(selectedCropName)
        ? selectedCropName!
        : crop?.name ?? '';

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionTitle('Log pest sighting'),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(36, 32),
                onPressed: () => setState(() => expanded = !expanded),
                child: Icon(
                  expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                  color: C.forest,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.pestSightings.isEmpty
                ? 'Record what you saw before deciding whether to spray.'
                : '${widget.pestSightings.length} sighting${widget.pestSightings.length == 1 ? '' : 's'} logged.',
            style: const TextStyle(
              color: C.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 12),
            _SprayDropdownCard(
              title: 'Bed',
              value: selectedBed == null ? 'Select bed' : 'Bed $selectedBed',
              icon: CupertinoIcons.square_grid_2x2,
              options: bedOptions,
              emptyText: 'No garden beds available.',
              onSelected: (value) => setState(() {
                selectedBed = int.tryParse(value);
                selectedCropName = null;
                selectedIssueName = null;
              }),
            ),
            const SizedBox(height: 8),
            _SprayDropdownCard(
              title: 'Crop',
              value: cropName.isEmpty ? 'Select crop' : cropName,
              icon: CupertinoIcons.leaf_arrow_circlepath,
              options: cropOptions,
              emptyText: 'No crops logged in this bed yet.',
              onSelected: (value) => setState(() {
                selectedCropName = value;
                selectedIssueName = null;
              }),
            ),
            const SizedBox(height: 8),
            _SprayDropdownCard(
              title: 'Pest or disease',
              value: issue,
              icon: CupertinoIcons.ant,
              options: issueOptions,
              emptyText: 'No issue choices available.',
              onSelected: (value) => setState(() => selectedIssueName = value),
            ),
            const SizedBox(height: 10),
            CupertinoSlidingSegmentedControl<PestSeverity>(
              groupValue: severity,
              children: const {
                PestSeverity.low: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Low'),
                ),
                PestSeverity.medium: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Medium'),
                ),
                PestSeverity.high: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('High'),
                ),
              },
              onValueChanged: (value) {
                if (value != null) setState(() => severity = value);
              },
            ),
            const SizedBox(height: 8),
            _SprayDropdownCard(
              title: 'Action taken',
              value: actionTaken,
              icon: CupertinoIcons.checkmark_circle,
              options: const [
                'Observed only',
                'Hosed pests off',
                'Hand removed pests',
                'Removed affected leaves',
                'Set trap / barrier',
                'Sprayed selected product',
              ],
              emptyText: 'No action choices available.',
              onSelected: (value) => setState(() => actionTaken = value),
            ),
            const SizedBox(height: 8),
            _SprayDropdownCard(
              title: 'Recheck',
              value: _recheckLabel(recheckDays),
              icon: CupertinoIcons.calendar_badge_clock,
              options: const ['Tomorrow', '2 days', '3 days', '1 week'],
              emptyText: 'No recheck choices available.',
              onSelected: (value) => setState(() => recheckDays = _recheckDays(value)),
            ),
            const SizedBox(height: 8),
            Field(controller: notes, placeholder: 'Notes optional', maxLines: 2),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Save pest sighting',
              onPressed: selectedBed == null || cropName.isEmpty
                  ? null
                  : () {
                      widget.onSave(
                        bed: selectedBed!,
                        cropName: cropName,
                        issueName: issue,
                        severity: severity,
                        actionTaken: actionTaken,
                        recheckDate: DateTime.now().add(Duration(days: recheckDays)),
                        notes: notes.text,
                      );
                      setState(() {
                        expanded = false;
                        notes.clear();
                      });
                    },
            ),
          ],
        ],
      ),
    );
  }

  String _recheckLabel(int days) => switch (days) {
        1 => 'Tomorrow',
        2 => '2 days',
        3 => '3 days',
        _ => '1 week',
      };

  int _recheckDays(String value) => switch (value) {
        'Tomorrow' => 1,
        '2 days' => 2,
        '3 days' => 3,
        _ => 7,
      };
}

'''
text = add_once(text, 'class ProductsScreen extends StatefulWidget', insert, 'Pest sighting quick form')
path.write_text(text, encoding='utf-8')

print('Pest Sighting Log feature patch applied.')
'@

Write-Host "`n== Apply Python patch =="
$py | python -

Write-Host "`n== Format changed Dart files =="
dart format $files

Write-Host "`n== Analyze =="
flutter analyze

Write-Host "`n== Build debug APK =="
flutter build apk --debug

Write-Host "`n== Commit and push =="
git add lib/models/garden_snapshot.dart `
  lib/features/home/presentation/home_controller.dart `
  lib/features/home/presentation/home_screen.dart `
  lib/features/spray/domain/spray_records.dart `
  lib/features/spray/presentation/pages/spray_screens.dart `
  tools/apply_pest_sighting_log_feature.ps1

git commit -m "Add pest sighting log with dropdown choices"
git push origin main

Write-Host "`n== Done =="
git status --short
