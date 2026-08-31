import 'weather_service.dart';

class CropProfile {
  const CropProfile({
    required this.name,
    required this.emoji,
    required this.minimumTemperature,
    required this.maximumTemperature,
    required this.minimumRainChance,
    required this.maximumRainChance,
    required this.seedCostPerAcre,
    required this.fertilizerCostPerAcre,
    required this.labourCostPerAcre,
    required this.yieldPerAcre,
    required this.pricePerUnit,
  });

  final String name;
  final String emoji;
  final double minimumTemperature;
  final double maximumTemperature;
  final int minimumRainChance;
  final int maximumRainChance;
  final double seedCostPerAcre;
  final double fertilizerCostPerAcre;
  final double labourCostPerAcre;
  final double yieldPerAcre;
  final double pricePerUnit;
}

class CropSuitability {
  const CropSuitability(this.crop, this.score);

  final CropProfile crop;
  final int score;

  String get level {
    if (score >= 78) return 'Highly Suitable';
    if (score >= 62) return 'Suitable';
    if (score >= 45) return 'Moderate';
    return 'Low Suitability';
  }
}

abstract final class CropCatalog {
  static const crops = <CropProfile>[
    CropProfile(
      name: 'Apple',
      emoji: '🍎',
      minimumTemperature: 10,
      maximumTemperature: 24,
      minimumRainChance: 20,
      maximumRainChance: 65,
      seedCostPerAcre: 90000,
      fertilizerCostPerAcre: 75000,
      labourCostPerAcre: 120000,
      yieldPerAcre: 5000,
      pricePerUnit: 520,
    ),
    CropProfile(
      name: 'Banana',
      emoji: '🍌',
      minimumTemperature: 22,
      maximumTemperature: 32,
      minimumRainChance: 45,
      maximumRainChance: 90,
      seedCostPerAcre: 110000,
      fertilizerCostPerAcre: 95000,
      labourCostPerAcre: 130000,
      yieldPerAcre: 8000,
      pricePerUnit: 160,
    ),
    CropProfile(
      name: 'Bean',
      emoji: '🫘',
      minimumTemperature: 18,
      maximumTemperature: 28,
      minimumRainChance: 25,
      maximumRainChance: 65,
      seedCostPerAcre: 40000,
      fertilizerCostPerAcre: 60000,
      labourCostPerAcre: 80000,
      yieldPerAcre: 3000,
      pricePerUnit: 350,
    ),
    CropProfile(
      name: 'Brinjal',
      emoji: '🍆',
      minimumTemperature: 22,
      maximumTemperature: 32,
      minimumRainChance: 25,
      maximumRainChance: 65,
      seedCostPerAcre: 30000,
      fertilizerCostPerAcre: 55000,
      labourCostPerAcre: 75000,
      yieldPerAcre: 7000,
      pricePerUnit: 200,
    ),
    CropProfile(
      name: 'Cabbage',
      emoji: '🥬',
      minimumTemperature: 15,
      maximumTemperature: 25,
      minimumRainChance: 25,
      maximumRainChance: 70,
      seedCostPerAcre: 45000,
      fertilizerCostPerAcre: 70000,
      labourCostPerAcre: 90000,
      yieldPerAcre: 9000,
      pricePerUnit: 190,
    ),
    CropProfile(
      name: 'Chilli',
      emoji: '🌶️',
      minimumTemperature: 20,
      maximumTemperature: 30,
      minimumRainChance: 20,
      maximumRainChance: 55,
      seedCostPerAcre: 45000,
      fertilizerCostPerAcre: 65000,
      labourCostPerAcre: 95000,
      yieldPerAcre: 3500,
      pricePerUnit: 650,
    ),
    CropProfile(
      name: 'Lemon',
      emoji: '🍋',
      minimumTemperature: 20,
      maximumTemperature: 32,
      minimumRainChance: 25,
      maximumRainChance: 70,
      seedCostPerAcre: 80000,
      fertilizerCostPerAcre: 65000,
      labourCostPerAcre: 90000,
      yieldPerAcre: 6000,
      pricePerUnit: 280,
    ),
    CropProfile(
      name: 'Coconut',
      emoji: '🥥',
      minimumTemperature: 24,
      maximumTemperature: 32,
      minimumRainChance: 40,
      maximumRainChance: 90,
      seedCostPerAcre: 100000,
      fertilizerCostPerAcre: 80000,
      labourCostPerAcre: 90000,
      yieldPerAcre: 3200,
      pricePerUnit: 130,
    ),
    CropProfile(
      name: 'Coffee',
      emoji: '☕',
      minimumTemperature: 18,
      maximumTemperature: 28,
      minimumRainChance: 40,
      maximumRainChance: 85,
      seedCostPerAcre: 90000,
      fertilizerCostPerAcre: 75000,
      labourCostPerAcre: 110000,
      yieldPerAcre: 1800,
      pricePerUnit: 900,
    ),
    CropProfile(
      name: 'Cucumber',
      emoji: '🥒',
      minimumTemperature: 22,
      maximumTemperature: 32,
      minimumRainChance: 20,
      maximumRainChance: 60,
      seedCostPerAcre: 35000,
      fertilizerCostPerAcre: 50000,
      labourCostPerAcre: 70000,
      yieldPerAcre: 7500,
      pricePerUnit: 170,
    ),
    CropProfile(
      name: 'Grapes',
      emoji: '🍇',
      minimumTemperature: 20,
      maximumTemperature: 32,
      minimumRainChance: 10,
      maximumRainChance: 45,
      seedCostPerAcre: 160000,
      fertilizerCostPerAcre: 90000,
      labourCostPerAcre: 140000,
      yieldPerAcre: 6500,
      pricePerUnit: 480,
    ),
    CropProfile(
      name: 'Groundnut',
      emoji: '🥜',
      minimumTemperature: 22,
      maximumTemperature: 32,
      minimumRainChance: 15,
      maximumRainChance: 50,
      seedCostPerAcre: 50000,
      fertilizerCostPerAcre: 45000,
      labourCostPerAcre: 65000,
      yieldPerAcre: 1400,
      pricePerUnit: 500,
    ),
    CropProfile(
      name: 'Guava',
      emoji: '🍐',
      minimumTemperature: 20,
      maximumTemperature: 34,
      minimumRainChance: 20,
      maximumRainChance: 70,
      seedCostPerAcre: 75000,
      fertilizerCostPerAcre: 60000,
      labourCostPerAcre: 85000,
      yieldPerAcre: 7000,
      pricePerUnit: 240,
    ),
    CropProfile(
      name: 'Maize',
      emoji: '🌽',
      minimumTemperature: 20,
      maximumTemperature: 32,
      minimumRainChance: 20,
      maximumRainChance: 65,
      seedCostPerAcre: 35000,
      fertilizerCostPerAcre: 50000,
      labourCostPerAcre: 65000,
      yieldPerAcre: 2200,
      pricePerUnit: 170,
    ),
    CropProfile(
      name: 'Mango',
      emoji: '🥭',
      minimumTemperature: 24,
      maximumTemperature: 34,
      minimumRainChance: 10,
      maximumRainChance: 55,
      seedCostPerAcre: 100000,
      fertilizerCostPerAcre: 70000,
      labourCostPerAcre: 95000,
      yieldPerAcre: 6500,
      pricePerUnit: 260,
    ),
    CropProfile(
      name: 'Okra',
      emoji: '🌿',
      minimumTemperature: 24,
      maximumTemperature: 35,
      minimumRainChance: 20,
      maximumRainChance: 65,
      seedCostPerAcre: 30000,
      fertilizerCostPerAcre: 45000,
      labourCostPerAcre: 65000,
      yieldPerAcre: 4500,
      pricePerUnit: 230,
    ),
    CropProfile(
      name: 'Onion',
      emoji: '🧅',
      minimumTemperature: 18,
      maximumTemperature: 30,
      minimumRainChance: 10,
      maximumRainChance: 45,
      seedCostPerAcre: 70000,
      fertilizerCostPerAcre: 65000,
      labourCostPerAcre: 90000,
      yieldPerAcre: 6000,
      pricePerUnit: 280,
    ),
    CropProfile(
      name: 'Papaya',
      emoji: '🍈',
      minimumTemperature: 22,
      maximumTemperature: 33,
      minimumRainChance: 25,
      maximumRainChance: 70,
      seedCostPerAcre: 60000,
      fertilizerCostPerAcre: 60000,
      labourCostPerAcre: 80000,
      yieldPerAcre: 9000,
      pricePerUnit: 190,
    ),
    CropProfile(
      name: 'Pineapple',
      emoji: '🍍',
      minimumTemperature: 20,
      maximumTemperature: 32,
      minimumRainChance: 25,
      maximumRainChance: 75,
      seedCostPerAcre: 130000,
      fertilizerCostPerAcre: 75000,
      labourCostPerAcre: 110000,
      yieldPerAcre: 10000,
      pricePerUnit: 210,
    ),
    CropProfile(
      name: 'Potato',
      emoji: '🥔',
      minimumTemperature: 15,
      maximumTemperature: 24,
      minimumRainChance: 20,
      maximumRainChance: 60,
      seedCostPerAcre: 120000,
      fertilizerCostPerAcre: 90000,
      labourCostPerAcre: 120000,
      yieldPerAcre: 6500,
      pricePerUnit: 320,
    ),
    CropProfile(
      name: 'Pumpkin',
      emoji: '🎃',
      minimumTemperature: 22,
      maximumTemperature: 33,
      minimumRainChance: 20,
      maximumRainChance: 65,
      seedCostPerAcre: 30000,
      fertilizerCostPerAcre: 45000,
      labourCostPerAcre: 60000,
      yieldPerAcre: 7000,
      pricePerUnit: 160,
    ),
    CropProfile(
      name: 'Rice',
      emoji: '🌾',
      minimumTemperature: 22,
      maximumTemperature: 34,
      minimumRainChance: 50,
      maximumRainChance: 100,
      seedCostPerAcre: 30000,
      fertilizerCostPerAcre: 45000,
      labourCostPerAcre: 65000,
      yieldPerAcre: 1800,
      pricePerUnit: 120,
    ),
    CropProfile(
      name: 'Sugarcane',
      emoji: '🎋',
      minimumTemperature: 22,
      maximumTemperature: 34,
      minimumRainChance: 35,
      maximumRainChance: 85,
      seedCostPerAcre: 80000,
      fertilizerCostPerAcre: 70000,
      labourCostPerAcre: 100000,
      yieldPerAcre: 25000,
      pricePerUnit: 18,
    ),
    CropProfile(
      name: 'Tea',
      emoji: '🍃',
      minimumTemperature: 18,
      maximumTemperature: 28,
      minimumRainChance: 50,
      maximumRainChance: 95,
      seedCostPerAcre: 90000,
      fertilizerCostPerAcre: 80000,
      labourCostPerAcre: 120000,
      yieldPerAcre: 2500,
      pricePerUnit: 130,
    ),
    CropProfile(
      name: 'Tomato',
      emoji: '🍅',
      minimumTemperature: 18,
      maximumTemperature: 29,
      minimumRainChance: 15,
      maximumRainChance: 55,
      seedCostPerAcre: 45000,
      fertilizerCostPerAcre: 65000,
      labourCostPerAcre: 90000,
      yieldPerAcre: 8000,
      pricePerUnit: 180,
    ),
  ];

