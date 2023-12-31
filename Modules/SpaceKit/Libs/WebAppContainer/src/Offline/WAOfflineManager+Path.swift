//
//  WAOfflineManager+Path.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/21.
//

import SKFoundation


extension WAOfflineManager {
    
    /// 获取解压后目录文件的完整路径
    func getTargetFileFullPath(for relativeFilePath: String) -> SKFilePath {
        return Self.unzipResFullPath(appName: self.resConfig.rootPath).appendingRelativePath(relativeFilePath)
    }
    
    //解压后存放的目录
    class func unzipResPath() -> SKFilePath {
        let location = SKFilePath.globalSandboxWithLibrary
        let dataFolderName = "WebAppBundle/"
        let rootPath = location.appendingRelativePath(dataFolderName)
        return rootPath
    }
    
    //解压后存放的完整目录
    class func unzipResFullPath(appName: String) -> SKFilePath {
        let base = unzipResPath()
        return base.appendingRelativePath(appName)
    }
}


