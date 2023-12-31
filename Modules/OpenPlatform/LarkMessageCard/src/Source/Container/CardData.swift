//
//  MessageCardContainer+CardProtocol.swift
//  LarkMessageCard
//
//  Created by majiaxin.jx on 2022/12/11.
//

import Foundation
import UniversalCardInterface

extension CardData {
    typealias SettingKey = String
    typealias Settings = [SettingKey: Any]
}

extension CardData {
    typealias FGKey = String
    typealias FG = [FGKey: Bool]
}

extension CardData {
    struct Data {
        let card: CardJSON
        let attachment: Attachment
        let actionValues: ActionValues
        
        func toDict() -> [AnyHashable: Any] {
            return [
                "card": card,
                "attachment": attachment.dictionary,
                "actionValues": actionValues
            ]
        }
    }
}

extension CardData.Data {
    // 卡片原始数据, 目前是 json 协议
    typealias CardJSON = String
    
    typealias ImageID = String
    struct ImageProperty: Encodable {
        let originWidth: Int32
        let originHeight: Int32
    }
    
    typealias UserID = String
    typealias PersonOpenID = String
    typealias ComponentName = String
    struct AtProperty: Encodable {
        let userID: String
        let content: String
        let isOuter: Bool
        let isAnonymous: Bool
    }
    struct OptionUser: Encodable {
        let userID: String
        let avatarKey: String
        let content: String
    }
    struct Person: Encodable {
        let personID: String
        let content: String
        let avatarKey: String
        let type: Int
    }
    struct Attachment: Encodable {
        let images: [ImageID : ImageProperty]
        let atUsers: [UserID : AtProperty]
        let optionUsers: [UserID: OptionUser]
        let componentStatusByName: [ComponentName: String]
        let persons: [PersonOpenID: Person]
    }

    
    typealias ActionID = String
    typealias ActionInitialOption = String
    typealias ActionValues = [ActionID: ActionInitialOption]
    
}

extension CardData {
    // 卡片上下文数据
    struct CardContext {
        let key: String
        let traceID: String
        let isWideMode: Bool
        let actionEnable: Bool
        let isForward: Bool
        let bizContext: [AnyHashable: Any]
        let businessType: String
        let actionContext: CardActionContextProtocol?
        let host: String
        let deliveryType: String

        // FIXME: 发布前改造
        // 改成 encodable
        func toDict() -> [String: Any] {
            return [
                "key": key,
                "traceID": traceID,
                "isWideMode": isWideMode,
                "actionEnable": actionEnable,
                "isForward": isForward,
                "bizContext": bizContext,
                "businessType": businessType,
                "actionContext": actionContext?.toDict() ?? "",
                "host": host,
                "deliveryType": deliveryType
            ]
        }
    }
    
    struct CardConfig: Encodable {
        let showTranslateMargin: Bool
        let showCardBGColor: Bool
        let showCardBorderRadius: Bool
        let preferWidth: CGFloat
    }
}

struct CardData {
    let cardID: String
    let version: String
    let status: String
    // 原文数据
    let original: Data
    // 译文数据
    let translation: Data?
    // 卡片传给 Lynx 的上下文数据
    let context: CardContext
    // 翻译相关信息
    let translateInfo: TranslateInfo
    // 卡片配置项
    let config: CardConfig
    // Settings
    let settings: Settings
    // FG
    let fg: FG
    // i18n 文本
    let i18nText: I18nText
    
    let targetElement: [String: Any]?
    
    // FIXME: 发布前改造
    // 改成 encodable
    func toDict() -> [String: Any] {
        var dict: [String : Any] = [
            "cardID": cardID,
            "version": version,
            "original": original.toDict(),
            "status": status,
            "context": context.toDict(),
            "config": config.dictionary ?? [:],
            "translateInfo": translateInfo.toDict(),
            "settings": settings,
            "fg": fg,
            "i18nText": i18nText.dictionary ?? [:]
        ]
        if let targetElement = targetElement {
            dict["targetElement"] = targetElement
        }
        if let translation = translation {
            dict["translation"] = translation.toDict()
        }
        return dict
    }
}


extension Encodable {
    fileprivate var dictionary: [String: AnyHashable]? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: AnyHashable] }
    }
}