  static CropProfile byName(String name) {
    return crops.firstWhere((crop) => crop.name == name);
  }

  static List<CropSuitability> forDay(WeatherDay day) {
    final ranked =
        crops.map((crop) => CropSuitability(crop, score(crop, day))).toList()
          ..sort((a, b) => b.score.compareTo(a.score));
    return List.unmodifiable(ranked);
  }

  static List<CropSuitability> forWeek(List<WeatherDay> days) {
    if (days.isEmpty) return const [];
    final ranked = crops.map((crop) {
      final total = days.fold<int>(0, (sum, day) => sum + score(crop, day));
      return CropSuitability(crop, (total / days.length).round());
    }).toList()..sort((a, b) => b.score.compareTo(a.score));
    return List.unmodifiable(ranked);
  }

  static int score(CropProfile crop, WeatherDay day) {
    final averageTemperature =
        (day.maximumTemperature + day.minimumTemperature) / 2;
    var temperatureScore = 55.0;
    if (averageTemperature < crop.minimumTemperature) {
      temperatureScore -= (crop.minimumTemperature - averageTemperature) * 7.5;
    } else if (averageTemperature > crop.maximumTemperature) {
      temperatureScore -= (averageTemperature - crop.maximumTemperature) * 7.5;
    } else {
      final midpoint = (crop.minimumTemperature + crop.maximumTemperature) / 2;
      temperatureScore -= (averageTemperature - midpoint).abs() * 1.2;
    }

    var rainScore = 30.0;
    if (day.rainChance < crop.minimumRainChance) {
      rainScore -= (crop.minimumRainChance - day.rainChance) * 0.6;
    } else if (day.rainChance > crop.maximumRainChance) {
      rainScore -= (day.rainChance - crop.maximumRainChance) * 0.7;
    }

    var fieldScore = 15.0;
    if (day.maximumWindSpeed >= 25) fieldScore -= 7;
    if (day.maximumWindSpeed >= 35) fieldScore -= 5;
    if (day.weatherCode >= 95) fieldScore -= 8;

    return (temperatureScore + rainScore + fieldScore).clamp(0, 100).round();
  }
}
