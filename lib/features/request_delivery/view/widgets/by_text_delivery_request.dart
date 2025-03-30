import 'package:flutter/material.dart';
import 'package:passenger_app/core/utils/toast_message_util.dart';
import 'package:passenger_app/features/request_delivery/viewmodel/delivery_request_viewmodel.dart';
import 'package:passenger_app/shared/models/request_type.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:passenger_app/shared/widgets/custom_elevated_button.dart';
import 'package:provider/provider.dart';

class ByTextDeliveryRequest extends StatelessWidget {
  const ByTextDeliveryRequest({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final deliveryRequestViewModel =
        Provider.of<DeliveryRequestViewModel>(context);
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
            "Detalla tu pedido y la direccón de entrega.",
          ),
          const Text(
            "Ejemplo: Necesito que me compren 50 panes y lo entrege a la entrada proncipal de la Espoch.",
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
              hintText: 'Especifica aquí...',
            ),
            textAlignVertical: TextAlignVertical.top, // Align text to the top
            expands: false, // TextField won't expand infinitely
            scrollPhysics: const BouncingScrollPhysics(),
          ),

          //Button
          const SizedBox(height: 7),
          CustomElevatedButton(
            onTap: () async {
              if (textController.text.length < 15) {
                ToastMessageUtil.showToast(
                    "Texto muy corto. Escribe al menos 15 caracteres.");
                return;
              }
              //Request the vehicle
              await deliveryRequestViewModel.writeDeliveryRequest(
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
