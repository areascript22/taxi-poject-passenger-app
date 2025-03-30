import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/features/home/repositories/home_services.dart';
import 'package:passenger_app/shared/models/passenger_model.dart';
import 'package:location/location.dart' as lc;
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:passenger_app/shared/repositories/local_notification_service.dart';
import 'package:passenger_app/shared/repositories/push_notification_service.dart';

class HomeViewModel extends ChangeNotifier {
  final Logger logger = Logger();
  PassengerModel? passenger;
  lc.Location location = lc.Location();
  int _currentPageIndex = 0;
  late StreamSubscription<ServiceStatus> serviceStatusSubscription;
  bool _locationPermissionsSystemLevel = true; //Location services  System level
  bool _locationPermissionUserLevel = false; // Location services at User level
  bool _isCurrentLocationAvailable = false;
  bool _isThereInternetConnection = true;
  Position? currentPosition;
  final connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? connectivityListener;

  //Listeners
  StreamSubscription<Position>? positionStream;

  //GETTERS
  int get currentPageIndex => _currentPageIndex;
  bool get locationPermissionsSystemLevel => _locationPermissionsSystemLevel;
  bool get locationPermissionUserLevel => _locationPermissionUserLevel;
  bool get isCurrentLocationAvailable => _isCurrentLocationAvailable;
   bool get isThereInternetConnection => _isThereInternetConnection;

  //SETTERS
  set currentPageIndex(int value) {
    _currentPageIndex = value;
    notifyListeners();
  }

  set locationPermissionsSystemLevel(bool value) {
    _locationPermissionsSystemLevel = value;
    notifyListeners();
  }

  set locationPermissionUserLevel(bool value) {
    _locationPermissionUserLevel = value;
    notifyListeners();
  }

  set isCurrentLocationAvailable(bool value) {
    _isCurrentLocationAvailable = value;
    notifyListeners();
  }
   set isThereInternetConnection(bool value) {
    _isThereInternetConnection = value;
    notifyListeners();
  }


  //FUNCTIONS
  //set device token to send Push notification
  void initializeNotifications(SharedProvider sharedProvider) async {
    _setDeviceToken(sharedProvider);
    await LocalNotificationService.initiLocalNotifications();
  }

  void _setDeviceToken(SharedProvider sharedProvider) async {
    String? deviceToken = await PushNotificationService.getDeviceToken();
    //store it locally
    if (deviceToken != null) {
      sharedProvider.passenger!.deviceToken = deviceToken;
      //udpate the value in Firestore
      await HomeServices.updateDeviceToken(deviceToken);
    }
  }

  //get issue bassed on priority
   Map? getIssueBassedOnPriority() {
    if (!isThereInternetConnection) {
      return {
        "priority": 0,
        "color": const Color(0xFFD13C35),
        "title": "Sin conexión a internet",
        "content": "Conectate a internet para continuar",
      };
    }
    if (!locationPermissionUserLevel) {
      return {
        "priority": 1,
        "color": Colors.red,
        "title": "Permisos de ubicación desactivados.",
        "content": "Click aquí para activarlos",
      };
    }
    if (!locationPermissionsSystemLevel) {
      return {
        "priority": 2,
        "color": const Color(0xFFFFC13C),
        "title": "Servicio de ubicación desactivados.",
        "content": "Click aquí para activarlo.",
      };
    }
    if (!isCurrentLocationAvailable) {
      return {
        "priority": 3,
        "color": Colors.white70,
        "title": "Te estamos buscando en el mapa.",
        "content": "Sin señal GPS.",
      };
    }
    return null;
  }

//RETURN TRUE if there is any issue (internet conextion, gps signal, etc)
  bool isThereAnyIssue() {
    return (!locationPermissionUserLevel ||
        !locationPermissionsSystemLevel ||
        !isCurrentLocationAvailable ||
        !isThereInternetConnection);
  }

 //Check internet connection
  void listenToInternetConnection() {
    connectivityListener = connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> event) {
      if (event.isEmpty || event.contains(ConnectivityResult.none)) {
        isThereInternetConnection = false;
      } else {
        isThereInternetConnection = true;
        logger.f("THERE IS CONNECTION");
      }
    });
  }
  //Check GPS permissions
  Future<bool> checkGpsPermissions(SharedProvider sharedProvider) async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are disabled
      locationPermissionsSystemLevel = false;
      return false;
    }

    // Check the app's location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // App does not have location permissions
      locationPermissionUserLevel = false;
      return false;
    }

    // Location services are enabled and app has permissions
    locationPermissionUserLevel = true;
    //initialize listener
    _startLocationTracking(sharedProvider);
    _getCurrentLocation(sharedProvider);

    return true;
  }

  Future<bool> requestPermissionsAtUserLevel(
      SharedProvider sharedProvider) async {
    // Check the app's location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request location permissions
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions denied
        locationPermissionUserLevel = false;
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied, cannot request them
      try {
        await Geolocator.openAppSettings();
        // After opening settings, you can't recheck immediately
      } on PlatformException catch (e) {
        logger.i("Error opening app settings: $e");
        locationPermissionUserLevel = false;
        return false;
      }
      locationPermissionUserLevel = false;
      return false;
    }

    // If all checks pass, permissions are granted and location services are enabled
    locationPermissionUserLevel = true;
    _startLocationTracking(sharedProvider);
    _getCurrentLocation(sharedProvider);
    return true;
  }

  //Open Activate Lcoation Services Dialog
  Future<void> requestLocationServiceSystemLevel() async {
    bool serviceEnabled = await location.requestService();
    locationPermissionsSystemLevel = serviceEnabled;
  }

  /// Listens to changes in location service status
  void listenToLocationServicesAtSystemLevel() {
    serviceStatusSubscription =
        Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      locationPermissionsSystemLevel = (status == ServiceStatus.enabled);
    });
  }

  // Function to start tracking location changes
  void _startLocationTracking(SharedProvider sharedProvider) async {
    //clear listener
    positionStream?.cancel();
    // Listen for location updates
    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        //   distanceFilter: 1, // Minimum change (in meters) to trigger updates
      ),
    ).listen((Position position) async {
      // If location is available, update the flag to true
      isCurrentLocationAvailable = true;
      currentPosition = position;
      sharedProvider.passengerCurrentCoords =
          LatLng(position.latitude, position.longitude);
      //  logger.i("Location updated: ${position.latitude}, ${position.longitude}");
    }, onError: (error) {
      // If there is an error, update the flag to false

      isCurrentLocationAvailable = false;

      logger.e("Error getting location: $error");
    });
  }

  void _getCurrentLocation(SharedProvider sharedProvider) async {
    //Get last known position
    if (!isCurrentLocationAvailable) {
      Position? cPosition = await Geolocator.getLastKnownPosition();
      if (cPosition != null) {
        logger.f("Last known position Catched");
        sharedProvider.passengerCurrentCoords =
            LatLng(cPosition.latitude, cPosition.longitude);
        isCurrentLocationAvailable = true;
      }
    }

    try {
      // Get the current location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      currentPosition = position;
      isCurrentLocationAvailable = true;
      sharedProvider.passengerCurrentCoords =
          LatLng(position.latitude, position.longitude);
      logger.i("GEt currento location executed...");
      //Animate camera
    } catch (e) {
      isCurrentLocationAvailable = false;
      logger.e("Error tracking location: $e");
    }
  }

  //check Play integrity
  void checkPlayIntegrity() async {
    //String? token = await PlayIntegrityService.getIntegrityToken();
    // print('Play Integrity Token: $token');
  }
}
