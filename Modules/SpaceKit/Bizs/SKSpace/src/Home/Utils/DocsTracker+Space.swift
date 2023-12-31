//
//  DocsTracker+space.swift
//  SKECM
//
//  Created by guoqp on 2021/4/19.
//

import Foundation
import SKFoundation
import SKCommon
import SKInfra

typealias EventType = DocsTracker.EventType

extension SpaceListDisplayMode {
    var value: String {
        switch self {
        case .grid:
            return "grid"
        case .list:
            return "list"
        }
    }
}

extension DocsTracker {
    static func clickEventType(for module: PageModule, slideAction: SlideAction? = nil) -> EventType {
        switch module {
        case .home:
            return .spaceHomePageClick
        case .personal:
            return .spacePersonalPageClick
        case .shared:
            return .spaceSharedPageClick
        case .favorites:
            return .spaceFavoritesPageClick
        case .offline:
            return .spaceOfflinePageClick
        case .personalFolderRoot, .sharedFolderRoot, .personalSubFolder, .sharedSubFolder:
            return .spaceFolderClick
        case .newDrive:
            return .spaceDrivePageClick
        case .baseHomePage:
            if slideAction != nil {
                if slideAction == .more {
                    return .bitableHomePageClick
                }
                return .bitableHomeMoreMenuViewClick
            } else {
                return .bitableHomePageClick
            }
        default:
            return .spaceHomePageClick
        }
    }
}

///在space page页的点击动作
public enum SpacePageClickParameter {
    case search
    //金刚位点击
    case myLibrary
    case personal
    case shared
    case wiki
    case discover
    case favorites
    case offline
    case templates
    case todo
    case unsorted //未整理
    case drive    //云盘
    //首页切换
    case recent
    case quickAccess
    case catalogue
    //mode 切换
    case viewSwitch(subView: HomePageSubModule?) //首页时 subView有值
    //筛选
    case filter

    //cell侧滑操作
    case listItem(isFolder: Bool, isShareFolder: Bool, isSubFolder: Bool, folderLevel: Int, pageModule: PageModule?, pageSubModule: HomePageSubModule?)
    case share
    case delete
    case more(subView: HomePageSubModule?, pageModule: PageModule?) //首页时 subView有值
    case addQuickAccess
    case removeQuickAccess
    case addFavorites
    case removeFavorites
    //悬浮按钮创建
    case create
    //1.0我的空间，共享空间点击全部
    case all

    ///一级参数
    var clickValue: String {
        switch self {
        case .search: return "search"
        case .myLibrary: return "my_docs"
        case .personal: return "personal"
        case .shared: return "shared"
        case .wiki: return "wiki"
        case .discover: return "discover"
        case .favorites: return "favorites"
        case .offline: return "offline"
        case .templates: return "templates"
        case .todo: return "todo"
        case .recent: return "recent"
        case .quickAccess: return "quick_access"
        case .catalogue: return "catalogue"
        case .viewSwitch: return "view_switch"
        case .listItem: return "list_item"
        case .filter: return "filter"
        case .share: return "share"
        case .more: return "more"
        case .delete: return "delete"
        case .addQuickAccess: return "add_to_quickaccess"
        case .removeQuickAccess: return "remove_from_quickaccess"
        case .addFavorites: return "add_to_favorites"
        case .removeFavorites: return "remove_from_favorites"
        case .create: return "create"
        case .all: return "all"
        case .unsorted: return "unsorted"
        case .drive: return "drive"
        }
    }

