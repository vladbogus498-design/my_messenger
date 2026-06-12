import 'package:flutter/foundation.dart';

import 'platform_detector_stub.dart'
    if (dart.library.io) 'platform_detector_io.dart';

class DesktopPlatformService {
  const DesktopPlatformService._();

  static bool get isWindowsDesktop => !kIsWeb && isWindowsPlatform;

  static bool get supportsVoiceRecording => !isWindowsDesktop;

  static String get unsupportedDesktopMessage => 'Not available on desktop yet';
}
