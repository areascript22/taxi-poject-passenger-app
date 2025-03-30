import 'package:cloud_firestore/cloud_firestore.dart';

class PassengerModel {
  final String id;
  String name;
  String lastName;
  final String email;
  String phone;
  String profilePicture;
  final List<PaymentMethod> paymentMethods;
  final List<RideHistory> rideHistory;
  final Ratings ratings;
  final Timestamp createdAt;
  Timestamp updatedAt;

  PassengerModel({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.profilePicture,
    required this.paymentMethods,
    required this.rideHistory,
    required this.ratings,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory method to create a Passenger from a Firestore document
  factory PassengerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PassengerModel(
      id: doc.id,
      name: data['name'],
      lastName: data['lastName'],
      email: data['email'],
      phone: data['phone'],
      profilePicture: data['profilePicture'],
      paymentMethods: (data['paymentMethods'] as List<dynamic>?)
              ?.map((e) => PaymentMethod.fromMap(e))
              .toList() ??
          [],
      rideHistory: (data['rideHistory'] as List<dynamic>?)
              ?.map((e) => RideHistory.fromMap(e))
              .toList() ??
          [],
      ratings: Ratings.fromMap(data['ratings']),
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }

  // Method to convert Passenger to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'profilePicture': profilePicture,
      'paymentMethods': paymentMethods.map((e) => e.toMap()).toList(),
      'rideHistory': rideHistory.map((e) => e.toMap()).toList(),
      'ratings': ratings.toMap(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class PaymentMethod {
  final String type;
  final String details;

  PaymentMethod({
    required this.type,
    required this.details,
  });

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      type: map['type'],
      details: map['details'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'details': details,
    };
  }
}

class RideHistory {
  final String rideId;
  final Timestamp date;
  final String driverId;
  final double fare;

  RideHistory({
    required this.rideId,
    required this.date,
    required this.driverId,
    required this.fare,
  });

  factory RideHistory.fromMap(Map<String, dynamic> map) {
    return RideHistory(
      rideId: map['rideId'],
      date: map['date'],
      driverId: map['driverId'],
      fare: map['fare'].toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rideId': rideId,
      'date': date,
      'driverId': driverId,
      'fare': fare,
    };
  }
}

class Ratings {
  final double rating;
  final int ratingCount;
  final double totalRatingScore;

  Ratings({
    required this.rating,
    required this.ratingCount,
    required this.totalRatingScore,
  });

  factory Ratings.fromMap(Map<String, dynamic> map) {
    return Ratings(
      rating: map['rating'].toDouble(),
      ratingCount: map['ratingCount'],
      totalRatingScore: map['totalRatingScore'].toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rating': rating,
      'ratingCount': ratingCount,
      'totalRatingScore': totalRatingScore,
    };
  }
}
