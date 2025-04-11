import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/features/map/repositorie/map_services.dart';
import 'package:image/image.dart' as img;
import 'package:passenger_app/shared/providers/shared_provider.dart';

class MapViewModel extends ChangeNotifier {
  final String apiKey = Platform.isAndroid
      ? dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID'] ?? ''
      : dotenv.env['GOOGLE_MAPS_API_KEY_IOS'] ?? '';
  bool _loading = false; //For showing a circular spineer while async funcs
  final Logger logger = Logger();
  late AnimationController animController;
  late Animation<Offset> animOffsetDB; //Drawer Button
  late Animation<Offset> animOfssetBS; //BottomSheet
  Timer? timer;

  //MARKS AND POLYLINES
  double _mainIconSize = 30;
  bool _isMovingMap = false;
  // bool _isRouteDrawn = false;

  bool _enteredInSelectingLocationMode =
      false; //True i am selecting any location
  BitmapDescriptor? pickUpMarker;
  BitmapDescriptor? dropOffMarker;

  // Set<Polyline> _polylines = {};

  //SEARCH DIRECTIONS BOTTOM SHEET
  bool _searchingDirections = false;
  bool _isPickUpFocussed = false;
  bool _isDropOffFocussed = false;
  List<dynamic> listOfLcoationsPickUp = [];
  List<dynamic> listOfLcoationsDropOff = [];
  final pickUpTextController = TextEditingController();
  final dropOffTextController = TextEditingController();
  final FocusNode pickUpFocusNode = FocusNode();
  final FocusNode dropOffFocusNode = FocusNode();
  Timer? _debounce; // Timer for debouncing
  bool _readableAddressObtained = false;

  //GETTERS
  bool get loading => _loading;
  double get mainIconSize => _mainIconSize;
  bool get isMovingMap => _isMovingMap;
  // bool get isRouteDrawn => _isRouteDrawn;

  bool get enteredInSelectingLocationMode => _enteredInSelectingLocationMode;

  bool get searchingDirections => _searchingDirections;
  bool get isPickUpFocussed => _isPickUpFocussed;
  bool get isDropOffFocussed => _isDropOffFocussed;
  bool get readableAddressObtained => _readableAddressObtained;

  //SETTERS
  set loading(bool value) {
    _loading = value;
    notifyListeners();
  }

  set mainIconSize(double value) {
    _mainIconSize = value;
    notifyListeners();
  }

  set isMovingMap(bool value) {
    _isMovingMap = value;
    notifyListeners();
  }

  // set isRouteDrawn(bool value) {
  //   _isRouteDrawn = value;
  //   notifyListeners();
  // }

  set enteredInSelectingLocationMode(bool value) {
    _enteredInSelectingLocationMode = value;
    notifyListeners();
  }

  set searchingDirections(bool value) {
    _searchingDirections = value;
    notifyListeners();
  }

  set isPickUpFocussed(bool value) {
    _isPickUpFocussed = value;
    notifyListeners();
  }

  set isDropOffFocussed(bool value) {
    _isDropOffFocussed = value;
    notifyListeners();
  }

  set readableAddressObtained(bool value) {
    _readableAddressObtained = value;
    notifyListeners();
  }

  //FUNCTIONS

