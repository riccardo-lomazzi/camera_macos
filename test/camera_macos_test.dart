import 'package:camera_macos/camera_macos_view.dart';
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
  Future<CameraMacOSArguments?> initialize(
      {String? deviceId,
      String? audioDeviceId,
      required CameraMacOSMode cameraMacOSMode}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> startVideoRecording({
    CameraMacOSDevice? device,
    double? maxVideoDuration,
    String? url,
    Function(CameraMacOSFile?, CameraMacOSException?)? onVideoRecordingFinished,
  }) {
    // TODO: implement recordVideo
    throw UnimplementedError();
  }

  @override
  Future<CameraMacOSFile?> stopVideoRecording() {
    // TODO: implement stopRecording
    throw UnimplementedError();
  }

  @override
  Future<CameraMacOSFile?> takePicture() {
    // TODO: implement takePicture
    throw UnimplementedError();
  }

  @override
  Future<bool> destroy() {
    // TODO: implement destroy
    throw UnimplementedError();
  }

  @override
  Future<List<CameraMacOSDevice>> listDevices(
      {CameraMacOSDeviceType? deviceType}) {
    // TODO: implement listDevices
    throw UnimplementedError();
  }
}

void main() {
  final CameraMacOSPlatform initialPlatform = CameraMacOSPlatform.instance;

  test('$MethodChannelCameraMacOS is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCameraMacOS>());
  });
}
