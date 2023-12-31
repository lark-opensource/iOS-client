//
//  WikiHomePageViewModelV2.swift
//  SKWikiV2
//
//  Created by majie.7 on 2022/12/5.
// swiftlint:disable file_length
// disable-lint: magic number

import Foundation
import SKCommon
import SKFoundation
import SKSpace
import RxSwift
import RxRelay
import RxCocoa
import SwiftyJSON
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignColor
import SKResource
import SKWorkspace
import LarkContainer

private extension Notification.Name {
    static let syncFilterStatus: Notification.Name = Notification.Name("WikiHomePageSyncFilterStatus")
}

struct WikiHomeListManager {
    var hasMore: Bool = false
    var starListHasMore: Bool = false
    var lastLabel: String?
    var starListLastLabel: String?
    var spaceType: SpaceType = .all
    var spaceClassType: SpaceClassType = .all
    
    var spaceTypeInt: Int? {
        switch spaceType {
        case .all, .star:
            return nil
        case .team:
            return 0
        case .personal:
            return 1
        }
    }
    
    //网络请求传参用， 数据库使用SpaceClassType内classID
    var classIdString: String? {
        switch spaceClassType {
        case .all, .star:
            return nil
        case .other(let classId):
            return classId
        }
    }
    
    mutating func update(hasMore: Bool, lastLabel: String) {
        self.hasMore = hasMore
        self.lastLabel = lastLabel
    }
    
    mutating func update(starHasMore: Bool, starLastLabel: String) {
        self.starListHasMore = starHasMore
        self.starListLastLabel = starLastLabel
    }
    
    mutating func update(type: SpaceType, classType: SpaceClassType) {
        self.spaceType = type
        self.spaceClassType = classType
    }
    
    mutating func update(classType: SpaceClassType) {
        self.spaceClassType = classType
    }
    
    mutating func update(spaceType: SpaceType) {
        self.spaceType = spaceType
    }
}

class WikiHomePageViewModelV2: NSObject, WikiHomePageViewModelProtocol {
    // Protocal
    struct Layout {
        static let heightOfHeaderSection: CGFloat = 44
    }
    var heightOfHeaderSection: CGFloat {
        Layout.heightOfHeaderSection
    }
    
    var actionOutput: Driver<WikiHomeAction> {
        actionInput.asDriver(onErrorJustReturn: .getListError(WikiError.dataParseError))
    }
    var tableViewShouldScrollToTop: Observable<Bool> {
        tableViewShouldScrollToTopSubject.asObserver()
    }
    var headerSpacesCount: Int {
        starSpaces.count
    }
    var isV2: Bool { true }
    var emptyListDescription: String {
        if filterShowEnableRelay.value {
            return BundleI18n.SKResource.LarkCCM_Wiki_CategoryMgmt_NoSpaceHere_Empty
        } else {
            return BundleI18n.SKResource.LarkCCM_Wiki_Category_NoWorkspace_Empty
        }
    }
    weak var ui: WikiHomePageUIDelegate?
    
    // WikiFilter配置
    let filterShowEnableRelay = BehaviorRelay(value: false)
    let filterClickEnableRelay = BehaviorRelay(value: true)
    let filterStateRelay = BehaviorRelay<SpaceListFilterState>(value: .deactivated)
    
    // 列表配置
    private var isLoadingSpaces: Bool = true
    var isReachable: Bool {
        reachabilityRelay.value
    }
    var starSpaces: [WikiSpace] = []
    var spaces: [WikiSpace] = []
    var classFilters: [WikiFilter] = []
    var listManager = WikiHomeListManager()
    var page: Int = 0   // 当前列表分页数
    let reachabilityRelay = BehaviorRelay(value: true)

    // Drive上传配置
    private var uploadHelper: SpaceListDriveUploadHelper
    private let mountToken: String = "all_files_token"
    private var driveListConfig: DriveListConfig { uploadHelper.driveListConfig }
    private var spacesRequest: DocsRequest<JSON>?
    
