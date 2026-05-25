Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "`n== Spray Tracker: Smart Planting Calendar patch =="

if (!(Test-Path ".\pubspec.yaml")) {
  throw "Run this from the spray-tracker repo root."
}

if (!(Test-Path ".\lib\features\seedlings\presentation\seedlings_screen.dart")) {
  throw "Seedlings tab files not found. Run .\tools\apply_seedlings_tab_feature.ps1 first."
}

$files = @(
  ".\lib\main.dart",
  ".\lib\features\seedlings\presentation\seedlings_screen.dart"
)

Write-Host "`n== Backup files =="
foreach ($file in $files) {
  Copy-Item $file "$file.before-smart-planting-calendar.bak" -Force
}

New-Item -ItemType Directory -Force .\lib\features\seedlings\domain | Out-Null

Write-Host "`n== Create planting calendar domain file =="
@'
part of '../../../main.dart';

enum PlantingRecommendationType {
  startIndoors,
  directSow,
  plantOut,
  wait,
  late,
}

String plantingRecommendationLabel(PlantingRecommendationType type) =>
    switch (type) {
      PlantingRecommendationType.startIndoors => 'Start indoors',
      PlantingRecommendationType.directSow => 'Direct sow',
      PlantingRecommendationType.plantOut => 'Plant out',
      PlantingRecommendationType.wait => 'Too early',
      PlantingRecommendationType.late => 'Late season',
    };

class CropCalendarRule {
  const CropCalendarRule({
    required this.cropId,
    required this.startIndoorsMonths,
    required this.directSowMonths,
    required this.plantOutMonths,
    required this.harvestMonths,
    required this.frostSensitive,
    required this.preferredStartMethod,
    required this.notes,
  });

  final String cropId;
  final List<int> startIndoorsMonths;
  final List<int> directSowMonths;
  final List<int> plantOutMonths;
  final List<int> harvestMonths;
  final bool frostSensitive;
  final String preferredStartMethod;
  final String notes;
}

class CropPlantingRecommendation {
  const CropPlantingRecommendation({
    required this.crop,
    required this.rule,
    required this.type,
    required this.action,
    required this.detail,
    required this.frostWarning,
  });

  final VegetableDefinition crop;
  final CropCalendarRule rule;
  final PlantingRecommendationType type;
  final String action;
  final String detail;
  final String frostWarning;
}

List<CropPlantingRecommendation> plantingRecommendationsForNow({
  required DateTime now,
  bool frostRisk = false,
}) {
  final month = now.month;
  final recommendations = <CropPlantingRecommendation>[];
  final rules = {for (final rule in cropCalendarRules) rule.cropId: rule};

  for (final crop in vegetableLibrary) {
    final rule = rules[crop.id] ?? fallbackCalendarRuleFor(crop);
    final type = _recommendationTypeFor(rule, month);
    final frostWarning = rule.frostSensitive && frostRisk
        ? 'Frost risk: keep protected until nights are warmer.'
        : '';
    recommendations.add(
      CropPlantingRecommendation(
        crop: crop,
        rule: rule,
        type: type,
        action: plantingRecommendationLabel(type),
        detail: _recommendationDetail(rule, type),
        frostWarning: frostWarning,
      ),
    );
  }

  recommendations.sort((a, b) {
    final priority = _recommendationPriority(a.type).compareTo(
      _recommendationPriority(b.type),
    );
    if (priority != 0) return priority;
    return a.crop.name.compareTo(b.crop.name);
  });
  return recommendations;
}

PlantingRecommendationType _recommendationTypeFor(
  CropCalendarRule rule,
  int month,
) {
  if (rule.startIndoorsMonths.contains(month)) {
    return PlantingRecommendationType.startIndoors;
  }
  if (rule.directSowMonths.contains(month)) {
    return PlantingRecommendationType.directSow;
  }
  if (rule.plantOutMonths.contains(month)) {
    return PlantingRecommendationType.plantOut;
  }

  final allPlantingMonths = [
    ...rule.startIndoorsMonths,
    ...rule.directSowMonths,
    ...rule.plantOutMonths,
  ];
  if (allPlantingMonths.isEmpty) return PlantingRecommendationType.wait;

  final nextPlanting = allPlantingMonths.any((item) => item > month);
  return nextPlanting ? PlantingRecommendationType.wait : PlantingRecommendationType.late;
}

