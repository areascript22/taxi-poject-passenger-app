import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
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
import 'package:passenger_app/shared/repositories/shared_service.dart';
import 'package:passenger_app/shared/util/shared_util.dart';
import 'package:passenger_app/shared/widgets/loading_overlay.dart';

class RequestDriverViewModel extends ChangeNotifier {
  final service = FlutterBackgroundService();
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

  void checkIfThereIsTripInProgress(SharedProvider sharedProvider) async {
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
      sharedProvider.driverModel = driverModel.information;
      referenceToCancelRide =
          FirebaseDatabase.instance.ref('drivers/$driverId/passenger');
      sharedProvider.deliveryLookingForDriver = false;
      sharedUtil.playAudio("sounds/acepted_ride.mp3");
      _listenToDriverStatus(driverId, sharedProvider);
      _listenToDriverCoordenates(driverModel.information.id, sharedProvider);
      //SAVE TO DRIVER ID
      // await RequestDriverService.saveDriverIdTemporally(
      //     sharedProvider.passenger!.id!, driverId);
    } else {
      logger.f("Ther is not driver: ${event.snapshot.value}");
    }
  }

  //Request Driver
  // void requestTaxi(
  //   BuildContext context,
  //   SharedProvider sharedProvider,
  //   String requestType, {
  //   String? audioFilePath,
  //   String? indicationText,
  // }) async {
  //   //Display the overlay
  //   OverlayEntry? overlayEntry;
  //   final overlay = Overlay.of(context);
  //   overlayEntry = OverlayEntry(
  //     builder: (context) => const LoadingOverlay(),
  //   );
  //   overlay.insert(overlayEntry);
  //   //// CHECK IF I AM AUTHENTICATED
  //   User? user = FirebaseAuth.instance.currentUser;
  //   if (user == null) {
  //     logger.e("Error, user not authenticated");
  //     overlayEntry.remove();
  //     return;
  //   }
  //   //Define origin coords
  //   LatLng origin;
  //   if (requestType == RequestType.byCoordinates) {
  //     if (sharedProvider.pickUpCoordenates == null) {
  //       ToastMessageUtil.showToast(
  //           "Seleccióna tu ubicación antes de solicitar tu táxi");
  //       overlayEntry.remove();
  //       return;
  //     }
  //     origin = sharedProvider.pickUpCoordenates!;
  //   } else {
  //     if (sharedProvider.passengerCurrentCoords == null) {
  //       ToastMessageUtil.showToast(
  //           "Sin señal GPS, no podemos encontrarte en el mapa");
  //       overlayEntry.remove();
  //       return;
  //     }
  //     origin = sharedProvider.passengerCurrentCoords!;
  //   }

  //   //Chech if i am within the Radius for the Taxi Stand (2.5 km)
  //   double startLat = origin.latitude;
  //   double startLng = origin.longitude;
  //   double endLat = ConfigurationFile.taxiStandCoords.latitude;
  //   double endLng = ConfigurationFile.taxiStandCoords.longitude;
  //   double distanceResponse =
  //       _calculateDistance(startLat, startLng, endLat, endLng);
  //   String? driverAssignedId;
  //   if (distanceResponse <= 2500) {
  //     //TRY TO GET THE FIRST DRIVER FROM QUEUE
  //     logger.f("SEARCHING IN THE QUEUE");
  //     driverAssignedId =
  //         await RequestDriverService.claimAndGetOldestDriverKey();
  //   }
  //   //TRY TO GET THE NEAREST AVAILABLE DRIVER
  //   if (driverAssignedId == null || distanceResponse > 2500) {
  //     logger.f("SEARCHING NEARESTl: ${sharedProvider.passengerCurrentCoords}");
  //     if (sharedProvider.passengerCurrentCoords != null) {
  //       driverAssignedId =
  //           await _findNearestDriver(sharedProvider.passengerCurrentCoords!);
  //       logger.f("DRIVERASSIGNEDiD: ${driverAssignedId}");
  //     }
  //   }

  //   //
  //   DriverModel? driverInfo;
  //   bool passengerNodeUpdated = false;
  //   //WE FIND A DRIVER WHETER FROM QUUE OR THE  NEAREST ONE
  //   if (driverAssignedId != null) {
  //     driverInfo =
  //         await SharedService.getDriverInformationById(driverAssignedId);
  //     passengerNodeUpdated = await RequestDriverService.updatePassengerNode(
  //       driverAssignedId,
  //       driverInfo?.information.deviceToken,
  //       sharedProvider,
  //       requestType,
  //       'passenger',
  //       audioFilePath: audioFilePath,
  //       indicationText: indicationText,
  //     );
  //   }
  //   //THERE ARE NO AVAILABLE DRIVERS IN THE QUEUE OR IN THE MAP
  //   if (driverAssignedId == null) {
  //     await addDriverRequestToQueue(
  //       sharedProvider,
  //       requestType,
  //       audioFilePath: audioFilePath,
  //       indicationText: indicationText,
  //     );
  //   }

  //   //Move to Operation mode
  //   if (passengerNodeUpdated && driverInfo != null) {
  //     referenceToCancelRide =
  //         FirebaseDatabase.instance.ref('drivers/$driverAssignedId/passenger');
  //     sharedUtil.makePhoneVibrate();
  //     sharedProvider.driverModel = driverInfo.information;
  //     _listenToDriverStatus(driverInfo.information.id, sharedProvider);
  //     _listenToDriverCoordenates(driverInfo.information.id, sharedProvider);
  //   }
  //   //Remove overlay when it's all comleted
  //   overlayEntry.remove();
  // }

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
            "Seleccióna tu ubicación antes de solicitar tu táxi");
        overlayEntry.remove();
        return;
      }
      origin = sharedProvider.pickUpCoordenates!;
    } else {
      if (sharedProvider.passengerCurrentCoords == null) {
        ToastMessageUtil.showToast(
            "Sin señal GPS, no podemos encontrarte en el mapa");
        overlayEntry.remove();
        return;
      }
      origin = sharedProvider.passengerCurrentCoords!;
    }
    //ADD THIS RIDE AS PENDINDG RIDE.
    overlayEntry.remove();
    await addDriverRequestToQueue2(
      sharedProvider,
      requestType,
      audioFilePath: audioFilePath,
      indicationText: indicationText,
    );
  }

  //
  Future<void> addDriverRequestToQueue2(
    SharedProvider sharedProvider,
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
        requestType,
        audioFilePath: audioFilePath,
        indicationText: indicationText,
      );
    }
  }

  //LISTER: Listen to driver acceptance
  void listenToDriverAcceptance(
    SharedProvider sharedProvider,
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
          sharedProvider.driverModel = driverModel.information;
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
          sharedProvider.driverModel = driverModel.information;
          sharedUtil.playAudio("sounds/acepted_ride.mp3");
          _listenToDriverStatus(driverId, sharedProvider);
          _listenToDriverCoordenates(
              driverModel.information.id, sharedProvider);
          //SAVE TO DRIVER ID
          await RequestDriverService.saveDriverIdTemporally(
              sharedProvider.passenger!.id!, driverId);
        }
      }
    });
  }

  //Add driver requuest to queue: Only if There aren't vehicles available
  Future<void> addDriverRequestToQueue(
    SharedProvider sharedProvider,
    String requestType, {
    String? audioFilePath,
    String? indicationText,
  }) async {
    //Get current locatino adress
    String? currentLocation = await MapServices.getReadableAddress(
        sharedProvider.passengerCurrentCoords!.latitude,
        sharedProvider.passengerCurrentCoords!.longitude,
        apiKey);
    //Add driver request to the pending ride queue
    bool driverRequestSuccess =
        await RequestDriverService.addDriverRequestToQueue(
            sharedProvider, currentLocation ?? '');
    if (!driverRequestSuccess) {
      return;
    }
    sharedProvider.deliveryLookingForDriver = true;
    final databaseRef = FirebaseDatabase.instance
        .ref('driver_requests/${sharedProvider.passenger!.id}/driver');

    //start listener to check if a driver has accepted
    driverAcceptanceListener = databaseRef.onValue.listen((event) async {
      if (event.snapshot.exists) {
        String? driverId = event.snapshot.value as String?;
        if (driverId == null) {
          return;
        }
        sharedProvider.deliveryLookingForDriver = false;

        //CHECK IF DRIVER IS AVAILABLE OR IN PROGRESS
        bool passengerNodeUpdated = false;
        DriverModel? driverModel =
            await SharedService.getDriverInformationById(driverId);
        if (driverModel != null) {
          sharedProvider.driverModel = driverModel.information;
          if (driverModel.status == "reserved") {
            passengerNodeUpdated =
                await RequestDriverService.updatePassengerNode(
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

            _listenToDriverStatus(driverId, sharedProvider);
          } else {
            passengerNodeUpdated =
                await RequestDriverService.updatePassengerNode(
              driverId,
              driverModel.information.deviceToken,
              sharedProvider,
              requestType,
              'secondPassenger',
              audioFilePath: audioFilePath,
              indicationText: indicationText,
            );
            referenceToCancelRide = FirebaseDatabase.instance
                .ref('drivers/$driverId/secondPassenger');
          }
        }

        //Move to Operation mode
        if (passengerNodeUpdated && driverModel != null) {
          sharedProvider.driverModel = driverModel.information;
          _listenToPassengerIdChanges(
              driverId, sharedProvider.passenger!.id!, sharedProvider);
          _listenToDriverCoordenates(
              driverModel.information.id, sharedProvider);
        }
      }
    });
  }

  //Listen when Our request pass to be the Current ride
  void _listenToPassengerIdChanges(
      String driverId, String passengerId, SharedProvider sharedProvider) {
    final databaseRef = FirebaseDatabase.instance.ref();
    // Define the path to listen for passengerId changes
    final passengerIdPath =
        databaseRef.child('drivers/$driverId/passenger/$passengerId');
    passengerIdChangesListener =
        passengerIdPath.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        String passengerIdTemp = event.snapshot.value.toString();
        // Check if the passengerId matches "123456"
        if (passengerIdTemp == passengerId) {
          logger.f("Listen ID changes ");
          _listenToDriverStatus(driverId, sharedProvider);
        }
      }
    });
  }

  //get the nearest driver
  // Future<String?> _findNearestDriver(LatLng userLocation) async {
  //   final DatabaseReference driversRef =
  //       FirebaseDatabase.instance.ref('drivers');
  //   final drivers = await RequestDriverService.fetchAvailableDrivers();
  //   logger.f("FIND NEAREST: $drivers");
  //   if (drivers.isEmpty) return null;

  //   //Sort Drivers
  //   drivers.sort((a, b) {
  //     final double distanceA = _calculateDistance(
  //       userLocation.latitude,
  //       userLocation.longitude,
  //       a['latitude'],
  //       a['longitude'],
  //     );
  //     final double distanceB = _calculateDistance(
  //       userLocation.latitude,
  //       userLocation.longitude,
  //       b['latitude'],
  //       b['longitude'],
  //     );
  //     return distanceA.compareTo(distanceB);
  //   });
  //   // Map<String, dynamic>? nearestDriver;
  //   // double minDistance = double.infinity;

  //   for (final item in drivers) {
  //     final String driverId = item['driverID'];
  //     //Run transaction
  //     // Force a read to ensure data is loaded
  //     int retries = 3; // Max retry attempts
  //     while (retries > 0) {
  //       await Future.delayed(const Duration(milliseconds: 500));
  //       final TransactionResult transactionResult =
  //           await driversRef.child(driverId).runTransaction(
  //         (value) {
  //           if (value == null) {
  //             retries--;
  //             return Transaction.abort();
  //           }
  //           final Map<dynamic, dynamic> driverData = Map.from(value as Map);
  //           if (driverData['status_availability'] != 'pending_online') {
  //             return Transaction.abort();
  //           }
  //           driverData['status'] = "reserved";
  //           driverData['status_availability'] = "reserved_online";
  //           return Transaction.success(driverData);
  //         },
  //       );
  //       if (transactionResult.committed) {
  //         return driverId; // Return the claimed driver's ID
  //       }
  //     }
  //   }

  //   return null;
  // }

