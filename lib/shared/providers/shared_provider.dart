import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:passenger_app/shared/models/driver_model.dart';
import 'package:passenger_app/shared/models/g_user.dart';
import 'package:passenger_app/shared/models/request_type.dart';
import 'package:passenger_app/shared/repositories/shared_service.dart';

class SharedProvider extends ChangeNotifier {
  final Logger logger = Logger();
  final String apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  BuildContext? mapPageContext;
  //Passenger data
  GUser? passenger;
  //Driver data
  DriverInformation? _driverInformation;
  String _driverStatus = ''; //To Track ride status
  String _deliveryStatus = ''; //To track delivery status
  LatLng? driverCurrentCoordenates;
  LatLng? passengerCurrentCoords;
  BitmapDescriptor? driverIcon;
  Marker _driverMarker = const Marker(markerId: MarkerId("taxi_marker"));
  Set<Polygon> _polygons = {};
  Completer<GoogleMapController> mapController = Completer();
  String? sector; //SECTOR of pick up point
  String version = '';

  //
  String? _pickUpLocation;
  String? _dropOffLocation;
  LatLng? _pickUpCoordenates;
  LatLng? _dropOffCoordenates;
  Polyline _polylineFromPickUpToDropOff =
      const Polyline(polylineId: PolylineId("default"));
  Set<Marker> _markers = {};

  bool _requestDriverOrDelivery = false; //False= driver, True:Delivery
  bool _selectingPickUpOrDropOff =
      true; //True:selectin pick up location, else DropOff
  bool _deliveryLookingForDriver = false;
  String _requestType = RequestType.byCoordinates;
  int? _routeDuration; //For the CountDown timer

  //CONSTRUCTOR
  SharedProvider() {
    _loadVersion();
  }

  //GETTERS
  DriverInformation? get driverInformation => _driverInformation;
  String get driverStatus => _driverStatus;
  String get deliveryStatus => _deliveryStatus;

  // LatLng? get driverCurrentCoordenates => _driverCurrentCoordenates;
  String? get pickUpLocation => _pickUpLocation;
  String? get dropOffLocation => _dropOffLocation;
  LatLng? get pickUpCoordenates => _pickUpCoordenates;
  LatLng? get dropOffCoordenates => _dropOffCoordenates;
  Polyline get polylineFromPickUpToDropOff => _polylineFromPickUpToDropOff;
  Set<Marker> get markers => _markers;
  Set<Polygon> get polygons => _polygons;

  Marker get driverMarker => _driverMarker;

  bool get requestDriverOrDelivery => _requestDriverOrDelivery;
  bool get selectingPickUpOrDropOff => _selectingPickUpOrDropOff;
  bool get deliveryLookingForDriver => _deliveryLookingForDriver;
  String get requestType => _requestType;

  int? get routeDuration => _routeDuration;

  //SETTTERS
  set driverInformation(DriverInformation? value) {
    _driverInformation = value;
    notifyListeners();
  }

  set driverStatus(String value) {
    _driverStatus = value;
    notifyListeners();
  }

  set deliveryStatus(String value) {
    _deliveryStatus = value;
    notifyListeners();
  }

  // set driverCurrentCoordenates(LatLng? value) {
  //   _driverCurrentCoordenates = value;
  //   notifyListeners();
  // }

  set pickUpLocation(String? value) {
    _pickUpLocation = value;
    notifyListeners();
  }

  set dropOffLocation(String? value) {
    _dropOffLocation = value;
    notifyListeners();
  }

  set pickUpCoordenates(LatLng? value) {
    _pickUpCoordenates = value;
    notifyListeners();
  }

  set dropOffCoordenates(LatLng? value) {
    _dropOffCoordenates = value;
    notifyListeners();
  }

  set polylineFromPickUpToDropOff(Polyline value) {
    _polylineFromPickUpToDropOff = value;
    notifyListeners();
  }

  set markers(Set<Marker> value) {
    _markers = value;
    notifyListeners();
  }

  set polygons(Set<Polygon> value) {
    _polygons = value;
    notifyListeners();
  }

  set driverMarker(Marker value) {
    _driverMarker = value;
    notifyListeners();
  }

  set requestDriverOrDelivery(bool value) {
    _requestDriverOrDelivery = value;
    notifyListeners();
  }

  set selectingPickUpOrDropOff(bool value) {
    _selectingPickUpOrDropOff = value;
    notifyListeners();
  }

  set deliveryLookingForDriver(bool value) {
    _deliveryLookingForDriver = value;
    notifyListeners();
  }

