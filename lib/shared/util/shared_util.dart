import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';

class SharedUtil {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final logger = Logger();
  Timer? _audioTimer; // Store the timer globally

  //Open Options like whatsapp and SMS
  void sendSMS(String phoneNumber, String message) async {
    final logger = Logger();
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {'body': message},
    );
    logger.i("send sms : $phoneNumber");
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        throw 'Could not launch SMS: $smsUri';
      }
    } catch (e) {
      logger.e('Error sending SMS: $e');
    }
  }

  //Play audio
  Future<void> playAudio(String filePath) async {
    bool response = await Vibration.hasVibrator();
    if (response) {
      Vibration.vibrate();
    }
    if (filePath.isEmpty) {
      logger.e("Audio URL is empty: $filePath.aac");
      return;
    }
    try {
      await _audioPlayer.play(AssetSource(filePath), volume: 1);
    } catch (e) {
      logger.e("Error trying to play audio: $e");
    }
  }

  //Make vibrate
  Future<void> makePhoneVibrate() async {
    bool? response = await Vibration.hasVibrator();
    if (response != null && response) {
      await Vibration.vibrate();
    } else {
      logger.e("Vibration is not available.");
    }
  }

  Future<void> repeatAudio(String filePath) async {
    const duration = Duration(minutes: 5);
    const interval = Duration(seconds: 2); // Adjust this interval as needed
    final startTime = DateTime.now();
    await playAudio(filePath);
    _audioTimer = Timer.periodic(interval, (timer) async {
      if (DateTime.now().difference(startTime) >= duration) {
        timer.cancel(); // Stop repeating after 5 minutes
        _audioTimer = null;
      } else {
        await playAudio(filePath); // Call the playAudio function
      }
    });
  }

  void stopAudioLoop() {
    _audioTimer?.cancel();
    _audioTimer = null; // Reset the timer variable
  }

  // lauch whatsapp
  void launchWhatsApp(String phoneNumber, {String message = ''}) async {
    final Uri whatsappUri = Uri.parse(
        "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch WhatsApp';
    }
  }

  //
  Future<void> openEmailApp() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'taxigo11032025@gmail.com', // Cambia al email del administrador
      queryParameters: {
        'subject': 'Consulta desde la app',
        'body': 'Hola, me gustaría hacer una consulta sobre...'
      },
    );
    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      logger.e('No se pudo abrir la aplicación de correo, $e');
    }
  }
}
