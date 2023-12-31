//
//  FileContent.swift
//  LarkModel
//
//  Created by chengzhipeng-bytedance on 2018/5/18.
//  Copyright © 2018年 qihongye. All rights reserved.
//

import Foundation
import UIKit
import RustPB

public struct FileContent: MessageContent {
    public typealias PBModel = RustPB.Basic_V1_Message
    /// 文件局域网传输状态
    public typealias LanTransStatus = RustPB.Basic_V1_TransStatus

    // 固有字段
    public let key: String
    public let name: String
    public let size: Int64
    public let mime: String

    /// 使用RustSDK默认缓存路径，用于密聊。
    public let cacheFilePath: String
    public let filePath: String
    public let fileSource: RustPB.Basic_V1_File.Source
    public let namespace: String
    public var isInMyNutStore: Bool
    public var lanTransStatus: LanTransStatus
    public let isEncrypted: Bool

    static let FILE_PREVIEW_HANG_POINT_KEY = "im_file"
    public var hangPoint: Basic_V1_UrlPreviewHangPoint?
    public let fileAbility: Basic_V1_Content.FileAbility
    public let filePermission: Basic_V1_Content.FilePermission
    public let fileLastUpdateUserId: Int64
    public let fileLastUpdateTimeMs: Int64
    public var fileLastUpdateUser: Basic_V1_Chatter?
    public var filePreviewStage: Basic_V1_FilePreviewStage
    // 消息链接化场景需要使用previewID做资源鉴权
    public var authToken: String?

    public init(
        key: String,
        name: String,
        size: Int64,
        mime: String,
        filePath: String,
        cacheFilePath: String,
        fileSource: RustPB.Basic_V1_File.Source,
        namespace: String,
        isInMyNutStore: Bool,
        lanTransStatus: LanTransStatus,
        hangPoint: Basic_V1_UrlPreviewHangPoint?,
        fileAbility: Basic_V1_Content.FileAbility,
        filePermission: Basic_V1_Content.FilePermission,
        fileLastUpdateUserId: Int64,
        fileLastUpdateTimeMs: Int64,
        filePreviewStage: Basic_V1_FilePreviewStage,
        isEncrypted: Bool = false
    ) {
        self.key = key
        self.name = name
        self.size = size
        self.mime = mime
        self.cacheFilePath = cacheFilePath
        self.filePath = filePath
        self.fileSource = fileSource
        self.namespace = namespace
        self.isInMyNutStore = isInMyNutStore
        self.lanTransStatus = lanTransStatus
        self.isEncrypted = isEncrypted
        self.hangPoint = hangPoint
        self.fileAbility = fileAbility
        self.filePermission = filePermission
        self.fileLastUpdateUserId = fileLastUpdateUserId
        self.fileLastUpdateTimeMs = fileLastUpdateTimeMs
        self.filePreviewStage = filePreviewStage
    }

    public static func transform(pb: PBModel) -> FileContent {
        return FileContent(
            key: pb.content.key,
            name: pb.content.name,
            size: pb.content.size,
            mime: pb.content.mime,
            filePath: pb.content.filePath,
            cacheFilePath: pb.content.cacheFilePath,
            fileSource: pb.content.fileSource,
            namespace: pb.content.namespace,
            isInMyNutStore: pb.content.isInMyNutStore,
            lanTransStatus: pb.content.lanTransStatus,
            hangPoint: pb.content.urlPreviewHangPointMap[Self.FILE_PREVIEW_HANG_POINT_KEY],
            fileAbility: pb.content.fileAbility,
            filePermission: pb.content.filePermission,
            fileLastUpdateUserId: pb.content.fileLastUpdateUserID,
            fileLastUpdateTimeMs: pb.content.fileLastUpdateTimeMs,
            filePreviewStage: pb.content.filePreviewStage,
            isEncrypted: pb.content.isEncrypted
        )
    }

    public mutating func complement(entity: RustPB.Basic_V1_Entity, message: Message) {
        if self.fileLastUpdateUserId > 0 {
            self.fileLastUpdateUser = entity.chatChatters[message.channel.id]?.chatters["\(self.fileLastUpdateUserId)"]
        }
    }

    public mutating func complement(previewID: String, messageLink: RustPB.Basic_V1_MessageLink, message: Message) {
        self.authToken = previewID
    }
}
