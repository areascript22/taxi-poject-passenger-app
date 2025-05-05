import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'package:logger/web.dart';
import 'package:passenger_app/core/utils/toast_message_util.dart';
import 'package:passenger_app/features/map/repositorie/map_services.dart';
import 'package:passenger_app/features/request_driver/repositorie/request_driver_service.dart';
import 'package:passenger_app/features/request_driver/utils/request_driver_util.dart';
import 'package:passenger_app/features/request_driver/view/widgets/driver_arrived_bottom_sheet.dart';
import 'package:passenger_app/features/request_driver/view/widgets/star_ratings_bottom_sheet.dart';
import 'package:passenger_app/shared/models/driver_model.dart';
import 'package:passenger_app/shared/models/request_type.dart';
import 'package:passenger_app/shared/models/route_info.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:passenger_app/shared/repositories/push_notification_service.dart';
import 'package:passenger_app/shared/repositories/shared_service.dart';
import 'package:passenger_app/shared/util/shared_util.dart';
import 'package:passenger_app/shared/widgets/loading_overlay.dart';

class RequestDriverViewModel extends ChangeNotifier {
  final Logger logger = Logger();
  final String apiKey = Platform.isAndroid
      ? dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID'] ?? ''
      : dotenv.env['GOOGLE_MAPS_API_KEY_IOS'] ?? '';
  final SharedUtil sharedUtil = SharedUtil();
  String? _timefromTaxiToPickUp;
  LatLng? driverCurrenTCoords;
  DatabaseReference? referenceToCancelRide;

  //listeners
  StreamSubscription<DatabaseEvent>? driverStatusListener;
  StreamSubscription<DatabaseEvent>? driverPositionListener;
  StreamSubscription<DatabaseEvent>? passengerIdChangesListener;
  StreamSubscription<DatabaseEvent>? driverAcceptanceListener;
  DatabaseReference? savedDriverRef;
  //Request by audio and text
  final requestByTextController = TextEditingController();

  String? audioFilePath;

  //GETTERS
  String? get timefromTaxiToPickUp => _timefromTaxiToPickUp;
  //SETTERS
  set timefromTaxiToPickUp(String? value) {
    _timefromTaxiToPickUp = value;
    notifyListeners();
  }

  //Cancel listeners
  void cancelDriverListeners() {
    driverStatusListener?.cancel();
    driverPositionListener?.cancel();
    passengerIdChangesListener?.cancel();
    driverAcceptanceListener?.cancel();
  }

