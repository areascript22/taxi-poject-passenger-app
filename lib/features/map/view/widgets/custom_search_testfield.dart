import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class CustomSearchTextField extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final FocusNode focusNode;
  final Widget? prefixIcon;
//  final Widget suffixIcon;
  final void Function()? activateMicrofone;

  const CustomSearchTextField({
    super.key,
    required this.hintText,
    required this.controller,
    required this.focusNode,
    required this.prefixIcon,
    // required this.suffixIcon,
    required this.activateMicrofone,
  });

  @override
  _CustomSearchTextFieldState createState() => _CustomSearchTextFieldState();
}

class _CustomSearchTextFieldState extends State<CustomSearchTextField> {
  // final FocusNode _focusNode = FocusNode();
  // bool tapInsideOutside = false;
  @override
  void initState() {
    super.initState();
    // _focusNode.addListener(() {
    //   setState(() {
    //     tapInsideOutside = _focusNode.hasFocus;
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: widget.focusNode,
      controller: widget.controller,
      decoration: InputDecoration(
        prefixIcon: widget.prefixIcon,
        hintText: widget.hintText, // Placeholder text
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // Rounded border
          borderSide: BorderSide.none, // Removes border lines
        ),
        filled: true,
        // fillColor: Colors.grey[200], // Light gray background
        suffixIcon: IconButton(
          icon: widget.controller!.text.isEmpty
              ? const Icon(Ionicons.mic_outline)
              : const Icon(Ionicons.close_outline),
          onPressed: widget.controller!.text.isNotEmpty
              ? () {
                  widget.controller!.clear();
                  setState(() {});
                }
              : widget.activateMicrofone,
        ),
      ),
    );
  }
}
