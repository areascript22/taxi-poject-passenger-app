import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class DeliveryDetailsButton extends StatelessWidget {
  final VoidCallback onPressed;

  const DeliveryDetailsButton({Key? key, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  Ionicons.cube_outline,
                  size: 20,
                ), // Left icon
                SizedBox(width: 10),
                Text(
                  'Detalles de la encomienda', // Text
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: onPressed,
              icon: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.black54,
              ),
            ),
            // Right arrow
          ],
        ),
      ),
    );
  }
}
