import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/features/request_delivery/model/delivery_details_model.dart';
import 'package:passenger_app/features/request_delivery/viewmodel/delivery_request_viewmodel.dart';
import 'package:passenger_app/shared/widgets/custom_elevated_button.dart';
import 'package:passenger_app/shared/widgets/custom_testfield.dart';
import 'package:provider/provider.dart';

class DeliveryDetailsBottomSheet extends StatefulWidget {
  const DeliveryDetailsBottomSheet({super.key});
  @override
  State<DeliveryDetailsBottomSheet> createState() =>
      _DeliveryDetailsBottomSheetState();
}

class _DeliveryDetailsBottomSheetState
    extends State<DeliveryDetailsBottomSheet> {
  final Logger logger = Logger();
  final recipientNameController = TextEditingController();
  final detailsTextController = TextEditingController();
  bool showrecipientNameError = false;
  bool showDetailsError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final deliveryRequestViewModel =
        Provider.of<DeliveryRequestViewModel>(context);
    // final sharedProvider = Provider.of<SharedProvider>(context);
    // Text controllers for sender and recipient
    // final senderTextController = TextEditingController();
    // final recipientTextController = TextEditingController();
    // Adjust padding for keyboard appearance
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    //Update field if DeliveryRequest is already saved in viewmodel
    DeliveryDetailsModel? deliveryDetailsModel =
        deliveryRequestViewModel.deliveryDetailsModel;

    if (deliveryDetailsModel != null) {
      recipientNameController.text = deliveryDetailsModel.recipientName;
      detailsTextController.text = deliveryDetailsModel.details;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background, // White background
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16), // Rounded top corners
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 15,
          right: 15,
          top: 10,
          bottom: keyboardHeight > 0
              ? keyboardHeight
              : 10, // Adjust bottom padding based on keyboard
        ),
        child: SingleChildScrollView(
          // Allows scrolling when keyboard is up
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Ensures the sheet covers content size
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                "Detalles de la encomienda",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              // // Sender's phone number
              // const SizedBox(height: 8),
              // PhoneTextField(
              //   controller: senderTextController,
              //   hintText: "Número del remitente",
              // ),

              // // Recipient's phone number
              // PhoneTextField(
              //   controller: recipientTextController,
              //   hintText: "Número del destinatario",
              // ),

              //Recipient name
              const SizedBox(height: 10),
              const Text(
                "Nombre del detinatario",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              CustomTextField(
                hintText: "Destinatario",
                textEditingController: recipientNameController,
                validator: (p0) {
                  if (p0 == null || p0.isEmpty) {
                    return 'Por favor, ingrese el nombre del destinatario'; // Required validation
                  }
                  return null;
                },
              ),
              //Validator text recipient name
              if (showrecipientNameError)
                const Text(
                  "Por favor, ingrese el nombre del destinatario",
                  style: TextStyle(color: Colors.red),
                ),

              // Delivery description
              const SizedBox(height: 10),
              const Text(
                "Describa la entrega",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),

              // TextField for delivery description
              const SizedBox(height: 10),
              TextFormField(
                controller: detailsTextController,
                maxLength: 200,
                maxLines: null, // Allow multiple lines
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: "Ejemplo: Caja de tamaño grande, frágil..",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.grey[400]!), // Default border
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: Colors.grey[400]!), // Border in unfocused mode
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: Colors.blue), // Border in focused mode
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  hintStyle: TextStyle(
                    color: Colors.grey[600], // Adjust hint text color if needed
                    height:
                        1.5, // This adjusts the line height for better readability
                  ),
                ),
              ),
              if (showDetailsError)
                const Text(
                  "Por favor, ingrese el los detalles de la entrega",
                  style: TextStyle(color: Colors.red),
                ),

              // Save button
              const SizedBox(height: 10),
              CustomElevatedButton(
                  onTap: () {
                    //validate
                    setState(() {
                      showrecipientNameError =
                          recipientNameController.text.isEmpty;
                      showDetailsError = detailsTextController.text.isEmpty;
                    });
                    if (showrecipientNameError || showDetailsError) {
                      return;
                    }
                    //save data in viewmodel
                    DeliveryDetailsModel deliveryDetailsModel =
                        DeliveryDetailsModel(
                      recipientName: recipientNameController.text,
                      details: detailsTextController.text,
                    );

                    deliveryRequestViewModel.deliveryDetailsModel =
                        deliveryDetailsModel;
                    //Pop this bottom sheet
                    Navigator.pop(context);
                  },
                  child: const Text("Guardar")),
            ],
          ),
        ),
      ),
    );
  }
}

// Function to display the bottom sheet
void showDeliveryDetailsBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Allows controlling the height
    backgroundColor: Colors.transparent, // Transparent background
    builder: (context) {
      return const DeliveryDetailsBottomSheet();
    },
  );
}
