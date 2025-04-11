import 'package:flutter/material.dart';
import 'package:passenger_app/features/technical_support/view/pages/technical_support_content/cancelar_solicitud.dart';
import 'package:passenger_app/features/technical_support/view/pages/technical_support_content/comunicate_admin.dart';
import 'package:passenger_app/features/technical_support/view/pages/technical_support_content/historial_carreras.dart';
import 'package:passenger_app/features/technical_support/view/pages/technical_support_content/solicitud_encomienda.dart';
import 'package:passenger_app/features/technical_support/view/pages/technical_support_content/solicitud_taxi.dart';
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
            OptionButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SolicitudTaxi()),
                );
              },
              title: '¿Cómo solicitar una carrera en taxi?',
            ),
            OptionButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SolicitudEncomienda()),
                );
              },
              title: '¿Cómo solicitar una encomienda?',
            ),
            OptionButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CancelarSolicitud()),
                );
              },
              title: '¿Cómo puedo cancelar una carrera o encomienda?',
            ),
            OptionButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HistorialDeCarreras()),
                );
              },
              title: '¿Cómo puedo ver mi hitorial de carreras?',
            ),
            OptionButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ContactoConAdministrador()),
                );
              },
              title:
                  '¿No encontraste lo que buscabas? Comunicate con el administrador',
            ),
          ],
        ),
      ),
    );
  }
}
