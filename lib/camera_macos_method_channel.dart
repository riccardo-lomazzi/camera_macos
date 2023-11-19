import 'dart:async';
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
  static const EventChannel eventChannel = EventChannel('camera_macos/stream');
  StreamSubscription? events;

  bool methodCallHandlerSet = false;

  bool isRecording = false;
  bool isDestroyed = false;

  Map<String, Function?> registeredCallbacks = {};

  bool get isStreamingImageData => events != null && !events!.isPaused;

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
  Future<CameraMacOSArguments?> initialize(
      {
      /// initialize the camera with a video device. If null, the macOS default camera is chosen
      String? deviceId,

      /// initialize the camera with an audio device. If null, the macOS default microphone is chosen
      String? audioDeviceId,

      /// Photo or Video
      required CameraMacOSMode cameraMacOSMode,

      /// format of the output photo
      PictureFormat pictureFormat = PictureFormat.tiff,

      /// format of the output photo
      VideoFormat videoFormat = VideoFormat.mp4,

      /// resolution of the output video/image
      PictureResolution resolution = PictureResolution.max,

      /// Enable Audio Recording
      bool enableAudio = true,

      /// Change the videos audio format type
      AudioFormat audioFormat = AudioFormat.kAudioFormatAppleLossless,
      AudioQuality audioQuality = AudioQuality.max,

      /// Enable light
      Torch toggleTorch = Torch.off,

      /// Set camera orientation
      CameraOrientation orientation =
          CameraOrientation.orientation0deg}) async {
    try {
      final Map<String, dynamic>? result =
          await methodChannel.invokeMapMethod<String, dynamic>(
        'initialize',
        {
          "deviceId": deviceId,
          "audioDeviceId": audioDeviceId,
          "type": cameraMacOSMode.index,
          "enableAudio": enableAudio,
          'resolution': resolution.name,
          'quality': audioQuality.name,
          'orientation': orientation.index * 90.0,
          'torch': toggleTorch.index,
          'pformat': pictureFormat.name,
          'vformat': videoFormat.name,
          'aformat': audioFormat.index,
        },
      );
      if (result == null) {
        throw FlutterError("Invalid args: invalid platform response");
      }
      if (result["error"] != null) {
        throw result["error"];
      }
      isDestroyed = false;
      List<Map<String, dynamic>> devicesList =
          List.from(result["devices"] ?? [])
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
      List<CameraMacOSDevice> devices = [];
      for (Map<String, dynamic> m in devicesList) {
        CameraMacOSDevice device = CameraMacOSDevice.fromMap(m);
        devices.add(device);
      }
      return CameraMacOSArguments(
        textureId: result["textureId"],
        size: Size(
          result["size"]?["width"] ?? 0,
          result["size"]?["height"] ?? 0,
        ),
        devices: devices,
      );
    } catch (e) {
      return Future.error(e);
    }
  }

  /// Call this method to take a picture.
  @override
  Future<CameraMacOSFile?> takePicture(
      {PictureFormat format = PictureFormat.tiff,
      PictureResolution resolution = PictureResolution.max}) async {
    try {
      final Map<String, dynamic>? result = await methodChannel
          .invokeMapMethod<String, dynamic>('takePicture',
              {'format': format.name, 'resolution': resolution.name});
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
      events?.cancel();
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
          if (args is Map) {
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

  @override
  Future<void> startImageStream(
      void Function(CameraImageData image) onAvailable) async {
    events = eventChannel.receiveBroadcastStream().listen((data) {
      onAvailable(CameraImageData(
          width: data['width'],
          height: data['height'],
          bytesPerRow: data['bytesPerRow'],
          bytes: Uint8List.fromList(data['data'])));
    });
  }

  @override
  Future<void> stopImageStream() async {
    events?.cancel();
  }

  @override
  Future<void> toggleTorch(Torch torch) {
    return methodChannel.invokeMethod<void>(
      'toggleTorch',
      <String, dynamic>{
        'torch': torch.index,
      },
    );
  }

  @override
  Future<void> setFocusPoint(Offset point) {
    assert(point.dx >= 0 && point.dx <= 1);
    assert(point.dy >= 0 && point.dy <= 1);

    return methodChannel.invokeMethod<void>(
      'setFocusPoint',
      <String, dynamic>{
        'x': point.dx,
        'y': point.dy,
      },
    );
  }

  @override
  Future<void> setZoomLevel(double zoom) {
    assert(zoom >= 0 && zoom <= 10.0);

    return methodChannel.invokeMethod<void>(
      'setZoom',
      <String, dynamic>{
        'zoom': zoom,
      },
    );
  }

  @override
  Future<void> setOrientation(CameraOrientation orientation) {
    return methodChannel.invokeMethod<void>(
      'setOrientation',
      <String, dynamic>{
        'orientation': orientation.index,
      },
    );
  }
}
