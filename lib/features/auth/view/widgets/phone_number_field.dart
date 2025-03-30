import 'package:flutter/material.dart';

class PhoneNumberField extends StatefulWidget {
  final TextEditingController textController;
  const PhoneNumberField({super.key, required this.textController});

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.textController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        prefixIcon: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("+593"),
              SizedBox(width: 8),
              Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        hintText: 'Número de teléfono',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        //  fillColor: Colors.grey[200],
      ),
    );
  }
}
