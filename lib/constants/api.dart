import 'dart:io';

class ApiConfig {

  static const String _localServerIP = "192.168.1.100:8080";

  static String get baseUrl {

    if (Platform.isAndroid) {
      return "http://10.0.2.2:8080";
    }


    if (Platform.isIOS) {
      return "http://localhost:8080";
    }
    return "http://$_localServerIP";
  }
}
