import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/features/auth/view/pages/passenger_data_wrapper.dart';
import 'package:passenger_app/shared/models/g_user.dart';
import 'package:passenger_app/shared/models/passenger_model.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:passenger_app/shared/widgets/custom_elevated_button.dart';
import 'package:passenger_app/shared/widgets/custom_testfield.dart';
import 'package:passenger_app/features/auth/viewmodel/passenger_viewmodel.dart';
import 'package:provider/provider.dart';

class CreateProfileData extends StatefulWidget {
  const CreateProfileData({super.key});

  @override
  State<CreateProfileData> createState() => _CreateProfileDataState();
}

class _CreateProfileDataState extends State<CreateProfileData> {
  final Logger logger = Logger();
  final FirebaseAuth authInstance = FirebaseAuth.instance;

  File? _imageFile;
  bool showImageSelectError = false;
  final formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  // final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final passengerViewModel = Provider.of<PassengerViewModel>(context);
    final sharedProvider = Provider.of<SharedProvider>(context);
    return Scaffold(
      appBar: AppBar(),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //Profile image
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      backgroundColor: Theme.of(context).colorScheme.background,
                      context: context,
                      builder: (BuildContext context) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 15),
                            Text(
                              "Selecciona una fuente",
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: const Text('Tomar foto'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.camera);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library),
                              title: const Text('Galería'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.gallery);
                              },
                            ),
                            if (_imageFile != null)
                              ListTile(
                                leading: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                title: const Text(
                                  'Eliminar foto',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _imageFile = null;
                                  });
                                },
                              ),
                          ],
                        );
                      },
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        //color: Colors.black,
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(100)),
                        boxShadow: [
                          BoxShadow(
                            spreadRadius: 5,
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 1),
                            offset: const Offset(2, 3),
                            blurRadius: 5,
                          )
                        ]),
                    child: CircleAvatar(
                      radius: 90,
                      backgroundColor: Colors.transparent,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : const AssetImage('assets/img/default_profile.png')
                              as ImageProvider,
                      child: const SizedBox(),
                    ),
                  ),
                ),
                if (showImageSelectError)
                  const Text(
                    "Por favor, seleccione una imagen",
                    style: TextStyle(color: Colors.red),
                  ),

                //Personal info
                //Name
                const SizedBox(height: 30),
                CustomTextField(
                  hintText: 'Nombre',
                  textEditingController: _nameController,
                  validator: (p0) {
                    if (p0 == null || p0.isEmpty) {
                      return 'Por favor, ingrese su nombre'; // Required validation
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  hintText: 'Apellido',
                  textEditingController: _lastnameController,
                  validator: (p0) {
                    if (p0 == null || p0.isEmpty) {
                      return 'Por favor, ingrese su apellido'; // Required validation
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // CustomTextField(
                //   hintText: 'Número celular +593',
                //   textEditingController: _phoneController,
                //   isKeyboardNumber: true,
                //   validator: (value) {
                //     // Check if the phone number is empty
                //     if (value == null || value.isEmpty) {
                //       return 'Por favor ingresa tu número de celular.';
                //     }
                //     // Validate if the input is exactly 10 digits
                //     if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                //       return 'El número de celular debe contener 10 dígitos';
                //     }
                //     return null; // If the input is valid
                //   },
                // ),
                //Email optional field
                CustomTextField(
                  hintText: "Email (opcional)",
                  textEditingController: _emailController,
                  validator: (p0) {
                    if (p0 != null && p0.isNotEmpty) {
                      final emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                      if (!emailRegex.hasMatch(p0)) {
                        return 'Enter a valid email';
                      }
                    }
                    return null; // No error if empty (optional field)
                  },
                ),

                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CustomElevatedButton(
                    onTap: () async {
                      //Unfocuss keyboard
                      FocusScope.of(context).unfocus();
                      //check if there is an image selected, otherwise we return
                      setState(() {
                        showImageSelectError = (_imageFile == null);
                      });
                      if (showImageSelectError) {
                        return;
                      }
                      //Check form fields
                      if (formKey.currentState?.validate() ?? false) {
                        setState(() {
                          isLoading = true;
                        });
                        //upnload image
                        String? profilePicture = '';
                        profilePicture = await passengerViewModel.uploadImage(
                            _imageFile!, authInstance.currentUser!.uid);
                        logger.i("Profile picture updated");

                        //ratings
                        final Ratings ratings = Ratings(
                          rating: 0,
                          ratingCount: 0,
                          totalRatingScore: 0,
                        );
                        //Create Passenger object
                        final passenger = GUser(
                          id: authInstance.currentUser!.uid,
                          name: _nameController.text,
                          lastName: _lastnameController.text,
                          email: _emailController.text,
                          phone:
                              authInstance.currentUser!.phoneNumber.toString(),
                          profilePicture: profilePicture ?? '',
                          ratings: ratings,
                          role: [Roles.passenger],
                          access: Access.granted,
                          deviceToken: null,
                        );

                        //Save data in firestore
                        bool dataSaved = await passengerViewModel
                            .savePassengerDataInFirestore(passenger);
                        logger.i("Passenger data saved");
                        //Navigato to Map Page
                        if (dataSaved) {
                          //Update values on Providers
                          sharedProvider.passenger = passenger;

                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const PassengerDataWrapper(),
                              ),
                            );
                          }
                        } else {
                          setState(() {
                            isLoading = false;
                          });
                        }

                        setState(() {
                          isLoading = false;
                        });
                      }
                    },
                    child: !isLoading
                        ? const Text("Continuar")
                        : const CircularProgressIndicator(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //Pick image from diferent sources
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedfile = await picker.pickImage(source: source);
    if (pickedfile != null) {
      setState(() {
        _imageFile = File(pickedfile.path);
      });
    }
  }
}
