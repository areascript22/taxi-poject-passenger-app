import 'package:flutter/material.dart';

class PhoneTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const PhoneTextField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        prefixIcon: const Padding(
          padding:
              EdgeInsets.only(left: 12, right: 10), // Spacing around the prefix
          child: Text(
            '+593',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 0, // Allows the prefix icon to take minimal width
          minHeight: 0,
        ),
        hintText: hintText,
      ),
    );
  }
}
