//
//  AppCategoryViewModel.swift
//  LarkWorkplace
//
//  Created by 李论 on 2020/6/21.
//

import UIKit
import RoundedHUD
import LarkOPInterface
import LarkWorkplaceModel
import LKCommonsLogging

/// 工作台-单个app的状态
enum WPCategoryItemState {
    /// 应用未添加
    case add
    /// 应用已经添加
    case alreadyAdd
    /// 应用添加中
    case addLoading
    /// 应用移除中
    case removeLoading
    /// 获取应用（应用未安装）
    case get
    /// 获取状态相应的文案
    func getText() -> String {
        switch self {
        case .add:
            return BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_AddBttn
        case .alreadyAdd:
            return BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_AddedBttn
        case .get:
            return BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_GetBttn
        case .addLoading, .removeLoading:
            return ""
        }
    }
}

/// 工作台-添加页面-分类应用栏单个应用的ViewModel
final class WPCategoryItemViewModel: Equatable {
    /// 一个应用对应的信息
    var item: WPCategoryAppItem
    /// 应用当前的状态
    var state: WPCategoryItemState {
        didSet {
            if let callBack = stateChangeCallback {
                callBack()
            }
        }
    }
    /// state change callback（在V层实现，在VM / C 触发）
    var stateChangeCallback: (() -> Void)?
    /// 应用右侧操作按钮的点击事件（在VM / C中实现，在V层被触发）
    var operateButtonClick: ((WPCategoryItemViewModel) -> Void)?
    // 逻辑梳理：1.CategoryCell被点击，触发operaButtonClick事件，交由VM开始增删请求。
    //         2.请求期间伴随cell的状态变化，又触发stateChangeCallback事件，交由Cell处理，显示状态展示

    init(item: WPCategoryAppItem, state: WPCategoryItemState) {
        self.item = item
        self.state = state
    }
    /// 获取item的需要展示的tag类型
    func getNeedDisplayTagType() -> WPCellTagType {
        // 只展示 bot 或 共享应用 标签
        if let isSharedByOtherOrganization = item.isSharedByOtherOrganization, isSharedByOtherOrganization,
           item.sharedSourceTenantInfo != nil {
            // 是共享应用，且 info 不为空时，展示 tag
            return .shared
        }
        if let ability = item.itemAbility, ability == .bot {
            return .bot
        } else {
            return .none
        }
    }
    /// 判断viewModel相等
    static func == (lhs: WPCategoryItemViewModel, rhs: WPCategoryItemViewModel) -> Bool {
        return lhs.item.itemId == rhs.item.itemId
    }
}

/// 工作台-分类页面-分类页的状态
enum AppCategoryPageState {
    /// 页面加载中（显示state-加载页）
    case loading
    /// 页面加载失败（显示state-失败页）
    case fail
    /// 空态页面（显示state-空态页）
    case empty
    /// 正常显示（显示应用列表）
    case success
}

/// 工作台-分类页面-分类页ViewModel
final class AppCategoryPageModel {
    /// 对应的tag
    var tag: WPCategory
    /// 应用列表
    var appList: [WPCategoryItemViewModel]?
    /// 分类查询的结果是否有更多
    var hasMore: Bool
    /// page state
    var pageState: AppCategoryPageState {
        didSet {
            stateChangeCallback?()
        }
    }
    /// state change callback
    var stateChangeCallback: (() -> Void)?
    /// 点击重试的回调
    var retryCallback: (() -> Void)?
    /// 搜索关键字
    var keyword: String?

    init(tag: WPCategory, hasMore: Bool = false, pageState: AppCategoryPageState = .loading) {
        self.tag = tag
        self.hasMore = hasMore
        self.pageState = pageState
    }
}

/// 工作台-分类页面-状态
enum AppCategoryViewState {
    /// 加载中
    case loading
    /// 加载成功
    case success
    /// 加载失败
    case failed
}

/// 工作台-分类页面-顶层ViewModel
final class AppCategoryViewModel {
    static let logger = Logger.log(AppCategoryViewModel.self)

