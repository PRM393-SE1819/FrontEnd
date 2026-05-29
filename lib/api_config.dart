import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _port = "5280";
  static const String _pcIP = "192.168.1.13";

  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:$_port/api";
    }

    if (Platform.isAndroid) {
      return "http://10.0.2.2:$_port/api";
    }

    return "http://$_pcIP:$_port/api";
  }
}
//app.use(cors({
//   origin: ['http://localhost:8080', 'http://127.0.0.1:8080'],
//   credentials: true
// }))