import 'dart:typed_data';

import 'package:camera_macos/camera_macos_device.dart';
import 'package:flutter/material.dart';

enum PictureFormat { jpg, jpeg, tiff, bmp, png }

enum VideoFormat { m4v, mov, mp4 }

enum PictureResolution {
  /// 480p (640x480)
  low,

  /// 540p (960x540)
  medium,

  /// 720p (1280x720)
  high,

  /// 1080p (1920x1080)
  veryHigh,

  /// 2160p (3840x2160)
  ultraHigh,

  /// The highest resolution available.
  max,
}

class CameraImageData {
  CameraImageData(
      {required this.width, required this.height, required this.bytes});

  final int width;
  final int height;
  final Uint8List bytes;

  @override
  String toString() {
    return {
      'width': width,
      'height': height,
      'size': bytes.length,
    }.toString();
  }
}

class CameraMacOSArguments {
  /// The texture id.
  final int? textureId;

  /// Size of the texture.
  final Size size;

  /// Chosen device
  final List<CameraMacOSDevice>? devices;

  /// Create a [CameraMacOSArguments].
  CameraMacOSArguments({
    this.textureId,
    required this.size,
    this.devices,
  });
}
