import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/features/ride_history/view/widgets/ride_history_tile.dart';
import 'package:passenger_app/shared/models/ride_history_model.dart';

class RideHistoryPage extends StatelessWidget {
  const RideHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logger = Logger();
    final passengerId = FirebaseAuth.instance.currentUser?.uid;
    if (passengerId == null) {
      logger.e("Driver is not authenticated");
      return const Center(
        child: Text("Error: No está autenticado."),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Todos mis viajes',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
          maxLines: 2,
        ),
        iconTheme: const IconThemeData(color: Colors.purple),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ride_history')
            .where('passengerId', isEqualTo: passengerId) // Filter by driverId
            .orderBy('timesTamp', descending: true) // Order by most recent
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
              color: Colors.blue,
            ));
          }

          if (snapshot.hasError) {
            logger.e("Error obteniendo datos: ${snapshot.error}");
            return const Center(child: Text('Error obteniendo datos.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aun no ha hecho un viaje.'));
          }

          final rideHistoryList = snapshot.data!.docs
              .map((doc) => RideHistoryModel.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: rideHistoryList.length,
            itemBuilder: (context, index) {
              final ride = rideHistoryList[index];
              return RideHistoryTile(ride: ride);
            },
          );
        },
      ),
    );
  }
}
