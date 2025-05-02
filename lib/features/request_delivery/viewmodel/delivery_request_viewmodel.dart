import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/core/utils/toast_message_util.dart';
import 'package:passenger_app/features/request_delivery/model/delivery_details_model.dart';
import 'package:passenger_app/features/request_delivery/repositorie/request_delivery_service.dart';
import 'package:passenger_app/features/request_delivery/view/widgets/delivery_arrived_bottom_sheet.dart';
import 'package:passenger_app/features/request_delivery/view/widgets/driver_has_package_bottom_sheet.dart';
import 'package:passenger_app/features/request_driver/view/widgets/star_ratings_bottom_sheet.dart';
import 'package:passenger_app/shared/models/driver_model.dart';
import 'package:passenger_app/shared/models/request_type.dart';
import 'package:passenger_app/shared/models/route_info.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:passenger_app/shared/repositories/shared_service.dart';
import 'package:passenger_app/shared/util/shared_util.dart';
import 'package:passenger_app/shared/widgets/loading_overlay.dart';

class DeliveryRequestViewModel extends ChangeNotifier {
  final String apiKey = Platform.isAndroid
      ? dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID'] ?? ''
      : dotenv.env['GOOGLE_MAPS_API_KEY_IOS'] ?? '';
  final logger = Logger();
  final sharedUtil = SharedUtil();
  bool _loading = false;
  DeliveryDetailsModel? _deliveryDetailsModel;
  String requestTypeTemp = RequestType.byCoordinates; //Value by default

  //Listeners
  StreamSubscription<DatabaseEvent>? driverStatusListener;
  StreamSubscription<DatabaseEvent>? driverAcceptanceListener;
  StreamSubscription<DatabaseEvent>? driverPositionListener;
  //textr controller
  final deliveryTextController = TextEditingController();
  String? audioFilePath;
  //GETTERS
  bool get loading => _loading;
  DeliveryDetailsModel? get deliveryDetailsModel => _deliveryDetailsModel;

  // SETTERS
  set loading(bool value) {
    _loading = value;
    notifyListeners();
  }

  set deliveryDetailsModel(DeliveryDetailsModel? value) {
    _deliveryDetailsModel = value;
    notifyListeners();
  }

  //FUNCTIONS
  void clearListeners() {
    logger.e("Removing Listeners...");
    driverStatusListener?.cancel();
    driverAcceptanceListener?.cancel();
    driverPositionListener?.cancel();
  }

