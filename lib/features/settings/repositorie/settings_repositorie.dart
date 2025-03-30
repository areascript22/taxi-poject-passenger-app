import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class SettingsService {
  static final logger = Logger();
  static Future<bool> deleteAccountPermanentely(String uid) async {
    try {
      // 1. Delete Firestore document
      await FirebaseFirestore.instance.collection('g_user').doc(uid).delete();

      // 2. Delete profile image from Storage
      final profileImageRef =
          FirebaseStorage.instance.ref().child('users/profile_image/$uid');
      try {
        await profileImageRef.delete();
      } catch (e) {
        logger.e('No profile image found or already deleted.');
      }

      // 3. Delete audio folder from Storage
      final audioFolderRef =
          FirebaseStorage.instance.ref().child('users/recorded_audio/$uid');
      try {
        final audioFiles = await audioFolderRef.listAll();
        for (var item in audioFiles.items) {
          await item.delete();
        }
      } catch (e) {
        logger.i('No audio files found or already deleted.');
      }

      // 4. Call your cloud function to delete the authenticated user
      final url = Uri.parse('https://deleteuser-4wrgni2wda-uc.a.run.app');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': uid}),
      );

      if (response.statusCode == 200) {
        logger.i('User deleted from Firebase Auth via cloud function.');
        return true;
      } else {
        logger.e('Failed to delete user from Auth: ${response.body}');
        return false;
      }
    } catch (e) {
      logger.e('Error while deleting user account: $e');
      return false;
    }
  }
}
