import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:passenger_app/features/auth/view/pages/auth_wrapper.dart';
import 'package:passenger_app/features/home/repositories/home_services.dart';
import 'package:passenger_app/features/settings/repositorie/settings_repositorie.dart';

class SettingsViewModel extends ChangeNotifier {
  bool _loading = false;
  //getters
  bool get loading => _loading;
  //setters
  set loading(bool value) {
    _loading = value;
    notifyListeners();
  }

  //delete account
  Future<void> deleteaccount(BuildContext context) async {
    loading = true;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }
    final response = await SettingsService.deleteAccountPermanentely(uid);
    await HomeServices.signOut();
    loading = false;
    if (response && context.mounted) {
      Navigator.pop(context);
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const AuthWrapper(),
          ),
          (route) => false);
    }
  }
}
