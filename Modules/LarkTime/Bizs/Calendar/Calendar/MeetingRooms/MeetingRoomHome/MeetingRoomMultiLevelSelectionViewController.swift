//
//  MeetingRoomMultiLevelSelectionViewController.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/8/19.
//

import UIKit
import RxSwift
import RxCocoa
import LarkContainer
import UniverseDesignToast
import EENavigator
import CalendarFoundation
import LarkAccountInterface
import LKCommonsLogging
import LarkUIKit
import EventKit
import LarkTimeFormatUtils

final class MLLevel {
    // 每次进入层级选择页面，会重置为会议室视图的 selectedLevelIds
    static var selectedLevelIds: [String] = []
    static var levelPaths: [String: [String]] = ["0": ["0"]]
    struct MeetingRoomWithSelection {
        let resource: Rust.MeetingRoom
        var selected: Bool
        var eventDuration: Int64
        var eventConditions: (approveDisabled: Bool, formDisabled: Bool)
        var subscribeStatus: SubscribeStatus

        var selectStatus: Status {
            if resource.status == .busy || predicateConditions() {
                return .disabled
            } else if selected {
                return .selected
            } else {
                return .nonSelected
            }
        }

        // 是否需要根据条件 disable
        private func predicateConditions() -> Bool {
            let formDisabled = resource.hasForm && eventConditions.formDisabled
            let needApprove = resource.needsApproval || resource.shouldTriggerApproval(duration: eventDuration)
            let approveDisabled = needApprove && eventConditions.approveDisabled
            return formDisabled || approveDisabled
        }
    }

    enum Status {
        case selected
        case nonSelected
        case halfSelected
        case disabled
        case hidden

        func convertToSelectType() -> SelectType {
            switch self {
            case .selected:
                return .selected
            case .nonSelected:
                return .nonSelected
            case .halfSelected:
                return .halfSelected
            case .disabled:
                return .disabled
            case .hidden:
                return .disabled
            }
        }
    }

    static let RequestRootLevelInfo = (name: BundleI18n.Calendar.Calendar_Edit_AllRooms, id: "0")

    static private func joinStatusList(list: [Status]) -> Status {
        var list = list.filter { $0 != .hidden }
        guard !list.isEmpty else { return .hidden }
        list = list.filter { $0 != .disabled }
        guard !list.isEmpty else { return .disabled }

        if list.allEqualTo(.nonSelected) {
            return .nonSelected
        } else if list.allEqualTo(.selected) {
            return .selected
        } else {
            return .halfSelected
        }
    }

    struct MLLevelConfig {
        var eventDuration: Int64 = 0
        var eventConditions: (approveDisabled: Bool, formDisabled: Bool) = (false, false)
        var showLevelsOnly: Bool = false
    }

    init(name: String, id: String, config: MLLevelConfig = MLLevelConfig()) {
        self.name = name
        self.id = id
        self.config = config
    }

    var name: String
    let id: String
    let config: MLLevelConfig
    /// 是否置顶
    var isTop: Bool = false
    /// SDK 给到的是否隐藏 level 判断
    var noUsableResource: Bool = false

    var hasChild: Bool = false // 是否有子层级
    var subLevels: [MLLevel] = []
    weak var superLevel: MLLevel?

    var allMeetingRooms: [MeetingRoomWithSelection] = []
    var filteredMeetingRooms: [MeetingRoomWithSelection] = []
    private var selectedMeetingRooms: [Rust.MeetingRoom] {
        return filteredMeetingRooms.filter({ $0.selected }).map(\.resource)
    }
    var levelAdjustTimeInfo: Rust.LevelAdjustTimeInfo?

    func deepCopy() -> MLLevel {
        let newLevel = MLLevel(name: self.name, id: self.id, config: self.config)
        newLevel.subLevels = subLevels.map {
            let newSub = $0.deepCopy()
            newSub.superLevel = newLevel
            return newSub
        }
        newLevel.hasChild = hasChild
        newLevel.allMeetingRooms = allMeetingRooms
        newLevel.filteredMeetingRooms = filteredMeetingRooms
        return newLevel
    }

    func toggleMeetingRoomSelection(meetingRoom: Rust.MeetingRoom) {
        guard let index = filteredMeetingRooms.firstIndex(where: { $0.resource.id == meetingRoom.id }) else {
            assertionFailure("确认选中的会议室是否在当前层级")
            return
        }

        filteredMeetingRooms[index].selected.toggle()
    }

    var status: Status {
        get {
            if config.showLevelsOnly {
                return statusWithLevelsOnly
            } else {
                return statusWithShowAll
            }
        }
        set {
            if config.showLevelsOnly {
                statusWithLevelsOnly = newValue
            } else {
                statusWithShowAll = newValue
            }
        }
    }

    private var statusWithShowAll: Status {
        // 会议室搜索页面的层级状态变化
        get {
            let meetingRoomJoinedStatus = Self.joinStatusList(list: filteredMeetingRooms.map(\.selectStatus))
            let subLevelJoinedStatus = Self.joinStatusList(list: subLevels.map(\.status))

            return Self.joinStatusList(list: [meetingRoomJoinedStatus, subLevelJoinedStatus])
        }
        set {
            subLevels.forEach { $0.status = newValue }

            switch newValue {
            case .selected:
                filteredMeetingRooms = filteredMeetingRooms.map {
                    MeetingRoomWithSelection(
                        // showAll 的情况下会忽略不可用，此时为了展示 disable 态会在过滤时保留，但全选的时候需要将 disable 重新摘出来
                        resource: $0.resource, selected: $0.selectStatus != .disabled,
                        eventDuration: $0.eventDuration, eventConditions: $0.eventConditions,
                        subscribeStatus: $0.subscribeStatus
                    )
                }
            case .nonSelected:
                filteredMeetingRooms = filteredMeetingRooms.map {
                    MeetingRoomWithSelection(
                        resource: $0.resource, selected: false,
                        eventDuration: $0.eventDuration, eventConditions: $0.eventConditions,
                        subscribeStatus: $0.subscribeStatus
                    )
                }
            default:
                assertionFailure("invalid status")
            }
        }
    }

