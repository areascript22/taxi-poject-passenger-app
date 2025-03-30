import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';

class ProfielServices {
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
      final uid = FirebaseAuth.instance.currentUser?.uid;
      // Update Firestore document
      await FirebaseFirestore.instance
          .collection('g_user')
          .doc(uid)
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
}
