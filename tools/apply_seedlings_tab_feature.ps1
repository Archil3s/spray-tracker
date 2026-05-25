Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "`n== Spray Tracker: Seedlings tab feature patch =="

if (!(Test-Path ".\pubspec.yaml")) {
  throw "Run this from the spray-tracker repo root."
}

$files = @(
  ".\lib\main.dart",
  ".\lib\models\garden_snapshot.dart",
  ".\lib\features\home\presentation\home_controller.dart",
  ".\lib\common\widgets\shared_widgets.dart"
)

Write-Host "`n== Backup files =="
foreach ($file in $files) {
  Copy-Item $file "$file.before-seedlings-tab.bak" -Force
}

New-Item -ItemType Directory -Force .\lib\features\seedlings\domain | Out-Null
New-Item -ItemType Directory -Force .\lib\features\seedlings\presentation | Out-Null

Write-Host "`n== Create Seedling model and screen files =="
@'
part of '../../../main.dart';

enum SeedlingStatus {
  started,
  germinated,
  prickedOut,
  pottedUp,
  hardeningOff,
  readyToPlantOut,
  plantedOut,
  failed,
}

String seedlingStatusLabel(SeedlingStatus status) => switch (status) {
      SeedlingStatus.started => 'Started',
      SeedlingStatus.germinated => 'Germinated',
      SeedlingStatus.prickedOut => 'Pricked out',
      SeedlingStatus.pottedUp => 'Potted up',
      SeedlingStatus.hardeningOff => 'Hardening off',
      SeedlingStatus.readyToPlantOut => 'Ready to plant out',
      SeedlingStatus.plantedOut => 'Planted out',
      SeedlingStatus.failed => 'Failed',
    };

class SeedlingBatch {
  const SeedlingBatch({
    required this.id,
    required this.cropId,
    required this.cropName,
    required this.varietyName,
    required this.quantityStarted,
    required this.quantityAlive,
    required this.dateStarted,
    required this.location,
    required this.method,
    required this.status,
    required this.expectedGerminationDaysMin,
    required this.expectedGerminationDaysMax,
    required this.targetPlantOutDate,
    required this.notes,
    this.plantedOutBed,
    this.plantedOutDate,
  });

  final int id;
  final String cropId;
  final String cropName;
  final String varietyName;
  final int quantityStarted;
  final int quantityAlive;
  final DateTime dateStarted;
  final String location;
  final String method;
  final SeedlingStatus status;
  final int expectedGerminationDaysMin;
  final int expectedGerminationDaysMax;
  final DateTime targetPlantOutDate;
  final int? plantedOutBed;
  final DateTime? plantedOutDate;
  final String notes;

  DateTime get germinationStart =>
      dateStarted.add(Duration(days: expectedGerminationDaysMin));

  DateTime get germinationEnd =>
      dateStarted.add(Duration(days: expectedGerminationDaysMax));

  bool get active =>
      status != SeedlingStatus.plantedOut && status != SeedlingStatus.failed;

  SeedlingBatch copyWith({
    int? quantityAlive,
    SeedlingStatus? status,
    int? plantedOutBed,
    DateTime? plantedOutDate,
  }) =>
      SeedlingBatch(
        id: id,
        cropId: cropId,
        cropName: cropName,
        varietyName: varietyName,
        quantityStarted: quantityStarted,
        quantityAlive: quantityAlive ?? this.quantityAlive,
        dateStarted: dateStarted,
        location: location,
        method: method,
        status: status ?? this.status,
        expectedGerminationDaysMin: expectedGerminationDaysMin,
        expectedGerminationDaysMax: expectedGerminationDaysMax,
        targetPlantOutDate: targetPlantOutDate,
        plantedOutBed: plantedOutBed ?? this.plantedOutBed,
        plantedOutDate: plantedOutDate ?? this.plantedOutDate,
        notes: notes,
      );
}

