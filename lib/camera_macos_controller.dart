import 'package:camera_macos/camera_macos_arguments.dart';
import 'package:camera_macos/camera_macos_file.dart';
import 'package:camera_macos/camera_macos_method_channel.dart';
import 'package:camera_macos/camera_macos_platform_interface.dart';

class CameraMacOSController {
  CameraMacOSPlatform _platformInstance;
  CameraMacOSArguments _arguments;

  CameraMacOSController(
    this._platformInstance,
    this._arguments,
  );

  Future<CameraMacOSFile?> takePicture() {
    return _platformInstance.takePicture();
  }

  Future<bool?> recordVideo({double? maxVideoDuration, String? url}) {
    return _platformInstance.startVideoRecording(
        maxVideoDuration: maxVideoDuration, url: url);
  }

  Future<CameraMacOSFile?> stopRecording() {
    return _platformInstance.stopVideoRecording();
  }

  Future<bool?> destroy() {
    return _platformInstance.destroy();
  }

  bool get isRecording =>
      (_platformInstance as MethodChannelCameraMacOS).isRecording;
  bool get isDestroyed =>
      (_platformInstance as MethodChannelCameraMacOS).isDestroyed;
}
