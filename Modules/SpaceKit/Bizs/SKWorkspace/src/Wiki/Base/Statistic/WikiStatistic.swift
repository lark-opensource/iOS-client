//
//  WikiStatistic.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/10/9.
//
// swiftlint:disable type_body_length file_length

import Foundation
import SKCommon
import SKFoundation
import SpaceInterface

// Wiki移动端埋点: https://bytedance.feishu.cn/space/doc/doccn3njbgbmFwDpIaKexnLFU5g#
public final class WikiStatistic {
    public enum ReportKey: String {
        case action
        case fileId = "file_id"
        case targetFileId = "target_file_id"
        case fileType = "file_type"
        case module
        case subModule = "sub_module"
        case group
        case editPermission = "file_is_have_edit"
        case nodeLevel = "expand_node_level"
        case count
        case indexId = "index_id"
        case source
        case sequenceNum = "sequence_num"
        case searchId = "search_id"
        case type
        case networkStatus = "network_status"
        case status
        case refType = "reference_type"
        case parentId = "parent_id"
        case parentType = "parent_type"
        case triggerLocation = "trigger_location"
        case targetModule = "target_module"
        case targetFolderType = "target_folder_type"
        //wiki click事件
        case click
        case target
        case isFavorites = "is_favorites"
        case childrenPageToken = "children_page_token"
        case childrenFileId = "children_file_id"
        case childrenFileType = "children_file_type"
        case areaId = "area_id"
        case targetSpaceId = "target_space_id"
        case pagesNum = "pages_num"
        case isSuccess = "is_success"
        case uploadStatus = "upload_status"
        case isComment = "is_comment"
        case includeChildrenPage = "is_include_children_page"

        /// 若点击查看公告时有小红点更新提醒，则上报 is_updated_notice=true
        case isUpdatedNotice = "is_updated_notice"
        case createCatalogLocation = "create_catalog_location"

        //wiki view事件
        case isLoadingSuccess = "is_loading_success"
        case isCreateFile = "is_create_file"
        case isMoveTo = "is_move_to"
        case isShortcutTo = "is_shortcut_to"
        case isEmpty = "is_empty"
        case viewTitle = "view_title"
        case categoryShow = "is_category_show"
        //wiki 公参
        case filePermission = "file_permission"
        case userPermission = "user_permission"
        case containerId = "container_id"
        case containerType = "container_type"
        case originFileId = "origin_file_id"
        case pageToken = "page_token"
        case isShortcut = "is_shortcut"
        case shortcutId = "shortcut_id"
        case appForm = "app_form"
        case viewStatus = "view_status"
        case isRepeat = "is_repeat"
        case isUserActive = "is_user_active"
        case originalContainer = "original_docs_container"
        case categoryId = "category_id"
        case deleteScope = "delete_scope"
        case isMyLibrary = "is_self_wiki"
    }

    private enum EnterWikiSource: String {
        case homeLink = "home_link"
        case fileLink = "file_link"
        case appCenter = "app_center"
        case larkSearch = "lark_search"
        case pages
        case larkMessage = "lark_message"
        case moveToWiki = "move_to_wiki"
        case others
        case recents = "recents"    // 列表页

        init(from: String?) {
            guard let from = from else {
                self = .recents
                return
            }
            // 部分 source 需要替换为打点需要的几种类型
            switch from {
            case "appcenter", "app_center":
                self = .appCenter
            case "tab_link", "file_link", "from_parent_docs":
                self = .fileLink
            case "pages":
                self = .pages
            case "message", "pin", "group_tab_record_docs", "group_tab_notice":
                self = .larkMessage
            case "lark_search", "search":
                self = .larkSearch
            case "move_to_wiki":
                self = .moveToWiki
            case "recents":
                self = .recents
            default:
                self = .fileLink
            }
        }
    }

    public enum ClientOpenSource: String {
        case message = "message"
        case pages = "pages"
        case doc = "tab_link"
        case appCenter = "app_center"
        case recents = "recents"
        case myLibrary = "my_docs"
        case unknown = ""
        var stasticsValue: String {
            switch self {
            case .message:
                return "message"
            case .pages:
                return "pages"
            case .doc:
                return "doc"
            case .recents:
                return "recents"
            case .appCenter:
                return "app_center"
            case .myLibrary:
                return "my_docs"
            case .unknown:
                return "unknown"
            }
        }
    }

    public enum ActionType: String {
        case expandPages = "expand_pages"
        case closePages = "close_pages"
        case switchPage = "switch_page"
        case fullExpandPages = "full_expand_pages"
        case nodeExpandChange = "node_expand_change"
        case selectSpace = "select_space"
        case selectPage = "select_page"
        case seeAll = "see_all"
        case createFromTree = "create_new_from_pages"
        case createFromHome = "confirm_create_new"
        case clickDelete = "click_delete_in_more"
        case confirmDelete = "confirm_delete"
        case clickMove = "click_move"
        case confirmMove = "click_confirm_move"
        case swipePage = "swipe_page"
        case search
        case create = "add_page"
        case shortcutTo = "shortcut_to"
        case comfirmShortcut = "comfirm_shortcut_to"
        case cancelShortcut = "cancel_shortcut_to"
        case star = "file_star"
        case unstar = "file_unstar"
        case copy = "click_make_a_copy"
        case confirmCopy = "confirm_make_a_copy"
        case cancelCopy = "cancel_make_a_copy"
    }


    // 点击事件的一二级参数取值
    public enum ClickType: String, Equatable {
        case viewAllWorkSpace = "view_all_workspace"
        case workspace
        case recentlyView = "recently_view"
        case create
        case doc
        case sheet
        case mindnote
        case confirm
        case add
        case more
        case expand
        case collapse
        case page
        case workspaceDetail = "workspace_detail"
        case starWorkspace = "star_workspace"
        case unstarWorkspace = "unstar_workspace"
        case cancel
        case moveTo = "move_to"
        case shortcutTo = "shortcut_to"
        case delete
        case restore
        case deleteCompletely = "delete_completely"
        case finish = "finish"
        case viewAnnouncement = "view_notice"
        // 在目录选择器内新建文件夹
        case createCatalog = "create_catalog"
        case rename

        case clipWiki = "clip_wiki"
        case unclipWiki = "unclip_wiki"
        case starWiki = "star_wiki"
        case unstarWiki = "unstar_wiki"
        case addPin = "add_to_quickaccess"
        case removePin = "remove_from_qucikaccess"
        case addOffline = "add_to_offline"
        case removeOffline = "remove_from_offline"
        // 移动到 space
        case remove
        // 发送申请
        case send
        case copyTo = "make_a_copy_to"
        // 点击查看
        case docsView = "docs_view"
        // 侧滑目录树view
        case slide
        case categoryClick = "wiki_category_click"
        // Wiki AI入口点击
        case wikiAiEntrance = "wiki_ai_entrance"
    }

