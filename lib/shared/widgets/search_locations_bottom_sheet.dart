import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/features/map/view/widgets/custom_search_testfield.dart';
import 'package:passenger_app/features/map/viewmodel/map_view_model.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SearchLocationButtonSheet extends StatefulWidget {
  final bool selectingPickUpOrDropOff;
  const SearchLocationButtonSheet(
      {super.key, required this.selectingPickUpOrDropOff});
  @override
  State<SearchLocationButtonSheet> createState() =>
      _SearchLocationButtonSheetState();
}

class _SearchLocationButtonSheetState extends State<SearchLocationButtonSheet> {
  final Logger logger = Logger();
  final SpeechToText speechToText = SpeechToText();
  bool speechEnabled = false;
  String wordsSpoken = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeTextControllersLiteners();
    });
  }

  void initializeTextControllersLiteners() {
    final mapViewModel = Provider.of<MapViewModel>(context, listen: false);
    final sharedProvider = Provider.of<SharedProvider>(context, listen: false);

    //Focus Text Fields
    if (widget.selectingPickUpOrDropOff) {
      FocusScope.of(context).requestFocus(mapViewModel.pickUpFocusNode);
    } else {
      FocusScope.of(context).requestFocus(mapViewModel.dropOffFocusNode);
    }
    mapViewModel.initializeTextControllersLiteners(sharedProvider);
  }

  //For microfone
  void initSpeech() async {
    speechEnabled = await speechToText.initialize();
    setState(() {});
    if (speechEnabled) {
      if (speechToText.isListening) {
        stopListening();
      } else {
        startListenning();
      }
    }
  }

  void startListenning() async {
    final mapViewModel = Provider.of<MapViewModel>(context, listen: false);
    await speechToText.listen(
      onResult: (result) {
        if (mapViewModel.isPickUpFocussed) {
          mapViewModel.pickUpTextController.text = result.recognizedWords;
          setState(() {});
        }
        if (mapViewModel.isDropOffFocussed) {
          mapViewModel.dropOffTextController.text = result.recognizedWords;
          setState(() {});
        }
      },
    );
  }

  void stopListening() async {
    await speechToText.stop();
    setState(() {});
  }

  void activateMicrofone() {
    initSpeech();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BuildContext fatherContext = context;
    final mapViewModel = Provider.of<MapViewModel>(context);
    final sharedProvider = Provider.of<SharedProvider>(context);

    return FractionallySizedBox(
      heightFactor: 0.8, // Set the height to 80% of the screen
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background, // White background
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16), // Rounded top corners
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                "Selecciona tu lugar de recogida.",
                style: Theme.of(context).textTheme.titleLarge,
              ),

              // Pick Up Search Direction
              const SizedBox(height: 8),
              CustomSearchTextField(
                activateMicrofone: activateMicrofone,
                focusNode: mapViewModel.pickUpFocusNode,
                prefixIcon: !mapViewModel.isPickUpFocussed
                    ? const Icon(
                        Ionicons.location,
                        color: Colors.red,
                      )
                    : const Icon(Ionicons.search),
                hintText: "Lugar de recogida",
                controller: mapViewModel.pickUpTextController,
              ),
              const SizedBox(height: 3),

              // Drop Off Search Direction
              // CustomSearchTextField(
              //   activateMicrofone: activateMicrofone,
              //   focusNode: mapViewModel.dropOffFocusNode,
              //   prefixIcon: !mapViewModel.isDropOffFocussed
              //       ? const Icon(
              //           Ionicons.location,
              //           color: Colors.green,
              //         )
              //       : const Icon(Ionicons.search),
              //   hintText: "Destino",
              //   controller: mapViewModel.dropOffTextController,
              // ),

              // Select location on the map
              const SizedBox(height: 10),
              // GestureDetector(
              //   onTap: () {
              //     sharedProvider.selectingPickUpOrDropOff =
              //         widget.selectingPickUpOrDropOff;
              //     mapViewModel.enteredInSelectingLocationMode = true;
              //     //animate camera
              //     if (sharedProvider.selectingPickUpOrDropOff) {
              //       if (sharedProvider.pickUpCoordenates != null) {
              //         mapViewModel.animateCameraToPosition(
              //             sharedProvider.pickUpCoordenates!);
              //       }
              //     } else {
              //       if (sharedProvider.dropOffCoordenates != null) {
              //         mapViewModel.animateCameraToPosition(
              //             sharedProvider.dropOffCoordenates!);
              //       }
              //     }
              //     Navigator.pop(context);
              //   },
              //   child: const Row(
              //     children: [
              //       Icon(
              //         Ionicons.location_outline,
              //         color: Colors.blue,
              //         size: 30,
              //       ),
              //       SizedBox(width: 8),
              //       Text(
              //         "Seleccionar dirección en el mapa",
              //         style: TextStyle(
              //           color: Colors.blue,
              //           fontSize: 16,
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              //Directions suggestions
              if (mapViewModel.isPickUpFocussed)
                !mapViewModel.loading
                    ? Expanded(
                        child: ListView.builder(
                          itemCount: mapViewModel.listOfLcoationsPickUp.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              onTap: () async {
                                //Display this direction on TextField
                                mapViewModel.pickUpTextController.text =
                                    mapViewModel.listOfLcoationsPickUp[index]
                                        ['description'];
                                //Get coordinated of this place
                                String placeId = mapViewModel
                                    .listOfLcoationsPickUp[index]['place_id'];
                                await mapViewModel.getCoordinatesByPlaceId(
                                    placeId, fatherContext, sharedProvider);
                              },
                              title: Text(
                                  "${mapViewModel.listOfLcoationsPickUp[index]['description']}"),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          color: Colors.grey,
                        ),
                      ),
              // if (mapViewModel.isDropOffFocussed)
              //   !mapViewModel.loading
              //       ? Expanded(
              //           child: ListView.builder(
              //             itemCount: mapViewModel.listOfLcoationsDropOff.length,
              //             itemBuilder: (context, index) {
              //               return ListTile(
              //                 onTap: () async {
              //                   //Display this direction on TextField
              //                   mapViewModel.dropOffTextController.text =
              //                       mapViewModel.listOfLcoationsDropOff[index]
              //                           ['description'];
              //                   //Get coordinated of this place
              //                   String placeId = mapViewModel
              //                       .listOfLcoationsDropOff[index]['place_id'];
              //                   await mapViewModel.getCoordinatesByPlaceId(
              //                       placeId, fatherContext, sharedProvider);
              //                 },
              //                 title: Text(
              //                     "${mapViewModel.listOfLcoationsDropOff[index]['description']}"),
              //               );
              //             },
              //           ),
              //         )
              //       : const Center(
              //           child: CircularProgressIndicator(
              //             color: Colors.grey,
              //           ),
              //         ),
            ],
          ),
        ),
      ),
    );
  }
}

// Function to display the bottom sheet
void showSearchBottomSheet(
    BuildContext context, bool selectingPickUpOrDropOff) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Allows controlling the height
    backgroundColor: Colors.transparent, // Transparent background
    builder: (context) {
      return SearchLocationButtonSheet(
        selectingPickUpOrDropOff: selectingPickUpOrDropOff,
      );
    },
  );
}