    ///二级参数
    var targetValue: String {
        switch self {
        case .search: return "search_main_view"
        case .myLibrary: return "ccm_docs_page_view"
        case .personal: return EventType.spacePersonalPageView.rawValue
        case .shared: return EventType.spaceSharedPageView.rawValue
        case .wiki: return "ccm_space_wiki_page_view"
        case .discover: return "ccm_wiki_discover_view"
        case .favorites: return EventType.spaceFavoritesPageView.rawValue
        case .offline: return EventType.spaceOfflinePageView.rawValue
        case .templates: return "ccm_template_systemcenter_view"
        case .todo: return "ccm_doc_todo_center_page_view"
        case .recent, .quickAccess, .catalogue: return EventType.spaceHomePageView.rawValue
        case .filter: return EventType.spaceHeaderFilterView.rawValue
        case .share: return "ccm_permission_share_view"
        case let .more(_, pageModule):
            if case .baseHomePage = pageModule {
                return "ccm_bitable_workspace_landing_more_menu_view"
            }
            return EventType.spaceRightClickMenuView.rawValue
        case .create: return EventType.spaceCreateNewView.rawValue
        case .delete: return "ccm_space_delete_view"
        case .viewSwitch, .addFavorites, .addQuickAccess, .removeFavorites, .removeQuickAccess: return "none"
        case .listItem: return "none" //特殊情况
        case .all: return "ccm_space_file_view"
        case .unsorted: return "ccm_space_unsorted_page_view"
        case .drive: return "ccm_space_drive_page_view"
        }
    }

    static func typeFor(entrance identifier: String) -> Self {
        if identifier == "personal" { return .personal }
        if identifier == "sharetome" { return .shared }
        if identifier == "wiki_home" { return .wiki }
        if identifier == "favorite" { return .favorites }
        if identifier == "offline" { return .offline }
        if identifier == "template" { return .templates }
        if identifier == "todo" { return .todo }
        if identifier == "my-library" { return .myLibrary }
        return .personal
    }

    static func typeFor(subTab tabID: String) -> Self? {
        switch tabID {
        case "pin":
            return .quickAccess
        case "recent":
            return .recent
        case "homeAssembleTree":
            return .catalogue
        case "personal":
            return .personal
        case "share-folder":
            return .shared
        default:
            return nil
        }
    }
}

extension DocsTracker {
    static func reportSpaceHomePageView(module: PageModule, subModule: HomePageSubModule) {
        if case let .baseHomePage(context) = module {
            var dic: [String: Any] = [
                "current_sub_view": subModule.rawValue,
            ]
            DocsTracker.reportBitableHomePageEvent(enumEvent: .baseHomepageFilelistView, parameters: dic, context: context)
        } else {
            var dic: [String: Any] = ["current_sub_view": subModule.rawValue]
            dic.merge(other: SpaceBizParameter(module: .home(subModule)).params)
            DocsTracker.log(enumEvent: .spaceHomePageView, parameters: dic)
        }
    }
    ///在space首页的点击动作
    public static func reportSpaceHomePageClick(params: SpacePageClickParameter, bizParms: SpaceBizParameter) {
        reportSpacePagePageClick(enumEvent: .spaceHomePageClick, params: params, bizParms: bizParms)
    }

    public static func reportNewDrivePageClick(params: SpacePageClickParameter, bizParms: SpaceBizParameter) {
        reportSpacePagePageClick(enumEvent: .spaceDrivePageClick, params: params, bizParms: bizParms)
    }