    public typealias ViewType = WorkspacePickerTracker.ActionType

    public enum ClickSearchSubModule: String {
        // 首页
        case wikiHome = "wiki_home"
        // 全部空间页
        case wikiAllSpace = "wiki_all_space"
        // 树页面
        case wikiPages = "wiki_pages"
    }

    public enum ClickSearchSource: String {
        // 浏览树
        case wikiPagesView = "wiki_pages_view"
        // 操作树（新建和移动）
        case wikiPagesOperation = "wiki_pages_operation"
    }

    public enum ClickSearchAction: String {
        // 点击搜索按钮或搜索框
        case searchButton = "search_button"
        // 点击搜索结果
        case clickSearchItem = "click_search_item"
        // 点击历史记录
        case clickSearchHistory = "click_search_history"
    }

    // 目录树操作的触发位置
    public typealias TriggerLocation = WorkspacePickerTracker.TriggerLocation

    private typealias StatisticParameters = [ReportKey: Any]

    static func eventTriggerLocation(meta: WikiTreeNodeMeta,
                                     nodeUID: WikiTreeNodeUID) -> TriggerLocation {
        switch nodeUID.section {
        case .mutilTreeRoot:
            return .sidebarPinWiki
        case .documentRoot:
            return .sidebarPinDocs
        case .mainRoot:
            if MyLibrarySpaceIdCache.isMyLibrary(meta.spaceID) {
                if meta.nodeType == .mainRoot {
                    return .sidebarMyDocsTab
                } else if meta.nodeType == .normal {
                    return .sidebarMyDocsNode
                }
            }
        default:
            break
        }
        return .wikiTree
    }

    /// 展开页面树 done
    public static func expandPage(wikiToken: String) {
        let para: StatisticParameters = [.action: ActionType.expandPages.rawValue,
                                         .fileId: DocsTracker.encrypt(id: wikiToken),
                                         .fileType: "doc",
                                         .module: "wiki2.0"]
        log(event: .wikiPagesOperation, parameters: para)
    }

    /// 收起页面树 done
    public static func closePage(wikiToken: String) {
        let para: StatisticParameters = [.action: ActionType.closePages.rawValue,
                                         .fileId: DocsTracker.encrypt(id: wikiToken),
                                         .fileType: "doc",
                                         .module: "wiki2.0"]
        log(event: .wikiPagesOperation, parameters: para)
    }

    /// 在树上切换文档
    public static func switchPage(wikiToken: String,
                           fileType: String,
                           targetWikiToken: String) {
        let para: StatisticParameters = [.action: ActionType.switchPage.rawValue,
                                         .fileId: DocsTracker.encrypt(id: wikiToken),
                                         .targetFileId: DocsTracker.encrypt(id: targetWikiToken),
                                         .fileType: fileType,
                                         .module: "wiki2.0"]
        log(event: .wikiPagesOperation, parameters: para)
    }

    /// 上拉知识库面板到最大高度
    public static func fullExpandPage(wikiToken: String) {
        let para: StatisticParameters = [.action: ActionType.fullExpandPages.rawValue,
                                         .fileId: DocsTracker.encrypt(id: wikiToken),
                                         .fileType: "doc",
                                         .module: "wiki2.0"]
        log(event: .wikiPagesOperation, parameters: para)
    }

    /// 展开 / 收起树节点
    public static func nodeExpandChange(wikiToken: String, level: Int) {
        let para: StatisticParameters = [.action: ActionType.nodeExpandChange.rawValue,
                                         .fileId: DocsTracker.encrypt(id: wikiToken),
                                         .fileType: "doc",
                                         .module: "wiki2.0",
                                         .nodeLevel: level]
        log(event: .wikiPagesOperation, parameters: para)
    }

    // MARK: - Wiki HomePage
    public static func homePageClickSpace(count: Int, index: Int) {
        let params: StatisticParameters = [.action: ActionType.selectSpace.rawValue,
                                           .module: "wiki2.0",
                                           .count: count,
                                           .indexId: index]
        log(event: .wikiHomeWorkspaceOperation, parameters: params)
    }

    public static func homePageClickRecentPage(index: Int) {
        let params: StatisticParameters = [.action: ActionType.selectPage.rawValue,
                                           .module: "wiki2.0",
                                           .indexId: index]
        log(event: .wikiHomeWorkspaceOperation, parameters: params)
    }

    public static func homePageClickAllSpace(count: Int) {
        let params: StatisticParameters = [.action: ActionType.seeAll.rawValue,
                                           .module: "wiki2.0",
                                           .count: count]
        log(event: .wikiHomeWorkspaceOperation, parameters: params)
    }

    public static func homePageClickSearch() {
        let params: StatisticParameters = [.action: ActionType.search.rawValue,
                                           .module: "navigation_bar"]
        log(event: .wikiHomeWorkspaceOperation, parameters: params)
    }

    public static func homePageClickCreate() {
        let params: StatisticParameters = [.action: ActionType.create.rawValue,
                                           .module: "navigation_bar"]
        log(event: .wikiHomeWorkspaceOperation, parameters: params)
    }

    public static func homePageEnterEvent(from: String?) {
        let params: StatisticParameters = [.source: EnterWikiSource.homeLink.rawValue]
        log(event: .wikiEnterEvent, parameters: params)
    }

    // 进入wiki
    public static func wikiDetailEnter(from: String?) {
        let params: StatisticParameters = [.source: EnterWikiSource(from: from).rawValue]
        log(event: .wikiEnterEvent, parameters: params)
    }

    // 点击搜索
    public static func clickSearch(subModule: ClickSearchSubModule, source: ClickSearchSource, action: ClickSearchAction) {
        let para: StatisticParameters = [.subModule: subModule.rawValue,
                                         .module: "wiki2.0",
                                         .action: action.rawValue,
                                         .source: source.rawValue]
        log(event: .wikiClickSearch, parameters: para)
    }
    
    // 点击MyAI入口
    public static func clickMyAI() {
        var para: StatisticParameters = [.click: ClickType.wikiAiEntrance.rawValue,
                                         .target: DocsTracker.EventType.wikiAIEnterChatMainView.rawValue,
                                         .appForm: "null",
                                         .module: "wiki2.0",
                                         .subModule: "null",
                                         .containerType: "wiki"]
        newLog(event: .wikiAllSpaceClick, parameters: para)
    }


