import 'crop_catalog.dart';
import 'weather_service.dart';

class CropRecommendationRequest {
  const CropRecommendationRequest({
    required this.district,
    required this.soil,
    required this.season,
    required this.waterSource,
    required this.acres,
  });

  final String district;
  final String soil;
  final String season;
  final String waterSource;
  final double acres;
}

class CropRecommendationItem {
  const CropRecommendationItem({
    required this.crop,
    required this.score,
    required this.expectedYield,
    required this.investment,
    required this.revenue,
    required this.expectedProfit,
    required this.riskLevel,
    required this.waterRequirement,
    required this.reasons,
  });

  final CropProfile crop;
  final int score;
  final double expectedYield;
  final double investment;
  final double revenue;
  final double expectedProfit;
  final String riskLevel;
  final String waterRequirement;
  final List<String> reasons;
}

class CropRecommendationBundle {
  const CropRecommendationBundle({
    required this.request,
    required this.rankedCrops,
    required this.liveWeatherUsed,
  });

  final CropRecommendationRequest request;
  final List<CropRecommendationItem> rankedCrops;
  final bool liveWeatherUsed;

  CropRecommendationItem get best => rankedCrops.first;
}

abstract final class CropRecommendationService {
  static const districts = <String>[
    'Ampara',
    'Anuradhapura',
    'Badulla',
    'Batticaloa',
    'Colombo',
    'Galle',
    'Gampaha',
    'Hambantota',
    'Jaffna',
    'Kalutara',
    'Kandy',
    'Kegalle',
    'Kilinochchi',
    'Kurunegala',
    'Mannar',
    'Matale',
    'Matara',
    'Monaragala',
    'Mullaitivu',
    'Nuwara Eliya',
    'Polonnaruwa',
    'Puttalam',
    'Ratnapura',
    'Trincomalee',
    'Vavuniya',
  ];

  static const _sandyCrops = <String>{
    'Chilli',
    'Coconut',
    'Cucumber',
    'Grapes',
    'Groundnut',
    'Maize',
    'Mango',
    'Okra',
    'Onion',
    'Pineapple',
    'Pumpkin',
  };
  static const _clayCrops = <String>{
    'Banana',
    'Cabbage',
    'Rice',
    'Sugarcane',
    'Tea',
  };
  static const _rainyCrops = <String>{
    'Banana',
    'Coconut',
    'Coffee',
    'Lemon',
    'Papaya',
    'Pineapple',
    'Rice',
    'Sugarcane',
    'Tea',
  };
  static const _dryCrops = <String>{
    'Chilli',
    'Cucumber',
    'Grapes',
    'Groundnut',
    'Maize',
    'Mango',
    'Okra',
    'Onion',
    'Pumpkin',
    'Tomato',
  };

  static const _hillDistricts = <String>{
    'Badulla',
    'Kandy',
    'Matale',
    'Nuwara Eliya',
  };
  static const _wetDistricts = <String>{
    'Colombo',
    'Galle',
    'Gampaha',
    'Kalutara',
    'Kegalle',
    'Matara',
    'Ratnapura',
  };
  static const _hillCrops = <String>{
    'Apple',
    'Bean',
    'Cabbage',
    'Coffee',
    'Potato',
    'Tea',
    'Tomato',
  };
  static const _wetCrops = <String>{
    'Banana',
    'Coconut',
    'Coffee',
    'Papaya',
    'Pineapple',
    'Rice',
    'Tea',
  };
  static const _dryZoneCrops = <String>{
    'Chilli',
    'Groundnut',
    'Maize',
    'Mango',
    'Okra',
    'Onion',
    'Rice',
    'Sugarcane',
  };

  static CropRecommendationBundle recommend(
    CropRecommendationRequest request, {
    WeatherReport? weather,
  }) {
    final weatherScores = weather == null
        ? const <String, int>{}
        : {
            for (final item in CropCatalog.forWeek(weather.days))
              item.crop.name: item.score,
          };

    final ranked = CropCatalog.crops.map((crop) {
      final weatherScore = weatherScores[crop.name] ?? 62;
      final soilScore = _soilScore(crop.name, request.soil);
      final seasonScore = _seasonScore(crop.name, request.season);
      final waterScore = _waterScore(crop, request.waterSource);
      final districtScore = _districtScore(crop.name, request.district);
      final score =
          (weatherScore * 0.55 +
                  soilScore +
                  seasonScore +
                  waterScore +
                  districtScore)
              .clamp(0, 98)
              .round();

      final investmentPerAcre =
          crop.seedCostPerAcre +
          crop.fertilizerCostPerAcre +
          crop.labourCostPerAcre;
      final yieldFactor = 0.72 + score / 300;
      final expectedYield = crop.yieldPerAcre * request.acres * yieldFactor;
      final investment = investmentPerAcre * request.acres;
      final revenue = expectedYield * crop.pricePerUnit;
      final expectedProfit = revenue - investment;

      return CropRecommendationItem(
        crop: crop,
        score: score,
        expectedYield: expectedYield,
        investment: investment,
        revenue: revenue,
        expectedProfit: expectedProfit,
        riskLevel: score >= 78
            ? 'Low'
            : score >= 58
            ? 'Medium'
            : 'High',
        waterRequirement: _waterRequirement(crop),
        reasons: [
          'Soil condition matches this crop.',
          'Season and water source match this crop.',
          weather == null
              ? 'District crop pattern was included.'
              : 'Live 7-day weather was included.',
        ],
      );
    }).toList()..sort((a, b) => b.score.compareTo(a.score));

    return CropRecommendationBundle(
      request: request,
      rankedCrops: List.unmodifiable(ranked),
      liveWeatherUsed: weather != null,
    );
  }

  static double _soilScore(String crop, String soil) {
    if (soil == 'Loamy') return 14;
    final matches = soil == 'Sandy'
        ? _sandyCrops.contains(crop)
        : _clayCrops.contains(crop);
    return matches ? 15 : 5;
  }

  static double _seasonScore(String crop, String season) {
    final matches = season == 'Rainy Season'
        ? _rainyCrops.contains(crop)
        : _dryCrops.contains(crop);
    return matches ? 12 : 6;
  }

  static double _waterScore(CropProfile crop, String waterSource) {
    if (waterSource == 'Irrigation') return 10;
    final requirement = _waterRequirement(crop);
    if (waterSource == 'Rain Water') {
      return requirement == 'High' ? 10 : 6;
    }
    return requirement == 'Low'
        ? 10
        : requirement == 'Medium'
        ? 8
        : 3;
  }

  static double _districtScore(String crop, String district) {
    final preferred = _hillDistricts.contains(district)
        ? _hillCrops
        : _wetDistricts.contains(district)
        ? _wetCrops
        : _dryZoneCrops;
    return preferred.contains(crop) ? 8 : 3;
  }

  static String _waterRequirement(CropProfile crop) {
    if (crop.minimumRainChance >= 45) return 'High';
    if (crop.maximumRainChance <= 50) return 'Low';
    return 'Medium';
  }
}
