import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/spray_condition.dart';

class OpenMeteoService {
  OpenMeteoService({http.Client? client}) : _client = client ?? http.Client();

  static final OpenMeteoService instance = OpenMeteoService();

  static const blenheimLatitude = -41.5134;
  static const blenheimLongitude = 173.9612;
  static const blenheimTimezone = 'Pacific/Auckland';

  final http.Client _client;

  Future<SprayConditionSummary> getBlenheimSprayConditions() async {
    final hours = await getBlenheimForecastHours();
    return summarizeSprayConditions(hours);
  }

  Future<GardenRiskSummary> getBlenheimGardenRisks() async {
    final hours = await getBlenheimForecastHours();
    return summarizeGardenRisks(hours);
  }

  Future<List<SprayForecastHour>> getBlenheimForecastHours() async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$blenheimLatitude',
      'longitude': '$blenheimLongitude',
      'hourly':
          'temperature_2m,precipitation,precipitation_probability,wind_speed_10m',
      'forecast_days': '3',
      'timezone': blenheimTimezone,
    });
    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Open-Meteo returned ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Open-Meteo response was not an object.');
    }

    final hourly = decoded['hourly'];
    if (hourly is! Map<String, dynamic>) {
      throw const FormatException('Open-Meteo response missed hourly data.');
    }

    final hours = _parseHours(hourly);
    final now = DateTime.now();
    final upcoming = hours
        .where(
            (hour) => hour.time.isAfter(now.subtract(const Duration(hours: 1))))
        .take(48)
        .toList(growable: false);
    if (upcoming.isEmpty) {
      throw const FormatException('Open-Meteo forecast had no upcoming hours.');
    }

    return upcoming;
  }

  List<SprayForecastHour> _parseHours(Map<String, dynamic> hourly) {
    final times = hourly['time'];
    final temperatures = hourly['temperature_2m'];
    final precipitation = hourly['precipitation'];
    final precipitationProbability = hourly['precipitation_probability'];
    final wind = hourly['wind_speed_10m'];
    if (times is! List ||
        temperatures is! List ||
        precipitation is! List ||
        precipitationProbability is! List ||
        wind is! List) {
      throw const FormatException('Open-Meteo hourly arrays were incomplete.');
    }

    final length = [
      times.length,
      temperatures.length,
      precipitation.length,
      precipitationProbability.length,
      wind.length,
    ].reduce((shortest, next) => shortest < next ? shortest : next);

    return List.generate(length, (index) {
      final time = DateTime.tryParse(times[index].toString());
      if (time == null) {
        throw FormatException('Invalid forecast time at index $index.');
      }

      return SprayForecastHour(
        time: time,
        temperatureC: _number(temperatures[index]),
        windKph: _number(wind[index]),
        precipitationMm: _number(precipitation[index]),
        precipitationProbability: _number(precipitationProbability[index]),
      );
    }, growable: false);
  }

  double _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