    static func reportSpacePagePageClick(enumEvent: EventType, params: SpacePageClickParameter, bizParms: SpaceBizParameter, otherParams: [String: Any]? = nil, userNewLog: Bool = false) {
        var dic: [String: Any] = ["click": params.clickValue]
        dic.merge(other: bizParms.params)
        if let otherParams = otherParams {
            dic.merge(other: otherParams)
        }
        switch params {
        case .search, .myLibrary, .personal, .shared, .wiki, .discover, .favorites, .offline, .templates, .todo, .create, .addFavorites, .addQuickAccess, .removeFavorites, .removeQuickAccess, .all:
            dic.merge(other: ["target": params.targetValue])
        case .unsorted, .drive:
            dic.merge(other: ["target": params.targetValue, "space_version": "new_format"])
        case .recent, .quickAccess, .catalogue, .filter, .share, .delete:
            let mode: SpaceListDisplayMode = LayoutManager.shared.isGrid ? .grid : .list
            dic.merge(other: ["target": params.targetValue,
                              "view_type": mode.value])
        case let .viewSwitch(subView: subView):
            let oldMode: SpaceListDisplayMode = LayoutManager.shared.isGrid ? .list : .grid
            let newMode: SpaceListDisplayMode = LayoutManager.shared.isGrid ? .grid : .list
            dic.merge(other: ["target": params.targetValue,
                              "view_type": oldMode.value,
                              "switch_to": newMode.value])
            if let view = subView {
                dic.merge(other: ["current_sub_view": view.rawValue])
            }
        case let .more(subView: subView, _):
            let mode: SpaceListDisplayMode = LayoutManager.shared.isGrid ? .grid : .list
            dic.merge(other: ["target": params.targetValue,
                              "view_type": mode.value])
            if let view = subView {
                dic.merge(other: ["current_sub_view": view.rawValue])
            }
        case let .listItem(isFolder: isFolder, isShareFolder: isShareFolder, isSubFolder: isSubFolder, folderLevel: folderLevel, pageModule: pageModule, pageSubModule: pageSubModule):
            let mode: SpaceListDisplayMode = LayoutManager.shared.isGrid ? .grid : .list
            var target = isFolder ? "ccm_space_folder_view" : "ccm_docs_page_view"
            if case .baseHomePage = pageModule {
                target = "ccm_bitable_content_page_view"
            }
            dic.merge(other: ["target": target,
                              "is_folder": String(isFolder),
                              "is_shared_folder": String(isShareFolder),
                              "is_subfolder": String(isSubFolder),
                              "folder_lever": folderLevel,
                              "view_type": mode.value])
            if let pageSubModule = pageSubModule {
                dic.merge(other: ["sub_view": pageSubModule.rawValue])
            }
        }
        if userNewLog {
            DocsTracker.newLog(enumEvent: enumEvent, parameters: dic)
        } else {
            DocsTracker.log(enumEvent: enumEvent, parameters: dic)
        }
    }
}

extension DocsTracker {
    static func reportSpacePersonalPageView() {
        let bizParams = SpaceBizParameter(module: .personal(.belongtome)).params
        DocsTracker.log(enumEvent: .spacePersonalPageView, parameters: bizParams)
    }
    /// 在个人空间主页的点击事件
    static func reportSpacePersonalPageClick(params: SpacePageClickParameter) {
        let bizParams = SpaceBizParameter(module: .personal(.belongtome))
        reportSpacePagePageClick(enumEvent: .spacePersonalPageClick, params: params, bizParms: bizParams)
    }
}

extension DocsTracker {
    static func reportSpaceSharedPageView() {
        let bizParams = SpaceBizParameter(module: .shared(.sharetome)).params
        DocsTracker.log(enumEvent: .spaceSharedPageView, parameters: bizParams)
    }
    /// 在共享空间主页的点击事件
    static func reportSpaceSharedPageClick(params: SpacePageClickParameter) {
        let bizParams = SpaceBizParameter(module: .shared(.sharetome))
        reportSpacePagePageClick(enumEvent: .spaceSharedPageClick, params: params, bizParms: bizParams)
    }

    /// 在共享空间上半部分文件夹的点击事件
    static func reportSpaceShareFolderPageClick(params: SpacePageClickParameter) {
        let bizParams = SpaceBizParameter(module: .shared(.sharedFolder))
        reportSpacePagePageClick(enumEvent: .spaceSharedPageClick, params: params, bizParms: bizParams)
    }
}

extension DocsTracker {
    static func reportSpaceFavoritesPageView() {
        let bizParams = SpaceBizParameter(module: .favorites).params
        DocsTracker.log(enumEvent: .spaceFavoritesPageView, parameters: bizParams)
    }
    /// 在收藏主页的点击事件
    static func reportSpaceFavoritesPageClick(params: SpacePageClickParameter) {
        let bizParams = SpaceBizParameter(module: .favorites)
        reportSpacePagePageClick(enumEvent: .spaceFavoritesPageClick, params: params, bizParms: bizParams)
    }
}

extension DocsTracker {
    static func reportSpaceOfflinePageView() {
        let bizParams = SpaceBizParameter(module: .offline).params
        DocsTracker.log(enumEvent: .spaceOfflinePageView, parameters: bizParams)
    }
    ///在离线文档主页的点击事件
    static func reportSpaceOfflinePageClick(params: SpacePageClickParameter) {
        let bizParams = SpaceBizParameter(module: .offline)
        reportSpacePagePageClick(enumEvent: .spaceOfflinePageClick, params: params, bizParms: bizParams)
    }
}

