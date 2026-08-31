import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english('en', 'English'),
  tamil('ta', 'தமிழ்'),
  sinhala('si', 'සිංහල');

  const AppLanguage(this.code, this.label);

  final String code;
  final String label;

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

abstract final class AppLanguageController {
  static const _storageKey = 'app_language';
  static bool hasSavedLanguage = false;
  static final ValueNotifier<AppLanguage> current = ValueNotifier(
    AppLanguage.english,
  );

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    hasSavedLanguage = preferences.containsKey(_storageKey);
    current.value = AppLanguage.fromCode(preferences.getString(_storageKey));
  }

  static Future<void> setLanguage(AppLanguage language) async {
    current.value = language;
    hasSavedLanguage = true;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, language.code);
  }
}

String tr(String english) {
  final language = AppLanguageController.current.value;
  if (language == AppLanguage.english || english.trim().isEmpty) return english;
  final translated = _translations[language.code]?[english];
  if (translated != null) return translated;

  final activeFarms = RegExp(r'^(\d+) Active Farms$').firstMatch(english);
  if (activeFarms != null) {
    return language == AppLanguage.tamil
        ? '${activeFarms.group(1)} செயலில் உள்ள பண்ணைகள்'
        : 'සක්‍රීය ගොවිපළ ${activeFarms.group(1)}ක්';
  }

  final newNotifications = RegExp(
    r'^(\d+) New Notifications$',
  ).firstMatch(english);
  if (newNotifications != null) {
    return language == AppLanguage.tamil
        ? '${newNotifications.group(1)} புதிய அறிவிப்புகள்'
        : 'නව දැනුම්දීම් ${newNotifications.group(1)}ක්';
  }

  final generateReport = RegExp(r'^Generate (.+) Report$').firstMatch(english);
  if (generateReport != null) {
    return language == AppLanguage.tamil
        ? '${generateReport.group(1)} அறிக்கையை உருவாக்கு'
        : '${generateReport.group(1)} වාර්තාව සාදන්න';
  }

  final acres = RegExp(r'^([\d.]+) Acres$').firstMatch(english);
  if (acres != null) {
    return language == AppLanguage.tamil
        ? '${acres.group(1)} ஏக்கர்'
        : '${acres.group(1)} අක්කර';
  }

  final tons = RegExp(r'^([\d.]+) Tons$').firstMatch(english);
  if (tons != null) {
    return language == AppLanguage.tamil
        ? '${tons.group(1)} டன்'
        : 'ටොන් ${tons.group(1)}';
  }

  final reportGenerated = RegExp(
    r'^(.+) report generated successfully$',
  ).firstMatch(english);
  if (reportGenerated != null) {
    return language == AppLanguage.tamil
        ? '${reportGenerated.group(1)} அறிக்கை வெற்றிகரமாக உருவாக்கப்பட்டது'
        : '${reportGenerated.group(1)} වාර්තාව සාර්ථකව සාදන ලදී';
  }

  final passwordResetSent = RegExp(
    r'^Password reset link sent to (.+)$',
  ).firstMatch(english);
  if (passwordResetSent != null) {
    return language == AppLanguage.tamil
        ? '${passwordResetSent.group(1)} முகவரிக்கு கடவுச்சொல் மீட்டமைப்பு இணைப்பு அனுப்பப்பட்டது'
        : '${passwordResetSent.group(1)} වෙත මුරපද යළි පිහිටුවීමේ සබැඳිය යවන ලදී';
  }

  final languagePreview = RegExp(
    r'^(.+) language preview$',
  ).firstMatch(english);
  if (languagePreview != null) {
    return language == AppLanguage.tamil
        ? '${languagePreview.group(1)} மொழி முன்னோட்டம்'
        : '${languagePreview.group(1)} භාෂා පෙරදසුන';
  }

  return english;
}

