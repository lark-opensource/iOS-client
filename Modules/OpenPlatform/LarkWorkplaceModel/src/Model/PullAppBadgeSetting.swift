//
//  PullAppBadgeSetting.swift
//  LarkWorkplaceModel
//
//  Created by Shengxy on 2022/10/27.
//

import Foundation

/// ['lark/app_badge/api/PullAppBadgeSetting'] - request parameters
/// request parameters for getting badge settings
struct WPGetBadgeSettingsRequestParams: Codable {
    /// page size, max 100
    let pageSize: Int
    /// token to get the next badge settings page data
    let pageToken: String?

    enum CodingKeys: String, CodingKey {
        case pageSize = "page_size"
        case pageToken = "page_token"
    }
}

/// ['lark/app_badge/api/PullAppBadgeSetting']
/// get all badge settings for current user
struct WPBadgeSettings: Codable {
    /// has more badge settings or not
    let hasMore: Bool
    /// token to get the next badge settings page data
    let pageToken: String?
    /// badge setting list
    let items: [WPBadgeSetting]?

    enum CodingKeys: String, CodingKey {
        case hasMore = "has_more"
        case pageToken = "page_token"
        case items
    }
}

/// badge setting item
struct WPBadgeSetting: Codable {
    /// application id
    let appId: String
    /// application name
    let name: String
    /// application i18n name
    let i18nName: [String: String]?
    /// avatar key
    let avatarKey: String
    /// badge enabled (user level)
    let needShow: Bool

    enum CodingKeys: String, CodingKey {
        case appId = "client_id"
        case name
        case i18nName = "i18n_name"
        case avatarKey = "avatar_key"
        case needShow = "need_show"
    }
}