//HELPER: To calculate the distance between two coordinates
  // double _calculateDistance(
  //     double startLat, double startLng, double endLat, double endLng) {
  //   return Geolocator.distanceBetween(
  //       startLat, startLng, endLat, endLng); // Distance in meters
  // }

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
          RouteInfo? routeInfo = await SharedService.getRoutePolylinePoints(
              driverCoords, destination, apiKey);
          if (routeInfo == null) {
            return;
          }
          if (timefromTaxiToPickUp == null) {
            timefromTaxiToPickUp = routeInfo.duration;
            logger.d("Route Duration: ${routeInfo.duration}");
            sharedProvider.routeDuration =
                RequestDriverUtil.extractMinutes(routeInfo.duration);

            sharedProvider.fitMarkers(driverCoords, destination);
          }
          if (sharedProvider.driverModel != null) {
            sharedProvider.polylineFromPickUpToDropOff = Polyline(
              polylineId: const PolylineId("pickUpToDropoff"),
              points: routeInfo.polylinePoints,
              width: 5,
              color: Colors.blue,
            );
          }
        }
      });
    } catch (e) {
      logger.e('Error listening to driver coordinates: $e');
    }
  }

  //LISTENER: To listen every status of the driver
  void _listenToDriverStatus(
      String driverId, SharedProvider sharedProvider) async {
    //GEt our id
    final passengerId = FirebaseAuth.instance.currentUser?.uid;
    if (passengerId == null) {
      logger.e("User is not authenticated");
      return;
    }
    //Start foreground services
    // if (!(await service.isRunning())) {
    //   await service.startService();
    //   service.invoke('setAsForeground', {'driverId': driverId});
    // }
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
              //  sharedProvider.topMessage = 'En marcha, vamos!!';
              break;
            case DriverRideStatus.finished:
              await RequestDriverService.removeDriverIdTemporally(passengerId);
              sharedProvider.driverStatus = DriverRideStatus.finished;
              _finishState(sharedProvider);

              break;
            case DriverRideStatus.canceled:
              sharedUtil.stopAudioLoop();
              await RequestDriverService.removeDriverIdTemporally(passengerId);
              sharedProvider.driverStatus = DriverRideStatus.canceled;
              cancelDriverListeners();
              //Return to normal state of the appp

              timefromTaxiToPickUp = null;

              sharedProvider.driverModel = null;
              sharedProvider.pickUpCoordenates = null;
              sharedProvider.pickUpLocation = null;
              sharedProvider.routeDuration = null;
              sharedProvider.markers.clear();
              sharedProvider.polylineFromPickUpToDropOff =
                  const Polyline(polylineId: PolylineId("default"));
              ToastMessageUtil.showToast("El viaje ha sido cancelado");
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
    if (sharedProvider.driverModel != null) {
      showStarRatingsBottomSheet(
        sharedProvider.mapPageContext!,
        sharedProvider.driverModel!.id,
      );
    }

    //Return to normal state of the appp
    sharedProvider.driverModel = null;
    sharedProvider.pickUpCoordenates = null;
    sharedProvider.pickUpLocation = null;
    sharedProvider.routeDuration = null;
    sharedProvider.markers.clear();
    sharedProvider.polylineFromPickUpToDropOff = const Polyline(
      polylineId: PolylineId("default"),
      points: [],
    );
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
