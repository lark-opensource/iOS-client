//
//  CardContent.swift
//  LarkModel
//
//  Created by qihongye on 2018/5/31.
//  Copyright © 2018年 qihongye. All rights reserved.
//

import Foundation
import RustPB

public struct CardContent: MessageContent {
    public typealias PBModel = RustPB.Basic_V1_Message
    public typealias TranslatePBModel = RustPB.Basic_V1_TranslateInfo
    public typealias TypeEnum = RustPB.Basic_V1_CardContent.TypeEnum
    public typealias ExtraType = RustPB.Basic_V1_CardContent.ExtraType
    public typealias ExtraInfo = RustPB.Basic_V1_CardContent.ExtraInfo
    public typealias CardHeader = RustPB.Basic_V1_CardContent.CardHeader
    public typealias CardAction = RustPB.Basic_V1_CardAction
    /// 消息卡片支持转发标记
    public var enableForward: Bool

    public var type: TypeEnum
    public var version: Int32
    public var header: CardHeader
    public var richText: RustPB.Basic_V1_RichText
    public var extra: ExtraType
    public var extraInfo: ExtraInfo
    public var actions: [String: CardAction]
    /// 是否有宽版的style
    public var wideScreenMode: Bool
    /// 是否是紧凑类型，默认是false
    public var compactWidth: Bool
    /// 宽版模式
    public var widthMode: String?
    public var enableTrabslate: Bool
    //摘要
    public var summary: String?
    public var jsonBody: String?
    public var jsonAttachment: Basic_V1_CardContent.JsonAttachment?
    public var appInfo: Basic_V1_CardAppInfo?

    /// 卡片唯一标识, 用于区分 messageid 相同,但内容已被更新的卡片
    /// 目前用于翻译, 由于 message 没有版本概念, 卡片更新后无法被知道以更新翻译数据
    /// 属于临时方案, 在后续翻译完整一致性方案上线后, 会使用主端的 message 版本标识
    public let uuid: String = UUID().uuidString

    /// cardVersion 正常对业务应该无感知，卡片子业务可能需要
    public init(type: TypeEnum,
                version: Int32 = 0,
                header: CardHeader,
                richText: RustPB.Basic_V1_RichText,
                extra: ExtraType,
                extraInfo: ExtraInfo,
                actions: [String: CardAction],
                enableForward: Bool,
                wideScreenMode: Bool,
                compactWidth: Bool,
                widthMode: String?,
                enableTranslate: Bool,
                jsonBody: String?,
                jsonAttachment: Basic_V1_CardContent.JsonAttachment?,
                appInfo: Basic_V1_CardAppInfo
    ) {
        self.type = type
        self.version = version
        self.header = header
        self.richText = richText
        self.extra = extra
        self.extraInfo = extraInfo
        self.actions = actions
        self.enableForward = enableForward
        self.wideScreenMode = wideScreenMode
        self.compactWidth = compactWidth
        self.widthMode = widthMode
        self.enableTrabslate = enableTranslate
        self.jsonBody = jsonBody
        self.jsonAttachment = jsonAttachment
        self.appInfo = appInfo
    }

    public static func transform(pb: PBModel) -> CardContent {
        return transform(cardContent: pb.content.cardContent)
    }

    public static func transform(cardContent: Basic_V1_CardContent) -> CardContent {
        return CardContent(
            type: cardContent.type,
            version: cardContent.cardVersion,
            header: cardContent.cardHeader,
            richText: cardContent.richtext,
            extra: cardContent.extra,
            extraInfo: cardContent.extraInfo,
            actions: cardContent.actions,
            enableForward: cardContent.enableForward,
            wideScreenMode: cardContent.hasWideScreenMode && cardContent.wideScreenMode,
            compactWidth: cardContent.hasCompactWidth && cardContent.compactWidth,
            widthMode: cardContent.hasWidthMode ? cardContent.widthMode : nil,
            enableTranslate: cardContent.extraInfo.customConfig.enableTranslate,
            jsonBody: cardContent.jsonBody,
            jsonAttachment: cardContent.jsonAttachment,
            appInfo: cardContent.appInfo
        )
    }

    public static func transform(pb: TranslatePBModel) -> CardContent {
        return transform(cardContent: pb.content.cardContent)
    }

    public func complement(entity: RustPB.Basic_V1_Entity, message: Message) {
        if let translatePB = entity.translateMessages[message.id] {
            message.translateState = .translated
            message.atomicExtra.unsafeValue.translateContent = CardContent.transform(pb: translatePB)
        }
    }
}
