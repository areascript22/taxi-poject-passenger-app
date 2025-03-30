import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class SelectLocationIcon extends StatelessWidget {
  final double mainIconSize;
  final Widget childT;
  const SelectLocationIcon({
    super.key,
    required this.mainIconSize,
    required this.childT,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 30, end: mainIconSize),
        duration: const Duration(milliseconds: 250),
        builder: (BuildContext context, double size, Widget? child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: childT,
              ),
              Icon(
                Ionicons.location,
                size: size,
              ),
              const SizedBox(
                height: 70,
              ),
            ],
          );
        },
      ),
    );
  }
}
