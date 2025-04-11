import 'package:flutter/material.dart';

class BSElevatedButton extends StatefulWidget {
  final Widget child;
  final bool pickUpDestination;
  final Icon icon;
  final Color backgroundColor;
  final void Function()? onPressed;

  const BSElevatedButton({
    super.key,
    required this.child,
    required this.pickUpDestination,
    required this.icon,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  State<BSElevatedButton> createState() => _BSElevatedButtonState();
}

class _BSElevatedButtonState extends State<BSElevatedButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: widget.onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.backgroundColor,
        elevation: 5.0, // Controla la altura de la sombra
        shadowColor: Theme.of(context)
            .colorScheme
            .inversePrimary
            .withOpacity(0.65), // Color de la sombra
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          widget.icon,
          const SizedBox(width: 5.0),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