    // UI配置
    private(set) var items: [WikiHomeListItem] = []
    private(set) var actionInput = PublishSubject<WikiHomeAction>()
    private var updateListRelay = PublishRelay<(Bool, [WikiSpace])>()
    let tableViewShouldScrollToTopSubject = PublishSubject<Bool>()
    
    private var apiManager: WikiTreeNetworkAPI
    private let bag = DisposeBag()
    
    let userResolver: UserResolver
    
    init(userResolver: UserResolver,
         apiManager: WikiTreeNetworkAPI = WikiNetworkManager.shared) {
        self.userResolver = userResolver
        self.apiManager = apiManager
        uploadHelper = .init(mountToken: mountToken,
                             mountPoint: DriveConstants.workspaceMountPoint,
                             scene: .workspace,
                             identifier: "wiki-home-page")
        super.init()
        WikiPerformanceTracker.shared.begin(stage: .loadFromDB)
        WikiPerformanceTracker.shared.begin(stage: .loadFromNetwork)
        self.setupNetworkMonitor()
        self.setupDriveUploader()
        self.setup()
    }
    
    private func setup() {
        updateListRelay.subscribe { [weak self] (isLoadMore, wikiSpaces) in
            guard let self else { return }
            if isLoadMore {
                self.spaces.append(contentsOf: wikiSpaces)
            } else {
                self.spaces = wikiSpaces
            }
            self.updateItemTypes(driveConfig: self.driveListConfig, items: self.spaces)
        }
        .disposed(by: bag)
        
        //数据库逻辑
        userResolver.docs.wikiStorage?.starSpacesUpdated.asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] starSpaces in
                guard let self else { return }
                self.starSpaces = starSpaces
                if self.isLoadingSpaces && !starSpaces.isEmpty {
                    self.isLoadingSpaces = false
                }
                self.actionInput.onNext(.updateHeaderList(count: self.starSpaces.count, isLoading: self.isLoadingSpaces))
            })
            .disposed(by: bag)
        
        userResolver.docs.wikiStorage?.wikiSpaceListUpdate
            .subscribe(onNext: { [weak self] wikiSpaces in
                guard let self else { return }
                WikiPerformanceTracker.shared.end(stage: .loadFromDB, succeed: true, dataSize: wikiSpaces.count)
                WikiPerformanceTracker.shared.reportLoadingSucceed(dataSource: .fromDBCache)
                self.updateListRelay.accept((false, wikiSpaces))
                // 更新UI
                self.actionInput.onNext(.updatePlaceHolderView(shouldShow: wikiSpaces.count == 0))
                DocsLogger.info("wiki.home.vm.v2: wiki space list load DB succeed, count: \(wikiSpaces.count)")
            }) { error in
                WikiPerformanceTracker.shared.end(stage: .loadFromDB, succeed: false, dataSize: 0)
                WikiPerformanceTracker.shared.reportLoadingFailed(dataSource: .fromDBCache, reason: error.localizedDescription)
                DocsLogger.error("wiki.home.vm.v2: wiki space list load DB error, error: \(error.localizedDescription)")
            }
            .disposed(by: bag)

        NotificationCenter.default.rx.notification(.syncFilterStatus)
            .subscribe(onNext: { [weak self] notification in
                guard let self else { return }
                if let object = notification.object as? WikiHomePageViewModelV2, object === self {
                    return
                }
                guard let userInfo = notification.userInfo,
                      let type = userInfo["type"] as? SpaceType,
                      let classType = userInfo["classType"] as? SpaceClassType else {
                    return
                }
                self.changeFilterStatus(type: type, classType: classType)
                self.listManager.update(type: type, classType: classType)
            })
            .disposed(by: bag)
    }
    
    private func setupDriveUploader() {
        uploadHelper.setup()
        uploadHelper.uploadStateChanged.subscribe(onNext: { [weak self] in
            guard let self else { return }
            self.updateItemTypes(driveConfig: self.driveListConfig, items: self.spaces)
        }).disposed(by: bag)
        uploadHelper.fileUploadFinishSuccess.subscribe(onNext: { success in
            let status = success ? "success" : "failed"
            WikiStatistic.spaceUploadProgressClick(containerID: "null", uploadStatus: status)
        }).disposed(by: bag)
    }
    
    private func setupNetworkMonitor() {
        RxNetworkMonitor.networkStatus(observerObj: self)
            .map { $1 }
            .distinctUntilChanged()
            .skip(1)
            .subscribe(onNext: {[weak self] isReachable in
                guard let self = self else { return }
                self.reachabilityRelay.accept(isReachable)
                self.filterClickEnableRelay.accept(isReachable)
                DispatchQueue.main.async {
                    self.actionInput.onNext(.updateNetworkState(isReachable: isReachable))
                }
                if let isStorageReady = self.userResolver.docs.wikiStorage?.isStorageReady {
                    if isReachable && isStorageReady {
                        guard User.current.info?.userID != nil else {
                            DocsLogger.warning("wiki homepage loaded, but userID is nil")
                            return
                        }
                        self.refresh()
                    }
                } else {
                    DocsLogger.error("wikiStorage is not ready")
                    spaceAssertionFailure("wikiStorage is not ready")
                }
        }).disposed(by: bag)
    }

    
    // 更新列表UI
    private func updateItemTypes(driveConfig: DriveListConfig, items: [WikiSpace]) {
        var itemTypes: [WikiHomeListItem] = []
        if driveConfig.isNeedUploading {
            DocsLogger.debug("wiki.home.vm -- uploadCount: \(driveConfig.remainder) progress: \(driveConfig.progress)")
            let status: DriveStatusItem.Status = driveConfig.failed ? .failed : .uploading
            let count = self.driveListConfig.failed ? driveConfig.errorCount : driveConfig.remainder
            let driveStatusItem = DriveStatusItem(count: count, total: driveConfig.totalCount,
                                                  progress: driveConfig.progress, status: status)
            itemTypes.append(.upload(item: driveStatusItem))
            reportProgressViewIfNeed()
        }
        let listItems = items.map { WikiHomeListItem.wikiSpace(item: $0) }
        itemTypes.append(contentsOf: listItems)
        self.items = itemTypes
        //更新UI
        self.actionInput.onNext(.updateList)
    }
    
    func didAppear(isFirstTime: Bool) {
        if isFirstTime {
            userResolver.docs.wikiStorage?.loadStorageIfNeed { [weak self] in
                self?.loadDBAndRefresh()
            }
        } else {
            if page == 0 {
                // 为了防止分页后refresh数据减少，tableView上跳，只在首页的时候appear会刷新
                refreshList()
            }
            refreshHeaderList()
        }
        WikiStatistic.allSpaceView(categoryShow: filterShowEnableRelay.value)
    }
    
    private func loadDBAndRefresh() {
        let filter = WikiFilterCache.shared.get()
        let spaceType = filter.0
        let classType = filter.1
        listManager.update(type: spaceType, classType: classType)
        if !LKFeatureGating.wikiNewWorkspace {
            listManager.update(spaceType: .all)
        }
        if !UserScopeNoChangeFG.MJ.newWikiHomeFilterEnable {
            listManager.update(classType: .all)
        }
        WikiFilterCache.shared.set(spaceType: listManager.spaceType, classType: listManager.spaceClassType)
        changeFilterStatus(type: listManager.spaceType, classType: listManager.spaceClassType)
        userResolver.docs.wikiStorage?.getWikiSpaceList(spaceType: listManager.spaceType, classType: listManager.spaceClassType) { [weak self] in
            self?.refresh()
        }
    }
    
    private func changeFilterStatus(type: SpaceType, classType: SpaceClassType) {
        if type == .all, classType == .all {
            filterStateRelay.accept(.deactivated)
        } else {
            filterStateRelay.accept(.activated(type: nil, sortOption: nil, descending: false))
        }
    }
    
    // 上下两部分别表全刷新
    func refresh() {
        refreshHeaderList()
        refreshFilter()
    }
    
    func refreshFilter() {
        // 空间自定义分类FG开启拉取分类数据，否则直接刷新列表，筛选项取决于空间类型分类FG开关
        guard UserScopeNoChangeFG.MJ.newWikiHomeFilterEnable else {
            DocsLogger.info("wiki.home.v2 --- current user not support custom class")
            filterShowEnableRelay.accept(LKFeatureGating.wikiNewWorkspace)
            refreshList()
            return
        }
        // 空间列表等到筛选项请求结束后根据已选筛选请求
        apiManager.getWikiFilter()
            .subscribe(onSuccess: { [weak self] filterList in
                guard let self else { return }
                let classId = self.listManager.spaceClassType.classId
                self.classFilters = filterList.filters
                let ids = filterList.filters.map { $0.classId }
                if !ids.contains(classId) {
                    // 请求的数据不包含上次的筛选项则重置为默认筛选
                    self.listManager.update(classType: .all)
                }
                if ids.isEmpty, !LKFeatureGating.wikiNewWorkspace {
                    // 自定义筛选项为空，且分类FG关，隐藏筛选项
                    self.filterShowEnableRelay.accept(false)
                } else {
                    self.filterShowEnableRelay.accept(true)
                }
                self.changeFilterStatus(type: self.listManager.spaceType, classType: self.listManager.spaceClassType)
                self.refreshList()
                DocsLogger.info("wiki.home.vm.v2 --- refresh wiki filter list success, classed count: \(ids.count)")
            }) { [weak self] error in
                self?.filterShowEnableRelay.accept(false)
                // 筛选项列表请求失败，重置所有筛选状态, 刷新列表
                self?.changeFilterStatus(type: .all, classType: .all)
                self?.listManager.update(type: .all, classType: .all)
                self?.refreshList()
                DocsLogger.error("wiki.home.vm.v2 --- refresh wiki filter list error")
            }
            .disposed(by: bag)
    }
    
    func refreshHeaderList() {
        apiManager.getStarWikiSpaces(lastLabel: nil)
            .subscribe(onSuccess: { [weak self] spaceInfo in
                WikiStatistic.homeView(isLoadingSuccess: true, isSpacesEmpty: spaceInfo.spaces.count == 0)
                DocsLogger.info("wiki.home.vm.v2 --- refresh star space list success!")
                self?.userResolver.docs.wikiStorage?.update(spaces: spaceInfo.spaces)
                self?.isLoadingSpaces = false
                self?.starSpaces = spaceInfo.spaces
                self?.listManager.update(starHasMore: spaceInfo.hasMore, starLastLabel: spaceInfo.lastLabel)
            }) { error in
                WikiStatistic.homeView(isLoadingSuccess: false, isSpacesEmpty: true)
                DocsLogger.error("wiki.home.vm.v2 --- refresh star space list error, error: \(error)")
                //处理报错
            }.disposed(by: bag)
    }
    
    func loadMoreHeaderList() {
        guard listManager.starListHasMore, let lastLabel = listManager.starListLastLabel else {
            DocsLogger.info("wiki.home.vm.v2 --- current wiki star space list has not more")
            return
        }
        
        apiManager.getStarWikiSpaces(lastLabel: lastLabel)
            .subscribe(onSuccess: { [weak self] spaceInfo in
                guard let self else { return }
                self.starSpaces.append(contentsOf: spaceInfo.spaces)
                self.listManager.update(starHasMore: spaceInfo.hasMore, starLastLabel: spaceInfo.lastLabel)
                self.actionInput.onNext(.updateHeaderList(count: self.starSpaces.count, isLoading: false))
                DocsLogger.info("wiki.home.vm.v2 --- load more star space list success")
            }, onError: { error in
                DocsLogger.error("wiki.home.vm.v2 --- load more star space list error, error: \(error)")
            }).disposed(by: bag)
    }
    
    func refreshList() {
        getWikiSpaceList { [weak self] spaceInfo in
            guard let self else { return }
            // 刷新时为首页数据，置为0
            self.page = 0
            WikiPerformanceTracker.shared.end(stage: .loadFromNetwork, succeed: true, dataSize: spaceInfo.spaces.count)
            WikiPerformanceTracker.shared.reportLoadingSucceed(dataSource: .fromNetwork)
            
            let spaceIds: [String] = spaceInfo.spaces.map { $0.spaceID }
            self.userResolver.docs.wikiStorage?.updateWikiSpaceQuote(spaceIds: spaceIds, type: self.listManager.spaceType, classType: self.listManager.spaceClassType)
            self.userResolver.docs.wikiStorage?.updateWikiSpaceList(spaces: spaceInfo.spaces)
            self.listManager.update(hasMore: spaceInfo.hasMore, lastLabel: spaceInfo.lastLabel)
            self.updateListRelay.accept((false, spaceInfo.spaces))
            self.actionInput.onNext(.stopPullToRefresh)
            self.actionInput.onNext(.stopLoadMoreList(hasMore: spaceInfo.hasMore))
            DocsLogger.info("wiki.home.vm.v2 --- refresh space list success")
        }
    }
    
    func loadMoreList() {
        guard listManager.hasMore, let lastLabel = listManager.lastLabel else {
            // 通知UI停止loadMore动画
            DocsLogger.info("wiki.home.vm.v2 --- current wiki space list has not more")
            actionInput.onNext(.stopLoadMoreList(hasMore: false))
            return
        }
        getWikiSpaceList(lastLabel: lastLabel) { [weak self] workSpaceInfo in
            //load more成功，分页数加1
            self?.page += 1
            DocsLogger.info("wiki.home.vm.v2 -- load more space list success", extraInfo: ["count": workSpaceInfo.spaces.count])
            self?.listManager.update(hasMore: workSpaceInfo.hasMore, lastLabel: workSpaceInfo.lastLabel)
            self?.updateListRelay.accept((true, workSpaceInfo.spaces))
            self?.actionInput.onNext(.stopLoadMoreList(hasMore: workSpaceInfo.hasMore))
        }
    }
    
    private func getWikiSpaceList(lastLabel: String = "", compeletion: @escaping ((WorkSpaceInfo) -> Void)) {
        apiManager.rxGetWikiSpacesV2(lastLabel: lastLabel,
                                     size: 50,
                                     type: listManager.spaceTypeInt,
                                     classId: listManager.classIdString)
        .observeOn(MainScheduler.instance)
        .subscribe(onSuccess: {[weak self] spaceInfo in
            DocsLogger.info("wiki.home.vm.v2 --- refresh space list success", extraInfo: ["count": spaceInfo.spaces.count])
            self?.actionInput.onNext(.updatePlaceHolderView(shouldShow: spaceInfo.spaces.count == 0))
            compeletion(spaceInfo)
        }) { [weak self] error in
            DocsLogger.error("wiki.home.vm.v2 --- refresh space list failed", error: error)
            if lastLabel.isEmpty {
                WikiPerformanceTracker.shared.end(stage: .loadFromNetwork, succeed: false, dataSize: 0)
                WikiPerformanceTracker.shared.reportLoadingFailed(dataSource: .fromNetwork, reason: error.localizedDescription)
            }
            // 通知刷新失败
            self?.actionInput.onNext(.stopLoadMoreList(hasMore: nil))
            self?.actionInput.onNext(.stopPullToRefresh)
        }.disposed(by: bag)
    }
    
    func setStarWikiSpace(space: WikiSpace, sourceView: UIView, completion: @escaping ((Bool) -> Void)) {
        WikiNetworkManager.shared.setStarSpaceV2(spaceID: space.spaceID, isAdd: !space.displayIsStar)
            .materialize()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { result in
                guard let window = sourceView.window else {
                    spaceAssertionFailure("wiki.home.vm.v2 --- can not get the window of source view")
                    return
                }
                switch result {
                case let .next(isStar):
                    completion(isStar)
                    if !isStar {
                        // 取消置顶
                        UDToast.showSuccess(with: BundleI18n.SKResource.LarkCCM_Wiki_PinWorkspace_Cancelled_Toast, on: window)
                        DocsLogger.info("wiki.home.vm.v2 --- unStar space success")
                    } else {
                        // 置顶
                        UDToast.showSuccess(with: BundleI18n.SKResource.LarkCCM_Wiki_PinWorkspace_Pinned_Toast, on: window)
                        DocsLogger.info("wiki.home.vm.v2 --- star space success ")
                    }
                    NotificationCenter.default.post(name: .Docs.clipWikiSpaceListUpdate, object: nil)
                case let .error(error):
                        if space.displayIsStar {
                            // 取消收藏
                            UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_Wiki_UnpinWorkspace_Failed_Toast, on: window)
                            DocsLogger.info("wiki.home.vm.v2 --- unStar space error: \(error)")
                        } else {
                            // 收藏
                            UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_Wiki_PinWorkspace_PinFailed_Toast, on: window)
                            DocsLogger.info("wiki.home.vm.v2 --- star space error: \(error)")
                        }
                default:
                    return
                }
            }).disposed(by: bag)
    }
    
    private func reportProgressViewIfNeed() {
        // 出现进度条上报
        if !self.items.contains(where: { item in
            if case .upload = item {
                return true
            } else {
                return false
            }
        }) {
            WikiStatistic.spaceUploadProgressView(containerID: "null")
        }
    }
    
    func didClickCreate(sourceView: UIView) {
        actionInput.onNext(.jumpToCreateWikiPicker(sourceView: sourceView))
    }
    
    // 兼容旧的查看全部空间逻辑
    func didClickAllSpaces() {}
}

