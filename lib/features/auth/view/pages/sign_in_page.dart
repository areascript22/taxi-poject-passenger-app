import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/core/utils/dialog_util.dart';
import 'package:passenger_app/core/utils/toast_message_util.dart';
import 'package:passenger_app/features/auth/repositories/verification_id_storage.dart';
import 'package:passenger_app/features/auth/view/pages/auth_wrapper.dart';
import 'package:passenger_app/features/auth/view/pages/verification_page.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:passenger_app/shared/widgets/app_check_verified.dart';
import 'package:passenger_app/shared/widgets/custom_elevated_button.dart';
import 'package:passenger_app/features/auth/view/widgets/phone_number_field.dart';
import 'package:passenger_app/features/auth/viewmodel/passenger_viewmodel.dart';
import 'package:provider/provider.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  //Text controller for number
  final Logger _logger = Logger();
  final TextEditingController textController = TextEditingController();
  bool isloading = false;
  bool showAlertMessage = false;

  @override
  void initState() {
    super.initState();
    textController.addListener(_onTextChanged);
    checkVerificationId();
  }

  //Check if there is a verification id in progress
  void checkVerificationId() async {
    final pasegerViewModel =
        Provider.of<PassengerViewModel>(context, listen: false);
    final resp = await VerificationStorage.getVerificationId();
    if (resp != null) {
      pasegerViewModel.verificationId = resp;
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VerificationPage()),
        );
      }
    }
  }

  //listneer
  void _onTextChanged() {
    showAlertMessage = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final passengerViewModel = Provider.of<PassengerViewModel>(context);
    final sharedProvider = Provider.of<SharedProvider>(context);
    //Sign in With Custom Token

    //Enviar codigo de verificacion
    void signInWithPhone() async {
      setState(() {
        isloading = true;
      });

      await FirebaseAuth.instance.verifyPhoneNumber(
        timeout: const Duration(seconds: 60),
        phoneNumber: "+593${textController.text}",
        // ✅ Auto-verification (No OTP needed)
        verificationCompleted: (PhoneAuthCredential credential) async {
          //Toast message
          ToastMessageUtil.showToast("Verificación Completada", context);
          _logger.i(
              "Verification completed: ${credential.smsCode}, ${credential.verificationId}");
          print(
              "Verification completed: ${credential.smsCode}, ${credential.verificationId}");
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);

            _logger.i("✅ Auto-sign-in successful!");
            print("✅ Auto-sign-in successful!");
            ToastMessageUtil.showToast("Inicio de sesión exitoso", context);

            setState(() {
              isloading = false;
            });
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthWrapper()),
                (Route<dynamic> route) => false, // elimina todo el stack
              );
            }
          } catch (e) {
            _logger.e("Error en la verificación automática: $e");
            print("Error en la verificación automática: $e");
            setState(() {
              isloading = false;
            });
          }
        },

        // ❌ Handles errors (e.g., invalid phone number, quota exceeded)
        verificationFailed: (FirebaseAuthException error) async {
          isloading = false;
          _logger.e(
              "❌ Error en la autenticación: ${error.message}   ${error.code}");
          print(
              "❌ Error en la autenticación: ${error.message}   ${error.code}");

          String errorMessage = "Error desconocido. Inténtelo de nuevo.";
          if (error.code == "invalid-phone-number") {
            errorMessage = "Número de teléfono inválido.";
          } else if (error.code == "quota-exceeded") {
            errorMessage = "Límite de solicitudes excedido. Intente más tarde.";
          } else if (error.code == "user-disabled") {
            errorMessage = "Este número de teléfono ha sido bloqueado.";
          } else if (error.code == "too-many-requests") {
            errorMessage = "Demasiados intentos. Inténtelo de nuevo más tarde.";
          } else {
            errorMessage = "Código de error: ${error.code}";
            passengerViewModel.phoneNumber = textController.text;
            passengerViewModel.verificationId = null;
            //TRY OTP VIA WHATSAPP
            final response =
                await passengerViewModel.requestSMSViaWhatsApp(context);
            if (response) {
              // Navigate to OTP verification screen
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const VerificationPage()),
                );
              }
              return;
            }
            //try log in with custom token
            final resp = await passengerViewModel
                .verifyPhoneAndLogin(textController.text);
            if (resp) {
              errorMessage = "Iniciando sesión";
            }
          }
          if (context.mounted) {
            ToastMessageUtil.showToast(errorMessage, context);
          }

          setState(() {
            isloading = false;
          });
        },

        // 📩 OTP sent via SMS
        codeSent: (String verificationId, int? forceResendingToken) async {
          ToastMessageUtil.showToast(
              "Código de verificación enviado vía SMS", context);
          _logger.i("📩 Código enviado: $verificationId");
          print("📩 Código enviado: $verificationId");
          //Save verification id locally
          await VerificationStorage.saveVerificationId(verificationId);

          setState(() {
            isloading = false;
          });
          passengerViewModel.phoneNumber = textController.text;
          passengerViewModel.verificationId = verificationId;
          // Navigate to OTP verification screen
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VerificationPage()),
            );
          }
        },
        // ⏳ Timeout reached (OTP must be entered manually)
        codeAutoRetrievalTimeout: (String verificationId) async {
          _logger.w("⏳ Tiempo de espera agotado para auto-retrieval.");
          print("⏳ Tiempo de espera agotado para auto-retrieval.");
        },
      );
    }

    void confirmSendSMS() {
      //Quitamos el 0 inicial del numero si es que lo tiene
      String text = textController.text;
      if (text.startsWith('0')) {
        textController.text = text.substring(1);
      }
      if (textController.text.length != 9) {
        setState(() {
          showAlertMessage = true;
        });
        ToastMessageUtil.showToast("Ingrese un número válido", context);
        return;
      }
      DialogUtil.messageDialog(
        onAccept: () {
          //Send SMS
          signInWithPhone();
          //  signInWithCustomToken1();
          Navigator.pop(context);
        },
        onCancel: () {
          //Pop the Dialog Util
          Navigator.pop(context);
        },
        content: Column(
          children: [
            const Text(
              "Se enviará un SMS al siguiente número",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              "+593 ${textController.text}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        context: context,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              //CONTENT
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //Titulo
                    const Text(
                      "Introduce tu número de teléfono.",
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "Te enviaremos un código para verificar tu número de telefono",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),

                    //boton prueba
                    // CustomElevatedButton(
                    //     onTap: () {
                    //       passengerViewModel.phoneNumber = '967340047';
                    //       passengerViewModel.requestSMSViaWhatsApp(context);
                    //     },
                    //     child: const Text("Test")),

                    const SizedBox(height: 60),

                    //TextField
                    PhoneNumberField(
                      textController: textController,
                    ),

                    if (showAlertMessage)
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "Ingrese un número válido",
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),
                    //Boton enviar
                    CustomElevatedButton(
                      onTap: !isloading
                          ? () async {
                              // FocusScope.of(context).unfocus();
                              confirmSendSMS();
                              //test
                              // passengerViewModel.verifyPhoneAndLogin(textController.text);
                              //  final logger = Logger();
                              //  final appCheckToken = await FirebaseAppCheck.instance.getToken(true);
                              //  logger.f('App Check Token: ${appCheckToken}');
                            }
                          : () {},
                      child: isloading
                          ? const CircularProgressIndicator()
                          : const Text("Enviar código"),
                    ),
                    const SizedBox(height: 10),
                    //Boton enviar WhatsApp
                    // CustomElevatedButton(
                    //   onTap: !isloading ? confirmSendSMS : () {},
                    //   child: isloading
                    //       ? const CircularProgressIndicator()
                    //       : const Text("Enviar código por WhatsApp"),
                    // ),

                    //test
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const VerificationPage()),
                        );
                      },
                      child: const Text(
                        "¿Ya tienes el código?, ingresalo aquí",
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.blue,
                          decorationThickness: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              //VERSION
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("V ${sharedProvider.version}"),
                  const SizedBox(width: 10),
                  const AppCheckVerified(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
