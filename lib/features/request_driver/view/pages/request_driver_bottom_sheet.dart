import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/features/request_driver/view/widgets/request_driver_by_coords.dart';
import 'package:passenger_app/shared/models/request_type.dart';
import 'package:passenger_app/features/request_driver/view/widgets/request_driver_by_audio.dart';
import 'package:passenger_app/features/request_driver/view/widgets/request_driver_by_text.dart';
import 'package:passenger_app/shared/widgets/custom_image_button.dart';
import 'package:passenger_app/features/request_driver/viewmodel/request_driver_viewmodel.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:provider/provider.dart';

class RequestDriverBottomSheet extends StatefulWidget {
  final void Function() fitMap;
  const RequestDriverBottomSheet({
    super.key,
    required this.fitMap,
  });

  @override
  State<RequestDriverBottomSheet> createState() =>
      _RequestDriverBottomSheetState();
}

class _RequestDriverBottomSheetState extends State<RequestDriverBottomSheet>
    with SingleTickerProviderStateMixin {
  final logger = Logger();
  final bool estimatedtime = false;
  int selectedIndex = 1; // Tracks the currently selected button index
  final List<Map> imagePaths = [
    {'path': 'assets/img/delivery.png', 'title': 'Encomiendas'},
    {'path': 'assets/img/car.png', 'title': 'Carreras'},
  ];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    initializeValues();
  }

  void initializeValues() {
    final sharedProvider = Provider.of<SharedProvider>(context, listen: false);
    final requestDriverViewModel =
        Provider.of<RequestDriverViewModel>(context, listen: false);

    //  requestDriverViewModel.listenToDriverAcceptance(sharedProvider);
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
    requestDriverViewModel.checkIfThereIsTripInProgress(
        sharedProvider, context);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sharedProvider = Provider.of<SharedProvider>(context);
    final requestDriverViewModel = Provider.of<RequestDriverViewModel>(context);

    final referenceTextController = TextEditingController();
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
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
                  spreadRadius: 5,
                  blurRadius: 7,
                ),
              ]),
          // height: 320,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
            child: Column(
              children: [
                //Delivery, Ride Options
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: List.generate(2, (index) {
                    return CustomImageButton(
                      imagePath: imagePaths[index]['path'],
                      title: imagePaths[index]['title'],
                      isSelected: selectedIndex == index,
                      onTap: () {
                        if (selectedIndex != index) {
                          sharedProvider.requestDriverOrDelivery = true;
                        }
                        selectedIndex = index; // Update the selected button
                        setState(() {});
                      },
                    );
                  }),
                ),
                //Devider line
                const Divider(color: Colors.blue),
                //REQUEST RIDE OPTIONS
                // TabBar at the top of the Bottom Sheet

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
                        if (sharedProvider.passengerCurrentCoords != null) {
                          sharedProvider.animateCameraToPosition(
                              sharedProvider.passengerCurrentCoords!);
                        }

                        sharedProvider.requestType = RequestType.byCoordinates;
                        break;
                      case 1:
                        sharedProvider.pickUpCoordenates = null;
                        sharedProvider.markers.clear();
                        sharedProvider.requestType =
                            RequestType.byRecordedAudio;
                        break;
                      case 2:
                        sharedProvider.pickUpCoordenates = null;
                        sharedProvider.markers.clear();
                        sharedProvider.requestType = RequestType.byTexting;
                        break;
                      default:
                    }
                  },
                ),
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
                    child: _buildTabView(_tabController.index, sharedProvider,
                        requestDriverViewModel, referenceTextController),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabView(
      int index,
      SharedProvider sharedViewModel,
      RequestDriverViewModel requestDriverViewModel,
      TextEditingController referenceTextController) {
    switch (index) {
      case 0:
        return const RequestDriverByCoords();
      case 1:
        return buildRequestDriverByAudio();
      case 2:
        return buildRequestDriverByText(() {});
      default:
        return const SizedBox();
    }
  }
}