    /// 常用应用分类的tag id
    private let commonTagId = -1
    /// App Pool. Update after fetching app list from remote server.
    /// The state of app will update after user click cell button.
    var allAppMap: [String: WPCategoryItemViewModel] = [:]
    /// common app list（常用应用）
    var commonAppList: [WPCategoryItemViewModel]? {
        didSet {
            /// 将旧标记为常用应用的列表清除常用标记
            unCommonAppList(commonAppList: oldValue ?? [])
            /// 将新列表标记为常用
            commonAppList(commonAppList: commonAppList ?? [])
            /// 更新常用列表的ID set
            var tempIDSet: Set<String> = []
            for model in commonAppList ?? [] {
                tempIDSet.insert(model.item.itemId)
            }
            commonAppIDSet = tempIDSet
            /// 刷新UI
            checkAndUpdateIfNeed()
            /// 如果是修改了常用，通知工作台首页刷新数据
            if oldValue != nil {
                WPNoti.workplaceCommonAppDataChange.postDataNeedUpdateNoti()
            }
        }
    }
    /// page list（分类页）
    var pageList: [AppCategoryPageModel]?
    /// category name list
    var categoryNameList: [String] {
        var categoryNameList: [String] = []
        for pageModel in pageList ?? [] {
            categoryNameList.append(pageModel.tag.categoryName)
        }
        return categoryNameList
    }
    /// data update callback
    var dataUpdateBlock: ((_ model: AppCategoryViewModel) -> Void)?
    /// View State
    var state: AppCategoryViewState = .loading {
        didSet {
            checkAndUpdateIfNeed()
        }
    }
    /// selected Tag
    var selectedIndex: Int?
    /// cell操作按钮点击回调
    var cellButtonClickEvent: ((_ itemModel: WPCategoryItemViewModel) -> Void)?
    /// 常用应用加锁
    let lock = NSRecursiveLock()
    /// Search
    var searchModel: AppCategoryPageModel
    /// 快速判断一个应用是不是常用应用
    private var commonAppIDSet: Set<String> = []

    private let dataManager: AppCenterDataManager

    init(dataManager: AppCenterDataManager) {
        self.dataManager = dataManager
        /// 搜索模型
        searchModel = AppCategoryPageModel(tag: WPCategory(categoryId: 0, categoryName: ""))
        selectedIndex = 0
    }
    /// 将应用标记为非常用应用
    func unCommonAppList(commonAppList: [WPCategoryItemViewModel]) {
        for model in commonAppList {
            if let commonModel = allAppMap[model.item.itemId] {
                /// 已经拉下来了Model，需要merge一下已经安装的状态，避免界面闪一下
                commonModel.state = .add
            }
            model.state = .add
        }
    }
    /// 将应用标记为常用应用
    func commonAppList(commonAppList: [WPCategoryItemViewModel]) {
        for model in commonAppList {
            if let commonModel = allAppMap[model.item.itemId] {
                /// 已经拉下来了Model，需要merge一下已经安装的状态，避免界面闪一下
                commonModel.state = .alreadyAdd
            }
            model.state = .alreadyAdd
        }
    }
    /// 通过网络请求分类页面数据
    func switchToPageIndex(index: Int) {
        if index < pageList?.count ?? 0 {
            selectedIndex = index
            if let selectedTag = pageList?[index].tag {
                fetchCategoryList(tag: selectedTag)
            }
            checkAndUpdateIfNeed()
        }
    }
    /// item是否是常用应用
    func isAppInCommonList(itemId: String) -> Bool {
        return commonAppIDSet.contains(itemId)
    }
    /// 根据tag id 得到 pagemodel
    func findPageForTag(tagId: Int) -> AppCategoryPageModel? {
        defer {
            lock.unlock()
        }
        lock.lock()
        for page in (pageList ?? []) where page.tag.categoryId == tagId {
            return page
        }
        return nil
    }
    /// 根据itemid找到 ItemViewModel
    func findItemViewModel(itemID: String) -> WPCategoryItemViewModel? {
        defer {
            lock.unlock()
        }
        lock.lock()
        return allAppMap[itemID]
    }
    /// 处理搜索结果
    /// Update search result model with response data from server
    ///
    /// - Parameter searchResult: Response data from server, which contains installed and uninstall app list.
    func updateSearchResult(searchResult: WPSearchCategoryApp) {
        let page = AppCategoryPageModel(
            tag: searchModel.tag,
            hasMore: searchResult.hasMoreApps(),
            pageState: searchResult.isEmpty() ? .empty : .success
        )
        page.keyword = searchResult.query
        let appList = extractItemViewModels(category: searchResult)
        /// 同步搜索到的可以使用的app
        lock.lock()
        for app in appList {
            if let localState = findItemViewModel(itemID: app.item.itemId)?.state {
                app.state = localState
            }
        }
        /// 设置applist
        page.appList = appList
        /// 替换新的搜索结果
        searchModel = page
        lock.unlock()
    }
    /// 请求网络数据，常用应用、分类页面数据
    func loadRemoteData() {
        fetchCommonList()
        fetchCategoryList()
    }

