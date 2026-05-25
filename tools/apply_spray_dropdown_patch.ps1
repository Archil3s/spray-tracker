Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "`n== Spray Tracker: apply dropdown-menu Spray Log patch =="

if (!(Test-Path ".\pubspec.yaml")) {
  throw "Run this from the spray-tracker repo root."
}

$target = ".\lib\features\spray\presentation\pages\spray_screens.dart"
$backup = ".\lib\features\spray\presentation\pages\spray_screens.before-dropdowns.bak"

Write-Host "`n== Backup =="
Copy-Item $target $backup -Force

$py = @'
from pathlib import Path

path = Path("lib/features/spray/presentation/pages/spray_screens.dart")
text = path.read_text(encoding="utf-8")
original = text

text = text.replace(
"""  String targetId = 'pest';
  SprayProduct? selectedProduct;
  int days = 0;
  final reason = TextEditingController();
  final notes = TextEditingController();
""",
"""  String targetId = 'pest';
  String? selectedIssue;
  String selectedActionTaken = 'Sprayed selected product';
  SprayProduct? selectedProduct;
  int days = 0;
  final notes = TextEditingController();
"""
)

text = text.replace(
"""  void dispose() {
    reason.dispose();
    notes.dispose();
    super.dispose();
  }
""",
"""  void dispose() {
    notes.dispose();
    super.dispose();
  }
"""
)

text = text.replace(
"""    final issue = reason.text.trim().isEmpty && issueSuggestions.isNotEmpty
        ? issueSuggestions.first.issue
        : reason.text.trim();
""",
"""    final issueOptions = _sprayIssueOptions(
      targetId: targetId,
      crops: cropDefinitions,
      suggestions: issueSuggestions,
    );
    final issue = selectedIssue != null && issueOptions.contains(selectedIssue)
        ? selectedIssue!
        : issueOptions.isNotEmpty
            ? issueOptions.first
            : '';
    final actionOptions = _sprayActionOptions(targetId);
    final actionTaken = actionOptions.contains(selectedActionTaken)
        ? selectedActionTaken
        : actionOptions.first;
"""
)

text = text.replace(
"""        TargetGrid(
          selected: targetId,
          onSelect: (id) => setState(() {
            targetId = id;
            if (widget.products.isNotEmpty) {
              _selectProduct(_bestProductForCurrentTarget());
            }
          }),
        ),
""",
"""        TargetGrid(
          selected: targetId,
          onSelect: (id) => setState(() {
            targetId = id;
            selectedIssue = null;
            selectedActionTaken = _sprayActionOptions(id).first;
            if (widget.products.isNotEmpty) {
              _selectProduct(_bestProductForCurrentTarget());
            }
          }),
        ),
"""
)

text = text.replace(
"""        _SprayAgainstSuggestionsPanel(
          suggestions: issueSuggestions,
          onUse: (suggestion) => setState(() {
            targetId = suggestion.targetId;
            reason.text = suggestion.issue;
            if (suggestion.product != null) {
              _selectProduct(suggestion.product!);
            } else if (widget.products.isNotEmpty) {
              _selectProduct(
                _bestProductForCurrentTarget(issue: suggestion.issue),
              );
            }
          }),
        ),
""",
"""        _SprayAgainstSuggestionsPanel(
          suggestions: issueSuggestions,
          onUse: (suggestion) => setState(() {
            targetId = suggestion.targetId;
            selectedIssue = suggestion.issue;
            selectedActionTaken = _sprayActionOptions(suggestion.targetId).first;
            if (suggestion.product != null) {
              _selectProduct(suggestion.product!);
            } else if (widget.products.isNotEmpty) {
              _selectProduct(
                _bestProductForCurrentTarget(issue: suggestion.issue),
              );
            }
          }),
        ),
"""
)

text = text.replace(
"""        const SizedBox(height: 18),
        Field(
          controller: reason,
          placeholder: 'Issue or reason, e.g. aphids on tomato tips',
        ),
        const SizedBox(height: 8),
        Field(controller: notes, placeholder: 'Notes optional', maxLines: 3),
""",
"""        const SizedBox(height: 18),
        _SprayDropdownCard(
          title: 'Issue / reason',
          value: issue.isEmpty ? 'Select issue' : issue,
          icon: CupertinoIcons.exclamationmark_circle,
          options: issueOptions,
          emptyText: 'Select planted beds first. The app will build choices from the crops in those beds.',
          onSelected: (value) {
            setState(() {
              selectedIssue = value;
              if (widget.products.isNotEmpty) {
                _selectProduct(_bestProductForCurrentTarget(issue: value));
              }
            });
          },
        ),
        const SizedBox(height: 8),
        _SprayDropdownCard(
          title: 'Action taken',
          value: actionTaken,
          icon: CupertinoIcons.checkmark_circle,
          options: actionOptions,
          emptyText: 'No actions available.',
          onSelected: (value) => setState(() => selectedActionTaken = value),
        ),
        const SizedBox(height: 8),
        Field(controller: notes, placeholder: 'Notes optional', maxLines: 3),
"""
)

