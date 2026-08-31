# AgriAI

AgriAI is a Flutter mobile application for AI-assisted smart farming. The
current Android build contains all 25 designed screens plus Firebase
Authentication and Cloud Firestore integration.

The full interface supports English, Tamil and Sinhala. The selected language
is applied throughout the app and saved on the device for the next launch.

## Implemented screens (25)

1. Splash
2. Language selection
3. Login
4. Registration
5. Home dashboard
6. Crop advisory
7. AI crop recommendation
8. Disease detection
9. Disease analysis result
10. Weather advisory
11. 7-day forecast
12. Profit planner
13. Farm management
14. Farm analytics
15. Reports
16. Market prices
17. Community market
18. Notifications
19. Government news
20. Profile
21. Settings
22. About AgriAI
23. Help center
24. AI farming assistant
25. AI voice assistant

## App behavior

- Registration and login use Firebase Authentication.
- Farmer profiles, farms, marketplace listings and notifications are stored in
  Cloud Firestore.
- Crop, disease and weather flows navigate to complete demo results.
- Disease detection can select a local photo from the camera or gallery and
  records scan metadata in Firestore.
- Crop recommendations, profit estimates and report requests are recorded in
  Firestore.
- Report and download actions display confirmation messages; they do not yet
  generate production files.

## Run

```sh
flutter pub get
flutter run
```

Before testing registration/login in a new Firebase project:

1. Enable **Authentication > Sign-in method > Email/Password**.
2. Create a **Cloud Firestore** database and publish `firestore.rules`.

The app presents phone-number login to the farmer and internally maps that
phone number to a Firebase Authentication email identity.

## Verify

```sh
flutter analyze
flutter test
flutter build apk --debug
```

The debug APK is generated at `build/app/outputs/flutter-apk/app-debug.apk`.

## Remaining production integrations

Live weather/market APIs, Firebase Storage image upload, production AI disease
inference, push notifications and downloadable report generation remain future
integrations. Firebase Storage was intentionally left out because new Firebase
projects require the Blaze plan for its use.
