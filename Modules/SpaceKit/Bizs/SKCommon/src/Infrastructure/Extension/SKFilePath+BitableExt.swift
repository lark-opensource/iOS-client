//
//  SKFilePath+BitableExt.swift
//  SKCommon
//
//  Created by huangzhikai on 2023/1/3.
//

import SKFoundation

extension SKFilePath {
    
    public static var bitableFormDir: SKFilePath {
        //let path = (libraryDir ?? homeDir).appendingPathComponent("Bitable/form")
        let path = SKFilePath.bitableGlobalSandboxWithLibrary.appendingRelativePath("form")
        path.createDirectoryIfNeeded()
        return path
    }
}


