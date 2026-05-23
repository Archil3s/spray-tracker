enum SprayConditionKind { good, wind, rain, heat, cool }

enum GardenRiskLevel { low, moderate, high }

class SprayForecastHour {
  const SprayForecastHour({
    required this.time,
    required this.temperatureC,
    required this.windKph,
    required this.precipitationMm,
    required this.precipitationProbability,
  });

  final DateTime time;
  final double temperatureC;
  final double windKph;
  final double precipitationMm;
  final double precipitationProbability;
}

class SprayWindow {
  const SprayWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class SprayWindowReminderPlan {
  const SprayWindowReminderPlan({
    required this.window,
    required this.notifyAt,
  });

  final SprayWindow window;
  final DateTime notifyAt;
}

class SprayConditionSummary {
  const SprayConditionSummary({
    required this.kind,
    required this.currentHour,
    required this.rainWithinSixHours,
    required this.nextGoodWindow,
  });

  final SprayConditionKind kind;
  final SprayForecastHour currentHour;
  final bool rainWithinSixHours;
  final SprayWindow? nextGoodWindow;
}

class GardenRiskSummary {
  const GardenRiskSummary({
    required this.frostRisk,
    required this.soilEvaporationRisk,
    required this.pestPressureRisk,
    required this.lowestTemperatureC,
    required this.peakTemperatureC,
    required this.peakWindKph,
    required this.rainNext24HoursMm,
  });

