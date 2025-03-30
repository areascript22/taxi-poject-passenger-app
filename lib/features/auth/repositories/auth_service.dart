import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger logger = Logger();

  //Sign up with email and password
  Future<User?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      logger.i("New user sucessfully created");
      return userCredential.user;
    } catch (e) {
      logger.i("Error creating user: $e");
      return null;
    }
  }

  // Login with email and password
  Future<User?> loginWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return userCredential.user;
    } catch (e) {
      logger.e('Error logging in: $e');
      return null;
    }
  }

// Send email verification
  Future<void> sendVerificationEmail(User user) async {
    if (!user.emailVerified) {
      try {
        await user.sendEmailVerification();
        logger.i('Verification email sent');
      } catch (e) {
        logger.e('Failed to send verification email: $e');
      }
    }
  }

  //Send password recovery email
  Future<void> sendPasswordRecoveryEmail(
      String email, BuildContext context) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Email enviado, revisa tu bandeja de entrada')),
        );
      }

      logger.i('Password recovery email sent');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Error: No se pudo enviar el email para recuperar la contraseña')),
        );
      }
      logger.e('Failed to send password recovery email: $e');
    }
  }

}