    // 新建子文档（从树上新建）
    public static func createFromTree(docsType: DocsType,
                               targetWikiToken: String) {
        let para: StatisticParameters = [.action: ActionType.createFromTree.rawValue,
                                         .targetFileId: DocsTracker.encrypt(id: targetWikiToken),
                                         .fileType: docsType.name,
                                         .module: "wiki2.0"]
        log(event: .wikiPagesOperation, parameters: para)
    }

    // 新建子文档（从首页新建）
    public static func createFromHomePage(docsType: DocsType,
                                   targetWikiToken: String) {
        let para: StatisticParameters = [.action: ActionType.createFromHome.rawValue,
                                         .targetFileId: DocsTracker.encrypt(id: targetWikiToken),
                                         .fileType: docsType.name,
                                         .module: "wiki2.0"]
        log(event: .wikiPagesOperation, parameters: para)
    }

    // 树上点击删除
    public static func clickTreeNodeDelete(wikiToken: String,
                                           fileType: String) {
        let para: StatisticParameters = [.action: ActionType.clickDelete.rawValue,
                                         .fileId: DocsTracker.encrypt(id: wikiToken),
                                         .fileType: fileType,
                                         .module: "wiki2.0"]
        log(event: .wikiPagesOperation, parameters: para)
    }

    // 树上点击确认删除
    public static func confirmTreeNodeDelete(wikiToken: String,
                                             fileType: String,
                                             status: Status) {
        let para: StatisticParameters = [.action: ActionType.confirmDelete.rawValue,
                                         .fileId: DocsTracker.encrypt(id: wikiToken),
                                         .fileType: fileType,
                                         .status: status.rawValue,
                                         .module: "wiki2.0"]
        log(event: .wikiPagesOperation, parameters: para)
    }

    // 树上点击移动
    public static func clickTreeNodeMove(wikiToken: String,
                                  fileType: String) {
        let para: StatisticParameters = [.action: ActionType.clickMove.rawValue,
                                         .fileId: DocsTracker.encrypt(id: wikiToken),
                                         .fileType: fileType,
                                         .module: "wiki2.0"]
        log(event: .wikiPagesOperation, parameters: para)
    }

    // 树上点击确认移动
    public static func confirmTreeNodeMove(wikiToken: String,
                                    fileType: String) {
        let para: StatisticParameters = [.action: ActionType.confirmMove.rawValue,
                                         .fileId: DocsTracker.encrypt(id: wikiToken),
                                         .fileType: fileType,
                                         .module: "wiki2.0"]
        log(event: .wikiPagesOperation, parameters: para)
    }

    public enum ReferenceType: String {
        case original
        case shortcut
    }

    public enum Status: String {
        case success
        case fail
    }

    // 树上点击创建快捷方式
    public static func shortcutTo(wikiToken: String,
                           docsType: String,
                           refType: ReferenceType) {
        let para: StatisticParameters = [.action: ActionType.shortcutTo.rawValue,
                                         .fileId: DocsTracker.encrypt(id: wikiToken),
                                         .fileType: docsType,
                                         .refType: refType.rawValue,
                                         .module: "wiki2.0"]
        log(event: .wikiPagesOperation, parameters: para)
    }

    // 树上左滑
    public static func swipeInTree(wikiToken: String,
                            fileType: String) {
        let para: StatisticParameters = [.action: ActionType.swipePage.rawValue,
                                         .fileId: DocsTracker.encrypt(id: wikiToken),
                                         .fileType: fileType,
                                         .module: "wiki2.0"]
        log(event: .wikiPagesOperation, parameters: para)
    }

    public static func star(wikiToken: String,
                            fileType: String,
                            refType: ReferenceType) {
        let para: StatisticParameters = [.action: ActionType.star.rawValue,
                                         .fileId: DocsTracker.encrypt(id: wikiToken),
                                         .fileType: fileType,
                                         .refType: refType.rawValue,
                                         .module: "wiki2.0"]
        log(event: .wikiPagesOperation, parameters: para)
    }

    public static func unstar(wikiToken: String,
                              fileType: String,
                              refType: ReferenceType) {
        let para: StatisticParameters = [.action: ActionType.unstar.rawValue,
                                         .fileId: DocsTracker.encrypt(id: wikiToken),
                                         .fileType: fileType,
                                         .refType: refType.rawValue,
                                         .module: "wiki2.0"]
        log(event: .wikiPagesOperation, parameters: para)
    }

    public static func copy(wikiToken: String,
                            fileType: String) {
        let para: StatisticParameters = [.action: ActionType.copy.rawValue,
                                         .fileId: DocsTracker.encrypt(id: wikiToken),
                                         .fileType: fileType,
                                         .module: "wiki2.0"]
        log(event: .wikiPagesOperation, parameters: para)
    }

    public static func confirmCopy(wikiToken: String,
                                   fileType: String,
                                   status: Status) {
        let para: StatisticParameters = [.action: ActionType.confirmCopy.rawValue,
                                         .fileId: DocsTracker.encrypt(id: wikiToken),
                                         .fileType: fileType,
                                         .status: status.rawValue,
                                         .module: "wiki2.0"]
        log(event: .wikiPagesOperation, parameters: para)
    }

    /*
     * 知识库首页事件
         * isLoadingSuccess: 首页知识库列表是否加载完成
         * isEmpty: 知识库列表是否为囧
         * containerType：公参，容器类型
         * appForm:
         * module: 模块类型
         * subModule：子模块
     */
    public static func homeView(isLoadingSuccess: Bool, isSpacesEmpty: Bool) {
        let para: StatisticParameters = [.isLoadingSuccess: String(isLoadingSuccess),
                                         .isEmpty: String(isSpacesEmpty),
                                         .appForm: "null",
                                         .module: "wiki",
                                         .subModule: "null",
                                         .containerType: "wiki"]
        newLog(event: .wikiHomeView, parameters: para)
    }

    /*
     * 知识库页面
         * containerType：公参，容器类型
         * appForm:
         * module: 模块类型
         * subModule：子模块
     */
    public static func allSpaceView(categoryShow: Bool? = nil) {
        var params: StatisticParameters = [.containerType: "wiki",
                                           .appForm: "null",
                                           .module: "wiki",
                                           .subModule: "null"]
        if let categoryShow {
            params[.categoryShow] = categoryShow
        }
        newLog(event: .wikiAllSpaceView, parameters: params)
    }

    /*
     * wiki新建页面
         * containerType：公参，容器类型
         * appForm:
         * module: 模块类型
         * subModule：子模块
     */
    public static func createNewView() {
        newLog(event: .wikiCreateNewView, parameters: [.containerType: "wiki",
                                                       .appForm: "null",
                                                       .module: "wiki",
                                                       .subModule: "null"])
    }