extension DocsTracker {
    static func reportSpacePageSearchClick(module: PageModule) {
        switch module {
        case .personal:
            DocsTracker.reportSpacePersonalPageClick(params: .search)
        case .shared:
            DocsTracker.reportSpaceSharedPageClick(params: .search)
        case .favorites:
            DocsTracker.reportSpaceFavoritesPageClick(params: .search)
        case .offline:
            DocsTracker.reportSpaceOfflinePageClick(params: .search)
        case let .baseHomePage(context):
            DocsTracker.reportBitableHomePageViewClick(context: context, params: .search)
        default:
            break
        }
    }

    static func reprotFolderPageSearchClick(module: PageModule, isShare: Bool) {
        switch module {
        case .personal:
            DocsTracker.reportSpacePersonalPageClick(params: .search)
        case .shared:
            DocsTracker.reportSpaceSharedPageClick(params: .search)
        default:
            let bizParms = SpaceBizParameter(module: module)
            DocsTracker.reportSpaceFolderClick(params: .search(isBlank: false, isShareFolder: isShare), bizParms: bizParms)
        }
    }
}

enum HeaderFilterClickParameter {
    case confirm(sortItem: SortItem, filterItem: FilterItem, target: EventType)
    case reset(target: EventType)

    ///一级参数
    var clickValue: String {
        switch self {
        case .confirm: return "confirm"
        case .reset: return "reset"
        }
    }
}

extension DocsTracker {
    ///筛选框view
    static func reportSpaceHeaderFilterView(bizParms: SpaceBizParameter) {
        let bizParams = bizParms.params
        DocsTracker.log(enumEvent: .spaceHeaderFilterView, parameters: bizParams)
    }

    ///在筛选框上的点击动作
    static func reportSpaceHeaderFilterClick(params: HeaderFilterClickParameter, bizParms: SpaceBizParameter) {
        var dic: [String: Any] = ["click": params.clickValue]
        dic.merge(other: bizParms.params)
        switch params {
        case let .confirm(sortItem, filterItem, target):
            dic["target"] = target.rawValue
            dic["doc_value"] = filterItem.filterType.reportNameV2
            dic["operate_value"] = sortItem.reportNameV2
        case let .reset(target):
            dic["target"] = target.rawValue
        }
        DocsTracker.log(enumEvent: .spaceHeaderFilterClick, parameters: dic)
    }

    static func reportSpaceHeaderFilterClick(by filterItem: FilterItem?, by sortItem: SortItem?, lastActionName: String, eventType: EventType, bizParms: SpaceBizParameter) {
        guard let filterItem = filterItem, let sortItem = sortItem else {
            DocsLogger.info("item is nil")
            return
        }
        if lastActionName == "done" {
            reportSpaceHeaderFilterClick(params: .confirm(sortItem: sortItem, filterItem: filterItem, target: eventType), bizParms: bizParms)
        }
        if lastActionName == "reset" {
            reportSpaceHeaderFilterClick(params: .reset(target: eventType), bizParms: bizParms)
        }
    }
}

///文件夹view里的点击
enum SpaceFolderClickParameter {
    case viewSwitch(isShareFolder: Bool)
    case create(isBlank: Bool, location: CreateButtonLocation, isShareFolder: Bool)
    case search(isBlank: Bool, isShareFolder: Bool)
    case more(isBlank: Bool, isShareFolder: Bool)
    case filter(isBlank: Bool, isShareFolder: Bool)
    ///一级参数
    var clickValue: String {
        switch self {
        case .viewSwitch: return "view_switch"
        case .create: return "create"
        case .search: return "search"
        case .more: return "more"
        case .filter: return "filter"
        }
    }
    ///二级参数
    var targetValue: String {
        switch self {
        case .create:
            return "ccm_space_create_new_view"
        case .more:
            return "ccm_space_right_click_menu_view"
        case .filter:
            return "ccm_space_header_filter_order_view"
        case .search:
            return "search_main_view"
        default:
            return "none"
        }
    }
}

