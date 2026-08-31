import 'package:agriai/main.dart';
import 'package:agriai/localization/app_language.dart';
import 'package:agriai/screens/login_screen.dart';
import 'package:agriai/screens/ai_assistant_screen.dart';
import 'package:agriai/screens/profit_planner_screen.dart';
import 'package:agriai/services/crop_catalog.dart';
import 'package:agriai/services/crop_recommendation_service.dart';
import 'package:agriai/services/ai_farming_service.dart';
import 'package:agriai/services/disease_classifier_service.dart';
import 'package:agriai/services/firebase_backend.dart';
import 'package:agriai/services/weather_service.dart';
import 'package:agriai/theme/app_theme.dart';
import 'package:agriai/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLanguageController.current.value = AppLanguage.english;
    AppLanguageController.hasSavedLanguage = false;
    ThemeController.current.value = ThemeMode.light;
  });

  testWidgets('AgriAI launches and opens language selection', (tester) async {
    await tester.pumpWidget(const AgriAIApp());

    expect(
      find.text('Empowering Farmers\nThrough Artificial Intelligence'),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();

    expect(find.text('Choose Language'), findsOneWidget);
    expect(find.text('தமிழ்'), findsOneWidget);
  });

  test(
    'saved Tamil and Sinhala languages load and translate content',
    () async {
      SharedPreferences.setMockInitialValues({'app_language': 'ta'});
      await AppLanguageController.initialize();
      expect(AppLanguageController.current.value, AppLanguage.tamil);
      expect(tr('Weather Advisory'), 'வானிலை ஆலோசனை');

      await AppLanguageController.setLanguage(AppLanguage.sinhala);
      expect(tr('Weather Advisory'), 'කාලගුණ උපදේශනය');
    },
  );

  test(
    'dark mode preference persists and changes the application theme',
    () async {
      await ThemeController.setDarkMode(true);
      expect(ThemeController.current.value, ThemeMode.dark);

      await ThemeController.setDarkMode(false);
      expect(ThemeController.current.value, ThemeMode.light);
    },
  );

  testWidgets('selecting Tamil updates the visible interface', (tester) async {
    await tester.pumpWidget(const AgriAIApp());
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();

    await tester.tap(find.text('தமிழ்'));
    await tester.pump();

    expect(find.text('மொழியைத் தேர்ந்தெடுக்கவும்'), findsOneWidget);
    expect(find.text('தொடரவும்'), findsOneWidget);
  });

  test('phone number is normalized for Firebase password authentication', () {
    expect(
      FirebaseBackend.authEmailForPhone('077 123 4567'),
      '94771234567@phone.agriai.app',
    );
  });

  test('free farming AI prompt follows the selected app language', () {
    final tamilPrompt = AiFarmingService.buildPrompt(
      'நெல் எப்போது நடலாம்?',
      AppLanguage.tamil,
    );
    final sinhalaPrompt = AiFarmingService.buildPrompt(
      'වී වගා කරන්නේ කවදාද?',
      AppLanguage.sinhala,
    );

    expect(tamilPrompt, contains('Respond in Tamil'));
    expect(tamilPrompt, contains('Sri Lankan farmers'));
    expect(sinhalaPrompt, contains('Respond in Sinhala'));
  });

  test('farm map has coordinates for all Sri Lankan district profiles', () {
    for (final district in CropRecommendationService.districts) {
      final coordinates = WeatherService.coordinatesFor(district);
      expect(coordinates.$1, inInclusiveRange(5.0, 10.5));
      expect(coordinates.$2, inInclusiveRange(79.0, 82.5));
    }
  });

  test('all 25 trained crops have weather and profit planning profiles', () {
    expect(CropCatalog.crops, hasLength(25));
    expect(CropCatalog.crops.map((crop) => crop.name).toSet(), hasLength(25));
    for (final crop in CropCatalog.crops) {
      expect(crop.yieldPerAcre, greaterThan(0));
      expect(crop.pricePerUnit, greaterThan(0));
    }

    final day = WeatherDay(
      date: DateTime(2026, 8, 18),
      weatherCode: 2,
      maximumTemperature: 30,
      minimumTemperature: 24,
      rainChance: 45,
      maximumWindSpeed: 14,
      uvIndex: 6,
      sunrise: DateTime(2026, 8, 18, 6),
      sunset: DateTime(2026, 8, 18, 18),
    );
    final ranked = CropCatalog.forDay(day);
    expect(ranked, hasLength(25));
    expect(ranked.first.score, greaterThanOrEqualTo(ranked.last.score));
  });

  test('crop advisory ranks all 25 crops with field and weather data', () {
    final weather = WeatherReport(
      district: 'Trincomalee',
      temperature: 29,
      humidity: 78,
      weatherCode: 2,
      windSpeed: 12,
      days: List.generate(
        7,
        (index) => WeatherDay(
          date: DateTime(2026, 8, 19 + index),
          weatherCode: 2,
          maximumTemperature: 31,
          minimumTemperature: 25,
          rainChance: 55,
          maximumWindSpeed: 14,
          uvIndex: 6,
          sunrise: DateTime(2026, 8, 19 + index, 6),
          sunset: DateTime(2026, 8, 19 + index, 18),
        ),
      ),
    );
    final result = CropRecommendationService.recommend(
      const CropRecommendationRequest(
        district: 'Trincomalee',
        soil: 'Loamy',
        season: 'Rainy Season',
        waterSource: 'Irrigation',
        acres: 2,
      ),
      weather: weather,
    );

    expect(CropRecommendationService.districts, hasLength(25));
    expect(result.rankedCrops, hasLength(25));
    expect(
      result.best.score,
      greaterThanOrEqualTo(result.rankedCrops.last.score),
    );
    expect(result.best.expectedYield, greaterThan(0));
    expect(result.liveWeatherUsed, isTrue);
  });

  test('uncertain disease predictions are rejected as unsupported', () {
    const uncertain = DiseasePrediction(
      rawLabel: 'mango___healthy',
      crop: 'Mango',
      disease: 'Healthy',
      confidence: 0.38,
      topPredictions: [
        DiseasePredictionItem(
          rawLabel: 'mango___healthy',
          crop: 'Mango',
          disease: 'Healthy',
          confidence: 0.38,
        ),
        DiseasePredictionItem(
          rawLabel: 'guava___healthy',
          crop: 'Guava',
          disease: 'Healthy',
          confidence: 0.31,
        ),
      ],
    );
    const confident = DiseasePrediction(
      rawLabel: 'rice___brown_spot',
      crop: 'Rice',
      disease: 'Brown Spot',
      confidence: 0.84,
      topPredictions: [
        DiseasePredictionItem(
          rawLabel: 'rice___brown_spot',
          crop: 'Rice',
          disease: 'Brown Spot',
          confidence: 0.84,
        ),
        DiseasePredictionItem(
          rawLabel: 'rice___healthy',
          crop: 'Rice',
          disease: 'Healthy',
          confidence: 0.08,
        ),
      ],
    );

    expect(uncertain.isUnsupported, isTrue);
    expect(confident.isUnsupported, isFalse);
  });

  test('selected-crop evidence prevents forced wrong disease results', () {
    const weakCropMatch = DiseasePrediction(
      rawLabel: 'mango___healthy',
      crop: 'Mango',
      disease: 'Healthy',
      confidence: 0.82,
      usedExpectedCrop: true,
      cropEvidence: 0.01,
      topPredictions: [
        DiseasePredictionItem(
          rawLabel: 'mango___healthy',
          crop: 'Mango',
          disease: 'Healthy',
          confidence: 0.82,
        ),
        DiseasePredictionItem(
          rawLabel: 'mango___anthracnose',
          crop: 'Mango',
          disease: 'Anthracnose',
          confidence: 0.10,
        ),
      ],
    );
    const goodCropMatch = DiseasePrediction(
      rawLabel: 'mango___healthy',
      crop: 'Mango',
      disease: 'Healthy',
      confidence: 0.72,
      usedExpectedCrop: true,
      cropEvidence: 0.24,
      topPredictions: [
        DiseasePredictionItem(
          rawLabel: 'mango___healthy',
          crop: 'Mango',
          disease: 'Healthy',
          confidence: 0.72,
        ),
        DiseasePredictionItem(
          rawLabel: 'mango___anthracnose',
          crop: 'Mango',
          disease: 'Anthracnose',
          confidence: 0.15,
        ),
      ],
    );

    expect(weakCropMatch.isUnsupported, isTrue);
    expect(goodCropMatch.isUnsupported, isFalse);
  });

  testWidgets('Tamil login and reset dialog fit a narrow phone screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    AppLanguageController.current.value = AppLanguage.tamil;

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('தொலைபேசி எண் அல்லது மின்னஞ்சல்'), findsOneWidget);
    expect(find.text('மறந்துவிட்டீர்களா?'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('மறந்துவிட்டீர்களா?'));
    await tester.pumpAndSettle();

    expect(find.text('கடவுச்சொல்லை மீட்டமை'), findsOneWidget);
    expect(find.text('மீட்டமைப்பு இணைப்பை அனுப்பு'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('25-crop Tamil profit planner fits a narrow phone screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    AppLanguageController.current.value = AppLanguage.tamil;

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const ProfitPlannerScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('லாபத் திட்டமிடல்'), findsOneWidget);
    expect(find.textContaining('நெல்'), findsOneWidget);
    final yieldField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('automatic_expected_yield')),
        matching: find.byType(EditableText),
      ),
    );
    final priceField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('automatic_selling_price')),
        matching: find.byType(EditableText),
      ),
    );
    expect(yieldField.readOnly, isTrue);
    expect(priceField.readOnly, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI messages stay readable in Tamil dark mode', (tester) async {
    AppLanguageController.current.value = AppLanguage.tamil;
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const AiAssistantScreen()),
    );
    await tester.pump();

    final message = tester.widget<Text>(
      find.text('வணக்கம் விவசாயி! இன்று நான் எப்படி உதவலாம்?'),
    );
    expect(message.style?.color, AppColors.text);
    expect(tester.takeException(), isNull);
  });
}
