//
//  Reaction.swift
//  Model
//
//  Created by qihongye on 2018/3/13.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import RustPB

public final class Reaction: ModelProtocol, AtomicExtra {
    public typealias PBModel = RustPB.Basic_V1_Message.Reaction

    public init(type: String, chatterIds: [String], chatterCount: Int32) {
        self.type = type
        self.chatterIds = chatterIds
        self.chatterCount = chatterCount
    }

    public var type: String

    public var chatterIds: [String]

    /// 超大群 chatter_ids 并不会全给，chatterCount是总数，普通群下chatterCount应该==chatterIds.count
    public var chatterCount: Int32

    struct ReactionExtra {
        var chatters: [Chatter]?
    }
    typealias ExtraModel = ReactionExtra
    var atomicExtra = SafeAtomic(value: ReactionExtra())

    public var chatters: [Chatter]? {
        get {
            return atomicExtra.value.chatters
        }
        set {
            atomicExtra.value.chatters = newValue
        }
    }

    public static func transform(pb: PBModel) -> Reaction {
        return Reaction(type: pb.type, chatterIds: pb.chatterIds, chatterCount: pb.chatterCount)
    }

    public static func transform(
        entity: RustPB.Basic_V1_Entity,
        message: RustPB.Basic_V1_Message,
        pb: PBModel
    ) -> Reaction {
        let reaction = transform(pb: pb)
        let chatters = reaction.chatterIds.compactMap({ (chatterID) -> Chatter? in
            return try? Chatter.transformChatter(
                entity: entity,
                message: message,
                id: chatterID
            )
        })
        reaction.atomicExtra.unsafeValue.chatters = chatters
        return reaction
    }

    public static func transform(entity: RustPB.Basic_V1_Entity,
                                 pb: RustPB.Im_V1_PushMessageReactions.Reactions.Reaction,
                                 chatID: String) -> Reaction {
        let reaction = Reaction(type: pb.type, chatterIds: pb.chatterIds, chatterCount: pb.chatterCount)
        let chatters = reaction.chatterIds.compactMap { (chatterID) -> Chatter? in
            return try? Chatter.transformChatChatter(entity: entity,
                                                     chatID: chatID,
                                                     id: chatterID)
        }
        reaction.atomicExtra.unsafeValue.chatters = chatters
        return reaction
    }

    public static func transform(messageLink: Basic_V1_MessageLink, pb: PBModel) -> Reaction {
        let reaction = transform(pb: pb)
        let chatters = reaction.chatterIds.compactMap({ (chatterID) -> Chatter? in
            if let chatterPB = messageLink.chatters[chatterID] {
                return Chatter.transform(pb: chatterPB)
            }
            return nil
        })
        reaction.atomicExtra.unsafeValue.chatters = chatters
        return reaction
    }
}
