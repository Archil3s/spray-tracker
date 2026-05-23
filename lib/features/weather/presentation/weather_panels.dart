part of '../../../main.dart';

class SprayConditionBanner extends StatelessWidget {
  const SprayConditionBanner({required this.sprayConditions, super.key});

  final Future<SprayConditionSummary> sprayConditions;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SprayConditionSummary>(
      future: sprayConditions,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SprayConditionPanel(
            title: 'Blenheim spray weather',
            body: 'Checking the next 48 hours...',
            color: C.blue,
            background: C.blueSoft,
            loading: true,
          );
        }

        final summary = snapshot.data;
        if (summary == null) {
          return const _SprayConditionPanel(
            title: 'Blenheim spray weather unavailable',
            body: 'Check conditions before applying a product.',
            color: C.muted,
            background: C.greySoft,
          );
        }

        final nextWindow = summary.nextGoodWindow;
        return _SprayConditionPanel(
          title: _sprayConditionTitle(summary.kind),
          body: _sprayConditionBody(summary),
          nextWindow: nextWindow == null
              ? 'No two-hour good spray window in the next 48 hours.'
              : 'Next good window: ${_sprayWindowText(nextWindow)}.',
          color: _sprayConditionColor(summary.kind),
          background: _sprayConditionBackground(summary.kind),
        );
      },
    );
  }
}

class _SprayConditionPanel extends StatelessWidget {
  const _SprayConditionPanel({
    required this.title,
    required this.body,
    required this.color,
    required this.background,
    this.nextWindow,
    this.loading = false,
  });

  final String title;
  final String body;
  final Color color;
  final Color background;
  final String? nextWindow;
  final bool loading;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: loading
                  ? const CupertinoActivityIndicator()
                  : Icon(CupertinoIcons.wind, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: const TextStyle(
                      color: C.ink,
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (nextWindow != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      nextWindow!,
                      style: const TextStyle(
                        color: C.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class GardenRiskPanel extends StatelessWidget {
  const GardenRiskPanel({required this.gardenRisks, super.key});

  final Future<GardenRiskSummary> gardenRisks;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GardenRiskSummary>(
      future: gardenRisks,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _GardenRiskPanelBody(
            title: 'Blenheim garden risks',
            subtitle: 'Checking frost, soil drying, and pest pressure...',
            loading: true,
          );
        }

        final summary = snapshot.data;
        if (summary == null) {
          return const _GardenRiskPanelBody(
            title: 'Garden risk unavailable',
            subtitle: 'Forecast analytics could not be loaded.',
          );
        }

        return _GardenRiskPanelBody(
          title: 'Blenheim garden risks',
          subtitle:
              'Low ${summary.lowestTemperatureC.round()} C | peak ${summary.peakTemperatureC.round()} C | rain ${summary.rainNext24HoursMm.toStringAsFixed(1)} mm',
          risks: [
            _GardenRiskItem('Frost', summary.frostRisk),
            _GardenRiskItem('Soil drying', summary.soilEvaporationRisk),
            _GardenRiskItem('Pest pressure', summary.pestPressureRisk),
          ],
        );
      },
    );
  }
}

class _GardenRiskPanelBody extends StatelessWidget {
  const _GardenRiskPanelBody({
    required this.title,
    required this.subtitle,
    this.risks = const [],
    this.loading = false,
  });

  final String title;
  final String subtitle;
  final List<_GardenRiskItem> risks;
  final bool loading;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: loading
                      ? const CupertinoActivityIndicator()
                      : const Icon(
                          CupertinoIcons.chart_bar_alt_fill,
                          color: C.forest,
                          size: 22,
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: C.forest,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: C.muted,
                          fontSize: 12,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (risks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: risks
                    .map(
                      (risk) => ProductTag(
                        label: '${risk.label}: ${_gardenRiskLabel(risk.level)}',
                        color: _gardenRiskColor(risk.level),
                        background: _gardenRiskBackground(risk.level),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      );
}

class _GardenRiskItem {
  const _GardenRiskItem(this.label, this.level);

  final String label;
  final GardenRiskLevel level;
}

String _sprayConditionTitle(SprayConditionKind kind) => switch (kind) {
      SprayConditionKind.good => 'Good spray window',
      SprayConditionKind.wind => 'Wind warning',
      SprayConditionKind.rain => 'Rain warning',
      SprayConditionKind.heat => 'Heat warning',
      SprayConditionKind.cool => 'Temperature warning',
    };

String _sprayConditionBody(SprayConditionSummary summary) {
  final hour = summary.currentHour;
  final wind = hour.windKph.round();
  final temperature = hour.temperatureC.round();
  return switch (summary.kind) {
    SprayConditionKind.good =>
      'Wind $wind km/h, $temperature C, and no forecast rain in 6 hours.',
    SprayConditionKind.wind =>
      'Wind is $wind km/h. Drift can keep spray off target.',
    SprayConditionKind.rain =>
      'Rain is forecast within 6 hours and can wash product off.',
    SprayConditionKind.heat =>
      '$temperature C now. Copper and sulfur can burn foliage above 28 C.',
    SprayConditionKind.cool =>
      '$temperature C now. Wait for a 10-28 C spray window.',
  };
}

Color _sprayConditionColor(SprayConditionKind kind) => switch (kind) {
      SprayConditionKind.good => C.forest,
      SprayConditionKind.wind => C.red,
      SprayConditionKind.rain => C.blue,
      SprayConditionKind.heat => C.amber,
      SprayConditionKind.cool => C.muted,
    };

Color _sprayConditionBackground(SprayConditionKind kind) => switch (kind) {
      SprayConditionKind.good => C.forestSoft,
      SprayConditionKind.wind => C.redSoft,
      SprayConditionKind.rain => C.blueSoft,
      SprayConditionKind.heat => C.amberSoft,
      SprayConditionKind.cool => C.greySoft,
    };

String _gardenRiskLabel(GardenRiskLevel level) => switch (level) {
      GardenRiskLevel.low => 'Low',
      GardenRiskLevel.moderate => 'Moderate',
      GardenRiskLevel.high => 'High',
    };

Color _gardenRiskColor(GardenRiskLevel level) => switch (level) {
      GardenRiskLevel.low => C.forest,
      GardenRiskLevel.moderate => C.amber,
      GardenRiskLevel.high => C.red,
    };

Color _gardenRiskBackground(GardenRiskLevel level) => switch (level) {
      GardenRiskLevel.low => C.forestSoft,
      GardenRiskLevel.moderate => C.amberSoft,
      GardenRiskLevel.high => C.redSoft,
    };

String _sprayWindowText(SprayWindow window) {
  final start = '${shortDate(window.start)} ${_hourLabel(window.start)}';
  return '$start-${_hourLabel(window.end)}';
}

String _hourLabel(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final suffix = date.hour < 12 ? 'am' : 'pm';
  return '$hour$suffix';
}