    /// 请求网络数据，常用应用
    /// Fetch the list of common and recommend app from remote server. (Category-Agnostic)
    /// Update common app list `commonAppList` and page state `state`.
    func fetchCommonList() {
        dataManager.fetchRankPageInfoWith(
            needCache: false,
            success: { [weak self] (rankModel, isFromCache) in
                Self.logger.info("fetch data successed (isFromCache: \(isFromCache)")
                self?.handleCommonList(model: rankModel, err: nil)
            },
            failure: { [weak self] (err) in
                self?.handleCommonList(model: nil, err: err)
            }
        )
    }

    /// Fetch the list of app in certain category from remote server.
    /// If `tag` is `nil`, initialize `pageList`, update page model for "recently used" tag in `pageList` and page state `state`
    /// If  `tag` is not `nil`, update page model for certain tag in `pageList` and page state `state`.
    ///
    /// - Parameter tag: Request category info. If `tag` is `nil`, request for first page app list (recently used app).
    func fetchCategoryList(tag: WPCategory? = nil) {
        if let tag = tag {
            Self.logger.info("fetch CategoryList start by tag \(tag.categoryName)")
            dataManager.fetchCategorySearchWith(
                query: "",
                tagId: "\(tag.categoryId)",
                success: { [weak self] (categoryModel) in
                    Self.logger.info("fetch CategoryList end by tag \(tag.categoryName)")
                    self?.handleCategoryData(categoryModel: categoryModel, tag: tag)
                },
                failure: { [weak self] (err) in
                    Self.logger.error("fetch CategoryList end error by tag \(tag.categoryName)", error: err)
                    self?.handleCategoryData(categoryModel: nil, err: err, tag: tag)
                }
            )
        } else {
            /// 拉取首页的分类数据
            Self.logger.info("fetch index CategoryList start")
            dataManager.fetchCategoryInfo(
                success: { [weak self] (categoryModel, isFromCache) in
                    Self.logger.info("fetch index CategoryList end (isFromCache: \(isFromCache)")
                    self?.handleAllCategoryData(categoryModel: categoryModel, err: nil)
                },
                failure: { [weak self] (err) in
                    Self.logger.error("etch index CategoryList end error", error: err)
                    self?.handleAllCategoryData(categoryModel: nil, err: err)
                }
            )
        }
    }

