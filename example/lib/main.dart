import 'package:camera_macos/camera_macos.dart';
import 'package:camera_macos/camera_macos_controller.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Camera MacOS Example'),
        ),
        body: Column(
          children: [
            Expanded(
              flex: 90,
              child: CameraMacOSView(
                cameraMode: CameraMacOSMode.picture,
                onCameraInizialized: (CameraMacOSController controller) {
                  setState(() {
                    macOSController = controller;
                  });
                },
              ),
            ),
            Expanded(
              flex: 10,
              child: Row(
                children: [
                  MaterialButton(
                    child: Text("Change camera mode"),
                    onPressed: () {
                      setState(() {
                        cameraMode = cameraMode == CameraMacOSMode.picture
                            ? CameraMacOSMode.video
                            : CameraMacOSMode.picture;
                      });
                    },
                  ),
                  Visibility(
                    visible: cameraMode == CameraMacOSMode.video,
                    child: TextField(
                      controller: durationController,
                      decoration: InputDecoration(
                        labelText: "Durata video",
                      ),
                    ),
                  ),
                  MaterialButton(
                    child: Text(cameraButtonText),
                    onPressed: () async {
                      if (macOSController != null) {
                        switch (cameraMode) {
                          case CameraMacOSMode.picture:
                            macOSController!.takePicture();
                            break;
                          case CameraMacOSMode.video:
                            if (macOSController!.isRecording) {
                              macOSController!.stopRecording();
                            } else {
                              macOSController!.recordVideo();
                            }
                            break;
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