// MARK: UITableViewDelegate
extension WikiHomePageViewModelV2 {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let index = indexPath.item
        guard index >= 0, index < items.count else {
            return 68
        }
        let itemType = items[index]
        switch itemType {
        case .wikiSpace:
            return 68
        case .upload:
            return 60
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Layout.heightOfHeaderSection
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = WikiHomePageAllSpaceHeaderView()
        view.setupFilterView(stateRelay: filterStateRelay,
                             clickEnable: filterClickEnableRelay.asDriver(),
                             showEnable: filterShowEnableRelay.asDriver())
        view.clickHandler = { [weak self, weak view] in
            guard let view else { return }
            self?.didClickFilter(sourceView: view.filterView)
        }
        WikiStatistic.clickAllSpaceView(clickType: .categoryClick)
        return view
    }

    func didClickFilter(sourceView: UIView) {
        let classes: [[String: String]] = classFilters.map { filter in
            ["spaceClassId": filter.classId, "spaceClassName": filter.className]
        }
        let type = listManager.spaceType
        let classId = listManager.spaceClassType.classId
        let vc = WikiFilterPanelViewController(type: type.rawValue, classId: classId, classFilters: classes, isIpad: ui?.isiPadRegularSize)
        vc.clickHandler = { [weak self] (type, classId) in
            guard let self else { return }
            let spaceType = SpaceType(rawValue: type) ?? .all
            var spaceClassType: SpaceClassType = .all
            if let classId {
                spaceClassType = .other(classId)
            }
            self.changeFilterStatus(type: spaceType, classType: spaceClassType)
            self.listManager.update(type: spaceType, classType: spaceClassType)
            WikiFilterCache.shared.set(spaceType: spaceType, classType: spaceClassType)
            self.userResolver.docs.wikiStorage?.getWikiSpaceList(spaceType: spaceType, classType: spaceClassType) {
                self.refreshList()
                // 其他端添加或删除过置顶知识库，切换筛选本地数据不准确，因此需要刷新一下最新数据
                self.refreshHeaderList()
            }
            WikiStatistic.clickAllSpaceView(clickType: .categoryClick, categoryId: classId)
            self.syncFilterStatus(type: spaceType, classType: spaceClassType)
        }
        vc.setupPopover(sourceView: sourceView, direction: .any)
        actionInput.onNext(.present(vc))
    }