    /// Transfer data model `WPSearchCategoryApp` requested from server to view model `[WPCategoryItemViewModel]`,
    /// Update page model for certain tag in `pageList` and page state `state`
    ///
    /// - Parameters:
    ///   - categoryModel: Data model from remote server, which contains list of installed and not installed app.
    ///   - err: Request / Decode failed error.
    ///   - tag: Category info.
    private func handleCategoryData(
        categoryModel: WPSearchCategoryApp?,
        err: Error? = nil,
        tag: WPCategory
    ) {
        Self.logger.info("handleCategoryData \(tag.categoryName)")
        guard err == nil else {
            Self.logger.error("handleCategoryData fail", tag: "AppCategoryViewModel", error: err)
            mergePageContent(appList: [], tagId: tag.categoryId, err: err)
            return
        }

        guard let category = categoryModel else {
            Self.logger.error("handleCategoryData categoryModel is nil", tag: "AppCategoryViewModel")
            mergePageContent(
                appList: [],
                tagId: tag.categoryId,
                err: NSError(
                    domain: "handleCategoryData",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "categoryModel is nil"]
                )
            )
            return
        }
        /// 处理为UI的 Model array
        let viewModels = extractItemViewModels(category: category)
        /// 回调UI
        mergePageContent(
            appList: viewModels,
            hasMore: category.hasMoreApps(),
            tagId: tag.categoryId
        )
    }

    /// Transfer data model `WPSearchCategoryApp` requested from server to view model `[WPCategoryItemViewModel]`.
    /// Initialize page model list `pageList`, update page model for commonly used category in `pageList` and page state.
    ///
    /// - Parameters:
    ///    - categoryModel: Data model from remote server, which contains list of installed and not installed app.
    ///    - err: Request / Decode failed error.
    private func handleAllCategoryData(categoryModel: WPSearchCategoryApp?, err: Error?) {
        Self.logger.info("handleHomeCategoryData \(categoryModel?.availableItems?.count ?? 0)")

        defer {
            checkAndUpdateIfNeed()
        }
        guard err == nil else {
            Self.logger.error(
                "handleHomeCategoryData fail",
                tag: "AppCategoryViewModel",
                error: err
            )
            mergePageList(err: err)
            return
        }

        guard let category = categoryModel else {
            Self.logger.error("handleCategoryData categoryModel is nil", tag: "AppCategoryViewModel")
            mergePageList(err: NSError(
                domain: "handleCategoryData",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "category is nil"]
            ))
            return
        }

        /// 解析分类的数据
        var tempPageList: [AppCategoryPageModel] = []
        for tag in category.categories ?? [] {
            let pageModel = AppCategoryPageModel(
                tag: tag,
                hasMore: category.hasMoreApps(),
                pageState: .loading
            )
            pageModel.retryCallback = { [weak self, weak pageModel] in
            guard let `self` = self else { return }
                if let pageModel = pageModel {
                    pageModel.pageState = .loading
                    self.fetchCategoryList(tag: pageModel.tag)
                    self.checkAndUpdateIfNeed()
                }
            }
            tempPageList.append(pageModel)
        }
        mergePageList(pageList: tempPageList)
        let viewModels = extractItemViewModels(category: category)
        /// 回调
        mergePageContent(
            appList: viewModels,
            tagId: commonTagId
        )
    }

    /// 根据分类或者搜索的到的结果，处理成 itemviewmodel列表
    /// Extract app view model list `[WPCategoryItemViewModel]` from response data model `WPSearchCategoryApp`.
    /// Initialize the state of each app with `.add` / `.alreadyAdd` / `.get` with reference to common app list `commonAppList`.
    ///
    /// - Parameter category: Data model from remote server, which contains list of installed and not installed app.
    private func extractItemViewModels(category: WPSearchCategoryApp) -> [WPCategoryItemViewModel] {
        /// 常用的信息是根据分类信息下来的，现在更新常用状态
        var tempCategoryViewModels: [WPCategoryItemViewModel] = []
        // 优化点：clickCallback不传model,availableItems和unavailableItems合成一个
        for wpCategoryItem in (category.availableItems ?? []) {
            let isCommonApp = isAppInCommonList(itemId: wpCategoryItem.itemId)
            let wpCategoryViewModel = WPCategoryItemViewModel(
                item: wpCategoryItem,
                state: isCommonApp ? .alreadyAdd : .add
            )
            wpCategoryViewModel.operateButtonClick = self.cellButtonClickEvent
            tempCategoryViewModels.append(wpCategoryViewModel)
        }
        /// 未安装的应用列表
        for wpCategoryItem in (category.unavailableItems ?? []) {
            let wpCategoryViewModel = WPCategoryItemViewModel(
                item: wpCategoryItem,
                state: .get
            )
            tempCategoryViewModels.append(wpCategoryViewModel)
            wpCategoryViewModel.operateButtonClick = self.cellButtonClickEvent
        }
        return tempCategoryViewModels
    }

    /// 同步分类结果页面，刷新page state
    /// Update page model for certain category in `pageList`, page state `state` and app pool `allAppMap`.
    ///
    /// - Parameters:
    ///   - appList: The list of app for certain category.
    ///   - hasMore: Has more apps.
    ///   - tagId: Category Identifier.
    ///   - err: Request / Decode failed error.
    private func mergePageContent(
        appList: [WPCategoryItemViewModel],
        hasMore: Bool = false,
        tagId: Int,
        err: Error? = nil
    ) {
        lock.lock()
        if let page = findPageForTag(tagId: tagId) {
            if err == nil {
                page.hasMore = hasMore
                page.appList = appList
                page.pageState = appList.isEmpty ? .empty : .success
                /// sync model state
                for model in appList {
                    let state = findItemViewModel(itemID: model.item.itemId)?.state ?? model.state
                    model.state = state
                    allAppMap[model.item.itemId] = model
                }
            } else {
                page.pageState = (page.appList == nil) ? .fail : .success
            }
        }
        lock.unlock()
    }

    /// 更新所有分类页列表
    /// Update page model list `pageList` and page state `state`.
    /// Change page state `state` to `.failed` if an error occured.
    /// Change page state `state` to `.success` or `.loading` with reference to the `commonAppList` and `pageList` setting status.
    ///
    /// - Parameters:
    ///    - pageList: New page model list.
    ///    - err: Request / Decode failed error.
    private func mergePageList(pageList: [AppCategoryPageModel] = [], err: Error? = nil) {
        Self.logger.info("mergePageList \(pageList.count)")
        guard err == nil else {
            Self.logger.error("mergePageList fail", tag: "AppCategoryViewModel", error: err)
            if self.pageList == nil {
                /// 如果当前没有分类页列表，那么设置为失败
                state = .failed
                WPMonitor().setCode(WPMCode.workplace_addapp_page_render_fail)
                    .setError(errMsg: "mergePageList fail", error: err)
                    .postFailMonitor()
            }
            return
        }
        lock.lock()
        self.pageList = pageList
        state = (isCommonAppListReady() && isPageListReady()) ? .success : .loading
        lock.unlock()
    }

    /// 处理常用应用列表刷新
    /// Transfer data model `WorkplaceRankPageViewModel` requested from server to view model `[WPCategoryItemViewModel]`,
    /// update the common app list `commonAppList` and page state `state`.
    ///
    /// - Parameters:
    ///    - model: Response model from server, which contains common and recommend app info
    ///    - err: Request / Decode failed error
    private func handleCommonList(model: WorkPlaceRankPageViewModel?, err: Error?) {
        Self.logger.info("handleCommonList \(model?.commonIconItemList ?? []) \(model?.commonWidgetItemList ?? [])")
        guard err == nil else {
            Self.logger.error("fetchCommonList fail", tag: "AppCategoryViewModel", error: err)
            mergeCommonAppList(appList: [], err: err)
            return
        }

        guard let rankModel = model else {
            Self.logger.error("fetchCommonList fail rankModel == nil", tag: "AppCategoryViewModel")
            return
        }
        /// 找到后台返回的合法的常用应用列表
        var tempCommonAppList: [WPCategoryItemViewModel] = []
        let itemList = (rankModel.recommendItemList ?? [])
            + (rankModel.distributedRecommendItemList ?? [])
            + (rankModel.commonIconItemList ?? [])
            + (rankModel.commonWidgetItemList ?? [])
        for itemID in itemList {
            if let item = rankModel.allItemInfos?[itemID] {
                let wpItem = WPCategoryAppItem.build(with: item)
                let wpItemModel = WPCategoryItemViewModel(item: wpItem, state: .alreadyAdd)
                tempCommonAppList.append(wpItemModel)
            }
        }

        mergeCommonAppList(appList: tempCommonAppList, err: nil)
    }

    /// 更新常用应用列表
    /// Update common app list `commonAppList` and page state `state`.
    /// Change page state `state` to `.failed` if an error occured and `commonAppList` is `nil`,
    /// Change page state `state` to `.success` or `.loading` with reference to the `commonAppList` and `pageList` setting status.
    ///
    /// - Parameters:
    ///   - appList: New common app list
    ///   - err: Request / Decode failed error
    private func mergeCommonAppList(
        appList: [WPCategoryItemViewModel],
        err: Error?
    ) {
        guard err == nil else {
            Self.logger.error(
                "mergeCommonAppList with error \(isCommonAppListReady())",
                tag: "AppCategoryViewModel"
            )
            if commonAppList == nil {
                /// 如果当前没有常用数据，那么设置为失败
                state = .failed
                WPMonitor().setCode(WPMCode.workplace_addapp_page_render_fail)
                    .setError(errMsg: "mergeCommonAppList fail", error: err)
                    .postFailMonitor()
            }
            return
        }

        lock.lock()
        commonAppList = appList
        state = (isCommonAppListReady() && isPageListReady()) ? .success : .loading
        lock.unlock()
    }

    /// 通知 ViewController 数据已更新，根据 View Model 刷新页面
    /// Notify ViewController to refresh page with updated view model.
    private func checkAndUpdateIfNeed() {
        /// 如果常用应用信息没有的话，不要回调; 如果当前状态已经失败了，那么回调
        if isCommonAppListReady() || state == .failed {
            dataUpdateBlock?(self)
        }
    }
    /// 常用应用是否准备好
    private func isCommonAppListReady() -> Bool {
        commonAppList != nil
    }
    /// 分类应用数据是否准备好
    private func isPageListReady() -> Bool {
        return pageList != nil
    }
}
