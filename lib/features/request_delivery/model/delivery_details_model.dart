class DeliveryDetailsModel {
  final String recipientName;
  final String details;

  DeliveryDetailsModel({
    required this.recipientName,
    required this.details,
  });

  // Convert a DeliveryDetailsModel object to a Map (for JSON or Firestore).
  Map<String, dynamic> toMap() {
    return {
      'recipientName': recipientName,
      'details': details,
    };
  }

  // Create a DeliveryDetailsModel object from a Map (for JSON or Firestore).
  factory DeliveryDetailsModel.fromMap(Map<String, dynamic> map) {
    return DeliveryDetailsModel(
      recipientName: map['recipientName'] ?? '',
      details: map['details'] ?? '',
    );
  }

  @override
  String toString() {
    return 'DeliveryDetailsModel(recipientName: $recipientName, details: $details)';
  }
}