int _recommendationPriority(PlantingRecommendationType type) => switch (type) {
      PlantingRecommendationType.startIndoors => 0,
      PlantingRecommendationType.directSow => 1,
      PlantingRecommendationType.plantOut => 2,
      PlantingRecommendationType.wait => 3,
      PlantingRecommendationType.late => 4,
    };

String _recommendationDetail(
  CropCalendarRule rule,
  PlantingRecommendationType type,
) =>
    switch (type) {
      PlantingRecommendationType.startIndoors =>
        'Use ${rule.preferredStartMethod.toLowerCase()} now. ${rule.notes}',
      PlantingRecommendationType.directSow =>
        'Sow direct now. ${rule.notes}',
      PlantingRecommendationType.plantOut =>
        'Plant sturdy seedlings into beds now. ${rule.notes}',
      PlantingRecommendationType.wait =>
        'Wait for the next planting window. ${rule.notes}',
      PlantingRecommendationType.late =>
        'Main planting window has likely passed. ${rule.notes}',
    };

CropCalendarRule fallbackCalendarRuleFor(VegetableDefinition crop) {
  final family = crop.familyId;
  if (family == 'brassicas') {
    return CropCalendarRule(
      cropId: crop.id,
      startIndoorsMonths: const [2, 3, 4, 8, 9],
      directSowMonths: const [3, 4, 8, 9, 10],
      plantOutMonths: const [4, 5, 9, 10],
      harvestMonths: const [5, 6, 7, 10, 11, 12],
      frostSensitive: false,
      preferredStartMethod: 'Tray',
      notes: 'Cool-season crop. Use mesh if whitefly or caterpillars are active.',
    );
  }
  if (family == 'leafy_greens') {
    return CropCalendarRule(
      cropId: crop.id,
      startIndoorsMonths: const [2, 3, 4, 5, 8, 9, 10],
      directSowMonths: const [2, 3, 4, 5, 8, 9, 10],
      plantOutMonths: const [3, 4, 5, 9, 10, 11],
      harvestMonths: const [3, 4, 5, 6, 9, 10, 11, 12],
      frostSensitive: false,
      preferredStartMethod: 'Tray',
      notes: 'Best in cooler weather; use shade during heat.',
    );
  }
  if (family == 'cucurbits') {
    return CropCalendarRule(
      cropId: crop.id,
      startIndoorsMonths: const [9, 10, 11],
      directSowMonths: const [10, 11, 12],
      plantOutMonths: const [10, 11, 12],
      harvestMonths: const [12, 1, 2, 3],
      frostSensitive: true,
      preferredStartMethod: 'Pot',
      notes: 'Warm-season crop. Avoid cold soil and frost.',
    );
  }
  if (family == 'herbs') {
    return CropCalendarRule(
      cropId: crop.id,
      startIndoorsMonths: const [8, 9, 10, 11],
      directSowMonths: const [9, 10, 11, 12],
      plantOutMonths: const [10, 11, 12],
      harvestMonths: const [11, 12, 1, 2, 3, 4],
      frostSensitive: true,
      preferredStartMethod: 'Tray',
      notes: 'Most herbs prefer warmth and shelter while young.',
    );
  }
  return CropCalendarRule(
    cropId: crop.id,
    startIndoorsMonths: const [8, 9, 10],
    directSowMonths: const [9, 10, 11],
    plantOutMonths: const [10, 11, 12],
    harvestMonths: const [12, 1, 2, 3],
    frostSensitive: true,
    preferredStartMethod: 'Tray',
    notes: 'Use local weather and frost risk before planting out.',
  );
}

