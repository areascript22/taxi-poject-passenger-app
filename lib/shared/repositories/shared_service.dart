import 'dart:async';

import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/shared/models/driver_model.dart';
import 'package:passenger_app/shared/models/route_info.dart';


class SharedService {
  //It returns a route as polylines (it is use to update polyline in Porvider)
  static Future<RouteInfo?> getRoutePolylinePoints(
      LatLng start, LatLng end, String apiKey) async {
    final Logger logger = Logger();

    PolylinePoints polylinePoints = PolylinePoints();
    List<LatLng> routePoints = [];
    try {
      try {
        PolylineResult result = await polylinePoints
            .getRouteBetweenCoordinates(
              googleApiKey: apiKey,
              request: PolylineRequest(
                  origin: PointLatLng(start.latitude, start.longitude),
                  destination: PointLatLng(end.latitude, end.longitude),
                  mode: TravelMode.driving),
            )
            .timeout(const Duration(seconds: 10));
        if (result.points.isNotEmpty) {
          result.points.forEach((PointLatLng point) {
            routePoints.add(LatLng(point.latitude, point.longitude));
          });
        }
        return RouteInfo(
          distance: "",
          duration:
              result.durationTexts != null ? result.durationTexts![0] : "",
          polylinePoints: routePoints,
        );
      } on TimeoutException catch (e) {
        logger.e("Timeout occurred: $e");
        return null;
      } on SocketException catch (e) {
        logger.e("Network issue: $e");
        return null;
      } catch (e) {
        logger.e("Unknown error: $e");
        return null;
      }
    } catch (e) {
      logger.e('Error fetching route: $e');
      return null;
    }
  }

  //Get driver data by id, under "drivers" node
  static Future<DriverModel?> getDriverInformationById(String driverId) async {
    final Logger logger = Logger();
    try {
      final DatabaseReference driversRef =
          FirebaseDatabase.instance.ref('drivers');
      final DataSnapshot snapshot = await driversRef.child(driverId).get();

      if (snapshot.exists && snapshot.value != null) {
        logger.f("Data fetched ${snapshot.value}");
        return DriverModel.fromFirestore(snapshot, driverId);
      } else {
        logger.e("No data found for driver ID: $driverId ");
        return null;
      }
    } catch (e) {
      logger.e("Error fetching driver data: $e, ");
      return null;
    }
  }

  //Upload an audio file to Storage and get its URL
  static Future<String?> uploadAudioToFirebase(
      String audioFilePath, String passengerId) async {
    final logger = Logger();
    if (audioFilePath.isEmpty) {
      logger.e("No audio file found to upload.");
      return null;
    }

    try {
      //Generate the name of the file
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('yyyyMMdd_HHmmss').format(now);
      String fileName = "audio_$formattedDate.aac";
      // Get a reference to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref();
      final audioRef =
          storageRef.child('users/recorded_audio/$passengerId/$fileName');
      final uploadTask = audioRef.putFile(File(audioFilePath));
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      logger.i('Audio uploaded successfully. URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      logger.e('Error uploading audio: $e');
      return null;
    }
  }

  // Cancel driver request or delivery request when there are not drivers yet.
  static Future<bool> removeDriverRequest(String passengerId) async {
    final logger = Logger();
    try {
      final dbRef = FirebaseDatabase.instance.ref();
      final storageRef =
          FirebaseStorage.instance.ref('audio_requests/$passengerId.aac');
      final path = 'driver_requests/$passengerId'; //Driver request path
      final path2 = 'delivery_requests/$passengerId'; //Delivery request path
      // Remove data at the specified path
      await dbRef.child(path).remove();
      await dbRef.child(path2).remove();
      await storageRef.delete();
      logger.i('Request removed successfully at $path');
      return true;
    } catch (e) {
      logger.e('Error removing data: $e');
      return false;
    }
  }

 

  


}
