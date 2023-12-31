//
//  FolderContent.swift
//  LarkModel
//
//  Created by 赵家琛 on 2021/4/18.
//

import Foundation
import RustPB

public struct FolderContent: MessageContent {
    public typealias PBModel = RustPB.Basic_V1_Message
    /// 文件夹局域网传输状态
    public typealias LanTransStatus = RustPB.Basic_V1_TransStatus

    // 固有字段
    public let key: String
    public let name: String
    public let size: Int64

    public let fileSource: RustPB.Basic_V1_File.Source
    public var lanTransStatus: LanTransStatus
    // 消息链接化场景需要使用previewID做资源鉴权
    public var authToken: String?

    public init(
        key: String,
        name: String,
        size: Int64,
        fileSource: RustPB.Basic_V1_File.Source,
        lanTransStatus: LanTransStatus
        ) {
        self.key = key
        self.name = name
        self.size = size
        self.fileSource = fileSource
        self.lanTransStatus = lanTransStatus
    }

    public static func transform(pb: PBModel) -> FolderContent {
        return FolderContent(
            key: pb.content.key,
            name: pb.content.name,
            size: pb.content.size,
            fileSource: pb.content.fileSource,
            lanTransStatus: pb.content.lanTransStatus
        )
    }

    public func complement(entity: RustPB.Basic_V1_Entity, message: Message) {}

    public mutating func complement(previewID: String, messageLink: RustPB.Basic_V1_MessageLink, message: Message) {
        self.authToken = previewID
    }
}
