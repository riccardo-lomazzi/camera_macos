//
//  URL+Extension.swift
//  camera_macos
//
//  Created by riccardo on 14/11/22.
//

import Foundation

func showInFinder(url: URL?) {
    guard let url = url else { return }
    
    if url.isDirectory {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
    } else {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

extension URL {
    var isDirectory: Bool {
        return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}
