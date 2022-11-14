//
//  FlutterMacOS+Extension.swift
//  camera_macos
//
//  Created by riccardo on 14/11/22.
//

import Foundation
import FlutterMacOS

extension FlutterError {
    var toMap: [String: Any?] {
        [
            "code": self.code,
            "message": self.message,
            "details": self.details,
        ]
    }
    
    var toFlutterResult: [String: Any] {
        [
            "error": self.toMap
        ]
    }
}
