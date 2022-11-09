import 'package:camera_macos/camera_macos_arguments.dart';
import 'package:camera_macos/camera_macos_file.dart';
import 'package:camera_macos/camera_macos_method_channel.dart';
import 'package:camera_macos/camera_macos_platform_interface.dart';

class CameraMacOSController {
  CameraMacOSPlatform _platformInstance;
  CameraMacOSArguments _arguments;
  bool isRecording = false;

  CameraMacOSController(
    this._platformInstance,
    this._arguments,
  );

  Future<CameraMacOSFile?> takePicture() {
    return _platformInstance.takePicture();
  }

  Future<bool?> recordVideo() {
    isRecording = true;
    return _platformInstance.startVideoRecording();
  }

  Future<CameraMacOSFile?> stopRecording() {
    isRecording = false;
    return _platformInstance.stopVideoRecording();
  }

  Future<bool?> destroy() {
    return _platformInstance.destroy();
  }

  bool get isDestroyed {
    return (_platformInstance as MethodChannelCameraMacOS).isDestroyed;
  }
}
