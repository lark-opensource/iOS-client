//
//  Extension.swift
//  LarkModel
//
//  Created by liuwanlin on 2018/8/1.
//

import Foundation
import RustPB

public protocol HasAtUsers: MessageContent {
    var richText: RustPB.Basic_V1_RichText { get }

    var atUserIdsSet: Set<String> { get }

    var atOuterIdsSet: Set<String> { get }

    var botIds: [String] { get set }

    mutating func packBotIDs(entity: RustPB.Basic_V1_Entity, channelID: String)
}

public extension HasAtUsers {
    var atUserIdsSet: Set<String> {
        return Set(richText.atIds.compactMap({ richText.elements[$0]?.property.at.userID }))
    }

    var atOuterIdsSet: Set<String> {
        return Set(richText.atIds.compactMap {
            richText.elements[$0]?.property.at.isOuter == true ?
                richText.elements[$0]?.property.at.userID :
            nil
        })
    }

    mutating func packBotIDs(entity: RustPB.Basic_V1_Entity, channelID: String) {
        guard !self.atUserIdsSet.isEmpty else {
            return
        }
        guard let chatters = entity.chatChatters[channelID]?.chatters else {
            return
        }
        let atUserIDsSet = self.atUserIdsSet
        self.botIds = chatters.filter({ atUserIDsSet.contains($0.key) && $0.value.type == .bot }).map({ $0.key })
    }
}

public protocol TruncateLongText {
    func truncateAttributeText(
        _ attributeText: NSMutableAttributedString,
        maxLength: Int
    ) -> NSMutableAttributedString
}

public extension TruncateLongText {
    func truncateAttributeText(
        _ attributeText: NSMutableAttributedString,
        maxLength: Int = 700
    ) -> NSMutableAttributedString {
        var attributeStr: NSMutableAttributedString! = attributeText.mutableCopy() as? NSMutableAttributedString
        if attributeStr.length > maxLength {
            attributeStr = attributeText.attributedSubstring(from: NSRange(location: 0, length: maxLength))
                as? NSMutableAttributedString
        }
        return attributeStr
    }
}
