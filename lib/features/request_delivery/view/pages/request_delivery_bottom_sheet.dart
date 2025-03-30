import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/features/request_delivery/view/widgets/by_audio_delivery_request.dart';
import 'package:passenger_app/features/request_delivery/view/widgets/by_coords_delivery_request.dart';
import 'package:passenger_app/features/request_delivery/view/widgets/by_text_delivery_request.dart';
import 'package:passenger_app/features/request_delivery/viewmodel/delivery_request_viewmodel.dart';
import 'package:passenger_app/shared/models/request_type.dart';
import 'package:passenger_app/shared/widgets/custom_image_button.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:provider/provider.dart';

class RequestDeliveryBottomSheet extends StatefulWidget {
  const RequestDeliveryBottomSheet({
    super.key,
  });

  @override
  State<RequestDeliveryBottomSheet> createState() =>
      _RequestDeliveryBottomSheetState();
}

class _RequestDeliveryBottomSheetState extends State<RequestDeliveryBottomSheet>
    with SingleTickerProviderStateMixin {
  final logger = Logger();
  final bool estimatedtime = false;
  int selectedIndex = 0; // Tracks the currently selected button index
  final List<Map> imagePaths = [
    {'path': 'assets/img/delivery.png', 'title': 'Encomiendas'},
    {'path': 'assets/img/car.png', 'title': 'Carreras'},
  ];
  bool showEncompleteFieldError = false;
  late TabController _tabController;
  late DeliveryRequestViewModel? viewMdelToDispose;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    initializeValues();
  }

  void initializeValues() {
    final sharedProvider = Provider.of<SharedProvider>(context, listen: false);
    viewMdelToDispose =
        Provider.of<DeliveryRequestViewModel>(context, listen: false);
    switch (sharedProvider.requestType) {
      case RequestType.byCoordinates:
        _tabController.index = 0;
        break;
      case RequestType.byRecordedAudio:
        _tabController.index = 1;
        break;
      case RequestType.byTexting:
        _tabController.index = 2;
        break;
      default:
    }
  }

  @override
  void dispose() {
    //  viewMdelToDispose!.clearListeners();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sharedProvider = Provider.of<SharedProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          // height: 320,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: List.generate(2, (index) {
                      return CustomImageButton(
                        imagePath: imagePaths[index]['path'],
                        title: imagePaths[index]['title'],
                        isSelected: selectedIndex == index,
                        onTap: () {
                          if (index != selectedIndex) {
                            sharedProvider.requestDriverOrDelivery = false;
                          }
                          selectedIndex = index; // Update the selected button
                          setState(() {});
                        },
                      );
                    }),
                  ),
                  const Divider(color: Colors.blue),
                  //OPTIONS: Coordenates, voice and text
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                    labelStyle: const TextStyle(fontSize: 18),
                    unselectedLabelStyle: const TextStyle(fontSize: 15),
                    tabs: const [
                      Tab(
                        child: Column(
                          children: [
                            Icon(
                              Ionicons.locate_outline,
                              size: 20,
                              color: Colors.green,
                            ),
                            Text(
                              "Por mapa",
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Column(
                          children: [
                            Icon(
                              Ionicons.mic_circle_outline,
                              size: 20,
                              color: Colors.blue,
                            ),
                            Text(
                              "Por audio",
                              style: TextStyle(
                                color: Colors.blue,
                              ),
                            )
                          ],
                        ),
                      ),
                      Tab(
                        child: Column(
                          children: [
                            Icon(
                              Ionicons.document_text_outline,
                              size: 20,
                              color: Colors.amber,
                            ),
                            Text(
                              "Por texto",
                              style: TextStyle(
                                color: Colors.amber,
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                    onTap: (value) {
                      switch (value) {
                        case 0:
                          sharedProvider.requestType =
                              RequestType.byCoordinates;
                          if (sharedProvider.passengerCurrentCoords != null) {
                            sharedProvider.animateCameraToPosition(
                                sharedProvider.passengerCurrentCoords!);
                          }
                          break;
                        case 1:
                          sharedProvider.requestType =
                              RequestType.byRecordedAudio;
                          sharedProvider.pickUpCoordenates = null;
                          sharedProvider.markers.clear();
                          break;
                        case 2:
                          sharedProvider.requestType = RequestType.byTexting;
                          sharedProvider.pickUpCoordenates = null;
                          sharedProvider.markers.clear();
                          break;
                        default:
                      }
                    },
                  ),

                  //TABBAR CONTENT
                  //Content
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: _buildTabView(_tabController.index),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabView(
    int index,
  ) {
    switch (index) {
      case 0:
        return const ByCoordDeliveryRequest();
      case 1:
        return const ByAudioDeliveryRequest();
      case 2:
        return const ByTextDeliveryRequest();
      default:
        return const SizedBox();
    }
  }
}
