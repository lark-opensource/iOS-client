//
//  PanelistPermission.swift
//  ByteViewNetwork
//
//  Created by lutingting on 2022/11/9.
//

import Foundation

public struct PanelistPermission: Equatable, Codable {

    /// 允许发送消息
    public var allowSendMessage: Bool

    /// 允许发送表情
    public var allowSendReaction: Bool

    /// 允许申请录制
    public var allowRequestRecord: Bool

    /// 允许使用Animoji
    public var allowVirtualAvatar: Bool

    /// 允许使用虚拟背景
    public var allowVirtualBackground: Bool

    public var messageButtonStatus: MessageButtonStatus

    public init(allowSendMessage: Bool,
                allowSendReaction: Bool,
                allowRequestRecord: Bool,
                allowVirtualAvatar: Bool,
                allowVirtualBackground: Bool,
                messageButtonStatus: MessageButtonStatus) {
        self.allowSendMessage = allowSendMessage
        self.allowSendReaction = allowSendReaction
        self.allowRequestRecord = allowRequestRecord
        self.allowVirtualAvatar = allowVirtualAvatar
        self.allowVirtualBackground = allowVirtualBackground
        self.messageButtonStatus = messageButtonStatus
    }

    public init() {
        self.init(allowSendMessage: false, allowSendReaction: false, allowRequestRecord: false, allowVirtualAvatar: false, allowVirtualBackground: false, messageButtonStatus: .default)
    }

    public enum MessageButtonStatus: Int, Codable {
        public typealias RawValue = Int
        case `default` // = 0

        /// 群会议的会中聊天复用当前群，会中聊天开关置灰
        case disableReuseGroup // = 1
    }
}

public struct AttendeePermission: Equatable {

    /// 允许发送消息
    public var allowSendMessage: Bool

    /// 允许发送表情
    public var allowSendReaction: Bool

    public init(allowSendMessage: Bool, allowSendReaction: Bool) {
        self.allowSendMessage = allowSendMessage
        self.allowSendReaction = allowSendReaction
    }

    public init() {
        self.init(allowSendMessage: false, allowSendReaction: false)
    }
}

extension PanelistPermission {
    var serverPbType: ServerPBPanelistPermission {
        var permission = ServerPBPanelistPermission()
        permission.allowSendMessage = allowSendMessage
        permission.allowSendReaction = allowSendReaction
        permission.allowRequestRecord = allowRequestRecord
        permission.allowVirtualAvatar = allowVirtualAvatar
        permission.allowVirtualBackground = allowVirtualBackground
        return permission
    }
}
