import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class BSTextField extends StatelessWidget {
  final TextEditingController textEditingController;
  final String hintText;
  final IconData leftIcon;
  final IconData rightIcon;
  final void Function()? onRightIconPressed;

  const BSTextField({
    super.key,
    required this.textEditingController,
    required this.hintText,
    required this.leftIcon,
    required this.rightIcon,
    this.onRightIconPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      
      controller: textEditingController,
      decoration: InputDecoration(
        suffixIcon: const Icon(Ionicons.pencil_outline),
        // icon: const Icon(Ionicons.pencil_outline),
        hintText: hintText,
      ),
    );
  }
}
