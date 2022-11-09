import 'package:camera_macos/camera_macos.dart';
import 'package:camera_macos/camera_macos_arguments.dart';
import 'package:camera_macos/camera_macos_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'camera_macos_platform_interface.dart';

/// An implementation of [CameraMacosPlatform] that uses method channels.
class MethodChannelCameraMacOS extends CameraMacOSPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('camera_macos');

  bool methodCallHandlerSet = false;

  @override
  Future<CameraMacOSArguments?> initialize({
    required CameraMacOSMode cameraMacOSMode,
  }) async {
    try {
      final Map<String, dynamic>? args =
          await methodChannel.invokeMapMethod<String, dynamic>(
        'initialize',
        {
          "type": cameraMacOSMode.index,
        },
      );
      if (args == null) {
        throw FlutterError("Invalid args: invalid platform response");
      }
      return CameraMacOSArguments(
        textureId: args["textureId"],
        size: Size(
          args["size"]?["width"] ?? 0,
          args["size"]?["height"] ?? 0,
        ),
      );
    } catch (e) {
      return Future.error(e);
    }
  }

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
        return result["imageData"] as CameraMacOSFile?;
      }
    } catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<bool> startVideoRecording({double? maxVideoDuration}) async {
    try {
      final result = await methodChannel.invokeMethod(
            'startRecording',
            {
              "maxVideoDuration": maxVideoDuration,
            },
          ) as bool? ??
          false;
      return result;
    } catch (e) {
      return Future.error(e);
    }
  }

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
        return CameraMacOSFile(
          bytes: result["videoData"] as Uint8List?,
        );
      }
    } catch (e) {
      return Future.error(e);
    }
  }
}