    private var statusWithLevelsOnly: Status {
        // 层级选择页面的层级状态变化
        get {
            guard let selfLevelPath = MLLevel.levelPaths[self.id] else {
                assertionFailure()
                return .hidden
            }

            if selfLevelPath.contains(where: MLLevel.selectedLevelIds.contains(_:)) {
                /// 全选判断逻辑：selectedLevelIds 中存在自己的一个父节点
                return .selected
            } else {
                /// 半选判断逻辑：有一个 selectedLevelIds 的 levelPath 中存在自己
                for id in MLLevel.selectedLevelIds {
                    if let levelPath = MLLevel.levelPaths[id],
                       levelPath.contains(where: { $0 == self.id }) {
                        return .halfSelected
                    }
                }
            }
            /// 否则为未选状态
            return .nonSelected
        }
        set {
            switch newValue {
            case .selected:
                /// 全选逻辑：
                /// 1. 从 selectedLevelIds 中移除自己的所有子层级后，将自己加入到 selectedLevelIds中
                MLLevel.selectedLevelIds.removeAll(where: { (MLLevel.levelPaths[$0] ?? []).contains(self.id) })
                MLLevel.selectedLevelIds.append(self.id)
//                /// 2. 判断是否需要全选状态向前移动：如果兄弟节点都处于全选状态，则父节点应变为全选状态（此逻辑已删除！！代码保留）
//                if let siblingLevels = superLevel?.subLevels.map({ $0.id }),
//                   Set(siblingLevels).isSubset(of: Set(MLLevel.selectedLevelIds)),
//                   self.id != MLLevel.RequestRootLevelInfo.id {
//                       /// 递归的改变父节点状态
//                       superLevel?.status = newValue
//                }

            case .nonSelected:
                /// 取消选择逻辑：
                if MLLevel.selectedLevelIds.contains(self.id) {
                    /// 若自己在 selectedLevelIds 中，说明自己是最浅全选节点，则将自己从中移除
                    MLLevel.selectedLevelIds.removeAll(where: { self.id == $0 })
                } else {
                    /// 若自己不在 selectedLevelIds 中，分两种情况：
                    /// 1. 自己的某个父节点是最浅全选节点，则需要递归的从父层级开始逐级删除自己，并添加对应的兄弟节点
                    /// 2. 自己的一些子节点是最浅全选节点，则需要删除 selectedLevelIds 中的这些子节点
                    if let selfLevelPath = MLLevel.levelPaths[self.id],
                       selfLevelPath.contains(where: MLLevel.selectedLevelIds.contains(_:)) {
                        superLevel?.status = newValue
                        if let siblingLevels = superLevel?.subLevels.filter({ $0.id != self.id }) {
                            MLLevel.selectedLevelIds.append(contentsOf: siblingLevels.map({ $0.id }))
                        }
                    } else {
                        MLLevel.selectedLevelIds.removeAll(where: { (MLLevel.levelPaths[$0] ?? []).contains(self.id) })
                    }
                }
            default:
                assertionFailure("invalid status")
            }
        }
    }

    func recursiveUpdateFilter(capacity: Int, equipments: [String], showAvailableOnly: Bool) {
        let predicate: (MeetingRoomWithSelection) -> Bool = { meetingRoom in
            let capacitySatisfy = meetingRoom.resource.capacity >= capacity

            let equipmentSatisfy = equipments.isEmpty || equipments.allSatisfy { meetingRoom.resource.equipments.map(\.id).contains($0) }

            let canUse = meetingRoom.selectStatus.convertToSelectType() != .disabled
            let showAll = !showAvailableOnly
            let availableSatisfy = showAll || canUse

            return capacitySatisfy && equipmentSatisfy && availableSatisfy
        }
        filteredMeetingRooms = allMeetingRooms.filter(predicate)

        subLevels.forEach {
            $0.recursiveUpdateFilter(capacity: capacity, equipments: equipments, showAvailableOnly: showAvailableOnly)
        }
    }

    var recursiveGetAllSelectedMeetingRooms: [Rust.MeetingRoom] {
        selectedMeetingRooms + subLevels.flatMap(\.recursiveGetAllSelectedMeetingRooms)
    }

    func populateWith(SDKInfoDict: [String: Rust.MeetingRoomLevelInfo], userCalendarIDs: [String]?) {
        var leavesToProcess = [self]
        while !leavesToProcess.isEmpty {
            let leaf = leavesToProcess.removeFirst()

            if let info = SDKInfoDict[leaf.id] {
                let meetingRoomsWithWeight = info.sonResources

                leaf.allMeetingRooms = meetingRoomsWithWeight.map {
                    MLLevel.MeetingRoomWithSelection(
                        resource: $0,
                        selected: false,
                        eventDuration: leaf.config.eventDuration,
                        eventConditions: leaf.config.eventConditions,
                        subscribeStatus: (userCalendarIDs ?? []).contains($0.calendarID) ? .subscribed : .noSubscribe)
                }
                leaf.filteredMeetingRooms = leaf.allMeetingRooms

                let subLevels = info.sonLevelInfos.map { content -> MLLevel in
                    let level = MLLevel(name: content.name, id: content.levelID, config: leaf.config)
                    level.superLevel = leaf
                    level.hasChild = content.hasChild_p
                    level.isTop = content.isTop
                    level.noUsableResource = content.noUsableResource
                    // 缓存新增子节点的 levelPath
                    if var levelPath = MLLevel.levelPaths[leaf.id],
                       MLLevel.levelPaths[content.levelID] == nil {
                        levelPath.append(content.levelID)
                        MLLevel.levelPaths[content.levelID] = levelPath
                    }
                    return level
                }
                leaf.subLevels = subLevels
                leavesToProcess.append(contentsOf: subLevels)
            }
        }
    }
    // 仅用于 levelOnly && subLevel.isEmpty 隐藏「>」
    var accessaryHidden = false
    /// 仅用于 level 是否常用的判断
    var isHabitualUsed = false
    /// 自动跳转路径，用于填充单选时的子节点
    var autoDisplayPath: [Rust.MeetingRoomLevelContent] = [] {
        didSet {
            guard !autoDisplayPath.isEmpty else { return }
            needUpdate = true
            var tempPath = autoDisplayPath
            let firstNode = tempPath.removeFirst()
            if firstNode.levelID == id {
                var current = self
                while !tempPath.isEmpty {
                    let subContent = tempPath.removeFirst()
                    if let level = current.subLevels.first(where: { $0.id == subContent.levelID }) {
                        current = level
                    } else {
                        let level = MLLevel(name: subContent.name, id: subContent.levelID)
                        level.superLevel = current
                        level.hasChild = subContent.hasChild_p
                        level.isTop = subContent.isTop
                        level.noUsableResource = subContent.noUsableResource
                        level.needUpdate = true
                        current.subLevels.append(level)

                        current = level
                    }
                }
            }
        }
    }
    /// 层级是否需要更新
    var needUpdate = false
}

extension MLLevel: Equatable {
    static func == (lhs: MLLevel, rhs: MLLevel) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name
    }
}

extension MLLevel {
    var rootLevel: MLLevel {
        var root = self
        while let superLevel = root.superLevel {
            root = superLevel
        }
        return root
    }

}

///多页面复用的 VC：通过 config 进行场景区分
/// - 订阅会议室页面
/// - 添加会议室页面
/// - 会议室视图页 > 层级选择页面
final class MeetingRoomMultiLevelSelectionViewController: UIViewController, UIGestureRecognizerDelegate, UserResolverWrapper {

