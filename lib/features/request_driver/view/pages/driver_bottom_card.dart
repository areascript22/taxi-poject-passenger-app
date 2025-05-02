import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ionicons/ionicons.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/features/map/view/widgets/circular_button.dart';
import 'package:passenger_app/shared/models/driver_model.dart';
import 'package:passenger_app/shared/models/request_type.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:passenger_app/shared/repositories/push_notification_service.dart';
import 'package:passenger_app/shared/util/shared_util.dart';
import 'package:passenger_app/shared/widgets/custom_elevated_button.dart';
import 'package:passenger_app/shared/widgets/user_avatar.dart';
import 'package:provider/provider.dart';

class DriverBottomCard extends StatefulWidget {
  const DriverBottomCard({super.key});

  @override
  State<DriverBottomCard> createState() => _DriverBottomCardState();
}

class _DriverBottomCardState extends State<DriverBottomCard> {
  final Logger logger = Logger();
  final sharedUtil = SharedUtil();
  @override
  Widget build(BuildContext context) {
    final SharedProvider sharedProvider = Provider.of<SharedProvider>(context);
    // final requestDriverViewModel =
    //     Provider.of<RequestDriverViewModel>(context, listen: false);
    DriverInformation? driverModel = sharedProvider.driverInformation;
    return Column(
      children: [
        //BUTTON: fit map
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              //TEST BUtton
              CustomElevatedButton(
                onTap: () async {
                  logger.f(
                      "Driver information: ${sharedProvider.driverInformation?.toMap()}");
                  await PushNotificationService.sendPushNotification(
                      deviceToken:
                          "ePzNboH9TOKITeCcRtrB0m:APA91bF8J0PUWgEWSmRzDzfBDhhMyS6eWgyYnxran4ao2E7Oh1lZAOpnUnc42zUpHnN3DyjAQ4pnE5LO6ZtK975GoRHKpRDuIiG01GFtIFSM3n9BobbTtc4",
                      title: "asdf",
                      body: "ssdfasdfasfd");
                },
                child: Text("Test"),
              ),
              //
              CircularButton(
                onPressed: () {
                  //call fit map function
                  if (sharedProvider.driverCurrentCoordenates == null) {
                    return;
                  }
                  if (sharedProvider.passengerCurrentCoords == null) {
                    return;
                  }
                  LatLng p2 = sharedProvider.driverCurrentCoordenates!;
                  LatLng p1;
                  if (sharedProvider.requestType == RequestType.byCoordinates) {
                    p1 = sharedProvider.pickUpCoordenates!;
                  } else {
                    p1 = sharedProvider.passengerCurrentCoords!;
                  }

                  sharedProvider.fitMarkers(p1, p2);
                },
                icon: const Icon(Ionicons.git_branch_outline),
              ),
            ],
          ),
        ),
        //Content
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              //  Expanded(
              //  child:
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  //Vehicle modle
                  Text(
                    driverModel!.vehicleModel,
                    style: Theme.of(context).textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  //Vehicle registration number
                  const SizedBox(height: 5),
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(5),
                        ),
                        border: Border.all(
                          color: Colors.grey,
                          width: 2,
                        )),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 15),
                      child: Text(
                        driverModel.carRegistrationNumber,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  //Taxi code
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/img/taxi.png',
                        height: 30,
                        width: 30,
                      ),
                      const SizedBox(width: 10),
                      Row(
                        children: [
                          Text(
                            driverModel.taxiCode,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),

              // ),
              const SizedBox(width: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //Profile Image
                  UserAvatar(imageUrl: driverModel.profilePicture),
                  //Name and ratings
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverModel.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          Text(driverModel.rating.toString()),
                        ],
                      ),
                    ],
                  ),
                  //Comunication options
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () {
                            //showDriverArrivedBotttomSheet(context);
                            sharedUtil.launchWhatsApp(driverModel.phone);
                          },
                          icon: const Icon(
                            Ionicons.chatbubble_ellipses_outline,
                            size: 30,
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
      ],
    );
  }
}
