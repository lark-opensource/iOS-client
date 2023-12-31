//
//  FollowAbbrInfo.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_FollowAbbrInfo
public struct FollowAbbrInfo: Equatable {
    public init(rawURL: String, fileTitle: String, fileToken: String, shareSubtype: FollowShareSubType,
                fileLabelURL: String, presenters: [ByteviewUser]) {
        self.rawURL = rawURL
        self.fileTitle = fileTitle
        self.fileToken = fileToken
        self.shareSubtype = shareSubtype
        self.fileLabelURL = fileLabelURL
        self.presenters = presenters
    }

    /// 共享文件链接
    public var rawURL: String

    /// 共享文件标题
    public var fileTitle: String

    /// 共享文件token
    public var fileToken: String

    /// 共享文件具体类型
    public var shareSubtype: FollowShareSubType

    /// 展示此文档对应的图标
    public var fileLabelURL: String

    /// 共享人, 同一个文件可能被多个人共享
    public var presenters: [ByteviewUser]
}

extension FollowAbbrInfo: CustomStringConvertible {

    public var description: String {
        String(
            indent: "FollowAbbrInfo",
            "presenters: \(presenters)",
            "rawURL: \(rawURL.hash)",
            "shareSubType: \(shareSubtype)"
        )
    }
}
