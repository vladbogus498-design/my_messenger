import 'package:flutter/foundation.dart';

class DesktopPlatformService {
  const DesktopPlatformService._();

  static bool get isWindowsDesktop =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  static bool get supportsVoiceRecording => !isWindowsDesktop;

  static String get unsupportedDesktopMessage => 'Not available on desktop yet';
}
