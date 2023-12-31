//
//  ShareUserCardContent.swift
//  LarkModel
//
//  Created by 赵家琛 on 2020/4/13.
//

import Foundation
import RustPB

public struct ShareUserCardContent: MessageContent {
    public let shareChatterID: String
    public var chatter: Chatter?

    public init(shareChatterID: String) {
        self.shareChatterID = shareChatterID
    }

    public static func transform(pb: RustPB.Basic_V1_Message) -> ShareUserCardContent {
        return ShareUserCardContent(shareChatterID: pb.content.shareChatterID)
    }

    public mutating func complement(entity: RustPB.Basic_V1_Entity, message: Message) {
        if let chatter = try? Chatter.transformChatChatter(entity: entity, chatID: message.channel.id, id: shareChatterID) {
            self.chatter = chatter
        }
    }

    public mutating func complement(previewID: String, messageLink: RustPB.Basic_V1_MessageLink, message: Message) {
        if let chatterPB = messageLink.chatters[shareChatterID] {
            self.chatter = Chatter.transform(pb: chatterPB)
        }
    }
}
