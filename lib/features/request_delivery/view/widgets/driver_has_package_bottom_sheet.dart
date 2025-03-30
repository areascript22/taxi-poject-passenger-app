import 'package:flutter/material.dart';
import 'package:passenger_app/shared/models/driver_model.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:passenger_app/shared/util/shared_util.dart';
import 'package:passenger_app/shared/widgets/custom_elevated_button.dart';
import 'package:provider/provider.dart';

class DriverHasPackageBottomSheet extends StatefulWidget {
  const DriverHasPackageBottomSheet({
    super.key,
  });

  @override
  State<DriverHasPackageBottomSheet> createState() =>
      _DriverHasPackageBottomSheetState();
}

class _DriverHasPackageBottomSheetState
    extends State<DriverHasPackageBottomSheet> {
  final sharedUtil = SharedUtil();
  @override
  void initState() {
    super.initState();
    initializePage();
  }

  void initializePage() async {
    await sharedUtil.makePhoneVibrate();
    await sharedUtil.playAudio("sounds/packageOnTheWay.mp3");
  }

  @override
  Widget build(BuildContext context) {
    final sharedProvider = Provider.of<SharedProvider>(context);
    final DriverInformation? driverModel = sharedProvider.driverModel;

    return PopScope(
      canPop: false,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (driverModel != null)
              Column(
                children: [
                  //Message "I have arrived"
                  Text(
                    '${driverModel.name} ha recogido su pedido.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  //Vehicle model
                  Text(
                    '${driverModel.vehicleModel}, ${driverModel.carRegistrationNumber}',
                    style: const TextStyle(fontSize: 17),
                  ),
                  //Regitration number
                  // Container(
                  //   padding: const EdgeInsets.all(10),
                  //   decoration: BoxDecoration(
                  //       borderRadius: const BorderRadius.all(
                  //         Radius.circular(5),
                  //       ),
                  //       border: Border.all(
                  //         color: Colors.grey,
                  //         width: 2,
                  //       )),
                  //   child: Text(
                  //     driverModel.carRegistrationNumber,
                  //     style: Theme.of(context).textTheme.bodyLarge,
                  //   ),
                  // ),
                ],
              ),

            //BUTTON: Ready, on the way
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: CustomElevatedButton(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Aceptar"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void showDriverHasPackageBotttomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isDismissible: false, // Prevents dismiss by tapping outside
    enableDrag: false, // Prevents dismiss by swiping down
    isScrollControlled: true,
    builder: (BuildContext context) {
      // Wrapping bottom sheet content in WillPopScope
      return const DriverHasPackageBottomSheet();
    },
  );
}
