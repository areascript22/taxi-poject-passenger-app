import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/features/ride_history/repository/ride_history_service.dart';
import 'package:passenger_app/shared/models/passenger_model.dart';
import 'package:passenger_app/shared/models/route_info.dart';
import 'package:passenger_app/shared/repositories/shared_service.dart';

class RideHistoryViewmodel extends ChangeNotifier {
  final logger = Logger();
  final String apiKey = Platform.isAndroid
      ? dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID'] ?? ''
      : dotenv.env['GOOGLE_MAPS_API_KEY_IOS'] ?? '';
  Completer<GoogleMapController> mapController1 = Completer();
  Polyline _polylineFromPickUpToDropOff =
      const Polyline(polylineId: PolylineId("default"));
  Set<Marker> _markers = {};
  String? _dropOffLocation;
  String _duration = '0 mins';
  String _distance = '0 km';

  //GETTERS
  Polyline get polylineFromPickUpToDropOff => _polylineFromPickUpToDropOff;
  Set<Marker> get markers => _markers;
  String? get dropOffLocation => _dropOffLocation;
  String get duration => _duration;
  String get distance => _distance;
  //SETTERS
  set polylineFromPickUpToDropOff(Polyline value) {
    _polylineFromPickUpToDropOff = value;
    notifyListeners();
  }

  set markers(Set<Marker> value) {
    _markers = value;
    notifyListeners();
  }

  set dropOffLocation(String? value) {
    _dropOffLocation = value;
    notifyListeners();
  }

  set duration(String value) {
    _duration = value;
    notifyListeners();
  }

  set distance(String value) {
    _distance = value;
    notifyListeners();
  }

  //FUNCTINONS
  //on map created function
  void onMapCreated(GoogleMapController controller) async {
    if (!mapController1.isCompleted) {
      mapController1.complete(controller);
    }
  }

  // init values
  void initValues(LatLng pickUpCoords, LatLng dropOffCoords) async {
    //add amrkers
    _addPickUpDroppOffCoords(pickUpCoords, dropOffCoords);
    GoogleMapController mapController = await mapController1.future;
    //fit markers
    _fitMapToTwoLatLngs(
      mapController: mapController,
      point1: pickUpCoords,
      point2: dropOffCoords,
    );

    //draw route
    _drawRoute(pickUpCoords, dropOffCoords);
    //Get drop off location
    dropOffLocation = await RideHistoryService.getReadableAddress(
        dropOffCoords.latitude, dropOffCoords.longitude, apiKey);
  }

  //add markers
  void _addPickUpDroppOffCoords(
      LatLng pickUpCoords, LatLng dropOffCoords) async {
    markers.clear();
    markers.add(
      Marker(
        markerId: MarkerId(pickUpCoords.toString()),
        position: pickUpCoords,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );
    markers.add(
      Marker(
        markerId: MarkerId(dropOffCoords.toString()),
        position: dropOffCoords,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }

  //fit map
  void _fitMapToTwoLatLngs({
    required GoogleMapController mapController,
    required LatLng point1,
    required LatLng point2,
    double padding = 50.0, // Optional padding around the markers
  }) {
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
    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    );
  }

  //draw route
  void _drawRoute(LatLng pickUpCoords, LatLng dropOffCoords) async {
    RouteInfo? response = await SharedService.getRoutePolylinePoints(
        pickUpCoords, dropOffCoords, apiKey);
    if (response == null) {
      logger.e("Error trying to draw map, respose is null");
      return;
    }
    polylineFromPickUpToDropOff = Polyline(
      polylineId: const PolylineId("default"),
      points: response.polylinePoints,
      color: Colors.blue,
      width: 5,
    );
    distance = response.distance;
    duration = response.duration;
  }

  //Retrieve passenger model from Firestore
  Future<PassengerModel?> getPassengerById(String driverId) async {
    if (driverId.isEmpty) {
      logger.e("Passenger id is null");
      return null;
    }
    return await RideHistoryService.getPassengerById (driverId);
  }
}
