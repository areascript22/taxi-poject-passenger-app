import 'package:flutter/material.dart';

class CustomCircularButton extends StatelessWidget {
  final void Function()? onPressed;
  final Icon icon;
  const CustomCircularButton({
    super.key,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .background, // Set the background color
        shape: BoxShape.circle, // Optional: make it circular
      ),
      child: IconButton(
        icon: icon,
        //   color: Colors.white, // Set the icon color
        onPressed: onPressed,
      ),
    );
  }
}
