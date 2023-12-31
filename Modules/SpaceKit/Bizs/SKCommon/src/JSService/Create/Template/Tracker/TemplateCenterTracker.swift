//
//  TemplateCenterTracker.swift
//  SKCommon
//
//  Created by bytedance on 2021/2/1.
//  swiftlint:disable file_length

import SKFoundation
import SpaceInterface
//import LarkAppCenter

//https://bytedance.feishu.cn/docs/doccnCyojrP8qh4yiBpqT8pLjPg#

public enum TemplateCenterTracker {
    /*
     // 模板中心banner曝光
     case showTemplateinnerbanner = "show_templateinnerbanner"
     // 模板中心用户点击banner
     case clickTemplateinnerbanner = "click_templateinnerbanner"
     // 模板中心搜索事件
     case templateSearch = "template_search"
     // 模板中心单个模板曝光事件
     case singletemplateExposure = "singletemplate_exposure"
     // 模板中心的曝光事件
     case enterTemplateCenter = "enter_template_center"
     */

    enum SearchAction: String {
        case clickSearchPlace = "click_searchplace"  // 点击搜索框
        case displaySearchRecommendWords = "display_searchrecommendwords" // 展示推荐搜索词
        case clickSearchRecommendWords = "click_searchrecommendwords" // 点击推荐搜索词
        case inputSearchwords = "Input_searchwords" // 当用户输入具体词进行搜索的时候上报
        case searchResult = "search_result" // 当有搜索结果的时候上报
        case clickSearchResultTemplate = "click_template_searchresult" // 点击搜索结果
        
    }

    /**
     1. from_onboarding_banner （新用户 banner）
     2. from_spacehometemplate_more（固定位）
     3. from_spacehometemplate_all_tab（固定位）
     4. from_space_icon （金刚位）
     5. from_newcreate_more （新建面板里的更多-套件）
     6. from_newcreate_templateicon （新建面板里的模板中心-单品）
     7. from_saveas_customtempl  (保存为自定义模板后，点击查看进入模板中心)
     */
    public enum EnterTemplateSource: String {
        case fromOnboardingBanner = "from_onboarding_banner"
        case fromSpacehometemplateMore = "from_spacehometemplate_more"
        case fromSpacehometemplateAllTab = "from_spacehometemplate_all_tab"
        case fromSpaceIcon = "from_space_icon"
        case fromNewcreateMore = "from_newcreate_more"
        case fromNewcreateTemplateicon = "from_newcreate_templateicon"
        case fromActivityBanner = "from_activity_banner"
        case fromSaveasCustomtempl = "from_saveas_customtempl"
        case wikiHomepageLarkSurvey = "wiki_home_create_form"
        case spaceHomepageLarkSurvey = "space_home_create_form"
        case spaceTemplate = "space_template" // 创建面板的推荐模板
        case createBlankDocs = "docs_newcreate_click" // 创建面板的新建空白文档按钮
        case docsBanner = "docs_banner"
        // bitable Home页
        case bitableHome = "bitable_ws_landing_template"
        //bitable Home页点击Banner进入模版中心
        case bitableHomeBanner = "bitable_ws_landing_banner"
        //bitable Home页点击+号按钮进入模版中心
        case bitableHomeCreateLarktab = "base_hp_landing_templates_larktab_bitable"
        case bitableHomeCreateWorkbench = "base_hp_landing_templates_workbench"
        case baseHomepageBannerTemplatesLarktab = "base_hp_banner_templates_larktab_bitable"
        case baseHomepageBannerTemplatesWorkbench = "base_hp_banner_templates_workbench"
        case baseHomepageBannerItemLarktab = "base_hp_banner_item_larktab_bitable"
        case baseHomepageBannerItemWorkbench = "base_hp_banner_item_workbench"
        case larkSurvey = "lark_survey"
        case baseHomepageLarkSurvey = "base_hp_create_form"
        /// 下面三个是applink进来的时候带入的
        case botDocs = "bot_docs"
        case botAdmin = "bot_admin"
        case botFeishu = "bot_feishu"
        case promotionalDocs = "promotional_docs"

        var isFromBitableHome: Bool {
            self == .bitableHome
            || self == .bitableHomeBanner
            || self == .bitableHomeCreateLarktab
            || self == .bitableHomeCreateWorkbench
            || self == .baseHomepageBannerTemplatesLarktab
            || self == .baseHomepageBannerTemplatesWorkbench
            || self == .baseHomepageBannerItemLarktab
            || self == .baseHomepageBannerItemWorkbench
        }

        func toTemplateSource() -> TemplateSource? {
            switch self {
            case .fromOnboardingBanner: return .onboardingDoc
            case .fromSpacehometemplateMore: return .createNewMore
            case .fromSpaceIcon: return .spaceTemplate
            case .fromNewcreateTemplateicon: return .createNewMore
            case .spaceHomepageLarkSurvey: return .spaceHomepageLarkSurvey
            case .createBlankDocs: return .createNewTemplate
            case .docsBanner: return .docsBanner
            case .bitableHome: return .bitableHome
            case .bitableHomeCreateLarktab: return .bitableHomeCreateLarktab
            case .bitableHomeCreateWorkbench: return .bitableHomeCreateWorkbench
            case .baseHomepageBannerTemplatesLarktab: return .baseHomepageBannerTemplatesLarktab
            case .baseHomepageBannerTemplatesWorkbench: return .baseHomepageBannerTemplatesWorkbench
            case .baseHomepageBannerItemLarktab: return .baseHomepageBannerItemLarktab
            case .baseHomepageBannerItemWorkbench: return .baseHomepageBannerItemWorkbench
            case .larkSurvey: return .lark_survey
            case .baseHomepageLarkSurvey: return .baseHomepageLarkSurvey
            default: return nil
            }
        }
    }
    /// 模版曝光位置
    enum TemplateExposureType: String {
        case center = "from_templatecenter" // 模版中心
        case preview = "from_preview"// 场景化模版预览页
        case announcement = "from_im_chat_announcement" // 群公告底部模版列表
    }
    /// 点击预览的位置
    enum ClickTemplatePreviewPosition: String {
        case center = "from_templatecenter"// 模版中心
        case collection = "from_set" // 场景化模版预览页
        case announcement = "from_im_chat_announcement" // 群公告模版预览
    }

