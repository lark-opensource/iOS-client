//
//  StatisticsDefine.swift
//  SpaceKit
//
//  Created by huahuahu on 2019/2/14.
//

import Foundation

// 埋点文档：https://bytedance.feishu.cn/docs/doccn86BHL0JUhqGDMwZyyzzMpc#
public enum FromSource: String, Equatable {

    case recent = "tab_recent"
    case sidebarRecent = "tab_sidebar_recent"
    case favorites = "tab_favorites" //收藏
    case personal = "tab_personal"
    case shareSpace = "tab_sharetome"
    case quickAccess = "tab_quickaccess"
    case search = "lark_search"
    case other = "tab_other"
    case larkCreate = "lark_create"
    case atInfo = "tab_at"
    case linkInDoc = "tab_link"
    // link
    case linkInParentDocs = "from_parent_docs"
    case linkInParentSheet = "from_parent_sheet"
    case linkInParentMindnote = "from_parent_mindnote"
    // todo中心
    case todo = "tab_todo"
    //doc 里点击创建
    case docCreate = "tab_create"
    // 全局公告
    case notice = "tab_notice"
    case personalFolder = "tab_personal_folder"
    case sharedFolder = "tab_shared_folder"
    /// 最近浏览的预加载
    case recentPreload = "recent_preload"
    /// 从单品的模板banner创建
    case fromOnboardingBanner = "from_onboarding_banner"
    /// 从创建面板的推荐模版新建
    case spaceTemplate = "space_template"
    /// 从模板中心新建
    case templateCenter = "new_template"
    /// 被移动到了wiki
    case moveToWiki = "move_to_wiki"
    /// 群Tab
    case groupTab = "chat_tabs_docPreview"
    /// 源文档历史版本
    case sourceVersionList = "source_version_list"
    /// 版本列表中切换
    case switchVersion = "switch_version"
    /// IM消息来源,单聊
    case chatP2P = "chat_p2p"
    /// IM消息来源,群聊
    case chatGroup = "chat_group"
    /// IM消息中的云文档tab
    case chatListTab = "space_list_tab"
    /// Bitable Home页面创建
    case bitableHome = "tab_lark_workspace_bitable_landing"
    case baseHomeLarkTabRecent = "base_hp_larktab_recent"
    case baseHomeLarkTabEmptyBase = "base_hp_larktab_empty_base"
    case baseHomeLarkTabForm = "base_hp_larktab_form"
    case baseHomeLarkTabQuickAccess = "base_hp_larktab_quickaccess"
    case baseHomeLarkTabFavorites = "base_hp_larktab_favorites"
    case baseHomeLarkTabComment = "base_hp_larktab_comment"
    case baseHomeLarkTabMention = "base_hp_larktab_mention"
    
    case baseHomeWorkbenchRecent = "base_hp_workbench_recent"
    case baseHomeWorkbenchEmptyBase = "base_hp_workbench_empty_base"
    case baseHomeWorkbenchForm = "base_hp_workbench_form"
    case baseHomeWorkbenchQuickAccess = "base_hp_workbench_quickaccess"
    case baseHomeWorkbenchFavorites = "base_hp_workbench_favorites"
    case baseHomeWorkbenchComment = "base_hp_workbench_comment"
    case baseHomeWorkbenchMention = "base_hp_workbench_mention"

    /// home v4 larktab
    case baseHomeLarkTabRecentV4 = "base_hp_larktab_recent_hpmobile_v2"
    case baseHomeLarkTabQuickAccessV4 = "base_hp_larktab_quickaccess_hpmobile_v2"
    case baseHomeLarkTabFavoritesV4 = "base_hp_larktab_favorites_hpmobile_v2"
    case baseHomeLarkTabEmptyBaseV4 = "base_hp_larktab_empty_base_hpmobile_v2"
    case baseHomeLarkTabFeedV4 = "homepage_feed_larktab_hpmobile_v2"
    /// home v4 workbench
    case baseHomeWorkbenchRecentV4 = "base_hp_workbench_recent_hpmobile_v2"
    case baseHomeWorkbenchQuickAccessV4 = "base_hp_workbench_quickaccess_hpmobile_v2"
    case baseHomeWorkbenchFavoritesV4 = "base_hp_workbench_favorites_hpmobile_v2"
    case baseHomeWorkbenchEmptyBaseV4 = "base_hp_workbench_empty_base_hpmobile_v2"
    case baseHomeWorkbenchFeedV4 = "homepage_feed_workbench_hpmobile_v2"

