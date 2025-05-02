import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart';
import 'package:passenger_app/core/utils/toast_message_util.dart';
import 'package:passenger_app/features/request_delivery/viewmodel/delivery_request_viewmodel.dart';
import 'package:passenger_app/shared/models/request_type.dart';
import 'package:passenger_app/shared/providers/shared_provider.dart';
import 'package:passenger_app/shared/widgets/custom_elevated_button.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

class ByAudioDeliveryRequest extends StatefulWidget {
  const ByAudioDeliveryRequest({super.key});
  @override
  _ByAudioDeliveryRequestState createState() => _ByAudioDeliveryRequestState();
}

class _ByAudioDeliveryRequestState extends State<ByAudioDeliveryRequest> {
  final Logger logger = Logger();
  final TextEditingController _textController = TextEditingController();
  //final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  //final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _currentDuration = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _testValue = 5;
  bool isSliding = false;

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _audioRecorded = false;

  Timer? timer;
  Duration elapsedDuration = Duration.zero;
  final _record = AudioRecorder();

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    // _player.openPlayer();
    listenToDuration();
  }

  @override
  void dispose() {
    _textController.dispose();
    _record.dispose();
    // _recorder.closeRecorder();
    // _player.closePlayer();
    super.dispose();
  }

  Future<void> _initializeRecorder() async {
    final deliveryRequestViewModel =
        Provider.of<DeliveryRequestViewModel>(context, listen: false);
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw 'Microphone permission not granted';
    }
    // await _recorder.openRecorder();
    //Check is there is recorded audio
    if (deliveryRequestViewModel.audioFilePath != null) {
      if (mounted) {
        setState(() {
          _audioRecorded = true;
        });
      }
    }
  }

//Start recording audio
  Future<void> _startRecording() async {
    final deliveryrequestViewModel =
        Provider.of<DeliveryRequestViewModel>(context, listen: false);
    await _audioPlayer.stop();
    if (mounted) {
      setState(() => _isPlaying = false);
    }
    _currentDuration = Duration.zero;
    elapsedDuration = Duration.zero;
    timer?.cancel();
    //timer
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          elapsedDuration += const Duration(seconds: 1);
        });
      }
    });

    //audio recorder
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/single_audio_delivery.aac';
    if (mounted) {
      setState(() {
        _isRecording = true;
        _audioRecorded = false;
      });
    }

    // await _recorder.startRecorder(toFile: filePath);
    await _record.start(const RecordConfig(), path: filePath);
    deliveryrequestViewModel.audioFilePath = filePath;
  }

//Stop recording audio
  Future<void> _stopRecording() async {
    //  await _recorder.stopRecorder();
    await _record.stop();
    if (mounted) {
      setState(() {
        _isRecording = false;
        _audioRecorded = true;
      });
    }

    timer?.cancel();
  }

