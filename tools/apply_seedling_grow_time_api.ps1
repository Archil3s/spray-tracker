Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "`n== Spray Tracker: Seedling grow-time API enrichment patch =="

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
  Copy-Item $file "$file.before-grow-time-api.bak" -Force
}

New-Item -ItemType Directory -Force .\lib\features\seedlings\data | Out-Null

Write-Host "`n== Create grow time API service =="
@'
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../crop_library.dart';

class GrowTimeEstimate {
  const GrowTimeEstimate({
    required this.germinationDaysMin,
    required this.germinationDaysMax,
    required this.transplantWeeks,
    required this.harvestDaysMin,
    required this.harvestDaysMax,
    required this.source,
    required this.note,
    this.apiGrowthRate,
    this.apiHarvestSeason,
  });

  final int germinationDaysMin;
  final int germinationDaysMax;
  final int transplantWeeks;
  final int harvestDaysMin;
  final int harvestDaysMax;
  final String source;
  final String note;
  final String? apiGrowthRate;
  final String? apiHarvestSeason;
}

class GrowTimeService {
  GrowTimeService({http.Client? client}) : _client = client ?? http.Client();

  static final GrowTimeService instance = GrowTimeService();

  static const perenualApiKey = String.fromEnvironment('PERENUAL_API_KEY');

  final http.Client _client;
  final Map<String, GrowTimeEstimate> _cache = {};

  Future<GrowTimeEstimate> estimateFor(VegetableDefinition crop) async {
    final cached = _cache[crop.id];
    if (cached != null) return cached;

    final fallback = GrowTimeDefaults.estimateFor(crop);
    if (perenualApiKey.trim().isEmpty) {
      _cache[crop.id] = fallback;
      return fallback;
    }

    try {
      final listUri = Uri.https('perenual.com', '/api/v2/species-list', {
        'key': perenualApiKey,
        'q': crop.name,
        'edible': '1',
      });
      final listResponse =
          await _client.get(listUri).timeout(const Duration(seconds: 6));
      if (listResponse.statusCode < 200 || listResponse.statusCode >= 300) {
        _cache[crop.id] = fallback;
        return fallback;
      }

      final listJson = jsonDecode(listResponse.body);
      final data = listJson is Map<String, dynamic> ? listJson['data'] : null;
      if (data is! List || data.isEmpty) {
        _cache[crop.id] = fallback;
        return fallback;
      }

      final first = data.whereType<Map<String, dynamic>>().firstOrNull;
      final id = first == null ? null : first['id'];
      if (id == null) {
        _cache[crop.id] = fallback;
        return fallback;
      }

      final detailUri = Uri.https('perenual.com', '/api/v2/species/details/$id', {
        'key': perenualApiKey,
      });
      final detailResponse =
          await _client.get(detailUri).timeout(const Duration(seconds: 6));
      if (detailResponse.statusCode < 200 || detailResponse.statusCode >= 300) {
        _cache[crop.id] = fallback;
        return fallback;
      }

      final detailJson = jsonDecode(detailResponse.body);
      if (detailJson is! Map<String, dynamic>) {
        _cache[crop.id] = fallback;
        return fallback;
      }

      final growthRate = _string(detailJson['growth_rate']);
      final harvestSeason = _string(detailJson['harvest_season']);
      final adjusted = _adjustFromApi(
        fallback,
        growthRate: growthRate,
        harvestSeason: harvestSeason,
      );
      _cache[crop.id] = adjusted;
      return adjusted;
    } on TimeoutException {
      _cache[crop.id] = fallback;
      return fallback;
    } catch (_) {
      _cache[crop.id] = fallback;
      return fallback;
    }
  }

  GrowTimeEstimate _adjustFromApi(
    GrowTimeEstimate fallback, {
    required String growthRate,
    required String harvestSeason,
  }) {
    final lower = growthRate.toLowerCase();
    var min = fallback.harvestDaysMin;
    var max = fallback.harvestDaysMax;
    if (lower.contains('high') || lower.contains('fast')) {
      min = (min * .92).round();
      max = (max * .92).round();
    } else if (lower.contains('low') || lower.contains('slow')) {
      min = (min * 1.12).round();
      max = (max * 1.12).round();
    }

    final apiBits = [
      if (growthRate.isNotEmpty) 'growth: $growthRate',
      if (harvestSeason.isNotEmpty) 'harvest season: $harvestSeason',
    ];

    return GrowTimeEstimate(
      germinationDaysMin: fallback.germinationDaysMin,
      germinationDaysMax: fallback.germinationDaysMax,
      transplantWeeks: fallback.transplantWeeks,
      harvestDaysMin: min,
      harvestDaysMax: max,
      source: apiBits.isEmpty ? fallback.source : 'Perenual + local estimate',
      note: apiBits.isEmpty
          ? fallback.note
          : 'API matched plant details (${apiBits.join(', ')}). Exact vegetable maturity days still use local fallback ranges.',
      apiGrowthRate: growthRate.isEmpty ? null : growthRate,
      apiHarvestSeason: harvestSeason.isEmpty ? null : harvestSeason,
    );
  }

