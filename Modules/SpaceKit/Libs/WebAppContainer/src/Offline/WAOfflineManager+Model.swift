//
//  ZipInfo.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/21.
//

import SKFoundation


extension WAOfflineManager {
    struct ZipInfo {
        static let unkonwnVersion = "unknow"
        let zipFileBasePath: SKFilePath
        let bundlePath: SKFilePath
        let zipName: String
        let zipPath: String
        let version: String
        
        var zipFileFullPath: SKFilePath {
            zipFileBasePath.appendingRelativePath(zipName)
        }
        
        var isVaild: Bool {
            if version == Self.unkonwnVersion { return false }
            return !zipFileBasePath.pathString.isEmpty
        }
        
        init(bundle: String, zipName: String, zipPath: String) {
            self.zipName = zipName
            self.zipPath = zipPath
            guard let resourceBundle = WAOfflineManager.bundle(from: bundle) else {
                let msg = "cannot find \(zipName) bundle"
                version = Self.unkonwnVersion
                self.bundlePath = SKFilePath.absPath("")
                self.zipFileBasePath = SKFilePath.absPath("")
                spaceAssertionFailure(msg)
                return
            }
            
            let bundlePath = SKFilePath(absPath: resourceBundle.bundlePath)
            let path = bundlePath.appendingRelativePath(zipPath)
            self.bundlePath = bundlePath
            self.zipFileBasePath = path
            self.version = WAOfflineManager.revision(in: path) ?? Self.unkonwnVersion
        }
    }
}