    let logger = Logger.log(MeetingRoomMultiLevelSelectionViewController.self, category: "Calendar.MeetingRoom")

    fileprivate lazy var levelIndicatorView: LevelIndicatorView = {
        let indicator = LevelIndicatorView()
        indicator.alwaysShowIndicator = config.alwaysShowLevelIndicator
        return indicator
    }()

    private lazy var containerView = UIView()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 60
        tableView.contentInset.bottom = 78
        tableView.backgroundColor = .ud.bgBody
        tableView.register(LevelTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.register(SubscribeMeetingRoomCell.self, forCellReuseIdentifier: "subscribe")
        tableView.register(SectionHeaderCell.self, forCellReuseIdentifier: "SectionHeaderCell")
        return tableView
    }()

    private lazy var loadingView: LoadingPlaceholderView = {
        let loading = LoadingPlaceholderView()
        loading.label.text = BundleI18n.Calendar.Calendar_Common_LoadingCommon
        loading.label.font = UIFont.cd.regularFont(ofSize: 16)
        return loading
    }()

    private lazy var emptyRoomsLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.cd.font(ofSize: 16)
        label.text = BundleI18n.Calendar.Calendar_Detail_NoAvailableRoomsFound
        return label
    }()
    private var tableViewContainer = UIView()
    private var autoJustTimeLabel = MeetingRoomAutoJustTimeLabel(horizontalPadding: 16)

    private lazy var selectAllView: SelectAllView = {
        SelectAllView()
    }()

    private let config: Config

    let userResolver: UserResolver
    @ScopedInjectedLazy private var rustAPI: CalendarRustAPI?
    @ScopedInjectedLazy var calendarManager: CalendarManager?

    private lazy var userCalendarIDs: [String] = {
        calendarManager?.allCalendars.map { $0.serverId } ?? []
    }()
    private let bag = DisposeBag()

    // 当前选中的层级
    fileprivate let selectedLevelIdsRelay = PublishRelay<[String]>()

    // 当前选中的所有会议室
    fileprivate let selectedMeetingRoomsRelay = PublishRelay<[Rust.MeetingRoom]>()
    fileprivate let selectionChangedSubject = PublishSubject<Void>()
    fileprivate let autoJustTimeTappedRelay = PublishRelay<(Bool, EKRecurrenceRule?)>()

    // 置顶信息
    fileprivate let pinRelatedInfo = BehaviorRelay<Rust.PinLevelRelatedInfo>(value: .init(autoDisplayPathMap: [:], recentlyUsedNodeList: []))

    // 影响样式 & 请求
    let isMultiSelectActive: BehaviorRelay<Bool>
    /// 用于日志
    private var firstShowPinInfo = true

    init(config: Config, userResolver: UserResolver) {
        self.config = config
        self.userResolver = userResolver
        self.isMultiSelectActive = .init(value: config.showLevelsOnly)
        if let selectedLevelIds = config.selectedLevelIds {
            MLLevel.selectedLevelIds = selectedLevelIds
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(levelIndicatorView)

        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalTo(levelIndicatorView.snp.bottom).priority(.low)
            make.leading.trailing.bottom.equalToSuperview()
        }
        containerView.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        containerView.addSubview(tableViewContainer)
        tableViewContainer.addSubview(autoJustTimeLabel)
        autoJustTimeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.height.equalTo(0)
        }
        tableViewContainer.addSubview(tableView)
        tableView.snp.remakeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(autoJustTimeLabel.snp.bottom)
        }

        levelIndicatorView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        updateLevelNode()

        bind()
    }

    private func updateLevelNode() {
        self.showLoading()
        guard let rustAPI = self.rustAPI else {
            logger.error("updateLevelNode failed, cause can not get rustapi from larkcontainer")
            return
        }
        if config.showLevelsOnly {
            // 会议室主视图层级筛选
            Observable.zip(rustAPI.pullLevelPathRequest(levelIds: MLLevel.selectedLevelIds),
                           rustAPI.getHierarchicalRoomViewSubLevelInfo(levelIds: [], needTopLevelInfo: true))
                .observeOn(MainScheduler.instance)
                .collectSlaInfo(.MeetingRoomViewAddEvent, action: "load_sublevel", source: "level")
                .subscribe(onNext: { [weak self] (levelPaths, subLevelInfos) in
                    guard let self = self,
                          let rootLevel = self.config.injectedRootLevel else { return }
                    let levelPaths = levelPaths.mapValues { path in
                        var path = path
                        if let first = path.first,
                           first != MLLevel.RequestRootLevelInfo.id {
                            path.insert(MLLevel.RequestRootLevelInfo.id, at: 0)
                        }
                        return path
                    }
                    MLLevel.levelPaths.merge(levelPaths, uniquingKeysWith: { $1 })
                    rootLevel.hasChild = !(subLevelInfos[MLLevel.RequestRootLevelInfo.id]?.sonLevelInfos.isEmpty ?? true)
                    rootLevel.populateWith(SDKInfoDict: subLevelInfos, userCalendarIDs: self.userCalendarIDs)
                    self.endLoading()
                    UDToast.removeToast(on: self.view)
                    self.updateUI()
                    self.selectedLevelIdsRelay.accept(MLLevel.selectedLevelIds)
                    self.levelIndicatorView.rx.level.onNext(rootLevel)
                }, onError: { [weak self] error in
                    guard let self = self else { return }
                    UDToast.removeToast(on: self.view)
                    print(error)
                    DispatchQueue.main.async {
                        UDToast.showFailure(with: BundleI18n.Calendar.Calendar_Common_FailedToLoad, on: self.view)
                    }
                })
                .disposed(by: bag)
        } else {
            requestForRoomsAndLevels(with: [MLLevel.RequestRootLevelInfo.id], needToplevelInfo: true)
                .map { [weak self] (sdkInfo, pinInfo, levelInfoMap) -> MLLevel in
                    self?.pinRelatedInfo.accept(pinInfo)

                    var eventDuration: Int64 = 0
                    if let startDate = self?.config.startDate, let endDate = self?.config.endDate {
                        eventDuration = Int64(endDate.timeIntervalSince(startDate))
                    }

                    let rootLevel = MLLevel(name: MLLevel.RequestRootLevelInfo.name,
                                            id: MLLevel.RequestRootLevelInfo.id,
                                            config: MLLevel.MLLevelConfig(
                                                eventDuration: eventDuration,
                                                eventConditions: self?.config.eventConditions ?? (false, false),
                                                showLevelsOnly: self?.config.showLevelsOnly ?? false)
                    )
                    rootLevel.levelAdjustTimeInfo = levelInfoMap[MLLevel.RequestRootLevelInfo.id]
                    rootLevel.populateWith(SDKInfoDict: sdkInfo, userCalendarIDs: self?.userCalendarIDs)
                    guard let self = self else { return rootLevel }
                    // 一定要确保 homeVC 进入在任何情况下都不过滤
                    rootLevel.rootLevel.recursiveUpdateFilter(capacity: self.config.rxMinCapacity?.value ?? 0,
                                                              equipments: self.config.rxEquipments?.value ?? [],
                                                              showAvailableOnly: self.config.rxAvailableRoomsOnly?.value ?? !self.config.showLevelsOnly)
                    if FG.supportLevelPinTop, !self.isMultiSelectActive.value {
                        CalendarTracerV2.EventAddResource.traceView {
                            $0.top_initial_group_id = pinInfo.autoDisplayPathMap.keys.first ?? ""
                            $0.mergeEventCommonParams(commonParam: self.config.eventParam ?? .init())
                        }
                    }
                    return rootLevel
                }.amb(Observable.deferred({ [weak self] in
                    guard let rootLevel = self?.config.injectedRootLevel else {
                        return .never()
                    }
                    return .just(rootLevel)
                        .delay(.milliseconds(100), scheduler: MainScheduler.instance)
                        .do(afterCompleted: {
                            // upade selectedNo. from HomeVC
                            let selectedRooms = self?.config.injectedRootLevel?.recursiveGetAllSelectedMeetingRooms ?? []
                            self?.selectedMeetingRoomsRelay.accept(selectedRooms)
                        })
                            }))
                .collectSlaInfo(.EventAddMeetingRoom, action: "load_level", source: "level")
                .subscribeForUI(onNext: { [weak self] newLevel in
                    guard let self = self else { return }
                    UDToast.removeToast(on: self.view)
                    self.endLoading()
                    self.updateUI()
                    self.levelIndicatorView.rx.level.onNext(newLevel)
                }, onError: { [weak self] error in
                    guard let self = self else { return }
                    UDToast.removeToast(on: self.view)
                    print(error)
                    DispatchQueue.main.async {
                        UDToast.showFailure(with: BundleI18n.Calendar.Calendar_Common_FailedToLoad, on: self.view)
                    }
                })
                .disposed(by: bag)
        }
    }

    // 重刷当前层级的数据
    func refreshCurrentLevel() {
        self.showLoading()
        guard let currentLevel = self.levelIndicatorView.currentLevel else { return }
        let nodeIDs = [currentLevel.id]
        self.requestForRoomsAndLevels(with: nodeIDs, needAutoJump: false)
            .collectSlaInfo(.EventAddMeetingRoom, action: "load_sublevel", source: "level")
            .subscribeForUI(onNext: { [weak self] sdkInfo, _, levelInfoMap in
                guard let self = self else { return }
                currentLevel.populateWith(SDKInfoDict: sdkInfo, userCalendarIDs: self.userCalendarIDs)
                currentLevel.rootLevel.recursiveUpdateFilter(capacity: self.config.rxMinCapacity?.value ?? 0,
                                                              equipments: self.config.rxEquipments?.value ?? [],
                                                              showAvailableOnly: self.config.rxAvailableRoomsOnly?.value ?? true)
                currentLevel.needUpdate = false
                currentLevel.levelAdjustTimeInfo = levelInfoMap[currentLevel.id]
                self.endLoading()
                self.levelIndicatorView.rx.level.onNext(currentLevel)
            }, onError: { [weak self] error in
                guard let self = self else { return }
                print(error)
                DispatchQueue.main.async {
                    UDToast.showFailure(with: BundleI18n.Calendar.Calendar_Common_FailedToLoad, on: self.view)
                }
            }).disposed(by: self.bag)
    }

    private func updateUI() {
        selectAllView.removeFromSuperview()
        if isMultiSelectActive.value {
            containerView.addSubview(selectAllView)
            tableViewContainer.snp.remakeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
            }
            selectAllView.snp.remakeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
                make.top.equalTo(tableViewContainer.snp.bottom)
            }
        } else {
            tableViewContainer.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        view.addSubview(emptyRoomsLabel)
        emptyRoomsLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(levelIndicatorView.snp.bottom).offset(14)
        }
        emptyRoomsLabel.isHidden = true
    }

    private func bind() {
        // 选择有变时更新已经选中的会议室 - 多选 & 单选
        selectionChangedSubject
            .map { [weak self] _ in
                return self?.levelIndicatorView.currentLevel?.rootLevel.recursiveGetAllSelectedMeetingRooms ?? []
            }
            .debug("selected rooms changed")
            .bind(to: selectedMeetingRoomsRelay)
            .disposed(by: bag)

        // 层级选择页面更新已经选中的层级id
        selectionChangedSubject
            .filter({ [weak self] _ in
                return self?.config.showLevelsOnly ?? false
            })
            .map { _ in
                return MLLevel.selectedLevelIds
            }
            .debug("selected level ids changed")
            .bind(to: selectedLevelIdsRelay)
            .disposed(by: bag)

        // 选择有变时更新TableView数据 - 多选刷新UI
        selectionChangedSubject
            .when(isMultiSelectActive)
            .subscribeForUI(onNext: { [weak self] _ in
                if let level = self?.levelIndicatorView.currentLevel {
                    self?.levelIndicatorView.rx.level.onNext(level)
                }
            })
            .disposed(by: bag)

        let filtersCombined = Observable.combineLatest(
            (config.rxMinCapacity ?? .init(value: 0)),
            (config.rxEquipments ?? .init(value: [])),
            (config.rxAvailableRoomsOnly ?? .init(value: !config.showLevelsOnly))
        )

        // tableview 展示当前层级信息
        levelIndicatorView.rx.level
            .map { [weak self] level -> [LevelElement] in
                guard let self = self else { return [] }
                let levelsOnly = self.config.showLevelsOnly
                if levelsOnly {
                    // 暂时端上做过滤，后期应该会服务端实现
                    self.emptyRoomsLabel.isHidden = level.hasChild
                    self.emptyRoomsLabel.text = I18n.Calendar_G_NoLayersNow

                    return level.subLevels.filter { $0.status != .hidden }
                    .map { level -> MLLevel in
                        level.accessaryHidden = !level.hasChild
                        return level
                    }
                } else {
                    var items: [LevelElement]
                    if !self.isMultiSelectActive.value {
                        let availableOnly = self.config.rxAvailableRoomsOnly?.value ?? !self.config.showLevelsOnly
                        items = level.filteredMeetingRooms + level.subLevels.filter { !availableOnly || !$0.noUsableResource || $0.levelAdjustTimeInfo?.needAdjustTime == true }
                    } else {
                        items = level.filteredMeetingRooms + level.subLevels.filter { $0.status != .hidden }
                    }

                    // add section header
                    if FG.supportLevelPinTop,
                       self.config.source == .addMeeting,
                       level.id == MLLevel.RequestRootLevelInfo.id,
                       !self.pinRelatedInfo.value.autoDisplayPathMap.isEmpty {
                        items = items.compactMap({ item -> LevelElement? in
                            // Appointment: autoDisplayPathMap 非空时，这里不会有会议室
                            guard let displayItem = item as? LevelsDisplayItem, let level = displayItem.level else { return nil }
                            if let path = self.pinRelatedInfo.value.autoDisplayPathMap[level.id]?.levelNode {
                                level.autoDisplayPath = path
                            }
                            return displayItem
                        })
                        // sdk 保证常用在前，端上通过 isTop 划分
                        if !items.isEmpty,
                           let firstIsTop = (items.first as? LevelsDisplayItem)?.level?.isTop, firstIsTop {
                            items.insert(SectionHeader(title: I18n.Calendar_G_FrequentlyUsed, hasTopSep: false), at: 0)

                            if let lastHabitualUsedIndex = items.lastIndex(where: { item in
                                guard let level = (item as? LevelsDisplayItem)?.level else { return false }
                                return level.isTop
                            }), lastHabitualUsedIndex < items.count - 1 {
                                items.insert(SectionHeader(title: I18n.Calendar_G_Others, hasTopSep: true), at: lastHabitualUsedIndex + 1)
                            }
                        }
                    }
                    self.logger.info(
                        """
                        levelIndicatorView,
                        needAdjustTime = \(level.levelAdjustTimeInfo?.needAdjustTime ?? false),
                        level.id = \(level.id)
                        fg = \(FG.calendarRoomsReservationTime),
                        endDateEditable = \(self.config.endDateEditable == true)
                        """)
                    // 先判断是否展示「一键调整当前截止时间」
                    let isNotTopLevel = level.id != "0"
                    if let info = level.levelAdjustTimeInfo,
                       info.needAdjustTime,
                       isNotTopLevel,
                       level.filteredMeetingRooms.isEmpty,
                       FG.calendarRoomsReservationTime,
                       self.config.endDateEditable == true {
                        self.autoJustTimeLabel.snp.remakeConstraints { make in
                            make.left.right.equalToSuperview().inset(16)
                            make.top.equalTo(14)
                        }
                        self.updateEmptyRoomsLabel(info: info)
                        self.emptyRoomsLabel.isHidden = true
                    } else if items.isEmpty {
                        self.autoJustTimeLabel.snp.remakeConstraints { make in
                            make.top.equalToSuperview()
                            make.height.equalTo(0)
                        }
                        self.emptyRoomsLabel.isHidden = false
                    } else {
                        self.autoJustTimeLabel.snp.remakeConstraints { make in
                            make.top.equalToSuperview()
                            make.height.equalTo(0)
                        }
                        self.emptyRoomsLabel.isHidden = true
                    }
                    self.emptyRoomsLabel.text = I18n.Calendar_Detail_NoAvailableRoomsFound
                    return items
                }
            }
            .debug("MR-test-tableview cell binding")
            .bind(to: tableView.rx.items) { [weak self] tableView, _, element in
                guard let self = self else { return UITableViewCell() }
                if let item = element as? MLLevel.MeetingRoomWithSelection,
                   self.isSubscribeScene {
                    return self.makeSubscribeMeetingRoomCell(in: tableView, item: item)
                } else if let item = element as? LevelsDisplayItem {
                    return self.makeLevelTableViewCell(in: tableView, item: item)
                } else if let item = element as? SectionHeader {
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: "SectionHeaderCell") as? SectionHeaderCell else { return UITableViewCell() }
                    cell.headerTitle = (item.title, item.hasTopSep)
                    return cell
                } else {
                    // failure
                    assertionFailure()
                    return SectionHeaderCell()
                }
            }
            .disposed(by: bag)

        // tableview 点击会议室选中/点击层级进入下一层级
        tableView.rx.modelSelected(LevelsDisplayItem.self)
            .debug("level or meetringRoom tapped: ")
            .subscribeForUI(onNext: { [weak self] item in
                guard let self = self else { return }
                self.tableViewCellTapped(with: item)
            })
            .disposed(by: bag)

        selectAllView.rx.selectAllStateDidChange
            .when(isMultiSelectActive)
            .subscribe(onNext: { [weak self] state in
                guard let self = self else { return }
                guard state == .selected || state == .nonSelected else { return }
                self.levelIndicatorView.currentLevel?.selectType = state
                self.selectionChangedSubject.onNext(())
            })
            .disposed(by: bag)

        Observable.combineLatest(levelIndicatorView.rx.level, selectionChangedSubject.startWith(()))
            .map { level, _ -> SelectType in
                level.status.convertToSelectType()
            }
            .debug("set selectAllView result")
            .bind(to: selectAllView.rx.selectAllState)
            .disposed(by: bag)

        filtersCombined
            .debug("filters changed")
            .subscribeForUI(onNext: { [weak self] capacity, equipments, availableRoomsOnly in
                guard let self = self else { return }
                guard let level = self.levelIndicatorView.currentLevel else { return }
                level.rootLevel.recursiveUpdateFilter(capacity: capacity, equipments: equipments, showAvailableOnly: availableRoomsOnly)
                level.rootLevel.status = .nonSelected
                self.levelIndicatorView.rx.level.onNext(level)
            })
            .disposed(by: bag)

        isMultiSelectActive.distinctUntilChanged().skip(1)
            .throttle(.milliseconds(200), scheduler: MainScheduler.instance)
            .debug("MR-test-isMultiSelectActive changed")
            .subscribeForUI(onNext: { [weak self] _ in
                guard let self = self else { return }
                UDToast.showLoading(with: BundleI18n.Calendar.Calendar_Edit_MoreMeetingRooms, on: self.view)
                self.updateLevelNode()
            })
            .disposed(by: bag)

        levelIndicatorView.levelToUpdate
            .subscribeForUI { [weak self] item in
                self?.levelTableViewCellTapped(with: item)
            }.disposed(by: bag)
    }

    private func updateEmptyRoomsLabel(info: Rust.LevelAdjustTimeInfo) {
        let newDate = info.resourceStrategy.getAdjustEventFurthestDate(timezone: config.timeZone, endDate: config.endDate ?? Date())
        let timezone = config.timeZone
        // 展示埋点
        CalendarTracerV2.UtiltimeAdjustRemind.traceView {
            $0.location = CalendarTracerV2.AdjustRemindLocation.addResourceView.rawValue
            $0.mergeEventCommonParams(commonParam: self.config.eventParam ?? .init())
        }
        let tapHandler: () -> Void = { [weak self] in
            guard let self = self else { return }
            let newEnd = EKRecurrenceEnd(end: newDate)
            // 1. 调整rrule的截止日期
            self.config.rrule?.recurrenceEnd = newEnd
            // 2. 同步信息到编辑页，修改其rrule
            self.autoJustTimeTappedRelay.accept((true, self.config.rrule))
            // 3. 根据新的截止时间重新刷新当前页面, 需要先调整rrule的截止日期
            self.refreshCurrentLevel()
            // 点击埋点
            CalendarTracerV2.UtiltimeAdjustRemind.traceClick {
                $0.click("adjust")
                $0.location = CalendarTracerV2.AdjustRemindLocation.addResourceView.rawValue
                $0.mergeEventCommonParams(commonParam: self.config.eventParam ?? .init())
            }
            // 展示toast
            let customOptions = Options(
                timeZone: timezone,
                timeFormatType: .long,
                datePrecisionType: .day
            )
            let dateDesc = TimeFormatUtils.formatDate(from: newDate, with: customOptions)
            UDToast.showTips(with: I18n.Calendar_G_AvailabilitySuggestion_TimeChanged_Popup(eventEndTime: dateDesc), on: self.view, delay: 5.0)
        }
        self.autoJustTimeLabel.updateInfo(date: newDate,
                                          timezone: timezone,
                                          preferredMaxLayoutWidth: self.view.frame.width - 16 * 2,
                                          tapHandler: tapHandler,
                                          font: UIFont.systemFont(ofSize: 16))
    }

    private func tableViewCellTapped(with item: LevelsDisplayItem) {
        if let meetingRoom = item.meetingRoom {
            // 点击会议室 cell
            if isSubscribeScene {
                /// 订阅场景直接 return，cell 的相关 action 在 cell 初始化的时候进行绑定，此处不进行
                return
            } else {
                /// 添加会议室场景
                levelTableViewCellTapped(with: meetingRoom, selectType: item.selectType)
            }
        } else if let nextLevel = item.level {
            // 点击层级 cell
            levelTableViewCellTapped(with: nextLevel)
        } else {
            assertionFailure()
        }
    }

    private func requestForRoomsAndLevels(
        with levelIDs: [String],
        needToplevelInfo: Bool = false,
        needAutoJump: Bool = false
    ) -> Observable<(sdkInfo: [String: Rust.MeetingRoomLevelInfo],
                     pinInfo: Rust.PinLevelRelatedInfo,
                     levelIDToAdjustTimeInfo: [String: Rust.LevelAdjustTimeInfo])> {
        guard let rustAPI = self.rustAPI else {
            logger.error("requestForRoomsAndLevels failed, cause can not get rustapi from larkcontainer")
            return .empty()
        }
        return rustAPI.getMeetingRoomsAndLevels(levelIDs: levelIDs,
                                                pullAll: isMultiSelectActive.value,
                                                startTime: config.startDate,
                                                endTime: config.endDate,
                                                rrule: config.rruleStr,
                                                needDisabledResource: config.showDisabledMeetingRooms,
                                                needToplevelInfo: FG.supportLevelPinTop && needToplevelInfo,
                                                needAutoJump: FG.supportLevelPinTop && needAutoJump,
                                                timezone: config.timeZone)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map { ($0.levelInfo, .init(autoDisplayPathMap: $0.autoDisplayPathMap, recentlyUsedNodeList: $0.recentlyUsedNodeList), $0.levelIDToAdjustTimeInfo) }
    }

    deinit {
        print("MeetingRoomMultiLevelSelectionViewController deinit")
    }

    private func showLoading() {
        loadingView.isHidden = false
        containerView.bringSubviewToFront(loadingView)
    }

    private func endLoading() {
        loadingView.isHidden = true
    }
}