text = text.replace(
"""                    reason: reason.text,
                    notes: notes.text,
""",
"""                    reason: issue,
                    notes: _sprayNotesWithAction(
                      actionTaken: actionTaken,
                      notes: notes.text,
                    ),
"""
)

insert = r'''
List<String> _sprayIssueOptions({
  required String targetId,
  required List<VegetableDefinition> crops,
  required List<SprayIssueSuggestion> suggestions,
}) {
  final values = <String>{};

  for (final suggestion in suggestions) {
    final issue = suggestion.issue.trim();
    if (issue.isNotEmpty) values.add(issue);
  }

  for (final crop in crops) {
    final source = switch (targetId) {
      'fungus' => crop.commonDiseases,
      'maintain' => crop.maintenanceTips,
      'prevent' => [
          ...crop.commonPests.take(3),
          ...crop.commonDiseases.take(3),
          ...crop.preventativeTips.take(3),
        ],
      _ => crop.commonPests,
    };

    for (final item in source) {
      final clean = item.trim();
      if (clean.isNotEmpty) values.add(clean);
    }
  }

  if (values.isEmpty) {
    values.addAll(
      switch (targetId) {
        'fungus' => const [
            'Powdery mildew',
            'Leaf spot',
            'Blight',
            'Botrytis',
            'Damping off',
          ],
        'maintain' => const [
            'General plant health',
            'Plant stress',
            'Feeding support',
            'Growth support',
          ],
        'prevent' => const [
            'Preventative spray',
            'Routine protection',
            'Before disease pressure',
            'Before pest pressure',
          ],
        _ => const [
            'Aphids',
            'Whitefly',
            'Thrips',
            'Mites',
            'Caterpillars',
            'Slugs / snails',
          ],
      },
    );
  }

  final result = values.toList()..sort();
  return result;
}

List<String> _sprayActionOptions(String targetId) => switch (targetId) {
      'fungus' => const [
          'Sprayed selected product',
          'Removed affected leaves',
          'Improved airflow',
          'Stopped overhead watering',
          'Observed only',
        ],
      'maintain' => const [
          'Fed plants',
          'Watered deeply',
          'Mulched bed',
          'Pruned / tidied plants',
          'Observed only',
        ],
      'prevent' => const [
          'Preventative spray applied',
          'Checked leaves',
          'Removed risky leaves',
          'Improved airflow',
          'Observed only',
        ],
      _ => const [
          'Sprayed selected product',
          'Hosed pests off',
          'Hand removed pests',
          'Removed affected leaves',
          'Set trap / barrier',
          'Observed only',
        ],
    };

String _sprayNotesWithAction({
  required String actionTaken,
  required String notes,
}) {
  final cleanNotes = notes.trim();
  if (cleanNotes.isEmpty) return 'Action: $actionTaken';
  return 'Action: $actionTaken\n$cleanNotes';
}

class _SprayDropdownCard extends StatelessWidget {
  const _SprayDropdownCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.options,
    required this.emptyText,
    required this.onSelected,
  });

  final String title;
  final String value;
  final IconData icon;
  final List<String> options;
  final String emptyText;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SmoothTap(
      onTap: options.isEmpty ? null : () => _showOptions(context),
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
                    options.isEmpty ? emptyText : value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: options.isEmpty ? C.muted : C.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(CupertinoIcons.chevron_down, color: C.muted, size: 18),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(title),
        message: Text('${options.length} choices available'),
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

'''

marker = "class ProductsScreen extends StatefulWidget"
if insert.strip() not in text:
    text = text.replace(marker, insert + "\n" + marker)

if text == original:
    raise SystemExit("No changes made. The file may already be patched or has changed structure.")

path.write_text(text, encoding="utf-8")
print("Patched spray_screens.dart")
'@

Write-Host "`n== Apply patch =="
$py | python -

Write-Host "`n== Format =="
dart format $target

Write-Host "`n== Analyze =="
flutter analyze

Write-Host "`n== Build debug APK =="
flutter build apk --debug

Write-Host "`n== Commit and push =="
git add $target tools/apply_spray_dropdown_patch.ps1
git commit -m "Replace Spray Log text fields with dropdown choices"
git push origin main

Write-Host "`n== Done =="
git status --short