  //fit map
  void fitMapToTwoLatLngs({
    double padding = 200.0, // Optional padding around the markers
    required SharedProvider sharedProvider,
  }) async {
    if (sharedProvider.pickUpCoordenates == null ||
        sharedProvider.dropOffCoordenates == null) {
      return;
    }
    LatLng point1 = sharedProvider.pickUpCoordenates!;
    LatLng point2 = sharedProvider.dropOffCoordenates!;

    // Create LatLngBounds based on the two LatLng points
    LatLngBounds bounds;

    if (point1.latitude > point2.latitude &&
        point1.longitude > point2.longitude) {
      bounds = LatLngBounds(southwest: point2, northeast: point1);
    } else if (point1.latitude > point2.latitude) {
      bounds = LatLngBounds(
        southwest: LatLng(point2.latitude, point1.longitude),
        northeast: LatLng(point1.latitude, point2.longitude),
      );
    } else if (point1.longitude > point2.longitude) {
      bounds = LatLngBounds(
        southwest: LatLng(point1.latitude, point2.longitude),
        northeast: LatLng(point2.latitude, point1.longitude),
      );
    } else {
      bounds = LatLngBounds(southwest: point1, northeast: point2);
    }

    // Animate the camera to fit the bounds
    GoogleMapController controller = await sharedProvider.mapController.future;
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    );
  }

  /// Function to animate the camera to a given LatLng position.

  //Animate camera to current Position
  Future<void> animateCameraToCurrentPosition(
      SharedProvider sharedProvider) async {
    try {
      GoogleMapController controller =
          await sharedProvider.mapController.future;
      Position? locationToMove = await Geolocator.getLastKnownPosition();
      if (locationToMove == null) {
        locationToMove = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.low)
            .timeout(
          const Duration(seconds: 10),
        );
        logger.i('');
      }

      LatLng target = LatLng(locationToMove.latitude, locationToMove.longitude);

      await controller
          .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: target,
        zoom: 15,
        bearing: 0,
      )));
    } catch (e) {
      logger.e("Error trying to animate map camera: $e");
    }
  }

  //Get and navigate to current location
  void getCurrentLocationAndNavigate(SharedProvider sharedProvider) async {
    try {
      // Get the current location
      Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium)
          .timeout(const Duration(seconds: 7));
      sharedProvider.animateCameraToPosition(
        LatLng(position.latitude, position.longitude),
      );
      logger.i("GEt currento location executed...");
      //Animate camera
    } catch (e) {
      logger.e("Error tracking location: $e");
    }
  }

  //Initialize all necesary data
  Future<void> initializeAnimations(
      TickerProvider vsyn, SharedProvider sharedProvider) async {
    //Initialize animation controller
    animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsyn,
    );
    animOffsetDB = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -2),
    ).animate(
      CurvedAnimation(
        parent: animController,
        curve: Curves.easeInOut,
      ),
    );
    animOfssetBS = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 2),
    ).animate(
      CurvedAnimation(
        parent: animController,
        curve: Curves.easeInOut,
      ),
    );
    //Initialize Markers
    pickUpMarker =
        await convertImageToBitmapDescriptor('assets/img/location1.png');
    dropOffMarker =
        await convertImageToBitmapDescriptor('assets/img/location2.png');
    sharedProvider.driverIcon =
        await convertImageToBitmapDescriptor('assets/img/taxi.png');
  }

//Convert an image from asset into BitmapDescription
  Future<BitmapDescriptor?> convertImageToBitmapDescriptor(String path) async {
    try {
      final ByteData byteData = await rootBundle.load(path);
      final Uint8List bytes = byteData.buffer.asUint8List();
      img.Image originalImage = img.decodeImage(bytes)!;
      img.Image resizedImage =
          img.copyResize(originalImage, width: 100, height: 100);
      final Uint8List resizedBytes =
          Uint8List.fromList(img.encodePng(resizedImage));
      final BitmapDescriptor icon = BitmapDescriptor.fromBytes(resizedBytes);
      return icon;
    } catch (e) {
      return null;
    }
  }

