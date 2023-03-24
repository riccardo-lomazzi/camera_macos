import 'package:camera_macos/camera_macos_view.dart';
import 'package:camera_macos/camera_macos_arguments.dart';
import 'package:camera_macos/camera_macos_device.dart';
import 'package:camera_macos/camera_macos_file.dart';
import 'package:camera_macos/exceptions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'camera_macos_platform_interface.dart';

/// An implementation of [CameraMacosPlatform] that uses method channels.
class MethodChannelCameraMacOS extends CameraMacOSPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('camera_macos');

  bool methodCallHandlerSet = false;

  bool isRecording = false;
  bool isDestroyed = false;

  Map<String, Function?> registeredCallbacks = {};

  /// Call this method to discover all camera devices.
  @override
  Future<List<CameraMacOSDevice>> listDevices(
      {CameraMacOSDeviceType? deviceType}) async {
    try {
      final Map<String, dynamic>? args =
          await methodChannel.invokeMapMethod<String, dynamic>(
        'listDevices',
        {
          "deviceType": deviceType?.index,
        },
      );
      if (args == null || args["devices"] == null) {
        throw FlutterError("Invalid args: invalid platform response");
      }
      List<Map<String, dynamic>> devicesList = List.from(args["devices"] ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      List<CameraMacOSDevice> devices = [];
      for (Map<String, dynamic> m in devicesList) {
        CameraMacOSDevice device = CameraMacOSDevice.fromMap(m);
        devices.add(device);
      }
      return devices;
    } catch (e) {
      return Future.error(e);
    }
  }

  /// Call this method to initialize camera. If you implement the widget in your widget tree, this method is useless.
  @override
  Future<CameraMacOSArguments?> initialize({
    /// initialize the camera with a video device. If null, the macOS default camera is chosen
    String? deviceId,

    /// initialize the camera with an audio device. If null, the macOS default microphone is chosen
    String? audioDeviceId,

    /// Photo or Video
    required CameraMacOSMode cameraMacOSMode,

    /// Enable Audio Recording
    bool enableAudio = true,
  }) async {
    try {
      final Map<String, dynamic>? args =
          await methodChannel.invokeMapMethod<String, dynamic>(
        'initialize',
        {
          "deviceId": deviceId,
          "audioDeviceId": audioDeviceId,
          "type": cameraMacOSMode.index,
          "enableAudio": enableAudio,
        },
      );
      if (args == null) {
        throw FlutterError("Invalid args: invalid platform response");
      }
      isDestroyed = false;
      List<Map<String, dynamic>> devicesList = List.from(args["devices"] ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      List<CameraMacOSDevice> devices = [];
      for (Map<String, dynamic> m in devicesList) {
        CameraMacOSDevice device = CameraMacOSDevice.fromMap(m);
        devices.add(device);
      }
      return CameraMacOSArguments(
        textureId: args["textureId"],
        size: Size(
          args["size"]?["width"] ?? 0,
          args["size"]?["height"] ?? 0,
        ),
        devices: devices,
      );
    } catch (e) {
      return Future.error(e);
    }
  }

  /// Call this method to take a picture.
  @override
  Future<CameraMacOSFile?> takePicture() async {
    try {
      final Map<String, dynamic>? result =
          await methodChannel.invokeMapMethod<String, dynamic>('takePicture');
      if (result == null) {
        throw FlutterError("Invalid result");
      }
      if (result["error"] != null) {
        throw result["error"];
      } else {
        return CameraMacOSFile(bytes: result["imageData"] as Uint8List?);
      }
    } catch (e) {
      return Future.error(e);
    }
  }

  /// Call this method to start a video recording.
  @override
  Future<bool> startVideoRecording({
    /// Max video duration, expressed in seconds
    double? maxVideoDuration,

    /// Enable audio (this flag overrides the initializion parameter of the same name)
    bool? enableAudio,

    /// A URL location to save the video
    String? url,

    /// Called only when the video has reached the max duration pointed by maxVideoDuration
    Function(CameraMacOSFile?, CameraMacOSException?)? onVideoRecordingFinished,
  }) async {
    try {
      registeredCallbacks["onVideoRecordingFinished"] =
          onVideoRecordingFinished;
      if (!methodCallHandlerSet) {
        methodChannel.setMethodCallHandler(_genericMethodCallHandler);
        methodCallHandlerSet = true;
      }
      final Map<String, dynamic>? result =
          await methodChannel.invokeMapMethod<String, dynamic>(
        'startRecording',
        {
          "maxVideoDuration": maxVideoDuration,
          "url": url,
          "enableAudio": enableAudio,
        },
      );
      if (result == null) {
        throw FlutterError("Invalid result");
      }
      if (result["error"] != null) {
        throw result["error"];
      } else {
        isRecording = true;
        return isRecording;
      }
    } catch (e) {
      isRecording = false;
      return Future.error(e);
    }
  }

  /// Call this method to stop video recording and collect the video data.
  @override
  Future<CameraMacOSFile?> stopVideoRecording() async {
    try {
      final Map<String, dynamic>? result =
          await methodChannel.invokeMapMethod<String, dynamic>('stopRecording');
      if (result == null) {
        throw FlutterError("Invalid result");
      }
      if (result["error"] != null) {
        throw result["error"];
      } else {
        isRecording = false;
        return CameraMacOSFile(
          bytes: result["videoData"] as Uint8List?,
          url: result["url"] as String?,
        );
      }
    } catch (e) {
      isRecording = false;
      return Future.error(e);
    }
  }

  /// Destroy the camera instance
  @override
  Future<bool?> destroy() async {
    try {
      final bool result = await methodChannel.invokeMethod('destroy') ?? false;
      isDestroyed = result;
      isRecording = false;
      return result;
    } catch (e) {
      return Future.error(e);
    }
  }

  Future<void> _genericMethodCallHandler(MethodCall call) async {
    switch (call.method) {
      case "onVideoRecordingFinished":
        isRecording = false;
        if (registeredCallbacks["onVideoRecordingFinished"] != null) {
          dynamic args = call.arguments;
          CameraMacOSFile? result;
          CameraMacOSException? exception;
          if (args is Map<String, dynamic>) {
            if (args["error"] != null) {
              exception = CameraMacOSException.fromMap(args["error"]);
            }
            result = CameraMacOSFile(
              bytes: args["videoData"] as Uint8List?,
              url: args["url"] as String?,
            );
          }
          registeredCallbacks["onVideoRecordingFinished"]!(result, exception);
        }
        break;
      default:
        break;
    }
  }
}
