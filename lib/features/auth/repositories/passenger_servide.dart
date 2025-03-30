import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/shared/models/g_user.dart';

class PassengerService {
  //GEt Passenger data from Firestore, only is passenger us authenticated
  static Future<GUser?> getUserData() async {
    final Logger logger = Logger();
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        logger.e("Usr is not authenticated");
        return null;
      }

      //firenbase
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('g_user')
          .doc(user.uid)
          .get();
      //Supabase

      if (userData.exists) {
        return GUser.fromMap(userData.data() as Map, id: userData.id);
      } else {
        return null;
      }
    } catch (e) {
      logger.e("Error al obtner datos de usuario: $e");
      return null;
    }
  }

  // Upload image to Firebase Storage
  static Future<String?> uploadImage(File imageFile, String uid) async {
    final Logger logger = Logger();
    try {
      final storageRef =
          FirebaseStorage.instance.ref().child('users/profile_image/$uid');
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      logger.e('Error uploading image: $e');
      return null;
    }
  }

  //Save user data in Firestore
  static Future<bool> savePassengerDataInFirestore(GUser passenger) async {
    final Logger logger = Logger();
    try {
      await FirebaseFirestore.instance
          .collection('g_user')
          .doc(passenger.id)
          .set(passenger.toMap());
      return true;
    } catch (e) {
      logger.e("Error adding user data in Firestore: ${e.toString()}");
      return false;
    }
  }
}