({int min, int max}) seedlingGerminationWindowFor(VegetableDefinition crop) {
  final id = crop.id.toLowerCase();
  final family = crop.familyId.toLowerCase();
  if (const ['tomato', 'chilli', 'capsicum', 'eggplant'].contains(id)) {
    return (min: 7, max: 14);
  }
  if (const ['lettuce', 'spinach', 'rocket'].contains(id)) {
    return (min: 3, max: 7);
  }
  if (family == 'brassicas') return (min: 4, max: 10);
  if (family == 'cucurbits') return (min: 5, max: 10);
  if (family == 'herbs') return (min: 7, max: 21);
  return (min: 7, max: 14);
}

DateTime seedlingTargetPlantOutDate(DateTime started, VegetableDefinition crop) {
  final family = crop.familyId.toLowerCase();
  final id = crop.id.toLowerCase();
  final weeks = switch (family) {
    'leafy_greens' => 4,
    'brassicas' => 5,
    'cucurbits' => 3,
    'herbs' => 6,
    _ => const ['tomato', 'chilli', 'capsicum', 'eggplant'].contains(id) ? 8 : 6,
  };
  return started.add(Duration(days: weeks * 7));
}
'@ | Set-Content -Encoding utf8 .\lib\features\seedlings\domain\seedling_models.dart

@'
part of '../../../main.dart';

class SeedlingsScreen extends StatefulWidget {
  const SeedlingsScreen({
    required this.batches,
    required this.gardenBeds,
    required this.onAddBatch,
    required this.onUpdateStatus,
    required this.onPlantOut,
    required this.message,
    super.key,
  });

  final List<SeedlingBatch> batches;
  final List<GardenBed> gardenBeds;
  final void Function({
    required VegetableDefinition crop,
    required String varietyName,
    required int quantityStarted,
    required DateTime dateStarted,
    required String location,
    required String method,
    required String notes,
  }) onAddBatch;
  final void Function(int id, SeedlingStatus status) onUpdateStatus;
  final void Function(int id, int bed) onPlantOut;
  final String message;

  @override
  State<SeedlingsScreen> createState() => _SeedlingsScreenState();
}

class _SeedlingsScreenState extends State<SeedlingsScreen> {
  bool adding = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.batches.where((batch) => batch.active).toList();
    final readySoon = active.where(_seedlingReadySoon).toList();
    final finished = widget.batches.where((batch) => !batch.active).take(4);

    return AppPage(
      title: 'Seedlings',
      subtitle: 'Start trays, track germination, and move plants into beds.',
      message: widget.message,
      children: [
        SectionTitle(
          'Ready soon',
          trailing: ProductTag(
            label: '${readySoon.length}',
            color: readySoon.isEmpty ? C.muted : C.amber,
            background: readySoon.isEmpty ? C.greySoft : C.amberSoft,
          ),
        ),
        const SizedBox(height: 8),
        if (readySoon.isEmpty)
          const EmptyCard('No seedling batches need urgent action yet.')
        else
          ...readySoon.map(
            (batch) => SeedlingBatchCard(
              batch: batch,
              gardenBeds: widget.gardenBeds,
              onUpdateStatus: widget.onUpdateStatus,
              onPlantOut: widget.onPlantOut,
            ),
          ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: adding ? 'Close seedling form' : 'Add seedling batch',
          onPressed: () => setState(() => adding = !adding),
        ),
        if (adding) ...[
          const SizedBox(height: 12),
          _AddSeedlingBatchPanel(
            onSave: (args) {
              widget.onAddBatch(
                crop: args.crop,
                varietyName: args.varietyName,
                quantityStarted: args.quantityStarted,
                dateStarted: args.dateStarted,
                location: args.location,
                method: args.method,
                notes: args.notes,
              );
              setState(() => adding = false);
            },
          ),
        ],
        const SizedBox(height: 18),
        SectionTitle(
          'Active seedlings',
          trailing: ProductTag(
            label: '${active.length}',
            color: C.forest,
            background: C.forestSoft,
          ),
        ),
        const SizedBox(height: 8),
        if (active.isEmpty)
          const EmptyCard('No active seedlings yet. Add a batch to begin.')
        else
          ...active.map(
            (batch) => SeedlingBatchCard(
              batch: batch,
              gardenBeds: widget.gardenBeds,
              onUpdateStatus: widget.onUpdateStatus,
              onPlantOut: widget.onPlantOut,
            ),
          ),
        if (finished.isNotEmpty) ...[
          const SizedBox(height: 18),
          const SectionTitle('Finished batches'),
          const SizedBox(height: 8),
          ...finished.map(
            (batch) => SeedlingBatchCard(
              batch: batch,
              gardenBeds: widget.gardenBeds,
              onUpdateStatus: widget.onUpdateStatus,
              onPlantOut: widget.onPlantOut,
            ),
          ),
        ],
      ],
    );
  }

  bool _seedlingReadySoon(SeedlingBatch batch) {
    final now = DateTime.now();
    if (batch.status == SeedlingStatus.readyToPlantOut ||
        batch.status == SeedlingStatus.hardeningOff) {
      return true;
    }
    if (batch.status == SeedlingStatus.started &&
        !batch.germinationStart.isAfter(now.add(const Duration(days: 2)))) {
      return true;
    }
    return !batch.targetPlantOutDate.isAfter(now.add(const Duration(days: 7)));
  }
}

