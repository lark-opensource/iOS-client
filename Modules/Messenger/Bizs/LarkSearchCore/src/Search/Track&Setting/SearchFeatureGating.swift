//
//  SearchFeatureGating.swift
//  LarkSearchCore
//
//  Created by SolaWing on 2020/12/10.
//

import Foundation
import LarkFeatureGating
import LarkContainer
import LarkSetting
@frozen
public struct SearchFeatureGatingDisableKey: ExpressibleByStringLiteral {
    public let rawValue: String
    @inlinable
    public init(stringLiteral value: String) {
        rawValue = value
    }
    public func isUserEnabled(userResolver: UserResolver) -> Bool {
        return !userResolver.fg.staticFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: rawValue))
    }
}

public enum SearchFeatureGatingKey: String, CaseIterable {
    // 格式要求：全小写

    public static var mainLocal: SearchFeatureGatingDisableKey { "lark.search.api.main.local.disable" } // 是否关掉大搜本地搜索的FG

    case mainRecommend = "lark.search.main.recommend" // 大搜搜索推荐模块开关
    case inChatImageSearchV2 = "lark.search.chat.image.v2" // 是否开启会话内图片搜索能力（包括显示搜索框和接入V2）
    case inChatImageV2 = "lark.search.message.image.noquery.v2" //是否使用 v2 NoQuery 拉取默认图片

    case inChatCompleteFilter = "lark.search.chat_inside_complete_filter" // 是否使用会话内搜索筛选器
    case mainSearchRefactor = "asl.search.main.tab.reactor" // 大搜重构

    case docFilterSharer = "search.doc.share" // 文档tab下是否支持分享者过滤器

    case searchFeedback = "lark.search.feedback.ui.redesign" // 是否开启反馈界面交互优化
    case errorTips = "search.network.error_tips" // 搜索网络提示

    // filter related
    case bitableFilter = "search.doc.bitablefilter" // 是否在会话内展示多维表格过滤器
    case docMindNoteFilter = "search.filter.docs_mindnote" // 大搜，会话内文档tab是否展示思维笔记
    case docWikiFilter = "lark.search.doc.wiki.filter" // 大搜，会话内文档tab是否支持类型过滤器

    case mainFilter = "lark_search.quick_search_filter.show" // 大搜，综搜是否显示from与in筛选器
    case groupSortFilter = "lark_search.vertical_search_filter.groups_tab_sort_show" // 群组tab是否展示排序筛选器
    case groupSortUpdatedTime = "lark_search.vertical_search_filter.groups_tab_sort_update_time" //群组tab是否展示排序-最近更新筛选器
    case resultBasedFilterRecommend = "lark_search.filter.from_result_recommendation" // 是否在from筛选器开启基于结果的推荐
    case jumpTabMoreOpenSearch = "search.quick_jump.layout_optimize" // 是否开启综搜在更多分类搜索能力
    case isSupportShieldChat = "asl_search.shield_chat" //大搜垂搜下中是否展示密盾聊（综搜结果暂时只能被后端控制）
    case isEnableOrganizationTag = "arch.user.organizationnametag" // 是否将外部标签升级为企业名称标签
    case searchInChatPreviewPremission = "lark.asl.preview_permission_control" // 会话内搜索权限管控
    case searchDynamicTag = "asl.search.dynamic.tag" // 是否启用大搜标签后端动态下发
    /// 控制请求一年内的数据
    case searchOneYearData = "lark.search.message.only365d"
    /// 搜索云文档快捷键
    case searchShortcut = "asl.search.shortcut_search"
    /// 搜索子文件夹、会话内搜索文件替换实体
    case enableSearchSubFile = "messenger.search_sub_files"
    case searchHistoryOptimize = "lark.search.mobile_history_support_filter" // 搜索历史改版，关闭后不记录筛选器信息
    case searchDynamicResult = "search.dynamic.result" // 联系人cell是否启用DSL渲染
    public static var pickerCalendarDepartment: SearchFeatureGatingDisableKey { "lark.search.picker.calendar.department.disable" } // 是否禁用日历选人picker选择部门和默认群推荐