extension DocsTracker {
    ///文件夹view
    static func reportSpaceFolderView(isShareFolder: Bool, bizParms: SpaceBizParameter) {
        let displayMode: SpaceListDisplayMode = LayoutManager.shared.isGrid ? .grid : .list
        var dic = [
            "is_shared_folder": String(isShareFolder),
            "view_type": displayMode.value,
            "is_block": "false",
            "user_brand": DomainConfig.envInfo.isFeishuBrand ? "feishu" : "lark"
        ]
        dic.merge(other: bizParms.params)
        DocsTracker.log(enumEvent: .spaceFolderView, parameters: dic)
    }

    ///文件夹view里的点击
    static func reportSpaceFolderClick(params: SpaceFolderClickParameter, bizParms: SpaceBizParameter) {
        var dic: [String: Any] = ["click": params.clickValue, "target": params.targetValue.isEmpty ? "none" : params.targetValue]
        dic.merge(other: bizParms.params)
        switch params {
        case let .viewSwitch(isShareFolder):
            dic["is_shared_folder"] = String(isShareFolder)
        case let .search(isBlank, isShareFolder), let .more(isBlank, isShareFolder), let .filter(isBlank, isShareFolder):
            dic["is_shared_folder"] = String(isShareFolder)
            dic["is_blank"] = String(isBlank)
        case let .create(isBlank, location, isShareFolder):
            dic["is_shared_folder"] = String(isShareFolder)
            dic["is_blank"] = String(isBlank)
            dic["location"] = (location == .blankPage) ? "middle" : "suspend_create"
        }
        DocsTracker.log(enumEvent: .spaceFolderClick, parameters: dic)
    }
}

// 文档详情页顶部栏view的点击
//enum DocTopBarClickParameter {
//    case share
//    case more
//    case comment
//    case back
//    case catalog
//    case fullScreen
//    case mormalScreen
//    case close
//    case openInNewWindow
//    ///一级参数
//    var clickValue: String {
//        switch self {
//        case .share: return "share"
//        case .more: return "…"
//        case .comment: return "comment"
//        case .back: return "back"
//        case .fullScreen: return "full_screen"
//        case .mormalScreen: return "normal_screen"
//        case .close: return "close"
//        case .openInNewWindow: return "open_in_new_window"
//        case .catalog: return "catalog"
//        }
//    }
//    ///二级参数
//    var targetValue: String {
//        switch self {
//        case .share:
//            return "ccm_permission_share_view"
//        case .more:
//            return "ccm_space_docs_more_menu_view"
//        case .comment:
//            return "ccm_comment_view"
//        case .openInNewWindow:
//            return "ccm_docs_page_view"
//        default:
//            return "none"
//        }
//    }
//}

extension DocsTracker {
    ///文件重命名view
    static func reportSpaceDriveRenameView(bizParms: SpaceBizParameter) {
        DocsTracker.log(enumEvent: .spaceDriveRenameView, parameters: bizParms.params)
    }
}

extension DocsTracker {
    static func reportBitableHomePageEvent(enumEvent: EventType, parameters: [String: Any]?, bizParams: SpaceBizParameter) {
        var dic: [String: Any] = bizParams.params
        dic.merge(other: parameters)
        DocsTracker.newLog(enumEvent: enumEvent, parameters: dic)
    }
    
    static func reportBitableHomePageEvent(enumEvent: EventType, parameters: [String: Any]?, context: BaseHomeContext) {
        let bizParams = SpaceBizParameter(module: .baseHomePage(context: context))
        reportBitableHomePageEvent(enumEvent: enumEvent, parameters: parameters, bizParams: bizParams)
    }
    
    ///bitable Home页面展示
    static func reportBitableHomePageView(context: BaseHomeContext) {
        reportBitableHomePageEvent(enumEvent: .bitableHomePage, parameters: nil, context: context)
        reportBitableHomePageEvent(enumEvent: .baseHomepageLandingView, parameters: nil, context: context)
    }

    /// bitable Home页的点击事件
    static func reportBitableHomePageViewClick(context: BaseHomeContext, params: SpacePageClickParameter) {
        let bizParams = SpaceBizParameter(module: .baseHomePage(context: context))
        reportSpacePagePageClick(enumEvent: .baseHomepageLandingClick, params: params, bizParms: bizParams, userNewLog: true)
    }
}