  void checkIfThereIsTripInProgress(
      SharedProvider sharedProvider, BuildContext context) async {
    final passengerId = FirebaseAuth.instance.currentUser?.uid;
    if (passengerId == null) {
      logger.e("User is not authenticated yet");
      return;
    }
    if (savedDriverRef != null) {
      logger.f("Ref already used");
      return;
    }
    savedDriverRef =
        FirebaseDatabase.instance.ref("trip_progress/$passengerId");
    DatabaseEvent event = await savedDriverRef!.once();
    if (event.snapshot.value != null) {
      final driverId = event.snapshot.value as String;
      logger.e("Current Driver: $driverId");
      DriverModel? driverModel =
          await SharedService.getDriverInformationById(driverId);
      logger.e("Current Driver: $driverModel");
      if (driverModel == null) {
        return;
      }
      sharedProvider.driverInformation = driverModel.information;
      referenceToCancelRide =
          FirebaseDatabase.instance.ref('drivers/$driverId/passenger');
      sharedProvider.deliveryLookingForDriver = false;
      sharedUtil.playAudio("sounds/acepted_ride.mp3");
      if (context.mounted) {
        _listenToDriverStatus(driverId, sharedProvider, context);
      }
      _listenToDriverCoordenates(driverModel.information.id, sharedProvider);
    } else {
      logger.f("Ther is not driver: ${event.snapshot.value}");
    }
  }

//Request Driver
  void requestTaxi2(
    BuildContext context,
    SharedProvider sharedProvider,
    String requestType, {
    String? audioFilePath,
    String? indicationText,
  }) async {
    //Display the overlay
    OverlayEntry? overlayEntry;
    final overlay = Overlay.of(context);
    overlayEntry = OverlayEntry(
      builder: (context) => const LoadingOverlay(),
    );
    overlay.insert(overlayEntry);
    //// CHECK IF I AM AUTHENTICATED
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      logger.e("Error, user not authenticated");
      overlayEntry.remove();
      return;
    }
    //Define origin coords
    LatLng origin;
    if (requestType == RequestType.byCoordinates) {
      if (sharedProvider.pickUpCoordenates == null) {
        ToastMessageUtil.showToast(
            "Seleccióna tu ubicación antes de solicitar tu táxi", context);
        overlayEntry.remove();
        return;
      }
      origin = sharedProvider.pickUpCoordenates!;
    } else {
      if (sharedProvider.passengerCurrentCoords == null) {
        ToastMessageUtil.showToast(
            "Sin señal GPS, no podemos encontrarte en el mapa", context);
        overlayEntry.remove();
        return;
      }
      origin = sharedProvider.passengerCurrentCoords!;
    }
    //ADD THIS RIDE AS PENDINDG RIDE.
    overlayEntry.remove();
    await addDriverRequestToQueue2(
      sharedProvider,
      context,
      requestType,
      audioFilePath: audioFilePath,
      indicationText: indicationText,
    );
  }

  //
  Future<void> addDriverRequestToQueue2(
    SharedProvider sharedProvider,
    BuildContext context,
    String requestType, {
    String? audioFilePath,
    String? indicationText,
  }) async {
    sharedProvider.deliveryLookingForDriver = true;
    //Get current locatino adress
    String? currentLocation = await MapServices.getReadableAddress(
        sharedProvider.passengerCurrentCoords!.latitude,
        sharedProvider.passengerCurrentCoords!.longitude,
        apiKey);
    //Define sector
    if (sharedProvider.requestType != RequestType.byCoordinates) {
      sharedProvider.updateSector(sharedProvider.passengerCurrentCoords);
    }

    //Add driver request to the pending ride queue
    bool driverRequestSuccess =
        await RequestDriverService.addDriverRequestToQueue(
            sharedProvider, currentLocation ?? '');
    if (driverRequestSuccess) {
      listenToDriverAcceptance(
        sharedProvider,
        context,
        requestType,
        audioFilePath: audioFilePath,
        indicationText: indicationText,
      );
    }
  }

  //LISTER: Listen to driver acceptance
  void listenToDriverAcceptance(
    SharedProvider sharedProvider,
    BuildContext context,
    String requestType, {
    String? audioFilePath,
    String? indicationText,
  }) {
    final databaseRef = FirebaseDatabase.instance
        .ref('driver_requests/${sharedProvider.passenger!.id}/driver');

    //LISTEN TO DRIVER ACCEPTANCE
    driverAcceptanceListener?.cancel();
    driverAcceptanceListener = databaseRef.onValue.listen((event) async {
      if (event.snapshot.exists) {
        //get driver info
        String? driverId = event.snapshot.value as String?;
        if (driverId == null) {
          return;
        }
        bool passengerNodeUpdated = false;
        DriverModel? driverModel =
            await SharedService.getDriverInformationById(driverId);
        if (driverModel != null) {
          sharedProvider.driverInformation = driverModel.information;
          passengerNodeUpdated = await RequestDriverService.updatePassengerNode(
            driverId,
            driverModel.information.deviceToken,
            sharedProvider,
            requestType,
            'passenger',
            audioFilePath: audioFilePath,
            indicationText: indicationText,
          );
          referenceToCancelRide =
              FirebaseDatabase.instance.ref('drivers/$driverId/passenger');
        }
        //Move to Operation mode
        if (passengerNodeUpdated && driverModel != null) {
          sharedProvider.deliveryLookingForDriver = false;
          sharedProvider.driverInformation = driverModel.information;
          sharedUtil.playAudio("sounds/acepted_ride.mp3");
          _listenToDriverStatus(driverId, sharedProvider, context);
          _listenToDriverCoordenates(
              driverModel.information.id, sharedProvider);
          //SAVE TO DRIVER ID
          await RequestDriverService.saveDriverIdTemporally(
              sharedProvider.passenger!.id!, driverId);
        }
      }
    });
  }

  //LISTENER: To update TaxiMarker based on driver coordinates
  void _listenToDriverCoordenates(
      String driverId, SharedProvider sharedProvider) {
    Logger logger = Logger();
    final databaseRef =
        FirebaseDatabase.instance.ref('drivers/$driverId/location');

    try {
      driverPositionListener = databaseRef.onValue.listen((event) async {
        //Check if there is any data
        if (event.snapshot.exists) {
          //get coordinates
          final coords = event.snapshot.value as Map;
          final LatLng driverCoords = LatLng(
              coords['latitude'].toDouble(), coords['longitude'].toDouble());
          driverCurrenTCoords = driverCoords;
          sharedProvider.driverCurrentCoordenates = driverCoords;
          //Update Driver marker
          sharedProvider.driverMarker = Marker(
              markerId: const MarkerId("marker_id"),
              icon: sharedProvider.driverIcon ?? BitmapDescriptor.defaultMarker,
              position: driverCoords);
          //Check if it is necesary to draw route

          //Update Polyline (Route from Driver to pick up point)
          LatLng destination;
          if (sharedProvider.requestType == RequestType.byCoordinates) {
            if (sharedProvider.pickUpCoordenates == null) {
              logger.e('pick up is null ${sharedProvider.pickUpCoordenates}');
              return;
            }
            destination = sharedProvider.pickUpCoordenates!;
          } else {
            if (sharedProvider.passengerCurrentCoords == null) {
              logger.e('Current ${sharedProvider.passengerCurrentCoords}');
              return;
            }
            destination = sharedProvider.passengerCurrentCoords!;
          }
          //Clean route
          if (sharedProvider.polylineFromPickUpToDropOff.points.isNotEmpty) {
            sharedProvider.clearPolylinePickUpToDropOff();
          }
          //Add Time duraion and First Route
          if (timefromTaxiToPickUp == null) {
            RouteInfo? routeInfo;
            routeInfo = await SharedService.getRoutePolylinePoints(
                driverCoords, destination, apiKey);
            if (routeInfo == null) return;
            //Add Duration
            timefromTaxiToPickUp = routeInfo.duration;
            sharedProvider.routeDuration =
                RequestDriverUtil.extractMinutes(routeInfo.duration);
            sharedProvider.fitMarkers(driverCoords, destination);
            //Add first route
            if (sharedProvider.driverInformation != null) {
              sharedProvider.polylineFromPickUpToDropOff = Polyline(
                polylineId: const PolylineId("pickUpToDropoff"),
                points: routeInfo.polylinePoints,
                width: 5,
                color: Colors.blue,
              );
            }
          }
        }
      });
    } catch (e) {
      logger.e('Error listening to driver coordinates: $e');
    }
  }

  //LISTENER: To listen every status of the driver
  void _listenToDriverStatus(String driverId, SharedProvider sharedProvider,
      BuildContext context) async {
    //GEt our id
    final passengerId = FirebaseAuth.instance.currentUser?.uid;
    if (passengerId == null) {
      logger.e("User is not authenticated");
      return;
    }
    //start listener
    final databaseRef =
        FirebaseDatabase.instance.ref('drivers/$driverId/status');

    try {
      driverStatusListener =
          databaseRef.onValue.listen((DatabaseEvent event) async {
        // Check if the snapshot has data
        if (event.snapshot.exists) {
          // Get the status value
          final status = event.snapshot.value as String;
          switch (status) {
            case DriverRideStatus.goingToPickUp:
              sharedProvider.driverStatus = DriverRideStatus.goingToPickUp;

              break;
            case DriverRideStatus.arrived:
              sharedProvider.driverStatus = DriverRideStatus.arrived;
              //Show Bottom Sheet
              if (sharedProvider.mapPageContext != null) {
                showDriverArrivedBotttomSheet(sharedProvider.mapPageContext!);
              }
              //   await sharedUtil.playAudio("sounds/taxi_espera.mp3");
              await sharedUtil.repeatAudio("sounds/taxi_espera.mp3");
              break;
            case DriverRideStatus.goingToDropOff:
              sharedProvider.driverStatus = DriverRideStatus.goingToDropOff;
              sharedProvider.routeDuration = null;
              sharedUtil.stopAudioLoop();
              sharedProvider.clearPolylinePickUpToDropOff();
              //  sharedProvider.topMessage = 'En marcha, vamos!!';
              break;
            case DriverRideStatus.finished:
              await RequestDriverService.removeDriverIdTemporally(passengerId);
              sharedProvider.driverStatus = DriverRideStatus.finished;
              _finishState(sharedProvider);

              break;
            case DriverRideStatus.canceled:
              sharedUtil.stopAudioLoop();
              cancelDriverListeners();
              await RequestDriverService.removeDriverIdTemporally(passengerId);
              sharedProvider.driverStatus = DriverRideStatus.canceled;
              timefromTaxiToPickUp = null;

              sharedProvider.pickUpCoordenates = null;
              sharedProvider.pickUpLocation = null;
              sharedProvider.routeDuration = null;
              sharedProvider.markers.clear();
              sharedProvider.clearPolylinePickUpToDropOff();
              //Show Toast Message
              if (context.mounted) {
                ToastMessageUtil.showToast(
                    "El viaje ha sido cancelado", context);
              }
              //Animate camerar to currento position
              if (sharedProvider.passengerCurrentCoords != null) {
                sharedProvider.animateCameraToPosition(
                    sharedProvider.passengerCurrentCoords!);
              }
              //Send push notification to the driver
              final driver = sharedProvider.passenger;
              final deviceToken = sharedProvider.driverInformation?.deviceToken;
              if (deviceToken != null) {
                await PushNotificationService.sendPushNotification(
                  deviceToken: deviceToken,
                  title: '❌CANCELADO',
                  body: '${driver?.name ?? 'Se'} ha cancelado la carrera',
                );
              }
              sharedProvider.driverInformation = null;

              break;
            default:
              logger.e("Driver Status not found..");
              break;
          }
        } else {
          logger.i('Driver $driverId status does not exist.');
        }
      });
    } catch (e) {
      logger.e('Error listening to driver status: $e');
    }
  }

  void _finishState(SharedProvider sharedProvider) async {
    //  driverPositionListener?.cancel();
    //Rate the driver
    timefromTaxiToPickUp = null;
    if (sharedProvider.driverInformation != null) {
      showStarRatingsBottomSheet(
        sharedProvider.mapPageContext!,
        sharedProvider.driverInformation!.id,
      );
    }

    //Return to normal state of the appp
    sharedProvider.driverInformation = null;
    sharedProvider.pickUpCoordenates = null;
    sharedProvider.pickUpLocation = null;
    sharedProvider.routeDuration = null;
    sharedProvider.markers.clear();
    sharedProvider.clearPolylinePickUpToDropOff();
    if (sharedProvider.passengerCurrentCoords != null) {
      await sharedProvider
          .animateCameraToPosition(sharedProvider.passengerCurrentCoords!);
    }
    cancelDriverListeners();
  }

  //CALLED BY DriverArrivedBottomSheet widget
  Future<void> updateDriverStatus(
      String driverId, String status, BuildContext context) async {
    final overlay = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => const LoadingOverlay(),
    );
    overlay.insert(overlayEntry);
    //Update Driver Status
    await RequestDriverService.updateDriverStatus(driverId, status);
    //Remove overlay when it's all comleted
    overlayEntry.remove();
  }

  void updateDriverStarRatings(double newRating, String driverId,
      BuildContext context, String comment) async {
    final overlay = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => const LoadingOverlay(),
    );
    overlay.insert(overlayEntry);
    //Update star
    final passengerId = FirebaseAuth.instance.currentUser?.uid;
    if (passengerId != null) {
      await RequestDriverService.updateDriverStarRatings(
        newRating,
        driverId,
        comment,
        passengerId,
      );
    } else {
      logger.e("Error, usuario no autenticado");
    }

    overlayEntry.remove();
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  //Upload recorded audio to Firestore Storage
  Future<String?> uploadRecordedAudioToStorage(
      String audioFilePath, BuildContext context) async {
    final overlay = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => const LoadingOverlay(),
    );
    overlay.insert(overlayEntry);
    ////
    final passengerId = FirebaseAuth.instance.currentUser?.uid;
    if (passengerId == null) {
      logger.e("Error: Passenger is not authenticated.");
      return null;
    }
    String? response =
        await SharedService.uploadAudioToFirebase(audioFilePath, passengerId);
    overlayEntry.remove();
    return response;
  }

//  Cancel ride
  Future<void> cancelRide(String driverId, BuildContext context) async {
    final overlay = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => const LoadingOverlay(),
    );
    overlay.insert(overlayEntry);
    // Check wheter i am the second or the main passenger
    if (referenceToCancelRide?.path == 'drivers/$driverId/passenger') {
      logger.f("Yes it is equals");
      await updateDriverStatus(
        driverId,
        DriverRideStatus.canceled,
        context,
      );
    } else if (referenceToCancelRide?.path ==
        'drivers/$driverId/secondPassenger') {
      await RequestDriverService.updateSecondPassengerStatus(
          driverId, DriverRideStatus.canceled);
    }
    overlayEntry.remove();
  }
}
