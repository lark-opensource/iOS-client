//
//  UpdatingPanelistPermission.swift
//  ByteViewNetwork
//
//  Created by kiri on 2023/4/19.
//

import Foundation

public struct UpdatingPanelistPermission {

    /// 允许发送消息
    public var allowSendMessage: Bool?

    /// 允许发送表情
    public var allowSendReaction: Bool?

    /// 允许使用Animoji
    public var allowVirtualAvatar: Bool?

    /// 允许使用虚拟背景
    public var allowVirtualBackground: Bool?

    /// 允许申请录制
    public var allowRequestRecord: Bool?

    public init() {}
}

public struct UpdatingAttendeePermission: Equatable {

    /// 允许发送消息
    public var allowSendMessage: Bool?

    /// 允许发送表情
    public var allowSendReaction: Bool?

    public init() {}
}

extension UpdatingPanelistPermission {
    var pbType: PBPanelistPermission {
        var panelistPermission = PBPanelistPermission()
        if let allowSendMessage = allowSendMessage {
            panelistPermission.allowSendMessage = allowSendMessage
        }
        if let allowSendReaction = allowSendReaction {
            panelistPermission.allowSendReaction = allowSendReaction
        }
        if let allowRequestRecord = allowRequestRecord {
            panelistPermission.allowRequestRecord = allowRequestRecord
        }
        if let allowVirtualAvatar = allowVirtualAvatar {
            panelistPermission.allowVirtualAvatar = allowVirtualAvatar
        }
        if let allowVirtualBackground = allowVirtualBackground {
            panelistPermission.allowVirtualBackground = allowVirtualBackground
        }
        return panelistPermission
    }
}

extension UpdatingAttendeePermission {
    var pbType: PBAttendeePermission {
        var attendeePermission = PBAttendeePermission()
        if let allowSendMessage = allowSendMessage {
            attendeePermission.allowSendMessage = allowSendMessage
        }
        if let allowSendReaction = allowSendReaction {
            attendeePermission.allowSendReaction = allowSendReaction
        }
        return attendeePermission
    }
}
