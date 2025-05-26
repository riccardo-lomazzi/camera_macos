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
    required String deviceId,
    String? audioDeviceId,
    bool enableAudio = true,
    PictureFormat pictureFormat = PictureFormat.tiff,
    VideoFormat videoFormat = VideoFormat.mp4,
    PictureResolution resolution = PictureResolution.max,
    AudioFormat audioFormat = AudioFormat.kAudioFormatAppleLossless,
    AudioQuality audioQuality = AudioQuality.max,
    Torch toggleTorch = Torch.off,
    CameraOrientation orientation = CameraOrientation.orientation0deg,
    bool isVideoMirrored = true,
    required CameraMacOSMode cameraMacOSMode,
  }) {
    throw UnimplementedError("");
  }

  Future<List<CameraMacOSDevice>> listDevices({
    CameraMacOSDeviceType? deviceType,
  }) {
    throw UnimplementedError("");
  }

  Future<CameraMacOSFile?> takePicture({
    required String deviceId,
  }) {
    throw UnimplementedError("");
  }

  Future<bool> startVideoRecording({
    required String deviceId,
    double? maxVideoDuration,
    String? url,
    bool? enableAudio,
    Function(CameraMacOSFile?, CameraMacOSException?)? onVideoRecordingFinished,
  }) {
    throw UnimplementedError("");
  }

  Future<CameraMacOSFile?> stopVideoRecording({
    required String deviceId,
  }) {
    throw UnimplementedError("");
  }

  Future<void> startImageStream(
    void Function(CameraImageData?) onAvailable, {
    required String deviceId,
    void Function(dynamic)? onError,
  }) async {
    throw UnimplementedError("");
  }

  Future<void> stopImageStream({
    required String deviceId,
  }) async {
    throw UnimplementedError("");
  }

  Future<void> setFocusPoint(
    Offset point, {
    required String deviceId,
  }) {
    throw UnimplementedError("");
  }

  Future<void> setZoomLevel(
    double zoom, {
    required String deviceId,
  }) {
    throw UnimplementedError("");
  }

  Future<void> setOrientation(
    CameraOrientation orientation, {
    required String deviceId,
  }) {
    throw UnimplementedError("");
  }

  Future<void> setVideoMirrored(
    bool isVideoMirrored, {
    required String deviceId,
  }) {
    throw UnimplementedError("");
  }

  Future<void> toggleTorch(
    Torch torch, {
    required String deviceId,
  }) {
    throw UnimplementedError("");
  }

  Future<bool?> destroy({
    required String deviceId,
  }) {
    throw UnimplementedError("");
  }
}
