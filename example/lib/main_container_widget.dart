import 'package:camera_macos/camera_macos_view.dart';
import 'package:camera_macos/camera_macos_controller.dart';
import 'package:camera_macos/camera_macos_file.dart';
import 'package:camera_macos/camera_macos_device.dart';
import 'package:camera_macos/camera_macos_platform_interface.dart';
import 'package:camera_macos/exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as pathJoiner;

class MainContainerWidget extends StatefulWidget {
  @override
  MainContainerWidgetState createState() => MainContainerWidgetState();
}

class MainContainerWidgetState extends State<MainContainerWidget> {
  CameraMacOSController? macOSController;
  late CameraMacOSMode cameraMode;
  late TextEditingController durationController;
  late double durationValue;
  Uint8List? lastImagePreviewData;
  Uint8List? lastRecordedVideoData;
  GlobalKey cameraKey = GlobalKey();
  List<CameraMacOSDevice> videoDevices = [];
  String? selectedVideoDevice;

  List<CameraMacOSDevice> audioDevices = [];
  String? selectedAudioDevice;

  bool enableAudio = true;
  bool usePlatformView = false;

  @override
  void initState() {
    super.initState();
    cameraMode = CameraMacOSMode.photo;
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
      case CameraMacOSMode.photo:
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
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Video Devices",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: DropdownButton<String>(
                                elevation: 3,
                                isExpanded: true,
                                value: selectedVideoDevice,
                                underline: Container(color: Colors.transparent),
                                items: videoDevices
                                    .map((CameraMacOSDevice device) {
                                  return DropdownMenuItem(
                                    value: device.deviceId,
                                    child: Text(device.deviceId),
                                  );
                                }).toList(),
                                onChanged: (String? newDeviceID) {
                                  setState(() {
                                    selectedVideoDevice = newDeviceID;
                                  });
                                },
                              ),
                            ),
                          ),
                          MaterialButton(
                            color: Colors.lightBlue,
                            textColor: Colors.white,
                            child: Text("List video devices"),
                            onPressed: listVideoDevices,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Divider(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Audio Devices",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: DropdownButton<String>(
                                elevation: 3,
                                isExpanded: true,
                                value: selectedAudioDevice,
                                underline: Container(color: Colors.transparent),
                                items: audioDevices
                                    .map((CameraMacOSDevice device) {
                                  return DropdownMenuItem(
                                    value: device.deviceId,
                                    child: Text(device.deviceId),
                                  );
                                }).toList(),
                                onChanged: (String? newDeviceID) {
                                  setState(() {
                                    selectedAudioDevice = newDeviceID;
                                  });
                                },
                              ),
                            ),
                          ),
                          MaterialButton(
                            color: Colors.lightBlue,
                            textColor: Colors.white,
                            child: Text("List audio devices"),
                            onPressed: listAudioDevices,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Divider(),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        selectedVideoDevice != null &&
                                selectedVideoDevice!.isNotEmpty
                            ? CameraMacOSView(
                                key: cameraKey,
                                deviceId: selectedVideoDevice,
                                audioDeviceId: selectedAudioDevice,
                                fit: BoxFit.fill,
                                cameraMode: CameraMacOSMode.photo,
                                onCameraInizialized:
                                    (CameraMacOSController controller) {
                                  setState(() {
                                    macOSController = controller;
                                  });
                                },
                                onCameraDestroyed: () {
                                  return Text("Camera Destroyed!");
                                },
                                enableAudio: enableAudio,
                                usePlatformView: usePlatformView,
                              )
                            : Center(
                                child: Text("Tap on List Devices first"),
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
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Settings",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 90,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            value: enableAudio,
                            contentPadding: EdgeInsets.zero,
                            tristate: false,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text("Enable Audio"),
                            onChanged: (bool? newValue) {
                              setState(() {
                                this.enableAudio = newValue ?? false;
                              });
                            },
                          ),
                          CheckboxListTile(
                            value: usePlatformView,
                            contentPadding: EdgeInsets.zero,
                            tristate: false,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                                "Use Platform View (Experimental - Not Working)"),
                            onChanged: (bool? newValue) {
                              setState(() {
                                this.usePlatformView = newValue ?? false;
                              });
                            },
                          ),
                          Text(
                            "Camera mode",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          RadioListTile(
                            title: Text("Photo"),
                            contentPadding: EdgeInsets.zero,
                            value: CameraMacOSMode.photo,
                            groupValue: cameraMode,
                            onChanged: (CameraMacOSMode? newMode) {
                              setState(() {
                                if (newMode != null) {
                                  this.cameraMode = newMode;
                                }
                              });
                            },
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text("Video"),
                                  value: CameraMacOSMode.video,
                                  groupValue: cameraMode,
                                  onChanged: (CameraMacOSMode? newMode) {
                                    setState(() {
                                      if (newMode != null) {
                                        this.cameraMode = newMode;
                                      }
                                    });
                                  },
                                ),
                              ),
                              Visibility(
                                visible: cameraMode == CameraMacOSMode.video,
                                child: Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0),
                                    child: TextField(
                                      controller: durationController,
                                      decoration: InputDecoration(
                                        labelText: "Video Length",
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Spacer(flex: 10),
                  ],
                ),
                Container(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                      onPressed: destroyCamera,
                    ),
                    MaterialButton(
                      color: Colors.lightBlue,
                      textColor: Colors.white,
                      child: Text(cameraButtonText),
                      onPressed: onCameraButtonTap,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> startRecording() async {
    try {
      String urlPath = await videoFilePath;
      await macOSController!.recordVideo(
        maxVideoDuration: durationValue,
        url: urlPath,
        enableAudio: enableAudio,
        onVideoRecordingFinished:
            (CameraMacOSFile? result, CameraMacOSException? exception) {
          setState(() {});
          if (exception != null) {
            showAlert(message: exception.toString());
          } else if (result != null) {
            showAlert(
              title: "SUCCESS",
              message: "Video saved at ${result.url}",
            );
          }
        },
      );
    } catch (e) {
      showAlert(message: e.toString());
    } finally {
      setState(() {});
    }
  }

  Future<void> listVideoDevices() async {
    try {
      List<CameraMacOSDevice> videoDevices =
          await CameraMacOS.instance.listDevices(
        deviceType: CameraMacOSDeviceType.video,
      );
      setState(() {
        this.videoDevices = videoDevices;
        if (videoDevices.isNotEmpty) {
          selectedVideoDevice = videoDevices.first.deviceId;
        }
      });
    } catch (e) {
      showAlert(message: e.toString());
    }
  }

  Future<void> listAudioDevices() async {
    try {
      List<CameraMacOSDevice> audioDevices =
          await CameraMacOS.instance.listDevices(
        deviceType: CameraMacOSDeviceType.audio,
      );
      setState(() {
        this.audioDevices = audioDevices;
        if (audioDevices.isNotEmpty) {
          selectedAudioDevice = audioDevices.first.deviceId;
        }
      });
    } catch (e) {
      showAlert(message: e.toString());
    }
  }

  void changeCameraMode() {
    setState(() {
      cameraMode = cameraMode == CameraMacOSMode.photo
          ? CameraMacOSMode.video
          : CameraMacOSMode.photo;
    });
  }

  Future<void> destroyCamera() async {
    try {
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
    } catch (e) {
      showAlert(message: e.toString());
    }
  }

  Future<void> onCameraButtonTap() async {
    try {
      if (macOSController != null) {
        switch (cameraMode) {
          case CameraMacOSMode.photo:
            CameraMacOSFile? imageData = await macOSController!.takePicture();
            if (imageData != null) {
              setState(() {
                lastImagePreviewData = imageData.bytes;
              });
              showAlert(
                title: "SUCCESS",
                message: "Image successfully created",
              );
            }
            break;
          case CameraMacOSMode.video:
            if (macOSController!.isRecording) {
              CameraMacOSFile? videoData =
                  await macOSController!.stopRecording();
              if (videoData != null) {
                setState(() {
                  lastRecordedVideoData = videoData.bytes;
                });
                showAlert(
                  title: "SUCCESS",
                  message: "Video saved at ${videoData.url}",
                );
              }
            } else {
              startRecording();
            }
            break;
        }
      }
    } catch (e) {
      showAlert(message: e.toString());
    }
  }

  Future<void> showAlert({
    String title = "ERROR",
    String message = "",
  }) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
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
}
