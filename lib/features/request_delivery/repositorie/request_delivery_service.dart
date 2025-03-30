import 'package:firebase_database/firebase_database.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/features/request_delivery/model/delivery_details_model.dart';
import 'package:passenger_app/shared/models/g_user.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';

class RequestDeliveryService {
  // Static function to write this model to Firebase Realtime Database
  static Future<bool> writeToDatabase({
    required String passengerId,
    required GUser passengerModel,
    required String requestType,
    DeliveryDetailsModel? deliveryDetails,
    required SharedProvider sharedProvider,
    String? audioFilePath,
    String? indicationText,
  }) async {
    final Logger logger = Logger();
    try {
      // Reference to the "delivery_requests" node in Firebase
      DatabaseReference ref =
          FirebaseDatabase.instance.ref('delivery_requests');
      // Use passengerId as the key for the delivery request
      DatabaseReference passengerRequestRef = ref.child(passengerId);
      // Add timestamp for sorting
      String timestamp = DateTime.now().toIso8601String();
      // Write the data to the passenger's unique node
      await passengerRequestRef.set(
        {
          'information': {
            'name': passengerModel.name,
            'phone': passengerModel.phone,
            'profilePicture': passengerModel.profilePicture,
            'pickUpLocation': sharedProvider.pickUpLocation,
            'dropOffLocation': sharedProvider.dropOffLocation,
            'audioFilePath': audioFilePath ?? '',
            'indicationText': indicationText ?? '',
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
            "currentCoordenates": {
              "latitude": sharedProvider.passengerCurrentCoords != null
                  ? sharedProvider.passengerCurrentCoords!.latitude
                  : 0.1,
              "longitude": sharedProvider.passengerCurrentCoords != null
                  ? sharedProvider.passengerCurrentCoords!.longitude
                  : 0.1,
            },
          },
          'details': deliveryDetails != null ? deliveryDetails.toMap() : null,
          'status': 'pending',
          'requestType': requestType,
          'timestamp': timestamp, // Add sortable timestamp here
        },
      ).timeout(const Duration(seconds: 7));

      logger.i(
          'Delivery request written successfully for passenger ID: $passengerId');
      return true;
    } catch (e) {
      logger.e('Error writing delivery request: $e');
      return false;
    }
  }

  //Update delivery Status
  static Future<void> updateDeliveryStatus(
      String passengerId, String status) async {
    final Logger logger = Logger();
    try {
      final DatabaseReference databaseRef = FirebaseDatabase.instance
          .ref('delivery_requests/$passengerId/status');

      // Update the status
      await databaseRef.set(status);

      logger.i('Successfully updated driver status for driverId: $passengerId');
    } catch (e) {
      logger.e('Failed to update driver status: $e');
    }
  }
}
