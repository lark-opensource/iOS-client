//
//  AppBadgeSettingModel.swift
//  LarkWorkplace
//
//  Created by houjihu on 2020/12/21.
//

import Foundation
import SwiftyJSON
import LKCommonsLogging

/// 批量拉取用户的 badge 开关数据模型
struct AppBadgeSettingModel: Codable {
    /// 表示是否存在下一页，true 表示存在。
    var hasMore: Bool
    /// 分页令牌，has_more 为 false 时没有此字段。
    var pageToken: String?
    /// 应用的 badge 开关集合。
    var items: [AppBadgeSettingItem]?

    enum CodingKeys: String, CodingKey {
        case hasMore = "has_more"
        case pageToken = "page_token"
        case items
    }

    /// 合并两个model的数据，状态以最后一个model为主
    static func merge(former: AppBadgeSettingModel, with later: AppBadgeSettingModel) -> AppBadgeSettingModel {
        var items = former.items
        if let formerItems = items, let laterItems = later.items {
            items = formerItems + laterItems
        } else {
            items = later.items
        }
        return AppBadgeSettingModel(hasMore: later.hasMore, pageToken: later.pageToken, items: items)
    }
}

/// 单个badge 开关数据模型
struct AppBadgeSettingItem: Codable {
    /// cli_ 开头的应用 ID。
    let clientID: String
    /// 应用名称
    let name: String
    /// 应用国际化名称，建议不存在时使用 name 兜底。
    let i18nName: [String: String]?
    /// 应用的头像 TOS key。
    let avatarKey: String
    /// 应用的 badge 开关，true 表示允许通知。
    var needShow: Bool

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case name
        case i18nName = "i18n_name"
        case avatarKey = "avatar_key"
        case needShow = "need_show"
    }
}