    /*
     * 所有知识库目标位置选择页面
         * viewTitle: 新建文档，移动至等事件标题
         * containerType：公参，容器类型
         * appForm:
         * module: 模块类型
         * subModule：子模块
     */
    public static func fileLocationSelectView(viewTitle: ViewType, triggerLocation: TriggerLocation) {
        let para: StatisticParameters = [.viewTitle: viewTitle.rawValue,
                                         .appForm: "null",
                                         .module: "wiki",
                                         .subModule: "null",
                                         .containerType: "wiki",
                                         .triggerLocation: triggerLocation.rawValue]
        newLog(event: .wikiFileLocationSelectView, parameters: para)
    }
    /*
     * wiki页面树页面
         * containerId: 知识库id
         * containerType：公参，容器类型
         * appForm:
         * module: 模块类型
         * subModule：子模块
     */
    public static func treeView(spaceId: String) {
        newLog(event: .wikiTreeView, parameters: [.containerType: "wiki",
                                                  .appForm: "null",
                                                  .module: "wiki",
                                                  .containerId: DocsTracker.encrypt(id: spaceId),
                                                  .subModule: "null",
                                                  .isMyLibrary: String(MyLibrarySpaceIdCache.isMyLibrary(spaceId))])
    }

    /*
     * 页面树上新建节点页面
         * containerId: 知识库id
         * pageToken: wikiToken
         * isShortcut: 是否为shortcut
         * shortcutId: 目前为wikiToken
         * fileId: wiki源文档token
         * fileType: 文件类型
         * containerType：公参，容器类型，默认wiki
         * appForm:
         * module: 公参，模块类型，默认wiki
         * subModule：子模块
     */
    public static func treeAddView(meta: WikiTreeNodeMeta) {
        let isShortcut = meta.isShortcut
        newLog(event: .wikiTreeAddView, parameters: [.pageToken: DocsTracker.encrypt(id: meta.wikiToken),
                                                     .isShortcut: String(isShortcut),
                                                     .shortcutId: isShortcut ? DocsTracker.encrypt(id: meta.wikiToken) : "null",
                                                     .appForm: "null",
                                                     .module: "wiki",
                                                     .subModule: "null",
                                                     .fileId: DocsTracker.encrypt(id: meta.objToken),
                                                     .fileType: meta.objType.name,
                                                     .containerId: DocsTracker.encrypt(id: meta.spaceID),
                                                     .containerType: "wiki",
                                                     .isMyLibrary: String(MyLibrarySpaceIdCache.isMyLibrary(meta.spaceID))])
    }

    /*
     * 页面树更多菜单页面
         * containerId: 知识库id
         * pageToken: wikiToken
         * isShortcut: 是否为shortcut
         * shortcutId: 目前为wikiToken
         * fileId: wiki源文档token
         * fileType: 文件类型
         * containerType：公参，容器类型，默认wiki
         * appForm:
         * module: 公参，模块类型，默认wiki
         * subModule：子模块
     */
    public static func treeMoreView(meta: WikiTreeNodeMeta) {
        let isShortcut = meta.isShortcut
        newLog(event: .wikiTreeMoreView, parameters: [.pageToken: DocsTracker.encrypt(id: meta.wikiToken),
                                                      .isShortcut: String(isShortcut),
                                                      .shortcutId: isShortcut ? DocsTracker.encrypt(id: meta.wikiToken) : "null",
                                                      .originalContainer: meta.originIsExternal ? "space" : "wiki",
                                                      .appForm: "null",
                                                      .module: "wiki",
                                                      .subModule: "null",
                                                      .fileId: DocsTracker.encrypt(id: meta.objToken),
                                                      .fileType: meta.objType.name,
                                                      .containerId: DocsTracker.encrypt(id: meta.spaceID),
                                                      .containerType: "wiki",
                                                      .isMyLibrary: String(MyLibrarySpaceIdCache.isMyLibrary(meta.spaceID))])
    }

    public enum ViewTitle: String {
        case moveTo = "move_to"
        case moveToSpace = "move_to_space"
        case shortcutTo = "shortcut_to"
    }

    /*
     * moveToWiki后出现的权限变更提示页面
         * containerId: 知识库id
         * pageToken: wikiToken
         * isShortcut: 是否为shortcut
         * shortcutId: 目前为wikiToken
         * viewTitle: 新建文档，移动至等事件标题
         * fileId: wiki源文档token
         * fileType: 文件类型
         * containerType：公参，容器类型，默认wiki
         * appForm:
         * module: 公参，模块类型，默认wiki
         * subModule：子模块
     */
    public static func permissonChangeView(context: WikiInteractionHandler.Context, viewTitle: ViewTitle) {
        let isShortcut = context.isShortcut
        newLog(event: .wikiPermissionChangeView, parameters: [.pageToken: DocsTracker.encrypt(id: context.wikiToken),
                                                              .isShortcut: String(isShortcut),
                                                              .shortcutId: isShortcut ? DocsTracker.encrypt(id: context.wikiToken) : "null",
                                                              .viewTitle: viewTitle.rawValue,
                                                              .appForm: "null",
                                                              .module: "wiki",
                                                              .subModule: "null",
                                                              .fileId: DocsTracker.encrypt(id: context.objToken),
                                                              .fileType: context.objType.name,
                                                              .containerId: DocsTracker.encrypt(id: context.spaceID),
                                                              .containerType: "wiki",
                                                              .isMyLibrary: String(MyLibrarySpaceIdCache.isMyLibrary(context.spaceID))])
    }

    public static func permissonChangeClick(context: WikiInteractionHandler.Context,
                                            clickType: ClickType,
                                            viewTitle: ViewTitle,
                                            target: String) {
        let isShortcut = context.isShortcut
        newLog(event: .wikiPermissionChangeClick,
               parameters: [
                .click: clickType.rawValue,
                .pageToken: DocsTracker.encrypt(id: context.wikiToken),
                .isShortcut: String(isShortcut),
                .target: target,
                .shortcutId: isShortcut ? DocsTracker.encrypt(id: context.wikiToken) : "null",
                .viewTitle: viewTitle.rawValue,
                .appForm: "null",
                .module: "wiki",
                .subModule: "null",
                .fileId: DocsTracker.encrypt(id: context.objToken),
                .fileType: context.objType.name,
                .containerId: DocsTracker.encrypt(id: context.spaceID),
                .containerType: "wiki",
                .isMyLibrary: String(MyLibrarySpaceIdCache.isMyLibrary(context.spaceID))
               ])
    }

