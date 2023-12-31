//
//  TabNotesInfo.swift
//  ByteViewNetwork
//
//  Created by liurundong.henry on 2023/7/3.
//

import Foundation

/// Tab列表会后显示的纪要数据
/// Videoconference_V1_VCTabNotesInfo
public struct TabNotesInfo: Equatable {
    /// 文档所有人
    public var owner: ByteviewUser
    /// 文档链接
    public var notesURL: String
    /// 文档标题
    public var fileTitle: String

    public init(owner: ByteviewUser, notesURL: String, fileTitle: String) {
        self.owner = owner
        self.notesURL = notesURL
        self.fileTitle = fileTitle
    }
}
