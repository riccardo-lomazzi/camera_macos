import 'package:camera_macos/camera_macos_arguments.dart';
import 'package:camera_macos/camera_macos_platform_interface.dart';
import 'package:flutter/foundation.dart';

class CameraMacOSController {
  CameraMacOSPlatform _platformInstance;
  CameraMacOSArguments _arguments;
  bool isRecording = false;

  CameraMacOSController(
    this._platformInstance,
    this._arguments,
  );

  Future<Uint8List?> takePicture() {
    return _platformInstance.takePicture();
  }

  Future<bool?> recordVideo() {
    isRecording = true;
    return _platformInstance.startVideoRecording();
  }

  Future<String?> stopRecording() {
    isRecording = false;
    return _platformInstance.stopVideoRecording();
  }
}
