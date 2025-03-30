import 'dart:async';
import 'package:flutter/material.dart';
import 'package:passenger_app/features/request_delivery/viewmodel/delivery_request_viewmodel.dart';
import 'package:passenger_app/shared/models/driver_model.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:passenger_app/shared/widgets/custom_elevated_button.dart';
import 'package:provider/provider.dart';

class DeliveryArrivedBottomSheet extends StatefulWidget {
  const DeliveryArrivedBottomSheet({
    super.key,
  });

  @override
  State<DeliveryArrivedBottomSheet> createState() =>
      _DeliveryArrivedBottomSheetState();
}

class _DeliveryArrivedBottomSheetState
    extends State<DeliveryArrivedBottomSheet> {
  int timeCount = 300;
  late Timer countDownTimer;

  @override
  void initState() {
    super.initState();
    if (context.mounted) {
      countDownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (timeCount > 0) {
          setState(() {
            timeCount--;
          });
        } else {
          countDownTimer.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    countDownTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deliveryRequestViewModel =
        Provider.of<DeliveryRequestViewModel>(context);
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
                    '${driverModel.name} ha llegado con su pedido.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  //Vehicle model
                  Text(
                    "${driverModel.vehicleModel}, ${driverModel.carRegistrationNumber}",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),

            //Timer Countdown
            const SizedBox(height: 20),
            Text(
              formatTime(timeCount),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 45),
            ),
            const Text(
              "Trate de llegar a tiempo",
              style: TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 10),

            //BUTTON: Ready, on the way
            Row(
              children: [
                Expanded(
                  child: CustomElevatedButton(
                    onTap: () async {
                      //Update Delivery Status
                      await deliveryRequestViewModel.updatedeliveryStatus(
                          DeliveryStatus.passengerHasThePakcage, context);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Tengo el pedido"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  //Helper funtions for this page
  String formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

void showDeliveryArrivedBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    // isDismissible: false, // Prevents dismiss by tapping outside
    // enableDrag: false, // Prevents dismiss by swiping down
    isScrollControlled: true,
    builder: (BuildContext context) {
      // Wrapping bottom sheet content in WillPopScope
      return const DeliveryArrivedBottomSheet();
    },
  );
}
