import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String productionUrl = "https://ainutritiontracking.onrender.com/api";
  
  // URL test local:
  // - http://localhost:1000/api dùng cho Web (Chrome, Edge) và iOS Simulator.
  // - http://10.0.2.2:1000/api dùng cho Android Emulator.
  static const String localUrl = "http://localhost:1000/api";
  static const String localAndroidUrl = "http://10.0.2.2:1000/api";

  // Chuyển thành true để chạy local, false để dùng production
  static const bool useLocal = true;

  static String get baseUrl {
    if (useLocal) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return localAndroidUrl;
      }
      return localUrl;
    }
    return productionUrl;
  }
}
