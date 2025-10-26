import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyC_wZVPV1csibeOs7isMdZeAJjpZ9XO0BQ",
    authDomain: "darkkickchat-765e0.firebaseapp.com",
    projectId: "darkkickchat-765e0",
    storageBucket: "darkkickchat-765e0.firebasestorage.app",
    messagingSenderId: "366138349689",
    appId: "1:366138349689:web:58d15e2f8ad82415961ca8",
  );
}
