import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class NSKitPlatformView extends StatelessWidget {
  final String viewType;
  const NSKitPlatformView({super.key, required this.viewType});

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: viewType,
      onCreatePlatformView: onCreatePlatformView,
      surfaceFactory:
          (BuildContext context, PlatformViewController controller) {
        return PlatformViewSurface(
          gestureRecognizers: {},
          controller: controller,
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
    );
  }

  PlatformViewController onCreatePlatformView(
      PlatformViewCreationParams params) {
    return NSKitPlatformViewController(paramsViewId: params.id);
  }
}

class NSKitPlatformViewController extends PlatformViewController {
  int paramsViewId;

  NSKitPlatformViewController({required this.paramsViewId}) : super();

  @override
  Future<void> clearFocus() async {
    return;
  }

  @override
  Future<void> dispatchPointerEvent(PointerEvent event) async {
    return;
  }

  @override
  Future<void> dispose() async {
    return;
  }

  @override
  int get viewId => this.paramsViewId;
}