    /// 无query页面
    case noQueryFilterEnable = "lark_search.quick_search_filter.no_query_show"
    /// MyAI 总开关
    case myAiMainSwitch = "lark.my_ai.main_switch"
    case showDepartmentInfo = "core.forward.search_department"
    /// picker 多选后退出搜索
    case finishAfterMultiSelect = "core.picker.finish_after_multi_select"
    // 通用推荐
    case commonRecommendDisable = "lark.search.common.recommend.disable" // 是否禁用通用推荐
    case mainTabViewMoreAdjust = "lark.search.mobile.view_more" //是否开启综搜下进垂类入口调整
    case enableSupportSpotlight = "search.mobile_support_spotlight" //是否支持移动端soptlight搜索
    case enableCommonlyUsedFilter = "lark.search.filter.reco" //是否开启常用筛选器功能
    case enableSpotlightLocalTag = "lark.search.mobile.spotlight.local_tag" //spotlight搜索结果是否展示Local标签
    case enableExtraInfoUpdate = "lark.search.mobile.extro_info.update" //群组，云文档（doc+wiki）extra展示优化 （PM单词拼错了）
    case enableSupportURLIconInline = "lark.search.url_icon.support_more_types" // 是否支持消息中插入url icon
    case docNewSlides = "asl.search.doc_type_filter_slides" // 控制云文档新版slides
    // 关闭大搜SearchResultViewModel崩溃尝试修复
    case closeSearchResultViewModelCrashFix = "asl.search.close_searchresultviewmodel_crash_fix"
    case enableMessageAttachment = "search.message_filter.message_type.link_card" //大搜消息新增附件开关
    case docIconCustom = "lark_feature_doc_icon_custom"
    case oncallEnable = "oncall.enable"
    case oncallPreGA = "oncall.enable.pre_ga"
    case searchFile = "search.file"
    case messageWithFilter = "search.filter.messgae.with"
    case translateImageInOtherView = "translate.other.image.viewer.enable"
    case searchToastOff = "lark.search.toastoff"
    case enableIntensionCapsule = "search.redesign.capsule" //意图胶囊开关
    case enableFilterEludeBot = "search.filter_setting.exclude_bot" //意图胶囊记忆「不看机器人」筛选器开关
    case forwardLoacalDataOptimized = "lark.forward.first_screen_data_pull_speed_optimization" // 转发推荐列表数据加载优化
    case searchCalendarMigration = "search.calendar_platform.mobile" // 日程搜索迁移
    case enableSpotlightNativeApp = "lark.search.navigation_enable.app" // Rust 支持native app Spotlight搜索开关
    case searchEmailMigration = "search.email_platform.mobile" // 邮箱搜索迁移
    case searchLeanModeIsOnBugfix = "search.leanModeIsOn.bugfix" // 7.4精简模式大搜不可用bugfix开关，用于兜底
    case rustSDKSearchFeedbackV2 = "search.sdk.search_feedback_v2" // 搜索结果点击后给rust进行feedback
    case searchLoadingBugfixProtectFg = "search.mainSearchLoading.bugfix" // 大搜偶现loading异常bugfix兜底开关
    case enableSearchiPadRedesign = "lark.search.ipad.redesign" // iPad搜索改版开关
    case enableSearchiPadSpliteMode = "lark.search.ipad.splite.mode" // iPad搜索改版 -- 消息分栏开关
    case disableCapsuleSupportKeyboard = "lark.search.disable.capsule.support.keyboard" // 胶囊容器pad不支持业务特殊处理的键盘监听的上下键/回车逻辑
    case enableAdvancedSyntax = "search.syntax.mobile" // 大搜高级语法
    case disableInterceptRepeatedVC = "lark.search.disable.intercept.repeatedvc" // 大搜跳大搜，原地切换tab,不打开新的大搜
    public enum CommonRecommend: String, CaseIterable {
        case main = "lark.search.common.recommend.smart_search" // 综搜通用推荐开关
        case app = "lark.search.common.recommend.app" // 大搜app tab通用推荐开关

        public func isUserEnabled(userResolver: UserResolver) -> Bool {
            return userResolver.fg.staticFeatureGatingValue(with:
                                                                FeatureGatingManager.Key(stringLiteral: rawValue)
            ) && !SearchFeatureGatingKey.commonRecommendDisable.isUserEnabled(userResolver: userResolver)
        }
    }

    public var forceTrue: Bool {
        return true
    }

    public var forceFalse: Bool {
        return false
    }

    public func isUserEnabled(userResolver: UserResolver) -> Bool {
        return userResolver.fg.staticFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: rawValue))
    }
    // 先兼容旧FG,picker用户态容器改造后可删除
    @inlinable public var isEnabled: Bool {
        return Container.shared.getCurrentUserResolver().fg.staticFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: rawValue))
    }
}

public enum SearchDisableFGCollection: String, CaseIterable {
    case mainLocal = "lark.search.api.main.local.disable"
    case pickerCalendarDepartment = "lark.search.picker.calendar.department.disable"

    public func isUserEnabled(userResolver: UserResolver) -> Bool {
        switch self {
        case .mainLocal:
            return SearchFeatureGatingKey.mainLocal.isUserEnabled(userResolver: userResolver)
        case .pickerCalendarDepartment:
            return SearchFeatureGatingKey.pickerCalendarDepartment.isUserEnabled(userResolver: userResolver)
        }
    }
}

