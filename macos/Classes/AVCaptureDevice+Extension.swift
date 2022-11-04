//
//  AVCaptureDevice+Extension.swift
//  camera_macos
//
//  Created by riccardo on 04/11/22.
//

import Foundation
import AVFoundation

extension AVCaptureDevice {
    
    public class func captureDevice(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if #available(macOS 10.15, *) {
            let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [ .builtInWideAngleCamera, .builtInMicrophone ], mediaType: AVMediaType.video, position: .unspecified).devices
            return devices.first(where: { $0.position == position })
        } else {
            return AVCaptureDevice.devices(for: .video).filter({$0.position == position}).first
        }
        
    }
    
}
