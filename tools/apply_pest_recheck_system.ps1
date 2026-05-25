Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "`n== Spray Tracker: Pest Recheck System feature patch =="

if (!(Test-Path ".\pubspec.yaml")) {
  throw "Run this from the spray-tracker repo root."
}

$files = @(
  ".\lib\models\garden_snapshot.dart",
  ".\lib\features\home\presentation\home_controller.dart",
  ".\lib\features\home\presentation\home_screen.dart",
  ".\lib\features\spray\domain\spray_records.dart"
)

Write-Host "`n== Backup files =="
foreach ($file in $files) {
  Copy-Item $file "$file.before-pest-recheck.bak" -Force
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
# spray_records.dart: PestSighting status/follow-up fields and helpers
# ---------------------------------------------------------------------------
path = Path('lib/features/spray/domain/spray_records.dart')
text = path.read_text(encoding='utf-8')

text = add_once(
    text,
    'enum PestSeverity { low, medium, high }',
    """enum PestSightingStatus { active, watching, resolved, worse }\n\n""",
    'PestSightingStatus enum',
)

text = add_once(
    text,
    'class PestSighting {',
    r'''String pestSightingStatusLabel(PestSightingStatus status) => switch (status) {
      PestSightingStatus.active => 'Active',
      PestSightingStatus.watching => 'Watching',
      PestSightingStatus.resolved => 'Resolved',
      PestSightingStatus.worse => 'Worse',
    };

bool pestSightingNeedsRecheck(PestSighting sighting, {DateTime? now}) {
  if (sighting.status == PestSightingStatus.resolved) return false;
  final today = now ?? DateTime.now();
  return !sighting.recheckDate.isAfter(today);
}

''',
    'PestSighting helpers',
)

text = replace_once(
    text,
    """    required this.actionTaken,\n    required this.date,\n    required this.recheckDate,\n    required this.notes,\n  });\n""",
    """    required this.actionTaken,\n    required this.date,\n    required this.recheckDate,\n    required this.notes,\n    this.status = PestSightingStatus.active,\n    this.followUpDate,\n    this.followUpResult,\n  });\n""",
    'PestSighting constructor fields',
)

text = replace_once(
    text,
    """  final DateTime recheckDate;\n  final String notes;\n\n  bool get recheckDue => !recheckDate.isAfter(DateTime.now());\n}\n""",
    r'''  final DateTime recheckDate;
  final String notes;
  final PestSightingStatus status;
  final DateTime? followUpDate;
  final String? followUpResult;

  bool get recheckDue => pestSightingNeedsRecheck(this);

  PestSighting copyWith({
    PestSightingStatus? status,
    DateTime? recheckDate,
    DateTime? followUpDate,
    String? followUpResult,
  }) =>
      PestSighting(
        id: id,
        bed: bed,
        cropName: cropName,
        issueName: issueName,
        severity: severity,
        actionTaken: actionTaken,
        date: date,
        recheckDate: recheckDate ?? this.recheckDate,
        notes: notes,
        status: status ?? this.status,
        followUpDate: followUpDate ?? this.followUpDate,
        followUpResult: followUpResult ?? this.followUpResult,
      );
}
''',
    'PestSighting status fields',
)

path.write_text(text, encoding='utf-8')

# ---------------------------------------------------------------------------
# garden_snapshot.dart: persist status/follow-up fields
# ---------------------------------------------------------------------------
path = Path('lib/models/garden_snapshot.dart')
text = path.read_text(encoding='utf-8')

text = replace_once(
    text,
    """    required this.recheckDate,\n    required this.notes,\n  });\n""",
    """    required this.recheckDate,\n    required this.notes,\n    this.status = 'active',\n    this.followUpDate,\n    this.followUpResult,\n  });\n""",
    'StoredPestSighting constructor fields',
)

text = replace_once(
    text,
    """  final DateTime recheckDate;\n  final String notes;\n\n  factory StoredPestSighting.fromJson(Map<String, dynamic> json) =>\n""",
    """  final DateTime recheckDate;\n  final String notes;\n  final String status;\n  final DateTime? followUpDate;\n  final String? followUpResult;\n\n  factory StoredPestSighting.fromJson(Map<String, dynamic> json) =>\n""",
    'StoredPestSighting fields',
)

text = replace_once(
    text,
    """        recheckDate:\n            DateTime.tryParse(_string(json['recheckDate'])) ?? DateTime(1970),\n        notes: _string(json['notes']),\n      );\n""",
    """        recheckDate:\n            DateTime.tryParse(_string(json['recheckDate'])) ?? DateTime(1970),\n        notes: _string(json['notes']),\n        status: _string(json['status']).isEmpty ? 'active' : _string(json['status']),\n        followUpDate: DateTime.tryParse(_string(json['followUpDate'])),\n        followUpResult: _string(json['followUpResult']).isEmpty\n            ? null\n            : _string(json['followUpResult']),\n      );\n""",
    'StoredPestSighting fromJson new fields',
)

text = replace_once(
    text,
    """        'recheckDate': recheckDate.toIso8601String(),\n        'notes': notes,\n      };\n}\n""",
    """        'recheckDate': recheckDate.toIso8601String(),\n        'notes': notes,\n        'status': status,\n        'followUpDate': followUpDate?.toIso8601String(),\n        'followUpResult': followUpResult,\n      };\n}\n""",
    'StoredPestSighting toJson new fields',
)

path.write_text(text, encoding='utf-8')

# ---------------------------------------------------------------------------
# home_controller.dart: restore/save follow-up fields and update method
# ---------------------------------------------------------------------------
path = Path('lib/features/home/presentation/home_controller.dart')
text = path.read_text(encoding='utf-8')

text = replace_once(
    text,
    """        recheckDate: sighting.recheckDate,\n        notes: sighting.notes,\n      );\n\n  PestSeverity _pestSeverityFromStorage""",
    """        recheckDate: sighting.recheckDate,\n        notes: sighting.notes,\n        status: _pestSightingStatusFromStorage(sighting.status),\n        followUpDate: sighting.followUpDate,\n        followUpResult: sighting.followUpResult,\n      );\n\n  PestSightingStatus _pestSightingStatusFromStorage(String value) =>\n      PestSightingStatus.values.firstWhere(\n        (status) => status.name == value,\n        orElse: () => PestSightingStatus.active,\n      );\n\n  PestSeverity _pestSeverityFromStorage""",
    'restore pest sighting status',
)

text = add_once(
    text,
    '  void savePestSighting({',
    r'''  void updatePestSightingFollowUp({
    required int id,
    required String result,
  }) {
    final now = DateTime.now();
    final status = switch (result) {
      'Pest gone' => PestSightingStatus.resolved,
      'Less pest pressure' => PestSightingStatus.watching,
      'Same as before' => PestSightingStatus.active,
      'Worse' => PestSightingStatus.worse,
      'Crop damaged' => PestSightingStatus.worse,
      _ => PestSightingStatus.active,
    };
    final nextRecheckDate = switch (result) {
      'Pest gone' => now,
      'Less pest pressure' => now.add(const Duration(days: 3)),
      'Same as before' => now.add(const Duration(days: 2)),
      'Worse' => now.add(const Duration(days: 1)),
      'Crop damaged' => now.add(const Duration(days: 1)),
      _ => now.add(const Duration(days: 2)),
    };
    setState(() {
      pestSightings = [
        for (final sighting in pestSightings)
          if (sighting.id == id)
            sighting.copyWith(
              status: status,
              followUpDate: now,
              followUpResult: result,
              recheckDate: nextRecheckDate,
            )
          else
            sighting,
      ];
      message = status == PestSightingStatus.resolved
          ? 'Pest sighting marked resolved'
          : 'Pest follow-up saved';
    });
    unawaited(_saveGarden());
  }

''',
    'updatePestSightingFollowUp method',
)

text = replace_once(
    text,
    """        recheckDate: sighting.recheckDate,\n        notes: sighting.notes,\n      );\n\n  StoredGardenBed _bedToStorage""",
    """        recheckDate: sighting.recheckDate,\n        notes: sighting.notes,\n        status: sighting.status.name,\n        followUpDate: sighting.followUpDate,\n        followUpResult: sighting.followUpResult,\n      );\n\n  StoredGardenBed _bedToStorage""",
    'pest sighting to storage status',
)

text = replace_once(
    text,
    """        pestSightings: pestSightings,\n        products: products,\n""",
    """        pestSightings: pestSightings,\n        products: products,\n        onPestFollowUp: updatePestSightingFollowUp,\n""",
    'HomeScreen follow-up callback',
)

path.write_text(text, encoding='utf-8')

# ---------------------------------------------------------------------------
# home_screen.dart: due-to-recheck section and action-sheet follow-up
# ---------------------------------------------------------------------------
path = Path('lib/features/home/presentation/home_screen.dart')
text = path.read_text(encoding='utf-8')

text = replace_once(
    text,
    """    required this.onOpenPestProfiles,\n    required this.onCopyBackup,\n""",
    """    required this.onOpenPestProfiles,\n    required this.onPestFollowUp,\n    required this.onCopyBackup,\n""",
    'HomeScreen constructor follow-up',
)

text = replace_once(
    text,
    """  final VoidCallback onOpenPestProfiles;\n  final VoidCallback onCopyBackup;\n""",
    """  final VoidCallback onOpenPestProfiles;\n  final void Function({required int id, required String result}) onPestFollowUp;\n  final VoidCallback onCopyBackup;\n""",
    'HomeScreen field follow-up',
)

text = replace_once(
    text,
    """        const SizedBox(height: 18),\n        const SectionTitle('Recent pest sightings'),\n""",
    r'''        const SizedBox(height: 18),
        const SectionTitle('Due to recheck'),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final due = pestSightings
                .where((sighting) => pestSightingNeedsRecheck(sighting))
                .toList(growable: false);
            if (due.isEmpty) {
              return const EmptyCard('No pest rechecks due today.');
            }
            return Column(
              children: [
                for (final sighting in due.take(4))
                  _PestRecheckDueCard(
                    sighting: sighting,
                    onFollowUp: onPestFollowUp,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        const SectionTitle('Recent pest sightings'),
''',
    'Due to recheck section',
)

insert = r'''
class _PestRecheckDueCard extends StatelessWidget {
  const _PestRecheckDueCard({
    required this.sighting,
    required this.onFollowUp,
  });

  final PestSighting sighting;
  final void Function({required int id, required String result}) onFollowUp;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: cardDecoration(color: C.amberSoft),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: C.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: C.line),
                  ),
                  child: const Icon(
                    CupertinoIcons.calendar_badge_clock,
                    color: C.amber,
                    size: 22,
                  ),
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
                        'Original action: ${sighting.actionTaken}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: C.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                StatusPill(pestSightingStatusLabel(sighting.status).toUpperCase(), hold: true),
              ],
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Record follow-up',
              onPressed: () => _showFollowUpMenu(context),
            ),
          ],
        ),
      );

  void _showFollowUpMenu(BuildContext context) {
    const options = [
      'Pest gone',
      'Less pest pressure',
      'Same as before',
      'Worse',
      'Crop damaged',
    ];
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Recheck result'),
        message: Text('${sighting.issueName} on ${sighting.cropName}, Bed ${sighting.bed}'),
        actions: [
          for (final option in options)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                onFollowUp(id: sighting.id, result: option);
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

'''
text = add_once(text, 'class _PestSightingHomeCard extends StatelessWidget', insert, 'Pest recheck due card')

text = replace_once(
    text,
    """                    '${sighting.cropName} | ${pestSeverityLabel(sighting.severity)} severity',\n""",
    """                    '${sighting.cropName} | ${pestSeverityLabel(sighting.severity)} | ${pestSightingStatusLabel(sighting.status)}',\n""",
    'recent card status label',
)

text = replace_once(
    text,
    """                    'Action: ${sighting.actionTaken} | recheck ${shortDate(sighting.recheckDate)}',\n""",
    """                    sighting.followUpResult == null\n                        ? 'Action: ${sighting.actionTaken} | recheck ${shortDate(sighting.recheckDate)}'\n                        : 'Follow-up: ${sighting.followUpResult} | next ${shortDate(sighting.recheckDate)}',\n""",
    'recent card follow-up label',
)

path.write_text(text, encoding='utf-8')

print('Pest Recheck System patch applied.')
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
  tools/apply_pest_recheck_system.ps1

git commit -m "Add pest recheck follow-up system"
git push origin main

Write-Host "`n== Done =="
git status --short