// MARK: Config

extension MeetingRoomMultiLevelSelectionViewController {
    struct Config {
        /// 是否只展示层级信息 false会同时展示会议室与层级
        var showLevelsOnly: Bool

        /// 日程条件-影响会议室可用
        var eventConditions: (approveDisabled: Bool, formDisabled: Bool) = (false, false)
        /// 表单导致不可用文案
        var meetingRoomWithFormUnAvaliableReason: String?

        /// 全选的层级 id
        var selectedLevelIds: [String]?

        /// 只有根层级的时候不自动折叠LevelIndicator
        var alwaysShowLevelIndicator = false

        /// 优先使用外界注入的level
        var injectedRootLevel: MLLevel?

        /// 响应外界筛选变化
        var rxEquipments: BehaviorRelay<[String]>?
        var rxMinCapacity: BehaviorRelay<Int>?
        var rxAvailableRoomsOnly: BehaviorRelay<Bool>?
        
        /// 标识场景
        enum Source: String {
            /// 添加会议室
            case addMeeting
            /// 会议室视图页 > 层级选择
            case meetingHome
            /// 订阅会议室
            case subscribeMeeting
        }
        var source: Source

        // 以下属性直接传给sdk

        /// 开始时间
        var startDate: Date?
        /// 结束时间
        var endDate: Date?
        /// rrule
        var rruleStr: String? {
            rrule?.iCalendarString()
        }
        var rrule: EventRecurrenceRule?
        /// 是否展示不可用的会议室
        var showDisabledMeetingRooms: Bool = false
        /// 时区
        var timeZone: TimeZone = .current
        /// 日程公参（only for trace & add resources)
        var eventParam: CommonParamData?
        var endDateEditable: Bool?
    }
}

