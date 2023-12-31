//
//  CardData.swift
//  UniversalCardInterface
//
//  Created by ByteDance on 2023/8/4.
//

import Foundation
import RustPB

public class UniversalCardData: Equatable {
    public typealias ActionStatus = Basic_V1_UniversalCardEntity.ActionStatus
    public typealias LocalStatus = String

    // 卡片 ID ,唯一标识符
    public let cardID: String
    // 卡片版本
    public let version: String

    // 外部业务相关
    public let bizID: String
    public let bizType: Int
    // 卡片来源相关
    public let appInfo: Basic_V1_CardAppInfo?

    // 卡片内容, 包含 Card JSON 及附属数据
    public let cardContent: UniversalCardContent
    // 翻译内容, 包含 Card JSON 及附属数据
    public let translateContent: UniversalCardContent?
    // 组件内部状态, 端上不消费
    public let actionStatus: Basic_V1_UniversalCardEntity.ActionStatus
    // Card 实体存的本地数据, 包含了卡片状态
    public let localExtra: Dictionary<Int32,String>
    // 本地存储的卡片状态
    public var localStatus: LocalStatus? {
        localExtra[Int32(
            Basic_V1_UniversalCardEntity.LocalExtraKey.openPlatformMessageCard.rawValue
        )]
    }

    // 卡片数据信任 version, 如果 version 相同意味着内容相同, 若后期这个规则有改变需要修改判断条件.
    // localState 不作为判断条件, 因为在运行时本地存储会频繁变更.
    public static func == (left: UniversalCardData, right: UniversalCardData) -> Bool {
        return left.cardID == right.cardID &&
        left.version == right.version &&
        left.cardContent == right.cardContent &&
        left.translateContent == right.translateContent &&
        left.actionStatus == right.actionStatus
    }

    // 从 PB 做转换
    public static func transform(entity: Basic_V1_UniversalCardEntity) -> UniversalCardData {
        return UniversalCardData(
            cardID: entity.cardID,
            version: entity.version,
            bizID: entity.bizID,
            bizType: entity.bizType.rawValue,
            cardContent: UniversalCardContent.transform(pb: entity.content),
            translateContent: nil,
            actionStatus: entity.actionStatus,
            localExtra: entity.localExtra,
            appInfo: nil // url 卡片现在没有 appInfo
        )
    }

    public init(
        cardID: String,
        version: String,
        bizID: String,
        bizType: Int,
        cardContent: UniversalCardContent,
        translateContent: UniversalCardContent?,
        actionStatus: ActionStatus,
        localExtra: [Int32: String],
        appInfo: Basic_V1_CardAppInfo?
    ) {
        self.cardID = cardID
        self.version = version
        self.bizID = bizID
        self.bizType = bizType
        self.cardContent = cardContent
        self.translateContent = translateContent
        self.actionStatus = actionStatus
        self.localExtra = localExtra
        self.appInfo = appInfo
    }
}

public struct UniversalCardDataActionSourceInfo {
    // 卡片 ID ,唯一标识符
    public let cardID: String
    // 卡片版本
    public let version: String

    // 外部业务相关
    public let bizID: String
    public let bizType: Int

    private init(
        cardID: String,
        version: String,
        bizID: String,
        bizType: Int
    ) {
        self.cardID = cardID
        self.version = version
        self.bizID = bizID
        self.bizType = bizType
    }

    public static func from(_ cardData: UniversalCardData) -> UniversalCardDataActionSourceInfo {
        return UniversalCardDataActionSourceInfo(
            cardID: cardData.cardID,
            version: cardData.version,
            bizID: cardData.bizID,
            bizType: cardData.bizType
        )
    }
}

