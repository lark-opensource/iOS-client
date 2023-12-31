//
//  GetTemplateWorkplaceHome.swift
//  LarkWorkplaceModel
//
//  Created by Shengxy on 2022/10/26.
//

import Foundation

/// ['lark/workplace/api/GetTemplateWorkplaceHome'] - request parameters
/// request paramaters for getting template portal's module
struct WPGetTempalteModuleRequestParams: Codable {
    /// lark version number, eg: "5.27.0"
    let larkVersion: String
    /// locale for response data
    let locale: String
    /// list of param each containing component index
    let moduleReqList: [Component]?
}

extension WPGetTempalteModuleRequestParams {
    /// properties for component indexing
    struct Component: Codable {
        /// component identifier, for component index
        let componentId: String
        /// component category
        let moduleType: WPTemplateModule.ComponentDetail.Category
        /// inner structure could be empty dictionary or Block
        let params: String
    }
}

extension WPGetTempalteModuleRequestParams.Component {
    /// properties for block indexing
    struct Block: Codable {
        /// block instance identifier
        /// same block on different devices could have different blockId
        let blockId: String
        /// application item identifier, for index
        let itemId: String
    }
}

/// ['lark/workplace/api/GetTemplateWorkplaceHome'] - response data
/// template portal module
public struct WPTemplateModule: Codable {
    /// template portal components' child node information
    let moduleDataList: [ComponentDetail]
}

extension WPTemplateModule {
    /// template portal component's child node information
    public struct ComponentDetail: Codable {
        /// error code
        let code: Int?
        /// error message
        let msg: String?
        /// component identifier, for component index
        let componentId: String?
        /// component type related data
        let data: JSONString<Bind4<Block, Favorite, FeedList, FeedSwiper>>?

        /// module category
        let moduleType: Category?
    }
}

extension WPTemplateModule.ComponentDetail {
    /// component category
    /// enum cases 1-5:  these fields are no longer supported on the server
    enum Category: Int, Codable {
        /// no longer supported on the server
        case common = 1
        /// no longer supported on the server
        case recommend = 2
        /// no longer supported on the server
        case customCategory = 3
        /// no longer supported on the server
        case officialCategory = 4
        /// no longer supported on the server
        case appList = 5
        /// commonly used & recommended app
        case favorite = 6
        /// normal block list
        case blockList = 7
    }

    /// template portal block component's child node information
    public struct Block: Codable {
        /// block application properties
        public let itemInfo: WPAppItem
    }

    /// template portal common and recommend component's child node information
    public struct Favorite: Codable {
        /// config of common and recommend component
        public let config: Config?
        /// tag of each application in favorite area
        public let favoriteItems: [AppTag]
        /// key: item identifier of each application in favorite area
        /// value: properties of each application in favorite area
        public let favoriteItemInfos: [String: WPAppItem]
        /// tag of each application in recently used area
        public let recentItems: [AppTag]?
        /// key: item identifier of each application in recently used area
        /// value: properties of each application in recently used area
        public let recentItemInfos: [String: WPAppItem]?
        /// settings of common and recommend component
        public let settingInfo: Settings?

        enum CodingKeys: String, CodingKey {
            case config = "commonBlockConfig"
            case favoriteItems = "children"
            case favoriteItemInfos = "itemInfos"
            case recentItems
            case recentItemInfos
            case settingInfo
        }
    }

    /// template portal feedlist component's child node information
    /// old version, no longer supported on current workplace editor
    @available(*, deprecated, message: "FeedList not available")
    struct FeedList: Codable {
        /// tab model
        let feeds: [FeedTab]
    }

    /// template portal feedswiper component's child node information
    /// old version, no longer supported on current workplace editor
    @available(*, deprecated, message: "FeedSwiper not available")
    struct FeedSwiper: Codable {
        /// item model
        let feeds: [WPFeedItem]
    }
}

extension WPTemplateModule.ComponentDetail.Favorite {
    /// config
    public struct Config: Codable {
        /// sub module list
        public let subModules: [SubModule]?
        /// title of favorite module
        public let favoriteTitle: Title
        /// icon of favorite module
        public let favoriteIconURL: String?
        /// title of recently used module
        public let recentTitle: Title
        /// icon of recently used module
        public let recentIconURL: String?

        enum CodingKeys: String, CodingKey {
            case subModules
            case favoriteTitle = "commonTitle"
            case favoriteIconURL = "commonIconURL"
            case recentTitle = "recentTitle"
            case recentIconURL = "recentIconURL"
        }
    }

