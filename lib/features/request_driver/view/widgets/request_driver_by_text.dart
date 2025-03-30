import 'package:flutter/material.dart';
import 'package:passenger_app/core/utils/toast_message_util.dart';
import 'package:passenger_app/features/request_driver/viewmodel/request_driver_viewmodel.dart';
import 'package:passenger_app/shared/models/request_type.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:passenger_app/shared/widgets/custom_elevated_button.dart';
import 'package:provider/provider.dart';

class RequestDriverByTyping extends StatelessWidget {
  final void Function()? requesFunction;
  const RequestDriverByTyping({
    super.key,
    required this.requesFunction,
  });

  @override
  Widget build(BuildContext context) {
    final requestDriverViewModel = Provider.of<RequestDriverViewModel>(context);
    final sharedProvider = Provider.of<SharedProvider>(context);
    final textController = TextEditingController();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          //Steps
          const Text(
            "Especifica el lugar tu dirección. ",
          ),
          const Text(
            "Ejemplo: Hola, necesito un hehículo a la entrada principal de la Unach.",
            style: TextStyle(fontWeight: FontWeight.w300),
          ),
          //Textfield
          const SizedBox(height: 10),
          TextField(
            controller: textController,
            maxLines: 4, // Limits visible lines to 5
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              border: OutlineInputBorder(), // Adds a border
              hintText: 'Especifica tu dirección...',
            ),
            textAlignVertical: TextAlignVertical.top, // Align text to the top
            expands: false, // TextField won't expand infinitely
            scrollPhysics: const BouncingScrollPhysics(),
          ),

          //Button
          const SizedBox(height: 7),
          CustomElevatedButton(
            onTap: () {
              if (textController.text.length < 15) {
                ToastMessageUtil.showToast(
                    "Texto muy corto. Escribe al menos 15 caracteres.");
                return;
              }
              //Request the vehicle
              requestDriverViewModel.requestTaxi2(
                context,
                sharedProvider,
                RequestType.byTexting,
                indicationText: textController.text,
              );
            },
            child: const Text("Solicitar taxi"),
          ),
        ],
      ),
    );
  }
}

Widget buildRequestDriverByText(void Function()? requesFunction) {
  //Pass the function as parameter
  return RequestDriverByTyping(
    requesFunction: requesFunction,
  );
}
