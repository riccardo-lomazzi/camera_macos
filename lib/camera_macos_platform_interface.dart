import 'package:camera_macos/camera_macos.dart';
import 'package:flutter/material.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'camera_macos_method_channel.dart';

typedef CameraMacOS = CameraMacOSPlatform;

abstract class CameraMacOSPlatform extends PlatformInterface {
  /// Constructs a CameraMacOSPlatform.
  CameraMacOSPlatform() : super(token: _token);

  static final Object _token = Object();

  static CameraMacOSPlatform _instance = MethodChannelCameraMacOS();

  /// The default instance of [CameraMacOSPlatform] to use.
  ///
  /// Defaults to [MethodChannelCameraMacos].
  static CameraMacOSPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CameraMacOSPlatform] when
  /// they register themselves.
  static set instance(CameraMacOSPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<CameraMacOSArguments?> initialize({
    String? deviceId,
    String? audioDeviceId,
    bool enableAudio = true,
    PictureFormat pictureFormat = PictureFormat.tiff,
    VideoFormat videoFormat = VideoFormat.mp4,
    PictureResolution resolution = PictureResolution.max,
    AudioFormat audioFormat = AudioFormat.kAudioFormatAppleLossless,
    AudioQuality audioQuality = AudioQuality.max,
    Torch toggleTorch = Torch.off,
    CameraOrientation orientation = CameraOrientation.orientation0deg,
    required CameraMacOSMode cameraMacOSMode,
  }) {
    throw UnimplementedError("");
  }

  Future<List<CameraMacOSDevice>> listDevices(
      {CameraMacOSDeviceType? deviceType}) {
    throw UnimplementedError("");
  }

  Future<CameraMacOSFile?> takePicture() {
    throw UnimplementedError("");
  }

  Future<bool> startVideoRecording({
    double? maxVideoDuration,
    String? url,
    bool? enableAudio,
    Function(CameraMacOSFile?, CameraMacOSException?)? onVideoRecordingFinished,
  }) {
    throw UnimplementedError("");
  }

  Future<CameraMacOSFile?> stopVideoRecording() {
    throw UnimplementedError("");
  }

  Future<void> startImageStream(
      void Function(CameraImageData) onAvailable) async {
    throw UnimplementedError("");
  }

  Future<void> stopImageStream() async {
    throw UnimplementedError("");
  }

  Future<void> setFocusPoint(Offset point) {
    throw UnimplementedError("");
  }

  Future<void> setZoomLevel(double zoom) {
    throw UnimplementedError("");
  }

  Future<void> setOrientation(CameraOrientation orientation) {
    throw UnimplementedError("");
  }

  Future<void> toggleTorch(Torch torch) {
    throw UnimplementedError("");
  }

  Future<bool?> destroy() {
    throw UnimplementedError("");
  }
}
