import 'package:camera_macos/camera_macos_arguments.dart';
import 'package:camera_macos/camera_macos_controller.dart';
import 'package:camera_macos/camera_macos_method_channel.dart';
import 'package:flutter/material.dart';

import 'camera_macos_platform_interface.dart';

class CameraMacOSView extends StatefulWidget {
  /// Handles how the widget should fit the screen.
  final BoxFit fit;

  final String? deviceId;
  final String? audioDeviceId;
  final bool enableAudio;
  final CameraMacOSMode cameraMode;
  final Widget Function(Object?)? onCameraLoading;
  final Function(CameraMacOSController) onCameraInizialized;
  final Widget Function()? onCameraDestroyed;

  const CameraMacOSView({
    Key? key,
    this.deviceId,
    this.audioDeviceId,
    this.enableAudio = true,
    this.fit = BoxFit.contain,
    required this.cameraMode,
    required this.onCameraInizialized,
    this.onCameraLoading,
    this.onCameraDestroyed,
  }) : super(key: key);

  @override
  CameraMacOSViewState createState() => CameraMacOSViewState();
}

class CameraMacOSViewState extends State<CameraMacOSView> {
  late CameraMacOSArguments arguments;
  late Future<CameraMacOSArguments?> initializeCameraFuture;

  @override
  void initState() {
    super.initState();
    initializeCameraFuture = CameraMacOSPlatform.instance
        .initialize(
      deviceId: widget.deviceId,
      audioDeviceId: widget.audioDeviceId,
      cameraMacOSMode: widget.cameraMode,
      enableAudio: widget.enableAudio,
    )
        .then((value) {
      if (value != null) {
        this.arguments = value;
        widget.onCameraInizialized(
          CameraMacOSController(value),
        );
      }
      return value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initializeCameraFuture,
      builder: (BuildContext context,
          AsyncSnapshot<CameraMacOSArguments?> snapshot) {
        if (snapshot.hasError) {
          if (widget.onCameraLoading != null) {
            return widget.onCameraLoading!(snapshot.error);
          } else {
            return const ColoredBox(color: Colors.black);
          }
        }
        if (!snapshot.hasData) {
          if (widget.onCameraLoading != null) {
            return widget.onCameraLoading!(null);
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        }

        if (CameraMacOSPlatform.instance is MethodChannelCameraMacOS &&
            (CameraMacOSPlatform.instance as MethodChannelCameraMacOS)
                .isDestroyed) {
          if (widget.onCameraDestroyed != null) {
            return widget.onCameraDestroyed!();
          } else {
            return Container();
          }
        }

        return ClipRect(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: FittedBox(
              fit: widget.fit,
              child: SizedBox(
                width: snapshot.data!.size.width,
                height: snapshot.data!.size.height,
                child: Texture(textureId: snapshot.data!.textureId!),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(CameraMacOSView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if camera mode has changed mode, reinitialize the camera
    if (oldWidget.deviceId != widget.deviceId ||
        oldWidget.audioDeviceId != widget.audioDeviceId ||
        oldWidget.cameraMode != widget.cameraMode ||
        oldWidget.enableAudio != widget.enableAudio ||
        oldWidget.key != widget.key) {
      initializeCameraFuture = CameraMacOSPlatform.instance
          .initialize(
        deviceId: widget.deviceId,
        audioDeviceId: widget.audioDeviceId,
        cameraMacOSMode: widget.cameraMode,
        enableAudio: widget.enableAudio,
      )
          .then((value) {
        if (value != null) {
          this.arguments = value;
          widget.onCameraInizialized(
            CameraMacOSController(value),
          );
        }
        return value;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

enum CameraMacOSMode {
  photo,
  video,
}
