//
//  VChatRoomCardContent.swift
//  LarkModel
//
//  Created by Prontera on 2020/3/16.
//

import Foundation
import RustPB

public struct VChatRoomCardContent: MessageContent {
    public typealias PBModel = RustPB.Basic_V1_Message
    public let forwarderID: String

    public init(forwarderID: String) {
        self.forwarderID = forwarderID
    }

    public static func transform(pb: PBModel) -> VChatRoomCardContent {
        let content = pb.content.videochatContent.meetingCard
        return VChatRoomCardContent(forwarderID: content.forwarderID)
    }

    public func complement(entity: RustPB.Basic_V1_Entity, message: Message) {}
}
