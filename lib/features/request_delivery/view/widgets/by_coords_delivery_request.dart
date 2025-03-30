import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:passenger_app/features/request_delivery/view/widgets/delivery_details_bottom_sheet.dart';
import 'package:passenger_app/features/request_delivery/view/widgets/delivery_details_button.dart';
import 'package:passenger_app/features/request_delivery/viewmodel/delivery_request_viewmodel.dart';
import 'package:passenger_app/shared/models/request_type.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:passenger_app/shared/widgets/bs_elevated_button.dart';
import 'package:passenger_app/shared/widgets/colorized_text.dart';
import 'package:passenger_app/shared/widgets/custom_elevated_button.dart';
import 'package:passenger_app/shared/widgets/search_locations_bottom_sheet.dart';
import 'package:provider/provider.dart';

class ByCoordDeliveryRequest extends StatefulWidget {
  const ByCoordDeliveryRequest({super.key});

  @override
  State<ByCoordDeliveryRequest> createState() => _ByCoordDeliveryRequestState();
}

class _ByCoordDeliveryRequestState extends State<ByCoordDeliveryRequest> {
  bool showEncompleteFieldError = false;
  @override
  Widget build(BuildContext context) {
    final sharedProvider = Provider.of<SharedProvider>(context);
    final deliveryRequestViewModel =
        Provider.of<DeliveryRequestViewModel>(context);
    return Column(
      children: [
        //Pick up location
        const SizedBox(height: 10),
        BSElevatedButton(
          onPressed: () => showSearchBottomSheet(context, true),
          backgroundColor: sharedProvider.pickUpLocation == null
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.background,
          pickUpDestination: true,
          icon: const Icon(
            Ionicons.location,
            size: 30,
            color: Colors.green,
          ),
          child: sharedProvider.pickUpLocation == null
              ? const ColorizedText()
              : Text(
                  sharedProvider.pickUpLocation == null
                      ? "Lugar de recogida"
                      : sharedProvider.pickUpLocation!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
        ),
        const SizedBox(height: 5),

        //Destination Location
        // BSElevatedButton(
        //   onPressed: () => showSearchBottomSheet(context, false),
        //   backgroundColor: sharedProvider.dropOffLocation == null
        //       ? Theme.of(context).colorScheme.primary
        //       : Theme.of(context).colorScheme.background,
        //   pickUpDestination: false,
        //   icon: sharedProvider.dropOffLocation == null
        //       ? const Icon(
        //           Ionicons.search,
        //           size: 20,
        //           color: Colors.black54,
        //         )
        //       : const Icon(
        //           Ionicons.location,
        //           size: 30,
        //           color: Colors.blue,
        //         ),
        //   child: Text(
        //     sharedProvider.dropOffLocation == null
        //         ? "Destino"
        //         : sharedProvider.dropOffLocation!,
        //     style: Theme.of(context).textTheme.bodyLarge,
        //     overflow: TextOverflow.ellipsis,
        //   ),
        // ),

        //Delivery Details
        const SizedBox(height: 5),
        DeliveryDetailsButton(
          onPressed: () => showDeliveryDetailsBottomSheet(context),
        ),
        //Uncomplete fields message

        //Request Delivery Button
        const SizedBox(height: 10),
        CustomElevatedButton(
          onTap: () async {
            if (deliveryRequestViewModel.deliveryDetailsModel == null) {
              showDeliveryDetailsBottomSheet(context);
              return;
            }
            //Write data in Realtime Database
            await deliveryRequestViewModel.writeDeliveryRequest(
                context, sharedProvider, RequestType.byCoordinates);
          },
          child: deliveryRequestViewModel.loading
              ? const CircularProgressIndicator()
              : const Text("Solicitar enconmienda"),
        ),
      ],
    );
  }
}