    public struct TemplateSource: Hashable, RawRepresentable {
        public var rawValue: String
        
        public static let spaceTemplate = TemplateSource("space_template") // 云文档模板库icon
        public static let createNewTemplate = TemplateSource("create_new_template") // 云文档新建面板新建文档按钮
        public static let createNewMore = TemplateSource("create_new_more") // 云文档新建面板更多按钮
        public static let chatLink = TemplateSource("chat_link") // 点击IM中分享的链接进入模板中心
        public static let onboardingDoc = TemplateSource("onboarding_doc") // 新人文档的领取模板链接
        public static let spaceBanner = TemplateSource("space_banner") // 云文档banner
        public static let spaceHomepageLarkSurvey = TemplateSource("space_home_create_form")
        public static let wikiHomepageLarkSurvey = TemplateSource("wiki_home_create_form")
        public static let docsBanner = TemplateSource("docs_banner") // 系统模板文档banner
        public static let bitableHome = TemplateSource("bitable_ws_landing_template")
        public static let bitableHomeBanner = TemplateSource("bitable_ws_landing_banner") //bitableHome页banner
        //bitable Home页点击+号按钮进入模版中心
        public static let bitableHomeCreateLarktab = TemplateSource("base_hp_landing_templates_larktab_bitable")
        public static let bitableHomeCreateWorkbench = TemplateSource("base_hp_landing_templates_workbench")
        public static let baseHomepageBannerTemplatesLarktab = TemplateSource("base_hp_banner_templates_larktab_bitable")
        public static let baseHomepageBannerTemplatesWorkbench = TemplateSource("base_hp_banner_templates_workbench")
        public static let baseHomepageBannerItemLarktab = TemplateSource("base_hp_banner_item_larktab_bitable")
        public static let baseHomepageBannerItemWorkbench = TemplateSource("base_hp_banner_item_workbench")
        public static let imNewGroupGuide = TemplateSource("im_new_group_guide") // IM新群指引
        public static let lark_survey = TemplateSource("lark_survey") // Lark New Form
        public static let baseHomepageLarkSurvey = TemplateSource("base_hp_create_form") // base首页入口 打开v5问卷
        
        public init(_ str: String) {
            self.rawValue = str
        }

        public init(rawValue: String) {
            self.init(rawValue)
        }

        public static func == (lhs: TemplateSource, rhs: TemplateSource) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(rawValue)
        }
        
        public init?(enterSource: String? = nil, source: EnterTemplateSource) {
            if enterSource == "chat_link" {
                self = .chatLink
                return
            } else if enterSource == "banner" {
                self = .spaceBanner
                return
            } else if enterSource == "onboarding_doc" {
                self = .onboardingDoc
                return
            } else if enterSource == "bitable_ws_landing_banner" {
                self = .bitableHomeBanner
                return
            } else if enterSource == "base_hp_banner_templates_larktab_bitable" {
                self = .baseHomepageBannerTemplatesLarktab
                return
            } else if enterSource == "base_hp_banner_templates_workbench" {
                self = .baseHomepageBannerTemplatesWorkbench
                return
            } else if enterSource == "base_hp_banner_item_larktab_bitable" {
                self = .baseHomepageBannerItemLarktab
                return
            } else if enterSource == "base_hp_banner_item_workbench" {
                self = .baseHomepageBannerItemWorkbench
                return
            } else if enterSource == "lark_survey" {
                self = .lark_survey
                return
            } else if enterSource == "base_hp_create_form" {
                self = .baseHomepageLarkSurvey
                return
            } else if enterSource == "space_home_create_form" {
                self = .spaceHomepageLarkSurvey
                return
            } else if enterSource == "wiki_home_create_form" {
                self = .wikiHomepageLarkSurvey
                return
            }

            if let templateSource = source.toTemplateSource() {
                self = templateSource
                return
            }
            return nil
        }
        
        public func shouldUseNewForm() -> Bool {
            if self == .lark_survey || self == .baseHomepageLarkSurvey || self == .spaceHomepageLarkSurvey || self == .wikiHomepageLarkSurvey {
                return true
            }else {
                return false
            }
        }
        
