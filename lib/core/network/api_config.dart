import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String productionUrl = "https://ainutritiontracking.onrender.com/api";

  static const String _port = "5280";
  static const String _pcIP = "192.168.1.13";

  static String get baseUrl {
    return productionUrl;
  }
}
