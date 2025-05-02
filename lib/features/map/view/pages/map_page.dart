import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ionicons/ionicons.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/features/request_delivery/view/widgets/bottom_sheet_cancel_delivery.dart';
import 'package:passenger_app/features/request_driver/view/widgets/bottom_sheet_cancel_ride.dart';
import 'package:passenger_app/shared/models/request_type.dart';
import 'package:passenger_app/shared/widgets/countdown_timer.dart';
import 'package:passenger_app/shared/widgets/custom_drawer.dart';
import 'package:passenger_app/features/map/view/widgets/circular_button.dart';
import 'package:passenger_app/features/request_driver/view/pages/driver_bottom_card.dart';
import 'package:passenger_app/features/request_delivery/view/pages/request_delivery_bottom_sheet.dart';
import 'package:passenger_app/features/request_driver/view/pages/request_driver_bottom_sheet.dart';
import 'package:passenger_app/features/map/view/widgets/select_location_icon.dart';
import 'package:passenger_app/features/map/viewmodel/map_view_model.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:passenger_app/shared/widgets/waiting_for_drover_overlay.dart';
import 'package:provider/provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldkey = GlobalKey<ScaffoldState>();
  final logger = Logger();
  String _mapStyle = "";
  MapViewModel? mapViewModelToDispose;
  SharedProvider? sharedProviderToDispose;

  @override
  void initState() {
    super.initState();
    //Adign A value to our
    initializeNeccesaryData();
    logger.t("MAPR INITIALZIED");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    updateMapStyle();
  }

  @override
  void dispose() {
    sharedProviderToDispose?.mapController = Completer();
    super.dispose();
  }

  void initializeNeccesaryData() {
    final mapViewModel = Provider.of<MapViewModel>(context, listen: false);
    final sharedProvider = Provider.of<SharedProvider>(context, listen: false);
    mapViewModelToDispose = mapViewModel;
    sharedProviderToDispose = sharedProvider;
    mapViewModel.initializeAnimations(this, sharedProvider);
    mapViewModel.animateCameraToCurrentPosition(sharedProvider);
    //initialize bottomsheets (Just to execute its init state)
    RequestDriverBottomSheet(fitMap: () {});
    const RequestDeliveryBottomSheet();
    sharedProvider.loadGeoJson();
  }

  //Update map Style
  Future<void> updateMapStyle() async {
    Brightness newBrightness = MediaQuery.of(context).platformBrightness;
    final sharedProvider = Provider.of<SharedProvider>(context, listen: false);
    String stylePath = newBrightness == Brightness.dark
        ? 'assets/json/dark_map_style.json'
        : 'assets/json/light_map_style.json';

    String style = await rootBundle.loadString(stylePath);
    setState(() {
      _mapStyle = style;
    });
    if (sharedProvider.mapController.isCompleted) {
      GoogleMapController controller =
          await sharedProvider.mapController.future;
      controller.setMapStyle(_mapStyle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapViewModel = Provider.of<MapViewModel>(context);
    final sharedProvider = Provider.of<SharedProvider>(context);
    sharedProvider.mapPageContext = context;
    return Scaffold(
      key: scaffoldkey,
      appBar: AppBar(
        actions: [
          if (sharedProvider.driverInformation != null)
            TextButton(
              onPressed: () {
                if (!sharedProvider.requestDriverOrDelivery) {
                  showCancelRideBottomSheet(context);
                } else {
                  showCancelDeliveryBottomSheet(context);
                }
              },
              child: const Text(
                "Cancelar",
                style:
                    TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
        ],
        automaticallyImplyLeading: false,
        toolbarHeight: sharedProvider.driverInformation != null ? 40 : 0,
      ),
      drawer: const CustomDrawer(),
      body: Stack(
        alignment: Alignment.center,
        children: [
          //Map
          GoogleMap(
            // zoomControlsEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            initialCameraPosition: const CameraPosition(
              target: LatLng(-1.666836, -78.651048),
              zoom: 14,
            ),
            polylines: {sharedProvider.polylineFromPickUpToDropOff},
            polygons: sharedProvider.polygons,
            markers: {
              sharedProvider.driverInformation != null
                  ? sharedProvider.driverMarker
                  : const Marker(markerId: MarkerId("defauklt")),
              ...sharedProvider.markers
            },
            onMapCreated: (controller) {
              if (!sharedProvider.mapController.isCompleted) {
                sharedProvider.mapController.complete(controller);
                updateMapStyle();
              }
            },
            onCameraMove: (position) {
              if (sharedProvider.requestType != RequestType.byCoordinates) {
                return;
              }
              if (sharedProvider.driverInformation == null) {
                sharedProvider.pickUpCoordenates = position.target;
              }
            },
            onCameraMoveStarted: () =>
                mapViewModel.hideBottomSheet(sharedProvider),
            onCameraIdle: () =>
                mapViewModel.showBottomSheetWithDelay(sharedProvider),
          ),
          //TOP MESSAGE
          if (sharedProvider.driverInformation != null)
            Positioned(
              top: 5,
              left: 25,
              right: 25,
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10))),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Align items at the top
                    children: [
                      // Icon
                      const Icon(
                        Ionicons.alert_circle_outline,
                        color: Colors.blue,
                        size: 30,
                      ),
                      const SizedBox(width: 5),

                      Expanded(
                        child: sharedProvider.routeDuration != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment
                                    .start, // Align text to the left
                                children: [
                                  Text(
                                    '${sharedProvider.driverInformation!.name} llegará por ti en aproximadamente',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize
                                        .min, // Prevents row from taking full width
                                    children: [
                                      CountdownTimer(
                                          minutes:
                                              sharedProvider.routeDuration!,
                                          fontsize: 30),
                                      Text(
                                        " minutos",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Text(
                                'En marcha, vamos!!',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                      ),
                    ],
                  )),
            ),
          //Select Location Icon
          if (sharedProvider.driverInformation == null &&
              sharedProvider.requestType == RequestType.byCoordinates)
            SelectLocationIcon(
              mainIconSize: mapViewModel.mainIconSize,
              childT: mapViewModel.isMovingMap
                  ? const CircularProgressIndicator()
                  : sharedProvider.selectingPickUpOrDropOff
                      ? sharedProvider.pickUpLocation != null
                          ? Text(sharedProvider.pickUpLocation!)
                          : const CircularProgressIndicator(
                              color: Colors.blue,
                            )
                      : sharedProvider.dropOffLocation != null
                          ? Text(sharedProvider.dropOffLocation!)
                          : const CircularProgressIndicator(
                              color: Colors.blue,
                            ),
            ),
          //     Menu Icon
          if (!mapViewModel.enteredInSelectingLocationMode &&
              sharedProvider.driverInformation == null)
            Positioned(
              top: 10,
              left: 15,
              child: SlideTransition(
                position: mapViewModel.animOffsetDB,
                child: CircularButton(
                  onPressed: () => scaffoldkey.currentState?.openDrawer(),
                  icon: const Icon(Icons.menu),
                ),
              ),
            ),

          //Go to current location button
          if (sharedProvider.driverInformation == null)
            Positioned(
              top: 10,
              right: 10,
              child: SlideTransition(
                position: mapViewModel.animOffsetDB,
                child: CircularButton(
                  onPressed: () async {
                    if (sharedProvider.passengerCurrentCoords == null) return;
                    await sharedProvider.animateCameraToPosition(
                        sharedProvider.passengerCurrentCoords!);
                  },
                  icon: const Icon(Icons.navigation_rounded),
                ),
              ),
            ),

          //Return to Select Pick Up
          if (mapViewModel.enteredInSelectingLocationMode)
            Positioned(
              top: 10,
              left: 15,
              child: SlideTransition(
                position: mapViewModel.animOffsetDB,
                child: CircularButton(
                  onPressed: () {
                    mapViewModel.enteredInSelectingLocationMode = false;
                    sharedProvider.selectingPickUpOrDropOff = true;
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
            ),
          // //Button "Hecho"
          // if (mapViewModel.enteredInSelectingLocationMode)
          //   Positioned(
          //     left: 50,
          //     right: 50,
          //     bottom: 20,
          //     child: SlideTransition(
          //       position: mapViewModel.animOfssetBS,
          //       child: CustomElevatedButton(
          //         onTap: !mapViewModel.readableAddressObtained
          //             ? null
          //             : () async {
          //                 //draw route
          //                 await mapViewModel
          //                     .drawRouteBetweenTwoPoints(sharedProvider);
          //                 //Return
          //                 mapViewModel.enteredInSelectingLocationMode = false;
          //               },
          //         color: Colors.blue,
          //         child: mapViewModel.loading
          //             ? const CircularProgressIndicator()
          //             : const Text("Hecho"),
          //       ),
          //     ),
          //   ),

          //Request Driver Bottom sheet
          if (!mapViewModel.isMovingMap &&
              !mapViewModel.enteredInSelectingLocationMode &&
              !sharedProvider.requestDriverOrDelivery &&
              sharedProvider.driverInformation == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: mapViewModel.animOfssetBS,
                child: RequestDriverBottomSheet(
                  fitMap: () {
                    mapViewModel.fitMapToTwoLatLngs(
                        sharedProvider: sharedProvider);
                  },
                ),
              ),
            ),
          //Request Delivery Bottom sheet
          if (!mapViewModel.isMovingMap &&
              !mapViewModel.enteredInSelectingLocationMode &&
              sharedProvider.requestDriverOrDelivery &&
              sharedProvider.driverInformation == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: mapViewModel.animOfssetBS,
                child: const RequestDeliveryBottomSheet(),
              ),
            ),

          //WHEN DRIVER IS COMMING.
          if (sharedProvider.driverInformation != null)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DriverBottomCard(),
            ),

          // Overlay
          if (sharedProvider.deliveryLookingForDriver)
            const Positioned.fill(
              child: WitingForDriverOverlay(),
            ),
        ],
      ),
    );
  }
}
