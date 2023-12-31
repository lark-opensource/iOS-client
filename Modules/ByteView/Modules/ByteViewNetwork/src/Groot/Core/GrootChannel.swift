//
//  GrootChannel.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/6.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_ChannelMeta
public struct GrootChannel: Hashable {
    public init(id: String,
                type: GrootChannelType,
                associateID: String? = nil,
                idType: AssociateType? = nil,
                meetingMeta: MeetingMeta? = nil) {
        self.id = id
        self.type = type
        self.associateID = associateID
        self.idType = idType
        self.meetingMeta = meetingMeta
    }

    /// 可能同时存在同类型的channel，因此需要通过channel_id来区分
    public var id: String

    public var type: GrootChannelType
    /// 与该channel相关联的ID，通常为meetingID
    public var associateID: String?
    /// 关联的ID的类型
    public var idType: AssociateType?

    public var meetingMeta: MeetingMeta?

    public enum AssociateType: Int {
        case unknown // = 0
        case meeting // = 1
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(type)
    }

    public static func == (lhs: GrootChannel, rhs: GrootChannel) -> Bool {
        return lhs.id == rhs.id && lhs.type == rhs.type
    }
}

extension GrootChannel: CustomStringConvertible {
    public var description: String {
        if let idt = idType, let aid = associateID {
            return String(indent: "GrootChannel", "id: \(id)", "type: \(type)", "associateId: \(aid)", "idType: \(idt)")
        } else {
            return String(indent: "GrootChannel", "id: \(id)", "type: \(type)")
        }
    }
}
