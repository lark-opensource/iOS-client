//
//  RustAggregatorTransformer.swift
//  Lark
//
//  Created by Yuguo on 2017/12/22.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import LKCommonsLogging

public struct RustAggregatorTransformer {
    static let logger = Logger.log(RustAggregatorTransformer.self, category: "RustAggregatorTransformer")

    public static func transformToQuasiMessageMap(entity: RustPB.Basic_V1_Entity) -> [String: Message] {
        var result: [String: Message] = [:]
        for (id, _) in entity.quasiMessages {
            do {
                result[id] = try Message.transformQuasi(entity: entity, cid: id)
            } catch {
                RustAggregatorTransformer.logger.error("transformToQuasiMessageMap error: \(error)")
            }
        }
        return result
    }

    public static func transformToQuasiMessageModels(
        entity: RustPB.Basic_V1_Entity,
        messageIds: [String]
    ) -> [Message] {
        return messageIds.compactMap({ (cid) -> Message? in
            do {
                return try Message.transformQuasi(entity: entity, cid: cid)
            } catch {
                RustAggregatorTransformer.logger.error("transformToQuasiMessageModels error: \(error)")
                return nil
            }
        })
    }

    public static func transformToQuasiMessage(
        entity: RustPB.Basic_V1_Entity,
        cid: String
    ) throws -> LarkModel.Message {
        return try Message.transformQuasi(entity: entity, cid: cid)
    }

    /**
     * Transform an entity to ChatModel Map according to options.
     * - parameter options: when it contains ".lastMessage", the LastMessage's optional properties only include user.
     * - parameter entity: RustPB.Basic_V1_Entity
     */
    public static func transformToChatsMap(
        fromEntity entity: RustPB.Basic_V1_Entity,
        chatOptionInfos: [String: Basic_V1_ChatOptionInfo]? = nil
    ) -> [String: LarkModel.Chat] {
        return entity.chats.mapValues({
            Chat.transform(
                entity: entity,
                chatOptionInfo: chatOptionInfos?[$0.id],
                pb: $0
            )
        })
    }

    public static func transformToMessageModel(
        fromEntity entity: RustPB.Basic_V1_Entity,
        currentChatterId: String
    ) -> [String: LarkModel.Message] {
        var result: [String: LarkModel.Message] = [:]
        for (id, message) in entity.messages {
            do {
                result[id] = try Message.transform(entity: entity, id: id, currentChatterID: currentChatterId)
            } catch {
                RustAggregatorTransformer.logger.error("transformToMessageModel error: \(error)")
                result[id] = Message.transform(pb: message)
            }
        }
        return result
    }

    public static func transformToEphemerialMessageModel(
        fromEntity entity: RustPB.Basic_V1_Entity,
        currentChatterId: String
    ) -> [String: LarkModel.Message] {
        var result: [String: LarkModel.Message] = [:]
        for (id, message) in entity.ephemeralMessages {
            do {
                result[id] = try Message.transform(entity: entity, id: id, currentChatterID: currentChatterId)
            } catch {
                RustAggregatorTransformer.logger.error("transformToMessageModel error: \(error)")
                result[id] = Message.transform(pb: message)
            }
        }
        return result
    }

    public static func transformToMessageModels(
        fromEntity entity: RustPB.Basic_V1_Entity,
        messageIds: [String]? = nil,
        currentChatterId: String
    ) -> [LarkModel.Message] {
        if let ids = messageIds {
            return ids.compactMap({ (id) -> Message? in
                do {
                    return try Message.transform(entity: entity, id: id, currentChatterID: currentChatterId)
                } catch {
                    RustAggregatorTransformer.logger.error("transformToMessageModels error: \(error)")
                    return nil
                }
            })
        }
        return entity.messages.compactMap({ (id, _) -> Message? in
            do {
                return try Message.transform(entity: entity, id: id, currentChatterID: currentChatterId)
            } catch {
                RustAggregatorTransformer.logger.error("transformToMessageModels error: \(error)")
                return nil
            }
        })
    }

    public static func transformToChatMessageMap(
        fromEntity entity: RustPB.Basic_V1_Entity,
        orderedMessageIds: [String],
        currentChatterId: String
    ) -> [String: [LarkModel.Message]] {
        let messages = transformToMessageModels(
            fromEntity: entity,
            messageIds: orderedMessageIds,
            currentChatterId: currentChatterId
        )
        return messages.reduce([:]) { (result, message) -> [String: [LarkModel.Message]] in
            var dic = result
            var messageArr = dic[message.channel.id] ?? []
            messageArr.append(message)
            dic[message.channel.id] = messageArr
            return dic
        }.mapValues({ (messages) -> [LarkModel.Message] in
            return messages.sorted(by: { $0.position < $1.position })
        })
    }
}