private extension Array where Element: Equatable {
    func allEqualTo(_ another: Element) -> Bool {
        allSatisfy { $0 == another }
    }
}

// MARK: Subscribe Meeting Room

extension MLLevel {
    func changeSubscribeStatus(meetingRoom: SubscribeAbleModel) {
        guard let index = filteredMeetingRooms.firstIndex(where: { $0.resource.calendarID == meetingRoom.calendarID }) else {
            assertionFailure("cannot find meetingRoom in current level")
            return
        }

        filteredMeetingRooms[index].subscribeStatus = meetingRoom.subscribeStatus
    }
}

extension MLLevel.MeetingRoomWithSelection: SubscribeMeetingRoomCellDataType, SubscribeAbleModel {
    var name: String { resource.name }
    // 需要审批（审批类会议室）
    var needsApproval: Bool { false }
    var capacityDesc: String { String(resource.capacity) }
    var location: String {
        resource.equipments.map(\.i18NName).joined(separator: "·")
    }
    var state: SubscribeStatus { subscribeStatus }
    var calendarID: String {
        get { resource.calendarID }
    }
    var isOwner: Bool {
        get { false }
        set {}
    }
    var pathName: String {
        ""
    }
}

extension MeetingRoomMultiLevelSelectionViewController: SubscribeAble {