    private func syncFilterStatus(type: SpaceType, classType: SpaceClassType) {
        NotificationCenter.default.post(name: .syncFilterStatus, object: self, userInfo: [
            "type": type,
            "classType": classType
        ])
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let index = indexPath.item
        guard index >= 0, index < items.count else {
            DocsLogger.error("[wiki] invalid recent entity index", extraInfo: ["selectIndex": index,
                                                                               "recentCount": items.count])
            return
        }
        let itemType = items[index]
        switch itemType {
        case let .wikiSpace(item):
            actionInput.onNext(.jumpToWikiTree(space: item))
            WikiStatistic.clickAllSpaceView(clickType: .workspace)
        case .upload:
            actionInput.onNext(.jumpToUploadList(mountToken: "all_files_token"))
        }
    }
    // 侧滑置顶
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let index = indexPath.row
        guard index < spaces.count else {
            spaceAssertionFailure("wiki.home.page.v2 --- row index out of bound when creatre swipe actions")
            return nil
        }
        var space = spaces[index]
        let action = UIContextualAction(style: .normal, title: nil) { (_, sourceView, _) in
            guard self.isReachable else { return }
            let cell = tableView.cellForRow(at: indexPath) ?? sourceView
            self.setStarWikiSpace(space: space, sourceView: cell) { [weak self] isStar in
                guard let self else { return }
                self.spaces[index].isStar = isStar
                tableView.setEditing(false, animated: true)
                // 收藏后立刻refresh 后端接口返回的数据可能未同步，因此手动添加
                if isStar {
                    self.starSpaces.insert(self.spaces[index], at: 0)
                    self.actionInput.onNext(.updateHeaderList(count: self.starSpaces.count, isLoading: self.isLoadingSpaces))
                    // 收藏成功后，滑动回第一个cell
                    self.actionInput.onNext(.scrollHeaderView(index: IndexPath(row: 0, section: 0)))
                } else {
                    self.refreshHeaderList()
                }
                let tempSpace = self.spaces[index]
                if let wikiSpaceCell = cell as? WikiWorkSpaceCell {
                    wikiSpaceCell.update(with: tempSpace)
                }
            }
        }
        action.image = space.displayIsStar ? UDIcon.setTopCancelOutlined.ud.withTintColor(UDColor.primaryOnPrimaryFill) :
                                             UDIcon.setTopOutlined.ud.withTintColor(UDColor.primaryOnPrimaryFill)
        if isReachable {
            action.backgroundColor = UDColor.colorfulBlue
        } else {
            action.backgroundColor = UDColor.B300
        }
        let configuration = UISwipeActionsConfiguration(actions: [action])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}


