import 'package:camera_macos/camera_macos.dart';
import 'package:camera_macos/camera_macos_controller.dart';
import 'package:camera_macos/camera_macos_file.dart';
import 'package:camera_macos/exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as pathJoiner;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  CameraMacOSController? macOSController;
  late CameraMacOSMode cameraMode;
  late TextEditingController durationController;
  late double durationValue;
  Uint8List? lastImagePreviewData;
  Uint8List? lastRecordedVideoData;
  GlobalKey cameraKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    cameraMode = CameraMacOSMode.picture;
    durationValue = 15;
    durationController = TextEditingController(text: "$durationValue");
    durationController.addListener(() {
      setState(() {
        double? textFieldContent = double.tryParse(durationController.text);
        if (textFieldContent == null) {
          durationValue = 15;
          durationController.text = "$durationValue";
        } else {
          durationValue = textFieldContent;
        }
      });
    });
  }

  String get cameraButtonText {
    String label = "Do something";
    switch (cameraMode) {
      case CameraMacOSMode.picture:
        label = "Take Picture";
        break;
      case CameraMacOSMode.video:
        if (macOSController?.isRecording ?? false) {
          label = "Stop recording";
        } else {
          label = "Record video";
        }
        break;
    }
    return label;
  }

  Future<String> get videoFilePath async => pathJoiner.join(
      (await getApplicationDocumentsDirectory()).path, "output.mp4");

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Camera MacOS Example'),
            ),
            body: Column(
              children: [
                Expanded(
                  flex: 90,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CameraMacOSView(
                          key: cameraKey,
                          fit: BoxFit.fill,
                          cameraMode: CameraMacOSMode.picture,
                          onCameraInizialized:
                              (CameraMacOSController controller) {
                            setState(() {
                              macOSController = controller;
                            });
                          },
                          onCameraDestroyed: () {
                            return Text("Camera Destroyed!");
                          },
                        ),
                        lastImagePreviewData != null
                            ? Container(
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    side: BorderSide(
                                      color: Colors.lightBlue,
                                      width: 10,
                                    ),
                                  ),
                                ),
                                child: Image.memory(
                                  lastImagePreviewData!,
                                  height: 50,
                                  width: 90,
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        MaterialButton(
                          color: Colors.lightBlue,
                          textColor: Colors.white,
                          child: Text("Change camera mode"),
                          onPressed: () {
                            setState(() {
                              cameraMode = cameraMode == CameraMacOSMode.picture
                                  ? CameraMacOSMode.video
                                  : CameraMacOSMode.picture;
                            });
                          },
                        ),
                        MaterialButton(
                          color: Colors.red,
                          textColor: Colors.white,
                          child: Builder(
                            builder: (context) {
                              String buttonText = "Destroy";
                              if (macOSController != null &&
                                  macOSController!.isDestroyed) {
                                buttonText = "Reinitialize";
                              }
                              return Text(buttonText);
                            },
                          ),
                          onPressed: () async {
                            if (macOSController != null) {
                              if (macOSController!.isDestroyed) {
                                setState(() {
                                  cameraKey = GlobalKey();
                                });
                              } else {
                                await macOSController?.destroy();
                                setState(() {});
                              }
                            }
                          },
                        ),
                        Visibility(
                          visible: cameraMode == CameraMacOSMode.video,
                          child: Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: TextField(
                                controller: durationController,
                                decoration: InputDecoration(
                                  labelText: "Durata video",
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                        MaterialButton(
                          color: Colors.lightBlue,
                          textColor: Colors.white,
                          child: Text(cameraButtonText),
                          onPressed: () async {
                            try {
                              if (macOSController != null) {
                                switch (cameraMode) {
                                  case CameraMacOSMode.picture:
                                    CameraMacOSFile? imageData =
                                        await macOSController!.takePicture();
                                    if (imageData != null) {
                                      setState(() {
                                        lastImagePreviewData = imageData.bytes;
                                      });
                                    }
                                    break;
                                  case CameraMacOSMode.video:
                                    if (macOSController!.isRecording) {
                                      CameraMacOSFile? videoData =
                                          await macOSController!
                                              .stopRecording();
                                      if (videoData != null) {
                                        setState(() {
                                          lastRecordedVideoData =
                                              videoData.bytes;
                                        });
                                      }
                                    } else {
                                      startRecording();
                                    }
                                    break;
                                }
                              }
                            } catch (e) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    content: Text(e.toString()),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> startRecording() async {
    String urlPath = await videoFilePath;
    await macOSController!.recordVideo(
      maxVideoDuration: durationValue,
      url: urlPath,
      onVideoRecordingFinished:
          (Map<String, dynamic>? result, CameraMacOSException? exception) {
        setState(() {});
        if (exception != null) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Text(exception.toString()),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      },
    );
    setState(() {});
  }
}
