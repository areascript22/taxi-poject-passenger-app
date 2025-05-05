import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/core/utils/toast_message_util.dart';
import 'package:passenger_app/features/auth/repositories/verification_id_storage.dart';
import 'package:passenger_app/features/auth/view/pages/auth_wrapper.dart';
import 'package:passenger_app/shared/models/g_user.dart';
import 'package:passenger_app/shared/models/passenger_model.dart';
import 'package:passenger_app/features/auth/model/api_status_code.dart';
import 'package:passenger_app/features/auth/repositories/passenger_servide.dart';

class PassengerViewModel extends ChangeNotifier {
  final Logger logger = Logger();
  String? phoneNumber;
  String? verificationId;
  bool _loading = false;
  bool _loading2 = false;
  PassengerModel? passenger;

  //GETTTERS
  bool get loading => _loading;
  bool get loading2 => _loading2;

  //SETTERS
  set loading(bool value) {
    _loading = value;
    notifyListeners();
  }

  set loading2(bool value) {
    _loading2 = value;
    notifyListeners();
  }

//Get Passenger data
  Future<bool> getPassengerData() async {
    loading = true;
    var response = PassengerService.getUserData();
    if (response is Succes) {
      var temp = response as Succes;
      passenger = temp.response as PassengerModel;
      loading = false;
      return true;
    }

    if (response is Failure) {}

    loading = false;
    return false;
  }

  //get the current authenticated user
  Future<GUser?> getAuthenticatedPassengerData() async {
    return PassengerService.getUserData();
  }

  //Save Pasesnger data in Firestore
  Future<bool> savePassengerDataInFirestore(GUser passenger) async {
    loading = true;
    bool response =
        await PassengerService.savePassengerDataInFirestore(passenger);
    loading = false;
    return response;
  }

// Upload image to Firebase Storage
  Future<String?> uploadImage(File imageFile, String uid) async {
    loading = true;
    String? response = await PassengerService.uploadImage(imageFile, uid);
    loading = false;
    return response;
  }

//Send OTP via wahtsapp
  Future<bool> requestSMSViaWhatsApp(BuildContext context) async {
    loading2 = true;
    try {
      final phone = "+593$phoneNumber";
      // final phone = "+593967340047";
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('sendOtpViaWhatsApp');
      final response = await callable.call({'phone': phone});

      logger.i("${response.data}  numberL $phone");
      loading2 = false;

      if (response.data['success']) {
        logger.f("OTP enviado mediante whatsapp");
        return true;
      } else {
        return false;
      }
    } catch (e) {
      logger.e("Error: $e");
      loading2 = false;
      return false;
    }
  }