  // Function to call the static method to write data to Firebase
  Future<void> writeDeliveryRequest(
    BuildContext context,
    SharedProvider sharedProvider,
    String requestType, {
    String? audioFilePath,
    String? indicationText,
  }) async {
    final overlay = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => const LoadingOverlay(),
    );
    overlay.insert(overlayEntry);
    // Create a DeliveryDetailsModel instance
    requestTypeTemp = requestType;
    try {
      loading = true;
      //get Passenger id
      String passengerId = FirebaseAuth.instance.currentUser!.uid;
      bool dataWritten = await RequestDeliveryService.writeToDatabase(
        requestType: requestType,
        passengerId: passengerId,
        deliveryDetails: deliveryDetailsModel,
        passengerModel: sharedProvider.passenger!,
        sharedProvider: sharedProvider,
        audioFilePath: audioFilePath,
        indicationText: indicationText,
      );
      //Start Listener
      if (dataWritten && context.mounted) {
        _listenToDriverAcceptance(passengerId, sharedProvider, context);
        sharedProvider.deliveryLookingForDriver = true;
      }
      loading = false;
    } catch (e) {
      logger.e("Error while writter delivery erquest: $e");
    }
    overlayEntry.remove();
  }

  //LISTENER: To listen when a driver accept our delivery request
  void _listenToDriverAcceptance(
      String passengerId, SharedProvider sharedProvider, BuildContext context) {
    final databaseRef =
        FirebaseDatabase.instance.ref('delivery_requests/$passengerId/driver');

    try {
      driverAcceptanceListener =
          databaseRef.onValue.listen((DatabaseEvent event) async {
        // Check if the snapshot has data
        if (event.snapshot.exists) {
          sharedUtil.makePhoneVibrate();
          //Fetch driver
          final driverMap = event.snapshot.value as Map;
          //Get key and body
          String? driverId;
          DriverInformation? driver;
          if (driverMap.isNotEmpty) {
            driverId = driverMap.keys.first.toString();
          }
          if (driverId == null) {
            logger.e("Driver not found..");
            return;
          }
          sharedProvider.deliveryLookingForDriver = false;
          //Get the driver data
          final driverModel =
              await SharedService.getDriverInformationById(driverId);
          driver = driverModel?.information;

          sharedProvider.driverInformation = driver;

          //Start Driver Location Listener
          _listenToDriverCoordenates(passengerId, driverId, sharedProvider);
          //Start Delivery Request Status Listener
          _listenToDeliveryRequestStatus(passengerId, sharedProvider, context);
          logger.i(
              "Driver retrieved succesfully: ${sharedProvider.driverInformation}");
        } else {
          logger.i('There is no drivers ');
        }
      });
    } catch (e) {
      logger.e('Error listening to driver status: $e');
    }
  }

  //LISTENER: To listen every status of the driver
  void _listenToDeliveryRequestStatus(
      String passengerId, SharedProvider sharedProvider, BuildContext context) {
    final Logger logger = Logger();
    final databaseRef =
        FirebaseDatabase.instance.ref('delivery_requests/$passengerId/status');
    logger.f("Starting listener at: $passengerId");

    try {
      driverStatusListener =
          databaseRef.onValue.listen((DatabaseEvent event) async {
        // Check if the snapshot has data
        if (event.snapshot.exists) {
          // Get the status value
          final status = event.snapshot.value as String;
          logger.e("Status changed to: $status");
          switch (status) {
            case DeliveryStatus.goingForThePackage:
              //Fit markers
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

              break;
            case DeliveryStatus.haveThePackage:
              sharedProvider.deliveryStatus = DeliveryStatus.haveThePackage;
              if (sharedProvider.mapPageContext != null) {
                showDriverHasPackageBotttomSheet(
                    sharedProvider.mapPageContext!);
              }
              break;
            case DeliveryStatus.arrivedToTheDeliveryPoint:
              sharedProvider.deliveryStatus =
                  DeliveryStatus.arrivedToTheDeliveryPoint;
              if (sharedProvider.mapPageContext != null) {
                showDeliveryArrivedBottomSheet(sharedProvider.mapPageContext!);
              }
              await sharedUtil.repeatAudio("sounds/pending_delivery.mp3");
              break;
            case DeliveryStatus.passengerHasThePakcage:
              sharedProvider.deliveryStatus =
                  DeliveryStatus.passengerHasThePakcage;
              sharedUtil.stopAudioLoop();
              break;
            case DeliveryStatus.finished:
              sharedProvider.deliveryStatus = DeliveryStatus.finished;
              //Rate the driver
              if (sharedProvider.driverInformation != null) {
                showStarRatingsBottomSheet(sharedProvider.mapPageContext!,
                    sharedProvider.driverInformation!.id);
              }
              //Return to normal state of the appp
              sharedProvider.driverInformation = null;
              sharedProvider.dropOffCoordenates = null;
              sharedProvider.dropOffLocation = null;
              sharedProvider.pickUpCoordenates = null;
              sharedProvider.pickUpLocation = null;
              sharedProvider.selectingPickUpOrDropOff = true;
              //  sharedProvider.duration = null;
              sharedProvider.markers.clear();
              sharedProvider.polylineFromPickUpToDropOff =
                  const Polyline(polylineId: PolylineId("default"));
              clearListeners();
              if (sharedProvider.passengerCurrentCoords != null) {
                sharedProvider.animateCameraToPosition(
                    sharedProvider.passengerCurrentCoords!);
              }

              break;
            case DeliveryStatus.canceled:
              //Return to normal state of the appp
              sharedProvider.driverInformation = null;
              sharedProvider.dropOffCoordenates = null;
              sharedProvider.dropOffLocation = null;
              sharedProvider.pickUpCoordenates = null;
              sharedProvider.pickUpLocation = null;
              sharedProvider.selectingPickUpOrDropOff = true;
              // sharedProvider.duration = null;
              sharedProvider.markers.clear();
              sharedProvider.polylineFromPickUpToDropOff =
                  const Polyline(polylineId: PolylineId("default"));
              clearListeners();
              ToastMessageUtil.showToast(
                  "La encomienda fue cancelada.", context);
              if (sharedProvider.passengerCurrentCoords != null) {
                sharedProvider.animateCameraToPosition(
                    sharedProvider.passengerCurrentCoords!);
              }

              break;
            default:
              logger.e("Driver Status not found..");
              break;
          }
        } else {
          logger.i('Driver $passengerId status does not exist.');
        }
      });
    } catch (e) {
      logger.e('Error listening to driver status: $e');
    }
  }

  //Update delivery status
  Future<void> updatedeliveryStatus(String status, BuildContext context) async {
    final overlay = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => const LoadingOverlay(),
    );
    overlay.insert(overlayEntry);

    final passengerId = FirebaseAuth.instance.currentUser?.uid;
    if (passengerId == null) {
      logger.e("User is not authenticated");
      return;
    }
    await RequestDeliveryService.updateDeliveryStatus(passengerId, status);
    overlayEntry.remove();
  }

  //LISTENER: To track driver location in real time
  void _listenToDriverCoordenates(
      String passengerId, String driverId, SharedProvider sharedProvider) {
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
          sharedProvider.driverCurrentCoordenates = driverCoords;

          //Update Driver marker
          sharedProvider.driverMarker = Marker(
              markerId: const MarkerId("marker_id"),
              icon: sharedProvider.driverIcon ?? BitmapDescriptor.defaultMarker,
              position: driverCoords);
          //Update Polyline (Route from Driver to a dynamic destination)
          LatLng destination;
          if (requestTypeTemp == RequestType.byCoordinates) {
            if (sharedProvider.pickUpCoordenates == null) {
              return;
            }
            destination = sharedProvider.pickUpCoordenates!;
          } else {
            if (sharedProvider.passengerCurrentCoords == null) {
              return;
            }
            destination = sharedProvider.passengerCurrentCoords!;
          }

          RouteInfo? routeInfo = await SharedService.getRoutePolylinePoints(
              driverCoords, destination, apiKey);

          if (routeInfo != null) {
            // if (sharedProvider.routeDuration != null) {
            //   sharedProvider.routeDuration =
            //       SharedHelpers.extractMinutes(routeInfo.duration);
            // }
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
}