        public func i18nExtInfo() -> [String: String] {
            var extraInfo: [String: String] = ["time_zone": TimeZone.current.identifier]
            if self == .lark_survey {
                extraInfo["business_source"] = "lark_survey"
            } else if self == .baseHomepageLarkSurvey {
                extraInfo["business_source"] = "homepage_form"
            } else if self == .spaceHomepageLarkSurvey || self == .wikiHomepageLarkSurvey {
                extraInfo["business_source"] = "space_form"
            }
            return extraInfo
        }
    }

    // 模板中心内部渠道
    public enum TemplateCenterSource: String {
        case searchResult = "templatecenter_searchresult" // 从模板中心的搜索结果
        case banner = "templatecenter_banner" // 从模版中心的banner
    }

    /// banner展示时触发埋点,
    static func reportShowTemplateBannerTracker(bannerCount: Int, bannerType: Int, topicId: Int, templateId: Int, openlink: String?, bannerId: Int?) {

        // 后台说topicId 跟banner是一一对应的关系，所以把topicId上报成bannerID
        let finalId = getBannerTrackerId(bannerType: bannerType, topicId: topicId, templateId: templateId, bannerId: bannerId)
        var params: [String: Any] = ["banner_number": String(bannerCount),
                                     "banner_type": bannerType == 1 ? "single template" : "album",
                                     "banner_id": String(finalId)]
        if let jumpLink = openlink, !jumpLink.isEmpty {
            params["openlink"] = jumpLink
        }
        DocsTracker.log(enumEvent: .showTemplateinnerbanner, parameters: params)
    }

    /// 点击banner时埋点, bannerType: 1:单个模板；2: 专题模板
    static func reportClickTemplateBannerTracker(bannerCount: Int, bannerType: Int, topicId: Int, templateId: Int, openlink: String?, bannerId: Int?) {
        let finalId = getBannerTrackerId(bannerType: bannerType, topicId: topicId, templateId: templateId, bannerId: bannerId)
        var params: [String: Any] = ["banner_number": String(bannerCount),
                                     "banner_type": bannerType == 1 ? "single template" : "album",
                                     "banner_id": String(finalId)]
        if let jumpLink = openlink, !jumpLink.isEmpty {
            params["openlink"] = jumpLink
        }
        DocsTracker.log(enumEvent: .clickTemplateinnerbanner, parameters: params)
    }

    static private func getBannerTrackerId(bannerType: Int, topicId: Int, templateId: Int, bannerId: Int?) -> Int {
        guard let type = TemplateBanner.BannerType(rawValue: bannerType) else { return 0 }
        switch type {
        case .singleTemplate:
            return templateId
        case .topicTemplates:
            return topicId
        case .jumpLinkUrl:
            return bannerId ?? 0
        default:
            return 0
        }
    }

    /// 只有点击推荐词的手才进行埋点统计
    static func reportSearchTemplateTracker(action: SearchAction,
                                            recommendword: String? = nil,
                                            searchWords: String? = nil,
                                            hasSearchResult: Bool? = nil) {
        var params: [String: Any] = [:]
        switch action {
        case .clickSearchPlace, .displaySearchRecommendWords:
            params = ["action": action.rawValue]
        case .clickSearchRecommendWords:
            params = ["action": action.rawValue]
            if let name = recommendword {
                params["click_searchrecommendwords_name"] = name
            }
        case .inputSearchwords:
            params = ["action": action.rawValue]
            if let name = searchWords {
                params = ["searchwords_name": name]
            }
        case .searchResult:
            params = ["template_searchresult": (hasSearchResult ?? false) ? "yes" : "no"]
        case .clickSearchResultTemplate:
            params = ["action": action.rawValue]
        }

        DocsTracker.log(enumEvent: .templateSearch, parameters: params)
    }

    /// 展示某个模板的时候上报
    static func reportShowSingleTemplateTracker(_ template: TemplateModel, from: TemplateExposureType = .center) {
        var params: [String: Any] = [
            "file_type": template.docsType.name,
            "template_name": template.displayTitle,
            "template_token": template.objToken.encryptToken,
            "template_id": template.id,
            "exposure_type": from.rawValue
        ]
        if template.type == .collection {
            params["template_type"] = "set"
        }
        DocsTracker.log(enumEvent: .singletemplateExposure, parameters: params)
    }

    /// 进入模板中心的时候上报
    public static func reportEnterTemplateCenterTracker(source: EnterTemplateSource) {
        DocsTracker.log(enumEvent: .enterTemplateCenter, parameters: ["source": source.rawValue])
    }

    public static func formateStatisticsInfoForCreateEvent(source: EnterTemplateSource, categoryName: String?, categoryId: String?) -> [String: Any]? {
        var info: [String: Any]? = [:]
        if let name = categoryName {
            info?["template_category_name"] = name
        }
        if let categoryId = categoryId {
            info?["template_category_id"] = categoryId
        }
        info?["template_createfromsource"] = source.rawValue
        return info
    }

    static func clickTemplatePreview(from: ClickTemplatePreviewPosition) {
        let params: [String: Any] = [
            "source": "from_picture",
            "click_source": from.rawValue
        ]
        DocsTracker.log(enumEvent: .clickTemplatePreview, parameters: params)
    }

    static func createFromTemplateCenter() {
        let params: [String: Any] = [
            "templatecenter_source": "from_set",
            "singletemplate_source": "from_preview",
            "template_type": "set"
        ]
        DocsTracker.log(enumEvent: .createFromTemplateCenter, parameters: params)
    }
}

public extension TemplateCenterTracker {
    enum ManageTempalteAction: String {
        case save                           // 保存成功
        case delete                         // 删除成功
        case share                          // 分享成功
        case clickSaveAs = "click_save_as" //  确认保存点击
        case clickDelete = "click_delete"  // 确认删除
        case clickShare = "click_share"    // 确认分享
    }

    static func reportManagementTemplateByUser(action: ManageTempalteAction, templateMainType: TemplateMainType) {
        var params = ["action": action.rawValue]

        var type: String
        switch templateMainType {
        case .gallery:
            type = "PGC"
        case .custom:
            type = "ugc"
        case .business:
            type = "Enterprise"
        }
        params["template_type"] = type

        DocsTracker.log(enumEvent: .managementTemplateByUser, parameters: params)
    }
}

extension TemplateCenterTracker {
    public enum PageType: String {
        case banner = "ccm_template_banner_view"
        case systemCenter = "ccm_template_systemcenter_view"
        case userCenter = "ccm_template_usercenter_view"
        case businessCenter = "ccm_template_enterprisecenter_view"
        case searchResult = "ccm_template_search_result_view"
        case docsPage = "ccm_docs_page_view"
        case preview = "ccm_template_preview_view"
        case setPreview = "ccm_set_template_preview_view"
        case share = "ccm_template_share_view"
        case horizontalListView = "ccm_vc_template_bottom_view"

        func toEvent() -> DocsTracker.EventType? {
            switch self {
            case .systemCenter: return .ccmTemplateSystemcenterViewClick
            case .userCenter: return .ccmTemplateUsercenterViewClick
            case .businessCenter: return .ccmTemplateEnterprisecenterViewClick
            case .banner: return .ccmTemplateBannerViewClick
            case .searchResult: return .ccmTemplateSearchResultViewClick
            case .preview: return .ccmTemplatePreviewViewClick
            case .horizontalListView: return .ccmVCTemplateBottomClick
            case .docsPage, .setPreview, .share: return nil
            }
        }
    }

    // 搜索词来源
    enum KeywordsType: String {
        case recommend // 热词
        case search // 用户自己输入
    }

    // 筛选类型
    enum FilterType: String {
        case all
        case doc
        case sheet
        case mindnote
        case bitable
    }

    // 点击的位置，移动端只用到image
//    enum UseSource: String {
//        case image
//        case button
//    }

    // 模板点击类型
    enum TemplateClickType: String {
        case use = "use_click" // 使用模板创建文档
        case preview = "preview_click" // 模板预览
        case bottomTemplate = "click_vc_template" //底部模板点击预览

