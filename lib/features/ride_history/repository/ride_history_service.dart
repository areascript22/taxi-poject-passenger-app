import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/shared/models/g_user.dart';

class RideHistoryService {
  //To retrieve data  passanger data from FIrestore
  static Future<GUser?> getGUserById(String driverId) async {
    final logger = Logger();
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('g_user')
          .doc(driverId)
          .get();

      if (doc.exists) {
        return GUser.fromMap(doc.data() as Map, id: doc.id);
      } else {
        return null;
      }
    } catch (e) {
      logger.e("Error fetching data from Firestore:$e");
      return null;
    }
  }
}