    public static func applyMoveOutView(context: WikiInteractionHandler.Context, viewTitle: ViewTitle) {
        let isShortcut = context.isShortcut
        newLog(event: .wikiApplyMoveOutView,
               parameters: [
                .pageToken: DocsTracker.encrypt(id: context.wikiToken),
                .isShortcut: String(isShortcut),
                .shortcutId: isShortcut ? DocsTracker.encrypt(id: context.wikiToken) : "null",
                .viewTitle: viewTitle.rawValue,
                .appForm: "null",
                .module: "wiki",
                .subModule: "null",
                .fileId: DocsTracker.encrypt(id: context.objToken),
                .fileType: context.objType.name,
                .containerId: DocsTracker.encrypt(id: context.spaceID),
                .containerType: "wiki",
                .isMyLibrary: String(MyLibrarySpaceIdCache.isMyLibrary(context.spaceID))
               ])
    }

    public static func applyMoveOutClick(context: WikiInteractionHandler.Context,
                                         clickType: ClickType,
                                         viewTitle: ViewTitle,
                                         haveComment: Bool,
                                         target: String) {
        let isShortcut = context.isShortcut
        newLog(event: .wikiPermissionChangeClick,
               parameters: [
                .click: clickType.rawValue,
                .isComment: String(haveComment),
                .pageToken: DocsTracker.encrypt(id: context.wikiToken),
                .isShortcut: String(isShortcut),
                .target: target,
                .shortcutId: isShortcut ? DocsTracker.encrypt(id: context.wikiToken) : "null",
                .viewTitle: viewTitle.rawValue,
                .appForm: "null",
                .module: "wiki",
                .subModule: "null",
                .fileId: DocsTracker.encrypt(id: context.objToken),
                .fileType: context.objType.name,
                .containerId: DocsTracker.encrypt(id: context.spaceID),
                .containerType: "wiki",
                .isMyLibrary: String(MyLibrarySpaceIdCache.isMyLibrary(context.spaceID))
               ])
    }

    /*
     * 删除wiki确认页面
         * containerId: 知识库id
         * pageToken: wikiToken
         * isShortcut: 是否为shortcut
         * shortcutId: 目前为wikiToken
         * fileId: wiki源文档token
         * fileType: 文件类型
         * containerType：公参，容器类型，默认wiki
         * appForm:
         * module: 公参，模块类型，默认wiki
         * subModule：子模块
     */
    public static func deleteConfirmView(meta: WikiTreeNodeMeta) {
        let isShortcut = meta.isShortcut
        newLog(event: .wikiDeleteConfirmView, parameters: [.pageToken: DocsTracker.encrypt(id: meta.wikiToken),
                                                           .isShortcut: String(isShortcut),
                                                           .shortcutId: isShortcut ? DocsTracker.encrypt(id: meta.wikiToken) : "null",
                                                           .appForm: "null",
                                                           .module: "wiki",
                                                           .subModule: "null",
                                                           .fileId: DocsTracker.encrypt(id: meta.objToken),
                                                           .fileType: meta.objType.name,
                                                           .containerId: DocsTracker.encrypt(id: meta.spaceID),
                                                           .containerType: "wiki",
                                                           .includeChildrenPage: meta.hasChild,
                                                           .isMyLibrary: String(MyLibrarySpaceIdCache.isMyLibrary(meta.spaceID))])
    }

    /*
     * 知识库首页点击事件
         * click: 在页面的动作
         * target: 动作发生后到达的目标页面
         * containerType：公参，容器类型，默认wiki
         * appForm:
         * module: 公参，模块类型，默认wiki
         * subModule：子模块
     */
    public static func clickHomeView(click: ClickType, target: String, params: [ReportKey: Any] = [:]) {
        var para: StatisticParameters = [.click: click.rawValue,
                                         .target: target,
                                         .appForm: "null",
                                         .module: "wiki",
                                         .subModule: "null",
                                         .containerType: "wiki"]
        para.merge(other: params)
        newLog(event: .wikiHomeClick, parameters: para)
    }

    /*
     * 知识库首页点击查看所有知识库事件
         * click: 在页面的动作
         * target: 动作发生后到达的目标页面
         * containerType：公参，容器类型，默认wiki
         * appForm:
         * module: 公参，模块类型，默认wiki
         * subModule：子模块
     */
    public static func clickAllSpaceView(clickType: ClickType = .workspace, categoryId: String? = nil) {
        var para: StatisticParameters = [.click: clickType.rawValue,
                                         .target: DocsTracker.EventType.wikiTreeView.rawValue,
                                         .appForm: "null",
                                         .module: "wiki",
                                         .subModule: "null",
                                         .containerType: "wiki"]
        if let categoryId {
            para[.categoryId] = categoryId
        }
        newLog(event: .wikiAllSpaceClick, parameters: para)
    }
    /*
     * 所有wiki新建页面发生动作事件
         * click: 在页面的动作，这里是创建的文档类型
         * target: 动作发生后到达的目标页面
         * containerType：公参，容器类型，默认wiki
         * appForm:
         * module: 公参，模块类型，默认wiki
         * subModule：子模块
     */
    public static func clickCreateNewView(fileType: String) {
        let para: StatisticParameters = [.click: fileType,
                                         .target: DocsTracker.EventType.wikiFileLocationSelectView.rawValue,
                                         .appForm: "null",
                                         .module: "wiki",
                                         .subModule: "null",
                                         .containerType: "wiki",
                                         .isFavorites: "false"]
        newLog(event: .wikiCreateNewClick, parameters: para)
    }
    
    public static func clickCreateNewViewByTemplate(click: String, target: String) {
        let para: StatisticParameters = [.click: click,
                                         .target: target,
                                         .appForm: "null",
                                         .module: "wiki",
                                         .subModule: "null",
                                         .containerType: "wiki",
                                         .isFavorites: "false"]
        newLog(event: .wikiCreateNewClick, parameters: para)
    }

    public typealias TargetModule = WorkspacePickerTracker.TargetModule
    public typealias TargetFolderType = WorkspacePickerTracker.TargetFolderType