  set requestType(String value) {
    _requestType = value;
    notifyListeners();
  }

  set routeDuration(int? value) {
    _routeDuration = value;
    notifyListeners();
  }

  //To update profile values
  void updatePassenger(Map valuesToUpdate) {
    if (valuesToUpdate['name'] != null) {
      passenger!.name = valuesToUpdate['name'];
    }
    if (valuesToUpdate['lastName'] != null) {
      passenger!.lastName = valuesToUpdate['lastName'];
    }

    if (valuesToUpdate['email'] != null) {
      passenger!.email = valuesToUpdate['email'];
    }
    notifyListeners();
  }

  //FUNCTIONS
  Future<void> cancelRequest() async {
    final passengerId = FirebaseAuth.instance.currentUser?.uid;
    if (passengerId == null) {
      logger.e("Passenger not authenticated. ");
      return;
    }
    await SharedService.removeDriverRequest(passengerId);
    deliveryLookingForDriver = false;
    SharedService.removeDriverRequestData(passengerId);
  }

  //Animate camera given an location point
  Future<void> animateCameraToPosition(LatLng locationToMove) async {
    polylineFromPickUpToDropOff = const Polyline(
      polylineId: PolylineId("default"),
      points: [],
    );
    try {
      GoogleMapController controller = await mapController.future;

      await controller
          .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: locationToMove,
        zoom: 15,
        bearing: 0,
      )));
    } catch (e) {
      logger.e("Error trying to animate map camera: $e");
    }
  }
  //Fit markers in the map

  //fit all markers on the map
  Future<void> fitMarkers(LatLng p1, LatLng p2) async {
    // Create LatLngBounds for the two points
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        p1.latitude < p2.latitude ? p1.latitude : p2.latitude,
        p1.longitude < p2.longitude ? p1.longitude : p2.longitude,
      ),
      northeast: LatLng(
        p1.latitude > p2.latitude ? p1.latitude : p2.latitude,
        p1.longitude > p2.longitude ? p1.longitude : p2.longitude,
      ),
    );

    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 100);
    try {
      GoogleMapController controller = await mapController.future;
      await controller.animateCamera(cameraUpdate);
    } catch (e) {
      logger.e("Error trying to animate camera: $e");
    }
  }

  //Polygons

  // Method to load and parse GeoJSON file
  Future<void> loadGeoJson() async {
    // Load the GeoJSON file from assets
    final String response =
        await rootBundle.loadString('assets/json/sectors.geojson');
    final Map<String, dynamic> data = json.decode(response);
    final List<dynamic> features = data['features'];
    for (var feature in features) {
      if (feature['geometry']['type'] == 'Polygon') {
        // Get the coordinates for the polygon
        var coordinates = feature['geometry']['coordinates']
            [0]; // GeoJSON polygons are nested
        List<LatLng> polygonPoints = coordinates.map<LatLng>((coord) {
          return LatLng(
              coord[1],
              coord[
                  0]); // GeoJSON uses [longitude, latitude], so we need to swap them
        }).toList();
        _polygons.add(Polygon(
          polygonId: PolygonId(feature['properties']['Name']),
          points: polygonPoints,
          strokeColor: Colors.transparent,
          fillColor: Colors.transparent,
          strokeWidth: 3,
        ));
      }
    }
  }

  // Simple point-in-polygon check using ray-casting algorithm
  bool _pointInPolygon(LatLng point, List<LatLng> polygonPoints) {
    int n = polygonPoints.length;
    bool inside = false;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      if ((polygonPoints[i].longitude > point.longitude) !=
              (polygonPoints[j].longitude > point.longitude) &&
          (point.latitude <
              (polygonPoints[j].latitude - polygonPoints[i].latitude) *
                      (point.longitude - polygonPoints[i].longitude) /
                      (polygonPoints[j].longitude -
                          polygonPoints[i].longitude) +
                  polygonPoints[i].latitude)) {
        inside = !inside;
      }
    }
    return inside;
  }

//GET SECTOR by coords
  void updateSector(LatLng? point) {
    if (point == null) return;
    sector = null;
    for (var polygon in _polygons) {
      if (_pointInPolygon(point, polygon.points)) {
        sector = polygon.polygonId
            .value; // This is the polygon's name (from GeoJSON "Name")
        logger.f("Sector updated to: $sector");
      }
    }
  }

  //To load current vertion
  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    version = info.version;
    notifyListeners();
  }
}
