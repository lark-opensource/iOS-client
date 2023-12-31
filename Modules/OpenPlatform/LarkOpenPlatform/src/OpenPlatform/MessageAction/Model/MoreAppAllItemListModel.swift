//
//  MoreAppAllItemListModel.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/5/8.
//

import Foundation
import LKCommonsLogging

/// 负责快捷索引页相关的log输出
let GuideIndexPageVCLogger = Logger.oplog(MoreAppListViewController.self, category: MessageActionPlusMenuDefines.messageActionLogCategory)

/// 业务场景
enum BizScene: String {
    /// +号菜单
    case addMenu
    /// MessageAction
    case msgAction
}

/// author: lilun.ios(November 17th, 2020 5:06pm) 
/// chore: message action url可配置，上报logID
/// 配置下发的接入企业自建应用url，文档 https://bytedance.feishu.cn/docs/doccnZn44QYwbv6bxCNwrSNt8Cb#bmrlRk
struct MessageActionUrl: Codable {
    let helpUrl: String?
}
struct GuideIndexInstructionUrl: Codable {
    let messageAction: MessageActionUrl?
    let plusMenu: MessageActionUrl?
    enum CodingKeys: String, CodingKey {
        case messageAction = "MessageAction"
        case plusMenu = "PlusMenu"
    }
}

/// 外露常用+更多应用列表数据
struct MoreAppAllItemListModel: Codable {
    var externalItemListModel: MoreAppExternalItemListModel
    var availableItemListModel: MoreAppAvailableItemListModel
}

/// 外化展示列表数据
struct MoreAppExternalItemListModel: Codable {
    /// 外化展示列表。不存在则可能无此字段(none)
    var externalItemList: [MoreAppItemModel]?
    /// 最小刷新间隔，单位：秒(s)
    let cacheExpireTime: Int?
    /// 外化展示常用应用的最大数量，默认为3
    let maxCommonItems: Int?
    /// 服务端时间戳
    let ts: Int?

    /// 本地更新时间戳
    var localUpdateTS: Int64?
    /// local cache key
    var cacheKey: String?
}

/// 更多应用列表数据
struct MoreAppAvailableItemListModel: Codable {
    /// 外化展示列表。不存在则可能无此字段(none)
    var availableItemList: [MoreAppItemModel]?
    /// 最小刷新间隔，单位：秒(s)
    let cacheExpireTime: Int?
    /// 服务端时间戳
    let ts: Int?
}

/// 外化展示数据
struct MoreAppItemModel: Codable, Equatable {
    let id: String
    let appId: String?
    /// 选填，应用名
    let name: String?
    /// 选填，应用描述
    let desc: String?
    let icon: MoreAppIconModel
    /// 选填，PC端AppLink
    let pcApplinkUrl: String?
    /// 选填，移动端AppLink
    let mobileApplinkUrl: String?
    /// 选填，消息快捷操作名
    let actionName: String?
    /// 对应的能力
    let requiredLaunchAbility: String?
    /// 必填，pc端是否可用
    let pcAvailable: Bool
    /// 必填，移动端是否可用
    let mobileAvailable: Bool
    /// 选填，消息快捷操作描述
    let itemDesc: String?
    /// 选填，应用目录详情页applink，仅ISV应用有该字段
    let appstoreDetailApplink: String?
    /// 选填，开发者用户ID，仅自建应用有该字段
    let developerUserId: String?
    /// 选填，开发者名字，仅自建应用有该字段
    let developerUserName: String?
    /// 选填，帮助文档，仅自建应用有该字段
    let helpDoc: String?

    static func == (lhs: MoreAppItemModel, rhs: MoreAppItemModel) -> Bool {
        return lhs.id == rhs.id && lhs.appId == rhs.appId
    }
}

/// 头像数据
struct MoreAppIconModel: Codable {
    let key: String
    let fsUnit: String?
}