    /*
     * 知识库选择目标位置页面发生动作事件
         * click: 在页面的动作 确认
         * target: 动作发生后到达的目标页面
         * targetSpaceId: 目标知识库id
         * childrenFileId: 新节点文档的objToken
         * childrenFileType: 新节点文档的类型
         * childrenPageToken: 新文档wikiToken
         * pageToken: 源文档wikiToken
         * isShortcut: 是否为shortcut
         * shortcutId: 目前为wikiToken
         * fileId: 源文档objToken
         * fileType: 文档类型
         * containerType：公参，容器类型，默认wiki
         * appForm:
         * module: 公参，模块类型，默认wiki
         * subModule：子模块
     */
    /// 知识库选择目标位置页面发生动作事件
    /// - Parameters:
    ///   - targetSpaceId: 目标容器 ID，知识库 ID 或文件夹 FolderToken
    ///   - fileId: 新节点 objToken
    ///   - fileType: 新节点 objType
    ///   - filePageToken: 新节点 pageToken，wiki 节点的 wikiToken、space 节点的 objToken、space shortcut 节点的 nodeToken
    ///   - viewTitle: 操作事件
    ///   - originSpaceId: 被操作节点的知识库 ID
    ///   - originWikiToken: 被操作节点的 wikiToken
    ///   - isShortcut: 被操作节点是否是 shortcut
    ///   - triggerLocation: 操作触发来源
    ///   - targetModule: 目标位置所属 module
    ///   - targetFolderType: 目标 space 文件夹类型，目标是 wiki 时不传
    public static func clickFileLocationSelect(targetSpaceId: String,
                                               fileId: String,
                                               fileType: String,
                                               filePageToken: String,
                                               viewTitle: ViewType,
                                               originSpaceId: String,
                                               originWikiToken: String,
                                               isShortcut: Bool,
                                               triggerLocation: TriggerLocation,
                                               targetModule: TargetModule,
                                               targetFolderType: TargetFolderType?) {
        var para: StatisticParameters = [
            .click: ClickType.confirm.rawValue,
            .viewTitle: viewTitle.rawValue,
            .target: DocsTracker.EventType.docsPageView.rawValue,
            .childrenFileId: DocsTracker.encrypt(id: fileId),
            .childrenFileType: fileType,
            .childrenPageToken: DocsTracker.encrypt(id: filePageToken),
            .pageToken: DocsTracker.encrypt(id: originWikiToken),
            .isShortcut: String(isShortcut),
            .shortcutId: isShortcut ? DocsTracker.encrypt(id: originWikiToken) : "null",
            .appForm: "null",
            .module: "wiki",
            .subModule: "null",
            .fileId: DocsTracker.encrypt(id: fileId),
            .fileType: fileType,
            .containerId: DocsTracker.encrypt(id: originSpaceId),
            .containerType: "wiki",
            .triggerLocation: triggerLocation.rawValue,
            .targetModule: targetModule.rawValue,
            .isMyLibrary: String(targetModule == .myLibrary)
        ]
        if targetSpaceId.isEmpty {
            // 选中我的空间根节点时，需要传空串
            para[.targetSpaceId] = ""
        } else {
            para[.targetSpaceId] = DocsTracker.encrypt(id: targetSpaceId)
        }
        if let targetFolderType = targetFolderType {
            para[.targetFolderType] = targetFolderType.rawValue
        }
        newLog(event: .wikiFileLocationSelectClick, parameters: para)
    }

    /*
     * 树节点展开事件
         * click: 在页面的动作，展开/收起
         * isFavorites: 是否是在收藏节点操作
         * target: 动作发生后到达的目标页面
         * pageToken: 源文档wikiToken
         * isShortcut: 是否为shortcut
         * shortcutId: 目前为wikiToken
         * fileId: 源文档objToken
         * fileType: 文档类型
         * containerType：公参，容器类型，默认wiki
         * appForm:
         * module: 公参，模块类型，默认wiki
         * subModule：子模块
     */
    public static func clickWikiTreeExpand(isExpand: Bool,
                                    isFavorites: Bool,
                                    meta: WikiTreeNodeMeta) {
        let isShortcut = meta.isShortcut
        let para: StatisticParameters = [.click: isExpand ? ClickType.expand.rawValue : ClickType.collapse.rawValue,
                                         .isFavorites: String(isFavorites),
                                         .target: "none",
                                         .pageToken: DocsTracker.encrypt(id: meta.wikiToken),
                                         .isShortcut: String(isShortcut),
                                         .shortcutId: isShortcut ? DocsTracker.encrypt(id: meta.wikiToken) : "null",
                                         .originalContainer: meta.originIsExternal ? "space" : "wiki",
                                         .appForm: "null",
                                         .module: "wiki",
                                         .subModule: "null",
                                         .fileId: DocsTracker.encrypt(id: meta.objToken),
                                         .fileType: meta.objType.name,
                                         .containerId: DocsTracker.encrypt(id: meta.spaceID),
                                         .containerType: "wiki",
                                         .isMyLibrary: String(MyLibrarySpaceIdCache.isMyLibrary(meta.spaceID))]
        newLog(event: .wikiTreeClick, parameters: para)
    }

    /*
     * wiki页面树发生动作事件
         * click: 在页面的动作，切换文档/左滑more/左滑添加
         * isFavorites: 是否是在收藏节点操作
         * target: 动作发生后到达的目标页面
         * pageToken: 源文档wikiToken
         * isShortcut: 是否为shortcut
         * shortcutId: 目前为wikiToken
         * fileId: 源文档objToken
         * fileType: 文档类型
         * containerType：公参，容器类型，默认wiki
         * appForm:
         * module: 公参，模块类型，默认wiki
         * subModule：子模块
     */
    static func clickWikiTree(click: ClickType,
                              isFavorites: Bool,
                              target: String,
                              meta: WikiTreeNodeMeta) {
        let isShortcut = meta.isShortcut
        let para: StatisticParameters = [
            .click: click.rawValue,
            .isFavorites: String(isFavorites),
            .target: target,
            .pageToken: DocsTracker.encrypt(id: meta.wikiToken),
            .isShortcut: String(isShortcut),
            .shortcutId: isShortcut ? DocsTracker.encrypt(id: meta.wikiToken) : "null",
            .originalContainer: meta.originIsExternal ? "space" : "wiki",
            .appForm: "null",
            .module: "wiki",
            .subModule: "null",
            .fileId: DocsTracker.encrypt(id: meta.objToken),
            .fileType: meta.objType.name,
            .containerId: DocsTracker.encrypt(id: meta.spaceID),
            .containerType: "wiki",
            .isMyLibrary: String(MyLibrarySpaceIdCache.isMyLibrary(meta.spaceID))
        ]
        newLog(event: .wikiTreeClick, parameters: para)
    }

    //收藏知识库
    /*
     * click: 在页面的动作，收藏/取消收藏
     * containerType：公参，容器类型，默认wiki
     * appForm:
     * module: 公参，模块类型，默认wiki
     * subModule：子模块
     */
    public static func starWorkSpace(isStar: Bool) {
        let para: StatisticParameters = [.click: isStar ? ClickType.starWorkspace.rawValue: ClickType.unstarWorkspace.rawValue,
                                         .appForm: "null",
                                         .module: "wiki",
                                         .subModule: "null",
                                         .target: "none",
                                         .containerType: "wiki"]
        newLog(event: .wikiTreeClick, parameters: para)
    }

