import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:firebase_database/firebase_database.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:passenger_app/shared/repositories/push_notification_service.dart';

class RequestDriverService {
  //Get first available drivre under "positions" node
  static Future<String?> claimAndGetOldestDriverKey() async {
    final Logger logger = Logger();
    final DatabaseReference driversRef =
        FirebaseDatabase.instance.ref('positions');

    try {
      String? driverIdToReturn;
      final TransactionResult transactionResult =
          await driversRef.runTransaction((mutableData) {
        if (mutableData == null) {
          return rtdb.Transaction.abort(); // No drivers available
        }
        final Map<dynamic, dynamic> driversMap = Map.from(mutableData as Map);

        final sortedDrivers = driversMap.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        final String oldestDriverKey = sortedDrivers[0].key;

        driverIdToReturn = driversMap[oldestDriverKey]['driver_id'];
        mutableData.remove(oldestDriverKey);
        return rtdb.Transaction.success(mutableData);
      });
      if (transactionResult.committed) {
        if (driverIdToReturn == null) {
          return null;
        } else {
          return driverIdToReturn;
        }
      } else {
        logger.i("No available drivers.");
        return null;
      }
    } catch (e) {
      logger.e("Error claiming the oldest driver: $e");
      return null;
    }
  }

  //get all available drivers in the map
  static Future<List<Map<String, dynamic>>> fetchAvailableDrivers() async {
    final logger = Logger();
    try {
      rtdb.DatabaseReference driversRef =
          rtdb.FirebaseDatabase.instance.ref('drivers');
      final snapshot = await driversRef
          .orderByChild('status_availability')
          .equalTo('pending_online')
          .get();

      if (snapshot.exists) {
        return (snapshot.value as Map<dynamic, dynamic>).entries.map((entry) {
          final driverData = entry.value as Map<dynamic, dynamic>;
          final driverCoordinates = driverData['location'];
          return {
            'driverID': entry.key,
            'latitude': driverCoordinates['latitude'],
            'longitude': driverCoordinates['longitude'],
          };
        }).toList();
      }
      return [];
    } catch (e) {
      logger.e("Erro fetching pending_online drivers: $e");
      return [];
    }
  }

  //Add request data under "drivers/key" node
  static Future<bool> updatePassengerNode(
    String driverId,
    String? driverDeviceToken,
    SharedProvider sharedProvider,
    String requestType,
    String nodeName, {
    String? audioFilePath,
    String? indicationText,
  }) async {
    final Logger logger = Logger();
    try {
      // Reference to the main node (e.g., a driver ID or any other node ID)
      final rtdb.DatabaseReference mainNodeRef =
          rtdb.FirebaseDatabase.instance.ref('drivers/$driverId');

      // Update the "passenger" node under the specific main node
      await mainNodeRef.child(nodeName).set({
        'passengerId': sharedProvider.passenger!.id,
        'status': "pending",
        'type': requestType,
        'information': {
          'deviceToken': sharedProvider.passenger?.deviceToken,
          'audioFilePath':
              audioFilePath ?? '', //In case it is 'byRecordedAudio' type
          'indicationText':
              indicationText ?? '', //In case it is 'byTexting' type
          'name': sharedProvider.passenger!.name,
          'phone': sharedProvider.passenger!.phone,
          'profilePicture': sharedProvider.passenger!.profilePicture,
          'pickUpLocation': sharedProvider.pickUpLocation ?? '',
          'dropOffLocation': sharedProvider.dropOffLocation ?? '',
          "currentCoordenates": {
            "latitude": sharedProvider.passengerCurrentCoords != null
                ? sharedProvider.passengerCurrentCoords!.latitude
                : 0.1, //To make sure that the data that will be updated are Double
            "longitude": sharedProvider.passengerCurrentCoords != null
                ? sharedProvider.passengerCurrentCoords!.longitude
                : 0.1,
          },
          "pickUpCoordenates": {
            "latitude": sharedProvider.pickUpCoordenates != null
                ? sharedProvider.pickUpCoordenates!.latitude
                : 0.1, //To make sure that the data that will be updated are Double
            "longitude": sharedProvider.pickUpCoordenates != null
                ? sharedProvider.pickUpCoordenates!.longitude
                : 0.1,
          },
          "dropOffCoordenates": {
            "latitude": sharedProvider.dropOffCoordenates != null
                ? sharedProvider.dropOffCoordenates!.latitude
                : 0.1,
            "longitude": sharedProvider.dropOffCoordenates != null
                ? sharedProvider.dropOffCoordenates!.longitude
                : 0.1,
          },
        },
      }).timeout(
        const Duration(seconds: 7),
      );
      //Send push notification to the driver
      if (driverDeviceToken != null) {
        PushNotificationService.sendPushNotification(
          deviceToken: driverDeviceToken,
          title: "Nuevo pasajero",
          body: "Un nuevo pasajero se le ha asignado",
        );
      }
      logger.i("Passenger node updated successfully.");
      return true;
    } catch (e) {
      logger.e("Error updating passenger node: $e");
      return false;
    }
  }