    /// SSR闲时预加载来源
    case ssrIdelpreload = "ssr_idle_preload"
    /// feed列表
    case docsFeed = "docs_feed"
    /// IM头部tab
    case chatTopTab = "top_doc_tab"
    /// 持久化来源
    case archedPreload = "db_preload_restore"
    /// DocsFeed Push
    case docsFeedPush = "docs_feed_push"
    case appcenter = "appcenter"
    /// IM Excel 文件通过 Sheet 打开
    case imExcel = "im_excel"
    ///  打开文档实时拉取
    case fetchBeforeRender = "fetch_before_render"
}

public struct PreloadFromSource: Equatable {
    public let source: FromSource?
    let unknownSource: String
    public init(rawValue: String) {
        self.source = FromSource(rawValue: rawValue)
        self.unknownSource = rawValue
    }
    public init(_ source: FromSource?) {
        self.source = source
        self.unknownSource = ""
    }
    public static func == (lhs: PreloadFromSource, rhs: PreloadFromSource) -> Bool {
        return lhs.source == rhs.source && lhs.unknownSource == lhs.unknownSource
    }
    public var rawValue: String {
        return source?.rawValue ?? unknownSource
    }
}

// 需求文档文档：https://bytedance.feishu.cn/docs/doccn5XGNH1Xy4tY80vA3mWZiNc
public let CCMOpenTypeKey = "ccm_open_type"

public enum CCMOpenType: String, Equatable {
    // MARK: 特殊的点
    /// 主端创建
    case larkTopbarCreate = "lark_topbar_create"

    // MARK: 文档中对应的点
    /// lark-云文档tab-主页-创建空白文档
    case homeCreateBlank = "home_CreateBlank"
    /// lark-云文档tab-主页-通过模板创建文档
    case homeCreateTemplate = "home_CreateTemplate"
    /// lark-云文档tab-主页-点击banner创建文档
    case homeCreateBanner = "home_CreateBanner"
    /// lark-云文档tab-主页-快速访问
    case homePin = "home_Pin"
    /// lark-云文档tab-主页-最近列表
    case homeRecent = "home_Recent"
    /// lark-云文档tab-我的空间-创建空白文档
    case personalCreateBlank = "personal_CreateBlank"
    /// lark-云文档tab-我的空间-通过模板创建文档
    case personalCreateTemplate = "personal_CreateTemplate"
    /// lark-云文档tab-我的空间-文件夹打开文档
    case personalFolder = "personal_Folder"
    /// lark-云文档tab-我的空间-归我所有模块打开
    case personalOwn = "personal_Own"
    /// lark-云文档tab-xxx-搜索
    case personalSearch = "personal_Search"
    /// lark-云文档tab-共享空间-创建空白文档
    case sharedCreateBlank = "shared_CreateBlank"
    /// lark-云文档tab-共享空间-通过模板创建文档
    case sharedCreateTemplate = "shared_CreateTemplate"
    /// lark-云文档tab-共享空间-共享文件夹打开文档 
    case sharedSharedFolder = "shared_SharedFolder"
    /// lark-云文档tab-共享空间-与我共享列表打开文档
    case sharedShareToMe = "shared_ShareToMe"
    /// lark-云文档tab-wiki主页-新建wiki
    case wikiCreateNew = "wiki_CreateNew"
    /// lark-云文档tab-wiki主页-收藏
    case wikiAll = "wiki_All"
    /// lark-云文档tab-wiki主页-全部wiki列表
    case wikiRecent = "wiki_Recent"
    /// lark-云文档tab-收藏
    case favorites = "favorites"
    /// lark-云文档tab-离线打开
    case offline = "offline"
    /// lark-云文档tab-模版库-新建模版
    case spaceTemplate = "spaceTemplate"
    /// lark-工作台tab- bitable主页-新建bitable
    case bitableHome = "lark_workspace_bitable_landing"
    /// lark-消息卡片-bitable记录卡片
    case recordMessage = "record_message"
    