        var target: PageType {
            switch self {
            case .use: return .docsPage
            case .preview: return .preview
            case .bottomTemplate: return .horizontalListView
            }
        }
    }

    // 文档详情页模板banner点击类型
    public enum DocsBannerClickType: String {
        case use = "use_click"
        case create = "create_template_objs"
        case openTemplateCenter = "feish_docs"
    }

    /// 模版中心首页一级目录切换
    /// - Parameters:
    ///   - from: 旧目录
    ///   - to: 新目录
    static func reportMainTypeSwitch(from: TemplateMainType, to: TemplateMainType) {
        guard from != to else { return }
        let event = from.eventType()
        let clickType = to.clickType()
        let params = [
            "click_type": clickType,
            "target": to.pageType().rawValue
        ]
        DocsTracker.newLog(enumEvent: event, parameters: params)
    }

    /// 搜索结果页一级目录切换埋点
    /// - Parameter to: 新目录
    static func reportSearchResultViewMainTypeSwitch(to: TemplateMainType) {
        let clickType = to.clickType()
        let params: [String: String] = [
            "click_type": clickType,
            "target": to.pageType().rawValue
        ]
        DocsTracker.newLog(enumEvent: .ccmTemplateSearchResultViewClick, parameters: params)
    }

    /// banner曝光埋点
    /// - Parameter bannerId: banner_id
    static func reportBannerShow(bannerId: Int) {
        let params: [String: String] = [
            "click_type": "show_banner",
            "target": "ccm_template_center_view"
        ]
        DocsTracker.newLog(enumEvent: .ccmTemplateSystemcenterViewClick, parameters: params)
    }

    /// banner点击埋点
    /// - Parameter bannerId: banner_id
    static func reportBannerClick(bannerId: Int) {
        let params = [
            "click_type": "click_banner",
            "banner_id": "\(bannerId)",
            "target": PageType.banner.rawValue
        ]
        DocsTracker.newLog(enumEvent: .ccmTemplateSystemcenterViewClick, parameters: params)
    }

    /// 搜索埋点
    /// - Parameters:
    ///   - source: 从模版中心首页哪个一级目录点击搜索
    ///   - keyword: 搜索词
    ///   - type: 搜索词类型
    ///   - hasResult: 搜索后是否有数据
    ///   - templateSource: 进入模板库的渠道
    ///   - templateType: 搜索哪类模板
    static func reportSearchAction(keyword: String, type: KeywordsType, hasResult: Bool, templateSource: TemplateSource?, templateType: TemplateModel.Source) {
        var params = [
            "click_type": "search_input_result",
            "keywords": keyword,
            "keywords_type": type.rawValue,
            "result": "\(hasResult)",
            "target": PageType.searchResult.rawValue
        ]
        if let templateSource = templateSource {
            params["template_source"] = templateSource.rawValue
        }
        if let templateType = templateType.trackValue() {
            params["template_type"] = templateType
        }
        DocsTracker.newLog(enumEvent: .ccmTemplateSearchResultViewClick, parameters: params)
    }

    /// 搜索按钮点击埋点
    /// - Parameters:
    ///   - mainType: 从模版中心首页哪个一级目录点击搜索
    static func reportSearchButtonClick(mainType: TemplateMainType, templateSource: TemplateSource?) {
        let event = mainType.eventType()
        var params = [
            "click_type": "search_input_click",
            "target": mainType.pageType().rawValue
        ]
        if let templateSource = templateSource {
            params["template_source"] = templateSource.rawValue
        }
        DocsTracker.newLog(enumEvent: event, parameters: params)
    }

    static func reportClearKeywordAction() {
        let params = ["click_type": "clear_keywords", "target": "none"]
        DocsTracker.newLog(enumEvent: .ccmTemplateSearchResultViewClick, parameters: params)
    }

    /// 过滤埋点
    /// - Parameters:
    ///   - source: 从模版中心首页哪个一级目录点击过滤
    ///   - filterType: 过滤类型
    ///   - hasResult: 过滤后是否有数据
    static func reportFilterAction(source: TemplateMainType, filterType: FilterType, hasResult: Bool, templateSource: TemplateSource?) {
        let event = source.eventType()
        let target = source.pageType()
        _reportFilterAction(event: event, filterType: filterType, hasResult: hasResult, target: target, templateSource: templateSource)
    }

    /// 模版中心banner详情页过滤埋点
    /// - Parameters:
    ///   - filterType: 过滤类型
    ///   - hasResult: 过滤后是否有数据
    static func reportBannerFilterAction(filterType: FilterType, hasResult: Bool) {
        _reportFilterAction(event: .ccmTemplateBannerViewClick, filterType: filterType, hasResult: hasResult, target: .banner, templateSource: nil)
    }

    private static func _reportFilterAction(event: DocsTracker.EventType, filterType: FilterType, hasResult: Bool, target: PageType, templateSource: TemplateSource?) {
        var params = [
            "click_type": "filter",
            "file_type": filterType.rawValue,
            "filter_result": "\(hasResult)",
            "target": target.rawValue
        ]
        if let templateSource = templateSource {
            params["template_source"] = templateSource.rawValue
        }
        DocsTracker.newLog(enumEvent: event, parameters: params)
    }

    /// 二级目录点击埋点
    /// - Parameters:
    ///   - mainType: 当前一级目录
    ///   - filterName: 筛选类型名字, 无则传空字符串
    static func reportCategoryClick(mainType: TemplateMainType, category: TemplateCenterViewModel.Category, templateSource: TemplateSource?, filterName: String) {
        let event = mainType.eventType()
        var params = [
            "click_type": "sort_click",
            "sort_name": category.name, // 二级目录名
            "sort_id": "\(category.id)",
            "target": mainType.pageType().rawValue
        ]
        if !filterName.isEmpty {
            params["filter_status"] = filterName
        }
        if let templateSource = templateSource {
            params["template_source"] = templateSource.rawValue
        }
        DocsTracker.newLog(enumEvent: event, parameters: params)
    }

