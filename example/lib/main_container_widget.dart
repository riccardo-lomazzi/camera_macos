import 'dart:io';

import 'package:camera_macos/camera_macos_arguments.dart';
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
import 'package:url_launcher/url_launcher.dart';

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
  PictureResolution selectedPictureResolution = PictureResolution.max;
  PictureFormat selectedPictureFormat = PictureFormat.tiff;
  VideoFormat selectedVideoFormat = VideoFormat.mp4;
  File? lastPictureTaken;

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

  Future<String> get imageFilePath async => pathJoiner.join(
      (await getApplicationDocumentsDirectory()).path,
      "P_${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}_${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}.${selectedPictureFormat.name.replaceAll("PictureFormat.", "")}");

  Future<String> get videoFilePath async => pathJoiner.join(
      (await getApplicationDocumentsDirectory()).path,
      "V_${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}_${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}.${selectedVideoFormat.name.replaceAll("VideoFormat.", "")}");

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
                                resolution: selectedPictureResolution,
                                pictureFormat: selectedPictureFormat,
                                videoFormat: selectedVideoFormat,
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
                            ? InkWell(
                                onTap: openPicture,
                                child: Container(
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
                                ),
                              )
                            : const SizedBox.shrink(),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Resolution
                              Column(
                                children: [
                                  Text("Saved Resolution"),
                                  DropdownButton<PictureResolution>(
                                    value: selectedPictureResolution,
                                    onChanged: (PictureResolution? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          this.selectedPictureResolution =
                                              newValue;
                                        });
                                      }
                                    },
                                    items:
                                        PictureResolution.values.map((element) {
                                      return DropdownMenuItem(
                                        value: element,
                                        child: Text(element.name),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),

                              // PictureFormat
                              Column(
                                children: [
                                  Text("Saved Picture Format"),
                                  DropdownButton<PictureFormat>(
                                    value: selectedPictureFormat,
                                    onChanged: (PictureFormat? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          this.selectedPictureFormat = newValue;
                                        });
                                      }
                                    },
                                    items: PictureFormat.values.map((element) {
                                      return DropdownMenuItem(
                                        value: element,
                                        child: Text(element.name),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ],
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
                          RadioListTile(
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
                          Visibility(
                            visible: cameraMode == CameraMacOSMode.video,
                            child: Row(
                              children: [
                                Flexible(
                                  flex: 20,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0),
                                    child: TextField(
                                      controller: durationController,
                                      decoration: InputDecoration(
                                        labelText: "Video Length (in seconds)",
                                      ),
                                    ),
                                  ),
                                ),
                                // VideoFormat
                                Flexible(
                                  flex: 80,
                                  child: Column(
                                    children: [
                                      Text("Video Format"),
                                      DropdownButton<VideoFormat>(
                                        value: selectedVideoFormat,
                                        onChanged: (VideoFormat? newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              this.selectedVideoFormat =
                                                  newValue;
                                            });
                                          }
                                        },
                                        items:
                                            VideoFormat.values.map((element) {
                                          return DropdownMenuItem(
                                            value: element,
                                            child: Text(element.name),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
                    macOSController != null
                        ? Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: MaterialButton(
                              color: Colors.lightBlue,
                              textColor: Colors.white,
                              child: Text(
                                macOSController!.isStreamingImageData
                                    ? "Stop Streaming Image Data"
                                    : "Stream Image Data",
                              ),
                              onPressed: macOSController!.isStreamingImageData
                                  ? stopImageStream
                                  : startImageStream,
                            ),
                          )
                        : const SizedBox.shrink(),
                    Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: MaterialButton(
                        color: Colors.lightBlue,
                        textColor: Colors.white,
                        child: Text("Open Output Folder"),
                        onPressed: openOutputFolder,
                      ),
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
                savePicture(lastImagePreviewData!);
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

  Future<void> savePicture(Uint8List photoBytes) async {
    try {
      String filename = await imageFilePath;
      File f = File(filename);
      if (f.existsSync()) {
        f.deleteSync(recursive: true);
      }
      f.createSync(recursive: true);
      f.writeAsBytesSync(photoBytes);
      lastPictureTaken = f;
    } catch (e) {
      showAlert(message: e.toString());
    }
  }

  Future<void> openPicture() async {
    try {
      if (lastPictureTaken != null) {
        Uri uriPath = Uri.file(lastPictureTaken!.path);
        if (await canLaunchUrl(uriPath)) {
          await launchUrl(uriPath);
        }
      }
    } catch (e) {
      showAlert(message: e.toString());
    }
  }

  Future<void> openOutputFolder() async {
    try {
      Uri uriPath =
          Uri.directory((await getApplicationDocumentsDirectory()).path);
      if (await canLaunchUrl(uriPath)) {
        await launchUrl(uriPath);
      }
    } catch (e) {
      showAlert(message: e.toString());
    }
  }

  void startImageStream() async {
    try {
      if (macOSController != null && !macOSController!.isStreamingImageData) {
        print("Started streaming");
        setState(() {
          macOSController!.startImageStream(
            (p0) {
              print(p0.toString());
            },
          );
        });
      }
    } catch (e) {
      showAlert(message: e.toString());
    }
  }

  void stopImageStream() async {
    try {
      if (macOSController != null && macOSController!.isStreamingImageData) {
        setState(() {
          macOSController!.stopImageStream();
          print("Stopped streaming");
        });
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
