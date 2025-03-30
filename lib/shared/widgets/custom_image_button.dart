import 'package:flutter/material.dart';

class CustomImageButton extends StatelessWidget {
  final String imagePath;
  final String title;
  final bool isSelected;
  final void Function()? onTap;

  const CustomImageButton({
    super.key,
    required this.imagePath,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: 100,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          color: isSelected ? Colors.blue[300] : Colors.transparent,
        ),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            // Image at the top
            Positioned(
              top: -3,
              child: Image.asset(
                imagePath,
                height: 35,
                fit: BoxFit.cover,
              ),
            ),
            // Text below the image
            Positioned(
              bottom: -2,
              child: Text(
                title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: !isSelected
                        ? Theme.of(context).colorScheme.inversePrimary
                        : Theme.of(context).colorScheme.background),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
