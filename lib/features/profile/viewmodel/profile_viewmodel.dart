import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/core/utils/toast_message_util.dart';
import 'package:passenger_app/features/profile/repositories/profile_services.dart';
import 'package:passenger_app/shared/models/g_user.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';

class ProfileViewModel extends ChangeNotifier {
  final Logger logger = Logger();
  int currentIndexStack = 0;
  bool _loading = false;

  //For EditProfilePage
  TextEditingController nameController = TextEditingController();
  TextEditingController lastnameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  bool _selectedImage = false;
  bool _showImageSelectError = false;

  //GETTERS
  bool get selectedImage => _selectedImage;
  bool get loading => _loading;
  bool get showImageSelectError => _showImageSelectError;

  //SETTERS
  set selectedImage(bool value) {
    _selectedImage = value;
    notifyListeners();
  }

  set loading(bool value) {
    _loading = value;
    notifyListeners();
  }

  set showImageSelectError(bool value) {
    _showImageSelectError = value;
    notifyListeners();
  }

  //Update Passenger data in Firestore
  void updatePassengerData(
      GlobalKey<FormState> formKey,
      BuildContext context,
      GUser passengerModel,
      File? imageFile,
      SharedProvider sharedProvider) async {
    loading = false;
    //check if there is an image selected, otherwise we return
    if (imageFile == null && passengerModel.profilePicture.isEmpty) {
      showImageSelectError = true;
      logger.i("imagen $imageFile   ${passengerModel.profilePicture}");
    } else {
      logger.i("No imagen");
      showImageSelectError = false;
    }

    if (showImageSelectError) {
      return;
    }
    //Check form fields
    if (formKey.currentState?.validate() ?? false) {
      loading = true;
      //upnload image
      String? profilePicture = '';
      if (imageFile != null) {
        //Upload new image
        profilePicture = await ProfielServices.uploadImage(
            imageFile, FirebaseAuth.instance.currentUser!.uid);

        // sharedProvider.passenger!.profilePicture = profilePicture!;
      }
      //add data to update
      Map<String, dynamic> valuesToUpdate = {};

      if (profilePicture!.isNotEmpty) {
        valuesToUpdate['profilePicture'] = profilePicture;
      }
      if (nameController.text != passengerModel.name) {
        valuesToUpdate['name'] = nameController.text;
      }
      if (lastnameController.text != passengerModel.lastName) {
        valuesToUpdate['lastName'] = lastnameController.text;
      }
      if (emailController.text != passengerModel.email) {
        valuesToUpdate['email'] = emailController.text;
      }
      //Update data in firestore
      bool dataUpdated =
          await ProfielServices.updatePassengerDataInFirestore(valuesToUpdate);

      //Navigato to Map Page
      if (dataUpdated) {
        sharedProvider.updatePassenger(valuesToUpdate); 

        if (context.mounted) {
          ToastMessageUtil.showToast('Datos actualizados');
          Navigator.pop(context);
        }
      }

      loading = false;
    }
  }
}
