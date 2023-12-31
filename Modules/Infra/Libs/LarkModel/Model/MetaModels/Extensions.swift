//
//  Extensions.swift
//  LarkModel
//
//  Created by liuwanlin on 2018/7/4.
//  Copyright © 2018年 qihongye. All rights reserved.
//

import UIKit
import Foundation
import RustPB

public extension RustPB.Basic_V1_Notice {
    var channel: RustPB.Basic_V1_Channel {
        return self.extra.channel
    }
}

public extension Chat {
    var isSingleBot: Bool {
        return chatter?.type == .bot
    }

    var p2pOppositeId: String? {
        if chatterId.isEmpty {
            return nil
        }
        return chatterId
    }

    var chatterHasResign: Bool {
        if self.type == .p2P, self.chatter?.isResigned ?? false {
            return true
        }
        return false
    }

    func canBeShared(_ currentUserId: String) -> Bool {
        guard !isCrypto, !isCrossTenant, !isOncall, !isFrozen else { return false }

        return self.ownerId == currentUserId || shareCardPermission == .allowed
    }

    var showApplyBadge: Bool {
        if showBanner, putChatterApplyCount > 0 {
            return true
        }
        return false
    }

    var isOncall: Bool {
        return !oncallId.isEmpty
    }

    var isSupportPinMessage: Bool {
        return !isCrypto && !isOncall && !isPrivateMode
    }
}

public extension SystemContent {
    var callerId: String? {
        /// 老类型从 values 取
        /// 新类型从 systemContentValues 取
        if let callerID = values["caller_id"], !callerID.isEmpty { return callerID }
        if let callerID = systemContentValues["caller_id"]?.contentValues.first?.value, !callerID.isEmpty { return callerID }
        return nil
    }

    var calleeId: String? {
        /// 老类型从 values 取
        /// 新类型从 systemContentValues 取
        if let calleeID = values["callee_id"], !calleeID.isEmpty { return calleeID }
        if let calleeID = systemContentValues["callee_id"]?.contentValues.first?.value, !calleeID.isEmpty { return calleeID }
        return nil
    }

    var triggerId: String? {
        switch self.systemType {
        case .userCheckOthersTelephone, .checkUserPhoneNumber:
            return self.callerId
        case .meetingTransferToChat, .meetingTransferToChatWithDocURL:
            return self.callerId
        case .addEmailMembers, .modifyEmailMembers, .removeEmailMembers, .userModifyEmailSubject:
            return nil
        case .userCallE2EeVoiceOnCancell, .userCallE2EeVoiceOnMissing, .userCallE2EeVoiceDuration,
             .userCallE2EeVoiceWhenOccupy, .userCallE2EeVoiceWhenRefused:
            return self.e2eeCallInfo?.e2EeFromID
        case .vcCallHostCancel, .vcCallFinishNotice, .vcCallDuration,
             .vcCallPartiNoAnswer, .vcCallPartiCancel, .vcCallHostBusy,
             .vcCallPartiBusy, .vcCallConnectFail, .vcCallDisconnect:
            return self.btyeViewInfo?.fromID
        @unknown default:
            return nil
        }
    }
}

public extension PostContent {
    var firstUrl: String? {
        if let imgId = richText.imageIds.first {
            return richText.elements[imgId]?.property.image.urls.first
        }

        return nil
    }

    var imageUrls: [String] {
        return self.richText.imageIds.compactMap({ (id) -> String? in
            return self.richText.elements[id]?.property.image.urls.first
        })
    }

    var isUntitledPost: Bool {
        return ["无标题帖子", "Untitled Post", "タイトルなし", "", "Untitled post"].contains(title)
    }
}

public extension Image {
    var firstUrl: String {
        return self.urls.first ?? ""
    }
}

extension RustPB.Feed_V1_Cursor {
    public var description: String {
        return "[\(self.maxCursor), \(self.minCursor)]"
    }
}

extension Array where Element == RustPB.Feed_V1_Cursor {
    public var description: String {
        return self.reduce("") { (str, cursor) -> String in
            if str.isEmpty {
                return cursor.description
            } else {
                return str + ", \(cursor.description)"
            }
        }
    }
}

extension RustPB.Feed_V1_PushFeedCursor {
    public var description: String {
        return "cursor: \(self.cursor.description), count: \(self.count), "
            + "feedCardID: \(self.feedCardID), feedType: \(self.feedType)"
    }
}

