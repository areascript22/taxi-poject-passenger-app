import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/core/utils/dialog_util.dart';
import 'package:passenger_app/features/auth/view/pages/auth_wrapper.dart';
import 'package:passenger_app/features/home/repositories/home_services.dart';
import 'package:passenger_app/features/settings/view/widgets/delete_account_dialog.dart';

class SettingsPageContent extends StatelessWidget {
  const SettingsPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    final logger = Logger();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
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
              'Configuración',
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            //About app
            _buildButton(() {}, "Modo oscuro", subtitle: 'Desactivado'),
            //About app
            _buildButton(() {}, 'Acerca de la aplicación'),

            //Cerrar ceson
            ListTile(
              title: const Text(
                "Cerrar sesión",
              ),
              onTap: () => DialogUtil.messageDialog(
                  context: context,
                  onAccept: () async {
                    try {
                      await HomeServices.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AuthWrapper(),
                            ),
                            (route) => false);
                      }
                    } catch (e) {
                      logger.e("Error signging out: $e");
                    }
                  },
                  onCancel: () {
                    Navigator.pop(context);
                  },
                  content: const Text(
                    "¿Esta seguro de que quiere cerrar seción?",
                    style: TextStyle(fontSize: 17),
                  )),
            ),

            //Delete accout
            ListTile(
              title: const Text(
                "Eliminar cuenta",
                style: TextStyle(fontSize: 17, color: Colors.red),
              ),
              onTap: () => dialogDeleteAccount(
                context: context,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Build Listile
  ListTile _buildButton(void Function()? onTap, String title,
      {String? subtitle}) {
    return ListTile(
      onTap: onTap,
      title: Text(
        title,
        style: const TextStyle(fontSize: 17),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(
        Ionicons.chevron_forward,
        size: 28,
        color: Colors.grey,
      ),
    );
  }
}
