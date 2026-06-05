import 'package:firebase_core/firebase_core.dart';

import 'config/app_config.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    final options = AppConfig.firebaseOptions;
    if (options != null) {
      return options;
    }
    throw UnsupportedError(
      'Firebase options must be supplied with --dart-define values.',
    );
  }
}
