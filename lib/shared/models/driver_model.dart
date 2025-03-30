import 'package:firebase_database/firebase_database.dart';

class DriverRideStatus {
  static const String goingToPickUp = 'goingToPickUp';
  static const String arrived = 'arrived';
  static const String goingToDropOff = 'goingToDropOff';
  static const String finished = 'finished';
  static const String canceled = 'canceled';
}

class DeliveryStatus {
  static const String goingForThePackage = 'goingForThePackage';
  static const String haveThePackage = 'haveThePackage';
  static const String goingToTheDeliveryPoint = 'goingToTheDeliveryPoint';
  static const String arrivedToTheDeliveryPoint = 'arrivedToTheDeliveryPoint';
  static const String passengerHasThePakcage = 'passengerHasThePakcage';
  static const String finished = 'finished';
  static const String canceled = 'canceled';
}

class DriverModel {
  final String statusAvailability;
  final String availability;
  final String status;
  final DriverInformation information;

  const DriverModel({
    required this.statusAvailability,
    required this.availability,
    required this.status,
    required this.information,
  });

  factory DriverModel.fromFirestore(DataSnapshot doc, String id) {
    final data = doc.value as Map<dynamic, dynamic>;
    return DriverModel(
      statusAvailability: data['status_availability'] ?? '',
      availability: data['availability'] ?? '',
      status: data['status'] ?? '',
      information: DriverInformation.fromFirestore(doc, id),
    );
  }
}

class DriverInformation {
  final String id;
  final String name;
  final String phone;
  final String profilePicture;
  final double rating;
  final String vehicleModel;
  final String carRegistrationNumber;
  final String deviceToken;
  final String taxiCode;

  const DriverInformation({
    required this.id,
    required this.name,
    required this.phone,
    required this.profilePicture,
    required this.rating,
    required this.vehicleModel,
    required this.carRegistrationNumber,
    required this.deviceToken,
    required this.taxiCode,
  });

  // Factory constructor to create a DriverModel instance from Firestore DocumentSnapshot
  factory DriverInformation.fromFirestore(DataSnapshot doc, String id) {
    final dataTemp = doc.value as Map<dynamic, dynamic>;
    final data = dataTemp['information'];
    return DriverInformation(
      id: id, // Use the snapshot's key as the ID
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      profilePicture: data['profilePicture'] ?? '',
      rating: data['rating'] != null ? (data['rating'] as num).toDouble() : 0.0,
      vehicleModel: data['vehicleModel'] ?? '',
      carRegistrationNumber: data['carRegistrationNumber'] ?? '',
      deviceToken: data['deviceToken'] ?? '',
      taxiCode: data['taxiCode'] ?? '',
    );
  }

  // Factory constructor to create a DriverModel instance from a Map<String, dynamic>
  factory DriverInformation.fromMap(Map<String, dynamic> map, String id) {
    return DriverInformation(
      id: id,
      name: map['name'] as String,
      phone: map['phone'] as String,
      profilePicture: map['profilePicture'] as String,
      rating: (map['rating'] as num).toDouble(),
      vehicleModel: map['vehicleModel'] as String,
      carRegistrationNumber: map['carRegistrationNumber'] as String,
      deviceToken: map['deviceToken'] ?? '',
      taxiCode: map['taxiCode'] ?? '',
    );
  }

  // Method to convert a DriverModel instance to a Firestore-friendly map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'profilePicture': profilePicture,
      'rating': rating,
      'vehicleModel': vehicleModel,
      'carRegistrationNumber': carRegistrationNumber,
      'deviceToken': deviceToken,
      'taxiCode': taxiCode,
    };
  }
}
