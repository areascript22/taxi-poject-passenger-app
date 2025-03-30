import 'package:flutter/material.dart';
import 'package:passenger_app/features/request_driver/viewmodel/request_driver_viewmodel.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:passenger_app/shared/widgets/custom_elevated_button.dart';
import 'package:passenger_app/shared/widgets/user_avatar.dart';
import 'package:provider/provider.dart';

class CancelRideBottomSheet extends StatelessWidget {
  const CancelRideBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final requestDriverViewModel = Provider.of<RequestDriverViewModel>(context);
    final sharedProvider = Provider.of<SharedProvider>(context);
    final driverInfo = sharedProvider.driverModel;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //Message: Passenger is waiting for you
          if (driverInfo != null)
            Text(
              "${driverInfo.name} está en camino",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 23),
            ),
          if (driverInfo != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: UserAvatar(imageUrl: driverInfo.profilePicture),
            ),
          const Text(
            "¿Esta seguro de que quiere cancelar?",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          //BUTTON: No
          const SizedBox(height: 5),
          CustomElevatedButton(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Text("No")),
          //BUTTON: Confirm cancel ride
          const SizedBox(height: 5),
          CustomElevatedButton(
            color: const Color.fromARGB(221, 213, 213, 213),
            onTap: () async {
              //Cancel ride
              if (driverInfo != null) {
                //Check if we are passenger or second passenger
                // requestDriverViewModel.updateDriverStatus(
                //   driverInfo.id,
                //   DriverRideStatus.canceled,
                //   context,
                // );
                await requestDriverViewModel.cancelRide(driverInfo.id, context);
              }

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text(
              "Sí cancelar",
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showCancelRideBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) => const CancelRideBottomSheet(),
  );
}
