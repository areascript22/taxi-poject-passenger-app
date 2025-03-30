// dialog_util.dart

import 'package:flutter/material.dart';

class DialogUtil {
  //Info Dialog
  static void messageDialog({
    required BuildContext context,
    required void Function() onAccept,
    required void Function() onCancel,
    required Widget content,
  }) {
    showDialog(
      context: context,
      builder: (context) {
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
                  content,
                  // const SizedBox(height: 5.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        onPressed: onCancel,
                        child: Text(
                          'Cancelar',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: onAccept,
                        child: Text(
                          "Aceptar",
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
 
}
