import 'package:camera_macos/camera_macos_arguments.dart';
import 'package:camera_macos/camera_macos_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'camera_macos_platform_interface.dart';

class CameraMacOSView extends StatefulWidget {
  /// Handles how the widget should fit the screen.
  final BoxFit fit;

  final CameraMacOSMode cameraMode;
  final Widget Function(Object?)? onCameraLoading;
  final Function(CameraMacOSController) onCameraInizialized;

  const CameraMacOSView({
    Key? key,
    this.fit = BoxFit.contain,
    required this.cameraMode,
    required this.onCameraInizialized,
    this.onCameraLoading,
  }) : super(key: key);

  @override
  CameraMacOSViewState createState() => CameraMacOSViewState();
}

class CameraMacOSViewState extends State<CameraMacOSView>
    with WidgetsBindingObserver {
  late CameraMacOSArguments arguments;
  late Future<CameraMacOSArguments?> initializeCameraFuture;

  @override
  void initState() {
    super.initState();
    initializeCameraFuture = CameraMacOSPlatform.instance
        .initialize(
      cameraMacOSMode: widget.cameraMode,
    )
        .then((value) {
      if (value != null) {
        this.arguments = value;
        widget.onCameraInizialized(
          CameraMacOSController(
            CameraMacOSPlatform.instance,
            value,
          ),
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
    if (oldWidget.cameraMode != widget.cameraMode) {
      initializeCameraFuture = CameraMacOSPlatform.instance
          .initialize(
        cameraMacOSMode: widget.cameraMode,
      )
          .then((value) {
        if (value != null) {
          this.arguments = value;
          widget.onCameraInizialized(
            CameraMacOSController(
              CameraMacOSPlatform.instance,
              value,
            ),
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
  picture,
  video,
}
