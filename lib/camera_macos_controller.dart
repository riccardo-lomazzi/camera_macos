import 'package:camera_macos/camera_macos_file.dart';
import 'package:camera_macos/camera_macos_method_channel.dart';
import 'package:camera_macos/camera_macos_platform_interface.dart';
import 'package:camera_macos/exceptions.dart';

class CameraMacOSController {
  CameraMacOSPlatform _platformInstance;

  CameraMacOSController(
    this._platformInstance,
  );

  Future<CameraMacOSFile?> takePicture() {
    return _platformInstance.takePicture();
  }

  Future<bool?> recordVideo({
    double? maxVideoDuration,
    String? url,
    Function(CameraMacOSFile?, CameraMacOSException?)? onVideoRecordingFinished,
  }) {
    return _platformInstance.startVideoRecording(
      maxVideoDuration: maxVideoDuration,
      url: url,
      onVideoRecordingFinished: onVideoRecordingFinished,
    );
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
