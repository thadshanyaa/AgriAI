import 'package:agriai/localization/app_language.dart';
import 'package:agriai/screens/login_screen.dart';
import 'package:agriai/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('English login page visual', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    AppLanguageController.current.value = AppLanguage.english;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login_english.png'),
    );
  });

  testWidgets('Tamil login page visual', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    AppLanguageController.current.value = AppLanguage.tamil;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login_tamil.png'),
    );
  });
}
