



import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _pcIp = "192.168.137.1";

  static String get baseUrl {
    // Flutter Web
    if (kIsWeb) {
      return "http://localhost:8080";
    }

    // Android
    if (Platform.isAndroid) {
      return "http://10.0.2.2:8080";
    }

    // iOS
    if (Platform.isIOS) {
      return "http://localhost:8080";
    }

    return "http://$_pcIp:8080";
  }
}