    private var isSubscribeScene: Bool {
        self.config.source == .subscribeMeeting
    }

    private func makeSubscribeMeetingRoomCell(in tableView: UITableView, item: MLLevel.MeetingRoomWithSelection) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "subscribe") as? SubscribeMeetingRoomCell
        else {
            return UITableViewCell()
        }
        cell.viewData = item
        cell.setFirstLevelStyle()
        cell.subscribeButtonTapped = { [weak self] in
            /// 订阅会议室日历
            guard let self = self else { return }
            self.subsribe(with: item)
        }

        cell.onTapped = { [weak self] in
            /// 进入会议室详情页
            guard let self = self else { return }
            CalendarTracer.shared.calClickMeetingRoomInfoFromSubscribe()
            var context = DetailOnlyContext()
            context.calendarID = item.resource.calendarID
            let viewModel = MeetingRoomDetailViewModel(input: .detailOnly(context), userResolver: self.userResolver)
            let toVC = MeetingRoomDetailViewController(viewModel: viewModel, userResolver: self.userResolver)
            self.userResolver.navigator.push(toVC, from: self)
        }
        return cell
    }

    private func subsribe(with meetingRoom: MLLevel.MeetingRoomWithSelection) {
        let changeSubscribeState = { [weak self] (meetingRoom: SubscribeAbleModel) in
            guard let currentLevel = self?.levelIndicatorView.currentLevel else { return }
            currentLevel.changeSubscribeStatus(meetingRoom: meetingRoom)
            self?.levelIndicatorView.rx.level.onNext(currentLevel)
        }
        /// 点击订阅/退订埋点
        if meetingRoom.subscribeStatus == .subscribed || meetingRoom.subscribeStatus == .noSubscribe {
            CalendarTracerV2.CalendarSubscribe.traceClick {
                let subscribed = (meetingRoom.subscribeStatus == .subscribed)
                $0
                 .click(subscribed ? "unsubscribe_resource_cal" : "subscribe_resource_cal")
                 .target("none")
                $0.calendar_id = meetingRoom.resource.calendarID
            }
        }
        guard let rustAPI = self.rustAPI else {
            logger.error("showLevelsOnly failed, cause can not get rustapi from larkcontainer")
            return
        }
        self.changeSubscribeStatus(content: meetingRoom,
                                   calendarApi: rustAPI,
                                   disposeBag: bag,
                                   searchType: .recom,
                                   pageType: .mtgrooms,
                                   controller: self,
                                   refresh: changeSubscribeState)
    }
}

