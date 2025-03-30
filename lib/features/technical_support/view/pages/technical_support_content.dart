import 'package:flutter/material.dart';
import 'package:passenger_app/features/technical_support/view/widgets/option_button.dart';

class TechnicalSupportContent extends StatefulWidget {
  const TechnicalSupportContent({super.key});

  @override
  State<TechnicalSupportContent> createState() =>
      _TechnicalSupportContentState();
}

class _TechnicalSupportContentState extends State<TechnicalSupportContent> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .inversePrimary
                    .withOpacity(0.2),
                blurRadius: 1,
                offset: const Offset(0, 5), // creates the soft blur effect
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Soporte técnico',
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            //Request a taxi ride
            OptionButton(
              onTap: () {},
              title: '¿Cómo solicitar una carrera en taxi?',
            ),
            //Request a taxi ride
            OptionButton(
              onTap: () {},
              title: '¿Cómo solicitar una encomienda?',
            ),
            //canceling ride
            OptionButton(
              onTap: () {},
              title: '¿Cómo puedo cancelar una carrera o encomienda?',
            ),
            //cRide history
            OptionButton(
              onTap: () {},
              title: '¿Cómo puedo ver mi hitorial de carreras?',
            ),
            //Admin support
            OptionButton(
              onTap: () {},
              title:
                  '¿No encontraste lo que buscabas? Comunicate con el administrador',
            ),
          ],
        ),
      ),
    );
  }
}