public extension RustPB.Settings_V1_TimeFormatSetting.TimeFormat {
    var is24HourTime: Bool {
        if case .twentyFourHour = self {
            return true
        }
        return false
    }
}

extension RustPB.Basic_V1_RichText {
    public static func text(_ text: String) -> RustPB.Basic_V1_RichText {
        var content = RustPB.Basic_V1_RichText()
        var elementIds: [String] = []
        var elements: [String: RustPB.Basic_V1_RichTextElement] = [:]

        let textElementId = String(arc4random() % 100_000_000)
        var textElement = RustPB.Basic_V1_RichTextElement()
        textElement.tag = RustPB.Basic_V1_RichTextElement.Tag.text
        var textProperty = RustPB.Basic_V1_RichTextElement.TextProperty()
        textProperty.content = text
        textElement.property.text = textProperty

        let pElementId = String(arc4random() % 100_000_000)
        var pElement = RustPB.Basic_V1_RichTextElement()
        pElement.tag = RustPB.Basic_V1_RichTextElement.Tag.p
        pElement.childIds = [textElementId]
        pElement.property.paragraph = RustPB.Basic_V1_RichTextElement.ParagraphProperty()

        elements[pElementId] = pElement
        elements[textElementId] = textElement
        elementIds.append(pElementId)

        content.elements = elements
        content.elementIds = elementIds
        content.innerText = textElement.property.text.content

        return content
    }

    public static func image(_ key: String, _ size: CGSize) -> RustPB.Basic_V1_RichText {
        var content = RustPB.Basic_V1_RichText()
        var elementIds: [String] = []
        var elements: [String: RustPB.Basic_V1_RichTextElement] = [:]

        let imageElementId = String(arc4random() % 100_000_000)
        var imageElement = RustPB.Basic_V1_RichTextElement()
        imageElement.tag = RustPB.Basic_V1_RichTextElement.Tag.img
        var imageProperty = RustPB.Basic_V1_RichTextElement.ImageProperty()
        imageProperty.token = key
        imageProperty.thumbKey = key
        imageProperty.middleKey = key
        imageProperty.originKey = key
        imageProperty.originWidth = Int32(size.width)
        imageProperty.originHeight = Int32(size.height)
        imageElement.property.image = imageProperty

        let figureElementId = String(arc4random() % 100_000_000)
        var figureElement = RustPB.Basic_V1_RichTextElement()
        figureElement.tag = RustPB.Basic_V1_RichTextElement.Tag.figure
        figureElement.property.figure = RustPB.Basic_V1_RichTextElement.FigureProperty()
        figureElement.childIds = [imageElementId]

        elements[imageElementId] = imageElement
        elements[figureElementId] = figureElement
        elementIds.append(figureElementId)

        content.elements = elements
        content.elementIds = elementIds
        content.imageIds = [imageElementId]
        content.innerText = ""

        return content
    }
}

public extension RustPB.Im_V1_GetChatChattersResponse {
    enum FormatedStyle {
        case normal
        case swapOwnerToFirst(String)
    }

    typealias FormatedChatterIDResult = [[String: [String]]]

    func formatedChatterIDs(_ style: FormatedStyle = .normal) -> FormatedChatterIDResult {
        let chatterIds: FormatedChatterIDResult

        switch style {
        case .normal:
            if self.letterMaps.isEmpty {
                chatterIds = [["": self.chatterIds]]
            } else {
                chatterIds = self.letterMaps.compactMap { $0.chatterIds.isEmpty ? nil : [$0.letter: $0.chatterIds] }
            }

        case .swapOwnerToFirst(let ownerID):
            if self.letterMaps.isEmpty {
                var temp = self.chatterIds
                if temp.contains(ownerID) {
                    temp.removeAll { $0 == ownerID }
                    temp.insert(ownerID, at: 0)
                }
                chatterIds = [["": temp]]
            } else {
                var isContentOwnerID: Bool = false

                let formatedChatterIDs = self.letterMaps.compactMap { (letterMap) -> [String: [String]]? in
                    var chatterIds = letterMap.chatterIds
                    if chatterIds.contains(ownerID) {
                        chatterIds.removeAll { $0 == ownerID }
                        isContentOwnerID = true
                    }
                    return chatterIds.isEmpty ? nil : [letterMap.letter: chatterIds]
                }
                chatterIds = isContentOwnerID ? [["": [ownerID]]] + formatedChatterIDs : formatedChatterIDs
            }
        }
        return chatterIds
    }
}