const cropCalendarRules = [
  CropCalendarRule(
    cropId: 'tomato',
    startIndoorsMonths: [8, 9, 10],
    directSowMonths: [],
    plantOutMonths: [10, 11, 12],
    harvestMonths: [1, 2, 3, 4],
    frostSensitive: true,
    preferredStartMethod: 'Tray',
    notes: 'Start protected. Plant out only after frost risk has passed.',
  ),
  CropCalendarRule(
    cropId: 'chilli',
    startIndoorsMonths: [7, 8, 9],
    directSowMonths: [],
    plantOutMonths: [10, 11, 12],
    harvestMonths: [1, 2, 3, 4],
    frostSensitive: true,
    preferredStartMethod: 'Heat mat',
    notes: 'Slow starter. Warmth improves germination.',
  ),
  CropCalendarRule(
    cropId: 'capsicum',
    startIndoorsMonths: [7, 8, 9],
    directSowMonths: [],
    plantOutMonths: [10, 11, 12],
    harvestMonths: [1, 2, 3, 4],
    frostSensitive: true,
    preferredStartMethod: 'Heat mat',
    notes: 'Needs warmth and a long season.',
  ),
  CropCalendarRule(
    cropId: 'eggplant',
    startIndoorsMonths: [8, 9],
    directSowMonths: [],
    plantOutMonths: [10, 11, 12],
    harvestMonths: [1, 2, 3],
    frostSensitive: true,
    preferredStartMethod: 'Heat mat',
    notes: 'Needs warmth; avoid planting out early.',
  ),
  CropCalendarRule(
    cropId: 'lettuce',
    startIndoorsMonths: [2, 3, 4, 5, 8, 9, 10, 11],
    directSowMonths: [2, 3, 4, 5, 8, 9, 10, 11],
    plantOutMonths: [3, 4, 5, 9, 10, 11],
    harvestMonths: [3, 4, 5, 6, 9, 10, 11, 12],
    frostSensitive: false,
    preferredStartMethod: 'Tray',
    notes: 'Avoid the hottest weeks unless shaded.',
  ),
  CropCalendarRule(
    cropId: 'spinach',
    startIndoorsMonths: [2, 3, 4, 8, 9, 10],
    directSowMonths: [2, 3, 4, 8, 9, 10],
    plantOutMonths: [3, 4, 5, 9, 10],
    harvestMonths: [4, 5, 6, 10, 11, 12],
    frostSensitive: false,
    preferredStartMethod: 'Tray',
    notes: 'Cool-season crop; may bolt in heat.',
  ),
  CropCalendarRule(
    cropId: 'carrot',
    startIndoorsMonths: [],
    directSowMonths: [2, 3, 4, 5, 8, 9, 10, 11],
    plantOutMonths: [],
    harvestMonths: [4, 5, 6, 7, 10, 11, 12],
    frostSensitive: false,
    preferredStartMethod: 'Direct sow',
    notes: 'Direct sow only; avoid transplanting.',
  ),
  CropCalendarRule(
    cropId: 'beetroot',
    startIndoorsMonths: [2, 3, 4, 8, 9, 10],
    directSowMonths: [2, 3, 4, 8, 9, 10],
    plantOutMonths: [3, 4, 5, 9, 10],
    harvestMonths: [4, 5, 6, 10, 11, 12],
    frostSensitive: false,
    preferredStartMethod: 'Cell tray',
    notes: 'Can be sown direct or started in cells.',
  ),
  CropCalendarRule(
    cropId: 'bean',
    startIndoorsMonths: [9, 10],
    directSowMonths: [10, 11, 12, 1],
    plantOutMonths: [10, 11, 12],
    harvestMonths: [12, 1, 2, 3],
    frostSensitive: true,
    preferredStartMethod: 'Direct sow',
    notes: 'Needs warm soil; direct sow after frost.',
  ),
  CropCalendarRule(
    cropId: 'pea',
    startIndoorsMonths: [2, 3, 4, 8, 9],
    directSowMonths: [2, 3, 4, 8, 9],
    plantOutMonths: [3, 4, 9, 10],
    harvestMonths: [4, 5, 6, 10, 11],
    frostSensitive: false,
    preferredStartMethod: 'Direct sow',
    notes: 'Cool-season crop; protect young seedlings from birds.',
  ),
  CropCalendarRule(
    cropId: 'zucchini',
    startIndoorsMonths: [9, 10, 11],
    directSowMonths: [10, 11, 12],
    plantOutMonths: [10, 11, 12],
    harvestMonths: [12, 1, 2, 3],
    frostSensitive: true,
    preferredStartMethod: 'Pot',
    notes: 'Warm-season crop; start in pots for quick plant-out.',
  ),
  CropCalendarRule(
    cropId: 'cucumber',
    startIndoorsMonths: [9, 10, 11],
    directSowMonths: [10, 11, 12],
    plantOutMonths: [10, 11, 12],
    harvestMonths: [12, 1, 2, 3],
    frostSensitive: true,
    preferredStartMethod: 'Pot',
    notes: 'Warmth and steady moisture are important.',
  ),
  CropCalendarRule(
    cropId: 'pumpkin',
    startIndoorsMonths: [9, 10, 11],
    directSowMonths: [10, 11, 12],
    plantOutMonths: [10, 11, 12],
    harvestMonths: [2, 3, 4],
    frostSensitive: true,
    preferredStartMethod: 'Pot',
    notes: 'Needs space and a long warm season.',
  ),
  CropCalendarRule(
    cropId: 'basil',
    startIndoorsMonths: [9, 10, 11],
    directSowMonths: [10, 11, 12],
    plantOutMonths: [11, 12],
    harvestMonths: [12, 1, 2, 3],
    frostSensitive: true,
    preferredStartMethod: 'Tray',
    notes: 'Very frost sensitive. Keep warm and sheltered.',
  ),
];
'@ | Set-Content -Encoding utf8 .\lib\features\seedlings\domain\planting_calendar.dart

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