    case baseHomeLarkTabRecent = "base_hp_larktab_recent"
    case baseHomeLarkTabEmptyBase = "base_hp_larktab_empty_base"
    case baseHomeLarkTabForm = "base_hp_larktab_form"
    case baseHomeLarkTabQuickAccess = "base_hp_larktab_quickaccess"
    case baseHomeLarkTabFavorites = "base_hp_larktab_favorites"
    case baseHomeLarkTabComment = "base_hp_larktab_comment"
    case baseHomeLarkTabMention = "base_hp_larktab_mention"
    
    case baseHomeWorkbenchRecent = "base_hp_workbench_recent"
    case baseHomeWorkbenchEmptyBase = "base_hp_workbench_empty_base"
    case baseHomeWorkbenchForm = "base_hp_workbench_form"
    case baseHomeWorkbenchQuickAccess = "base_hp_workbench_quickaccess"
    case baseHomeWorkbenchFavorites = "base_hp_workbench_favorites"
    case baseHomeWorkbenchComment = "base_hp_workbench_comment"
    case baseHomeWorkbenchMention = "base_hp_workbench_mention"

    /// home v4 larktab
    case baseHomeLarkTabRecentV4 = "base_hp_larktab_recent_hpmobile_v2"
    case baseHomeLarkTabQuickAccessV4 = "base_hp_larktab_quickaccess_hpmobile_v2"
    case baseHomeLarkTabFavoritesV4 = "base_hp_larktab_favorites_hpmobile_v2"
    case baseHomeLarkTabEmptyBaseV4 = "base_hp_larktab_empty_base_hpmobile_v2"
    case baseHomeLarkTabFeedV4 = "homepage_feed_larktab_hpmobile_v2"
    /// home v4 workbench
    case baseHomeWorkbenchRecentV4 = "base_hp_workbench_recent_hpmobile_v2"
    case baseHomeWorkbenchQuickAccessV4 = "base_hp_workbench_quickaccess_hpmobile_v2"
    case baseHomeWorkbenchFavoritesV4 = "base_hp_workbench_favorites_hpmobile_v2"
    case baseHomeWorkbenchEmptyBaseV4 = "base_hp_workbench_empty_base_hpmobile_v2"
    case baseHomeWorkbenchFeedV4 = "homepage_feed_workbench_hpmobile_v2"

    case baseInstructionDocx = "base_instruction_docx"

    case unknow = "unknow"

    public var trackValue: String {
        switch self {
        case .larkTopbarCreate:
            return rawValue
        case .bitableHome:
            return rawValue
        case .baseHomeLarkTabRecent, .baseHomeLarkTabEmptyBase, .baseHomeLarkTabForm,
                .baseHomeLarkTabQuickAccess, .baseHomeLarkTabFavorites, .baseHomeLarkTabComment,
                .baseHomeLarkTabMention, .baseHomeWorkbenchRecent, .baseHomeWorkbenchEmptyBase,
                .baseHomeWorkbenchForm, .baseHomeWorkbenchQuickAccess, .baseHomeWorkbenchFavorites,
                .baseHomeWorkbenchComment, .baseHomeWorkbenchMention,
                .baseHomeLarkTabRecentV4, .baseHomeLarkTabQuickAccessV4, .baseHomeLarkTabFavoritesV4, .baseHomeLarkTabEmptyBaseV4, .baseHomeLarkTabFeedV4,
                .baseHomeWorkbenchRecentV4, .baseHomeWorkbenchQuickAccessV4, .baseHomeWorkbenchFavoritesV4, .baseHomeWorkbenchEmptyBaseV4, .baseHomeWorkbenchFeedV4:
            return rawValue
        default:
            return "lark_docs_\(rawValue)"
        }
    }

