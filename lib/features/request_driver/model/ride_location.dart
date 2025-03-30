

class RideLocation {
  final String clientId;
  final String pickUpCoordinates; // Fixed typo "Coordenates"
  final String dropOffCoordinates; // Fixed typo "Coordenates"
  final String pickUpLocation;
  final String destinationLocation;
  final String destinationReference;
  final String status;
  final String distance;
  final String duration;

  RideLocation({
    required this.clientId,
    required this.pickUpCoordinates,
    required this.dropOffCoordinates,
    required this.pickUpLocation,
    required this.destinationLocation,
    required this.destinationReference,
    required this.status,
    required this.distance,
    required this.duration,
  });

  // Factory constructor for creating an instance from a JSON map
  factory RideLocation.fromJson(Map<String, dynamic> json) {
    return RideLocation(
      clientId: json['clientId'] as String,
      pickUpCoordinates: json['pickUpCoordinates'] as String,
      dropOffCoordinates: json['destinationCoordinates'] as String,
      pickUpLocation: json['pickUpLocation'] as String,
      destinationLocation: json['destinationLocation'] as String,
      destinationReference: json['destinationReference'] as String,
      status: json['status'] as String,
      distance: json['distance'] as String,
      duration: json['duration'] as String,
    );
  }

  // Method to convert an instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'pickUpCoordinates': pickUpCoordinates,
      'destinationCoordinates': dropOffCoordinates,
      'pickUpLocation': pickUpLocation,
      'destinationLocation': destinationLocation,
      'destinationReference': destinationReference,
      'status': status,
      'distance': distance,
      'duration': duration,
    };
  }

  // Overriding toString for better debugging and logging
  @override
  String toString() {
    return 'RideLocation(clientId: $clientId, pickUpCoordinates: $pickUpCoordinates, destinationCoordinates: $dropOffCoordinates, pickUpLocation: $pickUpLocation, destinationLocation: $destinationLocation, destinationReference: $destinationReference, status: $status, distance: $distance, duration: $duration)';
  }

  // Equality operator and hash code override
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    return other is RideLocation &&
        other.clientId == clientId &&
        other.pickUpCoordinates == pickUpCoordinates &&
        other.dropOffCoordinates == dropOffCoordinates &&
        other.pickUpLocation == pickUpLocation &&
        other.destinationLocation == destinationLocation &&
        other.destinationReference == destinationReference &&
        other.status == status &&
        other.distance == distance &&
        other.duration == duration;
  }

  @override
  int get hashCode => Object.hash(
        clientId,
        pickUpCoordinates,
        dropOffCoordinates,
        pickUpLocation,
        destinationLocation,
        destinationReference,
        status,
        distance,
        duration,
      );
}
