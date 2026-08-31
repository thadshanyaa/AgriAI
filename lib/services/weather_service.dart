import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherDay {
  const WeatherDay({
    required this.date,
    required this.weatherCode,
    required this.maximumTemperature,
    required this.minimumTemperature,
    required this.rainChance,
    required this.maximumWindSpeed,
    required this.uvIndex,
    required this.sunrise,
    required this.sunset,
  });

  final DateTime date;
  final int weatherCode;
  final double maximumTemperature;
  final double minimumTemperature;
  final int rainChance;
  final double maximumWindSpeed;
  final double uvIndex;
  final DateTime sunrise;
  final DateTime sunset;
}

class WeatherReport {
  const WeatherReport({
    required this.district,
    required this.temperature,
    required this.humidity,
    required this.weatherCode,
    required this.windSpeed,
    required this.days,
  });

  final String district;
  final double temperature;
  final int humidity;
  final int weatherCode;
  final double windSpeed;
  final List<WeatherDay> days;

  WeatherDay get today => days.first;
}

abstract final class WeatherService {
  static const _districtCoordinates = <String, (double, double)>{
    'Ampara': (7.2912, 81.6724),
    'Anuradhapura': (8.3114, 80.4037),
    'Badulla': (6.9934, 81.0550),
    'Batticaloa': (7.7170, 81.7000),
    'Colombo': (6.9271, 79.8612),
    'Galle': (6.0329, 80.2168),
    'Gampaha': (7.0840, 80.0098),
    'Hambantota': (6.1429, 81.1212),
    'Jaffna': (9.6615, 80.0255),
    'Kalutara': (6.5854, 79.9607),
    'Kandy': (7.2906, 80.6337),
    'Kegalle': (7.2513, 80.3464),
    'Kilinochchi': (9.3803, 80.3770),
    'Kurunegala': (7.4863, 80.3647),
    'Mannar': (8.9810, 79.9044),
    'Matale': (7.4675, 80.6234),
    'Matara': (5.9549, 80.5550),
    'Monaragala': (6.8728, 81.3507),
    'Mullaitivu': (9.2671, 80.8142),
    'Nuwara Eliya': (6.9497, 80.7891),
    'Polonnaruwa': (7.9403, 81.0188),
    'Puttalam': (8.0362, 79.8283),
    'Ratnapura': (6.6828, 80.3992),
    'Trincomalee': (8.5874, 81.2152),
    'Vavuniya': (8.7542, 80.4982),
  };

  static (double latitude, double longitude) coordinatesFor(
    String requestedDistrict,
  ) {
    return _districtCoordinates[requestedDistrict] ??
        _districtCoordinates['Trincomalee']!;
  }

  static Future<WeatherReport> fetch(String requestedDistrict) async {
    final district = _districtCoordinates.containsKey(requestedDistrict)
        ? requestedDistrict
        : 'Trincomalee';
    final coordinates = coordinatesFor(district);
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${coordinates.$1}',
      'longitude': '${coordinates.$2}',
      'current':
          'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,'
          'precipitation_probability_max,uv_index_max,wind_speed_10m_max',
      'timezone': 'Asia/Colombo',
      'forecast_days': '7',
    });

    final response = await http
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Weather service returned ${response.statusCode}.');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>?;
    final daily = json['daily'] as Map<String, dynamic>?;
    if (current == null || daily == null) {
      throw const FormatException('Weather service returned incomplete data.');
    }

    final times = _strings(daily, 'time');
    final codes = _numbers(daily, 'weather_code');
    final maximums = _numbers(daily, 'temperature_2m_max');
    final minimums = _numbers(daily, 'temperature_2m_min');
    final rainChances = _numbers(daily, 'precipitation_probability_max');
    final windSpeeds = _numbers(daily, 'wind_speed_10m_max');
    final uvIndexes = _numbers(daily, 'uv_index_max');
    final sunrises = _strings(daily, 'sunrise');
    final sunsets = _strings(daily, 'sunset');

    final days = <WeatherDay>[];
    for (var index = 0; index < times.length; index++) {
      days.add(
        WeatherDay(
          date: DateTime.parse(times[index]),
          weatherCode: codes[index].round(),
          maximumTemperature: maximums[index],
          minimumTemperature: minimums[index],
          rainChance: rainChances[index].round(),
          maximumWindSpeed: windSpeeds[index],
          uvIndex: uvIndexes[index],
          sunrise: DateTime.parse(sunrises[index]),
          sunset: DateTime.parse(sunsets[index]),
        ),
      );
    }
    if (days.isEmpty) {
      throw const FormatException('No weather forecast is available.');
    }

    return WeatherReport(
      district: district,
      temperature: _number(current, 'temperature_2m'),
      humidity: _number(current, 'relative_humidity_2m').round(),
      weatherCode: _number(current, 'weather_code').round(),
      windSpeed: _number(current, 'wind_speed_10m'),
      days: List.unmodifiable(days),
    );
  }

  static String condition(int code) {
    if (code == 0) return 'Clear sky';
    if (code == 1) return 'Mainly clear';
    if (code == 2) return 'Partly cloudy';
    if (code == 3) return 'Overcast';
    if (code == 45 || code == 48) return 'Foggy';
    if (code >= 51 && code <= 57) return 'Drizzle';
    if (code >= 61 && code <= 67) return 'Rain';
    if (code >= 80 && code <= 82) return 'Heavy rain';
    if (code >= 95) return 'Thunderstorm';
    return 'Cloudy';
  }

  static double _number(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) return value.toDouble();
    throw FormatException('Missing weather value: $key');
  }

  static List<double> _numbers(Map<String, dynamic> json, String key) {
    final values = json[key];
    if (values is! List) throw FormatException('Missing weather list: $key');
    return values.map((value) => (value as num).toDouble()).toList();
  }

  static List<String> _strings(Map<String, dynamic> json, String key) {
    final values = json[key];
    if (values is! List) throw FormatException('Missing weather list: $key');
    return values.map((value) => value.toString()).toList();
  }
}