const Map<String, Map<String, String>> _translations = {
  'ta': {
    'Signing in...': 'உள்நுழைகிறது...',
    'Creating account...': 'கணக்கு உருவாக்கப்படுகிறது...',
    'Saving recommendation...': 'பரிந்துரை சேமிக்கப்படுகிறது...',
    'Profile updated': 'சுயவிவரம் புதுப்பிக்கப்பட்டது',
    'Sign Out': 'வெளியேறு',
    'Not provided': 'வழங்கப்படவில்லை',
    'Farm saved to Firebase': 'பண்ணை Firebase-ல் சேமிக்கப்பட்டது',
    'No farms yet. Add your first farm.':
        'பண்ணைகள் எதுவும் இல்லை. முதல் பண்ணையைச் சேர்க்கவும்.',
    'Listing published to Firebase':
        'விற்பனைப் பதிவு Firebase-ல் வெளியிடப்பட்டது',
    'All notifications marked as read':
        'அனைத்து அறிவிப்புகளும் படித்ததாகக் குறிக்கப்பட்டன',
    'No notifications yet.': 'அறிவிப்புகள் எதுவும் இல்லை.',
    'Profit estimate saved': 'லாப மதிப்பீடு சேமிக்கப்பட்டது',
    'Please login again.': 'மீண்டும் உள்நுழையவும்.',
    'Firebase is not ready. Check google-services.json and rebuild the app.':
        'Firebase தயாராக இல்லை. google-services.json-ஐ சரிபார்த்து app-ஐ மீண்டும் build செய்யவும்.',
    'This phone number is already registered.':
        'இந்த தொலைபேசி எண் ஏற்கனவே பதிவு செய்யப்பட்டுள்ளது.',
    'Phone number or password is incorrect.':
        'தொலைபேசி எண் அல்லது கடவுச்சொல் தவறானது.',
    'Email/phone number or password is incorrect.':
        'மின்னஞ்சல்/தொலைபேசி எண் அல்லது கடவுச்சொல் தவறானது.',
    'Phone login is not linked on this device. Sign in once with your registered email; then this phone number will work.':
        'இந்த சாதனத்தில் தொலைபேசி உள்நுழைவு இன்னும் இணைக்கப்படவில்லை. பதிவு செய்த மின்னஞ்சலுடன் ஒருமுறை உள்நுழையவும்; அதன் பிறகு இந்தத் தொலைபேசி எண் வேலை செய்யும்.',
    'Use a stronger password with at least 6 characters.':
        'குறைந்தது 6 எழுத்துகள் கொண்ட வலுவான கடவுச்சொல்லைப் பயன்படுத்தவும்.',
    'No internet connection. Please try again.':
        'இணைய இணைப்பு இல்லை. மீண்டும் முயற்சிக்கவும்.',
    'Enable Email/Password in Firebase Authentication.':
        'Firebase Authentication-ல் Email/Password முறையை இயக்கவும்.',
    'Firestore access denied. Create the database and publish the security rules.':
        'Firestore அணுகல் மறுக்கப்பட்டது. Database-ஐ உருவாக்கி security rules-ஐ வெளியிடவும்.',
    'Firebase is temporarily unavailable. Check your connection.':
        'Firebase தற்காலிகமாக கிடைக்கவில்லை. இணைய இணைப்பைச் சரிபார்க்கவும்.',
    'Password reset will be added with verified email.':
        'Email சரிபார்ப்புடன் password reset பின்னர் சேர்க்கப்படும்.',
    'New Farm': 'புதிய பண்ணை',
    '1 Acre': '1 ஏக்கர்',
    'Farm': 'பண்ணை',
    'Farmer': 'விவசாயி',
    'New farm listing': 'புதிய பண்ணை விற்பனைப் பதிவு',
    'Contact seller': 'விற்பனையாளரைத் தொடர்புகொள்ளவும்',
    'Farm listing': 'பண்ணை விற்பனைப் பதிவு',
    'Notification': 'அறிவிப்பு',
    'Empowering Farmers\nThrough Artificial Intelligence':
        'செயற்கை நுண்ணறிவின் மூலம்\nவிவசாயிகளை மேம்படுத்துதல்',
    'Preparing your farming assistant...':
        'உங்கள் விவசாய உதவியாளர் தயாராகிறார்...',
    'AI Advisory': 'AI ஆலோசனை',
    'Weather': 'வானிலை',
    'Disease': 'நோய்',
    'Profit': 'லாபம்',
    'Grow Smart • Grow Better • Grow Together':
        'அறிவுடன் வளர்ப்போம் • சிறப்பாக வளர்ப்போம் • ஒன்றாக வளர்ப்போம்',
    'Choose Language': 'மொழியைத் தேர்ந்தெடுக்கவும்',
    'Select your preferred language':
        'உங்களுக்கு விருப்பமான மொழியைத் தேர்ந்தெடுக்கவும்',
    'Tap to hear language preview': 'மொழி முன்னோட்டத்தைக் கேட்க தட்டவும்',
    'Continue': 'தொடரவும்',
    'Phone Number': 'தொலைபேசி எண்',
    'Phone Number or Email': 'தொலைபேசி எண் அல்லது மின்னஞ்சல்',
    'On a new device, sign in with email once to enable phone login.':
        'புதிய சாதனத்தில் தொலைபேசி உள்நுழைவை இயக்க, முதலில் மின்னஞ்சலுடன் ஒருமுறை உள்நுழையவும்.',
    'Welcome Back': 'மீண்டும் வரவேற்கிறோம்',
    'Sign in to continue to AgriAI': 'AgriAI-ஐ தொடர உள்நுழையவும்',
    'Password': 'கடவுச்சொல்',
    'Show password': 'கடவுச்சொல்லைக் காட்டு',
    'Hide password': 'கடவுச்சொல்லை மறை',
    'Remember me': 'என்னை நினைவில் கொள்',
    'Forgot?': 'மறந்துவிட்டீர்களா?',
    'Fingerprint': 'கைரேகை',
    'Face': 'முகம்',
    'OR USE BIOMETRICS': 'அல்லது BIOMETRIC பயன்படுத்தவும்',
    'Reset Password': 'கடவுச்சொல்லை மீட்டமை',
    'Enter the exact email address used to create your account.':
        'உங்கள் கணக்கை உருவாக்கப் பயன்படுத்திய சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்.',
    'Recovery Email': 'மீட்பு மின்னஞ்சல்',
    'Send Reset Link': 'மீட்டமைப்பு இணைப்பை அனுப்பு',
    'A phone number cannot receive an email reset link. Use your registered login email.':
        'மின்னஞ்சல் மீட்டமைப்பு இணைப்பு தொலைபேசி எண்ணிற்கு வராது. பதிவு செய்த உள்நுழைவு மின்னஞ்சலைப் பயன்படுத்தவும்.',
    'Reset Link Requested': 'மீட்டமைப்பு இணைப்பு கோரப்பட்டது',
    'If this email belongs to an AgriAI account, Firebase will send a reset link to:':
        'இந்த மின்னஞ்சல் AgriAI கணக்கிற்கு உரியதானால், Firebase மீட்டமைப்பு இணைப்பை இங்கே அனுப்பும்:',
    'Check Inbox and Spam. Delivery can take a few minutes. For an old phone-only account, login once and add a verified email in Profile.':
        'Inbox மற்றும் Spam கோப்புறைகளைப் பார்க்கவும். மின்னஞ்சல் வர சில நிமிடங்கள் ஆகலாம். பழைய தொலைபேசி எண் மட்டும் கொண்ட கணக்காக இருந்தால், ஒருமுறை உள்நுழைந்து Profile-ல் சரிபார்க்கப்பட்ட மின்னஞ்சலைச் சேர்க்கவும்.',
    'OK': 'சரி',
    'Email for Login & Recovery': 'உள்நுழைவு மற்றும் மீட்புக்கான மின்னஞ்சல்',
    'Enter a valid email address': 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்',
    'Enter a valid phone number or email':
        'சரியான தொலைபேசி எண் அல்லது மின்னஞ்சலை உள்ளிடவும்',
    'Login once with your email/phone and password to enable biometric login.':
        'Biometric உள்நுழைவை இயக்க, முதலில் மின்னஞ்சல்/தொலைபேசி எண் மற்றும் கடவுச்சொல்லுடன் உள்நுழையவும்.',
    'Login with “Remember me” enabled before using fingerprint or face login.':
        'கைரேகை அல்லது முக உள்நுழைவைப் பயன்படுத்தும் முன் “என்னை நினைவில் கொள்” என்பதைத் தேர்ந்தெடுத்து உள்நுழையவும்.',
    'No fingerprint or face biometric is enrolled. Add one in Phone Settings first.':
        'கைரேகை அல்லது முக அடையாளம் பதிவு செய்யப்படவில்லை. முதலில் Phone Settings-ல் ஒன்றைச் சேர்க்கவும்.',
    'Biometric authentication was cancelled or not recognized.':
        'Biometric சரிபார்ப்பு ரத்து செய்யப்பட்டது அல்லது அடையாளம் காணப்படவில்லை.',
    'LOGIN': 'உள்நுழைக',
    "Don't have an account?": 'கணக்கு இல்லையா?',
    'Register Now': 'இப்போது பதிவு செய்க',
    'Account created. Please login.': 'கணக்கு உருவாக்கப்பட்டது. உள்நுழையவும்.',
    'Create Account': 'கணக்கை உருவாக்கவும்',
    'Join AgriAI Smart Farming': 'AgriAI ஸ்மார்ட் விவசாயத்தில் இணையுங்கள்',
    'Full Name': 'முழுப் பெயர்',
    'Email (Optional)': 'மின்னஞ்சல் (விருப்பம்)',
    'Confirm Password': 'கடவுச்சொல்லை உறுதிப்படுத்தவும்',
    'District': 'மாவட்டம்',
    'Farm Name': 'பண்ணையின் பெயர்',
    'Already have an account? Login': 'ஏற்கனவே கணக்கு உள்ளதா? உள்நுழைக',
    'Please select your district': 'உங்கள் மாவட்டத்தைத் தேர்ந்தெடுக்கவும்',
    'Required field': 'இந்த விவரம் அவசியம்',
    'Use at least 6 characters': 'குறைந்தது 6 எழுத்துகளைப் பயன்படுத்தவும்',
    'Passwords do not match': 'கடவுச்சொற்கள் பொருந்தவில்லை',
    'Enter a valid phone number': 'சரியான தொலைபேசி எண்ணை உள்ளிடவும்',
    'Enter your password': 'உங்கள் கடவுச்சொல்லை உள்ளிடவும்',
    'Your smart farming dashboard': 'உங்கள் ஸ்மார்ட் விவசாய முகப்பு',
    'Good Morning': 'காலை வணக்கம்',
    'Good Afternoon': 'மதிய வணக்கம்',
    'Good Evening': 'மாலை வணக்கம்',
    'Welcome': 'வரவேற்கிறோம்',
    'Loading weather...': 'வானிலை ஏற்றப்படுகிறது...',
    'Weather unavailable': 'வானிலைத் தகவல் கிடைக்கவில்லை',
    'Refresh': 'புதுப்பிக்கவும்',
    'Welcome, Farmer': 'வரவேற்கிறோம், விவசாயி',
    "Today's Weather: 29°C • Sunny": 'இன்றைய வானிலை: 29°C • வெயில்',
    'Crop': 'பயிர்',
    'My Farm': 'என் பண்ணை',
    'Reports': 'அறிக்கைகள்',
    'Market': 'சந்தை',
    'Profile': 'சுயவிவரம்',
    'AI Farming Tip': 'AI விவசாயக் குறிப்பு',
    'Water crops early morning to reduce evaporation and improve absorption.':
        'நீர் ஆவியாவதை குறைத்து உறிஞ்சுதலை மேம்படுத்த அதிகாலையில் பயிர்களுக்கு நீர் பாய்ச்சுங்கள்.',
    'Ask AgriAI Assistant': 'AgriAI உதவியாளரிடம் கேளுங்கள்',
    'Crop Advisory': 'பயிர் ஆலோசனை',
    'AI crop recommendation for your farm':
        'உங்கள் பண்ணைக்கான AI பயிர் பரிந்துரை',
    'Smart Crop Advisor': 'ஸ்மார்ட் பயிர் ஆலோசகர்',
    'Find Best Crop': 'சிறந்த பயிரைக் கண்டறியுங்கள்',
    'Based on soil, season and your farm location':
        'மண், பருவம் மற்றும் பண்ணை இருப்பிடத்தின் அடிப்படையில்',
    'Farm Details': 'பண்ணை விவரங்கள்',
    'Location / District': 'இருப்பிடம் / மாவட்டம்',
    'Soil Type': 'மண் வகை',
    'Sandy': 'மணற்பாங்கான',
    'Clay': 'களிமண்',
    'Loamy': 'வண்டல் மண்',
    'Season': 'பருவம்',
    'Rainy Season': 'மழைக்காலம்',
    'Dry Season': 'வறண்ட காலம்',
    'Water Source': 'நீர் ஆதாரம்',
    'Irrigation': 'நீர்ப்பாசனம்',
    'Rain Water': 'மழை நீர்',
    'Well': 'கிணறு',
    'Land Size (Acres)': 'நில அளவு (ஏக்கர்)',
    'acres': 'ஏக்கர்',
    'Get AI Recommendation': 'AI பரிந்துரையைப் பெறுங்கள்',
    'AI Output Preview': 'AI முடிவு முன்னோட்டம்',
    'Recommended crop • Expected yield • Risk level • Water requirement • Profit prediction':
        'பரிந்துரைக்கப்பட்ட பயிர் • எதிர்பார்க்கப்படும் விளைச்சல் • அபாய நிலை • நீர் தேவை • லாபக் கணிப்பு',
    'AI Recommendation': 'AI பரிந்துரை',
    'Best crop recommendation for your land':
        'உங்கள் நிலத்திற்கான சிறந்த பயிர் பரிந்துரை',
    'AI Analysis Complete': 'AI பகுப்பாய்வு முடிந்தது',
    'Rice is Recommended': 'நெல் பரிந்துரைக்கப்படுகிறது',
    'Confidence Score: 96%': 'நம்பகத்தன்மை மதிப்பெண்: 96%',
    'Recommendation Summary': 'பரிந்துரைச் சுருக்கம்',
    'Expected Yield': 'எதிர்பார்க்கப்படும் விளைச்சல்',
    'Growing Period': 'வளர்ச்சி காலம்',
    'Water Requirement': 'நீர் தேவை',
    'Fertilizer': 'உரம்',
    'Estimated Profit': 'மதிப்பிடப்பட்ட லாபம்',
    'Risk Level': 'அபாய நிலை',
    'Low': 'குறைவு',
    'Medium': 'நடுத்தரம்',
    'AI Suggestions': 'AI ஆலோசனைகள்',
    '✓ Start planting within the next 7 days.':
        '✓ அடுத்த 7 நாட்களுக்குள் நடவு செய்யத் தொடங்குங்கள்.',
    '✓ Use drip irrigation to save water.':
        '✓ நீரைச் சேமிக்க சொட்டு நீர்ப்பாசனம் பயன்படுத்துங்கள்.',
    '✓ Check the field after heavy rainfall.':
        '✓ கனமழைக்குப் பிறகு வயலைச் சரிபார்க்கவும்.',
    'Download Report': 'அறிக்கையைப் பதிவிறக்கவும்',
    'Analyzing farm and weather...':
        'பண்ணை மற்றும் வானிலை பகுப்பாய்வு செய்யப்படுகிறது...',
    'Analysis Complete': 'பகுப்பாய்வு முடிந்தது',
    'Suitability Score': 'பொருத்த மதிப்பெண்',
    'No recommendation yet': 'இன்னும் பரிந்துரை இல்லை',
    'Enter your farm details to generate a recommendation.':
        'பரிந்துரையை உருவாக்க உங்கள் பண்ணை விவரங்களை உள்ளிடுங்கள்.',
    'Open Crop Advisory': 'பயிர் ஆலோசனையைத் திறக்கவும்',
    'Estimated Investment': 'மதிப்பிடப்பட்ட முதலீடு',
    'Estimated Revenue': 'மதிப்பிடப்பட்ட வருமானம்',
    'High': 'அதிகம்',
    'Why this crop?': 'ஏன் இந்தப் பயிர்?',
    'Soil condition matches this crop.':
        'மண் நிலை இந்தப் பயிருக்கு பொருந்துகிறது.',
    'Season and water source match this crop.':
        'பருவமும் நீர் ஆதாரமும் இந்தப் பயிருக்கு பொருந்துகின்றன.',
    'District crop pattern was included.':
        'மாவட்ட பயிர் முறையும் கணக்கில் சேர்க்கப்பட்டது.',
    'Live 7-day weather was included.':
        'நேரடி 7 நாள் வானிலை கணக்கில் சேர்க்கப்பட்டது.',
    'Live 7-day weather included in this score.':
        'இந்த மதிப்பெண்ணில் நேரடி 7 நாள் வானிலை சேர்க்கப்பட்டுள்ளது.',
    'Weather was unavailable; farm details were used.':
        'வானிலை கிடைக்கவில்லை; பண்ணை விவரங்கள் பயன்படுத்தப்பட்டன.',
    'Top 5 Crops': 'சிறந்த 5 பயிர்கள்',
    'View all 25 crop rankings': '25 பயிர்களின் தரவரிசையையும் பார்க்கவும்',
    'Every trained crop is checked for your farm.':
        'பயிற்றுவிக்கப்பட்ட 25 பயிர்களும் உங்கள் பண்ணைக்காக சரிபார்க்கப்படுகின்றன.',
    'Open Profit Planner': 'லாபத் திட்டமிடலைத் திறக்கவும்',
    'Review 7-Day Weather': '7 நாள் வானிலையைப் பார்க்கவும்',
    'Yield and profit are estimates. Confirm soil tests, input costs and market prices before planting.':
        'விளைச்சலும் லாபமும் மதிப்பீடுகள். நடவு முன் மண் சோதனை, செலவுகள் மற்றும் சந்தை விலைகளை உறுதிப்படுத்தவும்.',
    'Disease Detection': 'பயிர் நோய் கண்டறிதல்',
    'AI-powered plant health scanner':
        'AI மூலம் இயங்கும் தாவர ஆரோக்கிய ஸ்கேனர்',
    'AI Plant Scanner': 'AI தாவர ஸ்கேனர்',
    'Scan Plant Disease': 'பயிர் நோயை ஸ்கேன் செய்யவும்',
    'Upload a leaf image to identify diseases':
        'நோயைக் கண்டறிய இலைப் படத்தைப் பதிவேற்றவும்',
    'Upload Image': 'படத்தைப் பதிவேற்றவும்',
    'Tap to Upload Leaf Photo': 'இலைப் படத்தைப் பதிவேற்ற தட்டவும்',
    'Camera or Gallery': 'கேமரா அல்லது படத்தொகுப்பு',
    'Camera': 'கேமரா',
    'Gallery': 'படத்தொகுப்பு',
    'Crop Type': 'பயிர் வகை',
    'Auto Detect': 'தானாகக் கண்டறியவும்',
    'Select Crop': 'பயிரைத் தேர்ந்தெடுக்கவும்',
    'Required — the AI checks diseases only for this crop':
        'கட்டாயம் — இந்தப் பயிருக்கான நோய்களை மட்டும் AI சரிபார்க்கும்',
    'Please select the crop before disease analysis':
        'நோய் பகுப்பாய்வுக்கு முன் பயிரைத் தேர்ந்தெடுக்கவும்',
    'Select the crop first; automatic crop identification is not used for disease diagnosis.':
        'முதலில் பயிரைத் தேர்ந்தெடுக்கவும்; நோய் கண்டறிதலுக்கு தானியங்கி பயிர் அடையாளம் பயன்படுத்தப்படாது.',
    'For better accuracy, select the crop if you already know it.':
        'சிறந்த துல்லியத்திற்கு, பயிர் தெரிந்தால் அதைத் தேர்ந்தெடுக்கவும்.',
    'Photo Tips': 'படக் குறிப்புகள்',
    'Camera is disabled in AgriAI Settings.':
        'AgriAI அமைப்புகளில் கேமரா முடக்கப்பட்டுள்ளது.',
    '• Use one leaf with good daylight.':
        '• நல்ல பகல் வெளிச்சத்தில் ஒரு இலையைப் பயன்படுத்தவும்.',
    '• Keep the leaf close and in focus.':
        '• இலையை அருகில் வைத்து தெளிவாகப் படம் எடுக்கவும்.',
    '• Avoid fingers, shadows and a busy background.':
        '• விரல்கள், நிழல்கள் மற்றும் குழப்பமான பின்னணியைத் தவிர்க்கவும்.',
    'Early': 'ஆரம்ப நிலை',
    'Leaf Area': 'இலைப் பகுதி',
    'Flowering': 'பூக்கும் நிலை',
    'Analyze with AI': 'AI மூலம் பகுப்பாய்வு செய்க',
    'Analyzing...': 'பகுப்பாய்வு செய்யப்படுகிறது...',
    'AI Result': 'AI முடிவு',
    'Disease name • Confidence score • Treatment recommendation • Organic solution':
        'நோயின் பெயர் • நம்பகத்தன்மை • சிகிச்சை பரிந்துரை • இயற்கைத் தீர்வு',
    'Disease Analysis Result': 'நோய் பகுப்பாய்வு முடிவு',
    'Unsupported Crop': 'ஆதரிக்கப்படாத பயிர்',
    'Sorry, this crop is not supported':
        'மன்னிக்கவும், இந்தப் பயிர் ஆதரிக்கப்படவில்லை',
    'The photo does not confidently match the 25 trained crops.':
        'இந்தப் படம் பயிற்றுவிக்கப்பட்ட 25 பயிர்களுடன் நம்பகமாகப் பொருந்தவில்லை.',
    'Scan Status': 'ஸ்கேன் நிலை',
    'Not Supported': 'ஆதரிக்கப்படவில்லை',
    'Model Confidence': 'மாதிரி நம்பகத்தன்மை',
    'Disease Result': 'நோய் முடிவு',
    'Not Available': 'கிடைக்கவில்லை',
    'What to do next': 'அடுத்து என்ன செய்வது',
    '• Use a clear photo of one leaf from a supported crop.':
        '• ஆதரிக்கப்படும் பயிரின் ஒரு தெளிவான இலைப் படத்தைப் பயன்படுத்தவும்.',
    '• If the crop is supported, retake it in good daylight.':
        '• பயிர் ஆதரிக்கப்பட்டால், நல்ல பகல் வெளிச்சத்தில் மீண்டும் படம் எடுக்கவும்.',
    '• A new crop requires new disease images and model retraining.':
        '• புதிய பயிருக்கு புதிய நோய் படங்களும் model மறுபயிற்சியும் தேவை.',
    'Scan Another Leaf': 'மற்றொரு இலையை ஸ்கேன் செய்யவும்',
    'AI diagnosis and treatment plan': 'AI நோயறிதல் மற்றும் சிகிச்சைத் திட்டம்',
    'AI Scan Complete': 'AI ஸ்கேன் முடிந்தது',
    'Leaf Blight Detected': 'இலை கருகல் கண்டறியப்பட்டது',
    'Confidence Score: 94%': 'நம்பகத்தன்மை மதிப்பெண்: 94%',
    'Disease Details': 'நோய் விவரங்கள்',
    'Severity': 'தீவிரம்',
    'Recovery': 'குணமடையும் காலம்',
    'Moderate': 'மிதமான',
    'Treatment Plan': 'சிகிச்சைத் திட்டம்',
    '• Remove infected leaves.': '• பாதிக்கப்பட்ட இலைகளை அகற்றவும்.',
    '• Apply recommended fungicide.':
        '• பரிந்துரைக்கப்பட்ட பூஞ்சைக் கொல்லியைப் பயன்படுத்தவும்.',
    '• Improve field drainage.': '• வயல் வடிகாலை மேம்படுத்தவும்.',
    '• Spray organic neem solution.': '• இயற்கை வேப்பக் கரைசலைத் தெளிக்கவும்.',
    'Recommended Product': 'பரிந்துரைக்கப்பட்ட தயாரிப்பு',
    'Copper-based Fungicide': 'செம்பு அடிப்படையிலான பூஞ்சைக் கொல்லி',
    'Download Treatment Report': 'சிகிச்சை அறிக்கையைப் பதிவிறக்கவும்',
    'Weather Advisory': 'வானிலை ஆலோசனை',
    'Real-time weather insights for your farm':
        'உங்கள் பண்ணைக்கான நிகழ்நேர வானிலைத் தகவல்கள்',
    "Today's Weather": 'இன்றைய வானிலை',
    'Sunny • Trincomalee': 'வெயில் • திருகோணமலை',
    'Weather Details': 'வானிலை விவரங்கள்',
    'Humidity': 'ஈரப்பதம்',
    'Rain Chance': 'மழை வாய்ப்பு',
    'Wind Speed': 'காற்றின் வேகம்',
    'UV Index': 'UV குறியீடு',
    'Sunrise': 'சூரிய உதயம்',
    'AI Farming Advice': 'AI விவசாய ஆலோசனை',
    'Best irrigation time: 6:00 AM': 'சிறந்த நீர்ப்பாசன நேரம்: காலை 6:00',
    'Safe spraying conditions today': 'இன்று தெளிப்பதற்கு ஏற்ற சூழல்',
    'No heavy rain expected': 'கனமழை எதிர்பார்க்கப்படவில்லை',
    'View 7-Day Forecast': '7 நாள் முன்னறிவிப்பைப் பார்க்கவும்',
    '7-Day Weather Forecast': '7 நாள் வானிலை முன்னறிவிப்பு',
    'AI weather prediction and farming advice':
        'AI வானிலை கணிப்பு மற்றும் விவசாய ஆலோசனை',
    'Sunny • Rain Chance 20%': 'வெயில் • மழை வாய்ப்பு 20%',
    '7-Day Forecast': '7 நாள் முன்னறிவிப்பு',
    'AI Recommendations': 'AI பரிந்துரைகள்',
    '• Irrigate crops tomorrow morning.':
        '• நாளை காலை பயிர்களுக்கு நீர் பாய்ச்சவும்.',
    '• Avoid spraying on Wednesday.': '• புதன்கிழமை தெளிப்பதைத் தவிர்க்கவும்.',
    '• Harvest before expected rainfall.':
        '• எதிர்பார்க்கப்படும் மழைக்கு முன் அறுவடை செய்யவும்.',
    '• Strong winds expected Friday.':
        '• வெள்ளிக்கிழமை பலத்த காற்று எதிர்பார்க்கப்படுகிறது.',
    'Refresh Forecast': 'முன்னறிவிப்பைப் புதுப்பிக்கவும்',
    'Unable to load weather. Check your internet connection.':
        'வானிலைத் தகவலை ஏற்ற முடியவில்லை. இணைய இணைப்பைச் சரிபார்க்கவும்.',
    'Clear sky': 'தெளிவான வானம்',
    'Mainly clear': 'பெரும்பாலும் தெளிவு',
    'Partly cloudy': 'பகுதி மேகமூட்டம்',
    'Overcast': 'முழு மேகமூட்டம்',
    'Foggy': 'மூடுபனி',
    'Drizzle': 'தூறல்',
    'Rain': 'மழை',
    'Heavy rain': 'கனமழை',
    'Thunderstorm': 'இடியுடன் கூடிய மழை',
    'Cloudy': 'மேகமூட்டம்',
    'Farming Advice': 'விவசாய ஆலோசனை',
    'Rain is likely. Delay irrigation and protect harvested crops.':
        'மழை பெய்ய வாய்ப்புள்ளது. நீர்ப்பாசனத்தைத் தாமதப்படுத்தி அறுவடை செய்த பயிர்களைப் பாதுகாக்கவும்.',
    'Low rain chance. Irrigate crops early in the morning.':
        'மழை வாய்ப்பு குறைவு. அதிகாலையில் பயிர்களுக்கு நீர் பாய்ச்சவும்.',
    'Strong wind expected. Avoid pesticide spraying.':
        'பலத்த காற்று எதிர்பார்க்கப்படுகிறது. பூச்சிக்கொல்லி தெளிப்பதைத் தவிர்க்கவும்.',
    'Wind conditions are suitable for normal field work.':
        'வழக்கமான வயல் வேலைக்கு காற்றின் நிலை ஏற்றதாக உள்ளது.',
    'High UV level. Avoid long field work around midday.':
        'UV அளவு அதிகம். நண்பகலில் நீண்ட நேர வயல் வேலையைத் தவிர்க்கவும்.',
    'Weather data: Open-Meteo': 'வானிலைத் தரவு: Open-Meteo',
    'Live weather forecast and farming advice':
        'நேரடி வானிலை முன்னறிவிப்பு மற்றும் விவசாய ஆலோசனை',
    'Farming Recommendations': 'விவசாய பரிந்துரைகள்',
    'Daily Crop Recommendations': 'தினசரி பயிர் பரிந்துரைகள்',
    'All 25 Crops - Weekly Suitability':
        'அனைத்து 25 பயிர்கள் - வாராந்திர பொருத்தம்',
    'Weather suitability uses temperature, rain and wind. Confirm soil, season and local advice before planting.':
        'வானிலைப் பொருத்தம் வெப்பநிலை, மழை மற்றும் காற்றின் அடிப்படையிலானது. பயிரிடுவதற்கு முன் மண், பருவம் மற்றும் உள்ளூர் ஆலோசனையை உறுதிப்படுத்தவும்.',
    'Recommended from your 25 crops':
        'உங்கள் 25 பயிர்களிலிருந்து பரிந்துரைக்கப்பட்டவை',
    'rain': 'மழை',
    'Highly Suitable': 'மிகவும் பொருத்தமானது',
    'Suitable': 'பொருத்தமானது',
    'Low Suitability': 'குறைந்த பொருத்தம்',
    'Rain is likely tomorrow. Reduce irrigation.':
        'நாளை மழை பெய்ய வாய்ப்புள்ளது. நீர்ப்பாசனத்தைக் குறைக்கவும்.',
    'Irrigate crops tomorrow morning.':
        'நாளை காலை பயிர்களுக்கு நீர் பாய்ச்சவும்.',
    'Avoid spraying on windy forecast days.':
        'காற்று அதிகமாக இருக்கும் நாட்களில் தெளிப்பதைத் தவிர்க்கவும்.',
    'Wind forecast is suitable for normal farm work.':
        'வழக்கமான பண்ணை வேலைக்கு காற்று முன்னறிவிப்பு ஏற்றதாக உள்ளது.',
    'Profit Planner': 'லாபத் திட்டமிடல்',
    'Estimate costs, revenue and profit':
        'செலவு, வருவாய் மற்றும் லாபத்தை மதிப்பிடுங்கள்',
    'Estimate costs, revenue and profit for all 25 crops':
        'அனைத்து 25 பயிர்களுக்கும் செலவு, வருவாய் மற்றும் லாபத்தை மதிப்பிடுங்கள்',
    'AI Profit Calculator': 'AI லாபக் கணிப்பான்',
    'Plan Before You Plant': 'பயிரிடும் முன் திட்டமிடுங்கள்',
    'Make informed decisions before the season starts':
        'பருவம் தொடங்குமுன் தகவலறிந்த முடிவெடுங்கள்',
    '25 crops • Editable costs, yield and selling price':
        '25 பயிர்கள் • செலவு, விளைச்சல் மற்றும் விற்பனை விலையை மாற்றலாம்',
    'Load 25-crop planning defaults':
        '25 பயிர் திட்டமிடல் இயல்புநிலைகளை ஏற்றவும்',
    'Seed / Planting Material Cost': 'விதை / நடவுப் பொருள் செலவு',
    'Fertilizer & Input Cost': 'உரம் மற்றும் உள்ளீட்டுச் செலவு',
    'Seed Cost': 'விதை செலவு',
    'Fertilizer Cost': 'உரச் செலவு',
    'Labour Cost': 'தொழிலாளர் செலவு',
    'Expected Yield (kg)': 'எதிர்பார்க்கப்படும் விளைச்சல் (கிலோ)',
    'Expected Yield (kg/units)': 'எதிர்பார்க்கப்படும் விளைச்சல் (கிலோ/அலகுகள்)',
    'Expected Selling Price (per kg/unit)':
        'எதிர்பார்க்கப்படும் விற்பனை விலை (கிலோ/அலகுக்கு)',
    'Calculate Profit': 'லாபத்தைக் கணக்கிடவும்',
    'Saving...': 'சேமிக்கப்படுகிறது...',
    'Estimated Results': 'மதிப்பிடப்பட்ட முடிவுகள்',
    'Investment': 'முதலீடு',
    'Revenue': 'வருவாய்',
    'Expected Profit': 'எதிர்பார்க்கப்படும் லாபம்',
    'Profit per Acre': 'ஏக்கருக்கு லாபம்',
    'Estimated ROI': 'மதிப்பிடப்பட்ட ROI',
    'Enter a valid amount': 'சரியான தொகையை உள்ளிடவும்',
    'Planning defaults are indicative. Edit them using your current supplier costs, expected yield and local market price before making a farming decision.':
        'திட்டமிடல் இயல்புநிலைகள் வழிகாட்டலுக்கானவை. விவசாய முடிவு எடுப்பதற்கு முன் தற்போதைய பொருள் செலவு, எதிர்பார்க்கப்படும் விளைச்சல் மற்றும் உள்ளூர் சந்தை விலையைப் பயன்படுத்தி மாற்றவும்.',
    'Farm Management': 'பண்ணை நிர்வாகம்',
    'Manage all your farms in one place':
        'உங்கள் எல்லா பண்ணைகளையும் ஒரே இடத்தில் நிர்வகிக்கவும்',
    'My Farms': 'என் பண்ணைகள்',
    'Track crops, irrigation and harvest':
        'பயிர், நீர்ப்பாசனம் மற்றும் அறுவடையைக் கண்காணிக்கவும்',
    'Add New Farm': 'புதிய பண்ணையைச் சேர்க்கவும்',
    'Current Crop': 'தற்போதைய பயிர்',
    'Area in acres': 'ஏக்கரில் பரப்பளவு',
    'Cancel': 'ரத்து செய்',
    'Add Farm': 'பண்ணையைச் சேர்க்கவும்',
    'View': 'பார்க்கவும்',
    'Upcoming Harvest': 'வரவிருக்கும் அறுவடை',
    'Rice Farm • 12 Days Remaining': 'நெல் பண்ணை • இன்னும் 12 நாட்கள்',
    'Farm Analytics': 'பண்ணை பகுப்பாய்வு',
    'AI insights for your farm performance':
        'உங்கள் பண்ணை செயல்திறனுக்கான AI நுண்ணறிவுகள்',
    'Farm Health Score': 'பண்ணை ஆரோக்கிய மதிப்பெண்',
    'Excellent crop condition': 'சிறந்த பயிர் நிலை',
    'Yield': 'விளைச்சல்',
    'Monthly Performance': 'மாதாந்திர செயல்திறன்',
    'AI Insights': 'AI நுண்ணறிவுகள்',
    '• Yield increased by 12% this month.':
        '• இந்த மாதம் விளைச்சல் 12% அதிகரித்துள்ளது.',
    '• Water usage reduced by 18%.': '• நீர் பயன்பாடு 18% குறைந்துள்ளது.',
    '• Harvest expected in 12 days.':
        '• 12 நாட்களில் அறுவடை எதிர்பார்க்கப்படுகிறது.',
    'Refresh Analytics': 'பகுப்பாய்வைப் புதுப்பிக்கவும்',
    'Farm analytics and downloadable reports':
        'பண்ணை பகுப்பாய்வு மற்றும் பதிவிறக்கக்கூடிய அறிக்கைகள்',
    'Analytics Dashboard': 'பகுப்பாய்வு முகப்பு',
    'Monthly Summary': 'மாதாந்திர சுருக்கம்',
    'Crop • Weather • Profit • Disease': 'பயிர் • வானிலை • லாபம் • நோய்',
    'Crop Report': 'பயிர் அறிக்கை',
    'Yield Analysis': 'விளைச்சல் பகுப்பாய்வு',
    'Forecast Report': 'வானிலை முன்னறிவிப்பு அறிக்கை',
    'Disease Report': 'நோய் அறிக்கை',
    'Health Report': 'ஆரோக்கிய அறிக்கை',
    'Profit Report': 'லாப அறிக்கை',
    'Income Report': 'வருமான அறிக்கை',
    'Export Options': 'ஏற்றுமதி விருப்பங்கள்',
    'Market Prices': 'சந்தை விலைகள்',
    'Official Sri Lanka daily food commodity prices':
        'இலங்கையின் அதிகாரப்பூர்வ தினசரி உணவுப் பொருள் விலைகள்',
    'Market prices updated': 'சந்தை விலைகள் புதுப்பிக்கப்பட்டன',
    'Unable to load market prices. Check your internet connection.':
        'சந்தை விலைகளை ஏற்ற முடியவில்லை. இணைய இணைப்பைச் சரிபார்க்கவும்.',
    'Unable to open the price bulletin.':
        'விலை அறிக்கையைத் திறக்க முடியவில்லை.',
    'Daily Price Bulletin': 'தினசரி விலை அறிக்கை',
    'English PDF • Official wholesale and retail prices':
        'ஆங்கில PDF • அதிகாரப்பூர்வ மொத்த மற்றும் சில்லறை விலைகள்',
    'Loading latest prices...': 'சமீபத்திய விலைகள் ஏற்றப்படுகின்றன...',
    'Refresh Market Prices': 'சந்தை விலைகளைப் புதுப்பிக்கவும்',
    'HARTI Market Information': 'HARTI சந்தைத் தகவல்',
    'Daily Food Prices': 'தினசரி உணவு விலைகள்',
    'Latest official bulletin': 'சமீபத்திய அதிகாரப்பூர்வ அறிக்கை',
    'Source: HARTI Sri Lanka • Tap a bulletin to view official prices':
        'மூலம்: HARTI இலங்கை • அதிகாரப்பூர்வ விலைகளைப் பார்க்க அறிக்கையைத் தட்டவும்',
    'Daily crop prices and AI price trends':
        'தினசரி பயிர் விலைகள் மற்றும் AI விலைப் போக்குகள்',
    "Today's Market": 'இன்றைய சந்தை',
    'Best Selling Crops': 'அதிகம் விற்பனையாகும் பயிர்கள்',
    'Updated: Colombo Market • Today': 'புதுப்பிப்பு: கொழும்பு சந்தை • இன்று',
    'Rice': 'நெல்',
    'Tomato': 'தக்காளி',
    'Chili': 'மிளகாய்',
    'Maize': 'சோளம்',
    'Apple': 'ஆப்பிள்',
    'Banana': 'வாழை',
    'Bean': 'பீன்ஸ்',
    'Brinjal': 'கத்தரிக்காய்',
    'Cabbage': 'முட்டைக்கோஸ்',
    'Chilli': 'மிளகாய்',
    'Lemon': 'எலுமிச்சை',
    'Coconut': 'தென்னை',
    'Coffee': 'காபி',
    'Cucumber': 'வெள்ளரிக்காய்',
    'Grapes': 'திராட்சை',
    'Groundnut': 'நிலக்கடலை',
    'Guava': 'கொய்யா',
    'Mango': 'மாம்பழம்',
    'Okra': 'வெண்டைக்காய்',
    'Onion': 'வெங்காயம்',
    'Papaya': 'பப்பாளி',
    'Pineapple': 'அன்னாசி',
    'Potato': 'உருளைக்கிழங்கு',
    'Pumpkin': 'பூசணிக்காய்',
    'Sugarcane': 'கரும்பு',
    'Tea': 'தேயிலை',
    'Per kg price': 'ஒரு கிலோ விலை',
    'AI Price Prediction': 'AI விலைக் கணிப்பு',
    'Chili price may increase next week.': 'அடுத்த வாரம் மிளகாய் விலை உயரலாம்.',
    'Recommended action: Sell 40% now.':
        'பரிந்துரை: இப்போது 40% விற்பனை செய்யுங்கள்.',
    'Confidence: 82%': 'நம்பகத்தன்மை: 82%',
    'Open Community Market': 'சமூகச் சந்தையைத் திறக்கவும்',
    'Community Market': 'சமூகச் சந்தை',
    'Buy, sell and connect with farmers':
        'விவசாயிகளுடன் வாங்கவும், விற்கவும், இணையவும்',
    'Farmer Marketplace': 'விவசாயிகள் சந்தை',
    'Sell Your Harvest': 'உங்கள் அறுவடையை விற்கவும்',
    'Crops • Tools • Equipment • Services':
        'பயிர்கள் • கருவிகள் • உபகரணங்கள் • சேவைகள்',
    'Sell Crops': 'பயிர்களை விற்கவும்',
    'Post your harvest': 'உங்கள் அறுவடையைப் பதிவிடுங்கள்',
    'Buy Products': 'பொருட்களை வாங்கவும்',
    'Find nearby crops': 'அருகிலுள்ள பயிர்களைக் கண்டறியவும்',
    'Rent Tools': 'கருவிகளை வாடகைக்கு எடுக்கவும்',
    'Tractor, sprayer': 'டிராக்டர், தெளிப்பான்',
    'Community': 'சமூகம்',
    'Ask farmers': 'விவசாயிகளிடம் கேளுங்கள்',
    'Latest Listings': 'சமீபத்திய பட்டியல்கள்',
    'Create New Listing': 'புதிய பட்டியலை உருவாக்கவும்',
    'Item and quantity': 'பொருள் மற்றும் அளவு',
    'Price': 'விலை',
    'Publish': 'வெளியிடவும்',
    'Notifications': 'அறிவிப்புகள்',
    'Stay updated with your farm alerts':
        'உங்கள் பண்ணை எச்சரிக்கைகளை உடனுக்குடன் அறியுங்கள்',
    "Today's Alerts": 'இன்றைய எச்சரிக்கைகள்',
    '5 New Notifications': '5 புதிய அறிவிப்புகள்',
    'All Caught Up': 'அனைத்தும் பார்க்கப்பட்டது',
    'Weather • Disease • Harvest • Market': 'வானிலை • நோய் • அறுவடை • சந்தை',
    'Weather Alert': 'வானிலை எச்சரிக்கை',
    'Heavy rain expected tomorrow.': 'நாளை கனமழை எதிர்பார்க்கப்படுகிறது.',
    'Disease Warning': 'நோய் எச்சரிக்கை',
    'Possible leaf blight detected nearby.': 'அருகில் இலை கருகல் இருக்கலாம்.',
    'Market Update': 'சந்தை புதுப்பிப்பு',
    'Rice price increased by 8% today.': 'இன்று நெல் விலை 8% உயர்ந்துள்ளது.',
    'Harvest Reminder': 'அறுவடை நினைவூட்டல்',
    'Harvest Farm 01 in 12 days.': 'பண்ணை 01-ஐ 12 நாட்களில் அறுவடை செய்யவும்.',
    'Mark All as Read': 'அனைத்தையும் படித்ததாகக் குறிக்கவும்',
    'All Alerts Read': 'அனைத்து எச்சரிக்கைகளும் படிக்கப்பட்டன',
    'View Government News': 'அரசாங்க செய்திகளைப் பார்க்கவும்',
    'Government News': 'அரசாங்க செய்திகள்',
    'Agriculture News': 'விவசாய செய்திகள்',
    'View Agriculture News': 'விவசாய செய்திகளைப் பார்க்கவும்',
    'Sri Lanka Agriculture News': 'இலங்கை விவசாய செய்திகள்',
    'Live updates from Sri Lankan news sources':
        'இலங்கை செய்தி மூலங்களிலிருந்து நேரடி புதுப்பிப்புகள்',
    'Local Farmer News': 'உள்ளூர் விவசாயி செய்திகள்',
    'Agriculture stories from Daily Mirror Sri Lanka':
        'டெய்லி மிரர் இலங்கையின் விவசாயச் செய்திகள்',
    'Refresh Agriculture News': 'விவசாய செய்திகளைப் புதுப்பிக்கவும்',
    'Agriculture news updated': 'விவசாய செய்திகள் புதுப்பிக்கப்பட்டன',
    'Last checked': 'கடைசியாகச் சரிபார்த்தது',
    'Auto refresh: every 15 minutes while this page is open':
        'இந்தப் பக்கம் திறந்திருக்கும் போது ஒவ்வொரு 15 நிமிடங்களுக்கும் தானாகப் புதுப்பிக்கப்படும்',
    'No Sri Lankan agriculture news is available right now.':
        'தற்போது இலங்கை விவசாயச் செய்திகள் எதுவும் கிடைக்கவில்லை.',
    'Unable to load agriculture news. Check your internet connection and try again.':
        'விவசாய செய்திகளை ஏற்ற முடியவில்லை. இணைய இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
    'Unable to open the original article.':
        'அசல் செய்தியைத் திறக்க முடியவில்லை.',
    'Try Again': 'மீண்டும் முயற்சிக்கவும்',
    'Source': 'மூலம்',
    'Tap an article to read the original.':
        'அசல் செய்தியைப் படிக்க ஒரு செய்தியைத் தட்டவும்.',
    'Agriculture updates and announcements':
        'விவசாய புதுப்பிப்புகள் மற்றும் அறிவிப்புகள்',
    'Latest Updates': 'சமீபத்திய புதுப்பிப்புகள்',
    'Farmer News': 'விவசாயி செய்திகள்',
    'Daily notices from Agriculture Department':
        'விவசாயத் துறையின் தினசரி அறிவிப்புகள்',
    'Subsidy Program': 'மானியத் திட்டம்',
    'Fertilizer subsidy registration is now open.':
        'உர மானியப் பதிவு தற்போது திறந்துள்ளது.',
    'Training Program': 'பயிற்சித் திட்டம்',
    'Organic farming workshop - 15 July.': 'இயற்கை விவசாயப் பயிற்சி - ஜூலை 15.',
    'Weather Warning': 'வானிலை எச்சரிக்கை',
    'Heavy rainfall expected in Eastern Province.':
        'கிழக்கு மாகாணத்தில் கனமழை எதிர்பார்க்கப்படுகிறது.',
    'Grant Scheme': 'உதவித்தொகைத் திட்டம்',
    'Applications invited for smart irrigation.':
        'ஸ்மார்ட் நீர்ப்பாசனத்திற்கான விண்ணப்பங்கள் வரவேற்கப்படுகின்றன.',
    'Refresh Government News': 'அரசாங்க செய்திகளைப் புதுப்பிக்கவும்',
    'Manage your farmer account': 'உங்கள் விவசாயி கணக்கை நிர்வகிக்கவும்',
    'Personal Information': 'தனிப்பட்ட தகவல்கள்',
    'Email': 'மின்னஞ்சல்',
    'Language': 'மொழி',
    'Farm Size': 'பண்ணை அளவு',
    'Main Crop': 'முக்கிய பயிர்',
    'Account Actions': 'கணக்கு நடவடிக்கைகள்',
    'Edit Profile': 'சுயவிவரத்தைத் திருத்தவும்',
    'Update your personal information':
        'உங்கள் தனிப்பட்ட தகவல்களைப் புதுப்பிக்கவும்',
    'Change Password': 'கடவுச்சொல்லை மாற்றவும்',
    'Keep your account secure': 'உங்கள் கணக்கைப் பாதுகாப்பாக வைத்திருங்கள்',
    'Phone': 'தொலைபேசி',
    'Save': 'சேமிக்கவும்',
    'Settings': 'அமைப்புகள்',
    'Customize your AgriAI experience':
        'உங்கள் AgriAI அனுபவத்தைத் தனிப்பயனாக்கவும்',
    'App Preferences': 'செயலி விருப்பங்கள்',
    'Control language, privacy and permissions':
        'மொழி, தனியுரிமை மற்றும் அனுமதிகளைக் கட்டுப்படுத்தவும்',
    'English': 'ஆங்கிலம்',
    'Tamil': 'தமிழ்',
    'Sinhala': 'சிங்களம்',
    'Dark Mode': 'இருண்ட தோற்றம்',
    'GPS Permission': 'GPS அனுமதி',
    'Camera Permission': 'கேமரா அனுமதி',
    'Privacy': 'தனியுரிமை',
    'Manage your data preferences': 'உங்கள் தரவு விருப்பங்களை நிர்வகிக்கவும்',
    'Help & Support': 'உதவி மற்றும் ஆதரவு',
    'Open the AgriAI help center': 'AgriAI உதவி மையத்தைத் திறக்கவும்',
    'About App': 'செயலியைப் பற்றி',
    'Save Settings': 'அமைப்புகளைச் சேமிக்கவும்',
    'Permission Required': 'அனுமதி தேவை',
    'Permission is blocked. Open phone settings to enable it.':
        'அனுமதி தடுக்கப்பட்டுள்ளது. அதை இயக்க phone settings-ஐ திறக்கவும்.',
    'Permission was not granted. You can try again.':
        'அனுமதி வழங்கப்படவில்லை. மீண்டும் முயற்சி செய்யலாம்.',
    'Open Phone Settings': 'தொலைபேசி அமைப்புகளைத் திறக்கவும்',
    'Privacy & Permissions': 'தனியுரிமை மற்றும் அனுமதிகள்',
    'AgriAI stores your account, farm history and saved results in Firebase. Camera and location are used only when you choose those features.':
        'AgriAI உங்கள் கணக்கு, பண்ணை வரலாறு மற்றும் சேமித்த முடிவுகளை Firebase-ல் சேமிக்கிறது. நீங்கள் தேர்வு செய்யும் அம்சங்களில் மட்டும் கேமரா மற்றும் இருப்பிடம் பயன்படுத்தப்படும்.',
    'Unable to open this service.': 'இந்தச் சேவையைத் திறக்க முடியவில்லை.',
    'Frequently Asked Questions': 'அடிக்கடி கேட்கப்படும் கேள்விகள்',
    'Close': 'மூடவும்',
    'How do I detect a crop disease?': 'பயிர் நோயை எவ்வாறு கண்டறிவது?',
    'Open Disease Detection, upload one clear leaf photo and tap Analyze with AI.':
        'நோய் கண்டறிதலைத் திறந்து, ஒரு தெளிவான இலைப் படத்தை பதிவேற்றி AI மூலம் பகுப்பாய்வு என்பதை அழுத்தவும்.',
    'Does AgriAI work without internet?':
        'இணையம் இல்லாமல் AgriAI வேலை செய்யுமா?',
    'Disease detection works on the phone. Weather, news and Firebase features require internet.':
        'நோய் கண்டறிதல் தொலைபேசியில் வேலை செய்யும். வானிலை, செய்திகள் மற்றும் Firebase அம்சங்களுக்கு இணையம் தேவை.',
    'Why is a crop shown as not supported?':
        'ஏன் ஒரு பயிர் ஆதரிக்கப்படவில்லை என்று காட்டப்படுகிறது?',
    'The image did not confidently match one of the 25 trained crops. Retake a clear photo or use a supported crop.':
        'படம் 25 பயிற்றுவிக்கப்பட்ட பயிர்களில் ஒன்றுடன் நம்பகமாகப் பொருந்தவில்லை. தெளிவாக மீண்டும் படம் எடுக்கவும்.',
    'Send Feedback': 'கருத்தை அனுப்பவும்',
    'Your feedback': 'உங்கள் கருத்து',
    'Tell us what should be improved...':
        'எதை மேம்படுத்த வேண்டும் என்று கூறுங்கள்...',
    'Submit': 'சமர்ப்பிக்கவும்',
    'Feedback sent successfully': 'கருத்து வெற்றிகரமாக அனுப்பப்பட்டது',
    'Please enter at least 5 characters.': 'குறைந்தது 5 எழுத்துகளை உள்ளிடவும்.',
    'Call Sri Lanka agriculture advisory service 1920':
        'இலங்கை விவசாய ஆலோசனை சேவை 1920-ஐ அழைக்கவும்',
    'Email agriculture advisory support':
        'விவசாய ஆலோசனை ஆதரவுக்கு மின்னஞ்சல் அனுப்பவும்',
    'AI & official farmer support': 'AI மற்றும் அதிகாரப்பூர்வ விவசாயி ஆதரவு',
    'Call 1920 Agriculture Support': '1920 விவசாய ஆதரவை அழைக்கவும்',
    'Department of Agriculture Sri Lanka': 'இலங்கை விவசாயத் திணைக்களம்',
    'AgriAI stores account details, farm records and saved results in Firebase. Camera, microphone and location are accessed only after permission and only for the feature you choose. Do not upload confidential images.':
        'AgriAI கணக்கு விவரங்கள், பண்ணை பதிவுகள் மற்றும் சேமித்த முடிவுகளை Firebase-ல் சேமிக்கிறது. அனுமதி வழங்கிய பின்னர் நீங்கள் தேர்ந்தெடுக்கும் அம்சத்திற்கு மட்டுமே கேமரா, மைக்ரோஃபோன் மற்றும் இருப்பிடம் பயன்படுத்தப்படும். இரகசிய படங்களைப் பதிவேற்ற வேண்டாம்.',
    'AgriAI predictions, weather advice and profit figures are estimates for educational support. Confirm important farming and pesticide decisions with a qualified agriculture officer.':
        'AgriAI கணிப்புகள், வானிலை ஆலோசனை மற்றும் லாபத் தொகைகள் கல்வி ஆதரவுக்கான மதிப்பீடுகள். முக்கிய விவசாய மற்றும் பூச்சிக்கொல்லி முடிவுகளை தகுதியான விவசாய அதிகாரியுடன் உறுதிப்படுத்தவும்.',
    'Add a verified email to reset your password.':
        'கடவுச்சொல்லை மீட்டமைக்க சரிபார்க்கப்பட்ட மின்னஞ்சலைச் சேர்க்கவும்.',
    'About AgriAI': 'AgriAI பற்றி',
    'AI Smart Farming Platform': 'AI ஸ்மார்ட் விவசாயத் தளம்',
    'Developed By': 'உருவாக்கியவர்கள்',
    'Technology': 'தொழில்நுட்பம்',
    'Languages': 'மொழிகள்',
    'Privacy Policy': 'தனியுரிமைக் கொள்கை',
    'View how your information is protected':
        'உங்கள் தகவல்கள் எவ்வாறு பாதுகாக்கப்படுகின்றன என்பதைப் பார்க்கவும்',
    'Terms & Conditions': 'விதிமுறைகள் மற்றும் நிபந்தனைகள்',
    'View application terms': 'செயலி விதிமுறைகளைப் பார்க்கவும்',
    'Official Website': 'அதிகாரப்பூர்வ இணையதளம்',
    'Contact': 'தொடர்பு',
    'Visit Website': 'இணையதளத்தைப் பார்வையிடவும்',
    'Help Center': 'உதவி மையம்',
    'Get support and farming guidance':
        'ஆதரவும் விவசாய வழிகாட்டுதலும் பெறுங்கள்',
    'Need Assistance?': 'உதவி தேவையா?',
    "We're Here to Help": 'உதவ நாங்கள் இருக்கிறோம்',
    '24/7 AI & Farmer Support': '24/7 AI மற்றும் விவசாயி ஆதரவு',
    'FAQs': 'அடிக்கடி கேட்கப்படும் கேள்விகள்',
    'Common farming questions': 'பொதுவான விவசாயக் கேள்விகள்',
    'Video Tutorials': 'வீடியோ வழிகாட்டிகள்',
    'Learn with step-by-step guides':
        'படிப்படியான வழிகாட்டிகள் மூலம் கற்றுக்கொள்ளுங்கள்',
    'AI Chat Assistant': 'AI அரட்டை உதவியாளர்',
    'Ask farming questions instantly':
        'விவசாயக் கேள்விகளை உடனடியாகக் கேளுங்கள்',
    'Agriculture Officer': 'விவசாய அதிகாரி',
    'Contact your local officer': 'உங்கள் உள்ளூர் அதிகாரியைத் தொடர்புகொள்ளவும்',
    'Feedback': 'கருத்து',
    'Share your suggestions': 'உங்கள் பரிந்துரைகளைப் பகிருங்கள்',
    'Customer Support': 'வாடிக்கையாளர் ஆதரவு',
    'Email and phone support': 'மின்னஞ்சல் மற்றும் தொலைபேசி ஆதரவு',
    'Contact Support': 'ஆதரவைத் தொடர்புகொள்ளவும்',
    'AI Farming Assistant': 'AI விவசாய உதவியாளர்',
    'Ask anything about your crops':
        'உங்கள் பயிர்களைப் பற்றி எதையும் கேளுங்கள்',
    'Hello Farmer!': 'வணக்கம் விவசாயி!',
    'How can I help you today?': 'இன்று நான் உங்களுக்கு எப்படி உதவலாம்?',
    'Hello Farmer! How can I help you today?':
        'வணக்கம் விவசாயி! இன்று நான் எப்படி உதவலாம்?',
    'What crop is best for clay soil?': 'களிமண்ணுக்கு எந்த பயிர் சிறந்தது?',
    'Rice and maize are suitable. Upload soil details for a more accurate AI recommendation.':
        'நெல் மற்றும் சோளம் ஏற்றவை. துல்லியமான AI பரிந்துரைக்கு மண் விவரங்களைப் பதிவேற்றவும்.',
    'Based on your farm profile, I recommend checking soil moisture and the 7-day weather forecast before planting.':
        'உங்கள் பண்ணை விவரத்தின் அடிப்படையில், பயிரிடுமுன் மண் ஈரப்பதத்தையும் 7 நாள் வானிலையையும் சரிபார்க்க பரிந்துரைக்கிறேன்.',
    'Type your message...': 'உங்கள் செய்தியை உள்ளிடுங்கள்...',
    'AI Voice Assistant': 'AI குரல் உதவியாளர்',
    'Talk to your farming assistant': 'உங்கள் விவசாய உதவியாளருடன் பேசுங்கள்',
    'Tap to Speak': 'பேச தட்டவும்',
    'Listening...': 'கேட்கிறது...',
    'Ask your farming question now':
        'உங்கள் விவசாயக் கேள்வியை இப்போது கேளுங்கள்',
    'Voice support in Tamil, Sinhala and English':
        'தமிழ், சிங்களம் மற்றும் ஆங்கிலத்தில் குரல் ஆதரவு',
    'Conversation': 'உரையாடல்',
    'What crop is suitable this season?':
        'இந்தப் பருவத்திற்கு எந்த பயிர் ஏற்றது?',
    'Rice is recommended based on your location and weather.':
        'உங்கள் இருப்பிடம் மற்றும் வானிலையின் அடிப்படையில் நெல் பரிந்துரைக்கப்படுகிறது.',
    'Start Voice Chat': 'குரல் உரையாடலைத் தொடங்கவும்',
    'Stop Voice Chat': 'குரல் உரையாடலை நிறுத்தவும்',
    'Mon': 'திங்கள்',
    'Monday': 'திங்கள்',
    'Tue': 'செவ்வாய்',
    'Tuesday': 'செவ்வாய்',
    'Wed': 'புதன்',
    'Wednesday': 'புதன்',
    'Thu': 'வியாழன்',
    'Thursday': 'வியாழன்',
    'Fri': 'வெள்ளி',
    'Friday': 'வெள்ளி',
    'Sat': 'சனி',
    'Saturday': 'சனி',
    'Sun': 'ஞாயிறு',
    'Sunday': 'ஞாயிறு',
    'Location': 'இருப்பிடம்',
    'Area': 'பரப்பளவு',
    'Trincomalee': 'திருகோணமலை',
    'Batticaloa': 'மட்டக்களப்பு',
    'Not selected': 'தேர்ந்தெடுக்கப்படவில்லை',
    'Leaf Blight': 'இலை கருகல்',
    '10–14 Days': '10–14 நாட்கள்',
    '120 Days': '120 நாட்கள்',
    'Urea + Compost': 'யூரியா + இயற்கை உரம்',
    'Rice - 500kg available': 'நெல் - 500 கிலோ கிடைக்கிறது',
    'Chili - 80kg available': 'மிளகாய் - 80 கிலோ கிடைக்கிறது',
    'Sprayer rental': 'தெளிப்பான் வாடகை',
    'Rs. 1500/day': 'ரூ. 1500/நாள்',
    'Password recovery link requested': 'கடவுச்சொல் மீட்பு இணைப்பு கோரப்பட்டது',
    'Crop recommendation report generated':
        'பயிர் பரிந்துரை அறிக்கை உருவாக்கப்பட்டது',
    'Unable to open image source': 'பட மூலத்தைத் திறக்க முடியவில்லை',
    'Treatment report generated': 'சிகிச்சை அறிக்கை உருவாக்கப்பட்டது',
    'Forecast updated': 'வானிலை முன்னறிவிப்பு புதுப்பிக்கப்பட்டது',
    'Profit estimate updated': 'லாப மதிப்பீடு புதுப்பிக்கப்பட்டது',
    'Farm analytics refreshed': 'பண்ணை பகுப்பாய்வு புதுப்பிக்கப்பட்டது',
    'Nearby products loaded': 'அருகிலுள்ள பொருட்கள் ஏற்றப்பட்டன',
    'Rental tools loaded': 'வாடகைக் கருவிகள் ஏற்றப்பட்டன',
    'News updated': 'செய்திகள் புதுப்பிக்கப்பட்டன',
    'Settings saved': 'அமைப்புகள் சேமிக்கப்பட்டன',
    'Image attachment ready': 'பட இணைப்பு தயாராக உள்ளது',
    'Live Gemini AI • Free tier': 'நேரடி Gemini AI • இலவச நிலை',
    'Use Disease Detection for leaf images':
        'இலைப் படங்களுக்கு நோய் கண்டறிதலைப் பயன்படுத்துங்கள்',
    'AI security setup is not finished. Register this device App Check debug token in Firebase Console.':
        'AI பாதுகாப்பு அமைப்பு இன்னும் முடியவில்லை. இந்த சாதனத்தின் App Check debug token-ஐ Firebase Console-ல் பதிவு செய்யுங்கள்.',
    'Enable Firebase AI Logic with the free Gemini Developer API, then try again.':
        'இலவச Gemini Developer API உடன் Firebase AI Logic-ஐ இயக்கி மீண்டும் முயற்சிக்கவும்.',
    'AI assistant is unavailable now. Check the internet and try again.':
        'AI உதவியாளர் இப்போது கிடைக்கவில்லை. இணையத்தைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
    'Farm Map': 'பண்ணை வரைபடம்',
    'Free OpenStreetMap • No API key or billing':
        'இலவச OpenStreetMap • API key அல்லது கட்டணம் இல்லை',
    'Selected farm location': 'தேர்ந்தெடுத்த பண்ணை இருப்பிடம்',
    'Use current location': 'தற்போதைய இருப்பிடத்தைப் பயன்படுத்து',
    'Turn on phone location services.': 'தொலைபேசி இருப்பிட சேவையை இயக்குங்கள்.',
    'Location permission is required to show your position.':
        'உங்கள் இருப்பிடத்தைக் காட்ட location அனுமதி தேவை.',
    'Unable to get your current location.':
        'உங்கள் தற்போதைய இருப்பிடத்தைப் பெற முடியவில்லை.',
    'Tap the map to move the farm marker':
        'பண்ணை குறியீட்டை நகர்த்த வரைபடத்தைத் தொடவும்',
    'Open Free Farm Map': 'இலவச பண்ணை வரைபடத்தைத் திறக்கவும்',
    'Allow notifications in phone settings':
        'தொலைபேசி அமைப்பில் அறிவிப்புகளை அனுமதிக்கவும்',
    'Test notification sent': 'சோதனை அறிவிப்பு அனுப்பப்பட்டது',
    'Unable to send test notification': 'சோதனை அறிவிப்பை அனுப்ப முடியவில்லை',
    'Test Phone Notification': 'தொலைபேசி அறிவிப்பைச் சோதிக்கவும்',
    'Free push notification setup is working.':
        'இலவச push அறிவிப்பு அமைப்பு வேலை செய்கிறது.',
    'Free AI Setup': 'இலவச AI அமைப்பு',
    'Groq API key': 'Groq API சாவி',
    'Create free Groq key': 'இலவச Groq சாவியை உருவாக்கவும்',
    'Voice Status': 'குரல் நிலை',
    'Voice fallback': 'மாற்று உரை உள்ளீடு',
    'Type your farming question if speech is unavailable':
        'குரல் கிடைக்காவிட்டால் உங்கள் விவசாயக் கேள்வியை தட்டச்சு செய்யவும்',
    'Real farm analytics and downloadable files':
        'உண்மையான பண்ணை பகுப்பாய்வு மற்றும் பதிவிறக்க அறிக்கைகள்',
    'Professional Summary': 'தொழில்முறை சுருக்கம்',
    'Your Data Summary': 'உங்கள் தரவு சுருக்கம்',
    'Active Farms': 'செயலில் உள்ள பண்ணைகள்',
    'Crop Recommendations': 'பயிர் பரிந்துரைகள்',
    'Disease Scans': 'நோய் பரிசோதனைகள்',
    'Profit Plans': 'லாபத் திட்டங்கள்',
    'Report Content': 'அறிக்கை உள்ளடக்கம்',
    'Export Format': 'ஏற்றுமதி வடிவம்',
    'Creating report...': 'அறிக்கை உருவாக்கப்படுகிறது...',
    'Crop, area and harvest tracking in one place':
        'பயிர், நில அளவு மற்றும் அறுவடையை ஒரே இடத்தில் கண்காணிக்கவும்',
    'Planting Date': 'நடவு தேதி',
    'Expected Harvest': 'எதிர்பார்க்கப்படும் அறுவடை',
    'Notes': 'குறிப்புகள்',
    'Optional': 'விருப்பமானது',
    'Save Farm': 'பண்ணையைச் சேமிக்கவும்',
    'Delete Farm': 'பண்ணையை நீக்கவும்',
    'Remove': 'அகற்றவும்',
    'Delete': 'நீக்கவும்',
    'Next Harvest': 'அடுத்த அறுவடை',
    'Harvest': 'அறுவடை',
    'Harvest date not set': 'அறுவடை தேதி அமைக்கப்படவில்லை',
    'days remaining': 'நாட்கள் மீதம்',
    'Analytics': 'பகுப்பாய்வு',
    'Next 5 Days - Best Crop': 'அடுத்த 5 நாட்கள் - சிறந்த பயிர்',
    'Detailed 7-Day Crop Advice': 'விரிவான 7 நாள் பயிர் ஆலோசனை',
    'suitable': 'பொருத்தம்',
    'Price source': 'விலை மூலம்',
    '25-crop planning reference': '25 பயிர் திட்டமிடல் குறிப்பு',
    'Community Market average': 'சமூக சந்தை சராசரி',
    'Update Yield & Current Price':
        'விளைச்சல் மற்றும் தற்போதைய விலையை புதுப்பிக்கவும்',
    'Updating yield and price...':
        'விளைச்சல் மற்றும் விலை புதுப்பிக்கப்படுகிறது...',
    'All 25 Crops - Planning Price Reference':
        'அனைத்து 25 பயிர்கள் - திட்டமிடல் விலைக் குறிப்பு',
    'Call HARTI price service 6666': 'HARTI விலை சேவை 6666-ஐ அழைக்கவும்',
    'These are editable planning estimates, not extracted live HARTI prices. Confirm the current daily price before selling.':
        'இவை மாற்றக்கூடிய திட்டமிடல் மதிப்பீடுகள்; நேரடி HARTI விலைகள் அல்ல. விற்பனைக்கு முன் இன்றைய விலையை உறுதி செய்யவும்.',
    'Offline Farming Help • Tap for Free AI Setup':
        'Offline விவசாய உதவி • இலவச AI அமைப்பிற்கு தட்டவும்',
    'Qwen Online AI • Groq Free Plan': 'Qwen Online AI • Groq இலவச திட்டம்',
    'Real speech recognition and spoken farming guidance':
        'உண்மையான குரல் அங்கீகாரம் மற்றும் விவசாய வழிகாட்டல்',
    'Tamil, Sinhala and English device speech support':
        'தமிழ், சிங்களம் மற்றும் ஆங்கில குரல் ஆதரவு',
    'Microphone or speech service is unavailable':
        'மைக்ரோஃபோன் அல்லது குரல் சேவை கிடைக்கவில்லை',
    'Preparing Microphone...': 'மைக்ரோஃபோன் தயாராகிறது...',
    'Preparing Answer...': 'பதில் தயாராகிறது...',
    'Voice Wave': 'குரல் அலை',
    'Listening to your question...': 'உங்கள் கேள்வி கேட்கப்படுகிறது...',
    'Stop & Answer': 'நிறுத்தி பதிலளிக்கவும்',
    '25 crops • Editable costs • Automatic yield and price':
        '25 பயிர்கள் • மாற்றக்கூடிய செலவுகள் • தானியங்கி விளைச்சல் மற்றும் விலை',
    'Automatically calculated from crop and land':
        'பயிர் மற்றும் நில அளவிலிருந்து தானாகக் கணக்கிடப்படுகிறது',
    'Automatically loaded for the selected crop':
        'தேர்ந்தெடுத்த பயிருக்குத் தானாக ஏற்றப்படுகிறது',
    'Yield and selling price are selected automatically. Enter only your actual planting, input and labour costs. Confirm the market price before making a farming decision.':
        'விளைச்சல் மற்றும் விற்பனை விலை தானாகத் தேர்ந்தெடுக்கப்படும். உங்கள் உண்மையான நடவு, உள்ளீடு மற்றும் தொழிலாளர் செலவுகளை மட்டும் உள்ளிடவும். விவசாய முடிவுக்கு முன் சந்தை விலையை உறுதி செய்யவும்.',
    'Selected Crop Match': 'தேர்ந்தெடுத்த பயிர் பொருத்தம்',
    'Dataset test accuracy: 92.55%. Real field-photo accuracy varies with lighting, focus and background.':
        'Dataset சோதனை துல்லியம்: 92.55%. உண்மையான வயல் படத் துல்லியம் வெளிச்சம், focus மற்றும் பின்னணியைப் பொறுத்து மாறும்.',
    'Photo ready. Select the correct crop when known, then analyze.':
        'படம் தயாராக உள்ளது. பயிர் தெரிந்தால் சரியான பயிரைத் தேர்ந்தெடுத்து பகுப்பாய்வு செய்யவும்.',
    'Disease Result Uncertain': 'நோய் முடிவு உறுதியாக இல்லை',
    'Low Confidence Image': 'குறைந்த நம்பகத்தன்மை கொண்ட படம்',
    'Disease uncertain': 'நோய் உறுதியாக இல்லை',
    'Unable to identify this crop safely':
        'இந்தப் பயிரை பாதுகாப்பாக அடையாளம் காண முடியவில்லை',
    'The selected crop is supported, but the disease pattern is not clear enough.':
        'தேர்ந்தெடுத்த பயிர் ஆதரிக்கப்படுகிறது; ஆனால் நோய் வடிவம் போதுமான அளவு தெளிவாக இல்லை.',
    'Selected Crop': 'தேர்ந்தெடுத்த பயிர்',
    'Possible Crop': 'சாத்தியமான பயிர்',
    'Disease Confidence': 'நோய் நம்பகத்தன்மை',
    'Uncertain - Retake Photo': 'உறுதியாக இல்லை - மீண்டும் படம் எடுக்கவும்',
    '• Fill most of the photo with one leaf only.':
        '• ஒரே ஒரு இலை படத்தின் பெரும்பகுதியை நிரப்புமாறு எடுக்கவும்.',
    '• Keep the damaged area visible and avoid branches or other leaves.':
        '• பாதிக்கப்பட்ட பகுதியை தெளிவாகக் காட்டி கிளைகள் அல்லது மற்ற இலைகளைத் தவிர்க்கவும்.',
    '• Select the crop manually when you know its name.':
        '• பயிரின் பெயர் தெரிந்தால் அதை கைமுறையாகத் தேர்ந்தெடுக்கவும்.',
    'Preliminary AI Result': 'ஆரம்ப AI முடிவு',
    'Possible Disease': 'சாத்தியமான நோய்',
    'Possible': 'சாத்தியமான',
    'Low confidence — verify before treatment':
        'குறைந்த நம்பகத்தன்மை — சிகிச்சைக்கு முன் உறுதி செய்யவும்',
    'Select the crop manually for a disease estimate':
        'நோய் மதிப்பீட்டிற்கு பயிரை கைமுறையாகத் தேர்ந்தெடுக்கவும்',
    'Select Crop First': 'முதலில் பயிரைத் தேர்ந்தெடுக்கவும்',
    'Top 3 Possible AI Matches': 'சாத்தியமான முதல் 3 AI பொருத்தங்கள்',
    'This is a preliminary low-confidence AI estimate, not a confirmed diagnosis. Do not apply chemicals without agriculture-officer advice.':
        'இது குறைந்த நம்பகத்தன்மை கொண்ட ஆரம்ப AI மதிப்பீடு; உறுதிப்படுத்தப்பட்ட நோயறிதல் அல்ல. விவசாய அதிகாரியின் ஆலோசனையின்றி இரசாயனங்களைப் பயன்படுத்த வேண்டாம்.',
  },
  'si': {
    'Signing in...': 'පිවිසෙමින්...',
    'Creating account...': 'ගිණුම සාදමින්...',
    'Saving recommendation...': 'නිර්දේශය සුරකිමින්...',
    'Profile updated': 'පැතිකඩ යාවත්කාලීන කරන ලදී',
    'Sign Out': 'පිටවන්න',
    'Not provided': 'ලබා දී නැත',
    'Farm saved to Firebase': 'ගොවිපළ Firebase වෙත සුරකින ලදී',
    'No farms yet. Add your first farm.':
        'තවම ගොවිපළ නැත. ඔබගේ පළමු ගොවිපළ එක් කරන්න.',
    'Listing published to Firebase': 'වෙළඳ දැන්වීම Firebase වෙත පළ කරන ලදී',
    'All notifications marked as read':
        'සියලු දැනුම්දීම් කියවූ ලෙස සලකුණු කරන ලදී',
    'No notifications yet.': 'තවම දැනුම්දීම් නැත.',
    'Profit estimate saved': 'ලාභ ඇස්තමේන්තුව සුරකින ලදී',
    'Please login again.': 'කරුණාකර නැවත පිවිසෙන්න.',
    'Firebase is not ready. Check google-services.json and rebuild the app.':
        'Firebase සූදානම් නැත. google-services.json පරීක්ෂා කර app එක නැවත build කරන්න.',
    'This phone number is already registered.':
        'මෙම දුරකථන අංකය දැනටමත් ලියාපදිංචි කර ඇත.',
    'Phone number or password is incorrect.': 'දුරකථන අංකය හෝ මුරපදය වැරදියි.',
    'Email/phone number or password is incorrect.':
        'ඊමේල්/දුරකථන අංකය හෝ මුරපදය වැරදියි.',
    'Phone login is not linked on this device. Sign in once with your registered email; then this phone number will work.':
        'මෙම උපාංගයේ දුරකථන පිවිසීම තවම සම්බන්ධ කර නැත. ලියාපදිංචි ඊමේල් ලිපිනයෙන් වරක් පිවිසෙන්න; ඉන්පසු මෙම දුරකථන අංකය ක්‍රියා කරයි.',
    'Use a stronger password with at least 6 characters.':
        'අවම වශයෙන් අක්ෂර 6ක් සහිත ශක්තිමත් මුරපදයක් භාවිත කරන්න.',
    'No internet connection. Please try again.':
        'අන්තර්ජාල සම්බන්ධතාවයක් නැත. නැවත උත්සාහ කරන්න.',
    'Enable Email/Password in Firebase Authentication.':
        'Firebase Authentication තුළ Email/Password ක්‍රමය සක්‍රීය කරන්න.',
    'Firestore access denied. Create the database and publish the security rules.':
        'Firestore ප්‍රවේශය ප්‍රතික්ෂේප විය. Database එක සාදා security rules පළ කරන්න.',
    'Firebase is temporarily unavailable. Check your connection.':
        'Firebase තාවකාලිකව ලබාගත නොහැක. සම්බන්ධතාවය පරීක්ෂා කරන්න.',
    'Password reset will be added with verified email.':
        'Email තහවුරු කිරීම සමඟ password reset පසුව එක් කෙරේ.',
    'New Farm': 'නව ගොවිපළ',
    '1 Acre': 'අක්කර 1',
    'Farm': 'ගොවිපළ',
    'Farmer': 'ගොවියා',
    'New farm listing': 'නව ගොවිපළ වෙළඳ දැන්වීම',
    'Contact seller': 'විකුණුම්කරු අමතන්න',
    'Farm listing': 'ගොවිපළ වෙළඳ දැන්වීම',
    'Notification': 'දැනුම්දීම',
    'Empowering Farmers\nThrough Artificial Intelligence':
        'කෘත්‍රිම බුද්ධියෙන්\nගොවීන් සවිබල ගැන්වීම',
    'Preparing your farming assistant...': 'ඔබේ ගොවි සහායකයා සූදානම් වෙමින්...',
    'AI Advisory': 'AI උපදේශන',
    'Weather': 'කාලගුණය',
    'Disease': 'රෝග',
    'Profit': 'ලාභය',
    'Grow Smart • Grow Better • Grow Together':
        'බුද්ධිමත්ව වවමු • හොඳින් වවමු • එක්ව වවමු',
    'Choose Language': 'භාෂාව තෝරන්න',
    'Select your preferred language': 'ඔබ කැමති භාෂාව තෝරන්න',
    'Tap to hear language preview': 'භාෂා පෙරදසුන ඇසීමට තට්ටු කරන්න',
    'Continue': 'ඉදිරියට',
    'Phone Number': 'දුරකථන අංකය',
    'Phone Number or Email': 'දුරකථන අංකය හෝ ඊමේල්',
    'On a new device, sign in with email once to enable phone login.':
        'නව උපාංගයක දුරකථන පිවිසීම සක්‍රිය කිරීමට පළමුව ඊමේල් ලිපිනයෙන් වරක් පිවිසෙන්න.',
    'Welcome Back': 'නැවත සාදරයෙන් පිළිගනිමු',
    'Sign in to continue to AgriAI': 'AgriAI වෙත ඉදිරියට යාමට පිවිසෙන්න',
    'Password': 'මුරපදය',
    'Show password': 'මුරපදය පෙන්වන්න',
    'Hide password': 'මුරපදය සඟවන්න',
    'Remember me': 'මාව මතක තබාගන්න',
    'Forgot?': 'අමතකද?',
    'Fingerprint': 'ඇඟිලි සලකුණ',
    'Face': 'මුහුණ',
    'OR USE BIOMETRICS': 'හෝ ජෛවමිතික භාවිත කරන්න',
    'Reset Password': 'මුරපදය නැවත සකසන්න',
    'Enter the exact email address used to create your account.':
        'ඔබගේ ගිණුම සෑදීමට භාවිත කළ නිවැරදි ඊමේල් ලිපිනය ඇතුළත් කරන්න.',
    'Recovery Email': 'ප්‍රතිසාධන ඊමේල්',
    'Send Reset Link': 'නැවත සැකසීමේ සබැඳිය යවන්න',
    'A phone number cannot receive an email reset link. Use your registered login email.':
        'ඊමේල් නැවත සැකසීමේ සබැඳියක් දුරකථන අංකයකට ලැබෙන්නේ නැත. ලියාපදිංචි පිවිසුම් ඊමේල් ලිපිනය භාවිත කරන්න.',
    'Reset Link Requested': 'නැවත සැකසීමේ සබැඳිය ඉල්ලන ලදී',
    'If this email belongs to an AgriAI account, Firebase will send a reset link to:':
        'මෙම ඊමේල් ලිපිනය AgriAI ගිණුමකට අයත් නම්, Firebase නැවත සැකසීමේ සබැඳිය මෙයට යවයි:',
    'Check Inbox and Spam. Delivery can take a few minutes. For an old phone-only account, login once and add a verified email in Profile.':
        'Inbox සහ Spam පරීක්ෂා කරන්න. ඊමේල් ලැබීමට මිනිත්තු කිහිපයක් ගත විය හැක. පැරණි දුරකථන අංකය පමණක් ඇති ගිණුමක් නම්, වරක් පිවිස Profile තුළ තහවුරු කළ ඊමේල් ලිපිනයක් එක් කරන්න.',
    'OK': 'හරි',
    'Email for Login & Recovery': 'පිවිසීම සහ ප්‍රතිසාධනය සඳහා ඊමේල්',
    'Enter a valid email address': 'වලංගු ඊමේල් ලිපිනයක් ඇතුළත් කරන්න',
    'Enter a valid phone number or email':
        'වලංගු දුරකථන අංකයක් හෝ ඊමේල් ලිපිනයක් ඇතුළත් කරන්න',
    'Login once with your email/phone and password to enable biometric login.':
        'ජෛවමිතික පිවිසීම සක්‍රිය කිරීමට පළමුව ඊමේල්/දුරකථන අංකය සහ මුරපදය සමඟ පිවිසෙන්න.',
    'Login with “Remember me” enabled before using fingerprint or face login.':
        'ඇඟිලි සලකුණ හෝ මුහුණ භාවිත කිරීමට පෙර “මාව මතක තබාගන්න” සක්‍රිය කර පිවිසෙන්න.',
    'No fingerprint or face biometric is enrolled. Add one in Phone Settings first.':
        'ඇඟිලි සලකුණක් හෝ මුහුණු ජෛවමිතිකයක් ලියාපදිංචි කර නැත. පළමුව Phone Settings තුළ එකක් එක් කරන්න.',
    'Biometric authentication was cancelled or not recognized.':
        'ජෛවමිතික සත්‍යාපනය අවලංගු කරන ලදී හෝ හඳුනාගත නොහැකි විය.',
    'LOGIN': 'පිවිසෙන්න',
    "Don't have an account?": 'ගිණුමක් නැද්ද?',
    'Register Now': 'දැන් ලියාපදිංචි වන්න',
    'Account created. Please login.': 'ගිණුම සාදන ලදී. පිවිසෙන්න.',
    'Create Account': 'ගිණුම සාදන්න',
    'Join AgriAI Smart Farming': 'AgriAI ස්මාර්ට් ගොවිතැන සමඟ එක්වන්න',
    'Full Name': 'සම්පූර්ණ නම',
    'Email (Optional)': 'විද්‍යුත් තැපෑල (විකල්ප)',
    'Confirm Password': 'මුරපදය තහවුරු කරන්න',
    'District': 'දිස්ත්‍රික්කය',
    'Farm Name': 'ගොවිපළේ නම',
    'Already have an account? Login': 'දැනටමත් ගිණුමක් තිබේද? පිවිසෙන්න',
    'Please select your district': 'ඔබේ දිස්ත්‍රික්කය තෝරන්න',
    'Required field': 'මෙය අනිවාර්යයි',
    'Use at least 6 characters': 'අවම වශයෙන් අක්ෂර 6ක් භාවිතා කරන්න',
    'Passwords do not match': 'මුරපද නොගැලපේ',
    'Enter a valid phone number': 'වලංගු දුරකථන අංකයක් ඇතුළත් කරන්න',
    'Enter your password': 'ඔබේ මුරපදය ඇතුළත් කරන්න',
    'Your smart farming dashboard': 'ඔබේ ස්මාර්ට් ගොවි මුල් පිටුව',
    'Good Morning': 'සුබ උදෑසනක්',
    'Good Afternoon': 'සුබ දහවලක්',
    'Good Evening': 'සුබ සන්ධ්‍යාවක්',
    'Welcome': 'සාදරයෙන් පිළිගනිමු',
    'Loading weather...': 'කාලගුණ තොරතුරු පූරණය වෙමින්...',
    'Weather unavailable': 'කාලගුණ තොරතුරු නොමැත',
    'Refresh': 'යාවත්කාලීන කරන්න',
    'Welcome, Farmer': 'සාදරයෙන් පිළිගනිමු, ගොවි මහතා',
    "Today's Weather: 29°C • Sunny": 'අද කාලගුණය: 29°C • හිරු එළිය',
    'Crop': 'බෝග',
    'My Farm': 'මගේ ගොවිපළ',
    'Reports': 'වාර්තා',
    'Market': 'වෙළඳපොළ',
    'Profile': 'පැතිකඩ',
    'AI Farming Tip': 'AI ගොවි උපදෙස',
    'Water crops early morning to reduce evaporation and improve absorption.':
        'වාෂ්පීකරණය අඩු කිරීමට උදෑසනම බෝගවලට ජලය දෙන්න.',
    'Ask AgriAI Assistant': 'AgriAI සහායකයාගෙන් අසන්න',
    'Crop Advisory': 'බෝග උපදේශනය',
    'AI crop recommendation for your farm': 'ඔබේ ගොවිපළ සඳහා AI බෝග නිර්දේශය',
    'Smart Crop Advisor': 'ස්මාර්ට් බෝග උපදේශක',
    'Find Best Crop': 'හොඳම බෝගය සොයන්න',
    'Based on soil, season and your farm location':
        'පස, කන්නය සහ ගොවිපළ පිහිටීම අනුව',
    'Farm Details': 'ගොවිපළ විස්තර',
    'Location / District': 'ස්ථානය / දිස්ත්‍රික්කය',
    'Soil Type': 'පස් වර්ගය',
    'Sandy': 'වැලි පස',
    'Clay': 'මැටි පස',
    'Loamy': 'ලෝම පස',
    'Season': 'කන්නය',
    'Rainy Season': 'වැසි කන්නය',
    'Dry Season': 'වියළි කන්නය',
    'Water Source': 'ජල මූලාශ්‍රය',
    'Irrigation': 'වාරිමාර්ග',
    'Rain Water': 'වැසි ජලය',
    'Well': 'ළිඳ',
    'Land Size (Acres)': 'ඉඩම් ප්‍රමාණය (අක්කර)',
    'acres': 'අක්කර',
    'Get AI Recommendation': 'AI නිර්දේශය ලබාගන්න',
    'AI Output Preview': 'AI ප්‍රතිඵල පෙරදසුන',
    'Recommended crop • Expected yield • Risk level • Water requirement • Profit prediction':
        'නිර්දේශිත බෝගය • අපේක්ෂිත අස්වැන්න • අවදානම • ජල අවශ්‍යතාව • ලාභ අනාවැකිය',
    'AI Recommendation': 'AI නිර්දේශය',
    'Best crop recommendation for your land': 'ඔබේ ඉඩම සඳහා හොඳම බෝග නිර්දේශය',
    'AI Analysis Complete': 'AI විශ්ලේෂණය සම්පූර්ණයි',
    'Rice is Recommended': 'වී නිර්දේශ කර ඇත',
    'Confidence Score: 96%': 'විශ්වාසනීයත්වය: 96%',
    'Recommendation Summary': 'නිර්දේශ සාරාංශය',
    'Expected Yield': 'අපේක්ෂිත අස්වැන්න',
    'Growing Period': 'වර්ධන කාලය',
    'Water Requirement': 'ජල අවශ්‍යතාව',
    'Fertilizer': 'පොහොර',
    'Estimated Profit': 'ඇස්තමේන්තුගත ලාභය',
    'Risk Level': 'අවදානම් මට්ටම',
    'Low': 'අඩු',
    'Medium': 'මධ්‍යම',
    'AI Suggestions': 'AI යෝජනා',
    '✓ Start planting within the next 7 days.':
        '✓ ඉදිරි දින 7 තුළ වගාව ආරම්භ කරන්න.',
    '✓ Use drip irrigation to save water.':
        '✓ ජලය ඉතිරි කිරීමට බිංදු වාරිමාර්ග භාවිතා කරන්න.',
    '✓ Check the field after heavy rainfall.':
        '✓ තද වැසි පසු කෙත පරීක්ෂා කරන්න.',
    'Download Report': 'වාර්තාව බාගන්න',
    'Analyzing farm and weather...': 'ගොවිපළ සහ කාලගුණය විශ්ලේෂණය කරමින්...',
    'Analysis Complete': 'විශ්ලේෂණය සම්පූර්ණයි',
    'Suitability Score': 'යෝග්‍යතා ලකුණු',
    'No recommendation yet': 'තවම නිර්දේශයක් නොමැත',
    'Enter your farm details to generate a recommendation.':
        'නිර්දේශයක් ලබාගැනීමට ගොවිපළ විස්තර ඇතුළත් කරන්න.',
    'Open Crop Advisory': 'බෝග උපදේශනය විවෘත කරන්න',
    'Estimated Investment': 'ඇස්තමේන්තුගත ආයෝජනය',
    'Estimated Revenue': 'ඇස්තමේන්තුගත ආදායම',
    'High': 'ඉහළ',
    'Why this crop?': 'මෙම බෝගය තෝරාගත්තේ ඇයි?',
    'Soil condition matches this crop.': 'පස් තත්ත්වය මෙම බෝගයට ගැළපේ.',
    'Season and water source match this crop.':
        'කන්නය සහ ජල මූලාශ්‍රය මෙම බෝගයට ගැළපේ.',
    'District crop pattern was included.':
        'දිස්ත්‍රික් බෝග රටාවද ගණනයට ඇතුළත් විය.',
    'Live 7-day weather was included.': 'සජීවී දින 7 කාලගුණය ගණනයට ඇතුළත් විය.',
    'Live 7-day weather included in this score.':
        'මෙම ලකුණට සජීවී දින 7 කාලගුණය ඇතුළත්ය.',
    'Weather was unavailable; farm details were used.':
        'කාලගුණය නොලැබුණු නිසා ගොවිපළ විස්තර භාවිතා විය.',
    'Top 5 Crops': 'හොඳම බෝග 5',
    'View all 25 crop rankings': 'බෝග 25ම ශ්‍රේණිගත කිරීම බලන්න',
    'Every trained crop is checked for your farm.':
        'පුහුණු කළ බෝග 25ම ඔබේ ගොවිපළ සඳහා පරීක්ෂා කෙරේ.',
    'Open Profit Planner': 'ලාභ සැලසුම්කරු විවෘත කරන්න',
    'Review 7-Day Weather': 'දින 7 කාලගුණය බලන්න',
    'Yield and profit are estimates. Confirm soil tests, input costs and market prices before planting.':
        'අස්වැන්න සහ ලාභය ඇස්තමේන්තු වේ. වගාවට පෙර පස් පරීක්ෂණ, වියදම් සහ වෙළඳපොළ මිල තහවුරු කරන්න.',
    'Disease Detection': 'බෝග රෝග හඳුනාගැනීම',
    'AI-powered plant health scanner': 'AI ශාක සෞඛ්‍ය ස්කෑනරය',
    'AI Plant Scanner': 'AI ශාක ස්කෑනරය',
    'Scan Plant Disease': 'බෝග රෝගය ස්කෑන් කරන්න',
    'Upload a leaf image to identify diseases':
        'රෝග හඳුනාගැනීමට කොළ ඡායාරූපයක් උඩුගත කරන්න',
    'Upload Image': 'ඡායාරූපය උඩුගත කරන්න',
    'Tap to Upload Leaf Photo': 'කොළ ඡායාරූපයක් උඩුගත කිරීමට තට්ටු කරන්න',
    'Camera or Gallery': 'කැමරාව හෝ ගැලරිය',
    'Camera': 'කැමරාව',
    'Gallery': 'ගැලරිය',
    'Crop Type': 'බෝග වර්ගය',
    'Auto Detect': 'ස්වයංක්‍රීයව හඳුනාගන්න',
    'Select Crop': 'බෝගය තෝරන්න',
    'Required — the AI checks diseases only for this crop':
        'අනිවාර්යයි — AI මෙම බෝගයට අදාළ රෝග පමණක් පරීක්ෂා කරයි',
    'Please select the crop before disease analysis':
        'රෝග විශ්ලේෂණයට පෙර බෝගය තෝරන්න',
    'Select the crop first; automatic crop identification is not used for disease diagnosis.':
        'පළමුව බෝගය තෝරන්න; රෝග හඳුනාගැනීම සඳහා ස්වයංක්‍රීය බෝග හඳුනාගැනීම භාවිතා නොවේ.',
    'For better accuracy, select the crop if you already know it.':
        'වැඩි නිරවද්‍යතාව සඳහා බෝගය දන්නේ නම් එය තෝරන්න.',
    'Photo Tips': 'ඡායාරූප උපදෙස්',
    'Camera is disabled in AgriAI Settings.':
        'AgriAI සැකසුම් තුළ කැමරාව අක්‍රිය කර ඇත.',
    '• Use one leaf with good daylight.':
        '• හොඳ දිවා ආලෝකයේ එක් කොළයක් භාවිතා කරන්න.',
    '• Keep the leaf close and in focus.':
        '• කොළය ළඟින් සහ පැහැදිලිව ඡායාරූප ගන්න.',
    '• Avoid fingers, shadows and a busy background.':
        '• ඇඟිලි, සෙවණැලි සහ අවුල් පසුබිම් වළක්වන්න.',
    'Early': 'මුල් අවධිය',
    'Leaf Area': 'කොළ ප්‍රදේශය',
    'Flowering': 'මල් අවධිය',
    'Analyze with AI': 'AI මඟින් විශ්ලේෂණය කරන්න',
    'Analyzing...': 'විශ්ලේෂණය වෙමින්...',
    'AI Result': 'AI ප්‍රතිඵලය',
    'Disease name • Confidence score • Treatment recommendation • Organic solution':
        'රෝග නාමය • විශ්වාසය • ප්‍රතිකාර නිර්දේශය • කාබනික විසඳුම',
    'Disease Analysis Result': 'රෝග විශ්ලේෂණ ප්‍රතිඵලය',
    'Unsupported Crop': 'සහාය නොදක්වන බෝගය',
    'Sorry, this crop is not supported': 'කණගාටුයි, මෙම බෝගයට සහාය නොදක්වයි',
    'The photo does not confidently match the 25 trained crops.':
        'මෙම ඡායාරූපය පුහුණු කළ බෝග 25 සමඟ විශ්වාසදායකව නොගැළපේ.',
    'Scan Status': 'ස්කෑන් තත්ත්වය',
    'Not Supported': 'සහාය නොදක්වයි',
    'Model Confidence': 'මොඩල් විශ්වාසය',
    'Disease Result': 'රෝග ප්‍රතිඵලය',
    'Not Available': 'ලබාගත නොහැක',
    'What to do next': 'ඊළඟට කළ යුතු දේ',
    '• Use a clear photo of one leaf from a supported crop.':
        '• සහාය දක්වන බෝගයක එක් පැහැදිලි කොළ ඡායාරූපයක් භාවිතා කරන්න.',
    '• If the crop is supported, retake it in good daylight.':
        '• බෝගයට සහාය දක්වන්නේ නම් හොඳ දිවා ආලෝකයේ නැවත ඡායාරූප ගන්න.',
    '• A new crop requires new disease images and model retraining.':
        '• නව බෝගයකට නව රෝග ඡායාරූප සහ මොඩලය නැවත පුහුණු කිරීම අවශ්‍යයි.',
    'Scan Another Leaf': 'තවත් කොළයක් ස්කෑන් කරන්න',
    'AI diagnosis and treatment plan': 'AI රෝග නිර්ණය සහ ප්‍රතිකාර සැලැස්ම',
    'AI Scan Complete': 'AI ස්කෑන් කිරීම සම්පූර්ණයි',
    'Leaf Blight Detected': 'පත්‍ර අංගමාරය හඳුනාගෙන ඇත',
    'Confidence Score: 94%': 'විශ්වාසනීයත්වය: 94%',
    'Disease Details': 'රෝග විස්තර',
    'Severity': 'තීව්‍රතාව',
    'Recovery': 'සුවවීම',
    'Moderate': 'මධ්‍යස්ථ',
    'Treatment Plan': 'ප්‍රතිකාර සැලැස්ම',
    '• Remove infected leaves.': '• ආසාදිත කොළ ඉවත් කරන්න.',
    '• Apply recommended fungicide.': '• නිර්දේශිත දිලීර නාශකය යොදන්න.',
    '• Improve field drainage.': '• කෙතේ ජලාපවහනය වැඩිදියුණු කරන්න.',
    '• Spray organic neem solution.': '• කාබනික කොහොඹ ද්‍රාවණය ඉසින්න.',
    'Recommended Product': 'නිර්දේශිත නිෂ්පාදනය',
    'Copper-based Fungicide': 'තඹ මත පදනම් වූ දිලීර නාශකය',
    'Download Treatment Report': 'ප්‍රතිකාර වාර්තාව බාගන්න',
    'Weather Advisory': 'කාලගුණ උපදේශනය',
    'Real-time weather insights for your farm':
        'ඔබේ ගොවිපළ සඳහා තත්‍ය කාලීන කාලගුණ තොරතුරු',
    "Today's Weather": 'අද කාලගුණය',
    'Sunny • Trincomalee': 'හිරු එළිය • ත්‍රිකුණාමලය',
    'Weather Details': 'කාලගුණ විස්තර',
    'Humidity': 'ආර්ද්‍රතාව',
    'Rain Chance': 'වැසි සම්භාවිතාව',
    'Wind Speed': 'සුළං වේගය',
    'UV Index': 'UV දර්ශකය',
    'Sunrise': 'හිරු උදාව',
    'AI Farming Advice': 'AI ගොවි උපදෙස්',
    'Best irrigation time: 6:00 AM': 'හොඳම ජල සැපයුම් වේලාව: පෙ.ව. 6:00',
    'Safe spraying conditions today': 'අද ඉසීම සඳහා සුදුසු තත්ත්වයක්',
    'No heavy rain expected': 'තද වැසි අපේක්ෂා නොකෙරේ',
    'View 7-Day Forecast': 'දින 7ක අනාවැකිය බලන්න',
    '7-Day Weather Forecast': 'දින 7ක කාලගුණ අනාවැකිය',
    'AI weather prediction and farming advice':
        'AI කාලගුණ අනාවැකි සහ ගොවි උපදෙස්',
    'Sunny • Rain Chance 20%': 'හිරු එළිය • වැසි සම්භාවිතාව 20%',
    '7-Day Forecast': 'දින 7ක අනාවැකිය',
    'AI Recommendations': 'AI නිර්දේශ',
    '• Irrigate crops tomorrow morning.': '• හෙට උදෑසන බෝගවලට ජලය දෙන්න.',
    '• Avoid spraying on Wednesday.': '• බදාදා ඉසීමෙන් වළකින්න.',
    '• Harvest before expected rainfall.':
        '• අපේක්ෂිත වර්ෂාවට පෙර අස්වැන්න නෙළන්න.',
    '• Strong winds expected Friday.': '• සිකුරාදා තද සුළං අපේක්ෂා කෙරේ.',
    'Refresh Forecast': 'අනාවැකිය යාවත්කාලීන කරන්න',
    'Unable to load weather. Check your internet connection.':
        'කාලගුණ තොරතුරු පූරණය කළ නොහැක. අන්තර්ජාල සම්බන්ධතාව පරීක්ෂා කරන්න.',
    'Clear sky': 'පැහැදිලි අහස',
    'Mainly clear': 'බොහෝ දුරට පැහැදිලියි',
    'Partly cloudy': 'අර්ධ වලාකුළු සහිතයි',
    'Overcast': 'වලාකුළින් බරයි',
    'Foggy': 'මීදුම සහිතයි',
    'Drizzle': 'පොද වැසි',
    'Rain': 'වැසි',
    'Heavy rain': 'තද වැසි',
    'Thunderstorm': 'ගිගුරුම් සහිත වැසි',
    'Cloudy': 'වලාකුළු සහිතයි',
    'Farming Advice': 'ගොවි උපදෙස්',
    'Rain is likely. Delay irrigation and protect harvested crops.':
        'වැසි ඇති විය හැක. වාරිමාර්ග ප්‍රමාද කර නෙළූ අස්වැන්න ආරක්ෂා කරන්න.',
    'Low rain chance. Irrigate crops early in the morning.':
        'වැසි අවස්ථාව අඩුයි. උදෑසනම බෝගවලට ජලය දෙන්න.',
    'Strong wind expected. Avoid pesticide spraying.':
        'තද සුළං අපේක්ෂිතයි. පළිබෝධනාශක ඉසීමෙන් වළකින්න.',
    'Wind conditions are suitable for normal field work.':
        'සාමාන්‍ය කෙත් වැඩ සඳහා සුළං තත්ත්වය සුදුසුයි.',
    'High UV level. Avoid long field work around midday.':
        'UV මට්ටම ඉහළයි. මධ්‍යහ්නයේ දිගු වේලාවක් කෙත් වැඩ කිරීමෙන් වළකින්න.',
    'Weather data: Open-Meteo': 'කාලගුණ දත්ත: Open-Meteo',
    'Live weather forecast and farming advice':
        'සජීවී කාලගුණ අනාවැකි සහ ගොවි උපදෙස්',
    'Farming Recommendations': 'ගොවි නිර්දේශ',
    'Daily Crop Recommendations': 'දෛනික බෝග නිර්දේශ',
    'All 25 Crops - Weekly Suitability': 'බෝග 25ම - සතිපතා යෝග්‍යතාව',
    'Weather suitability uses temperature, rain and wind. Confirm soil, season and local advice before planting.':
        'කාලගුණ යෝග්‍යතාව උෂ්ණත්වය, වැසි සහ සුළඟ මත පදනම් වේ. වගා කිරීමට පෙර පස, කන්නය සහ ප්‍රාදේශීය උපදෙස් තහවුරු කරන්න.',
    'Recommended from your 25 crops': 'ඔබගේ බෝග 25න් නිර්දේශිත බෝග',
    'rain': 'වැසි',
    'Highly Suitable': 'ඉතා යෝග්‍යයි',
    'Suitable': 'යෝග්‍යයි',
    'Low Suitability': 'අඩු යෝග්‍යතාව',
    'Rain is likely tomorrow. Reduce irrigation.':
        'හෙට වැසි ඇති විය හැක. වාරිමාර්ග අඩු කරන්න.',
    'Irrigate crops tomorrow morning.': 'හෙට උදෑසන බෝගවලට ජලය දෙන්න.',
    'Avoid spraying on windy forecast days.':
        'සුළං වැඩි අනාවැකි දිනවල ඉසීමෙන් වළකින්න.',
    'Wind forecast is suitable for normal farm work.':
        'සාමාන්‍ය ගොවි වැඩ සඳහා සුළං අනාවැකිය සුදුසුයි.',
    'Profit Planner': 'ලාභ සැලසුම්කරු',
    'Estimate costs, revenue and profit':
        'වියදම්, ආදායම සහ ලාභය ඇස්තමේන්තු කරන්න',
    'Estimate costs, revenue and profit for all 25 crops':
        'බෝග 25ම සඳහා වියදම්, ආදායම සහ ලාභය ඇස්තමේන්තු කරන්න',
    'AI Profit Calculator': 'AI ලාභ ගණකය',
    'Plan Before You Plant': 'වගා කිරීමට පෙර සැලසුම් කරන්න',
    'Make informed decisions before the season starts':
        'කන්නය ආරම්භ වීමට පෙර නිවැරදි තීරණ ගන්න',
    '25 crops • Editable costs, yield and selling price':
        'බෝග 25ක් • වියදම්, අස්වැන්න සහ විකුණුම් මිල වෙනස් කළ හැක',
    'Load 25-crop planning defaults': 'බෝග 25 සැලසුම් පෙරනිමි පූරණය කරන්න',
    'Seed / Planting Material Cost': 'බීජ / රෝපණ ද්‍රව්‍ය වියදම',
    'Fertilizer & Input Cost': 'පොහොර සහ යෙදවුම් වියදම',
    'Seed Cost': 'බීජ වියදම',
    'Fertilizer Cost': 'පොහොර වියදම',
    'Labour Cost': 'ශ්‍රම වියදම',
    'Expected Yield (kg)': 'අපේක්ෂිත අස්වැන්න (කි.ග්‍රෑ.)',
    'Expected Yield (kg/units)': 'අපේක්ෂිත අස්වැන්න (කි.ග්‍රෑ./ඒකක)',
    'Expected Selling Price (per kg/unit)':
        'අපේක්ෂිත විකුණුම් මිල (කි.ග්‍රෑ./ඒකකයකට)',
    'Calculate Profit': 'ලාභය ගණනය කරන්න',
    'Saving...': 'සුරකිමින්...',
    'Estimated Results': 'ඇස්තමේන්තුගත ප්‍රතිඵල',
    'Investment': 'ආයෝජනය',
    'Revenue': 'ආදායම',
    'Expected Profit': 'අපේක්ෂිත ලාභය',
    'Profit per Acre': 'අක්කරයකට ලාභය',
    'Estimated ROI': 'ඇස්තමේන්තුගත ROI',
    'Enter a valid amount': 'වලංගු අගයක් ඇතුළත් කරන්න',
    'Planning defaults are indicative. Edit them using your current supplier costs, expected yield and local market price before making a farming decision.':
        'සැලසුම් පෙරනිමි මාර්ගෝපදේශ සඳහා පමණි. ගොවි තීරණයක් ගැනීමට පෙර වත්මන් සැපයුම් වියදම්, අපේක්ෂිත අස්වැන්න සහ ප්‍රාදේශීය වෙළඳපොළ මිල අනුව ඒවා වෙනස් කරන්න.',
    'Farm Management': 'ගොවිපළ කළමනාකරණය',
    'Manage all your farms in one place':
        'ඔබේ සියලු ගොවිපළ එකම ස්ථානයක කළමනාකරණය කරන්න',
    'My Farms': 'මගේ ගොවිපළ',
    'Track crops, irrigation and harvest':
        'බෝග, වාරිමාර්ග සහ අස්වැන්න නිරීක්ෂණය කරන්න',
    'Add New Farm': 'නව ගොවිපළක් එක් කරන්න',
    'Current Crop': 'වත්මන් බෝගය',
    'Area in acres': 'අක්කර ප්‍රමාණය',
    'Cancel': 'අවලංගු කරන්න',
    'Add Farm': 'ගොවිපළ එක් කරන්න',
    'View': 'බලන්න',
    'Upcoming Harvest': 'ඉදිරි අස්වැන්න',
    'Rice Farm • 12 Days Remaining': 'වී ගොවිපළ • තවත් දින 12යි',
    'Farm Analytics': 'ගොවිපළ විශ්ලේෂණ',
    'AI insights for your farm performance':
        'ඔබේ ගොවිපළ කාර්යසාධනය සඳහා AI තොරතුරු',
    'Farm Health Score': 'ගොවිපළ සෞඛ්‍ය ලකුණු',
    'Excellent crop condition': 'විශිෂ්ට බෝග තත්ත්වය',
    'Yield': 'අස්වැන්න',
    'Monthly Performance': 'මාසික කාර්යසාධනය',
    'AI Insights': 'AI තොරතුරු',
    '• Yield increased by 12% this month.':
        '• මේ මාසයේ අස්වැන්න 12%කින් වැඩි විය.',
    '• Water usage reduced by 18%.': '• ජල භාවිතය 18%කින් අඩු විය.',
    '• Harvest expected in 12 days.': '• දින 12කින් අස්වැන්න අපේක්ෂා කෙරේ.',
    'Refresh Analytics': 'විශ්ලේෂණ යාවත්කාලීන කරන්න',
    'Farm analytics and downloadable reports':
        'ගොවිපළ විශ්ලේෂණ සහ බාගත කළ හැකි වාර්තා',
    'Analytics Dashboard': 'විශ්ලේෂණ මුල් පිටුව',
    'Monthly Summary': 'මාසික සාරාංශය',
    'Crop • Weather • Profit • Disease': 'බෝග • කාලගුණය • ලාභය • රෝග',
    'Crop Report': 'බෝග වාර්තාව',
    'Yield Analysis': 'අස්වැන්න විශ්ලේෂණය',
    'Forecast Report': 'අනාවැකි වාර්තාව',
    'Disease Report': 'රෝග වාර්තාව',
    'Health Report': 'සෞඛ්‍ය වාර්තාව',
    'Profit Report': 'ලාභ වාර්තාව',
    'Income Report': 'ආදායම් වාර්තාව',
    'Export Options': 'අපනයන විකල්ප',
    'Market Prices': 'වෙළඳපොළ මිල',
    'Official Sri Lanka daily food commodity prices':
        'ශ්‍රී ලංකාවේ නිල දෛනික ආහාර ද්‍රව්‍ය මිල',
    'Market prices updated': 'වෙළඳපොළ මිල යාවත්කාලීන කරන ලදී',
    'Unable to load market prices. Check your internet connection.':
        'වෙළඳපොළ මිල පූරණය කළ නොහැක. අන්තර්ජාල සම්බන්ධතාව පරීක්ෂා කරන්න.',
    'Unable to open the price bulletin.': 'මිල වාර්තාව විවෘත කළ නොහැක.',
    'Daily Price Bulletin': 'දෛනික මිල වාර්තාව',
    'English PDF • Official wholesale and retail prices':
        'ඉංග්‍රීසි PDF • නිල තොග සහ සිල්ලර මිල',
    'Loading latest prices...': 'නවතම මිල පූරණය වෙමින්...',
    'Refresh Market Prices': 'වෙළඳපොළ මිල යාවත්කාලීන කරන්න',
    'HARTI Market Information': 'HARTI වෙළඳපොළ තොරතුරු',
    'Daily Food Prices': 'දෛනික ආහාර මිල',
    'Latest official bulletin': 'නවතම නිල වාර්තාව',
    'Source: HARTI Sri Lanka • Tap a bulletin to view official prices':
        'මූලාශ්‍රය: HARTI ශ්‍රී ලංකා • නිල මිල බැලීමට වාර්තාවක් තට්ටු කරන්න',
    'Daily crop prices and AI price trends': 'දෛනික බෝග මිල සහ AI මිල ප්‍රවණතා',
    "Today's Market": 'අද වෙළඳපොළ',
    'Best Selling Crops': 'වැඩිම අලෙවි වන බෝග',
    'Updated: Colombo Market • Today': 'යාවත්කාලීන: කොළඹ වෙළඳපොළ • අද',
    'Rice': 'වී',
    'Tomato': 'තක්කාලි',
    'Chili': 'මිරිස්',
    'Maize': 'බඩ ඉරිඟු',
    'Apple': 'ඇපල්',
    'Banana': 'කෙසෙල්',
    'Bean': 'බෝංචි',
    'Brinjal': 'වම්බටු',
    'Cabbage': 'ගෝවා',
    'Chilli': 'මිරිස්',
    'Lemon': 'ලෙමන්',
    'Coconut': 'පොල්',
    'Coffee': 'කෝපි',
    'Cucumber': 'පිපිඤ්ඤා',
    'Grapes': 'මිදි',
    'Groundnut': 'රටකජු',
    'Guava': 'පේර',
    'Mango': 'අඹ',
    'Okra': 'බණ්ඩක්කා',
    'Onion': 'ලූනු',
    'Papaya': 'පැපොල්',
    'Pineapple': 'අන්නාසි',
    'Potato': 'අර්තාපල්',
    'Pumpkin': 'වට්ටක්කා',
    'Sugarcane': 'උක්',
    'Tea': 'තේ',
    'Per kg price': 'කිලෝවක මිල',
    'AI Price Prediction': 'AI මිල අනාවැකිය',
    'Chili price may increase next week.': 'ලබන සතියේ මිරිස් මිල ඉහළ යා හැක.',
    'Recommended action: Sell 40% now.': 'නිර්දේශය: දැන් 40%ක් විකුණන්න.',
    'Confidence: 82%': 'විශ්වාසනීයත්වය: 82%',
    'Open Community Market': 'ප්‍රජා වෙළඳපොළ විවෘත කරන්න',
    'Community Market': 'ප්‍රජා වෙළඳපොළ',
    'Buy, sell and connect with farmers':
        'ගොවීන් සමඟ මිලදී ගන්න, විකුණන්න සහ සම්බන්ධ වන්න',
    'Farmer Marketplace': 'ගොවි වෙළඳපොළ',
    'Sell Your Harvest': 'ඔබේ අස්වැන්න විකුණන්න',
    'Crops • Tools • Equipment • Services': 'බෝග • මෙවලම් • උපකරණ • සේවා',
    'Sell Crops': 'බෝග විකුණන්න',
    'Post your harvest': 'ඔබේ අස්වැන්න පළ කරන්න',
    'Buy Products': 'නිෂ්පාදන මිලදී ගන්න',
    'Find nearby crops': 'අසල බෝග සොයන්න',
    'Rent Tools': 'මෙවලම් කුලියට ගන්න',
    'Tractor, sprayer': 'ට්‍රැක්ටරය, ඉසිනය',
    'Community': 'ප්‍රජාව',
    'Ask farmers': 'ගොවීන්ගෙන් අසන්න',
    'Latest Listings': 'නවතම දැන්වීම්',
    'Create New Listing': 'නව දැන්වීමක් සාදන්න',
    'Item and quantity': 'භාණ්ඩය සහ ප්‍රමාණය',
    'Price': 'මිල',
    'Publish': 'පළ කරන්න',
    'Notifications': 'දැනුම්දීම්',
    'Stay updated with your farm alerts':
        'ඔබේ ගොවිපළ අනතුරු ඇඟවීම් සමඟ යාවත්කාලීන වන්න',
    "Today's Alerts": 'අද අනතුරු ඇඟවීම්',
    '5 New Notifications': 'නව දැනුම්දීම් 5ක්',
    'All Caught Up': 'සියල්ල කියවා ඇත',
    'Weather • Disease • Harvest • Market':
        'කාලගුණය • රෝග • අස්වැන්න • වෙළඳපොළ',
    'Weather Alert': 'කාලගුණ අනතුරු ඇඟවීම',
    'Heavy rain expected tomorrow.': 'හෙට තද වැසි අපේක්ෂා කෙරේ.',
    'Disease Warning': 'රෝග අනතුරු ඇඟවීම',
    'Possible leaf blight detected nearby.': 'අසල පත්‍ර අංගමාරය තිබිය හැක.',
    'Market Update': 'වෙළඳපොළ යාවත්කාලීනය',
    'Rice price increased by 8% today.': 'අද වී මිල 8%කින් වැඩි විය.',
    'Harvest Reminder': 'අස්වැන්න මතක් කිරීම',
    'Harvest Farm 01 in 12 days.': 'දින 12කින් ගොවිපළ 01 අස්වැන්න නෙළන්න.',
    'Mark All as Read': 'සියල්ල කියවූ ලෙස සලකුණු කරන්න',
    'All Alerts Read': 'සියලු අනතුරු ඇඟවීම් කියවා ඇත',
    'View Government News': 'රජයේ පුවත් බලන්න',
    'Government News': 'රජයේ පුවත්',
    'Agriculture News': 'කෘෂිකාර්මික පුවත්',
    'View Agriculture News': 'කෘෂිකාර්මික පුවත් බලන්න',
    'Sri Lanka Agriculture News': 'ශ්‍රී ලංකා කෘෂිකාර්මික පුවත්',
    'Live updates from Sri Lankan news sources':
        'ශ්‍රී ලංකා පුවත් මූලාශ්‍රවලින් සජීවී යාවත්කාලීන',
    'Local Farmer News': 'දේශීය ගොවි පුවත්',
    'Agriculture stories from Daily Mirror Sri Lanka':
        'ඩේලි මිරර් ශ්‍රී ලංකා කෘෂිකාර්මික පුවත්',
    'Refresh Agriculture News': 'කෘෂිකාර්මික පුවත් යාවත්කාලීන කරන්න',
    'Agriculture news updated': 'කෘෂිකාර්මික පුවත් යාවත්කාලීන කරන ලදී',
    'Last checked': 'අවසන් වරට පරීක්ෂා කළේ',
    'Auto refresh: every 15 minutes while this page is open':
        'මෙම පිටුව විවෘතව ඇති විට සෑම විනාඩි 15කටම ස්වයංක්‍රීයව යාවත්කාලීන වේ',
    'No Sri Lankan agriculture news is available right now.':
        'දැනට ශ්‍රී ලංකා කෘෂිකාර්මික පුවත් නොමැත.',
    'Unable to load agriculture news. Check your internet connection and try again.':
        'කෘෂිකාර්මික පුවත් පූරණය කළ නොහැක. අන්තර්ජාල සම්බන්ධතාව පරීක්ෂා කර නැවත උත්සාහ කරන්න.',
    'Unable to open the original article.': 'මුල් පුවත විවෘත කළ නොහැක.',
    'Try Again': 'නැවත උත්සාහ කරන්න',
    'Source': 'මූලාශ්‍රය',
    'Tap an article to read the original.':
        'මුල් පුවත කියවීමට පුවතක් තට්ටු කරන්න.',
    'Agriculture updates and announcements': 'කෘෂිකාර්මික යාවත්කාලීන සහ නිවේදන',
    'Latest Updates': 'නවතම යාවත්කාලීන',
    'Farmer News': 'ගොවි පුවත්',
    'Daily notices from Agriculture Department':
        'කෘෂිකර්ම දෙපාර්තමේන්තුවේ දෛනික නිවේදන',
    'Subsidy Program': 'සහනාධාර වැඩසටහන',
    'Fertilizer subsidy registration is now open.':
        'පොහොර සහනාධාර ලියාපදිංචිය දැන් විවෘතයි.',
    'Training Program': 'පුහුණු වැඩසටහන',
    'Organic farming workshop - 15 July.':
        'කාබනික ගොවිතැන් වැඩමුළුව - ජූලි 15.',
    'Weather Warning': 'කාලගුණ අනතුරු ඇඟවීම',
    'Heavy rainfall expected in Eastern Province.':
        'නැගෙනහිර පළාතේ තද වැසි අපේක්ෂා කෙරේ.',
    'Grant Scheme': 'ප්‍රදාන යෝජනා ක්‍රමය',
    'Applications invited for smart irrigation.':
        'ස්මාර්ට් වාරිමාර්ග සඳහා අයදුම්පත් කැඳවයි.',
    'Refresh Government News': 'රජයේ පුවත් යාවත්කාලීන කරන්න',
    'Manage your farmer account': 'ඔබේ ගොවි ගිණුම කළමනාකරණය කරන්න',
    'Personal Information': 'පුද්ගලික තොරතුරු',
    'Email': 'විද්‍යුත් තැපෑල',
    'Language': 'භාෂාව',
    'Farm Size': 'ගොවිපළ ප්‍රමාණය',
    'Main Crop': 'ප්‍රධාන බෝගය',
    'Account Actions': 'ගිණුම් ක්‍රියා',
    'Edit Profile': 'පැතිකඩ සංස්කරණය කරන්න',
    'Update your personal information': 'ඔබේ පුද්ගලික තොරතුරු යාවත්කාලීන කරන්න',
    'Change Password': 'මුරපදය වෙනස් කරන්න',
    'Keep your account secure': 'ඔබේ ගිණුම ආරක්ෂිතව තබාගන්න',
    'Phone': 'දුරකථනය',
    'Save': 'සුරකින්න',
    'Settings': 'සැකසුම්',
    'Customize your AgriAI experience': 'ඔබේ AgriAI අත්දැකීම අභිරුචිකරණය කරන්න',
    'App Preferences': 'යෙදුම් මනාප',
    'Control language, privacy and permissions':
        'භාෂාව, පෞද්ගලිකත්වය සහ අවසර පාලනය කරන්න',
    'English': 'ඉංග්‍රීසි',
    'Tamil': 'දෙමළ',
    'Sinhala': 'සිංහල',
    'Dark Mode': 'අඳුරු ප්‍රකාරය',
    'GPS Permission': 'GPS අවසරය',
    'Camera Permission': 'කැමරා අවසරය',
    'Privacy': 'පෞද්ගලිකත්වය',
    'Manage your data preferences': 'ඔබේ දත්ත මනාප කළමනාකරණය කරන්න',
    'Help & Support': 'උදව් සහ සහාය',
    'Open the AgriAI help center': 'AgriAI උදව් මධ්‍යස්ථානය විවෘත කරන්න',
    'About App': 'යෙදුම පිළිබඳව',
    'Save Settings': 'සැකසුම් සුරකින්න',
    'Permission Required': 'අවසරය අවශ්‍යයි',
    'Permission is blocked. Open phone settings to enable it.':
        'අවසරය අවහිර කර ඇත. එය සක්‍රිය කිරීමට දුරකථන සැකසුම් විවෘත කරන්න.',
    'Permission was not granted. You can try again.':
        'අවසරය ලබා දී නැත. නැවත උත්සාහ කළ හැක.',
    'Open Phone Settings': 'දුරකථන සැකසුම් විවෘත කරන්න',
    'Privacy & Permissions': 'පෞද්ගලිකත්වය සහ අවසර',
    'AgriAI stores your account, farm history and saved results in Firebase. Camera and location are used only when you choose those features.':
        'AgriAI ඔබේ ගිණුම, ගොවිපළ ඉතිහාසය සහ සුරැකි ප්‍රතිඵල Firebase හි තබයි. කැමරාව සහ ස්ථානය ඔබ එම විශේෂාංග තෝරාගත් විට පමණක් භාවිතා වේ.',
    'Unable to open this service.': 'මෙම සේවාව විවෘත කළ නොහැක.',
    'Frequently Asked Questions': 'නිතර අසන ප්‍රශ්න',
    'Close': 'වසන්න',
    'How do I detect a crop disease?': 'බෝග රෝගයක් හඳුනාගන්නේ කෙසේද?',
    'Open Disease Detection, upload one clear leaf photo and tap Analyze with AI.':
        'රෝග හඳුනාගැනීම විවෘත කර පැහැදිලි කොළ ඡායාරූපයක් උඩුගත කර AI විශ්ලේෂණය ඔබන්න.',
    'Does AgriAI work without internet?':
        'අන්තර්ජාලය නොමැතිව AgriAI ක්‍රියා කරයිද?',
    'Disease detection works on the phone. Weather, news and Firebase features require internet.':
        'රෝග හඳුනාගැනීම දුරකථනයේ ක්‍රියා කරයි. කාලගුණ, පුවත් සහ Firebase සඳහා අන්තර්ජාලය අවශ්‍යයි.',
    'Why is a crop shown as not supported?':
        'බෝගයක් සහාය නොදක්වන ලෙස පෙන්වන්නේ ඇයි?',
    'The image did not confidently match one of the 25 trained crops. Retake a clear photo or use a supported crop.':
        'ඡායාරූපය පුහුණු කළ බෝග 25න් එකකට විශ්වාසදායකව නොගැළපේ. පැහැදිලි ඡායාරූපයක් නැවත ගන්න.',
    'Send Feedback': 'ප්‍රතිචාර යවන්න',
    'Your feedback': 'ඔබේ ප්‍රතිචාරය',
    'Tell us what should be improved...': 'වැඩිදියුණු කළ යුතු දේ කියන්න...',
    'Submit': 'යොමු කරන්න',
    'Feedback sent successfully': 'ප්‍රතිචාරය සාර්ථකව යවන ලදී',
    'Please enter at least 5 characters.': 'අවම වශයෙන් අක්ෂර 5ක් ඇතුළත් කරන්න.',
    'Call Sri Lanka agriculture advisory service 1920':
        'ශ්‍රී ලංකා කෘෂිකර්ම උපදේශන සේවාව 1920 අමතන්න',
    'Email agriculture advisory support': 'කෘෂිකර්ම උපදේශන සහායට ඊමේල් කරන්න',
    'AI & official farmer support': 'AI සහ නිල ගොවි සහාය',
    'Call 1920 Agriculture Support': '1920 කෘෂිකර්ම සහාය අමතන්න',
    'Department of Agriculture Sri Lanka': 'ශ්‍රී ලංකා කෘෂිකර්ම දෙපාර්තමේන්තුව',
    'AgriAI stores account details, farm records and saved results in Firebase. Camera, microphone and location are accessed only after permission and only for the feature you choose. Do not upload confidential images.':
        'AgriAI ගිණුම් විස්තර, ගොවිපළ වාර්තා සහ සුරැකි ප්‍රතිඵල Firebase හි තබයි. අවසර ලබා දුන් පසු ඔබ තෝරාගත් විශේෂාංගයට පමණක් කැමරාව, මයික්‍රෆෝනය සහ ස්ථානය භාවිතා වේ. රහස් ඡායාරූප උඩුගත නොකරන්න.',
    'AgriAI predictions, weather advice and profit figures are estimates for educational support. Confirm important farming and pesticide decisions with a qualified agriculture officer.':
        'AgriAI අනාවැකි, කාලගුණ උපදෙස් සහ ලාභ අගයන් අධ්‍යාපනික සහාය සඳහා ඇස්තමේන්තු වේ. වැදගත් ගොවිතැන් සහ පළිබෝධනාශක තීරණ සුදුසුකම් ලත් කෘෂිකර්ම නිලධාරියෙකු සමඟ තහවුරු කරන්න.',
    'Add a verified email to reset your password.':
        'මුරපදය යළි පිහිටුවීමට තහවුරු කළ ඊමේලයක් එක් කරන්න.',
    'About AgriAI': 'AgriAI පිළිබඳව',
    'AI Smart Farming Platform': 'AI ස්මාර්ට් ගොවි වේදිකාව',
    'Developed By': 'සංවර්ධනය කළේ',
    'Technology': 'තාක්ෂණය',
    'Languages': 'භාෂා',
    'Privacy Policy': 'පෞද්ගලිකත්ව ප්‍රතිපත්තිය',
    'View how your information is protected':
        'ඔබේ තොරතුරු ආරක්ෂා වන ආකාරය බලන්න',
    'Terms & Conditions': 'නියම සහ කොන්දේසි',
    'View application terms': 'යෙදුම් නියම බලන්න',
    'Official Website': 'නිල වෙබ් අඩවිය',
    'Contact': 'සම්බන්ධ වන්න',
    'Visit Website': 'වෙබ් අඩවියට යන්න',
    'Help Center': 'උදව් මධ්‍යස්ථානය',
    'Get support and farming guidance': 'සහාය සහ ගොවි මාර්ගෝපදේශ ලබාගන්න',
    'Need Assistance?': 'උදව් අවශ්‍යද?',
    "We're Here to Help": 'අපි උදව් කිරීමට මෙහි සිටිමු',
    '24/7 AI & Farmer Support': '24/7 AI සහ ගොවි සහාය',
    'FAQs': 'නිතර අසන ප්‍රශ්න',
    'Common farming questions': 'පොදු ගොවි ප්‍රශ්න',
    'Video Tutorials': 'වීඩියෝ පාඩම්',
    'Learn with step-by-step guides': 'පියවරෙන් පියවර මාර්ගෝපදේශ සමඟ ඉගෙනගන්න',
    'AI Chat Assistant': 'AI සංවාද සහායක',
    'Ask farming questions instantly': 'ගොවි ප්‍රශ්න වහාම අසන්න',
    'Agriculture Officer': 'කෘෂිකර්ම නිලධාරියා',
    'Contact your local officer': 'ඔබේ ප්‍රදේශීය නිලධාරියා අමතන්න',
    'Feedback': 'ප්‍රතිචාර',
    'Share your suggestions': 'ඔබේ යෝජනා බෙදාගන්න',
    'Customer Support': 'පාරිභෝගික සහාය',
    'Email and phone support': 'විද්‍යුත් තැපෑල සහ දුරකථන සහාය',
    'Contact Support': 'සහාය අමතන්න',
    'AI Farming Assistant': 'AI ගොවි සහායක',
    'Ask anything about your crops': 'ඔබේ බෝග ගැන ඕනෑම දෙයක් අසන්න',
    'Hello Farmer!': 'ආයුබෝවන් ගොවි මහතා!',
    'How can I help you today?': 'අද මට ඔබට උදව් කළ හැක්කේ කෙසේද?',
    'Hello Farmer! How can I help you today?':
        'ආයුබෝවන් ගොවි මහතා! අද මට උදව් කළ හැක්කේ කෙසේද?',
    'What crop is best for clay soil?': 'මැටි පසට හොඳම බෝගය කුමක්ද?',
    'Rice and maize are suitable. Upload soil details for a more accurate AI recommendation.':
        'වී සහ බඩ ඉරිඟු සුදුසුයි. වඩා නිවැරදි AI නිර්දේශයක් සඳහා පස් විස්තර උඩුගත කරන්න.',
    'Based on your farm profile, I recommend checking soil moisture and the 7-day weather forecast before planting.':
        'ඔබේ ගොවිපළ පැතිකඩ අනුව, වගා කිරීමට පෙර පස් තෙතමනය සහ දින 7ක කාලගුණය පරීක්ෂා කරන්න.',
    'Type your message...': 'ඔබේ පණිවිඩය ලියන්න...',
    'AI Voice Assistant': 'AI හඬ සහායක',
    'Talk to your farming assistant': 'ඔබේ ගොවි සහායකයා සමඟ කතා කරන්න',
    'Tap to Speak': 'කතා කිරීමට තට්ටු කරන්න',
    'Listening...': 'සවන් දෙමින්...',
    'Ask your farming question now': 'ඔබේ ගොවි ප්‍රශ්නය දැන් අසන්න',
    'Voice support in Tamil, Sinhala and English':
        'දෙමළ, සිංහල සහ ඉංග්‍රීසි හඬ සහාය',
    'Conversation': 'සංවාදය',
    'What crop is suitable this season?': 'මෙම කන්නයට සුදුසු බෝගය කුමක්ද?',
    'Rice is recommended based on your location and weather.':
        'ඔබේ ස්ථානය සහ කාලගුණය අනුව වී නිර්දේශ කර ඇත.',
    'Start Voice Chat': 'හඬ සංවාදය ආරම්භ කරන්න',
    'Stop Voice Chat': 'හඬ සංවාදය නවත්වන්න',
    'Mon': 'සඳුදා',
    'Monday': 'සඳුදා',
    'Tue': 'අඟහරු',
    'Tuesday': 'අඟහරුවාදා',
    'Wed': 'බදාදා',
    'Wednesday': 'බදාදා',
    'Thu': 'බ්‍රහස්පතින්දා',
    'Thursday': 'බ්‍රහස්පතින්දා',
    'Fri': 'සිකුරාදා',
    'Friday': 'සිකුරාදා',
    'Sat': 'සෙනසුරාදා',
    'Saturday': 'සෙනසුරාදා',
    'Sun': 'ඉරිදා',
    'Sunday': 'ඉරිදා',
    'Location': 'ස්ථානය',
    'Area': 'ප්‍රමාණය',
    'Trincomalee': 'ත්‍රිකුණාමලය',
    'Batticaloa': 'මඩකලපුව',
    'Not selected': 'තෝරා නැත',
    'Leaf Blight': 'පත්‍ර අංගමාරය',
    '10–14 Days': 'දින 10–14',
    '120 Days': 'දින 120',
    'Urea + Compost': 'යූරියා + කොම්පෝස්ට්',
    'Rice - 500kg available': 'වී - කි.ග්‍රෑ. 500ක් ඇත',
    'Chili - 80kg available': 'මිරිස් - කි.ග්‍රෑ. 80ක් ඇත',
    'Sprayer rental': 'ඉසිනය කුලියට',
    'Rs. 1500/day': 'රු. 1500/දින',
    'Password recovery link requested': 'මුරපද ප්‍රතිසාධන සබැඳිය ඉල්ලා ඇත',
    'Crop recommendation report generated': 'බෝග නිර්දේශ වාර්තාව සාදන ලදී',
    'Unable to open image source': 'ඡායාරූප මූලාශ්‍රය විවෘත කළ නොහැක',
    'Treatment report generated': 'ප්‍රතිකාර වාර්තාව සාදන ලදී',
    'Forecast updated': 'අනාවැකිය යාවත්කාලීන කරන ලදී',
    'Profit estimate updated': 'ලාභ ඇස්තමේන්තුව යාවත්කාලීන කරන ලදී',
    'Farm analytics refreshed': 'ගොවිපළ විශ්ලේෂණ යාවත්කාලීන කරන ලදී',
    'Nearby products loaded': 'අසල නිෂ්පාදන පූරණය කරන ලදී',
    'Rental tools loaded': 'කුලී මෙවලම් පූරණය කරන ලදී',
    'News updated': 'පුවත් යාවත්කාලීන කරන ලදී',
    'Settings saved': 'සැකසුම් සුරකින ලදී',
    'Image attachment ready': 'ඡායාරූප ඇමුණුම සූදානම්',
    'Live Gemini AI • Free tier': 'සජීවී Gemini AI • නොමිලේ මට්ටම',
    'Use Disease Detection for leaf images':
        'පත්‍ර ඡායාරූප සඳහා රෝග හඳුනාගැනීම භාවිතා කරන්න',
    'AI security setup is not finished. Register this device App Check debug token in Firebase Console.':
        'AI ආරක්ෂක සැකසුම තවම අවසන් නැත. මෙම උපාංගයේ App Check debug token එක Firebase Console හි ලියාපදිංචි කරන්න.',
    'Enable Firebase AI Logic with the free Gemini Developer API, then try again.':
        'නොමිලේ Gemini Developer API සමඟ Firebase AI Logic සක්‍රිය කර නැවත උත්සාහ කරන්න.',
    'AI assistant is unavailable now. Check the internet and try again.':
        'AI සහායකයා දැන් ලබාගත නොහැක. අන්තර්ජාලය පරීක්ෂා කර නැවත උත්සාහ කරන්න.',
    'Farm Map': 'ගොවිපළ සිතියම',
    'Free OpenStreetMap • No API key or billing':
        'නොමිලේ OpenStreetMap • API key හෝ ගෙවීම් නැත',
    'Selected farm location': 'තෝරාගත් ගොවිපළ ස්ථානය',
    'Use current location': 'වත්මන් ස්ථානය භාවිතා කරන්න',
    'Turn on phone location services.': 'දුරකථනයේ ස්ථාන සේවාව සක්‍රිය කරන්න.',
    'Location permission is required to show your position.':
        'ඔබේ ස්ථානය පෙන්වීමට ස්ථාන අවසරය අවශ්‍යයි.',
    'Unable to get your current location.': 'ඔබේ වත්මන් ස්ථානය ලබාගත නොහැක.',
    'Tap the map to move the farm marker':
        'ගොවිපළ සලකුණ ගෙන යාමට සිතියම තට්ටු කරන්න',
    'Open Free Farm Map': 'නොමිලේ ගොවිපළ සිතියම විවෘත කරන්න',
    'Allow notifications in phone settings':
        'දුරකථන සැකසුම් තුළ දැනුම්දීම් සඳහා අවසර දෙන්න',
    'Test notification sent': 'පරීක්ෂණ දැනුම්දීම යවන ලදී',
    'Unable to send test notification': 'පරීක්ෂණ දැනුම්දීම යැවිය නොහැක',
    'Test Phone Notification': 'දුරකථන දැනුම්දීම පරීක්ෂා කරන්න',
    'Free push notification setup is working.':
        'නොමිලේ push දැනුම්දීම් සැකසුම ක්‍රියා කරයි.',
    'Free AI Setup': 'නොමිලේ AI සැකසුම',
    'Groq API key': 'Groq API යතුර',
    'Create free Groq key': 'නොමිලේ Groq යතුරක් සාදන්න',
    'Voice Status': 'හඬ තත්ත්වය',
    'Voice fallback': 'විකල්ප පෙළ ආදානය',
    'Type your farming question if speech is unavailable':
        'හඬ ලබාගත නොහැකි නම් ගොවිතැන් ප්‍රශ්නය ටයිප් කරන්න',
    'Real farm analytics and downloadable files':
        'සත්‍ය ගොවිපළ විශ්ලේෂණ සහ බාගත කළ හැකි ගොනු',
    'Professional Summary': 'වෘත්තීය සාරාංශය',
    'Your Data Summary': 'ඔබේ දත්ත සාරාංශය',
    'Active Farms': 'ක්‍රියාකාරී ගොවිපළ',
    'Crop Recommendations': 'බෝග නිර්දේශ',
    'Disease Scans': 'රෝග පරීක්ෂණ',
    'Profit Plans': 'ලාභ සැලසුම්',
    'Report Content': 'වාර්තා අන්තර්ගතය',
    'Export Format': 'අපනයන ආකෘතිය',
    'Creating report...': 'වාර්තාව සාදමින්...',
    'Crop, area and harvest tracking in one place':
        'බෝගය, ඉඩම සහ අස්වැන්න එකම තැනක නිරීක්ෂණය කරන්න',
    'Planting Date': 'වගා කළ දිනය',
    'Expected Harvest': 'අපේක්ෂිත අස්වැන්න',
    'Notes': 'සටහන්',
    'Optional': 'විකල්ප',
    'Save Farm': 'ගොවිපළ සුරකින්න',
    'Delete Farm': 'ගොවිපළ මකන්න',
    'Remove': 'ඉවත් කරන්න',
    'Delete': 'මකන්න',
    'Next Harvest': 'ඊළඟ අස්වැන්න',
    'Harvest': 'අස්වැන්න',
    'Harvest date not set': 'අස්වැන්න දිනය සකසා නැත',
    'days remaining': 'දින ඉතිරි',
    'Analytics': 'විශ්ලේෂණ',
    'Next 5 Days - Best Crop': 'ඊළඟ දින 5 - හොඳම බෝගය',
    'Detailed 7-Day Crop Advice': 'විස්තරාත්මක දින 7 බෝග උපදෙස්',
    'suitable': 'සුදුසු',
    'Price source': 'මිල මූලාශ්‍රය',
    '25-crop planning reference': 'බෝග 25 සැලසුම් යොමුව',
    'Community Market average': 'ප්‍රජා වෙළඳපොළ සාමාන්‍යය',
    'Update Yield & Current Price': 'අස්වැන්න සහ වත්මන් මිල යාවත්කාලීන කරන්න',
    'Updating yield and price...': 'අස්වැන්න සහ මිල යාවත්කාලීන කරමින්...',
    'All 25 Crops - Planning Price Reference': 'බෝග 25ම - සැලසුම් මිල යොමුව',
    'Call HARTI price service 6666': 'HARTI මිල සේවාව 6666 අමතන්න',
    'These are editable planning estimates, not extracted live HARTI prices. Confirm the current daily price before selling.':
        'මේවා සංස්කරණය කළ හැකි සැලසුම් ඇස්තමේන්තු වන අතර සජීවී HARTI මිල නොවේ. විකිණීමට පෙර අද මිල තහවුරු කරන්න.',
    'Offline Farming Help • Tap for Free AI Setup':
        'Offline ගොවි උපකාරය • නොමිලේ AI සැකසුමට තට්ටු කරන්න',
    'Qwen Online AI • Groq Free Plan': 'Qwen Online AI • Groq නොමිලේ සැලසුම',
    'Real speech recognition and spoken farming guidance':
        'සත්‍ය හඬ හඳුනාගැනීම සහ ගොවිතැන් මාර්ගෝපදේශය',
    'Tamil, Sinhala and English device speech support':
        'දෙමළ, සිංහල සහ ඉංග්‍රීසි හඬ සහාය',
    'Microphone or speech service is unavailable':
        'මයික්‍රොෆෝනය හෝ හඬ සේවාව ලබාගත නොහැක',
    'Preparing Microphone...': 'මයික්‍රොෆෝනය සූදානම් කරමින්...',
    'Preparing Answer...': 'පිළිතුර සූදානම් කරමින්...',
    'Voice Wave': 'හඬ තරංගය',
    'Listening to your question...': 'ඔබේ ප්‍රශ්නයට සවන් දෙමින්...',
    'Stop & Answer': 'නවත්වා පිළිතුරු දෙන්න',
    '25 crops • Editable costs • Automatic yield and price':
        'බෝග 25 • සංස්කරණය කළ හැකි වියදම් • ස්වයංක්‍රීය අස්වැන්න සහ මිල',
    'Automatically calculated from crop and land':
        'බෝගය සහ ඉඩම අනුව ස්වයංක්‍රීයව ගණනය කෙරේ',
    'Automatically loaded for the selected crop':
        'තෝරාගත් බෝගයට ස්වයංක්‍රීයව පූරණය වේ',
    'Yield and selling price are selected automatically. Enter only your actual planting, input and labour costs. Confirm the market price before making a farming decision.':
        'අස්වැන්න සහ විකිණුම් මිල ස්වයංක්‍රීයව තෝරා ගනී. ඔබේ සැබෑ රෝපණ, යෙදවුම් සහ ශ්‍රම වියදම් පමණක් ඇතුළත් කරන්න. තීරණයකට පෙර වෙළඳපොළ මිල තහවුරු කරන්න.',
    'Selected Crop Match': 'තෝරාගත් බෝග ගැළපීම',
    'Dataset test accuracy: 92.55%. Real field-photo accuracy varies with lighting, focus and background.':
        'Dataset පරීක්ෂණ නිරවද්‍යතාව 92.55%කි. සැබෑ ක්ෂේත්‍ර ඡායාරූප නිරවද්‍යතාව ආලෝකය, focus සහ පසුබිම අනුව වෙනස් වේ.',
    'Photo ready. Select the correct crop when known, then analyze.':
        'ඡායාරූපය සූදානම්. බෝගය දන්නේ නම් නිවැරදි බෝගය තෝරා විශ්ලේෂණය කරන්න.',
    'Disease Result Uncertain': 'රෝග ප්‍රතිඵලය අවිනිශ්චිතයි',
    'Low Confidence Image': 'අඩු විශ්වාසයක් ඇති ඡායාරූපය',
    'Disease uncertain': 'රෝගය අවිනිශ්චිතයි',
    'Unable to identify this crop safely': 'මෙම බෝගය ආරක්ෂිතව හඳුනාගත නොහැක',
    'The selected crop is supported, but the disease pattern is not clear enough.':
        'තෝරාගත් බෝගයට සහාය ඇත, නමුත් රෝග ලක්ෂණ ප්‍රමාණවත් තරම් පැහැදිලි නැත.',
    'Selected Crop': 'තෝරාගත් බෝගය',
    'Possible Crop': 'විය හැකි බෝගය',
    'Disease Confidence': 'රෝග විශ්වාසය',
    'Uncertain - Retake Photo': 'අවිනිශ්චිතයි - නැවත ඡායාරූපයක් ගන්න',
    '• Fill most of the photo with one leaf only.':
        '• එක් පත්‍රයකින් පමණක් ඡායාරූපයේ වැඩි කොටස පුරවන්න.',
    '• Keep the damaged area visible and avoid branches or other leaves.':
        '• හානි වූ කොටස පැහැදිලිව තබා අතු සහ අනෙකුත් පත්‍ර වළක්වන්න.',
    '• Select the crop manually when you know its name.':
        '• බෝගයේ නම දන්නේ නම් එය අතින් තෝරන්න.',
    'Preliminary AI Result': 'මූලික AI ප්‍රතිඵලය',
    'Possible Disease': 'විය හැකි රෝගය',
    'Possible': 'විය හැකි',
    'Low confidence — verify before treatment':
        'අඩු විශ්වාසය — ප්‍රතිකාරයට පෙර තහවුරු කරන්න',
    'Select the crop manually for a disease estimate':
        'රෝග ඇස්තමේන්තුව සඳහා බෝගය අතින් තෝරන්න',
    'Select Crop First': 'පළමුව බෝගය තෝරන්න',
    'Top 3 Possible AI Matches': 'විය හැකි ඉහළම AI ගැළපීම් 3',
    'This is a preliminary low-confidence AI estimate, not a confirmed diagnosis. Do not apply chemicals without agriculture-officer advice.':
        'මෙය අඩු විශ්වාසයක් ඇති මූලික AI ඇස්තමේන්තුවක් මිස තහවුරු කළ රෝග විනිශ්චයක් නොවේ. කෘෂිකර්ම නිලධාරී උපදෙස් නොමැතිව රසායනික ද්‍රව්‍ය භාවිතා නොකරන්න.',
  },
};
