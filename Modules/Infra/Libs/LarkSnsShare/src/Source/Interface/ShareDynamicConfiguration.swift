//
//  ShareDynamicConfiguration.swift
//  LarkSnsShare
//
//  Created by shizhengyu on 2020/11/12.
//

import Foundation
import RxSwift

/// 详见 https://bytedance.feishu.cn/docs/doccngbnlPSCV7NQ7CuXLy19RJn#

public enum PanelItem: Hashable {
    case wechatSession // 由于应用瘦身原因，仅在飞书内支持
    case wechatTimeline // 由于应用瘦身原因，仅在飞书内支持
    case wechatFavorite  // 暂不支持
    case wechatSpecifiedSession // 暂不支持
    case qq // 由于应用瘦身原因，仅在飞书内支持
    case qqZone // 暂不支持
    case weibo // 由于应用瘦身原因，仅在飞书内支持
    case copyText
    case saveImage
    case shareImage
    case systemShare
    case custom(String) // 配置平台上自定义的 panelItem

    public var rawValue: String {
        switch self {
        case .wechatSession: return "wechat_session"
        case .wechatTimeline: return "wechat_timeline"
        case .wechatFavorite: return "wechat_favorite"
        case .wechatSpecifiedSession: return "wechat_specifiedSession"
        case .qq: return "qq"
        case .qqZone: return "qq_zone"
        case .weibo: return "weibo"
        case .copyText: return "copy_text"
        case .saveImage: return "save_image"
        case .shareImage: return "share_image"
        case .systemShare: return "system_share"
        case .custom(let identifier): return "custom_\(identifier)"
        }
    }

    public func toShareItem() -> LarkShareItemType {
        switch self {
        case .wechatSession: return .wechat
        case .wechatTimeline: return .timeline
        case .wechatFavorite: return .unknown
        case .wechatSpecifiedSession: return .unknown
        case .qq: return .qq
        case .qqZone: return .unknown
        case .weibo: return .weibo
        case .copyText: return .copy
        case .saveImage: return .save
        case .shareImage: return .shareImage
        case .systemShare: return .more(.default)
        case .custom: return .custom(CustomShareContext.default())
        }
    }

    public func toSnsType() -> SnsType? {
        switch self {
        case .wechatSession: return .wechat
        case .wechatTimeline: return .wechat
        case .wechatFavorite: return .wechat
        case .wechatSpecifiedSession: return .wechat
        case .qq: return .qq
        case .qqZone: return .qq
        case .weibo: return .weibo
        default: return nil
        }
    }

    public static func transform(rawValue: String) -> PanelItem {
        switch rawValue {
        case "wechat_session": return .wechatSession
        case "wechat_timeline": return .wechatTimeline
        case "wechat_favorite": return .wechatFavorite
        case "wechat_specifiedSession": return .wechatSpecifiedSession
        case "qq": return .qq
        case "qq_zone": return .qqZone
        case "weibo": return .weibo
        case "copy_text": return .copyText
        case "save_image": return .saveImage
        case "share_image": return .shareImage
        case "system_share": return .systemShare
        default: return .custom(rawValue)
        }
    }

    public static func == (lhs: PanelItem, rhs: PanelItem) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(rawValue)
    }
}

public enum AnswerType: Hashable {
    case ban      // 禁用
    case downgradeToSystemShare   // 降级为系统分享
    case downgradeToWakeupByTip   // 降级为操作提示弹窗
    case unknown  // 未知

    public var rawValue: String {
        switch self {
        case .ban: return "ban"
        case .downgradeToSystemShare: return "downgrade_to_system_share"
        case .downgradeToWakeupByTip: return "downgrade_to_wakeup_by_tip"
        case .unknown: return "unknown"
        }
    }

    public static func transform(rawValue: String) -> AnswerType {
        switch rawValue {
        case "ban": return .ban
        case "downgrade_to_system_share": return .downgradeToSystemShare
        case "downgrade_to_wakeup_by_tip": return .downgradeToWakeupByTip
        default: return .unknown
        }
    }

    public static func == (lhs: AnswerType, rhs: AnswerType) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(rawValue)
    }
}

public struct ShareDynamicConfiguration {
    public let traceId: String
    public var items: [PanelItem]
    public let answerTypeMapping: [PanelItem: AnswerType]

    public init(
        traceId: String,
        items: [PanelItem],
        answerTypeMapping: [PanelItem: AnswerType] = [:]
    ) {
        self.traceId = traceId
        self.items = items
        self.answerTypeMapping = answerTypeMapping
    }
}

public protocol ShareConfigurationProvider {
    func parse(traceId: String) -> Observable<ShareDynamicConfiguration>
}
