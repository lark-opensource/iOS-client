//
//  TabDetailChatHistoryV2.swift
//  ByteViewNetwork
//
//  Created by helijian on 2022/10/16.
//

import Foundation

public struct TabDetailChatHistoryV2: Equatable {

    public enum DocType: Int, Hashable {
        case unknown = 0
        case doc = 1
        case docx = 2
    }

    public enum Status: Int, Hashable {
        case unavailable = 0
        case ready = 1
        case waiting = 2
        case succeeded = 3
        case failed = 4
    }

    /// 聊天记录文档归属用户
    public var owner: ByteviewUser

    /// 聊天记录文档生成状态
    public var status: Status

    /// 聊天记录文档标题
    public var title: String

    /// 聊天记录文档 URL
    public var url: String

    /// 聊天记录文档类型
    public var type: DocType

    public var meetingID: String

    public var version: Int32

    public init(meetingID: String, version: Int32, owner: ByteviewUser, status: Status, title: String, url: String, type: DocType) {
        self.meetingID = meetingID
        self.version = version
        self.owner = owner
        self.status = status
        self.title = title
        self.url = url
        self.type = type
    }
}

extension TabDetailChatHistoryV2: CustomStringConvertible {
    public var description: String {
        "TabDetailChatHistory(meetingID: \(meetingID), version: \(version), owner: \(owner), status: \(status), title: \(title.hash), url: \(url.hash), type: \(type))"
    }
}