    /* 点击知识库详情
         * click: 在页面的动作，点击知识库详情
         * containerType：公参，容器类型，默认wiki
         * appForm:
         * module: 公参，模块类型，默认wiki
         * subModule：子模块
     */
    public static func clickWorkSpaceDetail() {
        let para: StatisticParameters = [.click: ClickType.workspaceDetail.rawValue,
                                         .appForm: "null",
                                         .module: "wiki",
                                         .subModule: "null",
                                         .target: "none",
                                         .containerType: "wiki"]
        newLog(event: .wikiTreeClick, parameters: para)
    }

    struct TreeAddEvent {
        let wikiToken: String
        let fileId: String
        let fileType: String
        let isFavorites: Bool
        let target: String
        let meta: WikiTreeNodeMeta
        let triggerLocation: TriggerLocation
    }
    /// 页面树上新建节点页面发生动作事件
    /// - Parameters:
    ///   - wikiToken: 新建成功的文档 wikiToken
    ///   - fileId: 新建成功的文档 objToken
    ///   - fileType: 新建成功的页面 DocType 名字
    ///   - isFavorites: 是否是从收藏树上触发
    ///   - target: 动作发生后到达的目标页面
    ///   - meta: 父节点信息
    ///   - node: 新建节点的父节点
    static func clickWikiTreeAdd(event: TreeAddEvent) {
        let para: StatisticParameters = [.click: event.fileType,
                                         .childrenPageToken: DocsTracker.encrypt(id: event.wikiToken),
                                         .childrenFileType: event.fileType,
                                         .childrenFileId: DocsTracker.encrypt(id: event.fileId),
                                         .isFavorites: String(event.isFavorites),
                                         .target: event.target,
                                         .pageToken: DocsTracker.encrypt(id: event.meta.wikiToken),
                                         .isShortcut: String(event.meta.isShortcut),
                                         .shortcutId: event.meta.isShortcut ? DocsTracker.encrypt(id: event.meta.wikiToken) : "null",
                                         .appForm: "null",
                                         .module: "wiki",
                                         .subModule: "null",
                                         .fileId: DocsTracker.encrypt(id: event.meta.objToken),
                                         .fileType: event.meta.objType.name,
                                         .containerId: DocsTracker.encrypt(id: event.meta.spaceID),
                                         .containerType: "wiki",
                                         .triggerLocation: event.triggerLocation.rawValue,
                                         .isMyLibrary: String(MyLibrarySpaceIdCache.isMyLibrary(event.meta.spaceID))
        ]
        newLog(event: .wikiTreeAddClick, parameters: para)
    }

    /*
     * 页面树上更多操作页面发生动作事件
         * click: 在页面的动作，move_to/delete/shortcut_to
         * isFavorites: 是否是在收藏节点操作
         * target: 动作发生后到达的目标页面
         * pageToken: 源文档wikiToken
         * isShortcut: 是否为shortcut
         * shortcutId: 目前为wikiToken
         * fileId: 源文档objToken
         * fileType: 文档类型
         * containerType：公参，容器类型，默认wiki
         * appForm:
         * module: 公参，模块类型，默认wiki
         * subModule：子模块
     */
    static func clickWikiTreeMore(click: ClickType,
                              isFavorites: Bool,
                              target: String,
                              meta: WikiTreeNodeMeta) {
        let isShortcut = meta.isShortcut
        let para: StatisticParameters = [.click: click.rawValue,
                                         .isFavorites: String(isFavorites),
                                         .target: target,
                                         .pageToken: DocsTracker.encrypt(id: meta.wikiToken),
                                         .isShortcut: String(isShortcut),
                                         .shortcutId: isShortcut ? DocsTracker.encrypt(id: meta.wikiToken) : "null",
                                         .originalContainer: meta.originIsExternal ? "space" : "wiki",
                                         .appForm: "null",
                                         .module: "wiki",
                                         .subModule: "null",
                                         .fileId: DocsTracker.encrypt(id: meta.objToken),
                                         .fileType: meta.objType.name,
                                         .containerId: DocsTracker.encrypt(id: meta.spaceID),
                                         .containerType: "wiki",
                                         .isMyLibrary: String(MyLibrarySpaceIdCache.isMyLibrary(meta.spaceID))]
        newLog(event: .wikiTreeMoreClick, parameters: para)
    }


    /*
     * 页面树上更多操作页面收藏取消收藏
         * click: 在页面的动作，收藏/取消收藏
         * isFavorites: 是否是在收藏节点操作
         * target: 动作发生后到达的目标页面
         * pageToken: 源文档wikiToken
         * isShortcut: 是否为shortcut
         * shortcutId: 目前为wikiToken
         * fileId: 源文档objToken
         * fileType: 文档类型
         * containerType：公参，容器类型，默认wiki
         * appForm:
         * module: 公参，模块类型，默认wiki
         * subModule：子模块
     */
    static func clickWikiTreeMoreStar(click: ClickType,
                                  isFavorites: Bool,
                                  pagesNum: Int,
                                  meta: WikiTreeNodeMeta) {
        let isShortcut = meta.isShortcut
        let para: StatisticParameters = [.click: click.rawValue,
                                         .isFavorites: String(isFavorites),
                                         .pagesNum: pagesNum,
                                         .target: "none",
                                         .pageToken: DocsTracker.encrypt(id: meta.wikiToken),
                                         .isShortcut: String(isShortcut),
                                         .shortcutId: isShortcut ? DocsTracker.encrypt(id: meta.wikiToken) : "null",
                                         .originalContainer: meta.originIsExternal ? "space" : "wiki",
                                         .appForm: "null",
                                         .module: "wiki",
                                         .subModule: "null",
                                         .fileId: DocsTracker.encrypt(id: meta.objToken),
                                         .fileType: meta.objType.name,
                                         .containerId: DocsTracker.encrypt(id: meta.spaceID),
                                         .containerType: "wiki",
                                         .isMyLibrary: String(MyLibrarySpaceIdCache.isMyLibrary(meta.spaceID))]
        newLog(event: .wikiTreeMoreClick, parameters: para)
    }
    
    enum DeleteScope: String {
        case all = "include_children"
        case single = "single_page"
    }

