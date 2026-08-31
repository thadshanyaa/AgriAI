import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_routes.dart';
import 'localization/app_language.dart';
import 'services/firebase_backend.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'screens/about_screen.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/ai_recommendation_screen.dart';
import 'screens/community_market_screen.dart';
import 'screens/crop_advisory_screen.dart';
import 'screens/disease_detection_screen.dart';
import 'screens/disease_result_screen.dart';
import 'screens/farm_analytics_screen.dart';
import 'screens/farm_management_screen.dart';
import 'screens/farm_map_screen.dart';
import 'screens/government_news_screen.dart';
import 'screens/help_center_screen.dart';
import 'screens/home_screen.dart';
import 'screens/language_screen.dart';
import 'screens/login_screen.dart';
import 'screens/market_prices_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profit_planner_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/voice_assistant_screen.dart';
import 'screens/weather_forecast_screen.dart';
import 'screens/weather_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBackend.initialize();
  if (FirebaseBackend.isReady) {
    try {
      await NotificationService.initialize();
    } catch (error) {
      debugPrint('Push notification initialization failed: $error');
    }
  }
  await AppLanguageController.initialize();
  await ThemeController.initialize();
  runApp(const AgriAIApp());
}

class AgriAIApp extends StatelessWidget {
  const AgriAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLanguageController.current,
      builder: (context, language, _) => ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.current,
        builder: (context, themeMode, _) => MaterialApp(
          title: 'AgriAI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          locale: Locale(language.code),
          supportedLocales: const [Locale('en'), Locale('ta'), Locale('si')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: AppRoutes.splash,
          routes: {
            AppRoutes.splash: (_) => const SplashScreen(),
            AppRoutes.language: (_) => const LanguageScreen(),
            AppRoutes.login: (_) => const LoginScreen(),
            AppRoutes.register: (_) => const RegisterScreen(),
            AppRoutes.home: (_) => const HomeScreen(),
            AppRoutes.cropAdvisory: (_) => const CropAdvisoryScreen(),
            AppRoutes.aiRecommendation: (_) => const AiRecommendationScreen(),
            AppRoutes.diseaseDetection: (_) => const DiseaseDetectionScreen(),
            AppRoutes.diseaseResult: (_) => const DiseaseResultScreen(),
            AppRoutes.weather: (_) => const WeatherScreen(),
            AppRoutes.forecast: (_) => const WeatherForecastScreen(),
            AppRoutes.profitPlanner: (_) => const ProfitPlannerScreen(),
            AppRoutes.farmManagement: (_) => const FarmManagementScreen(),
            AppRoutes.farmMap: (_) => const FarmMapScreen(),
            AppRoutes.farmAnalytics: (_) => const FarmAnalyticsScreen(),
            AppRoutes.reports: (_) => const ReportsScreen(),
            AppRoutes.marketPrices: (_) => const MarketPricesScreen(),
            AppRoutes.communityMarket: (_) => const CommunityMarketScreen(),
            AppRoutes.notifications: (_) => const NotificationsScreen(),
            AppRoutes.governmentNews: (_) => const GovernmentNewsScreen(),
            AppRoutes.profile: (_) => const ProfileScreen(),
            AppRoutes.settings: (_) => const SettingsScreen(),
            AppRoutes.about: (_) => const AboutScreen(),
            AppRoutes.help: (_) => const HelpCenterScreen(),
            AppRoutes.assistant: (_) => const AiAssistantScreen(),
            AppRoutes.voiceAssistant: (_) => const VoiceAssistantScreen(),
          },
        ),
      ),
    );
  }
}
