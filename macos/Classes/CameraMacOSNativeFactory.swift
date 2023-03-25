//
//  CameraMacOSNativeFactory.swift
//  camera_macos
//
//  Created by riccardo on 25/03/23.
//

import Foundation
import FlutterMacOS
import AppKit
import AVFoundation

class CameraMacOSNativeFactory: NSObject, FlutterPlatformViewFactory {
    
    private var messenger: FlutterBinaryMessenger
    var frame: CGRect
    
    var view: NSView!
    var previewLayer: AVCaptureVideoPreviewLayer!

    init(messenger: FlutterBinaryMessenger, frame: CGRect = CGRect.zero) {
        self.messenger = messenger
        self.frame = frame
        super.init()
    }
    
    public func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
        let view: NSView = NSView(frame: frame)
        view.wantsLayer = true
        view.updateLayer()
        self.view = view
        if let viewLayer = view.layer, let previewLayer = self.previewLayer {
            viewLayer.addSublayer(previewLayer)
        }
        return view
    }
    
    public func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
        return FlutterStandardMessageCodec.sharedInstance()
    }
    
}