// MARK: UITableviewDataSource
extension WikiHomePageViewModelV2 {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < items.count else {
            DocsLogger.error("wiki.home.recent --- index out of range", extraInfo: ["count": items.count, "index": indexPath.row])
            return UITableViewCell()
        }
        let itemType = items[indexPath.row]
        switch itemType {
        case let .wikiSpace(item):
            let cell = tableView.dequeueReusableCell(withIdentifier: WikiHomePageCellIdentifier.wikiSpaceListIdentifier.rawValue, for: indexPath)
            guard let wikiSpaceCell = cell as? WikiWorkSpaceCell else {
                DocsLogger.error("wiki.home.list.v2 --- failed to convert cell to subclass WikiWorkSpaceCell")
                return cell
            }
            wikiSpaceCell.update(with: item)
            item.isTreeContentCached.drive(onNext: { [weak self, weak wikiSpaceCell] isCache in
                guard let self = self else { return }
                let isEnable: Bool
                if !self.isReachable {
                    isEnable = isCache
                } else {
                    isEnable = true
                }
                wikiSpaceCell?.contentEnable = isEnable
                wikiSpaceCell?.isUserInteractionEnabled = isEnable
            })
            return wikiSpaceCell
        case let .upload(item):
            let cell = tableView.dequeueReusableCell(withIdentifier: WikiHomePageCellIdentifier.uploadCellReuseIdentifier.rawValue, for: indexPath)
            guard let uploadCell = cell as? WikiUploadCell else {
                DocsLogger.error("wiki.home.recent --- failed to convert cell to WikiUploadCell")
                return cell
            }
            DocsLogger.info("wiki.home.recent -- drive upload progress: \(item.progress)/\(item.count), status: \(item.status)")
            uploadCell.update(item)
            return uploadCell
        }
    }
}

