import 'package:camera_macos/camera_macos_arguments.dart';
import 'package:camera_macos/camera_macos_device.dart';
import 'package:camera_macos/camera_macos_file.dart';
import 'package:camera_macos/camera_macos_method_channel.dart';
import 'package:camera_macos/camera_macos_platform_interface.dart';
import 'package:camera_macos/exceptions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCameraMacOSPlatform
    with MockPlatformInterfaceMixin
    implements CameraMacOSPlatform {
  @override
  Future<CameraMacOSArguments?> initialize({
    String? deviceId,
    String? audioDeviceId,
    bool enableAudio = true,
    PictureFormat pictureFormat = PictureFormat.tiff,
    VideoFormat videoFormat = VideoFormat.mp4,
    PictureResolution resolution = PictureResolution.max,
    required CameraMacOSMode cameraMacOSMode,
    AudioFormat audioFormat = AudioFormat.kAudioFormatAppleLossless,
    AudioQuality audioQuality = AudioQuality.max,
    Torch toggleTorch = Torch.off,
    CameraOrientation orientation = CameraOrientation.orientation0deg,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> startVideoRecording({
    CameraMacOSDevice? device,
    double? maxVideoDuration,
    String? url,
    bool? enableAudio,
    Function(CameraMacOSFile?, CameraMacOSException?)? onVideoRecordingFinished,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CameraMacOSFile?> stopVideoRecording() {
    throw UnimplementedError();
  }

  @override
  Future<CameraMacOSFile?> takePicture() {
    throw UnimplementedError();
  }

  @override
  Future<bool> destroy() {
    throw UnimplementedError();
  }

  @override
  Future<List<CameraMacOSDevice>> listDevices(
      {CameraMacOSDeviceType? deviceType}) {
    throw UnimplementedError();
  }

  @override
  Future<void> startImageStream(
      void Function(CameraImageData) onAvailable) async {
    throw UnimplementedError("");
  }

  @override
  Future<void> stopImageStream() async {
    throw UnimplementedError("");
  }

  @override
  Future<void> setFocusPoint(Offset? point) {
    throw UnimplementedError("");
  }

  @override
  Future<void> setZoomLevel(double zoom) {
    throw UnimplementedError("");
  }

  @override
  Future<void> setOrientation(CameraOrientation orientation) {
    throw UnimplementedError("");
  }

  @override
  Future<void> toggleTorch(Torch torch) {
    throw UnimplementedError("");
  }
}

void main() {
  final CameraMacOSPlatform initialPlatform = CameraMacOSPlatform.instance;

  test('$MethodChannelCameraMacOS is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCameraMacOS>());
  });
}