    public struct Settings: Codable {
        public let url: String?
    }

    /// application tag
    public struct AppTag: Codable {
        /// application item identifier, for index
        public let itemId: String?
        /// application type
        public let type: AppType?
        /// application type
        public let subType: AppSubType?
        /// application display size (only blocks have this field)
        public let size: DisplaySize?
    }

    /// application display size
    public enum DisplaySize: String, Codable {
        case large
        case medium
        case small
    }

    /// application type
    public enum AppType: String, Codable {
        /// widget
        case widget
        /// block
        case block
        /// icon
        case icon
        /// nonstandard block
        case nonStandardBlock = "non_standard_block"
    }

    /// application type
    public enum AppSubType: String, Codable {
        /// commonly used and recommend application (used by native portal)
        case normal
        /// commonly used application (user-picked)
        case common
        /// non-removable recommend application (admin-picked)
        case recommend
        /// neither commonly used nor recommend application
        case available
        /// removable recommend application (admin-picked)
        case deletableRecommend = "distributed_recommend"
        /// add app icon (only valid in native portal)
        case systemAdd = "system_add"
        /// widget (only valid in native portal)
        case platformWidget = "platform_widget"
        /// block application (only valid in native portal)
        case platformBlock = "platform_block"
    }
}

extension WPTemplateModule.ComponentDetail.Favorite.Config {
    /// sub module type
    public enum SubModule: String, Codable {
        case favorite = "common"
        case recentlyUsed = "recent"
    }

    /// title of sub module
    public struct Title: Codable {
        /// default locale
        public let defaultLocale: String
        /// text for different locale
        public let text: [String: String]

        enum CodingKeys: String, CodingKey {
            case defaultLocale = "default_locale"
            case text
        }
    }
}

extension WPTemplateModule.ComponentDetail.FeedList {
    /// data model of one tab in feedlist
    struct FeedTab: Codable {
        /// tab index
        let id: String
        /// the name of the tab, i18n dictionary
        let tabName: [String: String]
        /// feed items in current tab
        let list: [WPFeedItem]
    }
}

/// item properties
public struct WPAppItem: Codable {
    /// item identifier, for item index
    public let itemId: String
    /// item name
    public let name: String
    /// item type
    public let itemType: AppType
    /// application identifier
    /// valid when the current item is a real app (not link)
    public let appId: String?
    /// correspond bot identifier
    /// valid when the current app support bot
    public let botId: String?
    /// custom redirect url
    /// valid when the item type is link
    public let linkURL: String?
    /// application description
    public let desc: String?
    /// key for icon image url generation
    public let iconKey: String?
    /// icon url ( itemType = customLinkInAppList )
    public let iconURL: String?
    /// key for switching to native tab
    public let nativeAppKey: String?
    /// is new application or not (only used in native portal)
    public let isNew: Bool?
    /// badge configuration
    public let badgeInfo: JSONString<[WPBadge]>?
    /// basic properties of block application
    public let block: WPBlockInfo?
    /// application redirect url
    public let url: OpenURL?
    /// default app feature on mobile - set when the developer releases their app
    /// "default app feature " determines which feature turns on when user opens your app through workplace.
    public let mobileDefaultAbility: AppAbility?
    /// default app feature on pc - set when the developer releases their app
    public let pcDefaultAbility: AppAbility?
    /// block device preview token
    public let previewToken: String?
    /// app shared by other organization or not
    public let isSharedByOtherOrganization: Bool?
    /// shared tenant information
    public let sharedSourceTenantInfo: WPTenantInfo?
    /// whether could be opened by browser
    public let openBrowser: Bool?
    /// 是否支持设置角标
    public let badgeAuthed: Bool?

    enum CodingKeys: String, CodingKey {
        case itemId
        case name
        case itemType
        case appId
        case botId
        case linkURL = "linkUrl"
        case desc
        case iconKey
        case iconURL = "iconUrl"
        case nativeAppKey
        case isNew
        case badgeInfo
        case block
        case url
        case mobileDefaultAbility
        case pcDefaultAbility
        case previewToken
        case isSharedByOtherOrganization
        case sharedSourceTenantInfo
        case openBrowser
        case badgeAuthed
    }

