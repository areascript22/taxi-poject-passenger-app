import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  // Instancia del plugin de notificaciones locales
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Función estática para inicializar el canal de notificación
  static Future<void> initializeNotificationChannel() async {
    // Crear un canal de notificación de alta prioridad
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // ID del canal
      'High Importance Notifications', // Nombre del canal

      importance: Importance.high, // Prioridad alta
      playSound: true, // Reproducir sonido
    );

    // Crear el canal en el dispositivo
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  //permissions
  static Future<void> requestPermission() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
    print("PERMISSION STATUS: ${settings.authorizationStatus}");
  }

  //Get device token and init listener for local notifications
  static Future<String?> getDeviceToken() async {
    String? deviceToken = await FirebaseMessaging.instance.getToken();
    return deviceToken;
  }

  static Future<void> sendPushNotification({
    required String deviceToken,
    required String title,
    required String body,
    String? tripID,
  }) async {
    try {
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('sendPushNotification');

      final response = await callable.call({
        'token': deviceToken,
        'title': title,
        'body': body,
      });

      print(
          '✅ Notificación enviada al token : $deviceToken : ${response.data}');
    } on FirebaseFunctionsException catch (e) {
      print('❌ Error en la función: ${e.message} ');
    } catch (e) {
      print('❌ Error inesperado: $e');
    }
  }
}
