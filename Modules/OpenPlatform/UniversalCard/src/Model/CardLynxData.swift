//
//  CardLynxData.swift
//  UniversalCard
//
//  Created by ByteDance on 2023/8/9.
//

import Foundation
import RustPB
import UniversalCardInterface

/*
 * 传给 Lynx 的数据, 无业务含义, 纯粹为了数据包装
 */
struct LynxData: Encodable {
    static let lynxTimingPrefix = "__lynx_timing_actual_fmp_"

    let cardData: LynxData.CardData
    let config: LynxData.CardConfig
    let context: LynxData.CardContext
    let isUniversalCard: Bool
    let __lynx_timing_flag: String

    init(
        cardData: UniversalCardData,
        cardConfig: UniversalCardConfig,
        cardContext: UniversalCardContext
    ) {
        self.cardData = CardData(cardData)
        self.config = cardConfig
        let traceID = cardContext.renderingTrace?.traceId ?? "unknown"
        self.context = CardContext(
            key: cardContext.key,
            traceID: traceID,
            businessType: cardContext.renderBizType ?? "unknown",
            bizContext: cardContext.bizContext,
            actionContext: cardContext.actionContext,
            host: cardContext.host ?? "",
            deliveryType: cardContext.deliveryType ?? ""
        )
        self.isUniversalCard = true
        // Lynx 内部关键字,用于确保 lynx 更新, 保证触发updateTiming回调
        self.__lynx_timing_flag = LynxData.lynxTimingPrefix + traceID
    }
    
    static func getTraceID(fromTiming timing: [AnyHashable: Any]) -> String? {
        for key in timing.keys {
            if let keyStr = key as? String, keyStr.hasPrefix(lynxTimingPrefix) {
                return keyStr.replacingOccurrences(of: lynxTimingPrefix, with: "")
            }
        }
        return nil
    }
}

extension LynxData {

    struct CardData: Encodable {
        let cardID: String
        let version: String
        let cardContent: CardData.CardContent
        let translateContent: CardData.CardContent?
        let actionStatus: CardData.ActionStatus
        let localStatus: String?

        init(_ data: UniversalCardData) {
            self.cardID = data.cardID
            self.version = data.version
            let attachment = CardContent.Attachment(data.cardContent.attachment)
            self.cardContent = CardContent(
                card: data.cardContent.card,
                attachment: attachment
            )
            if let translateContent = data.translateContent {
                let attachment = CardContent.Attachment(data.cardContent.attachment)
                self.translateContent = CardContent(
                    card: translateContent.card,
                    attachment: attachment
                )
            } else {
                self.translateContent = nil
            }
            self.actionStatus = ActionStatus(
                componentStatusByName: data.actionStatus.componentStatusByName,
                componentStatusByActionID: data.actionStatus.componentStatusByActionID
            )
            self.localStatus = data.localStatus
        }
    }

    typealias CardConfig = UniversalCardConfig


    struct CardContext: Encodable {
        let key: String
        let traceID: String
        let businessType: String
        let bizContext: Encodable?
        let actionContext: Encodable?
        let host: String
        let deliveryType: String

        enum CodingKeys: String, CodingKey {
            case key
            case traceID
            case businessType
            case bizContext
            case actionContext
            case host
            case deliveryType
        }
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(key, forKey: .key)
            try container.encode(traceID, forKey: .traceID)
            try container.encode(businessType, forKey: .businessType)
            if let bizContext = bizContext {
                try container.encode(bizContext, forKey: .bizContext)
            }
            try container.encode(host, forKey: .host)
            try container.encode(deliveryType, forKey: .deliveryType)
            
            if let actionContext = actionContext {
                try container.encode(actionContext, forKey: .actionContext)
            }
        }
    }
}

extension LynxData.CardData {

    struct ActionStatus: Encodable {
        let componentStatusByName: [String: String]
        let componentStatusByActionID: [String: String]
    }

    struct CardContent: Encodable, Equatable {
        typealias CardJSON = String
        typealias ActionID = String
        typealias ActionInitialOption = String
        typealias ActionValues = [ActionID: ActionInitialOption]

        let card: CardJSON
        let attachment: Attachment

        init(card: CardJSON, attachment: Attachment) {
            self.card = card
            self.attachment = attachment
        }
    }
}


extension LynxData.CardData.CardContent {

    struct Attachment: Encodable, Equatable {
        typealias ImageID = String
        typealias UserID = String
        typealias PersonOpenID = String
        typealias ComponentName = String
        typealias ComponentStatus = String

        struct ImageProperty: Encodable, Equatable {
            let originWidth: Int32
            let originHeight: Int32
        }

        struct AtProperty: Encodable, Equatable {
            let userID: String
            let content: String
            let isOuter: Bool
            let isAnonymous: Bool
        }

        struct OptionUser: Encodable, Equatable {
            let userID: String
            let content: String
        }

        struct Person: Encodable, Equatable {
            let id: String
            let content: String
            let avatarKey: String
            let type: Int
        }

        let images: [ImageID : ImageProperty]
        // 当前 At 的用户, At 组件在端上渲染, 这里的信息主要用于算摘要, 算摘要逻辑在 lynx
        let atUsers: [UserID : AtProperty]
        // 当前的用户信息, 组件在端上和 lynx 同时渲染, 这里的信息主要用于算摘要和 lynx 部分显示
        let characters: [UserID: Person]

        init(_ attachment: UniversalCardContent.Attachment) {
            images = attachment.images.mapValues{ image in
                return ImageProperty(
                    originWidth: image.originWidth, originHeight: image.originHeight
                )
            }
            atUsers = attachment.atUsers.mapValues { at in
                return AtProperty(
                    userID: at.userID,
                    content: at.content,
                    isOuter: at.isOuter,
                    isAnonymous: at.isAnonymous
                )
            }
            characters = attachment.characters.mapValues { person in
                return Person(
                    id: person.id,
                    content: person.content,
                    avatarKey: person.avatarKey,
                    type: person.type.rawValue
                )
            }

        }
    }
}
