import 'dart:io';

class ApiConfig {
  static const String _pcIp = "192.168.137.1";

  static String get baseUrl {
    if (Platform.isAndroid) {
      // Emulator
      if (_isEmulator()) {
        return "http://10.0.2.2:8080";
      }
      // Real device
      return "http://$_pcIp:8080";
    }

    if (Platform.isIOS) {
      return "http://localhost:8080";
    }

    return "http://$_pcIp:8080";
  }

  static bool _isEmulator() {
    return Platform.environment.containsKey('ANDROID_EMULATOR');
  }
}