//Delete recorded audio
  Future<void> _removeRecordedAudio() async {
    final deliveryrequestViewModel =
        Provider.of<DeliveryRequestViewModel>(context, listen: false);
    if (deliveryrequestViewModel.audioFilePath == null) return;
    // await _recorder.deleteRecord(fileName: _audioFilePath!);
    // _record.
    if (deliveryrequestViewModel.audioFilePath != null) {
      final file = File(deliveryrequestViewModel.audioFilePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    deliveryrequestViewModel.audioFilePath = null;
    if (mounted) {
      setState(() {
        _audioRecorded = false;
      });
    }
  }

//Play audio
  Future<void> _playAudio() async {
    final deliveryrequestViewModel =
        Provider.of<DeliveryRequestViewModel>(context, listen: false);
    if (deliveryrequestViewModel.audioFilePath == null) return;
    await _audioPlayer
        .play(DeviceFileSource(deliveryrequestViewModel.audioFilePath!));
    if (mounted) {
      setState(() => _isPlaying = true);
    }
  }

//Stop audio
  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  //Seek to a specific position in the current song
  Future<Null> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  //Listen to duration
  void listenToDuration() {
    //Listen for the total duration
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _totalDuration = newDuration;
        });
      }
    });

    //Listen for the current durationa
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _currentDuration = newPosition;
        });
      }
    });

    //Listen for song completion
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  String formatTime(Duration duration) {
    String twoDigitSeconds =
        duration.inSeconds.remainder(60).toString().padLeft(1, "0");
    String formatedTime = "${duration.inMinutes}: $twoDigitSeconds";
    return formatedTime;
  }

  @override
  Widget build(BuildContext context) {
    final deliveryRequestViewModel =
        Provider.of<DeliveryRequestViewModel>(context);
    final sharedProvider = Provider.of<SharedProvider>(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //Steps
          const Text(
            "Graba un audio espcificando su pedido",
          ),
          const Text(
            "Ejemplo: Necisito que me compre 50 panes de la panadaría X.",
            style: TextStyle(fontWeight: FontWeight.w300),
          ),
          //Container audio player
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xff13181C),
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            child: Column(
              children: [
                //While recording
                if (_isRecording)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xff13181C),
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          formatTime(elapsedDuration),
                          style: TextStyle(color: Colors.white),
                        )
                      ],
                    ),
                  ),
                //(Play/Stop) recorded audio
                if (_audioRecorded)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F272A),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      // mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Play/Pause button
                        IconButton(
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: _isPlaying ? _pauseAudio : _playAudio,
                        ),
                        // Progress Indicator
                        Expanded(
                          flex: 2,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.green,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.green,
                              overlayColor: Colors.green.withOpacity(0.2),
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6.0),
                              trackHeight: 2.0,
                            ),
                            child: Slider(
                              min: 0.0,
                              max: _totalDuration.inSeconds.toDouble(),
                              value: !isSliding
                                  ? _currentDuration.inSeconds.toDouble()
                                  : _testValue,
                              label: _testValue.round().toString(),
                              onChangeStart: (value) {
                                isSliding = true;
                              },
                              onChanged: (double value) {
                                if (mounted) {
                                  setState(() {
                                    _testValue = value;
                                  });
                                }
                              },
                              onChangeEnd: (value2) async {
                                await seek(Duration(seconds: value2.toInt()));
                                if (mounted) {
                                  setState(() {
                                    isSliding = false;
                                  });
                                }
                              },
                            ),
                          ),
                        ),

                        // Duration
                        Text(
                          _currentDuration != Duration.zero
                              ? formatTime(_currentDuration)
                              : formatTime(elapsedDuration),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                //Delete and Record Audio
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //Delete button
                    if (_audioRecorded)
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 30,
                        ),
                        onPressed: () {
                          _removeRecordedAudio();
                        },
                      ),
                    //Record button
                    GestureDetector(
                      onTap: _isRecording ? _stopRecording : _startRecording,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            _isRecording ? Colors.red : Colors.blue,
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          //Reqeust button
          const SizedBox(height: 15),
          CustomElevatedButton(
            onTap: () async {
              if (!_audioRecorded ||
                  deliveryRequestViewModel.audioFilePath == null) {
                ToastMessageUtil.showToast(
                    "Graba un audio par pedir tu vehículo.", context);
                return;
              }
              //Upload the audio to Firebase and get its URL
              String? audioUrl =
                  await deliveryRequestViewModel.uploadRecordedAudioToStorage(
                      deliveryRequestViewModel.audioFilePath!, context);
              //Request Taxi
              if (context.mounted) {
                await deliveryRequestViewModel.writeDeliveryRequest(
                  context,
                  sharedProvider,
                  RequestType.byRecordedAudio,
                  audioFilePath: audioUrl,
                );
              }
            },
            child: const Text("Solicitar taxi"),
          ),
        ],
      ),
    );
  }
}

Widget buildRequestDriverByAudio() {
  return const ByAudioDeliveryRequest();
}
