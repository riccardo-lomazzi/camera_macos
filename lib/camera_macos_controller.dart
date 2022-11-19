import 'package:camera_macos/camera_macos_file.dart';
import 'package:camera_macos/camera_macos_method_channel.dart';
import 'package:camera_macos/camera_macos_platform_interface.dart';
import 'package:camera_macos/exceptions.dart';

class CameraMacOSController {
  CameraMacOSPlatform _platformInstance;

  CameraMacOSController(
    this._platformInstance,
  );

  /// Call this method to take a picture.
  Future<CameraMacOSFile?> takePicture() {
    return _platformInstance.takePicture();
  }

  /// Call this method to start a video recording.
  Future<bool?> recordVideo({
    /// Expressed in seconds
    double? maxVideoDuration,

    /// A URL location to save the video. Default is Library/Cache directory of the application.
    String? url,

    /// Called only when the video has reached the max duration pointed by maxVideoDuration
    Function(CameraMacOSFile?, CameraMacOSException?)? onVideoRecordingFinished,
  }) {
    return _platformInstance.startVideoRecording(
      maxVideoDuration: maxVideoDuration,
      url: url,
      onVideoRecordingFinished: onVideoRecordingFinished,
    );
  }

  /// Call this method to stop video recording and collect the video data.
  Future<CameraMacOSFile?> stopRecording() {
    return _platformInstance.stopVideoRecording();
  }

  /// Destroy the camera instance
  Future<bool?> destroy() {
    return _platformInstance.destroy();
  }

  /// Getter that checks if a video is currently recording
  bool get isRecording =>
      (_platformInstance as MethodChannelCameraMacOS).isRecording;

  /// Getter that checks if a camera instance has been destroyed or not initiliazed yet.
  bool get isDestroyed =>
      (_platformInstance as MethodChannelCameraMacOS).isDestroyed;
}
