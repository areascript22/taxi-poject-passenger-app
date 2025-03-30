import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final bool isObscureText;
  final bool isKeyboardNumber;
  final TextEditingController textEditingController;
  final String? Function(String?)? validator;
  const CustomTextField({
    super.key,
    required this.hintText,
    this.isObscureText = false,
    this.isKeyboardNumber = false,
    required this.textEditingController,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType:
          isKeyboardNumber ? TextInputType.number : TextInputType.text,
      obscureText: isObscureText,
      controller: textEditingController,
      decoration: InputDecoration(
        hintText: hintText,
      ),
      validator: validator,
    
    );
  }
}