//Hide BottomSheet
  void hideBottomSheet(SharedProvider sharedProvider) {
    animController.forward();
    mainIconSize = 50;
    isMovingMap = true;
    if (enteredInSelectingLocationMode ||
        sharedProvider.dropOffLocation == null) {
      logger.i("Hide bottom sheet func: ");
      if (sharedProvider.selectingPickUpOrDropOff) {
        sharedProvider.pickUpLocation = null;
      }
      if (!sharedProvider.selectingPickUpOrDropOff) {
        sharedProvider.dropOffLocation = null;
      }
    }
    readableAddressObtained = false;

    timer?.cancel();
  }

  //To show BootomSheet with delay
  Future<void> showBottomSheetWithDelay(SharedProvider sharedProvider) async {
    timer?.cancel();
    timer = Timer(
      const Duration(milliseconds: 500),
      () async {
        isMovingMap = false;
        animController.reverse();
        mainIconSize = 40;
        if (sharedProvider.pickUpCoordenates != null &&
            sharedProvider.driverModel == null) {
          sharedProvider.pickUpLocation = await MapServices.getReadableAddress(
            sharedProvider.pickUpCoordenates!.latitude,
            sharedProvider.pickUpCoordenates!.longitude,
            apiKey,
          );
          //Update sector
          sharedProvider.updateSector(sharedProvider.pickUpCoordenates);
        }
        if (sharedProvider.pickUpCoordenates != null) {
          addPickUpOrDropOffMarkerToMap(
              sharedProvider.pickUpCoordenates!, sharedProvider);
        }

        readableAddressObtained = true;
      },
    );
  }

  // Function to add a marker on map (CALLED BY: MapPage page and SelectDestination page)
  void addPickUpOrDropOffMarkerToMap(
      LatLng position, SharedProvider sharedProvider) {
    //clean markers
    if (sharedProvider.selectingPickUpOrDropOff) {
      sharedProvider.markers.removeWhere(
        (element) => element.markerId == const MarkerId("pick_up"),
      );
    } else {
      sharedProvider.markers.removeWhere(
        (element) => element.markerId == const MarkerId("drop_off"),
      );
    }
    //add marker
    sharedProvider.markers.add(
      Marker(
        markerId: MarkerId(
            sharedProvider.selectingPickUpOrDropOff ? "pick_up" : "drop_off"),
        position: position,
        infoWindow: const InfoWindow(
          title: 'Marker Title',
          snippet: 'Marker Snippet',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            sharedProvider.selectingPickUpOrDropOff
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueBlue),
      ),
    );
  }

  //Draw route

  //SEARCH DIRECTIONS BOTTOM SHEET
  //Get autocomplete direction
  Future<void> getAutocompletePlaces(String input) async {
    // Cancel the previous debounce if it exists
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Set a new debounce timer
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (input.isNotEmpty) {
        loading = true;

        // Call the API
        List<dynamic> response =
            await MapServices.getAutocompletePlaces(input, apiKey);

        // Update the appropriate list based on focus
        if (isPickUpFocussed) {
          listOfLcoationsPickUp = response;
        }
        if (isDropOffFocussed) {
          listOfLcoationsDropOff = response;
        }

        loading = false;
      }
    });
  }

  //Get Coordinates as LatLng by passing the Place id
  Future<void> getCoordinatesByPlaceId(String placeId, BuildContext context,
      SharedProvider sharedProvider) async {
    loading = true;
    LatLng? response =
        await MapServices.getCoordinatesByPlaceId(placeId, apiKey);
    if (response != null) {
      if (isPickUpFocussed) {
        sharedProvider.pickUpCoordenates = response;
        //Pending: Add a Marker to that point
        sharedProvider.pickUpLocation = pickUpTextController.text;
        addPickUpOrDropOffMarkerToMap(
            sharedProvider.pickUpCoordenates!, sharedProvider);
      }

      sharedProvider.animateCameraToPosition(response);
    }
    if (sharedProvider.pickUpCoordenates != null) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
    loading = false;
  }

  //Init text controllers listeners
  void initializeTextControllersLiteners(SharedProvider sharedProvider) {
    if (sharedProvider.pickUpLocation != null) {
      pickUpTextController.text = sharedProvider.pickUpLocation!;
    }
    if (sharedProvider.dropOffLocation != null) {
      dropOffTextController.text = sharedProvider.dropOffLocation!;
    }

    pickUpFocusNode.addListener(() {
      isPickUpFocussed = pickUpFocusNode.hasFocus;
      sharedProvider.selectingPickUpOrDropOff = true;
    });
    dropOffFocusNode.addListener(() {
      isDropOffFocussed = dropOffFocusNode.hasFocus;
      sharedProvider.selectingPickUpOrDropOff = false;
    });
    //FocusTextFields

    //Listener for Text editing controllers
    pickUpTextController.addListener(() {
      getAutocompletePlaces(pickUpTextController.text);
    });
    dropOffTextController.addListener(() {
      getAutocompletePlaces(dropOffTextController.text);
    });
  }

  //change map style
}
