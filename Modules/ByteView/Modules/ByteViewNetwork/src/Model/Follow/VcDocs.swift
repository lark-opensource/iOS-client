//
//  VcDocs.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/11/30.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_VcDocs
public struct VcDocs: Equatable {

    public var docToken: String

    public var docURL: String

    public var docType: VcDocType

    public var docSubType: VcDocSubType

    /// 文档标题(raw)
    public var docTitle: String

    public var isCrossTenant: Bool

    public var ownerName: String

    public var ownerId: String

    public var status: ShareStatus

    /// 文档标题(关键词高亮)
    public var docTitleHighlight: String

    public var createTime: String

    public var updateTime: String

    /// 文档摘要(关键词高亮)
    public var abstract: String

    public var thumbnail: FollowInfo.ThumbnailDetail

    /// 展示此文档对应的图标
    public var docLabelURL: String

    public var containerType: ContainerType

    public var iconMeta: String

    public enum ShareStatus: Int, Hashable {
        case unknown // = 0
        case fullyShare // = 1
        case partialShare // = 2
        case noSharePermission // = 3
        case noSupportShare // = 4
    }

    public enum ContainerType: Int, Hashable {
        case space // = 0
        case wiki2 // = 1
    }
}

extension VcDocs: CustomStringConvertible {
    public var description: String {
        String(
            indent: "VcDocs",
            "docURL: \(docURL.hash)",
            "docType: \(docType)",
            "docSubType: \(docSubType)",
            "containerType: \(containerType)",
            "isCrossTenant: \(isCrossTenant)",
            "ownerId: \(ownerId)",
            "status: \(status)",
            "createTime: \(createTime)",
            "updateTime: \(updateTime)",
            "thumbnail: \(thumbnail)",
            "docLabelURL: \(docLabelURL.hash)"
        )
    }
}
