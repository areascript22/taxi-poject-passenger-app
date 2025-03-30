import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/core/utils/toast_message_util.dart';
import 'package:passenger_app/features/ride_history/view/widgets/custom_devider.dart';
import 'package:passenger_app/shared/widgets/custom_elevated_button.dart';
import 'package:passenger_app/shared/widgets/custom_testfield.dart';
import 'package:passenger_app/features/auth/viewmodel/passenger_viewmodel.dart';
import 'package:provider/provider.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  //
  int _secondsRemaining = 30; // Cambia el tiempo inicial si lo deseas
  late Timer _timer;
  bool _canResend = false;

  //
  final Logger logger = Logger();
  final TextEditingController textController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Form key for validation

  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  void startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
        setState(() {
          _canResend = true;
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passengerViewModel = Provider.of<PassengerViewModel>(context);
    return Scaffold(
      appBar: AppBar(),
      body: PopScope(
        canPop: true,
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //Titulo
                const Text(
                  "Ingresa el código",
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                //Texfiel de verificacion
                CustomTextField(
                  isKeyboardNumber: true,
                  hintText: 'Código sms',
                  textEditingController: textController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese su contraseña'; // Required validation
                    }
                    return null; // Return null if validation passes
                  },
                ),
                const SizedBox(height: 10),

                //Test
                CustomElevatedButton(
                  onTap: () => passengerViewModel.verifyOtpSMSOrWhatsapp(
                      textController.text, context),
                  child: passengerViewModel.loading
                      ? const CircularProgressIndicator()
                      : const Text("Verificar"),
                ),
                const SizedBox(height: 10),
                const CustomDevider(),
                const SizedBox(height: 10),
                //Reenviar por whatsapp
                const Text(
                  "¿Todavía no has recibido el código?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_canResend)
                  Text(
                    _canResend
                        ? 'Volver a enviar el código'
                        : 'Puedes reenviar el código en: ${formatTime(_secondsRemaining)}',
                    style: const TextStyle(fontSize: 20),
                  ),

                const SizedBox(height: 10),
                if (_canResend)
                  GestureDetector(
                    onTap: () async {
                      passengerViewModel.verificationId = null;
                      final response = await passengerViewModel
                          .requestSMSViaWhatsApp(context);
                      if (response && context.mounted) {
                        ToastMessageUtil.showToast(
                            "Código de verificación enviado a su WhatsApp");
                      } else {
                        ToastMessageUtil.showToast(
                            "No se pudo reenviar el código, intentalo de nuevo");
                      }
                    },
                    child: !passengerViewModel.loading2
                        ? const Text(
                            "Volver a enviar el código",
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                              decorationThickness: 0.8,
                            ),
                          )
                        : const CircularProgressIndicator(),
                  ),
                // ElevatedButton(
                //   onPressed: _canResend
                //       ? () async {
                //           passengerViewModel.verificationId = null;
                //           final response = await passengerViewModel
                //               .signInWithCustomToken1(context);
                //           if (response && context.mounted) {
                //             Navigator.pushReplacement(
                //               context,
                //               MaterialPageRoute(
                //                   builder: (context) => const VerificationPage()),
                //             );
                //           }
                //         }
                //       : null,
                //   child: Row(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       !passengerViewModel.loading
                //           ? const Text("Reenviar por WhatsApp")
                //           : const CircularProgressIndicator(),
                //       const SizedBox(width: 10),
                //       const Icon(Ionicons.logo_whatsapp),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