  //sign in with Custom token directly
  Future<bool> signInWithCustomToken(
      String phoneNumber, BuildContext context) async {
    final phone = "+593$phoneNumber";
    try {
      ToastMessageUtil.showToast("Iniciando sesión", context);
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('getAuthCustomToken');

      final response = await callable.call({
        'phone': phone.toString(), // Ejemplo: "+12345678900"
      });
      final data = response.data;
      if (data['success'] == true && data['customToken'] != null) {
        // Iniciar sesión con el custom token
        await FirebaseAuth.instance.signInWithCustomToken(data['customToken']);
        await VerificationStorage.clearVerificationId();
        logger.f('Éxito');
        return true;
      } else {
        if (context.mounted) {
          ToastMessageUtil.showToast(
              "No se pudo inicar sesión. Intentalo mas tarde", context);
        }

        logger.e('Error');
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        ToastMessageUtil.showToast(
            "No se pudo inicar sesión. Intentalo mas tarde", context);
      }
      logger.e('Error: $e');
      return false;
    }
  }

//VErify OTP SMS or Whatsapp
  void verifyOtpSMSOrWhatsapp(String smsCode, BuildContext context) async {
    FocusScope.of(context).unfocus();
    loading = true;
    if (smsCode.isEmpty) {
      ToastMessageUtil.showToast(
          "Ingrese el código SMS para continuar", context);
      loading = false;
      return;
    }

    final response = await _verifySms(smsCode, context);
    if (response) {
      await VerificationStorage.clearVerificationId();
    }
    // print("Verifying sms: $response");
    if (context.mounted && !response) {
      final resp = await _verifyOTPWhatsapp(smsCode, context);
      if (resp) {
        await VerificationStorage.clearVerificationId();
      }
      //  print("Verifying whatsapp $resp");
    }
    loading = false;
  }

//To verifiy code SMS
  Future<bool> _verifySms(String smsCode, BuildContext context) async {
    if (verificationId == null) {
      logger.w("verificationId es null");
      ToastMessageUtil.showToast(
          "Código inválido. Inténtelo de nuevo.", context);
      return false;
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId!,
      smsCode: smsCode,
    );

    try {
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (context.mounted) {
        Navigator.pop(context);
      }

      return true;
    } on FirebaseAuthException catch (e) {
      String message = "Error al verificar el código. Inténtelo de nuevo.";
      logger.e("FirebaseAuthException: ${e.code} - ${e.message}");

      switch (e.code) {
        case 'invalid-verification-code':
          message = "El código ingresado no es válido.";
          break;
        case 'session-expired':
          message = "El código ha expirado. Solicite uno nuevo.";
          if (context.mounted) {
            ToastMessageUtil.showToast(message, context);
          }
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthWrapper()),
              (Route<dynamic> route) => false, // elimina todo el stack
            );
          }
          return false;
        case 'invalid-verification-id':
          message = "La sesión de verificación no es válida.";
          break;
        case 'too-many-requests':
          message = "Demasiados intentos. Intente más tarde.";
          break;
        case 'network-request-failed':
          message = "Sin conexión a Internet. Verifique su red.";
          break;
        default:
          message = "Error: ${e.message ?? "Ocurrió un error inesperado"}";
          break;
      }
      if (context.mounted) {
        ToastMessageUtil.showToast(message, context);
      }

      return false;
    } catch (e, stacktrace) {
      logger.e("Excepción no controlada: $e , $stacktrace");
      if (context.mounted) {
        ToastMessageUtil.showToast(
            "Ocurrió un error inesperado. Inténtelo nuevamente.", context);
      }
      return false;
    }
  }

  Future<bool> _verifyOTPWhatsapp(String smsCode, BuildContext context) async {
    try {
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('verifyOtpCode');
      final response = await callable.call({
        'phone': '+593967340047',
        'otp': smsCode,
      });
      final token = response.data['customToken'];
      await FirebaseAuth.instance.signInWithCustomToken(token);
      if (context.mounted) {
        Navigator.pop(context);
      }
      return true;
    } catch (e) {
      logger.e("Error: $e");
      return false;
    }
  }

  // Future<void> loginWithPhoneNumber(
  //     String phoneNumber,
  //     Function(String verificationId) onCodeSent,
  //     Function(String error) onError) async {
  //   try {
  //     await _auth.verifyPhoneNumber(
  //       phoneNumber: phoneNumber,
  //       timeout: const Duration(seconds: 60),
  //       verificationCompleted: (PhoneAuthCredential credential) async {
  //         // Auto-retrieve or instant verification (for Android)
  //         await _auth.signInWithCredential(credential);
  //       },
  //       verificationFailed: (FirebaseAuthException e) {
  //         onError(e.message ?? "Verification failed");
  //       },
  //       codeSent: (String verificationId, int? resendToken) {
  //         onCodeSent(verificationId);
  //       },
  //       codeAutoRetrievalTimeout: (String verificationId) {},
  //     );
  //   } catch (e) {
  //     onError(e.toString());
  //   }
  // }

  // Future<UserCredential> verifyOTP(
  //     String verificationId, String otpCode) async {
  //   PhoneAuthCredential credential = PhoneAuthProvider.credential(
  //     verificationId: verificationId,
  //     smsCode: otpCode,
  //   );
  //   return await _auth.signInWithCredential(credential);
  // }
}
