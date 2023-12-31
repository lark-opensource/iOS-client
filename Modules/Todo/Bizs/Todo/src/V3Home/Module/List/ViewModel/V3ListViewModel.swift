//
//  V3ListViewModel.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/25.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import LarkAccountInterface

final class V3ListViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    // 视图状态（loading, failed）
    let rxViewState = BehaviorRelay<ListViewState>(value: .idle)
    // 提醒
    let rxNotice = BehaviorRelay<Rust.ListLaunchScreen?>(value: nil)
    // 刷新
    enum ListUpdateType {
        case reload(V3ListViewData)
        // 重置offset
        case resetOffset
        // 显示toast
        case showToast(String)
    }
    var onListUpdate: ((ListUpdateType) -> Void)?

    let context: V3HomeModuleContext
    let disposeBag = DisposeBag()
    // 数据队列
    var queue = V3ListQueue()
    // 记录被选中的 guid，确保刷新的时候不会失焦
    var selectedGuid: String?
    // 本地新创建的todo，用于高亮显示
    var newCreatedGuid: String?
    // 定时器：用于刷新截止时间的状态
    var dueTimetimer: Timer?
    let timerInterval: TimeInterval = 180
    lazy var lastTimeContext: TimeContext = curTimeContext
    // 记录展开收起: viewGuid: [SectionId: isFold]
    lazy var sectionFoldState = [String: [String: Bool]]()
    // 分组更多操作
    enum SectionMoreAction {
        case rename
        case forwardCreate
        case backwardCreate
        case reorder
    }

    struct ListMetaDataScene {
        // 我负责的这些是持久化数据
        var persist: ListMetaData?
        // 任务清单是临时性
        var temporary: ListMetaData?
    }
    // 列表元数据场景：持久化：我负责的等；临时性：任务清单场
    lazy var listScene: ListMetaDataScene = .init() {
        didSet {
            let tasks = listScene.persist?.tasks
            let handler = { [weak self] (req: [Rust.TaskContainer: Rust.TaskView]) -> [String: String]? in
                guard let self = self else { return nil }
                var map = [String: String]()
                req.forEach { (container, view) in
                    if let count = self.filterInProgressCount(container, from: view.viewFilters, in: tasks) {
                        map[container.key] = count
                    } else {
                        map[container.key] = ""
                    }
                }
                V3Home.logger.info("in progress count is :\(map)")
                return map
            }
            context.bus.post(.calculateInProgressCount(handler))
        }
    }

    // 心跳 timer
    var heartbeatTimer: Timer?

    @ScopedInjectedLazy var operateApi: TodoOperateApi?
    @ScopedInjectedLazy var updateNoti: TodoUpdateNoti?
    @ScopedInjectedLazy var settingService: SettingService?
    @ScopedInjectedLazy var fetchApi: TodoFetchApi?
    @ScopedInjectedLazy var listApi: TaskListApi?
    @ScopedInjectedLazy var listNoti: TaskListNoti?
    @ScopedInjectedLazy var commentApi: TodoCommentApi?
    @ScopedInjectedLazy var timeService: TimeService?
    @ScopedInjectedLazy var completeService: CompleteService?
    @ScopedInjectedLazy var richContentService: RichContentService?

    init(resolver: UserResolver, context: V3HomeModuleContext) {
        self.userResolver = resolver
        self.context = context
        setState()
        bindBusEvent()
        observeViewData()
    }

    deinit {
        stopDueTimeTimer()
        stopHeartBeatTimer()
    }

    private var isSetuped = true
    private func setState() {
        context.store.rxValue(forKeyPath: \.view)
            .distinctUntilChanged { $0 == $1 }
            .subscribe(onNext: { [weak self] view in
                guard let self = self, let view = view,
                      let viewGuid = view.metaData?.guid, !viewGuid.isEmpty
                else { return }
                if self.isSetuped {
                    self.isSetuped = false
                    self.listenUpdateNoti()
                    self.listenTimeNoti()
                    self.listenSetting()
                }
                self.willFetchListData()
                self.fetchListData()
            })
            .disposed(by: disposeBag)
        context.store.rxValue(forKeyPath: \.sideBarItem)
            .observeOn(MainScheduler.asyncInstance)
            .distinctUntilChanged { $0?.container?.guid == $1?.container?.guid }
            .subscribe(onNext: { [weak self] item in
                guard let self = self, let item = item, item.container != nil else { return }
                self.containerTrack()
                self.showNoticeIfNeeded()
                self.resetContainer()
            })
            .disposed(by: disposeBag)
    }

    private func observeViewData() {
        queue.rxUIData
            .subscribe(onNext: { [weak self] res in
                guard let self = self, let data = res else { return }
                let viewData = self.updateSelctedIndexPath(data)
                self.onListUpdate?(.reload(viewData))
                self.rxViewState.accept(viewData.isEmpty ? .empty : .data)
            })
            .disposed(by: disposeBag)
    }
}
