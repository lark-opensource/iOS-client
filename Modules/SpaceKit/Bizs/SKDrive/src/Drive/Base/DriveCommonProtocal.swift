//
//  DriveCommonProtocal.swift
//  SpaceKit-DocsSDK
//
//  Created by zenghao on 2019/6/28.
//

import Foundation
import SKCommon
import SKFoundation
import LarkDocsIcon

public protocol DriveFileCacheable {
    var type: String { get }
    var name: String { get }
    var fileToken: String { get }
}

extension DriveFileCacheable {
    var fileType: DriveFileType {
        return DriveFileType(fileExtension: type)
    }

    var fileExtension: String? {
        return SKFilePath.getFileExtension(from: name)
    }
}

extension DriveFileInfo {
    var originFileType: DriveFileType {
        guard let fileExt = fileExtension, !fileExt.isEmpty else {
            return DriveFileType(fileExtension: type)
        }
        return DriveFileType(fileExtension: fileExt)
    }

    var fileExtension: String? {
        return SKFilePath.getFileExtension(from: name)
    }
}
