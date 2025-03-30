import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/features/profile/viewmodel/profile_viewmodel.dart';
import 'package:passenger_app/shared/models/g_user.dart';
import 'package:passenger_app/shared/widgets/custom_elevated_button.dart';
import 'package:passenger_app/shared/widgets/custom_testfield.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:provider/provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final Logger logger = Logger();
  final FirebaseAuth authInstance = FirebaseAuth.instance;
  File? _imageFile;
//  bool showImageSelectError = false;
  final formKey = GlobalKey<FormState>();

  // bool isThereChangesToSave = false;

  @override
  Widget build(BuildContext context) {
    final homeViewModel = Provider.of<ProfileViewModel>(context);
    final sharedProvider = Provider.of<SharedProvider>(context);

    GUser? passengerModel = sharedProvider.passenger;

    if (passengerModel != null) {
      logger.f("Porfile values: ${passengerModel.toMap()}");
      homeViewModel.nameController.text = passengerModel.name;
      homeViewModel.lastnameController.text = passengerModel.lastName ?? '';
      homeViewModel.phoneController.text = passengerModel.phone;
      homeViewModel.emailController.text = passengerModel.email ?? '';
    }

    return Scaffold(
      appBar: AppBar(),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: passengerModel != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //Profile image
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            backgroundColor:
                                Theme.of(context).colorScheme.background,
                            context: context,
                            builder: (BuildContext context) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 15),
                                  Text(
                                    "Selecciona una fuente",
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
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
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.transparent,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : null,
                          child: _imageFile == null
                              ? ClipOval(
                                  child: passengerModel
                                          .profilePicture.isNotEmpty
                                      ? FadeInImage.assetNetwork(
                                          placeholder:
                                              'assets/img/no_image.png',
                                          image: passengerModel.profilePicture,
                                          fadeInDuration:
                                              const Duration(milliseconds: 50),
                                          fit: BoxFit.cover,
                                          width: 150,
                                          height: 150,
                                        )
                                      : Image.asset(
                                          'assets/img/default_profile.png',
                                          fit: BoxFit.cover,
                                          width: 155,
                                          height: 155,
                                        ),
                                )
                              : const SizedBox(),
                        ),
                      ),
                      if (homeViewModel.showImageSelectError)
                        const Text(
                          "Por favor, seleccione una imagen",
                          style: TextStyle(color: Colors.red),
                        ),

                      //Personal info
                      //Name
                      const SizedBox(height: 30),
                      CustomTextField(
                        hintText: 'Nombre',
                        textEditingController: homeViewModel.nameController,
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
                        textEditingController: homeViewModel.lastnameController,
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
                      //   textEditingController: homeViewModel.phoneController,
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
                      CustomTextField(
                        hintText: "Email (opcional)",
                        textEditingController: homeViewModel.emailController,
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
                          onTap: () => homeViewModel.updatePassengerData(
                              formKey,
                              context,
                              passengerModel,
                              _imageFile,
                              sharedProvider),
                          child: !homeViewModel.loading
                              ? const Text("Guardar")
                              : const CircularProgressIndicator(),
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: CircularProgressIndicator(),
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
