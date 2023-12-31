//
//  EmojiDataDependencyImpl.swift
//  ByteViewMod
//
//  Created by lutingting on 2023/9/19.
//

import Foundation
import ByteView
import LarkEmotionKeyboard

final class EmojiDataDependencyImpl: EmojiDataDependency {
    func getUserReactionsByType() -> [ByteView.ReactionEntity] {
        let entities = EmojiImageService.default?.getMRUReactions()
        let reactionEntities = entities?.map({ $0.vcType })
        return reactionEntities ?? []
    }

    func getAllReactions() -> [ByteView.ReactionGroup] {
        let groups = EmojiImageService.default?.getAllReactions()
        let reactionGroup = groups?.map({ $0.vcType })
        return reactionGroup ?? []
    }

    func getCustomReactions() -> [ByteView.ReactionGroup] {
        let groups = EmojiImageService.default?.getCustomReactions()
        let reactionGroup = groups?.map({ $0.vcType })
        return reactionGroup ?? []
    }
}

fileprivate extension LarkEmotionKeyboard.ReactionGroup {
    var vcType: ByteView.ReactionGroup {
        return .init(type: .init(rawValue: type.rawValue) ?? .unknown, iconKey: iconKey, title: title, source: source, entities: entities.map({ $0.vcType }))
    }
}

fileprivate extension LarkEmotionKeyboard.ReactionEntity {
    var vcType: ByteView.ReactionEntity {
        return .init(key: key, selectSkinKey: selectSkinKey, skinKeys: skinKeys, size: size)
    }
}