// MARK: Add Meeting Room | Multi Level Selection

extension Reactive where Base == MeetingRoomMultiLevelSelectionViewController {
    var selectedLevelIds: Observable<[String]> {
        base.selectedLevelIdsRelay.asObservable()
    }

    var selectedMeetingRooms: Observable<[Rust.MeetingRoom]> {
        base.selectedMeetingRoomsRelay.asObservable()
    }

    var currentLevel: Observable<MLLevel> {
        base.levelIndicatorView.rx.level.asObservable()
    }
    
    var autoJustTimeTappedOb: Observable<(Bool, EKRecurrenceRule?)> {
        base.autoJustTimeTappedRelay.asObservable()
    }
}

protocol LevelElement { }

struct SectionHeader: LevelElement {
    let title: String
    let hasTopSep: Bool
}

protocol LevelsDisplayItem: LevelElement {
    var title: String { get }
    var level: MLLevel? { get }
    var meetingRoom: Rust.MeetingRoom? { get }
    var selectType: SelectType { get set }
}

extension MLLevel: LevelsDisplayItem {
    var title: String { name }
    var level: MLLevel? { self }
    var meetingRoom: Rust.MeetingRoom? { nil }
    var selectType: SelectType {
        get { status.convertToSelectType() }
        set {
            switch newValue {
            case .selected:
                status = .selected
            case .nonSelected:
                status = .nonSelected
            default:
                assertionFailure("invalid status")
            }
        }

    }
}

extension MLLevel.MeetingRoomWithSelection: LevelsDisplayItem {
    var title: String { resource.name }
    var level: MLLevel? { nil }
    var meetingRoom: Rust.MeetingRoom? { resource }
    var selectType: SelectType {
        get { selectStatus.convertToSelectType() }
        set {
            switch newValue {
            case .selected:
                selected = true
            case .nonSelected:
                selected = false
            default:
                assertionFailure("invalid status")
            }
        }
    }
}

extension MeetingRoomMultiLevelSelectionViewController {
    private func makeLevelTableViewCell(in tableView: UITableView, item: LevelsDisplayItem) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? LevelTableViewCell else {
            return UITableViewCell()
        }

        if let level = item.level {
            let isLevelHabitualUsed = self.pinRelatedInfo.value.recentlyUsedNodeList.contains(level.id)
            item.level?.isHabitualUsed = isLevelHabitualUsed
        }

        cell.layoutUI(withCheckBox: self.isMultiSelectActive.value)
        cell.levelDisplayItem = item
        cell.state = item.selectType