    /*
     * 知识空间确认删除文档页面发生动作事件
         * click: 在页面的动作，删除
         * isFavorites: 是否是在收藏节点操作
         * target: 动作发生后到达的目标页面
         * isSuccess: 是否删除成功
         * pageToken: 源文档wikiToken
         * isShortcut: 是否为shortcut
         * shortcutId: 目前为wikiToken
         * fileId: 源文档objToken
         * fileType: 文档类型
         * containerType：公参，容器类型，默认wiki
         * appForm:
         * module: 公参，模块类型，默认wiki
         * subModule：子模块
     */
    static func clickDeleteConfirm(isFavorites: Bool,
                                   isSuccess: Bool,
                                   includeChildren: Bool,
                                   deleteScope: DeleteScope,
                                   meta: WikiTreeNodeMeta) {
        let isShortcut = meta.isShortcut
        let para: StatisticParameters = [.click: ClickType.delete.rawValue,
                                         .isFavorites: String(isFavorites),
                                         .target: "none",
                                         .isSuccess: String(isSuccess),
                                         .pageToken: DocsTracker.encrypt(id: meta.wikiToken),
                                         .isShortcut: String(isShortcut),
                                         .shortcutId: isShortcut ? DocsTracker.encrypt(id: meta.wikiToken) : "null",
                                         .appForm: "null",
                                         .module: "wiki",
                                         .subModule: "null",
                                         .fileId: DocsTracker.encrypt(id: meta.objToken),
                                         .fileType: meta.objType.name,
                                         .containerId: DocsTracker.encrypt(id: meta.spaceID),
                                         .containerType: "wiki",
                                         .includeChildrenPage: String(includeChildren),
                                         .deleteScope: deleteScope.rawValue,
                                         .isMyLibrary: String(MyLibrarySpaceIdCache.isMyLibrary(meta.spaceID))]
        newLog(event: .wikiTreeDeleteConfirmClick, parameters: para)
    }

    /*
     * 知识空间确认删除文档页面发生动作事件
         * click: 在页面的动作，取消
         * isFavorites: 是否是在收藏节点操作
         * target: 动作发生后到达的目标页面
         * isSuccess: 是否删除成功
         * pageToken: 源文档wikiToken
         * isShortcut: 是否为shortcut
         * shortcutId: 目前为wikiToken
         * fileId: 源文档objToken
         * fileType: 文档类型
         * containerType：公参，容器类型，默认wiki
         * appForm:
         * module: 公参，模块类型，默认wiki
         * subModule：子模块
     */
    static func clickDeleteCancel(isFavorites: Bool, meta: WikiTreeNodeMeta) {
        let isShortcut = meta.isShortcut
        let para: StatisticParameters = [.click: ClickType.cancel.rawValue,
                                         .isFavorites: String(isFavorites),
                                         .pageToken: DocsTracker.encrypt(id: meta.wikiToken),
                                         .isShortcut: String(isShortcut),
                                         .shortcutId: isShortcut ? DocsTracker.encrypt(id: meta.wikiToken) : "null",
                                         .appForm: "null",
                                         .module: "wiki",
                                         .subModule: "null",
                                         .target: "none",
                                         .fileId: DocsTracker.encrypt(id: meta.objToken),
                                         .fileType: meta.objType.name,
                                         .containerId: DocsTracker.encrypt(id: meta.spaceID),
                                         .containerType: "wiki",
                                         .isMyLibrary: String(MyLibrarySpaceIdCache.isMyLibrary(meta.spaceID))]
        newLog(event: .wikiTreeDeleteConfirmClick, parameters: para)
    }
    /*
     * 上传进度条出现事件
         * containerID: spaceID 加密
         * containerType：公参，容器类型 wiki
         * appForm:
         * module: 模块类型 wiki
         * subModule：子模块
     */
    public static func spaceUploadProgressView(containerID: String) {
        let params: StatisticParameters = [.containerId: containerID,
                                           .appForm: "null",
                                           .module: "wiki",
                                           .subModule: "null",
                                           .containerType: "wiki",
                                           .isMyLibrary: String(MyLibrarySpaceIdCache.isMyLibrary(containerID))]
        newLog(event: .spaceUploadProgressView, parameters: params)
    }
    /*
     * 上传进度条出现事件
         * containerID: spaceID 加密
         * containerType：公参，容器类型 wiki
         * appForm:
         * module: 模块类型 wiki
         * subModule：子模块
         * click: 在上传进度条发送的事件
         * uploadStatus: 成功或者失败
     */
    public static func spaceUploadProgressClick(containerID: String, uploadStatus: String) {
        let params: StatisticParameters = [.containerId: containerID,
                                           .click: ClickType.finish.rawValue,
                                           .appForm: "null",
                                           .module: "wiki",
                                           .subModule: "null",
                                           .containerType: "wiki",
                                           .target: "none",
                                           .uploadStatus: uploadStatus,
                                           .isMyLibrary: String(MyLibrarySpaceIdCache.isMyLibrary(containerID))]
        newLog(event: .spaceUploadProgressClick, parameters: params)
    }

    public static func wikiDocsMoveResultToastView(success: Bool, viewTitle: ViewTitle) {
        let params: StatisticParameters = [
            .viewTitle: viewTitle.rawValue,
            .isSuccess: success ? "true" : "false"
        ]
        newLog(event: .wikiDocsMoveResultToastView, parameters: params)
    }

    public static func wikiDocsMoveResultToast(click: ClickType, viewTitle: ViewTitle, target: String) {
        let params: StatisticParameters = [
            .viewTitle: viewTitle.rawValue,
            .click: click.rawValue,
            .target: target
        ]
        newLog(event: .wikiDocsMoveResultToastClick, parameters: params)
    }
    
    // 目录树侧滑浏览操作
    public static func wikiTreeViewSlideEvent(spaceId: String) {
        let params: StatisticParameters = [.click: ClickType.slide.rawValue,
                                           .module: "wiki",
                                           .containerId: DocsTracker.encrypt(id: spaceId),
                                           .isMyLibrary: String(MyLibrarySpaceIdCache.isMyLibrary(spaceId))]
        newLog(event: .wikiTreeClick, parameters: params)
    }
    
    // 目录树当前一屏有超过屏幕宽度节点的事件上报
    public static func wikiTriggerSlideEvent(spaceID: String) {
        var params: [String: Any] = ["space_id": DocsTracker.encrypt(id: spaceID), "is_self_wiki": MyLibrarySpaceIdCache.isMyLibrary(spaceID)]
        DocsTracker.newLog(enumEvent: .wikiTriggerSlideEvent, parameters: params)
    }

    private static func log(event: DocsTracker.EventType, parameters: StatisticParameters) {
        var rawParameters: [AnyHashable: Any] = [:]
        parameters.forEach { rawParameters[$0.0.rawValue] = $0.1 }
        DocsLogger.debug("wiki2.0 event: \(event), params: \(rawParameters)")
        DocsTracker.log(enumEvent: event, parameters: rawParameters)
    }

    private static func newLog(event: DocsTracker.EventType, parameters: StatisticParameters) {
        var rawParameters: [AnyHashable: Any] = [:]
        parameters.forEach { rawParameters[$0.0.rawValue] = $0.1 }
        DocsLogger.debug("wiki2.0 new event: \(event), params: \(rawParameters)")
        DocsTracker.newLog(enumEvent: event, parameters: rawParameters)
    }
}
