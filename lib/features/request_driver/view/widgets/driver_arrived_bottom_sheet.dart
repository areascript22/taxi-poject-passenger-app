import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:passenger_app/features/request_driver/viewmodel/request_driver_viewmodel.dart';
import 'package:passenger_app/shared/models/driver_model.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:passenger_app/shared/widgets/custom_elevated_button.dart';
import 'package:provider/provider.dart';

class DriverArrivedBottomSheet extends StatefulWidget {
  const DriverArrivedBottomSheet({
    super.key,
  });

  @override
  State<DriverArrivedBottomSheet> createState() =>
      _DriverArrivedBottomSheetState();
}

class _DriverArrivedBottomSheetState extends State<DriverArrivedBottomSheet> {
  int timeCount = 300;
  late Timer countDownTimer;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final requestDriverViewModel = Provider.of<RequestDriverViewModel>(context);
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
            //Message "I have arrived"
            Text(
              '${driverModel!.name} ha llegado',
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
            //Vehicle model
            Text(
              driverModel.vehicleModel,
              style: const TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 20),

            //Timer Countdown
            Text(
              formatTime(timeCount),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 45),
            ),
            const Text(
              "Trate de llegar a timepo",
              style: TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 10),

            //BUTTON: Ready, on the way
            Row(
              children: [
                Expanded(
                  child: CustomElevatedButton(
                    onTap: () async {
                      requestDriverViewModel.updateDriverStatus(
                          sharedProvider.driverModel!.id,
                          DriverRideStatus.goingToDropOff,
                          context);
                      countDownTimer.cancel();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Ionicons.hand_left_outline,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text("Gracias")
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                //Contact button
                SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () {
                          // _sendSMS(
                          //     provider.driver!.phoneNumber, "Espenrando...");
                        },
                        icon: const Icon(
                          Ionicons.chatbubble_ellipses_outline,
                          size: 35,
                        ),
                      ),
                    ],
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

void showDriverArrivedBotttomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isDismissible: false, // Prevents dismiss by tapping outside
    enableDrag: false, // Prevents dismiss by swiping down
    isScrollControlled: true,
    builder: (BuildContext context) {
      // Wrapping bottom sheet content in WillPopScope
      return const DriverArrivedBottomSheet();
    },
  );
}