  final GardenRiskLevel frostRisk;
  final GardenRiskLevel soilEvaporationRisk;
  final GardenRiskLevel pestPressureRisk;
  final double lowestTemperatureC;
  final double peakTemperatureC;
  final double peakWindKph;
  final double rainNext24HoursMm;
}

SprayConditionSummary summarizeSprayConditions(
  List<SprayForecastHour> hours,
) {
  if (hours.isEmpty) {
    throw ArgumentError.value(hours, 'hours', 'Forecast cannot be empty.');
  }

  final rainSoon = _rainWithinSixHours(hours, 0);
  final current = hours.first;
  final kind = current.windKph >= 15
      ? SprayConditionKind.wind
      : rainSoon
          ? SprayConditionKind.rain
          : current.temperatureC > 28
              ? SprayConditionKind.heat
              : current.temperatureC < 10
                  ? SprayConditionKind.cool
                  : SprayConditionKind.good;

  return SprayConditionSummary(
    kind: kind,
    currentHour: current,
    rainWithinSixHours: rainSoon,
    nextGoodWindow: nextGoodSprayWindow(hours),
  );
}

GardenRiskSummary summarizeGardenRisks(List<SprayForecastHour> hours) {
  if (hours.isEmpty) {
    throw ArgumentError.value(hours, 'hours', 'Forecast cannot be empty.');
  }

  final next24 = hours.take(24).toList(growable: false);
  final lowestTemperature = _lowest(hours, (hour) => hour.temperatureC);
  final peakTemperature = _highest(hours, (hour) => hour.temperatureC);
  final peakWind = _highest(hours, (hour) => hour.windKph);
  final rainNext24 = _sum(next24, (hour) => hour.precipitationMm);
  final wetHours = hours
      .where(
        (hour) =>
            hour.precipitationMm >= 0.2 || hour.precipitationProbability >= 45,
      )
      .length;
  final mildHours = hours
      .where((hour) => hour.temperatureC >= 12 && hour.temperatureC <= 26)
      .length;

  final frostRisk = lowestTemperature <= 0
      ? GardenRiskLevel.high
      : lowestTemperature <= 2
          ? GardenRiskLevel.moderate
          : GardenRiskLevel.low;

  final dryNext24 = rainNext24 < 1;
  final soilEvaporationRisk =
      dryNext24 && (peakTemperature >= 24 || peakWind >= 20)
          ? GardenRiskLevel.high
          : dryNext24 && (peakTemperature >= 18 || peakWind >= 12)
              ? GardenRiskLevel.moderate
              : GardenRiskLevel.low;

  final pestPressureRisk = mildHours >= hours.length ~/ 2 && wetHours >= 8
      ? GardenRiskLevel.high
      : mildHours >= hours.length ~/ 3 && wetHours >= 3
          ? GardenRiskLevel.moderate
          : GardenRiskLevel.low;

  return GardenRiskSummary(
    frostRisk: frostRisk,
    soilEvaporationRisk: soilEvaporationRisk,
    pestPressureRisk: pestPressureRisk,
    lowestTemperatureC: lowestTemperature,
    peakTemperatureC: peakTemperature,
    peakWindKph: peakWind,
    rainNext24HoursMm: rainNext24,
  );
}

SprayWindow? nextGoodSprayWindow(List<SprayForecastHour> hours) {
  for (var start = 0; start < hours.length; start++) {
    if (!_isGoodSprayHour(hours, start)) continue;

    var end = start + 1;
    while (end < hours.length && _isGoodSprayHour(hours, end)) {
      end++;
    }

    if (end - start >= 2) {
      return SprayWindow(
        start: hours[start].time,
        end: hours[end - 1].time.add(const Duration(hours: 1)),
      );
    }

    start = end - 1;
  }

  return null;
}

SprayWindowReminderPlan? planSprayWindowReminder(
  SprayWindow? window, {
  required DateTime now,
}) {
  if (window == null || !window.start.isAfter(now)) {
    return null;
  }

  final today = DateTime(now.year, now.month, now.day);
  final windowDay = DateTime(
    window.start.year,
    window.start.month,
    window.start.day,
  );
  final dayOffset = windowDay.difference(today).inDays;
  if (dayOffset == 1) {
    final eveningHeadsUp = today.add(const Duration(hours: 19));
    if (eveningHeadsUp.isAfter(now)) {
      return SprayWindowReminderPlan(
        window: window,
        notifyAt: eveningHeadsUp,
      );
    }

    final leadReminder = window.start.subtract(_leadTime);
    if (leadReminder.isAfter(now)) {
      return SprayWindowReminderPlan(window: window, notifyAt: leadReminder);
    }

    return null;
  }

  final leadReminder = window.start.subtract(_leadTime);
  if (dayOffset == 0 && leadReminder.isAfter(now)) {
    return SprayWindowReminderPlan(window: window, notifyAt: leadReminder);
  }

  return null;
}

bool _isGoodSprayHour(List<SprayForecastHour> hours, int index) {
  final hour = hours[index];
  return hour.windKph < 15 &&
      hour.temperatureC >= 10 &&
      hour.temperatureC <= 28 &&
      !_rainWithinSixHours(hours, index);
}

bool _rainWithinSixHours(List<SprayForecastHour> hours, int index) {
  final end = (index + 6).clamp(0, hours.length);
  for (var next = index; next < end; next++) {
    if (hours[next].precipitationMm > 0) {
      return true;
    }
  }
  return false;
}

double _highest(
  Iterable<SprayForecastHour> hours,
  double Function(SprayForecastHour hour) valueOf,
) {
  var value = valueOf(hours.first);
  for (final hour in hours.skip(1)) {
    final next = valueOf(hour);
    if (next > value) value = next;
  }
  return value;
}

double _lowest(
  Iterable<SprayForecastHour> hours,
  double Function(SprayForecastHour hour) valueOf,
) {
  var value = valueOf(hours.first);
  for (final hour in hours.skip(1)) {
    final next = valueOf(hour);
    if (next < value) value = next;
  }
  return value;
}

double _sum(
  Iterable<SprayForecastHour> hours,
  double Function(SprayForecastHour hour) valueOf,
) {
  var total = 0.0;
  for (final hour in hours) {
    total += valueOf(hour);
  }
  return total;
}

const _leadTime = Duration(minutes: 30);
