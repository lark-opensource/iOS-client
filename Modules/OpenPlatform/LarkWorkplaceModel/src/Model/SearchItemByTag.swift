//
//  SearchItemByTag.swift
//  LarkWorkplaceModel
//
//  Created by Shengxy on 2022/10/28.
//

import Foundation

/// ['lark/workplace/api/SearchItemByTag'] - request parameters
/// request parameters for search app in a certain category
public struct WPSearchCategoryAppRequestParams: Codable {
    /// empty string or app search keyword
    let query: String
    /// category id
    let tagId: String
    /// lark version number, eg: "5.27.0"
    let larkVersion: String
    /// locale for response data
    let locale: String
    /// this field is always true
    let needWidget: Bool
    /// need block or not
    let needBlock: Bool

    public init(query: String, tagId: String, larkVersion: String, locale: String, needWidget: Bool, needBlock: Bool) {
        self.query = query
        self.tagId = tagId
        self.larkVersion = larkVersion
        self.locale = locale
        self.needWidget = needWidget
        self.needBlock = needBlock
    }
}

/// ['lark/workplace/api/SearchItemByTag']
/// search app in a certain category
public struct WPSearchCategoryApp: Codable {
    /// installed app
    public let availableItems: [WPCategoryAppItem]?
    /// uninstalled isv app
    /// in following cases, the array is empty:
    /// 1. the number of installed apps exceeds 100
    /// 2. there is no uninstalled isv app in the current category
    public let unavailableItems: [WPCategoryAppItem]?
    /// category tag list
    public let categories: [WPCategory]?
    /// search result has more items
    public let hasMore: Bool?
    /// search key words
    public let query: String?
    /// category tag id
    public let categoryId: String?

    enum CodingKeys: String, CodingKey {
        case availableItems
        case unavailableItems
        case categories = "tag"
        case hasMore
        case query
        case categoryId = "tagId"
    }
}

/// application category
public struct WPCategory: Codable {
    /// category name, eg: "Recently used"
    public let categoryName: String
    /// category identifier
    public let categoryId: Int

    enum CodingKeys: String, CodingKey {
        case categoryName = "tagName"
        case categoryId = "tagId"
    }

    public init(categoryId: Int, categoryName: String) {
        self.categoryId = categoryId
        self.categoryName = categoryName
    }
}

/// app properties
public struct WPCategoryAppItem: Codable {
    /// item identifier
    public let itemId: String
    /// item name
    public let name: String
    /// item description
    public let desc: String?
    /// item icon key
    public let iconKey: String
    /// app store detail page url
    public let appStoreDetailPageURL: String?
    /// mobile app store redirect link
    public let appStoreRedirectURL: String?
    /// one app may have more than one abilities
    /// nil for app in app store
    public let itemAbility: Ability?
    /// app shared by other organization or not
    public let isSharedByOtherOrganization: Bool?
    /// shared tenant information
    public let sharedSourceTenantInfo: WPTenantInfo?

    enum CodingKeys: String, CodingKey {
        case itemId
        case name
        case desc
        case iconKey
        case appStoreDetailPageURL = "appstoreUrl"
        case appStoreRedirectURL = "applinkStoreUrl"
        case itemAbility
        case isSharedByOtherOrganization
        case sharedSourceTenantInfo
    }

    public init(itemId: String,
                name: String,
                desc: String?,
                iconKey: String,
                appStoreDetailPageURL: String?,
                appStoreRedirectURL: String?,
                itemAbility: Ability?,
                isSharedByOtherOrganization: Bool?,
                sharedSourceTenantInfo: WPTenantInfo?
    ) {
        self.itemId = itemId
        self.name = name
        self.desc = desc
        self.iconKey = iconKey
        self.appStoreDetailPageURL = appStoreDetailPageURL
        self.appStoreRedirectURL = appStoreRedirectURL
        self.itemAbility = itemAbility
        self.isSharedByOtherOrganization = isSharedByOtherOrganization
        self.sharedSourceTenantInfo = sharedSourceTenantInfo
    }
}

extension WPCategoryAppItem {
    /// item ability
    public struct Ability: OptionSet, Codable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let bot = Ability(rawValue: 1 << 0)  // 0b00001 = bot
        public static let widget = Ability(rawValue: 1 << 1)   // 0b00010 = widget
        public static let miniApp = Ability(rawValue: 1 << 2)  // 0b00100 = mini-app
        public static let web = Ability(rawValue: 1 << 3)  // 0b01000 = web
        public static let applink = Ability(rawValue: 1 << 4)  // 0b10000 = applink
    }
}
