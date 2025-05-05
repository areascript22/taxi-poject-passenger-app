import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Acerca de nosotros',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
          maxLines: 2,
        ),
        iconTheme: const IconThemeData(color: Colors.purple),
      ),
      body: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Image.asset(
            //   "assets/img/taxi_go_icon.png",
            //   height: 200,
            //   width: 200,
            // ),
             Text(
              "asdfasfdasdf",
            ),
          ],
        ),
      ),
    );
  }
}