    init(
        itemId: String,
        name: String,
        itemType: AppType,
        appId: String?,
        botId: String?,
        linkURL: String?,
        desc: String?,
        iconKey: String?,
        iconURL: String?,
        nativeAppKey: String?,
        isNew: Bool?,
        badgeInfo: JSONString<[WPBadge]>?,
        block: WPBlockInfo?,
        url: OpenURL?,
        mobileDefaultAbility: AppAbility?,
        pcDefaultAbility: AppAbility?,
        previewToken: String?,
        isSharedByOtherOrganization: Bool?,
        sharedSourceTenantInfo: WPTenantInfo?,
        openBrowser: Bool?,
        badgeAuthed: Bool?
    ) {
        self.itemId = itemId
        self.name = name
        self.itemType = itemType
        self.appId = appId
        self.botId = botId
        self.linkURL = linkURL
        self.desc = desc
        self.iconKey = iconKey
        self.iconURL = iconURL
        self.nativeAppKey = nativeAppKey
        self.isNew = isNew
        self.badgeInfo = badgeInfo
        self.block = block
        self.url = url
        self.mobileDefaultAbility = mobileDefaultAbility
        self.pcDefaultAbility = pcDefaultAbility
        self.previewToken = previewToken
        self.isSharedByOtherOrganization = isSharedByOtherOrganization
        self.sharedSourceTenantInfo = sharedSourceTenantInfo
        self.openBrowser = openBrowser
        self.badgeAuthed = badgeAuthed
    }

    public static func buildBlockDemoItem(appId: String, blockInfo: WPBlockInfo, previewToken: String? = nil) -> WPAppItem {
        return WPAppItem(
            itemId: "",
            name: "",
            itemType: .nonstandardBlock,
            appId: appId,
            botId: nil,
            linkURL: nil,
            desc: nil,
            iconKey: nil,
            iconURL: nil,
            nativeAppKey: nil,
            isNew: nil,
            badgeInfo: nil,
            block: blockInfo,
            url: nil,
            mobileDefaultAbility: nil,
            pcDefaultAbility: nil,
            previewToken: previewToken,
            isSharedByOtherOrganization: nil,
            sharedSourceTenantInfo: nil,
            openBrowser: nil,
            badgeAuthed: nil
        )
    }

    public static func buildAddItem() -> WPAppItem {
        return WPAppItem(
            itemId: "",
            name: "",
            itemType: .normalApplication,
            appId: nil,
            botId: nil,
            linkURL: nil,
            desc: nil,
            iconKey: nil,
            iconURL: nil,
            nativeAppKey: nil,
            isNew: nil,
            badgeInfo: nil,
            block: nil,
            url: nil,
            mobileDefaultAbility: nil,
            pcDefaultAbility: nil,
            previewToken: nil,
            isSharedByOtherOrganization: nil,
            sharedSourceTenantInfo: nil,
            openBrowser: nil,
            badgeAuthed: nil
        )
    }
}

extension WPAppItem {
    /// application ability, different open strategy
    public enum AppAbility: Int, Codable {
        /// unknown
        case unknown = 0
        /// miniapp
        case miniApp = 1
        /// web, h5
        case web = 2
        /// bot
        case bot = 3
        /// widget (deprecated)
        case widget = 4
        /// native app
        case native = 5
    }

    /// application type, different appearance, different shown area
    /// enum cases 3,4,6:  these fields are no longer supported on the server
    public enum AppType: Int, Codable {
        /// icon and block shown in 'common and recommend' area
        /// standard block will be shown in block way
        /// unstandard block will be shown in icon way
        case normalApplication = 1
        /// tenant custom application (use 'Approval' template, eg: "Purchase" app)
        case tenantDefineApplication = 2
        /// no longer supported on the server
        case personCustom = 3
        /// no longer supported on the server
        case native = 4
        /// nonstandard block shown in areas except 'common and recommend'
        case nonstandardBlock = 5
        /// custom link in app list block
        case customLinkInAppList = 6
        /// common and recommend component (not really an application)
        case favorite = 7
        /// pure link
        case link = 8
    }

    /// application open url
    public struct OpenURL: Codable {
        /// enable offline h5 package or not
        public let offlineWeb: Bool?
        /// mobile app link (high priority)
        public let mobileAppLink: String?
        /// mobile web application redirect url
        public let mobileWebURL: String?
        /// mobile mini-app redirect url
        public let mobileMiniAppURL: String?
        /// mobile widget card schema (native portal)
        public let mobileCardWidgetURL: String?
        /// pc web application redirect url
        public let pcWebURL: String?
        /// pc mini-app redirect url
        public let pcMiniAppURL: String?
        /// pc app link (high priority)
        public let pcAppLink: String?
        /// pc widget card schema (native portal)
        public let pcCardWidgetURL: String?