  String _string(Object? value) => value is String ? value.trim() : '';
}

class GrowTimeDefaults {
  const GrowTimeDefaults._();

  static GrowTimeEstimate estimateFor(VegetableDefinition crop) {
    final id = crop.id.toLowerCase();
    final family = crop.familyId.toLowerCase();
    final germ = germinationWindowFor(crop);
    final transplantWeeks = transplantWeeksFor(crop);
    final harvest = harvestWindowFor(crop);
    return GrowTimeEstimate(
      germinationDaysMin: germ.min,
      germinationDaysMax: germ.max,
      transplantWeeks: transplantWeeks,
      harvestDaysMin: harvest.min,
      harvestDaysMax: harvest.max,
      source: 'Local grow-time estimate',
      note: id.isEmpty || family.isEmpty
          ? 'Generic seedling grow-time range.'
          : 'Vegetable grow-time estimate based on crop family and common home-garden timing.',
    );
  }

  static ({int min, int max}) germinationWindowFor(VegetableDefinition crop) {
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

  static int transplantWeeksFor(VegetableDefinition crop) {
    final id = crop.id.toLowerCase();
    final family = crop.familyId.toLowerCase();
    return switch (family) {
      'leafy_greens' => 4,
      'brassicas' => 5,
      'cucurbits' => 3,
      'herbs' => 6,
      _ => const ['tomato', 'chilli', 'capsicum', 'eggplant'].contains(id)
          ? 8
          : 6,
    };
  }

  static ({int min, int max}) harvestWindowFor(VegetableDefinition crop) {
    final id = crop.id.toLowerCase();
    final family = crop.familyId.toLowerCase();
    if (id.contains('radish')) return (min: 25, max: 35);
    if (id.contains('lettuce') || id.contains('rocket')) return (min: 35, max: 60);
    if (id.contains('spinach') || id.contains('silverbeet')) return (min: 45, max: 70);
    if (id.contains('tomato')) return (min: 70, max: 100);
    if (id.contains('chilli') || id.contains('capsicum')) return (min: 80, max: 120);
    if (id.contains('eggplant')) return (min: 80, max: 110);
    if (id.contains('zucchini') || id.contains('cucumber')) return (min: 50, max: 70);
    if (id.contains('pumpkin') || id.contains('squash')) return (min: 90, max: 130);
    if (id.contains('bean')) return (min: 50, max: 75);
    if (id.contains('pea')) return (min: 60, max: 85);
    if (id.contains('carrot')) return (min: 70, max: 100);
    if (id.contains('beetroot')) return (min: 55, max: 80);
    if (id.contains('onion') || id.contains('garlic')) return (min: 120, max: 210);
    if (family == 'brassicas') return (min: 60, max: 110);
    if (family == 'herbs') return (min: 45, max: 90);
    return (min: 60, max: 100);
  }
}
'@ | Set-Content -Encoding utf8 .\lib\features\seedlings\data\grow_time_service.dart

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

# main.dart import
path = Path('lib/main.dart')
text = path.read_text(encoding='utf-8')
text = add_once(
    text,
    "import 'features/notifications/harvest_reminder_service.dart';",
    "import 'features/seedlings/data/grow_time_service.dart';\n",
    'grow time import',
)
path.write_text(text, encoding='utf-8')

# seedlings screen UI enrichment
path = Path('lib/features/seedlings/presentation/seedlings_screen.dart')
text = path.read_text(encoding='utf-8')

# Add harvest tag to cards after Plant out tag
text = replace_once(
    text,
    """              ProductTag(\n                label: 'Plant out ${shortDate(batch.targetPlantOutDate)}',\n                color: C.amber,\n                background: C.amberSoft,\n              ),\n""",
    """              ProductTag(\n                label: 'Plant out ${shortDate(batch.targetPlantOutDate)}',\n                color: C.amber,\n                background: C.amberSoft,\n              ),\n              ProductTag(\n                label: _harvestEstimateLabel(crop, batch.dateStarted),\n                color: C.forest,\n                background: C.forestSoft,\n              ),\n""",
    'seedling card harvest tag',
)

# Add helper method in SeedlingBatchCard before _showStatusSheet
text = add_once(
    text,
    "  void _showStatusSheet(BuildContext context) {",
    r'''  String _harvestEstimateLabel(VegetableDefinition crop, DateTime started) {
    final harvest = GrowTimeDefaults.harvestWindowFor(crop);
    final early = started.add(Duration(days: harvest.min));
    final late = started.add(Duration(days: harvest.max));
    return 'Harvest ${shortDate(early)}-${shortDate(late)}';
  }

''',
    'harvest estimate helper',
)

# Add future state to Add panel
text = replace_once(
    text,
    """  int quantity = 12;\n  int startOffsetDays = 0;\n  final notes = TextEditingController();\n""",
    """  int quantity = 12;\n  int startOffsetDays = 0;\n  late Future<GrowTimeEstimate> growTimeEstimate =\n      GrowTimeService.instance.estimateFor(crop);\n  final notes = TextEditingController();\n""",
    'grow time future field',
)

# Refresh estimate when crop changes
text = replace_once(
    text,
    """              crop = vegetableLibrary.firstWhere((item) => item.name == value);\n              varietyName = '';\n""",
    """              crop = vegetableLibrary.firstWhere((item) => item.name == value);\n              varietyName = '';\n              growTimeEstimate = GrowTimeService.instance.estimateFor(crop);\n""",
    'refresh grow estimate on crop select',
)

# Replace static expected germination tag with FutureBuilder block
text = replace_once(
    text,
    """          ProductTag(\n            label: 'Expected germination ${germination.min}-${germination.max} days',\n            color: C.blue,\n            background: C.blueSoft,\n          ),\n""",
    r'''          FutureBuilder<GrowTimeEstimate>(
            future: growTimeEstimate,
            builder: (context, snapshot) {
              final estimate = snapshot.data;
              final harvestLabel = estimate == null
                  ? 'Harvest estimate loading'
                  : 'Harvest ${estimate.harvestDaysMin}-${estimate.harvestDaysMax} days';
              final sourceLabel = estimate?.source ?? 'Loading grow time';
              return Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  ProductTag(
                    label: estimate == null
                        ? 'Expected germination ${germination.min}-${germination.max} days'
                        : 'Germination ${estimate.germinationDaysMin}-${estimate.germinationDaysMax} days',
                    color: C.blue,
                    background: C.blueSoft,
                  ),
                  ProductTag(
                    label: harvestLabel,
                    color: C.forest,
                    background: C.forestSoft,
                  ),
                  ProductTag(
                    label: sourceLabel,
                    color: estimate?.source.contains('Perenual') == true
                        ? C.amber
                        : C.muted,
                    background: estimate?.source.contains('Perenual') == true
                        ? C.amberSoft
                        : C.greySoft,
                  ),
                ],
              );
            },
          ),
''',
    'future grow estimate tags',
)

# Add note below FutureBuilder if API source exists
text = replace_once(
    text,
    """          const SizedBox(height: 8),\n          Field(controller: notes, placeholder: 'Notes optional', maxLines: 2),\n""",
    r'''          const SizedBox(height: 8),
          FutureBuilder<GrowTimeEstimate>(
            future: growTimeEstimate,
            builder: (context, snapshot) {
              final estimate = snapshot.data;
              if (estimate == null) return const SizedBox.shrink();
              return Text(
                estimate.note,
                style: const TextStyle(
                  color: C.muted,
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Field(controller: notes, placeholder: 'Notes optional', maxLines: 2),
''',
    'grow estimate note',
)

path.write_text(text, encoding='utf-8')

print('Seedling grow-time API enrichment patch applied.')
'@

Write-Host "`n== Apply Python patch =="
$py | python -

Write-Host "`n== Format changed Dart files =="
dart format .\lib\main.dart `
  .\lib\features\seedlings\data\grow_time_service.dart `
  .\lib\features\seedlings\presentation\seedlings_screen.dart

Write-Host "`n== Analyze =="
flutter analyze

Write-Host "`n== Build debug APK =="
flutter build apk --debug

Write-Host "`n== Commit and push =="
git add lib/main.dart `
  lib/features/seedlings/data/grow_time_service.dart `
  lib/features/seedlings/presentation/seedlings_screen.dart `
  tools/apply_seedling_grow_time_api.ps1

git commit -m "Add seedling grow time API enrichment"
git push origin main

Write-Host "`n== Done =="
git status --short

Write-Host "`n== Optional API key build =="
Write-Host "flutter build apk --debug --dart-define=PERENUAL_API_KEY=YOUR_KEY_HERE"
