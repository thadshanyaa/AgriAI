import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseBackendException implements Exception {
  const FirebaseBackendException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract final class FirebaseBackend {
  static bool _ready = false;
  static Object? _initializationError;

  static bool get isReady => _ready;
  static Object? get initializationError => _initializationError;
  static User? get currentUser =>
      _ready ? FirebaseAuth.instance.currentUser : null;

  static FirebaseAuth get _auth {
    _ensureReady();
    return FirebaseAuth.instance;
  }

  static FirebaseFirestore get _firestore {
    _ensureReady();
    return FirebaseFirestore.instance;
  }

  static Future<void> initialize() async {
    final supported =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (!supported) return;
    try {
      await Firebase.initializeApp();
      _ready = true;
      _initializationError = null;
    } catch (error) {
      _ready = false;
      _initializationError = error;
    }
  }

  static void _ensureReady() {
    if (!_ready) {
      throw const FirebaseBackendException(
        'Firebase is not ready. Check google-services.json and rebuild the app.',
      );
    }
  }

  static String authEmailForPhone(String phone) {
    final digits = normalizePhone(phone);
    return '$digits@phone.agriai.app';
  }

  static String normalizePhone(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = '94${digits.substring(1)}';
    if (digits.length < 9) {
      throw const FirebaseBackendException('Enter a valid phone number.');
    }
    return digits;
  }

  static String _phoneLoginKey(String phone) {
    return 'phone_login_email_${normalizePhone(phone)}';
  }

  static Future<void> _savePhoneLogin(String phone, String email) async {
    if (phone.trim().isEmpty || email.trim().isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _phoneLoginKey(phone),
      email.trim().toLowerCase(),
    );
  }

  static Future<String?> _savedEmailForPhone(String phone) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_phoneLoginKey(phone));
  }

  static Future<void> _linkCurrentUserPhoneLogin() async {
    final user = currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) return;
    try {
      final profile = await _firestore.collection('users').doc(user.uid).get();
      final phone = profile.data()?['phone'] as String?;
      if (phone != null && phone.trim().isNotEmpty) {
        await _savePhoneLogin(phone, email);
      }
    } catch (_) {
      // Email login is still valid if the optional local phone link fails.
    }
  }

  static Future<void> register({
    required String fullName,
    required String phone,
    required String password,
    required String district,
    required String farmName,
    required String language,
    required String contactEmail,
  }) async {
    final authEmail = contactEmail.trim().toLowerCase();
    if (!authEmail.contains('@') || !authEmail.contains('.')) {
      throw const FirebaseBackendException(
        'Enter a valid email address for login and password recovery.',
      );
    }
    UserCredential? credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: authEmail,
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(fullName.trim());

      final userRef = _firestore.collection('users').doc(user.uid);
      final farmRef = userRef.collection('farms').doc();
      final batch = _firestore.batch();
      batch.set(userRef, {
        'uid': user.uid,
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'authEmail': authEmail,
        'contactEmail': authEmail,
        'district': district,
        'language': language,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(farmRef, {
        'name': farmName.trim(),
        'location': district,
        'crop': 'Not selected',
        'area': '1 Acre',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      await _savePhoneLogin(phone, authEmail);
      await _auth.signOut();
    } catch (error) {
      if (credential?.user != null) {
        try {
          await credential!.user!.delete();
        } catch (_) {
          // Preserve the original setup error for the user.
        }
      }
      throw FirebaseBackendException(friendlyMessage(error));
    }
  }

  static Future<void> login({
    required String identifier,
    required String password,
  }) async {
    final value = identifier.trim();
    final isEmail = value.contains('@');
    final savedEmail = isEmail ? null : await _savedEmailForPhone(value);
    final authEmail = isEmail
        ? value.toLowerCase()
        : savedEmail ?? authEmailForPhone(value);
    try {
      await _auth.signInWithEmailAndPassword(
        email: authEmail,
        password: password,
      );
      await _linkCurrentUserPhoneLogin();
    } catch (error) {
      if (!isEmail &&
          savedEmail == null &&
          error is FirebaseAuthException &&
          const {
            'invalid-credential',
            'wrong-password',
            'user-not-found',
          }.contains(error.code)) {
        throw const FirebaseBackendException(
          'Phone login is not linked on this device. Sign in once with your registered email; then this phone number will work.',
        );
      }
      throw FirebaseBackendException(friendlyMessage(error));
    }
  }

  static Future<void> sendPasswordResetEmail(
    String email, {
    String languageCode = 'en',
  }) async {
    final value = email.trim().toLowerCase();
    if (!value.contains('@') || !value.contains('.')) {
      throw const FirebaseBackendException(
        'Enter the recovery email used during registration.',
      );
    }
    try {
      await _auth.setLanguageCode(languageCode);
      await _auth.sendPasswordResetEmail(email: value);
    } catch (error) {
      throw FirebaseBackendException(friendlyMessage(error));
    }
  }

  static Future<void> signOut() async {
    if (_ready) await _auth.signOut();
  }

  static Stream<Map<String, dynamic>?> profileStream() {
    final user = currentUser;
    if (user == null) return Stream.value(null);
    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  static Future<String> currentDistrict() async {
    final user = currentUser;
    if (user == null) return 'Trincomalee';
    try {
      final profile = await _firestore.collection('users').doc(user.uid).get();
      return profile.data()?['district'] as String? ?? 'Trincomalee';
    } catch (_) {
      return 'Trincomalee';
    }
  }

  static Future<bool> updateProfile({
    required String fullName,
    required String phone,
    required String contactEmail,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw const FirebaseBackendException('Please login again.');
    }
    try {
      final normalizedEmail = contactEmail.trim().toLowerCase();
      var verificationSent = false;
      if (normalizedEmail.isNotEmpty &&
          (!normalizedEmail.contains('@') || !normalizedEmail.contains('.'))) {
        throw const FirebaseBackendException('Enter a valid email address.');
      }
      if (normalizedEmail.isNotEmpty &&
          user.email?.toLowerCase() != normalizedEmail) {
        await user.verifyBeforeUpdateEmail(normalizedEmail);
        verificationSent = true;
      }
      await _firestore.collection('users').doc(user.uid).set({
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'contactEmail': normalizedEmail,
        if (verificationSent) 'pendingAuthEmail': normalizedEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await user.updateDisplayName(fullName.trim());
      final currentAuthEmail = user.email;
      if (currentAuthEmail != null && currentAuthEmail.isNotEmpty) {
        await _savePhoneLogin(phone, currentAuthEmail);
      }
      return verificationSent;
    } catch (error) {
      throw FirebaseBackendException(friendlyMessage(error));
    }
  }

  static Future<void> updateLanguage(String language) async {
    final user = currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set({
      'language': language,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<List<Map<String, dynamic>>> farmsStream() {
    final user = currentUser;
    if (user == null) return Stream.value(const []);
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('farms')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  static Future<void> addFarm({
    required String name,
    required String crop,
    required double acres,
    required DateTime plantedOn,
    required DateTime harvestOn,
    required String notes,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw const FirebaseBackendException('Please login again.');
    }
    final profile = await _firestore.collection('users').doc(user.uid).get();
    await _firestore.collection('users').doc(user.uid).collection('farms').add({
      'name': name.trim(),
      'location': profile.data()?['district'] ?? 'Trincomalee',
      'crop': crop.trim(),
      'area':
          '${acres.toStringAsFixed(acres.truncateToDouble() == acres ? 0 : 1)} Acres',
      'acres': acres,
      'plantedOn': Timestamp.fromDate(plantedOn),
      'harvestOn': Timestamp.fromDate(harvestOn),
      'notes': notes.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteFarm(String farmId) async {
    final user = currentUser;
    if (user == null) {
      throw const FirebaseBackendException('Please login again.');
    }
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('farms')
        .doc(farmId)
        .delete();
  }

  static Stream<List<Map<String, dynamic>>> marketListingsStream() {
    if (currentUser == null) return Stream.value(const []);
    return _firestore
        .collection('marketListings')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  static Future<void> addMarketListing({
    required String category,
    required String item,
    required String quantity,
    required String unit,
    required String price,
    required String notes,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw const FirebaseBackendException('Please login again.');
    }
    final profile = await _firestore.collection('users').doc(user.uid).get();
    final priceValue = double.tryParse(
      price.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    await _firestore.collection('marketListings').add({
      'ownerId': user.uid,
      'ownerName': user.displayName ?? 'Farmer',
      'category': category,
      'item': item.trim(),
      'quantity': quantity.trim(),
      'unit': unit,
      'price': priceValue == null
          ? price.trim()
          : 'Rs. ${priceValue.round()}/$unit',
      'priceValue': priceValue,
      'notes': notes.trim(),
      'district': profile.data()?['district'] ?? '',
      'contactPhone': profile.data()?['phone'] ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteMarketListing(String listingId) async {
    final user = currentUser;
    if (user == null) {
      throw const FirebaseBackendException('Please login again.');
    }
    await _firestore.collection('marketListings').doc(listingId).delete();
  }

  static Future<double?> communityPriceForCrop(String crop) async {
    final snapshot = await _firestore.collection('marketListings').get();
    final values = snapshot.docs
        .where(
          (doc) => (doc.data()['item']?.toString().toLowerCase() ?? '')
              .contains(crop.toLowerCase()),
        )
        .map((doc) => (doc.data()['priceValue'] as num?)?.toDouble())
        .whereType<double>()
        .where((value) => value > 0)
        .toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static Stream<List<Map<String, dynamic>>> notificationsStream() {
    final user = currentUser;
    if (user == null) return Stream.value(const []);
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .snapshots()
        .map((snapshot) {
          const legacyDemoTitles = {
            'Weather Alert',
            'Disease Warning',
            'Market Update',
            'Harvest Reminder',
          };
          final items = snapshot.docs
              .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
              .where((item) => !legacyDemoTitles.contains(item['title']))
              .toList();
          items.sort((first, second) {
            final a = first['createdAt'] as Timestamp?;
            final b = second['createdAt'] as Timestamp?;
            return (b?.millisecondsSinceEpoch ?? 0).compareTo(
              a?.millisecondsSinceEpoch ?? 0,
            );
          });
          return items;
        });
  }

  static Future<void> addNotification({
    required String title,
    required String message,
    required String type,
  }) async {
    final user = currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .add({
          'title': title,
          'message': message,
          'type': type,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  static Future<void> markAllNotificationsRead() async {
    final user = currentUser;
    if (user == null) return;
    final notifications = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .get();
    final batch = _firestore.batch();
    for (final notification in notifications.docs) {
      batch.update(notification.reference, {'isRead': true});
    }
    await batch.commit();
  }

  static Future<void> saveDiseaseScan({
    required String selectedCrop,
    required String detectedCrop,
    required String growthStage,
    required String result,
    required String rawLabel,
    required double confidence,
  }) async {
    final user = currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('diseaseScans')
        .add({
          'selectedCrop': selectedCrop,
          'detectedCrop': detectedCrop,
          'growthStage': growthStage,
          'hadImage': true,
          'result': result,
          'rawLabel': rawLabel,
          'confidence': confidence,
          'model': 'agriai_mobilenetv3large_122class_float16',
          'createdAt': FieldValue.serverTimestamp(),
        });
    try {
      await addNotification(
        title: 'Disease scan completed',
        message: '$detectedCrop: $result (${(confidence * 100).round()}%)',
        type: 'disease',
      );
    } catch (_) {}
  }

  static Future<void> saveCropRecommendation({
    required String district,
    required String soil,
    required String season,
    required String waterSource,
    required double acres,
    required String recommendedCrop,
    required int confidence,
    required double expectedYield,
    required double expectedProfit,
    required String riskLevel,
    required String waterRequirement,
    required List<Map<String, Object>> alternatives,
    required bool liveWeatherUsed,
  }) async {
    final user = currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('recommendations')
        .add({
          'district': district,
          'soil': soil,
          'season': season,
          'waterSource': waterSource,
          'acres': acres,
          'recommendedCrop': recommendedCrop,
          'confidence': confidence,
          'expectedYield': expectedYield,
          'expectedProfit': expectedProfit,
          'riskLevel': riskLevel,
          'waterRequirement': waterRequirement,
          'alternatives': alternatives,
          'liveWeatherUsed': liveWeatherUsed,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  static Future<void> saveProfitPlan({
    required String crop,
    required double acres,
    required double investment,
    required double revenue,
    required double expectedProfit,
    required double expectedYield,
    required double pricePerUnit,
  }) async {
    final user = currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('profitPlans')
        .add({
          'crop': crop,
          'acres': acres,
          'investment': investment,
          'revenue': revenue,
          'expectedProfit': expectedProfit,
          'expectedYield': expectedYield,
          'pricePerUnit': pricePerUnit,
          'createdAt': FieldValue.serverTimestamp(),
        });
    try {
      await addNotification(
        title: 'Profit plan saved',
        message: '$crop expected profit: Rs. ${expectedProfit.round()}',
        type: 'market',
      );
    } catch (_) {}
  }

  static Future<void> saveReportRequest(String format) async {
    final user = currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('reportRequests')
        .add({
          'format': format,
          'status': 'requested',
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  static Future<void> saveFeedback(
    String message, {
    String? contactEmail,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw const FirebaseBackendException('Please login again.');
    }
    final value = message.trim();
    if (value.length < 5) {
      throw const FirebaseBackendException(
        'Please enter at least 5 characters.',
      );
    }
    final email = contactEmail?.trim().toLowerCase() ?? '';
    if (email.isNotEmpty && (!email.contains('@') || !email.contains('.'))) {
      throw const FirebaseBackendException('Enter a valid email address.');
    }
    final feedback = <String, dynamic>{
      'userId': user.uid,
      'userName': user.displayName ?? 'Farmer',
      'userEmail': user.email ?? '',
      'contactEmail': email,
      'message': value,
      'recipient': 'thadshanyaa@gmail.com',
      'status': 'new',
      'createdAt': FieldValue.serverTimestamp(),
    };
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('feedback')
        .add(feedback);
  }

  static String friendlyMessage(Object error) {
    if (error is FirebaseBackendException) return error.message;
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'email-already-in-use' =>
          'This email address is already used by another account.',
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'Email/phone number or password is incorrect.',
        'weak-password' =>
          'Use a stronger password with at least 6 characters.',
        'network-request-failed' => 'No internet connection. Please try again.',
        'operation-not-allowed' =>
          'Enable Email/Password in Firebase Authentication.',
        'invalid-email' => 'Enter a valid email address.',
        'requires-recent-login' =>
          'Please sign out, login again, and then update your recovery email.',
        'too-many-requests' =>
          'Too many attempts. Please wait a few minutes and try again.',
        _ => error.message ?? 'Firebase authentication failed.',
      };
    }
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Firestore access denied. Create the database and publish the security rules.';
      }
      if (error.code == 'unavailable') {
        return 'Firebase is temporarily unavailable. Check your connection.';
      }
      return error.message ?? 'Firebase request failed.';
    }
    return error.toString();
  }
}
