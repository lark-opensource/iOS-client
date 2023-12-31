//
//  DriveFileMeta.swift
//  DocsSDK
//
//  Created by Wenjian Wu on 2019/3/14.
//  

import Foundation

/// 文件元数据
struct DriveFileMeta: DriveFileCacheable {
    /// 大小
    let size: UInt64?
    /// 文件名称
    let name: String
    /// 文件类型
    let type: String

    /// 文件token
    let fileToken: String
    /// 父节点token
    let mountNodeToken: String

    let mountPoint: String = "email"

    var downloadUrl: String?

    var version: String?
    var dataVersion: String?

    init(size: UInt64?,
         name: String,
         type: String,
         fileToken: String,
         mountNodeToken: String,
         version: String?,
         dataVersion: String?) {
        self.size = size
        self.name = name
        self.type = type
        self.fileToken = fileToken
        self.mountNodeToken = mountNodeToken
        self.version = version
        self.dataVersion = dataVersion
    }
}

extension DriveFileMeta {
    init(fileInfo: DriveFileInfo) {
        name = fileInfo.name
        type = fileInfo.type
        fileToken = fileInfo.fileToken
        mountNodeToken = fileInfo.mountNodeToken
        size = fileInfo.size
        version = fileInfo.version
        dataVersion = fileInfo.dataVersion
    }
}
