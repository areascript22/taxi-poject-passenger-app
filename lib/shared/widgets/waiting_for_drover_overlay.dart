import 'package:flutter/material.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:passenger_app/shared/widgets/custom_elevated_button.dart';
import 'package:provider/provider.dart';

class WitingForDriverOverlay extends StatelessWidget {
  //final void Function()? onCancel;
  const WitingForDriverOverlay({
    super.key,
    //required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final sharedProvider = Provider.of<SharedProvider>(context);
    return PopScope(
      canPop: false,
      child: Container(
        color: Colors.black.withOpacity(0.7), // Semi-transparent background
        child: Center(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Buscando conductor....',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const LinearProgressIndicator(
                  color: Colors.blue,
                ),
                //Cancel Button
                const SizedBox(height: 20),
                CustomElevatedButton(
                  onTap: () async {
                    await sharedProvider.cancelRequest();
                  },
                  child: const Text("Cancelar petición."),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showWaitingForDriverOverlay(
    BuildContext context, void Function()? onCancel) {
  showDialog(
    context: context,
    builder: (context) {
      return WitingForDriverOverlay();
    },
  );
}
