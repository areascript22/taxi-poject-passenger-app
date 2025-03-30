import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';

class HomeServices {
  // Sign out
  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // Upload image to Firebase Storage
  static Future<String?> uploadImage(File imageFile, String uid) async {
    final Logger logger = Logger();
    try {
      final storageRef =
          FirebaseStorage.instance.ref().child('ProfileImage/Users/$uid');
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      logger.e('Error uploading image: $e');
      return null;
    }
  }

  static Future<bool> updatePassengerDataInFirestore(
      Map<String, dynamic> values) async {
    final Logger logger = Logger();
    try {
      // Update Firestore document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(values['id'])
          .update(values)
          .then((value) => null)
          .catchError((error) {
        logger.e("Error: $error");
      });

      return true;
    } catch (e) {
      logger.e("Error updating passenger data in Firestore: ${e.toString()}");
      return false;
    }
  }

  //Update device token in Firestore
  static Future<void> updateDeviceToken(String deviceToken) async {
    final logger = Logger();
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('g_user').doc(userId).update({
        'deviceToken': deviceToken,
      });
      logger.i("Device token updated successfully.");
    } catch (e) {
      logger.e("Error updating device token: $e");
    }
  }
}