# main.dart part
path = Path('lib/main.dart')
text = path.read_text(encoding='utf-8')
text = add_once(
    text,
    "part 'features/seedlings/domain/seedling_models.dart';",
    "part 'features/seedlings/domain/planting_calendar.dart';\n",
    'planting calendar part',
)
path.write_text(text, encoding='utf-8')

# seedlings_screen.dart UI
path = Path('lib/features/seedlings/presentation/seedlings_screen.dart')
text = path.read_text(encoding='utf-8')

# Add state fields
text = replace_once(
    text,
    """class _SeedlingsScreenState extends State<SeedlingsScreen> {\n  bool adding = false;\n""",
    """class _SeedlingsScreenState extends State<SeedlingsScreen> {\n  bool adding = false;\n  PlantingRecommendationType? calendarFilter;\n  VegetableDefinition? preselectedCrop;\n""",
    'calendar state fields',
)

# Replace Add panel creation so preselected crop can be passed in
text = replace_once(
    text,
    """          _AddSeedlingBatchPanel(\n            onSave: (args) {\n""",
    """          _AddSeedlingBatchPanel(\n            initialCrop: preselectedCrop,\n            onSave: (args) {\n""",
    'initial crop param',
)

# Reset preselected after save
text = replace_once(
    text,
    """              setState(() => adding = false);\n""",
    """              setState(() {\n                adding = false;\n                preselectedCrop = null;\n              });\n""",
    'reset preselected after save',
)

# Insert What can I start now section before Ready soon
text = replace_once(
    text,
    """      children: [\n        SectionTitle(\n          'Ready soon',\n""",
    r'''      children: [
        SectionTitle(
          'What can I start now?',
          trailing: ProductTag(
            label: 'Blenheim timing',
            color: C.forest,
            background: C.forestSoft,
          ),
        ),
        const SizedBox(height: 8),
        _PlantingCalendarFilterRow(
          selected: calendarFilter,
          onChanged: (value) => setState(() => calendarFilter = value),
        ),
        const SizedBox(height: 10),
        Builder(
          builder: (context) {
            final recommendations = plantingRecommendationsForNow(
              now: DateTime.now(),
              frostRisk: DateTime.now().month <= 9 || DateTime.now().month >= 5 && DateTime.now().month <= 8,
            ).where((item) {
              return calendarFilter == null || item.type == calendarFilter;
            }).take(8).toList(growable: false);
            if (recommendations.isEmpty) {
              return const EmptyCard('No crops match this filter right now.');
            }
            return Column(
              children: [
                for (final recommendation in recommendations)
                  _PlantingRecommendationCard(
                    recommendation: recommendation,
                    onStartBatch: (crop) => setState(() {
                      preselectedCrop = crop;
                      adding = true;
                    }),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        SectionTitle(
          'Ready soon',
''',
    'what can I start now section',
)

# Add initialCrop to Add panel widget
text = replace_once(
    text,
    """class _AddSeedlingBatchPanel extends StatefulWidget {\n  const _AddSeedlingBatchPanel({required this.onSave});\n\n  final ValueChanged<_SeedlingFormResult> onSave;\n""",
    """class _AddSeedlingBatchPanel extends StatefulWidget {\n  const _AddSeedlingBatchPanel({required this.onSave, this.initialCrop});\n\n  final ValueChanged<_SeedlingFormResult> onSave;\n  final VegetableDefinition? initialCrop;\n""",
    'Add panel initialCrop field',
)

