import 'package:shared_preferences/shared_preferences.dart';

class VerificationStorage {
  static const _key = 'verificationId';

  /// Guarda el verificationId
  static Future<void> saveVerificationId(String verificationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, verificationId);
  }

  /// Obtiene el verificationId guardado, o null si no existe
  static Future<String?> getVerificationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  /// Elimina el verificationId guardado
  static Future<void> clearVerificationId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