class SeedlingBatchCard extends StatelessWidget {
  const SeedlingBatchCard({
    required this.batch,
    required this.gardenBeds,
    required this.onUpdateStatus,
    required this.onPlantOut,
    super.key,
  });

  final SeedlingBatch batch;
  final List<GardenBed> gardenBeds;
  final void Function(int id, SeedlingStatus status) onUpdateStatus;
  final void Function(int id, int bed) onPlantOut;

  @override
  Widget build(BuildContext context) {
    final crop = vegetableLibrary.firstWhere(
      (item) => item.id == batch.cropId,
      orElse: () => vegetableLibrary.first,
    );
    final status = seedlingStatusLabel(batch.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: cardDecoration(
        color: batch.status == SeedlingStatus.failed ? C.redSoft : C.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CropIcon(crop.iconPath, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch.varietyName.isEmpty
                          ? batch.cropName
                          : '${batch.cropName} | ${batch.varietyName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: C.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${batch.quantityAlive}/${batch.quantityStarted} alive | ${batch.method} | ${batch.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: C.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(status.toUpperCase(), hold: batch.status == SeedlingStatus.failed),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              ProductTag(
                label: 'Started ${shortDate(batch.dateStarted)}',
                color: C.forest,
                background: C.forestSoft,
              ),
              ProductTag(
                label:
                    'Germ ${shortDate(batch.germinationStart)}-${shortDate(batch.germinationEnd)}',
                color: C.blue,
                background: C.blueSoft,
              ),
              ProductTag(
                label: 'Plant out ${shortDate(batch.targetPlantOutDate)}',
                color: C.amber,
                background: C.amberSoft,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _seedlingNextAction(batch),
            style: const TextStyle(
              color: C.ink,
              height: 1.25,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Update status',
                  onPressed: () => _showStatusSheet(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PrimaryButton(
                  label: 'Plant into bed',
                  onPressed: batch.active && gardenBeds.isNotEmpty
                      ? () => _showPlantOutSheet(context)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _seedlingNextAction(SeedlingBatch batch) {
    final now = DateTime.now();
    return switch (batch.status) {
      SeedlingStatus.started => now.isBefore(batch.germinationStart)
          ? 'Next: keep evenly moist and check germination from ${shortDate(batch.germinationStart)}.'
          : 'Next: check for germination and update status when seedlings emerge.',
      SeedlingStatus.germinated => 'Next: watch for true leaves, then prick out or pot up.',
      SeedlingStatus.prickedOut => 'Next: keep sheltered while roots recover.',
      SeedlingStatus.pottedUp => 'Next: feed lightly and prepare for hardening off.',
      SeedlingStatus.hardeningOff => 'Next: increase outdoor time, then plant out when sturdy.',
      SeedlingStatus.readyToPlantOut => 'Next: choose a bed and plant out.',
      SeedlingStatus.plantedOut => batch.plantedOutBed == null
          ? 'Planted out.'
          : 'Planted into Bed ${batch.plantedOutBed} on ${shortDate(batch.plantedOutDate ?? now)}.',
      SeedlingStatus.failed => 'Batch marked failed. Start a replacement batch if needed.',
    };
  }

  void _showStatusSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Update seedling status'),
        message: Text(batch.cropName),
        actions: [
          for (final status in SeedlingStatus.values)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                onUpdateStatus(batch.id, status);
              },
              child: Text(seedlingStatusLabel(status)),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showPlantOutSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Plant into bed'),
        message: Text(batch.cropName),
        actions: [
          for (final bed in gardenBeds)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                onPlantOut(batch.id, bed.number);
              },
              child: Text(bed.label),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

class _AddSeedlingBatchPanel extends StatefulWidget {
  const _AddSeedlingBatchPanel({required this.onSave});

  final ValueChanged<_SeedlingFormResult> onSave;

  @override
  State<_AddSeedlingBatchPanel> createState() => _AddSeedlingBatchPanelState();
}

class _AddSeedlingBatchPanelState extends State<_AddSeedlingBatchPanel> {
  VegetableDefinition crop = vegetableLibrary.first;
  String varietyName = '';
  String method = 'Tray';
  String location = 'Windowsill';
  int quantity = 12;
  int startOffsetDays = 0;
  final notes = TextEditingController();

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final varieties = crop.varieties.map((item) => item.name).toList();
    final dateStarted = DateTime.now().subtract(Duration(days: startOffsetDays));
    final germination = seedlingGerminationWindowFor(crop);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('New seedling batch'),
          const SizedBox(height: 10),
          _SeedlingPickerCard(
            title: 'Crop',
            value: crop.name,
            icon: CupertinoIcons.leaf_arrow_circlepath,
            options: vegetableLibrary.map((item) => item.name).toList(),
            onSelected: (value) => setState(() {
              crop = vegetableLibrary.firstWhere((item) => item.name == value);
              varietyName = '';
            }),
          ),
          const SizedBox(height: 8),
          _SeedlingPickerCard(
            title: 'Variety',
            value: varietyName.isEmpty ? 'No variety selected' : varietyName,
            icon: CupertinoIcons.tag,
            options: varieties.isEmpty ? const ['No variety selected'] : ['No variety selected', ...varieties],
            onSelected: (value) => setState(() {
              varietyName = value == 'No variety selected' ? '' : value;
            }),
          ),
          const SizedBox(height: 8),
          _SeedlingPickerCard(
            title: 'Method',
            value: method,
            icon: CupertinoIcons.tray,
            options: const ['Tray', 'Pot', 'Cell tray', 'Paper towel', 'Direct sow'],
            onSelected: (value) => setState(() => method = value),
          ),
          const SizedBox(height: 8),
          _SeedlingPickerCard(
            title: 'Location',
            value: location,
            icon: CupertinoIcons.house,
            options: const ['Indoors', 'Greenhouse', 'Windowsill', 'Heat mat', 'Outside'],
            onSelected: (value) => setState(() => location = value),
          ),
          const SizedBox(height: 8),
          _SeedlingPickerCard(
            title: 'Date started',
            value: _startDateLabel(startOffsetDays),
            icon: CupertinoIcons.calendar,
            options: const ['Today', 'Yesterday', '3 days ago', '1 week ago'],
            onSelected: (value) => setState(() => startOffsetDays = _startOffset(value)),
          ),
          const SizedBox(height: 8),
          Stepper(
            label: 'Quantity started',
            value: quantity,
            minus: quantity > 1 ? () => setState(() => quantity--) : null,
            plus: () => setState(() => quantity++),
          ),
          const SizedBox(height: 8),
          ProductTag(
            label: 'Expected germination ${germination.min}-${germination.max} days',
            color: C.blue,
            background: C.blueSoft,
          ),
          const SizedBox(height: 8),
          Field(controller: notes, placeholder: 'Notes optional', maxLines: 2),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Save seedling batch',
            onPressed: () => widget.onSave(
              _SeedlingFormResult(
                crop: crop,
                varietyName: varietyName,
                quantityStarted: quantity,
                dateStarted: dateStarted,
                location: location,
                method: method,
                notes: notes.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _startDateLabel(int offset) => switch (offset) {
        0 => 'Today',
        1 => 'Yesterday',
        3 => '3 days ago',
        _ => '1 week ago',
      };

  int _startOffset(String value) => switch (value) {
        'Today' => 0,
        'Yesterday' => 1,
        '3 days ago' => 3,
        _ => 7,
      };
}

class _SeedlingFormResult {
  const _SeedlingFormResult({
    required this.crop,
    required this.varietyName,
    required this.quantityStarted,
    required this.dateStarted,
    required this.location,
    required this.method,
    required this.notes,
  });

  final VegetableDefinition crop;
  final String varietyName;
  final int quantityStarted;
  final DateTime dateStarted;
  final String location;
  final String method;
  final String notes;
}

class _SeedlingPickerCard extends StatelessWidget {
  const _SeedlingPickerCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.options,
    required this.onSelected,
  });

  final String title;
  final String value;
  final IconData icon;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SmoothTap(
        onTap: () => _showOptions(context),
        semanticsLabel: title,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: C.forestSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: C.forest, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: C.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: C.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_down, color: C.muted, size: 18),
            ],
          ),
        ),
      );

  void _showOptions(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(title),
        actions: [
          for (final option in options)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                onSelected(option);
              },
              child: Text(option),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
'@ | Set-Content -Encoding utf8 .\lib\features\seedlings\presentation\seedlings_screen.dart

$py = @'
from pathlib import Path


def add_once(text, marker, insert, label):
    if insert.strip() in text:
        return text
    if marker not in text:
        raise SystemExit(f"Missing insert marker: {label}")
    return text.replace(marker, insert + marker, 1)


def replace_once(text, old, new, label):
    if old not in text:
        raise SystemExit(f"Missing patch target: {label}")
    return text.replace(old, new, 1)

# main.dart parts
path = Path('lib/main.dart')
text = path.read_text(encoding='utf-8')
text = add_once(text, "part 'features/garden/domain/garden_models.dart';", "part 'features/seedlings/domain/seedling_models.dart';\n", 'seedling model part')
text = add_once(text, "part 'features/spray/presentation/pages/spray_screens.dart';", "part 'features/seedlings/presentation/seedlings_screen.dart';\n", 'seedlings screen part')
path.write_text(text, encoding='utf-8')

# GardenSnapshot persistence
path = Path('lib/models/garden_snapshot.dart')
text = path.read_text(encoding='utf-8')
if 'StoredSeedlingBatch' not in text:
    text = text.replace("    this.plants = const [],\n", "    this.plants = const [],\n    this.seedlings = const [],\n", 1)
    text = text.replace("  final List<StoredGardenPlant> plants;\n", "  final List<StoredGardenPlant> plants;\n  final List<StoredSeedlingBatch> seedlings;\n", 1)
    text = text.replace("    final plantJson = json['plants'];\n", "    final plantJson = json['plants'];\n    final seedlingJson = json['seedlings'];\n", 1)
    text = text.replace("          : const [],\n    );\n", "          : const [],\n      seedlings: seedlingJson is List\n          ? seedlingJson\n              .whereType<Map>()\n              .map((item) => StoredSeedlingBatch.fromJson(\n                    Map<String, dynamic>.from(item),\n                  ))\n              .where((batch) => batch.id > 0)\n              .toList(growable: false)\n          : const [],\n    );\n", 1)
    text = text.replace("        'plants': plants.map((plant) => plant.toJson()).toList(),\n", "        'plants': plants.map((plant) => plant.toJson()).toList(),\n        'seedlings': seedlings.map((batch) => batch.toJson()).toList(),\n", 1)
    insert = r'''
class StoredSeedlingBatch {
  const StoredSeedlingBatch({
    required this.id,
    required this.cropId,
    required this.cropName,
    required this.varietyName,
    required this.quantityStarted,
    required this.quantityAlive,
    required this.dateStarted,
    required this.location,
    required this.method,
    required this.status,
    required this.expectedGerminationDaysMin,
    required this.expectedGerminationDaysMax,
    required this.targetPlantOutDate,
    required this.notes,
    this.plantedOutBed,
    this.plantedOutDate,
  });

  final int id;
  final String cropId;
  final String cropName;
  final String varietyName;
  final int quantityStarted;
  final int quantityAlive;
  final DateTime dateStarted;
  final String location;
  final String method;
  final String status;
  final int expectedGerminationDaysMin;
  final int expectedGerminationDaysMax;
  final DateTime targetPlantOutDate;
  final int? plantedOutBed;
  final DateTime? plantedOutDate;
  final String notes;

  factory StoredSeedlingBatch.fromJson(Map<String, dynamic> json) =>
      StoredSeedlingBatch(
        id: _int(json['id']),
        cropId: _string(json['cropId']),
        cropName: _string(json['cropName']),
        varietyName: _string(json['varietyName']),
        quantityStarted: _int(json['quantityStarted']),
        quantityAlive: _int(json['quantityAlive']),
        dateStarted:
            DateTime.tryParse(_string(json['dateStarted'])) ?? DateTime(1970),
        location: _string(json['location']),
        method: _string(json['method']),
        status: _string(json['status']).isEmpty ? 'started' : _string(json['status']),
        expectedGerminationDaysMin:
            _int(json['expectedGerminationDaysMin'], fallback: 7),
        expectedGerminationDaysMax:
            _int(json['expectedGerminationDaysMax'], fallback: 14),
        targetPlantOutDate:
            DateTime.tryParse(_string(json['targetPlantOutDate'])) ??
                DateTime(1970),
        plantedOutBed: json['plantedOutBed'] == null
            ? null
            : _int(json['plantedOutBed']),
        plantedOutDate: DateTime.tryParse(_string(json['plantedOutDate'])),
        notes: _string(json['notes']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'cropId': cropId,
        'cropName': cropName,
        'varietyName': varietyName,
        'quantityStarted': quantityStarted,
        'quantityAlive': quantityAlive,
        'dateStarted': dateStarted.toIso8601String(),
        'location': location,
        'method': method,
        'status': status,
        'expectedGerminationDaysMin': expectedGerminationDaysMin,
        'expectedGerminationDaysMax': expectedGerminationDaysMax,
        'targetPlantOutDate': targetPlantOutDate.toIso8601String(),
        'plantedOutBed': plantedOutBed,
        'plantedOutDate': plantedOutDate?.toIso8601String(),
        'notes': notes,
      };
}

'''
    text = text.replace("String _string(Object? value)", insert + "String _string(Object? value)", 1)
path.write_text(text, encoding='utf-8')

# Bottom nav
path = Path('lib/common/widgets/shared_widgets.dart')
text = path.read_text(encoding='utf-8')
if "NavSpec('Seedlings'" not in text:
    text = text.replace("      NavSpec('Garden', CupertinoIcons.square_grid_2x2),\n      NavSpec('Spray', CupertinoIcons.drop),", "      NavSpec('Garden', CupertinoIcons.square_grid_2x2),\n      NavSpec('Seedlings', CupertinoIcons.leaf_arrow_circlepath),\n      NavSpec('Spray', CupertinoIcons.drop),", 1)
path.write_text(text, encoding='utf-8')

# Home controller
path = Path('lib/features/home/presentation/home_controller.dart')
text = path.read_text(encoding='utf-8')
if 'seedlingBatches' not in text:
    text = text.replace("  int nextPlantId = 1;\n", "  int nextPlantId = 1;\n  int nextSeedlingBatchId = 1;\n", 1)
    text = text.replace("  List<SprayRecord> records = [];\n", "  List<SprayRecord> records = [];\n  List<SeedlingBatch> seedlingBatches = [];\n", 1)
    text = text.replace("    final restoredRecords =\n        snapshot.records.map(_recordFromStorage).toList(growable: false);\n", "    final restoredRecords =\n        snapshot.records.map(_recordFromStorage).toList(growable: false);\n    final restoredSeedlings =\n        snapshot.seedlings.map(_seedlingFromStorage).toList(growable: false);\n", 1)
    text = text.replace("      records = restoredRecords;\n      nextRecordId = _nextRecordId(snapshot, restoredRecords);\n      nextPlantId = _nextGardenPlantId(restoredPlants);\n", "      records = restoredRecords;\n      seedlingBatches = restoredSeedlings;\n      nextRecordId = _nextRecordId(snapshot, restoredRecords);\n      nextPlantId = _nextGardenPlantId(restoredPlants);\n      nextSeedlingBatchId = _nextSeedlingBatchId(restoredSeedlings);\n", 1)
    insert = r'''
  int _nextSeedlingBatchId(List<SeedlingBatch> batches) {
    var next = 1;
    for (final batch in batches) {
      if (batch.id >= next) next = batch.id + 1;
    }
    return next;
  }

  SeedlingBatch _seedlingFromStorage(StoredSeedlingBatch batch) =>
      SeedlingBatch(
        id: batch.id,
        cropId: batch.cropId,
        cropName: batch.cropName,
        varietyName: batch.varietyName,
        quantityStarted: batch.quantityStarted,
        quantityAlive: batch.quantityAlive,
        dateStarted: batch.dateStarted,
        location: batch.location,
        method: batch.method,
        status: _seedlingStatusFromStorage(batch.status),
        expectedGerminationDaysMin: batch.expectedGerminationDaysMin,
        expectedGerminationDaysMax: batch.expectedGerminationDaysMax,
        targetPlantOutDate: batch.targetPlantOutDate,
        plantedOutBed: batch.plantedOutBed,
        plantedOutDate: batch.plantedOutDate,
        notes: batch.notes,
      );

  SeedlingStatus _seedlingStatusFromStorage(String value) =>
      SeedlingStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => SeedlingStatus.started,
      );

'''
    text = text.replace("  SprayRecord _recordFromStorage(StoredSprayRecord record) =>", insert + "  SprayRecord _recordFromStorage(StoredSprayRecord record) =>", 1)
    insert = r'''
  void addSeedlingBatch({
    required VegetableDefinition crop,
    required String varietyName,
    required int quantityStarted,
    required DateTime dateStarted,
    required String location,
    required String method,
    required String notes,
  }) {
    final germination = seedlingGerminationWindowFor(crop);
    final batch = SeedlingBatch(
      id: nextSeedlingBatchId,
      cropId: crop.id,
      cropName: crop.name,
      varietyName: varietyName,
      quantityStarted: quantityStarted,
      quantityAlive: quantityStarted,
      dateStarted: dateStarted,
      location: location,
      method: method,
      status: SeedlingStatus.started,
      expectedGerminationDaysMin: germination.min,
      expectedGerminationDaysMax: germination.max,
      targetPlantOutDate: seedlingTargetPlantOutDate(dateStarted, crop),
      notes: notes.trim(),
    );
    setState(() {
      nextSeedlingBatchId++;
      seedlingBatches.insert(0, batch);
      message = '${crop.name} seedlings added';
      tab = 2;
    });
    unawaited(_saveGarden());
  }

  void updateSeedlingStatus(int id, SeedlingStatus status) {
    setState(() {
      seedlingBatches = [
        for (final batch in seedlingBatches)
          if (batch.id == id) batch.copyWith(status: status) else batch,
      ];
      message = 'Seedling status updated';
    });
    unawaited(_saveGarden());
  }

  void plantOutSeedlingBatch(int id, int bed) {
    final batch = seedlingBatches.firstWhere(
      (item) => item.id == id,
      orElse: () => seedlingBatches.first,
    );
    final crop = vegetableLibrary.firstWhere(
      (item) => item.id == batch.cropId,
      orElse: () => vegetableLibrary.first,
    );
    final nextCrops = [...bedCrops[bed] ?? <VegetableDefinition>[]];
    if (!nextCrops.any((item) => item.id == crop.id)) nextCrops.add(crop);
    setState(() {
      bedCrops[bed] = nextCrops;
      seedlingBatches = [
        for (final item in seedlingBatches)
          if (item.id == id)
            item.copyWith(
              status: SeedlingStatus.plantedOut,
              plantedOutBed: bed,
              plantedOutDate: DateTime.now(),
            )
          else
            item,
      ];
      selectedBed = bed;
      message = '${batch.cropName} planted into Bed $bed';
      tab = 1;
    });
    unawaited(_saveGarden());
  }

'''
    text = text.replace("  void saveSpray({", insert + "  void saveSpray({", 1)
    text = text.replace("        records: records.map(_recordToStorage).toList(growable: false),\n", "        records: records.map(_recordToStorage).toList(growable: false),\n        seedlings: seedlingBatches.map(_seedlingToStorage).toList(growable: false),\n", 1)
    insert = r'''
  StoredSeedlingBatch _seedlingToStorage(SeedlingBatch batch) =>
      StoredSeedlingBatch(
        id: batch.id,
        cropId: batch.cropId,
        cropName: batch.cropName,
        varietyName: batch.varietyName,
        quantityStarted: batch.quantityStarted,
        quantityAlive: batch.quantityAlive,
        dateStarted: batch.dateStarted,
        location: batch.location,
        method: batch.method,
        status: batch.status.name,
        expectedGerminationDaysMin: batch.expectedGerminationDaysMin,
        expectedGerminationDaysMax: batch.expectedGerminationDaysMax,
        targetPlantOutDate: batch.targetPlantOutDate,
        plantedOutBed: batch.plantedOutBed,
        plantedOutDate: batch.plantedOutDate,
        notes: batch.notes,
      );

'''
    text = text.replace("  StoredGardenBed _bedToStorage", insert + "  StoredGardenBed _bedToStorage", 1)
    # tab indexes
    text = text.replace("onPlanSpray: () => setState(() => tab = 2)", "onPlanSpray: () => setState(() => tab = 3)")
    text = text.replace("onStartSpray: () => setState(() => tab = 2)", "onStartSpray: () => setState(() => tab = 3)")
    text = text.replace("      tab = 3;\n      message = 'Opened spray record", "      tab = 4;\n      message = 'Opened spray record", 1)
    text = text.replace("      tab = 4;\n      message = view == ProtectionView.pests", "      tab = 5;\n      message = view == ProtectionView.pests", 1)
    # pages list insert seedlings after GardenScreen block before SprayLogScreen
    marker = "      SprayLogScreen(\n"
    seed_page = r'''      SeedlingsScreen(
        batches: seedlingBatches,
        gardenBeds: gardenLayout,
        message: message,
        onAddBatch: addSeedlingBatch,
        onUpdateStatus: updateSeedlingStatus,
        onPlantOut: plantOutSeedlingBatch,
      ),
'''
    if seed_page.strip() not in text:
        text = text.replace(marker, seed_page + marker, 1)
path.write_text(text, encoding='utf-8')

print('Seedlings tab feature patch applied.')
'@

Write-Host "`n== Apply Python patch =="
$py | python -

Write-Host "`n== Format changed Dart files =="
dart format .\lib\main.dart `
  .\lib\models\garden_snapshot.dart `
  .\lib\features\home\presentation\home_controller.dart `
  .\lib\common\widgets\shared_widgets.dart `
  .\lib\features\seedlings\domain\seedling_models.dart `
  .\lib\features\seedlings\presentation\seedlings_screen.dart

Write-Host "`n== Analyze =="
flutter analyze

Write-Host "`n== Build debug APK =="
flutter build apk --debug

Write-Host "`n== Commit and push =="
git add lib/main.dart `
  lib/models/garden_snapshot.dart `
  lib/features/home/presentation/home_controller.dart `
  lib/common/widgets/shared_widgets.dart `
  lib/features/seedlings/domain/seedling_models.dart `
  lib/features/seedlings/presentation/seedlings_screen.dart `
  tools/apply_seedlings_tab_feature.ps1

git commit -m "Add seedlings tab and batch tracking"
git push origin main

Write-Host "`n== Done =="
git status --short
