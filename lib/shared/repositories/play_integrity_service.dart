import 'package:flutter/services.dart';

class PlayIntegrityService {
  static const MethodChannel _channel = MethodChannel('play_integrity');

  static Future<String?> getIntegrityToken1() async {
    try {
      final String? token = await _channel.invokeMethod('getIntegrityToken');
      return token;
    } catch (e) {
      print('Error fetching Play Integrity Token: $e');
      return null;
    }
  }
}