    /// 点击使用模版埋点
    /// - Parameters:
    ///   - template: 模版数据。
    ///   - from: 在哪个页面点击。当前首页三个tab、banner详情页、搜索结果页可点击使用模版、模板预览页
    ///   - category: 当前二级目录名。首页三个tab有二级目录，需要传；其它没有不用传
    ///   - clickType: 点击类型。使用模板、预览模板
    ///   - templateCenterSource: 从模板中心哪个内部渠道进入（只用于模板预览页）
    ///   - index: 模板所在位置索引
    ///   - filterName: 筛选类型, 无则传空字符串
    ///   - sectionName: 模板当所在子分类（组头）
    ///   - otherParams: 其它参数（优先级高）
    static func reportUseTemplate(
        template: TemplateModel,
        from: PageType,
        templateSource: TemplateSource?,
        category: String? = nil,
        clickType: TemplateClickType,
        templateCenterSource: TemplateCenterSource? = nil,
        index: Int,
        filterName: String,
        sectionName: String,
        otherParams: [String: Any]? = nil
    ) {
        guard let event = from.toEvent() else { return }

        let token = template.source == .system ? template.objToken : template.objToken.encryptToken
        let name = template.source == .system ? template.displayTitle : template.displayTitle.encryptToken
        var params: [String: Any] = [
            "click_type": clickType.rawValue,
            "template_token": token,
            "template_name": name,
            "use_source": "image",
            "target": clickType.target.rawValue,
            "position_index": "\(index + 1)"
        ]
        if !filterName.isEmpty {
            params["filter_status"] = filterName
        }
        if !sectionName.isEmpty {
            params["sub_template_sort"] = sectionName
        }
        if let templateType = template.source?.trackValue() {
            params["template_type"] = templateType
        }
        params["is_set"] = template.type == .collection
        if template.type == .collection, let collectionId = template.extra?.colletionId {
            params["set_id"] = collectionId
        }
        if let category = category {
            params["template_sort"] = category
        }
        if let docsTypeStr = String(docsType: template.docsType) {
            params["create_file_type"] = docsTypeStr
        }
        if let templateSource = templateSource {
            params["template_source"] = templateSource.rawValue
        }
        if templateSource == .baseHomepageLarkSurvey {
            params["click_type"] = "create_template_objs"
        }
        params["templatecenter_source"] = templateCenterSource?.rawValue ?? ""
        if template.source == .system {
            params[DocsTracker.Params.nonSensitiveToken] = true
        }
        if clickType == .preview {
            params["is_customized"] = "\(template.type == .ecology)"
            params["set_name"] = template.name
        }
        if let otherParams = otherParams {
            params.merge(other: otherParams)
        }
        DocsTracker.newLog(enumEvent: event, parameters: params)
    }

    /// 模版曝光埋点
    /// - Parameters:
    ///   - template: 模版数据
    ///   - from: 当前页面类型。当前首页三个tab、banner详情页、搜索结果页可曝光模版
    ///   - category: 当前二级目录名。首页三个tab有二级目录，需要传；其它没有不用传
    ///   - templateSource: 通过什么入口进入模板中心
    ///   - otherParams: 其它参数（优先级高）
    ///   - sectionName: 模版组头名字
    ///   - index: 模版位置
    static func reportTemplateDisplay(template: TemplateModel,
                                      from: PageType,
                                      category: String?,
                                      templateSource: TemplateCenterTracker.TemplateSource?,
                                      otherParams: [String: Any]? = nil,
                                      sectionName: String,
                                      index: Int) {
        guard template.source != .emptyData, template.source != .createBlankDocs, let event = from.toEvent() else { return }

        let token = template.source == .system ? template.objToken : template.objToken.encryptToken
        let name = template.source == .system ? template.displayTitle : template.displayTitle.encryptToken
        let is_set = template.type == .collection || template.type == .ecology
        var params: [String: Any] = [
            "click_type": "single_template_show",
            "template_token": token,
            "template_name": name,
            "is_set": is_set,
            "target": from.rawValue,
            "position_index": "\(index + 1)",
            "is_customized": "\(template.type == .ecology)", // 是否生态模版
            "set_name": template.name
        ]
        if !sectionName.isEmpty {
            params["sub_template_sort"] = sectionName
        }
        if is_set, let collectionId = template.extra?.colletionId {
            params["set_id"] = collectionId
        }
        if let templateType = template.source?.trackValue() {
            params["template_type"] = templateType
        }
        if let category = category {
            params["template_sort"] = category
        }
        if let templateSource = templateSource {
            params["template_source"] = templateSource.rawValue
        }
        if template.source == .system {
            params[DocsTracker.Params.nonSensitiveToken] = true
        }
        if let otherParams = otherParams {
            params.merge(other: otherParams)
        }
        DocsTracker.newLog(enumEvent: event, parameters: params)
    }

    /// 根据模版创建文档成功
    /// - Parameters:
    ///   - template: 模版数据
    ///   - docsToken：文档token
    ///   - from: 当前页面类型。当前首页三个tab、banner详情页、搜索结果页可曝光模版
    ///   - category: 当前二级目录名。首页三个tab有二级目录，需要传；其它没有不用传
    ///   - templateSource: 通过什么入口进入模板中心
    ///   - otherParams: 其它参数（优先级高）
    static func reportSuccessCreateDocs(
        template: TemplateModel, docsToken: String, from: PageType, category: String?,
        templateSource: TemplateCenterTracker.TemplateSource?, otherParams: [String: Any]? = nil) {
        guard let event = from.toEvent() else { return }

        let token = template.source == .system ? template.objToken : template.objToken.encryptToken
        let name = template.source == .system ? template.displayTitle : template.displayTitle.encryptToken
        let fileId = docsToken.encryptToken
        var params: [String: Any] = [
            "click_type": "create_template_objs",
            "template_token": token,
            "template_name": name,
            "use_source": "image",
            "file_id": fileId
        ]
        if let templateType = template.source?.trackValue() {
            params["template_type"] = templateType
        }
        if let templateSource = templateSource {
            params["template_source"] = templateSource.rawValue
        }
        if let createFileType = String(docsType: template.docsType) {
            params["create_file_type"] = createFileType
        }
        if let category = category {
            params["template_sort"] = category
        }
        if template.source == .system {
            params[DocsTracker.Params.nonSensitiveToken] = true
        }
        if let otherParams = otherParams {
            params.merge(other: otherParams)
        }
        DocsTracker.newLog(enumEvent: event, parameters: params)
    }

