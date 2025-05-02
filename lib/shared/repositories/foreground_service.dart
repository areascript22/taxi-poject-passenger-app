// import 'dart:async';
// import 'dart:ui';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:passenger_app/firebase_options.dart';
// import 'package:passenger_app/shared/models/driver_model.dart';
// import 'package:passenger_app/shared/util/shared_util.dart';
//
// //VARIABLES
// StreamSubscription<DatabaseEvent>? driverStatusListener;
// //FUNCTIONS
// Future<void> startBackgroundService() async {
//   final service = FlutterBackgroundService();
//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: false,
//       isForegroundMode: true,
//       initialNotificationTitle: "Carrera en progreso",
//       initialNotificationContent: "El servicio está ejecutándose...",
//     ),
//     iosConfiguration: IosConfiguration(
//       onForeground: onStart,
//       onBackground: onIosBackground,
//     ),
//   );
// }
//
// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();
//
//   if (service is AndroidServiceInstance) {
//     //FOREGROUND SERVICE
//     service.on('setAsForeground').listen((event) async {
//       final sharedUtil = SharedUtil();
//       service.setAsForegroundService();
//       final driverId = event?['driverId'];
//       if (driverId != null) {
//         listenToDriverStatus(driverId, sharedUtil, service);
//         await service.setForegroundNotificationInfo(
//           title: "Carrera en progreso",
//           content: "Proceso en segundo plano",
//         );
//       }
//     });
//
//     //BACKGROUND SERVICE
//     service.on('setAsBackground').listen((event) {
//       service.setAsBackgroundService();
//     });
//   }
//   service.on('stopService').listen((event) {
//     service.stopSelf();
//     driverStatusListener?.cancel();
//   });
// }
//
// //Listening to driver's arrival
// void listenToDriverStatus(
//     String driverId, SharedUtil sharedUtil, ServiceInstance service) async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   final ref = FirebaseDatabase.instance.ref("drivers/$driverId/status");
//   driverStatusListener = ref.onValue.listen((event) async {
//     if (event.snapshot.exists) {
//       final status = event.snapshot.value as String;
//       //Chech if driver has arrived on pick-up point
//       if (status == DriverRideStatus.arrived) {
//         await sharedUtil.repeatAudio("sounds/taxi_espera.mp3");
//       }
//       if (status == DriverRideStatus.goingToDropOff) {
//         sharedUtil.stopAudioLoop();
//       }
//       if (status == DriverRideStatus.finished || status == DriverRideStatus.canceled) {
//         sharedUtil.stopAudioLoop();
//         service.stopSelf();
//       }
//     }
//   });
// }
// //Listening to Delivery status
//
//
// //IOS
// @pragma('vm:entry-point')
// bool onIosBackground(ServiceInstance service) {
//   return true;
// }
