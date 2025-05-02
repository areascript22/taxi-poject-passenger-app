import 'package:flutter/material.dart';
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),

      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Icon(Icons.info_outline, color: Colors.purple,size: 30,),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Asegúrate de tener buena señal para recibir tu código SMS.',
              style: TextStyle( fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    )
    ;
  }
}