        cell.rx.selectState
            .debug("MR-test-invisibleButton tapped")
            .bind(to: self.selectionChangedSubject)
            .disposed(by: cell.disposeBag)
        cell.rx.infoIconTapped
            .subscribeForUI(onNext: { [weak self] meetingRoom in
                guard let self = self else { return }
                let context = DetailWithStatusContext(calendarID: meetingRoom.calendarID,
                                                      rrule: self.config.rruleStr ?? "",
                                                      startTime: self.config.startDate,
                                                      endTime: self.config.endDate,
                                                      timeZone: self.config.timeZone.identifier)
                let vm = MeetingRoomDetailViewModel(input: MeetingRoomDetailInput.detailWithStatus(context), userResolver: self.userResolver)
                let vc = MeetingRoomDetailViewController(viewModel: vm, userResolver: self.userResolver)
                self.userResolver.navigator.push(vc, from: self)
            })
            .disposed(by: cell.disposeBag)
        return cell

    }

    // 点击会议室类型的 LevelTableViewCell
    private func levelTableViewCellTapped(with meetingRoom: Rust.MeetingRoom, selectType: SelectType) {
        if !self.isMultiSelectActive.value {
            self.levelIndicatorView.currentLevel?.rootLevel.status = .nonSelected
        }

        guard !(meetingRoom.needsApproval && self.config.rruleStr.isNotEmpty) else {
            // 全量审批和重复性互斥
            UDToast.showTips(with: I18n.Calendar_Approval_RecurToast, on: self.view)
            return
        }

        guard let startDate = config.startDate,
              let endDate = config.endDate,
              !(meetingRoom.shouldTriggerApproval(duration: Int64(endDate.timeIntervalSince(startDate))) && self.config.rruleStr.isNotEmpty)
        else {
            if let trigger = meetingRoom.schemaExtraData.cd.conditionalApprovalTriggerDuration {
                // 触发了条件审批的会议室 和 rrule 互斥
                let duration = Double(trigger) / 3600.0
                UDToast.showTips(with: I18n.Calendar_Rooms_CantReserveOverTime(num: String(format: "%g", duration)), on: self.view)
            }
            return
        }

        guard !(meetingRoom.hasForm && self.config.eventConditions.formDisabled) else {
            // 编辑前置下，编辑此次和编辑后续不可以选择表单会议室
            if let reason = self.config.meetingRoomWithFormUnAvaliableReason {
                UDToast.showTips(with: reason, on: self.view)
            }
            return
        }

        guard selectType != .disabled || !self.isMultiSelectActive.value else { return }
        self.levelIndicatorView.currentLevel?.toggleMeetingRoomSelection(meetingRoom: meetingRoom)
        self.selectionChangedSubject.onNext(())

        // Disgusting tracing code
        if !self.isMultiSelectActive.value, FG.supportLevelPinTop {
            let currentLevel = levelIndicatorView.currentLevel
            var initLevel = currentLevel
            while let superLevel = initLevel?.superLevel, superLevel.id != MLLevel.RequestRootLevelInfo.id {
                initLevel = superLevel
            }
            let topOneLevel = currentLevel?.rootLevel.subLevels.first
            let pinIDs = pinRelatedInfo.value.autoDisplayPathMap.keys

            CalendarTracerV2.EventAddResource.traceClick {
                $0.click("add_resource")
                $0.reousrce_id = meetingRoom.id
                $0.group_id = currentLevel?.id ?? ""
                $0.initial_group_id = initLevel?.id ?? ""
                $0.is_top_group = (topOneLevel?.autoDisplayPath.last?.levelID == $0.group_id).description
                $0.is_top_initial_group = (topOneLevel?.id == $0.initial_group_id).description
                $0.is_recently_used = pinIDs.contains($0.initial_group_id ?? "").description
                $0.mergeEventCommonParams(commonParam: self.config.eventParam ?? .init())
            }
        }
    }

    // 点击层级类型的 LevelTableViewCell
    private func levelTableViewCellTapped(with nextLevel: MLLevel) {
        if self.config.showLevelsOnly {
            if nextLevel.hasChild,
               nextLevel.subLevels.isEmpty {
                guard let rustAPI = self.rustAPI else {
                    logger.error("showLevelsOnly failed, cause can not get rustapi from larkcontainer")
                    return
                }
                // 有子层级，但是为空，需要请求获取子层级信息
                self.showLoading()
                rustAPI.getHierarchicalRoomViewSubLevelInfo(levelIds: [nextLevel.id])
                    .subscribeForUI(onNext: { [weak self] sdkInfo in
                        guard let self = self else { return }
                        nextLevel.populateWith(SDKInfoDict: sdkInfo, userCalendarIDs: self.userCalendarIDs)
                        self.endLoading()
                        self.levelIndicatorView.rx.level.onNext(nextLevel)
                    })
                    .disposed(by: self.bag)
            } else {
                self.levelIndicatorView.rx.level.onNext(nextLevel)
            }
        } else {
            let needAutoJumpToLeaf = self.levelIndicatorView.currentLevel?.id == MLLevel.RequestRootLevelInfo.id && !nextLevel.autoDisplayPath.isEmpty
            var nodeToDisplay = nextLevel
            // leaf Node
            if needAutoJumpToLeaf {
                for levelInfo in nextLevel.autoDisplayPath.dropFirst() {
                    if let node = nodeToDisplay.subLevels.first(where: { $0.id == levelInfo.levelID }) {
                        nodeToDisplay = node
                    }
                }
            }

            let backToSuperLevelIfEmpty = { (leaf: MLLevel) -> (displayLevel: MLLevel, hasBackJump: Bool) in
                if needAutoJumpToLeaf,
                   leaf.filteredMeetingRooms.isEmpty,
                   leaf.subLevels.allSatisfy({ level in
                       // 无子节点（会议室+子层级）需要隐藏 ｜ 无可用会议室）, 且无一键调整
                       return (level.status == .hidden || level.noUsableResource) && (level.levelAdjustTimeInfo?.needAdjustTime == false)
                   }),
                   let superL = leaf.superLevel {
                    return (superL, true)
                } else { return (leaf, false) }
            }

            if !self.isMultiSelectActive.value {
                self.showLoading()
                let nodeIDs = needAutoJumpToLeaf ? nextLevel.autoDisplayPath.map(\.levelID) : [nodeToDisplay.id]
                self.requestForRoomsAndLevels(with: nodeIDs, needAutoJump: needAutoJumpToLeaf)
                    .collectSlaInfo(.EventAddMeetingRoom, action: "load_sublevel", source: "level")
                    .subscribeForUI(onNext: { [weak self] sdkInfo, _, levelInfoMap in
                        guard let self = self else { return }
                        var hasBackJump = false
                        if !sdkInfo.keys.contains(nodeToDisplay.id) {
                            nodeToDisplay = nodeToDisplay.superLevel ?? nodeToDisplay
                            hasBackJump = true
                        }

                        nodeToDisplay.populateWith(SDKInfoDict: sdkInfo, userCalendarIDs: self.userCalendarIDs)
                        nodeToDisplay.rootLevel.recursiveUpdateFilter(capacity: self.config.rxMinCapacity?.value ?? 0,
                                                                      equipments: self.config.rxEquipments?.value ?? [],
                                                                      showAvailableOnly: self.config.rxAvailableRoomsOnly?.value ?? true)
                        nodeToDisplay.needUpdate = false
                        // 这里只可能取nodeToDisplay.id
                        nodeToDisplay.levelAdjustTimeInfo = levelInfoMap[nodeToDisplay.id]
                        self.endLoading()
                        self.levelIndicatorView.rx.level.onNext(nodeToDisplay)
                        if needAutoJumpToLeaf, !hasBackJump { UDToast.showTips(with: I18n.Calendar_G_LocateToFrequentlyUsed, on: self.view) }
                    }, onError: { [weak self] error in
                        guard let self = self else { return }
                        print(error)
                        DispatchQueue.main.async {
                            UDToast.showFailure(with: BundleI18n.Calendar.Calendar_Common_FailedToLoad, on: self.view)
                        }
                    }).disposed(by: self.bag)
            } else {
                let predicateResult = backToSuperLevelIfEmpty(nodeToDisplay)
                nodeToDisplay = predicateResult.displayLevel
                self.levelIndicatorView.rx.level.onNext(nodeToDisplay)
                if needAutoJumpToLeaf, !predicateResult.hasBackJump { UDToast.showTips(with: I18n.Calendar_G_LocateToFrequentlyUsed, on: view) }
            }
        }
    }
}
