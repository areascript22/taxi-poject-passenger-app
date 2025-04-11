import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/core/utils/toast_message_util.dart';
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
    print("Reqeusting via whatsapp");
    loading2 = true;
    try {
      final phone = "+593$phoneNumber";
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('sendOtpViaWhatsApp');
      final response = await callable.call({'phone': phone});
      logger.i("${response.data}  numberL $phone");
      print("${response.data}  numberL $phone");
      loading2 = false;
      return true;
    } catch (e) {
      logger.e("Error: $e");
      loading2 = false;
      return false;
    }
  }

//VErify OTP SMS or Whatsapp
  void verifyOtpSMSOrWhatsapp(String smsCode, BuildContext context) async {
    loading = true;
    if (smsCode.isEmpty) {
      ToastMessageUtil.showToast("Ingrese el código SMS para continuar");
      loading = false;
      return;
    }

    final response = await _verifySms(smsCode, context);
    print("Verifying sms: $response");
    if (context.mounted && !response) {
      final resp = await _verifyOTPWhatsapp(smsCode, context);
      print("Verifying whatsapp $resp");
    }
    loading = false;
  }

//To verifiy code SMS
  Future<bool> _verifySms(String smsCode, BuildContext context) async {
    if (verificationId == null) {
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
    } catch (e) {
      logger.i("Error...... ${e.toString()}");
      String message = "Error al verificar el código, intentelo de nuevo";
      if (e is FirebaseAuthException) {
        if (e.code == 'session-expired') {
          message = "El código ha expirado. Intentelo de nuevo";
        }
      }
      ToastMessageUtil.showToast(message);
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