    /// 模板中心创建空白文档成功
    /// - Parameters:
    ///   - docsToken：文档token
    ///   - docsType: 文档类型
    ///   - templateSource: 通过什么入口进入模板中心
    static func reportSuccessCreateBlankDocs(docsToken: String, docsType: DocsType, templateSource: TemplateCenterTracker.TemplateSource?) {
        let event: DocsTracker.EventType = .ccmTemplateSystemcenterViewClick
        var params: [String: Any] = [
            "click_type": "create_blank_objs",
            "file_id": docsToken.encryptToken
        ]
        if let createFileType = String(docsType: docsType) {
            params["create_file_type"] = createFileType
        }
        if let templateSource = templateSource {
            params["template_source"] = templateSource.rawValue
        }
        DocsTracker.newLog(enumEvent: event, parameters: params)
    }

    /// 模版分享按钮点击埋点
    /// - Parameters:
    ///   - template: 模版数据
    ///   - from: 当前页面类型。首页“用户自定义tab”、搜索结果页“用户自定义tab”的用户自定义模版可分享
    ///   - templateSource: 进入模板中心渠道
    ///   - templateCenterSource: 模板中心内部渠道
    static func reportTemplateShare(
        template: TemplateModel, from: PageType, templateSource: TemplateCenterTracker.TemplateSource?,
        templateCenterSource: TemplateCenterTracker.TemplateCenterSource? = nil) {
        guard from == .userCenter || from == .searchResult || from == .preview else { return }
        guard let event = from.toEvent() else { return }
        let token = template.source == .system ? template.objToken : template.objToken.encryptToken
        let name = template.source == .system ? template.displayTitle : template.displayTitle.encryptToken
        var params: [String: Any] = [
            "click_type": "share_button",
            "template_token": token,
            "template_name": name,
            "target": "ccm_template_share_view",
            "is_customized": "\(template.type == .ecology)", // 生态模板
            "set_name": template.name
        ]
        if let collectionId = template.extra?.colletionId {
                params["set_id"] = collectionId
        }
        if let templateType = template.source?.trackValue() {
            params["template_type"] = templateType
        }
        if let templateSource = templateSource {
            params["template_source"] = templateSource.rawValue
        }
        if let templateCenterSource = templateCenterSource {
            params["templatecenter_source"] = templateCenterSource.rawValue
        }
        if template.source == .system {
            params[DocsTracker.Params.nonSensitiveToken] = true
        }
        DocsTracker.newLog(enumEvent: event, parameters: params)
    }

    /// 模版删除按钮点击埋点
    /// - Parameters:
    ///   - template: 模版数据
    ///   - from: 当前页面类型。首页“用户自定义tab”、搜索结果页“用户自定义tab”的用户自定义模版可删除
    static func reportTemplateDelete(template: TemplateModel, from: PageType) {
        guard from == .userCenter || from == .searchResult || from == .preview else { return }
        guard let event = from.toEvent() else { return }
        let token = template.source == .system ? template.objToken : template.objToken.encryptToken
        var params: [String: Any] = [
            "click_type": "delete_button",
            "template_token": token,
            "target": "ccm_template_usercenter_view"
        ]
        if template.source == .system {
            params[DocsTracker.Params.nonSensitiveToken] = true
        }
        DocsTracker.newLog(enumEvent: event, parameters: params)
    }

    /// 推荐模版接口成功率埋点
    /// - Parameters:
    ///   - success: 是否请求成功
    ///   - errorMsg: 失败时的错误信息
    static func reportSuggestedTemplateRequestResult(success: Bool, errorMsg: String = "") {
        let params: [String: String] = [
            "success": "\(success)",
            "error": errorMsg
        ]
        DocsTracker.newLog(enumEvent: .devRecommendTemplateDataRequest, parameters: params)
    }

    /// 普通模板预览切换按钮点击埋点
    /// - Parameters:
    ///   - template: 切换后的模板
    ///   - isNext: 是否为“下一个”按钮，true为“下一个”，false为“上一个”
    static func reportTemplatePreviewClickSwitch(to template: TemplateModel, isNext: Bool, templateSource: TemplateCenterTracker.TemplateSource? = nil) {
        let token = template.source == .system ? template.objToken : template.objToken.encryptToken
        let name = template.source == .system ? template.displayTitle : template.displayTitle.encryptToken
        var params: [String: Any] = [
            "click_type": isNext ? "next" : "last",
            "template_token": token,
            "template_name": name,
            "target": PageType.preview.rawValue
        ]
        if template.source == .system {
            params[DocsTracker.Params.nonSensitiveToken] = true
        }
        if let templateSource = templateSource {
            params["template_source"] = templateSource.rawValue
        }
        DocsTracker.newLog(enumEvent: .ccmTemplatePreviewViewClick, parameters: params)
    }

    /// 自定义模板预览more按钮点击埋点
    static func reportCustomTemplatePreviewClickMore() {
        let params: [String: Any] = [
            "click_type": "more"
        ]
        DocsTracker.newLog(enumEvent: .ccmTemplatePreviewViewClick, parameters: params)
    }
    
    static func reporBottomTemplateListClickMore(templateSource: TemplateCenterTracker.TemplateSource? = nil) {
        guard let event =  PageType.horizontalListView.toEvent() else { return }
        var params: [String: Any] = [
            "click_type": "click_template_systemcenter"
        ]
        if let templateSource = templateSource {
            params["template_source"] = templateSource.rawValue
        }
        DocsTracker.newLog(enumEvent: event, parameters: params)
    }
    
    /// 模板预览后退按钮点击埋点
    static func reportCustomTemplatePreviewClickBack(templateSource: TemplateCenterTracker.TemplateSource? = nil) {
        var params: [String: Any] = [
            "click_type": "back"
        ]
        if let templateSource = templateSource {
            params["template_source"] = templateSource.rawValue
        }
        DocsTracker.newLog(enumEvent: .ccmTemplatePreviewViewClick, parameters: params)
    }