# Initialize crop from widget.initialCrop in initState instead of field literal
text = replace_once(
    text,
    """  VegetableDefinition crop = vegetableLibrary.first;\n  String varietyName = '';\n""",
    """  late VegetableDefinition crop = widget.initialCrop ?? vegetableLibrary.first;\n  String varietyName = '';\n""",
    'initial crop field assignment',
)

# Add calendar widgets before Add panel class
insert = r'''
class _PlantingCalendarFilterRow extends StatelessWidget {
  const _PlantingCalendarFilterRow({
    required this.selected,
    required this.onChanged,
  });

  final PlantingRecommendationType? selected;
  final ValueChanged<PlantingRecommendationType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, PlantingRecommendationType? value})>[
      (label: 'All', value: null),
      (label: 'Start indoors', value: PlantingRecommendationType.startIndoors),
      (label: 'Direct sow', value: PlantingRecommendationType.directSow),
      (label: 'Plant out', value: PlantingRecommendationType.plantOut),
      (label: 'Too early', value: PlantingRecommendationType.wait),
      (label: 'Late', value: PlantingRecommendationType.late),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: NumberChip(
                label: item.label,
                selected: selected == item.value,
                onTap: () => onChanged(item.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlantingRecommendationCard extends StatelessWidget {
  const _PlantingRecommendationCard({
    required this.recommendation,
    required this.onStartBatch,
  });

  final CropPlantingRecommendation recommendation;
  final ValueChanged<VegetableDefinition> onStartBatch;

  @override
  Widget build(BuildContext context) {
    final crop = recommendation.crop;
    final grow = GrowTimeDefaults.harvestWindowFor(crop);
    final type = recommendation.type;
    final isHold = type == PlantingRecommendationType.wait ||
        type == PlantingRecommendationType.late;
    final color = switch (type) {
      PlantingRecommendationType.startIndoors => C.blue,
      PlantingRecommendationType.directSow => C.forest,
      PlantingRecommendationType.plantOut => C.amber,
      PlantingRecommendationType.wait => C.muted,
      PlantingRecommendationType.late => C.red,
    };
    final background = switch (type) {
      PlantingRecommendationType.startIndoors => C.blueSoft,
      PlantingRecommendationType.directSow => C.forestSoft,
      PlantingRecommendationType.plantOut => C.amberSoft,
      PlantingRecommendationType.wait => C.greySoft,
      PlantingRecommendationType.late => C.redSoft,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: cardDecoration(),
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
                      crop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: C.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      recommendation.detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: C.muted,
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(recommendation.action.toUpperCase(), hold: isHold),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              ProductTag(
                label: recommendation.rule.preferredStartMethod,
                color: color,
                background: background,
              ),
              ProductTag(
                label: 'Harvest ${grow.min}-${grow.max} days',
                color: C.forest,
                background: C.forestSoft,
              ),
              if (recommendation.rule.frostSensitive)
                ProductTag(
                  label: 'Frost sensitive',
                  color: C.amber,
                  background: C.amberSoft,
                ),
            ],
          ),
          if (recommendation.frostWarning.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              recommendation.frostWarning,
              style: const TextStyle(
                color: C.amber,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Start batch',
            onPressed: isHold ? null : () => onStartBatch(crop),
          ),
        ],
      ),
    );
  }
}

'''
text = add_once(text, 'class _AddSeedlingBatchPanel extends StatefulWidget', insert, 'planting calendar widgets')

path.write_text(text, encoding='utf-8')

print('Smart Planting Calendar patch applied.')
'@

Write-Host "`n== Apply Python patch =="
$py | python -

Write-Host "`n== Format changed Dart files =="
dart format .\lib\main.dart `
  .\lib\features\seedlings\domain\planting_calendar.dart `
  .\lib\features\seedlings\presentation\seedlings_screen.dart

Write-Host "`n== Analyze =="
flutter analyze

Write-Host "`n== Build debug APK =="
flutter build apk --debug

Write-Host "`n== Commit and push =="
git add lib/main.dart `
  lib/features/seedlings/domain/planting_calendar.dart `
  lib/features/seedlings/presentation/seedlings_screen.dart `
  tools/apply_smart_planting_calendar.ps1

git commit -m "Add smart planting calendar to seedlings"
git push origin main

Write-Host "`n== Done =="
git status --short
