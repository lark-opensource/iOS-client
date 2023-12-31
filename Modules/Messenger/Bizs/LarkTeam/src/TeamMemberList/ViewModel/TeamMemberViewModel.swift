//
//  TeamMemberViewModel.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/7/20.
//

import UIKit
import Foundation
import RustPB
import RxSwift
import LarkTag
import RxCocoa
import LarkModel
import EENavigator
import LarkContainer
import LKCommonsLogging
import LarkSDKInterface
import UniverseDesignToast
import UniverseDesignDialog
import LarkMessengerInterface
import LarkListItem
import ThreadSafeDataStructure
import LarkGuideUI
import LarkGuide

@frozen
enum TeamMemberViewStatus {
    case loading
    case error(Error)
    case viewStatus(TeamMemberBaseTableView.Status)
}

protocol TeamMemberVMDelegate: AnyObject {
    func getCellByIndexPath(_ indexPath: IndexPath) -> TeamMemberCellInterface?
}

@frozen
enum TeamMemberDisplayMode {
    case display
    case multiselect
}

// 团队成员页viewModel
final class TeamMemberViewModel {
    static let logger = Logger.log(TeamMemberViewModel.self, category: "LarkTeam")
    let schedulerType: SchedulerType
    let disposeBag = DisposeBag()

    // 列表数据相关
    var nextOffset: Int64?
    var hasMore: Bool = false
    var indexMap: [String: Int] = [:]
    var canLeftSlide = true
    let currentUserId: String

    // 搜索相关
    var searchNextOffset: String?
    var searchHasMore: Bool = false
    var searchIndexMap: [String: Int] = [:]
    var searchID: String = ""
    var isInSearch = false
    let searchPlaceHolder: String = BundleI18n.LarkTeam.Project_T_SearchMemberBox
    var filterKey: String? {
        didSet {
            searchDatas = []
            searchNextOffset = nil
            searchHasMore = false
            searchIndexMap = [:]
            searchID = UUID().uuidString
        }
    }

    private var _datas: SafeAtomic<[TeamMemberItem]> = [] + .readWriteLock
    private var _searchDatas: SafeAtomic<[TeamMemberItem]> = [] + .readWriteLock
    var datas: [TeamMemberItem] {
        get { _datas.value }
        set { _datas.value = newValue }
    }

    var searchDatas: [TeamMemberItem] {
        get { _searchDatas.value }
        set { _searchDatas.value = newValue }
    }

    let statusBehavior = BehaviorSubject<TeamMemberViewStatus>(value: .loading)
    var statusVar: Driver<TeamMemberViewStatus> {
        return statusBehavior.asDriver(onErrorRecover: { .just(.error($0)) })
    }

    var isFirstDataLoaded: Bool = false
    // 页面底部是否显示安全策略view组件
    var shouldShowTipView: Bool = false

    // 通信
    weak var delegate: TeamMemberVMDelegate?
    weak var targetVC: UIViewController?
    // ------
    let teamId: Int64
    var team: Basic_V1_Team? {
        didSet {
            self.teamRelay.accept(team)
        }
    }
    var displayMode: TeamMemberMode
    var navItemType: TeamMemberNavItemType
    let scene: TeamMemberDataScene
    let selectdMemberCallback: TeamSelectdMemberCallback?
    private let teamRelay: BehaviorRelay<Basic_V1_Team?> = BehaviorRelay(value: nil)
    var teamOb: Observable<Basic_V1_Team?> {
        return teamRelay.asObservable()
    }

    let unableCancelSelectedIdsRelay: BehaviorRelay<[String]> = BehaviorRelay(value: [])
    let teamAPI: TeamAPI
    let isTransferTeam: Bool
    let pushTeamMembers: Observable<PushTeamMembers>
    let pushTeams: Observable<PushTeams>
    let pushItems: Observable<PushItems>
    let guideService: NewGuideService
    let navigator: EENavigator.Navigatable
    let userResolver: LarkContainer.UserResolver

    init(teamId: Int64,
         currentUserId: String,
         displayMode: TeamMemberMode,
         navItemType: TeamMemberNavItemType,
         teamAPI: TeamAPI,
         isTransferTeam: Bool,
         pushTeamMembers: Observable<PushTeamMembers>,
         pushTeams: Observable<PushTeams>,
         pushItems: Observable<PushItems>,
         scene: TeamMemberDataScene,
         guideService: NewGuideService,
         userResolver: UserResolver,
         selectdMemberCallback: TeamSelectdMemberCallback?) {
        self.teamId = teamId
        self.displayMode = displayMode
        self.navItemType = navItemType
        self.currentUserId = currentUserId
        self.teamAPI = teamAPI
        self.isTransferTeam = isTransferTeam
        self.pushTeamMembers = pushTeamMembers
        self.pushTeams = pushTeams
        self.pushItems = pushItems
        self.scene = scene
        self.guideService = guideService
        self.selectdMemberCallback = selectdMemberCallback
        self.userResolver = userResolver
        self.navigator = userResolver.navigator
        let queue = DispatchQueue.global()
        self.schedulerType = SerialDispatchQueueScheduler(queue: queue, internalSerialQueueName: queue.label)
        self.searchDatas = []
        bind(teamId: teamId)
    }

    func removeChatterBySelectedItems(_ selectedItems: [TeamMemberItem]) {
        removeMembers(selectedItems, alertContent: BundleI18n.LarkTeam.Project_T_RemoveMember_Subtitle(selectedItems.count))
    }
}

// MARK: - actions组装
extension TeamMemberViewModel {
    func structureActionItems(tapTask: @escaping () -> Void,
                                       indexPath: IndexPath) -> [UIContextualAction]? {
        return getCellActionsItems(tapTask: tapTask, indexPath: indexPath)
    }
}

// MARK: - DataSource
extension TeamMemberViewModel {
    // load数据
    func loadData(isFirst: Bool = false) -> Observable<[TeamMemberItem]> {
        return getTeamMembers(isFirst: isFirst)
    }

    // 是否还有更多数据
    func hasMoreData() -> Bool {
        if isInSearch {
            return searchHasMore
        } else {
            return hasMore
        }
    }

    // 首次加载数据，需要加载默认选中的数据，所以单独拉出来处理
    func loadFirstScreenData() {
        loadData(isFirst: true)
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] datas in
                guard let self = self else { return }
                self.statusBehavior.onNext(.viewStatus(datas.isEmpty ? .empty : .display))
            }, onError: { [weak self] (error) in
                self?.statusBehavior.onNext(.error(error))
            }, onDisposed: { [weak self] in
                self?.isFirstDataLoaded = true
            }).disposed(by: disposeBag)
    }

    // 上拉加载更多
    func loadMoreData() {
        let response: Observable<[TeamMemberItem]>
        if isInSearch {
            response = getSearchTeamMembers(id: self.searchID)
        } else {
            guard isFirstDataLoaded else { return }
            response = loadData()
        }
        response.observeOn(schedulerType)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.statusBehavior.onNext(.viewStatus(.display))
            }, onError: { [weak self] _ in
                self?.statusBehavior.onNext(.viewStatus(.display))
            }).disposed(by: disposeBag)
    }
}