    /// 套组模板预览埋点
    /// - Parameters:
    ///   - template: 预览的模板
    ///   - collectionId: 套组模板id
    ///   - templateSource: 模板渠道
    ///   - templateCenterSource: 模板中心内部渠道
    static func reportTemplateCollectionPreview(
        template: TemplateModel,
        collectionId: String,
        templateSource: TemplateCenterTracker.TemplateSource? = nil,
        templateCenterSource: TemplateCenterTracker.TemplateCenterSource? = nil,
        sectionName: String?
    ) {
        let token = template.source == .system ? template.objToken : template.objToken.encryptToken
        let name = template.source == .system ? template.displayTitle : template.displayTitle.encryptToken
        var params = [String: Any]()
        params["click"] = "single_template_preview"
        params["template_token"] = token
        params["template_name"] = name
        params["set_id"] = collectionId
        params["set_name"] = template.name
        if let name = sectionName, !name.isEmpty {
            params["sub_template_sort"] = name
        }
        params["is_customized"] = "\(template.type == .ecology)"
        if let templateSource = templateSource {
            params["template_source"] = templateSource.rawValue
        }
        if let templateCenterSource = templateCenterSource {
            params["templatecenter_source"] = templateCenterSource.rawValue
        }
        if template.source == .system {
            params[DocsTracker.Params.nonSensitiveToken] = true
        }
        DocsTracker.newLog(enumEvent: .ccmSetTemplatePreviewClick, parameters: params)
    }

    /// 套组模板预览页面点击左上角导航栏返回
    /// - Parameters:
    ///   - template: 预览的模板
    ///   - collectionId: 套组模板id
    ///   - templateSource: 模板渠道
    ///   - templateCenterSource: 模板中心内部渠道
    ///   - setName: 套组名称
    static func reportTemplateCollectionCancelBack(
        type: TemplateModel.TemplateType,
        collectionId: String,
        templateSource: TemplateCenterTracker.TemplateSource? = nil,
        templateCenterSource: TemplateCenterTracker.TemplateCenterSource? = nil,
        setName: String? = nil
    ) {
        var params = [String: Any]()
        params["click"] = "cancel"
        params["is_customized"] = "\(type == .ecology)"
        params["set_name"] = setName ?? ""
        params["set_id"] = collectionId
        if let templateSource = templateSource {
            params["template_source"] = templateSource.rawValue
        }
        if let templateCenterSource = templateCenterSource {
            params["templatecenter_source"] = templateCenterSource.rawValue
        }
        DocsTracker.newLog(enumEvent: .ccmSetTemplatePreviewClick, parameters: params)
    }

    /// 套组生态模板预览页面点击立即咨询
    /// - Parameters:
    ///   - template: 预览的模板
    ///   - collectionId: 套组模板id
    ///   - templateSource: 模板渠道
    ///   - templateCenterSource: 模板中心内部渠道
    ///   - setName: 套组名称
    static func reportTemplateCollectionConsultClick(
        type: TemplateModel.TemplateType,
        collectionId: String,
        templateSource: TemplateCenterTracker.TemplateSource? = nil,
        templateCenterSource: TemplateCenterTracker.TemplateCenterSource? = nil,
        setName: String? = nil
    ) {
        var params = [String: Any]()
        params["click"] = "consult_button"
        params["is_customized"] = "\(type == .ecology)"
        params["set_name"] = setName ?? ""
        params["set_id"] = collectionId
        if let templateSource = templateSource {
            params["template_source"] = templateSource.rawValue
        }
        if let templateCenterSource = templateCenterSource {
            params["templatecenter_source"] = templateCenterSource.rawValue
        }
        DocsTracker.newLog(enumEvent: .ccmSetTemplatePreviewClick, parameters: params)
    }

    /// 点击套组模板“获取并使用整套模板”按钮埋点
    /// - Parameters:
    ///   - templateCollection: 套组模板
    ///   - templateSource: 模板渠道
    ///   - templateCenterSource: 模板中心内部渠道
    static func reportTemplateCollectionUseButtonClick(
        collectionId: String,
        templates: [TemplateModel],
        templateSource: TemplateCenterTracker.TemplateSource? = nil,
        templateCenterSource: TemplateCenterTracker.TemplateCenterSource? = nil
    ) {
        for template in templates {
            let token = template.source == .system ? template.objToken : template.objToken.encryptToken
            let name = template.source == .system ? template.displayTitle : template.displayTitle.encryptToken
            var params = [String: Any]()
            params["click"] = "use_click_button"
            params["template_token"] = token
            params["template_name"] = name
            params["set_id"] = collectionId
            if let templateSource = templateSource {
                params["template_source"] = templateSource.rawValue
            }
            if let templateCenterSource = templateCenterSource {
                params["templatecenter_source"] = templateCenterSource.rawValue
            }
            if template.source == .system {
                params[DocsTracker.Params.nonSensitiveToken] = true
            }
            DocsTracker.newLog(enumEvent: .ccmSetTemplatePreviewClick, parameters: params)
        }
    }

    /// 套组模板保存成功后埋点
    /// - Parameters:
    ///   - collectionId: 套组id
    ///   - templateAndFileTokens: 套组内每一篇模板及其保存成功后创建的文档token（token已加密）
    ///   - folderToken: 保存到的文件夹的token（已加密）
    ///   - templateSource: 模板渠道
    ///   - templateCenterSource: 模板中心内部渠道
    static func reportTemplateCollectionUse(
        collectionId: String,
        templateAndFileTokens: [(TemplateModel, String)],
        folderToken: String,
        templateSource: TemplateCenterTracker.TemplateSource? = nil,
        templateCenterSource: TemplateCenterTracker.TemplateCenterSource? = nil
    ) {
        for (template, fileToken) in templateAndFileTokens {
            var params = [String: Any]()
            let token = template.source == .system ? template.objToken : template.objToken.encryptToken
            let name = template.source == .system ? template.displayTitle : template.displayTitle.encryptToken
            params["click"] = "use_click"
            params["template_token"] = token
            params["template_name"] = name
            params["set_id"] = collectionId
            params["file_id"] = fileToken
            params["folder_token"] = fileToken
            if let templateSource = templateSource {
                params["template_source"] = templateSource.rawValue
            }
            if let templateCenterSource = templateCenterSource {
                params["templatecenter_source"] = templateCenterSource.rawValue
            }
            if template.source == .system {
                params[DocsTracker.Params.nonSensitiveToken] = true
            }
            DocsTracker.newLog(enumEvent: .ccmSetTemplatePreviewClick, parameters: params)
        }
    }