extension SearchFeatureGatingKey {
    var description: String {
        switch self {
        case .mainRecommend:
            return "大搜搜索推荐模块开关"
        case .inChatImageSearchV2:
            return "是否开启会话内图片搜索能力（包括显示搜索框和接入V2）"
        case .inChatCompleteFilter:
            return "是否开启会话内搜索来自更多筛选器"
        case .inChatImageV2:
            return "是否使用 v2 NoQuery 拉取默认图片"
        case .docFilterSharer:
            return "文档tab下是否支持分享者过滤器"
        case .searchFeedback:
            return "是否开启反馈界面交互优化"
        case .bitableFilter:
            return "是否在会话内展示多维表格过滤器"
        case .docMindNoteFilter:
            return "大搜，会话内文档tab是否展示思维笔记"
        case .docWikiFilter:
            return "大搜，会话内文档tab是否支持类型过滤器"
        case .mainFilter:
            return "大搜，综搜是否显示from与in筛选器"
        case .groupSortFilter:
            return "大搜群组tab是否展示排序筛选器"
        case .groupSortUpdatedTime:
            return "群组tab是否展示排序-最近更新筛选器"
        case .resultBasedFilterRecommend:
            return "是否在from筛选器开启基于结果的推荐"
        case .jumpTabMoreOpenSearch:
            return "是否开启综搜在更多分类搜索能力"
        case .commonRecommendDisable:
            return "是否禁用通用推荐"
        case .mainSearchRefactor:
            return "是否开启大搜重构"
        case .noQueryFilterEnable:
            return "no query page whether show filter or not"
        case .isSupportShieldChat:
            return "大搜垂搜下中是否展示密盾聊"
        case .isEnableOrganizationTag:
            return "是否将外部标签升级为企业名称标签"
        case .searchInChatPreviewPremission:
            return "会话内搜索文件与图片视频预览权限管控"
        case .searchOneYearData:
            return "区分冷热库搜索，默认搜索一年内数据"
        case .searchShortcut:
            return "enable search shortcut of document"
        case .errorTips:
            return "搜索网络提示"
        case .searchDynamicTag:
            return "是否启用大搜标签后端动态下发"
        case .searchHistoryOptimize:
            return "搜索历史改版，关闭后不记录筛选器信息"
        case .showDepartmentInfo:
            return "是否展示全部部门信息"
        case .searchDynamicResult:
            return "联系人cell是否启用DSL渲染"
        case .finishAfterMultiSelect:
            return "Picker exits the search after multiple selections"
        case .enableSearchSubFile:
            return "search sub file inChat and replace ItemType"
        case .myAiMainSwitch:
            return "Enable My AI"
        case .mainTabViewMoreAdjust:
            return "是否开启综搜下进垂类入口调整"
        case .enableSupportSpotlight:
            return "是否支持移动端soptlight搜索"
        case .enableCommonlyUsedFilter:
            return "是否开启常用筛选器功能"
        case .enableSpotlightLocalTag:
            return "是否在spotlight搜索结果上展示Local标签"
        case .enableExtraInfoUpdate:
            return "群组，云文档（doc+wiki）extra展示优化"
        case .enableSupportURLIconInline:
            return "是否支持消息中插入url icon"
        case .docNewSlides:
            return "控制云文档新版slides"
        case .closeSearchResultViewModelCrashFix:
            return "关闭大搜SearchResultViewModel崩溃尝试修复"
        case .enableMessageAttachment:
            return "大搜消息新增附件开关"
        case .docIconCustom:
            return "doc icon custom"
        case .oncallEnable:
            return "oncall enable"
        case .oncallPreGA:
            return "oncall pre ga"
        case .searchFile:
            return "search file enable"
        case .messageWithFilter:
            return "with filter in message Tab"
        case .translateImageInOtherView:
            return "enable translate image in ohter view(flag,collection)"
        case .searchToastOff:
            return "search toast off enable"
        case .enableIntensionCapsule:
            return "是否开启大搜意图胶囊"
        case .forwardLoacalDataOptimized:
            return "forward default chat view data load optimize"
        case .enableFilterEludeBot:
            return "是否开启意图胶囊记忆「不看机器人」筛选器"
        case .searchCalendarMigration:
            return "日程搜索迁移"
        case .searchEmailMigration:
            return "邮箱搜索迁移"
        case .searchLeanModeIsOnBugfix:
            return "iOS 7.4 leanModeIsOn bugfix fg"
        case .rustSDKSearchFeedbackV2:
            return "搜索结果点击后给rust进行feedback"
        case .searchLoadingBugfixProtectFg:
            return "大搜偶现loading异常bugfix兜底开关"
        case .enableSearchiPadRedesign:
            return "iPad搜索改版开关"
        case .enableSearchiPadSpliteMode:
            return "iPad搜索改版 -- 消息分栏开关"
        case .disableCapsuleSupportKeyboard:
            return "胶囊容器pad不支持业务特殊处理的键盘监听的上下键/回车逻辑"
        case .enableAdvancedSyntax:
            return "是否开启大搜高级语法"
        case .disableInterceptRepeatedVC:
            return "兜底，关闭在大搜跳转大搜出现两个rootVC"
        default:
            return "no description"
        }
    }
}

extension SearchFeatureGatingKey.CommonRecommend {
    var description: String {
        switch self {
        case .main:
            return "综搜通用推荐开关"
        case .app:
            return "大搜app tab通用推荐开关"
        }
    }
}

extension SearchDisableFGCollection {
    var description: String {
        switch self {
        case .mainLocal:
            return "是否关掉大搜本地搜索的FG"
        case .pickerCalendarDepartment:
            return "是否禁用日历选人picker选择部门和默认群推荐"
        }
    }
}