    public static func getOpenType(by createSouce: CCMOpenCreateSource, isTemplate: Bool = false) -> CCMOpenType {
        switch createSouce {
        case .home:
            return isTemplate ? .homeCreateTemplate : .homeCreateBlank
        case .homeBanner:
            return .homeCreateBanner
        case .personal:
            return isTemplate ? .personalCreateTemplate : .personalCreateBlank
        case .shared:
            return isTemplate ? .sharedCreateTemplate : .sharedCreateBlank
        case .wiki:
            return .wikiCreateNew
        case .bitableHome:
            return .bitableHome
        case .baseHomeLarkTabEmptyBase:
            return .baseHomeLarkTabEmptyBase
        case .baseHomeWorkbenchEmptyBase:
            return .baseHomeWorkbenchEmptyBase
        case .baseHomeLarkTabForm:
            return .baseHomeLarkTabForm
        case .baseHomeWorkbenchForm:
            return .baseHomeWorkbenchForm
        case .lark:
            return .larkTopbarCreate
        case .templateCenter:
            return .spaceTemplate
        case .copy, .unknow:
            return .unknow
        case .baseHomeLarkTabEmptyBaseV4:
            return .baseHomeLarkTabEmptyBaseV4
        case .baseHomeWorkbenchEmptyBaseV4:
            return .baseHomeWorkbenchEmptyBaseV4
        }
    }
}

public enum CCMOpenCreateSource {
    case home
    case homeBanner
    case personal
    case shared
    case wiki
    case bitableHome
    case templateCenter //模版中心
    case copy //创建副本
    case lark //主端
    case unknow
    case baseHomeLarkTabEmptyBase
    case baseHomeWorkbenchEmptyBase
    case baseHomeLarkTabForm
    case baseHomeWorkbenchForm

    /// home v4 larktab
    case baseHomeLarkTabEmptyBaseV4
    /// home v4 workbench
    case baseHomeWorkbenchEmptyBaseV4

    public var isBaseHome: Bool {
        return self == .bitableHome
            || self == .baseHomeLarkTabEmptyBase
            || self == .baseHomeWorkbenchEmptyBase
            || self == .baseHomeLarkTabForm
        || self == .baseHomeWorkbenchForm
        || self == .baseHomeLarkTabEmptyBaseV4
        || self == .baseHomeWorkbenchEmptyBaseV4
    }
}

extension DocsTracker {
    public struct Params {
        public static let fileType = "file_type"
        public static let webviewTerminateCount = "doc_web_terminateCount"
        public static let docNetStatus = "doc_network_status"
        public static let docHasCached = "doc_has_cache"
        public static let preloadHtmlEnabled = "preload_html_enabled"
        public static let docFrom = "doc_from"
        public static let openDocDesc = "open_doc_desc"
        public static let hasShownLoading = "doc_has_shown_loading"
        public static let netChannel = "http_channel"
        public static let useMultiConnection = "doc_use_multi_connection"
        public static let httpRequestMethod = "http_request_method"
        public static let hasRustMetrics = "has_rust_metrics"

        public static let module     = "module"
        public static let fileId     = "file_id"
        public static let isOwner    = "is_owner"
        public static let action     = "action"
        public static let failReason = "fail_reason"
        public static let responseLentgh = "response_length"
        public static let downloadCostTime = "cost_time"
        public static let fontMd5 = "md5"
        public static let fontSource = "data_from"
        public static let fontSize = "length"
        public static let fontDownloadStage = "stage"
        public static let userid = "user_id"
        public static let nonSensitiveToken = "non_sensitive_token" //上报中包含文档token但是非敏感token时，设置此参数true可以避免assert
    }
}

extension NetworkType {
    /// 上报时的网络类型对应的整数
    public var intForStatistics: Int {
        switch self {
        case .wifi: return 1
        case .wwan4G: return 2
        case .wwan3G: return 3
        case .wwan2G: return 4
        case .notReachable: return 6
        }
    }
}
