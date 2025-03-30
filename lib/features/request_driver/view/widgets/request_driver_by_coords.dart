import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:passenger_app/shared/widgets/colorized_text.dart';
import 'package:passenger_app/features/request_driver/viewmodel/request_driver_viewmodel.dart';
import 'package:passenger_app/shared/models/request_type.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:passenger_app/shared/widgets/bs_elevated_button.dart';
import 'package:passenger_app/shared/widgets/custom_elevated_button.dart';
import 'package:passenger_app/shared/widgets/search_locations_bottom_sheet.dart';
import 'package:provider/provider.dart';

class RequestDriverByCoords extends StatelessWidget {
  const RequestDriverByCoords({super.key});

  @override
  Widget build(BuildContext context) {
    final sharedProvider = Provider.of<SharedProvider>(context);
    final requestDriverViewModel = Provider.of<RequestDriverViewModel>(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      // color: Color.fromARGB(255, 112, 47, 47),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          //Pick up location
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //Title
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Seleccióna tu dirección.",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                        "Esta dirección es a donde el taxista llegará a recogerlo."),
                  ],
                ),
              ),

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
              //   backgroundColor: sharedViewModel.dropOffLocation == null
              //       ? Theme.of(context).colorScheme.primary
              //       : Theme.of(context).colorScheme.background,
              //   pickUpDestination: false,
              //   icon: sharedViewModel.dropOffLocation == null
              //       ? const Icon(
              //           Ionicons.search,
              //           size: 20,
              //           color: Colors.black54,
              //         )
              //       : const Icon(
              //           Ionicons.location,
              //           size: 20,
              //           color: Colors.blue,
              //         ),
              //   child: Expanded(
              //     child: Text(
              //       sharedViewModel.dropOffLocation == null
              //           ? "Destino"
              //           : sharedViewModel.dropOffLocation!,
              //       style: Theme.of(context).textTheme.bodyLarge,
              //       overflow: TextOverflow.ellipsis,
              //     ),
              //   ),
              // ),
              const SizedBox(height: 5),
              //Estimated time
              // if (estimatedtime)
              // if (sharedProvider.duration != null)
              //   Container(
              //     decoration: BoxDecoration(
              //       borderRadius: BorderRadius.circular(9),
              //       color: Theme.of(context).cardColor,
              //     ),
              //     child: Padding(
              //       padding: const EdgeInsets.all(9.0),
              //       child: Row(
              //         children: [
              //           const Icon(
              //             Ionicons.information_circle_outline,
              //             color: Colors.blue,
              //           ),
              //           const SizedBox(width: 10),
              //           Text(
              //             "Tiempo de viaje ~ ${sharedProvider.duration}",
              //             style: const TextStyle(
              //               fontWeight: FontWeight.bold,
              //               fontSize: 17,
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
            ],
          ),

          //Request Taxi
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CustomElevatedButton(
              onTap: () {
                
                requestDriverViewModel.requestTaxi2(
                    context, sharedProvider, RequestType.byCoordinates);
              },
              child: const Text("Solicitar taxi"),
            ),
          ),
        ],
      ),
    );
  }
}