    /// 模板文档banner显示埋点
    /// - Parameters:
    ///   - template: 对应的模板model
    ///   - docsInfo: 文档信息
    public static func reportDocsBannerShow(template: TemplateModel, docsInfo: DocsInfo) {
        var params: [String: Any] = [:]
        params["file_id"] = docsInfo.objToken.encryptToken
        params["file_type"] = docsInfo.type.rawValue
        params["template_token"] = template.source == .system ? template.objToken : template.objToken.encryptToken
        params["template_name"] = template.source == .system ? template.displayTitle : template.displayTitle.encryptToken
        params["template_type"] = template.source?.trackValue()
        if template.source == .system {
            params[DocsTracker.Params.nonSensitiveToken] = true
        }
        DocsTracker.newLog(event: DocsTracker.EventType.templateContentPageView.rawValue, parameters: params)
    }

    /// 文档详情页banner点击埋点
    /// - Parameters:
    ///   - template: 对应的模板model
    ///   - docsInfo: 文档信息
    ///   - clickType: 点击类型
    ///   - extParams: 额外参数
    public static func reportDocsBannerClick(template: TemplateModel, docsInfo: DocsInfo, clickType: DocsBannerClickType, extParams: [String: Any]? = nil) {
        var params: [String: Any] = [:]
        params["click"] = clickType.rawValue
        params["file_id"] = docsInfo.objToken.encryptToken
        params["file_type"] = docsInfo.type.rawValue
        params["template_token"] = template.source == .system ? template.objToken : template.objToken.encryptToken
        params["template_name"] = template.source == .system ? template.displayTitle : template.displayTitle.encryptToken
        params["template_type"] = template.source?.trackValue()
        if template.source == .system {
            params[DocsTracker.Params.nonSensitiveToken] = true
        }
        if let extParams = extParams {
            for (k, v) in extParams {
                params[k] = v
            }
        }
        DocsTracker.newLog(event: DocsTracker.EventType.templateContentPageClick.rawValue, parameters: params)
    }
}

/// 页面曝光
extension TemplateCenterTracker {

    /// 页面曝光
    /// - Parameter page: 页面
    static func reportPageViewEvent(page: PageType, templateSource: TemplateSource? = nil, templateCenterSource: TemplateCenterTracker.TemplateCenterSource? = nil, otherParams: [String: Any]? = nil) {
        var params: [String: Any] = [:]
        if let otherParams = otherParams {
            params = otherParams
        }
        if let templateSource = templateSource {
            params["template_source"] = templateSource.rawValue
        }
        if let templateCenterSource = templateCenterSource {
            params["templatecenter_source"] = templateCenterSource.rawValue
        }
        DocsTracker.newLog(event: page.rawValue, parameters: params)
    }

    /// 模版中心tab页曝光
    /// - Parameters:
    ///   - type: tab 类型
    ///   - enterSource: 目前用于链接跳转自定义模版
    static func reportTemplateCenterTabView(type: TemplateMainType, enterSource: String?, templateSource: TemplateSource?) {
        var page: PageType
        switch type {
        case .gallery: page = .systemCenter
        case .business: page = .businessCenter
        case .custom: page = .userCenter
        }
        var params: [String: String] = [:]
        if let enterSource = enterSource {
            params["enterSource"] = enterSource
        }
        if let templateSource = templateSource {
            params["template_source"] = templateSource.rawValue
        }
        DocsTracker.newLog(event: page.rawValue, parameters: params)
    }

    /// 系统模板页点击feedback上报
    ///   - templateSource: 模板渠道
    static func reportSystemcenterFeedback(templateSource: TemplateCenterTracker.TemplateSource?) {
        var params: [String: String] = ["click_type": "feedback"]
        if let templateSource = templateSource {
            params["template_source"] = templateSource.rawValue
        }
        DocsTracker.newLog(enumEvent: .ccmTemplateSystemcenterViewClick, parameters: params)
    }

    /// 搜索结果页点击feedback上报
    /// - Parameters:
    ///   - source: 从模版中心首页哪个一级目录点击搜索
    ///   - keyword: 搜索词
    ///   - type: 搜索词类型
    ///   - hasResult: 搜索后是否有数据
    ///   - templateSource: 进入模板库的渠道
    static func reportSearchResultFeedback(keyword: String, type: KeywordsType, hasResult: Bool, templateSource: TemplateSource?) {
        var params = [
            "click_type": "feedback",
            "keywords": keyword,
            "result": "\(hasResult)"
        ]
        if let templateSource = templateSource {
            params["template_source"] = templateSource.rawValue
        }
        DocsTracker.newLog(enumEvent: .ccmTemplateSearchResultViewClick, parameters: params)
    }
}

extension TemplateMainType {
    func eventType() -> DocsTracker.EventType {
        switch self {
        case .gallery:
            return .ccmTemplateSystemcenterViewClick
        case .custom:
            return .ccmTemplateUsercenterViewClick
        case .business:
            return .ccmTemplateEnterprisecenterViewClick
        }
    }
    func clickType() -> String {
        switch self {
        case .business: return "enterprise_template_click"
        case .custom: return "user_template_click"
        case .gallery: return "system_template_click"
        }
    }
    func pageType() -> TemplateCenterTracker.PageType {
        switch self {
        case .business: return .businessCenter
        case .custom: return .userCenter
        case .gallery: return .systemCenter
        }
    }
}
extension String {
    init?(docsType: DocsType) {
        switch docsType {
        case .doc: self = "doc"
        case .sheet: self = "sheet"
        case .mindnote: self = "mindnote"
        case .bitable: self = "bitable"
        case .docX: self = "docx"
        default:
            return nil
        }
    }
}
