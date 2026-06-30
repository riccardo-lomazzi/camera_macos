//
//  URL+Extension.swift
//  camera_macos
//
//  Created by riccardo on 14/11/22.
//

import Foundation
#if os(macOS)
import AppKit // Required for NSWorkspace
#endif

func showInFinder(url: URL?) {
    guard let url = url else { return }
    
    #if os(macOS)
    if url.isDirectory {
        // Casting nil to String? resolves the 'contextual type' error
        NSWorkspace.shared.selectFile(nil as String?, inFileViewerRootedAtPath: url.path)
    } else {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    #endif
}

extension URL {
    var isDirectory: Bool {
        return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}
