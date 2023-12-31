//
//  DriveSDK+Path.swift
//  SKDrive
//
//  Created by ByteDance on 2022/12/19.
//

import Foundation
import SKFoundation
import SpaceInterface

/// Drive 存储统一迁移，由于外部调用传递的是String path
/// 需要转成SKAbsFilePath进行兼容

extension DriveSDKLocalFileV2 {
    var absFilePath: SKFilePath {
        return SKFilePath(absUrl: fileURL)
    }
}

extension DriveLocalFileEntity {
    var absFilePath: SKFilePath {
        return SKFilePath(absUrl: fileURL)
    }
}