  //Add passenger to the driver request queue
  static Future<bool> addDriverRequestToQueue(
      SharedProvider sharedProvider, String currentLocation) async {
    final logger = Logger();
    //get id
    final driverId = FirebaseAuth.instance.currentUser?.uid;
    if (driverId == null) {
      logger.e("Error: User is not authenticated.");
      return false;
    }
    //Determinate SECTOR

    try {
      rtdb.DatabaseReference dataRef =
          rtdb.FirebaseDatabase.instance.ref('driver_requests');
      Map<String, dynamic> data = {
        'name': sharedProvider.passenger!.name,
        'profilePicture': sharedProvider.passenger!.profilePicture,
        'pickUpLocation': sharedProvider.pickUpLocation ?? '',
        'currentLocation': currentLocation,
        'requestType': sharedProvider.requestType,
        'sector': sharedProvider.sector,
        'timestamp': ServerValue.timestamp,
      };
      logger.i('Data to save: $data');

      await dataRef
          .child(driverId)
          .set(data)
          .timeout(const Duration(seconds: 7));

      logger.i("driver request written succesfully.");
      return true;
    } catch (e) {
      logger.e('Error trying to add driverRequest to the queue. : $e');
      return false;
    }
  }

  //Update "status" field under 'driver/driverId' node
  static Future<void> updateDriverStatus(String driverId, String status) async {
    final Logger logger = Logger();
    try {
      final rtdb.DatabaseReference databaseRef =
          rtdb.FirebaseDatabase.instance.ref('drivers/$driverId/status');
      // Update the status
      await databaseRef.set(status);

      logger.i('Successfully updated driver status for driverId: $driverId');
    } catch (e) {
      logger.e('Failed to update driver status: $e');
    }
  }

  static Future<void> updateSecondPassengerStatus(
      String driverId, String status) async {
    final logger = Logger();
    try {
      final rtdb.DatabaseReference databaseReference =
          rtdb.FirebaseDatabase.instance.ref('drivers/$driverId');
      databaseReference.update({
        'status': status,
      });
      logger.i('Successfully updated second passenger status: $driverId');
    } catch (e) {
      logger.e('Failed to update second passenger status: $e');
    }
  }

  static Future<void> updateDriverStarRatings(double newRating, String driverId,
      String comment, String passengerId) async {
    final Logger logger = Logger();
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    if (driverId.isEmpty) {
      logger.e("Driver Id is empty: $driverId");
      return;
    }

    // Reference to the driver's document
    final DocumentReference userRef =
        firestore.collection('drivers').doc(driverId);

    try {
      // Use Firestore transaction to ensure atomic updates
      await firestore.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction.get(userRef);

        if (userSnapshot.exists) {
          // Retrieve the 'ratings' map or initialize it to default values
          Map<String, dynamic> ratings = userSnapshot.get('ratings') ??
              {
                'totalRatingScore': 0.0,
                'ratingCount': 0,
                'rating': 0.0,
              };

          double totalRatingScore =
              (ratings['totalRatingScore'] ?? 0.0).toDouble();
          int ratingCount = (ratings['ratingCount'] ?? 0).toInt();

          // Update the total rating score and increment the rating count
          totalRatingScore += newRating;
          ratingCount += 1;

          // Calculate the new average rating
          double averageRating = totalRatingScore / ratingCount.toDouble();
          averageRating = double.parse(averageRating.toStringAsFixed(1));

          // Update the 'ratings' map in the driver's document
          transaction.update(userRef, {
            'ratings': {
              'totalRatingScore': totalRatingScore,
              'ratingCount': ratingCount,
              'rating': averageRating,
            }
          });
        } else {
          // Initialize the 'ratings' map if the document doesn't exist
          transaction.set(userRef, {
            'ratings': {
              'totalRatingScore': newRating,
              'ratingCount': 1,
              'rating': newRating,
            }
          });
        }
      });

      logger.i('New rating has been saved and average updated.');

      // If a comment is provided, add it to the subcollection
      if (comment.isNotEmpty) {
        final CollectionReference commentsRef = firestore
            .collection('drivers')
            .doc(driverId)
            .collection('comments');

        await commentsRef.doc(passengerId).set({
          'comment': comment,
          'timestamp': FieldValue.serverTimestamp(),
        });

        logger.i('Comment has been saved in the subcollection.');
      }
    } catch (e) {
      logger.e("An error occurred while updating ratings: $e");
    }
  }

  static Future<void> saveDriverIdTemporally(
      String passengerId, String driverId) async {
    final logger = Logger();
    final dbref = rtdb.FirebaseDatabase.instance.ref("trip_progress");
    try {
      await dbref.set({passengerId: driverId});
    } catch (e) {
      logger.e("Error: $e");
    }
  }

  static Future<void> removeDriverIdTemporally(String passengerId) async {
    final logger = Logger();
    final dbref =
        rtdb.FirebaseDatabase.instance.ref("trip_progress/$passengerId");
    try {
      await dbref.remove();
    } catch (e) {
      logger.e("Error: $e");
    }
  }
}
