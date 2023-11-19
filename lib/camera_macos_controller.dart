import 'package:camera_macos/camera_macos_arguments.dart';
import 'package:camera_macos/camera_macos_file.dart';
import 'package:camera_macos/camera_macos_method_channel.dart';
import 'package:camera_macos/camera_macos_platform_interface.dart';
import 'package:camera_macos/exceptions.dart';
import 'package:flutter/services.dart';

class CameraMacOSController {
  late CameraMacOSArguments args;

  CameraMacOSController(this.args);

  CameraMacOSPlatform get _platformInstance => CameraMacOSPlatform.instance;

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

    /// Enable audio (this flag overrides the initialization setting)
    bool? enableAudio,

    /// Called only when the video has reached the max duration pointed by maxVideoDuration
    Function(CameraMacOSFile?, CameraMacOSException?)? onVideoRecordingFinished,
  }) {
    return _platformInstance.startVideoRecording(
      maxVideoDuration: maxVideoDuration,
      enableAudio: enableAudio,
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

  /// Turn light on
  Future<void> toggleTorch(Torch torch) async {
    _platformInstance.toggleTorch(torch);
  }

  /// Stream current argb image
  Future<void> startImageStream(
      void Function(CameraImageData) onAvailable) async {
    _platformInstance.startImageStream(onAvailable);
  }

  /// Stop the image from streaming
  Future<void> stopImageStream() async {
    _platformInstance.stopImageStream();
  }

  /// Set a new focus point in the image
  Future<void> setFocusPoint(Offset point) async {
    _platformInstance.setFocusPoint(point);
  }

  Future<void> setZoomLevel(double zoom) async {
    _platformInstance.setZoomLevel(zoom);
  }

  Future<void> setOrientation(CameraOrientation orientation) async {
    _platformInstance.setOrientation(orientation);
  }

  /// Getter that checks if a video is currently recording
  bool get isRecording =>
      (_platformInstance as MethodChannelCameraMacOS).isRecording;

  /// Getter that checks if a camera instance has been destroyed or not initiliazed yet.
  bool get isDestroyed =>
      (_platformInstance as MethodChannelCameraMacOS).isDestroyed;

  /// Getter that checks if the image stream is running
  bool get isStreamingImageData =>
      (_platformInstance as MethodChannelCameraMacOS).isStreamingImageData;
}