        enum CodingKeys: String, CodingKey {
            case offlineWeb
            case mobileAppLink
            case mobileWebURL = "mobileH5Url"
            case mobileMiniAppURL = "mobileMpUrl"
            case mobileCardWidgetURL = "mobileCardWidgetUrl"
            case pcWebURL = "pcH5Url"
            case pcMiniAppURL = "pcMpUrl"
            case pcAppLink
            case pcCardWidgetURL = "pcCardWidgetUrl"
        }
    }
}

/// application's badge configuration
public struct WPBadge: Codable {
    /// application identifier
    public let appId: String
    /// supported client type
    public let clientType: ClientType
    /// supported application type
    public let appAbility: AppType
    /// primary key in a database table
    public let id: Int64
    /// version number
    /// used to do data source filtering, higher version preferred
    public let version: Int64
    /// badge update time
    public let updateTime: Int64
    /// the number of unread notifications
    public let badgeNum: Int64
    /// enable or disable show badge
    /// false when user disable show badge settings or in ttc blacklist
    /// the user can change the enable/disable status on application's about page
    /// the user can change the enable/disable status on workplace settings page(on navigation bar)
    public let needShow: Bool
    /// extra parameters for application developer
    public let extra: String?

    enum CodingKeys: String, CodingKey {
        case appId = "clientId"
        case clientType
        case appAbility
        case id
        case version
        case updateTime
        case badgeNum
        case needShow
        case extra
    }

    public init(appId: String, clientType: ClientType, appAbility: AppType, id: Int64, version: Int64, updateTime: Int64, badgeNum: Int64, needShow: Bool, extra: String?) {
        self.appId = appId
        self.clientType = clientType
        self.appAbility = appAbility
        self.id = id
        self.version = version
        self.updateTime = updateTime
        self.badgeNum = badgeNum
        self.needShow = needShow
        self.extra = extra
    }
}

extension WPBadge {
    /// application type that supports badge
    public enum AppType: Int, Codable {
        /// mini application
        case miniApp = 1
        /// h5 web application
        case web = 2
    }

    /// client type that supports badge
    public enum ClientType: Int, Codable {
        /// PC client
        case pc = 1
        /// iOS / Android client
        case mobile = 2
    }
}

/// block application basic properties
public struct WPBlockInfo: Codable, Equatable {
    /// block instance identifier
    /// same block on different devices could have different blockId
    public let blockId: String
    /// blockTypeId is an unique identifier for a centain developed block
    /// one application can have more than one blockTypeId
    public let blockTypeId: String
    /// has setting menu item or not
    public let hasSetting: Bool?
    /// settings redirect url
    public let settingURL: String?
    /// block header title
    public let title: [String: String]?
    /// block header redirect url
    public let schema: String?
    /// block header icon url
    public let titleIconURL: String?
    /// when user preferred language doesn't exist in supported language list,
    /// using the 'defaultLocale' as the shown language
    public let defaultLocale: String?

    enum CodingKeys: String, CodingKey {
        case blockId
        case blockTypeId
        case hasSetting
        case settingURL = "settingUrl"
        case title = "i18nName"
        case schema = "linkURL"
        case titleIconURL = "iconURL"
        case defaultLocale

    }

    public init(blockId: String, blockTypeId: String, hasSetting: Bool?=nil, settingURL: String?=nil, title: [String : String]?=nil, schema: String?=nil, titleIconURL: String?=nil, defaultLocale: String?=nil) {
        self.blockId = blockId
        self.blockTypeId = blockTypeId
        self.hasSetting = hasSetting
        self.settingURL = settingURL
        self.title = title
        self.schema = schema
        self.titleIconURL = titleIconURL
        self.defaultLocale = defaultLocale
    }
}

/// feed item's properties
struct WPFeedItem: Codable {
    /// the icon url of the feed item
    let imageURL: String?
    /// the redirect url of the feed item
    let url: String?
    /// the title of the feed item
    let title: String?
    /// the description text of the feed item
    let description: String?
    /// the date string of the feed item
    let date: String?

    enum CodingKeys: String, CodingKey {
        case imageURL = "imageUrl"
        case url
        case title
        case description
        case date
    }
}

/// tenant related information
public struct WPTenantInfo: Codable {
    /// tenant identifier
    public let id: String
    /// tenant name
    public let name: String

    enum CodingKeys: String, CodingKey {
        case id = "tenantID"
        case name = "tenantName"
    }
}
