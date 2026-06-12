import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class AppConfig {
  const AppConfig._();

  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseMeasurementId = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
  );

  static const cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );
  static const cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );

  static FirebaseOptions? get firebaseOptions {
    if (_hasFirebaseDartDefines) {
      return const FirebaseOptions(
        apiKey: firebaseApiKey,
        authDomain: firebaseAuthDomain,
        projectId: firebaseProjectId,
        storageBucket: firebaseStorageBucket,
        messagingSenderId: firebaseMessagingSenderId,
        appId: firebaseAppId,
        measurementId: firebaseMeasurementId,
      );
    }

    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _windowsFirebaseOptions;
    }

    return null;
  }

  static bool get hasCloudinaryUnsignedUploadConfig =>
      cloudinaryCloudName.trim().isNotEmpty &&
      cloudinaryUploadPreset.trim().isNotEmpty;

  static bool get _hasFirebaseDartDefines {
    return firebaseApiKey.isNotEmpty &&
        firebaseProjectId.isNotEmpty &&
        firebaseMessagingSenderId.isNotEmpty &&
        firebaseAppId.isNotEmpty;
  }

  static const FirebaseOptions _windowsFirebaseOptions = FirebaseOptions(
    apiKey: 'AIzaSyC8r4HyPtERm3vHdwzTVhhE3iv-1AYSb1g',
    authDomain: 'darkkickchat-765e0.firebaseapp.com',
    projectId: 'darkkickchat-765e0',
    storageBucket: 'darkkickchat-765e0.firebasestorage.app',
    messagingSenderId: '366138349689',
    appId: '1:366138349689:android:19376aa5063fbb17961ca8',
  );
}
