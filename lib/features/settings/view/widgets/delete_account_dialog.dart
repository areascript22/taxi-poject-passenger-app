import 'package:flutter/material.dart';

import 'package:ionicons/ionicons.dart';
import 'package:passenger_app/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:passenger_app/shared/widgets/custom_elevated_button.dart';
import 'package:provider/provider.dart';

//Delete account dialog
void dialogDeleteAccount({
  required BuildContext context,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return const DeleteAcount();
    },
  );
}

class DeleteAcount extends StatefulWidget {
  const DeleteAcount({
    super.key,
  });

  @override
  State<DeleteAcount> createState() => _DeleteAcountState();
}

class _DeleteAcountState extends State<DeleteAcount> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SettingsViewModel(),
      builder: (context, child) {
        final settingsViewModel = Provider.of<SettingsViewModel>(context);
        return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: SizedBox(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      "¿Estás seguro de eliminar su cuenta?",
                      style: TextStyle(fontSize: 18),
                    ),

                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(
                            Ionicons.information_circle_outline,
                            size: 50,
                            color: Colors.blue,
                          ),
                          Expanded(
                            child: Text(
                              "Todos los datos asociados a tu cuenta serán eliminadas.",
                              style: TextStyle(fontSize: 15),
                            ),
                          )
                        ],
                      ),
                    ),

                    //
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancelar',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        const SizedBox(width: 10),
                        CustomElevatedButton(
                          onTap: () async {
                            await settingsViewModel.deleteaccount(context);
                          },
                          child: !settingsViewModel.loading
                              ? const Text(
                                  "Aceptar",
                                )
                              : const CircularProgressIndicator(),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ));
      },
    );
  }
}
