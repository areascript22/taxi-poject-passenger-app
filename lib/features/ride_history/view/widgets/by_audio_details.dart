import 'package:flutter/material.dart';
import 'package:passenger_app/features/ride_history/view/widgets/audio_player_info.dart';
import 'package:passenger_app/features/ride_history/view/widgets/custom_devider.dart';
import 'package:passenger_app/shared/models/ride_history_model.dart';

class ByAudioDetails extends StatelessWidget {
  final RideHistoryModel ride;
  const ByAudioDetails({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomDevider(),
          const Text(
            "Indicaciónes",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          //Audio Player
          AudioPlayerInfo(
            filePath: ride.audioFilePath,
          ),
        ],
      ),
    );
  }
}
