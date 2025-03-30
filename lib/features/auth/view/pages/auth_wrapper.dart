import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:passenger_app/features/auth/view/pages/passenger_data_wrapper.dart';
import 'package:passenger_app/features/auth/view/pages/sign_in_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        //If user is already autenticated we can check if there is data or not
        if (snapshot.hasData) {
          return const PassengerDataWrapper();
        } else {
          return const SignInPage();
        }
      },
    );
  }
}