// MARK: UICollectionViewDelegate
extension WikiHomePageViewModelV2 {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let index = indexPath.item
        guard index >= 0, index < starSpaces.count else {
            DocsLogger.error("[wiki] invalid space index",
                             extraInfo: ["selectIndex": index, "spaceCount": spaces.count])
            return
        }
        let space = starSpaces[index]
        self.actionInput.onNext(.jumpToWikiTree(space: space))
        WikiStatistic.homePageClickSpace(count: starSpaces.count, index: index)
        WikiStatistic.clickHomeView(click: .workspace, target: DocsTracker.EventType.wikiTreeView.rawValue)
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let collectionView = scrollView as? UICollectionView,
            let layout = collectionView.collectionViewLayout as? WikiHorizontalPagingLayout else {
                return
        }
        let offset = targetContentOffset.pointee
        let newOffset = layout.snapTo(currentOffset: offset, velocity: velocity)
        targetContentOffset.pointee = newOffset
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.item == self.starSpaces.count - 1 else {
            return
        }
        self.loadMoreHeaderList()
    }
}

// MARK: UICollectionViewDataSource
extension WikiHomePageViewModelV2 {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isLoadingSpaces {
            return WikiSpaceCoverConfig.placeHolderCount
        }
        return starSpaces.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // 如果正在展示 loading 状态，直接返回占位的 cell
        if isLoadingSpaces {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WikiHomePageCellIdentifier.spacePlaceHolderCellReuseIdentifier.rawValue,
                                                          for: indexPath)
            guard let placeHolderCell = cell as? WikiSpacePlaceHolderCollectionCell else {
                DocsLogger.error("wiki.home.space --- failed to convert cell to subclass WikiSpacePlaceHolderCollectionCell")
                return cell
            }
            placeHolderCell.shouldShowShadow = WikiSpaceCoverConfig.placeHolderShouldShowShadow
            return placeHolderCell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WikiHomePageCellIdentifier.spaceCellReuseIdentifier.rawValue, for: indexPath)

        guard indexPath.item < starSpaces.count else {
            spaceAssertionFailure("wiki.home.space --- star space list data array index out of range")
            return cell
        }
        guard let spaceCell = cell as? WikiHomePageSpaceViewCell else {
            DocsLogger.error("wiki.home.space --- failed to convert cell to subclass WikiSpaceCellRepresentable")
            return cell
        }

        let space = starSpaces[indexPath.item]
        spaceCell.updateUI(item: space)
        space.isTreeContentCached.drive(onNext: {[weak self, weak spaceCell] isCache in
            guard let self = self else { return }
            let isEnable: Bool
            if !self.isReachable {
                isEnable = isCache
            } else {
                isEnable = true
            }
            spaceCell?.set(enable: isEnable)
            spaceCell?.isUserInteractionEnabled = isEnable
        }).disposed(by: spaceCell.reuseBag)
        return spaceCell
    }
}

extension WikiHomePageViewModelV2: UIScrollViewDelegate {
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        tableViewShouldScrollToTopSubject.onNext(true)
        return true
    }
}
