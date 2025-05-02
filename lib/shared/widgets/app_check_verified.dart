import 'package:flutter/material.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

class AppCheckVerified extends StatefulWidget {
  const AppCheckVerified({Key? key}) : super(key: key);

  @override
  State<AppCheckVerified> createState() => _AppCheckVerifiedState();
}

class _AppCheckVerifiedState extends State<AppCheckVerified> {
  bool? _isValid;

  @override
  void initState() {
    super.initState();
    _checkAppCheckStatus();
  }

  Future<void> _checkAppCheckStatus() async {
    try {
      final tokenResult = await FirebaseAppCheck.instance.getToken(true);
      if (tokenResult!.isNotEmpty) {
        setState(() {
          _isValid = true;
        });
      } else {
        setState(() {
          _isValid = false;
        });
      }
    } catch (e) {
      // Error significa que no se puede obtener el token
      setState(() {
        _isValid = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isValid == null) {
      return const CircularProgressIndicator(); // o cualquier ícono de loading
    }

    return Icon(
      Icons.verified,
      color: _isValid! ? Colors.green : Colors.red,
      size: 25,
    );
  }
}
