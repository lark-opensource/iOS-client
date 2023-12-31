//
//  MeetingRoomSearchViewModel.swift
//  Calendar
//
//  Created by zhuheng on 2021/1/22.
//

import RxSwift
import RxCocoa
import LarkContainer

// 会议室搜索：
//          日程添加会议室: 限定起止时间 & rrule
//          搜索会议室: 不限定起止时间 & rrule
//          订阅会议室: 不限定起止时间 & rrule
// DataFlow:
//          rxHideUnavailable    -> onAllCellDataUpdate
//          rxNeedEquipments     -> reSearch
//          rxMinCapacity        -> reSearch
//          rxQuery              -> reSearch

typealias MeetingRoomSearchDataType = EventMeetingRoomCellDataType & SubscribeMeetingRoomCellDataType
final class MeetingRoomSearchViewModel: UserResolverWrapper {
    enum ViewState {
        // 加载中
        case loading
        // 加载完成（有数据），hasMore - 是否还有更多，isLoadingMore - 是否在加载更多
        case data(hasMore: Bool, isLoadingMore: Bool)
        // 加载完成（无数据），String 参数 - 搜索结果为空的文案展示
        case empty(String, hasMore: Bool)
        // 加载失败
        case failed
        // 取消搜索
        case cancelSearch
    }

    @ScopedInjectedLazy var calendarManager: CalendarManager?
    let userResolver: UserResolver
    let rxViewState = BehaviorRelay(value: ViewState.data(hasMore: false, isLoadingMore: false))
    let rxAlert = PublishRelay<(String, String)>()
    var onAllCellDataUpdate: (() -> Void)?
    var onSubscribeSuccess: ((_ toastInfo: String) -> Void)?
    var onSubscribeError: ((_ toastInfo: String) -> Void)?

    typealias SearchItem = CalendarRustAPI.MeetingRoomSearchItem
    // 是否隐藏不可用会议室
    private let rxHideUnavailable: BehaviorRelay<Bool>
    // empty 场景下可用/不可用会议室的文案展示
    private var emptyText = I18n.Calendar_Detail_NoAvailableRoomsFound
    // 搜索 key
    private let rxQuery: BehaviorRelay<String>

    private var loadedSearchItems: [SearchItem] = []
    private var lastLoadingDisposable: Disposable?
    private let disposeBag = DisposeBag()
    private let meetingRoomApi: CalendarRustAPI?
    private let tenantId: String
    private var startDate: Date?
    private var endDate: Date?
    private var multiLevelResources: Bool
    private let rrule: EventRecurrenceRule?
    private let eventConditions: (approveDisabled: Bool, formDisabled: Bool)
    private let meetingRoomWithFormDisableReason: String
    private let filterMeetingRoomIds: Set<String>
    private static let loadStep = 50
    private var cellDataArray: [CellData] = []
    private let rxNeedEquipments: BehaviorRelay<[String]>
    private let rxMinCapacity: BehaviorRelay<Int>
    private let scene: Scene

    // 多选load more使用
    private var cursor: Int = 0

    enum Scene {
        // 订阅会议室场景
        case subscribe
        // 大搜场景
        case search
        // 添加会议室场景
        case add
    }

    init(
        userResolver: UserResolver,
        meetingRoomApi: CalendarRustAPI?,
        tenantId: String,
        startDate: Date? = nil,
        endDate: Date? = nil,
        rrule: EventRecurrenceRule? = nil,
        eventConditions: (approveDisabled: Bool, formDisabled: Bool) = (false, false),
        meetingRoomWithFormDisableReason: String = "",
        multiLevelResources: Bool,
        rxHideUnavailable: BehaviorRelay<Bool>,
        rxQuery: BehaviorRelay<String>,
        rxNeedEquipments: BehaviorRelay<[String]>,
        rxMinCapacity: BehaviorRelay<Int>,
        filterMeetingRoomIds: Set<String> = Set<String>(),
        scene: Scene
    ) {
        self.userResolver = userResolver
        self.filterMeetingRoomIds = filterMeetingRoomIds
        self.meetingRoomApi = meetingRoomApi
        self.tenantId = tenantId
        self.startDate = startDate
        self.endDate = endDate
        self.rrule = rrule
        self.eventConditions = eventConditions
        self.meetingRoomWithFormDisableReason = meetingRoomWithFormDisableReason
        self.multiLevelResources = multiLevelResources
        self.rxHideUnavailable = rxHideUnavailable
        self.rxQuery = rxQuery
        self.rxNeedEquipments = rxNeedEquipments
        self.rxMinCapacity = rxMinCapacity
        self.scene = scene

        rxQuery.debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .bind { [weak self] _ in
                guard let self = self else { return }
                self.reSearch()
            }
            .disposed(by: disposeBag)

        rxNeedEquipments.debounce(.milliseconds(300), scheduler: MainScheduler.instance)        .skip(1)
            .distinctUntilChanged()
            .bind { [weak self] (_) in
                self?.reSearch()
            }.disposed(by: disposeBag)

        rxMinCapacity.debounce(.milliseconds(300), scheduler: MainScheduler.instance)        .skip(1)
            .distinctUntilChanged()
            .bind { [weak self] (_) in
                self?.reSearch()
            }.disposed(by: disposeBag)

        self.rxHideUnavailable.distinctUntilChanged().skip(1)
            .bind { [weak self] _ in
                guard let self = self else { return }
                self.cellDataArray = self.produceCellData()
                switch self.rxViewState.value {
                case .empty(_, let hasMore):
                    if self.cellDataArray.isEmpty {
                        self.rxViewState.accept(.empty(self.emptyText, hasMore: hasMore))
                    } else {
                        self.rxViewState.accept(.data(hasMore: hasMore, isLoadingMore: false))
                    }
                case .data(let hasMore, let isLoadingMore):
                    if self.cellDataArray.isEmpty {
                        self.rxViewState.accept(.empty(self.emptyText, hasMore: hasMore))
                    } else {
                        self.rxViewState.accept(.data(hasMore: hasMore, isLoadingMore: isLoadingMore))
                    }
                default:
                    break
                }
                self.onAllCellDataUpdate?()
            }
            .disposed(by: disposeBag)
    }

    private func reSearch() {
        if rxQuery.value.isEmpty {
            self.rxViewState.accept(.cancelSearch)
            return
        }
        self.loadedSearchItems = []
        self.rxViewState.accept(.loading)
        self.loadMeetingRoom(by: rxQuery.value, count: Self.loadStep)
    }

    func loadMore() {
        guard case .data(let hasMore, let isLoadingMore) = rxViewState.value,
            hasMore, !isLoadingMore else {
            return
        }

        self.rxViewState.accept(.data(hasMore: true, isLoadingMore: true))
        if multiLevelResources {
            loadMeetingRoom(by: rxQuery.value, cursor: cursor, count: Self.loadStep)
        } else {
            loadMeetingRoom(by: rxQuery.value, cursor: cursor, count: Self.loadStep)
        }
    }

    private func loadMeetingRoom(by query: String, cursor: Int = 0, count: Int) {
        lastLoadingDisposable?.dispose()
        if query.isEmpty {
            loadedSearchItems = []
            cellDataArray = produceCellData()
            onAllCellDataUpdate?()
            rxViewState.accept(.cancelSearch)
            return
        }
        let rxGetMeetingRooms: Observable<(items: [CalendarRustAPI.MeetingRoomSearchItem], cursor: Int, hasMore: Bool)>?
        if multiLevelResources {
            rxGetMeetingRooms = meetingRoomApi?.searchMeetingRoomsWithMultiLevel(
                byKeyword: query,
                cursor: cursor,
                tenantId: tenantId,
                startDate: startDate,
                endDate: endDate,
                count: count,
                rruleStr: rrule?.iCalendarString(),
                needDisabledResource: false,
                minCapacity: Int32(rxMinCapacity.value),
                needEquipments: rxNeedEquipments.value
            )
        } else {
            rxGetMeetingRooms = meetingRoomApi?.searchMeetingRooms(
                byKeyword: query,
                cursor: cursor,
                tenantId: tenantId,
                startDate: startDate,
                endDate: endDate,
                count: count,
                rruleStr: rrule?.iCalendarString(),
                needDisabledResource: false,
                minCapacity: Int32(rxMinCapacity.value),
                needEquipments: rxNeedEquipments.value
            )
        }
        lastLoadingDisposable = rxGetMeetingRooms?
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] tuple in
                    guard let self = self else { return }
                    guard self.rxQuery.value == query else { return }
                    let (items, cursor, hasMore) = tuple
                    self.cursor = cursor
                    self.loadedSearchItems += items
                    self.cellDataArray = self.produceCellData()
                    self.onAllCellDataUpdate?()
                    if self.cellDataArray.isEmpty {
                        self.rxViewState.accept(.empty(self.emptyText, hasMore: hasMore))
                    } else {
                        self.rxViewState.accept(.data(hasMore: hasMore, isLoadingMore: false))
                    }
                    SlaMonitor.traceSuccess(.EventAddMeetingRoom ,
                                            action: "load_search",
                                            source: self.multiLevelResources ? "level" : "meeting")
                },
                onError: { [weak self] error in
                    guard let self = self else { return }
                    guard self.rxQuery.value == query else { return }
                    if case .data(let hasMore, _) = self.rxViewState.value {
                        self.rxViewState.accept(.data(hasMore: hasMore, isLoadingMore: false))
                    } else {
                        self.rxViewState.accept(.failed)
                    }
                    SlaMonitor.traceFailure(.EventAddMeetingRoom,
                                            error: error,
                                            action: "load_search",
                                            source: self.multiLevelResources ? "level" : "meeting")
                }
            )
    }

    private func produceCellData() -> [CellData] {
        let userCalendarIDs:[String] = calendarManager?.allCalendars.map { $0.serverId } ?? []
        // 对于含有重复性规则的日程，审批类会议室不可用
        let isAvailableForMeetingRoomThatNeedsApproval = (rrule == nil)
        let isDisableForMeetingRoomThatHasForm = eventConditions.formDisabled
        return loadedSearchItems
            .filter { !filterMeetingRoomIds.contains($0.meetingRoom.calendarID) }
            .map { searchItem in
                var isAvailable = searchItem.meetingRoom.status == .free
                var unAvailableReason: String?
                if searchItem.meetingRoom.hasForm, isDisableForMeetingRoomThatHasForm {
                    isAvailable = false
                    unAvailableReason = meetingRoomWithFormDisableReason
                }

                if let startDate = startDate,
                   let endDate = endDate,
                   !isAvailableForMeetingRoomThatNeedsApproval,
                   searchItem.meetingRoom.shouldTriggerApproval(duration: Int64(endDate.timeIntervalSince(startDate))),
                   let trigger = searchItem.meetingRoom.schemaExtraData.cd.conditionalApprovalTriggerDuration {
                    // 触发了条件审批的会议室 和 rrule 互斥
                    let duration = Double(trigger) / 3600.0
                    isAvailable = false
                    unAvailableReason = I18n.Calendar_Rooms_CantReserveOverTime(num: String(format: "%g", duration))
                }

                if searchItem.meetingRoom.needsApproval, !isAvailableForMeetingRoomThatNeedsApproval {
                    isAvailable = false
                    unAvailableReason = I18n.Calendar_Approval_RecurToast
                }

                let status: SubscribeStatus = userCalendarIDs.contains(searchItem.meetingRoom.calendarID) ? .subscribed : .noSubscribe
                let locationStr: String
                if multiLevelResources {
                    locationStr = searchItem.meetingRoom.equipments.map(\.i18NName).joined(separator: "·")
                } else {
                    locationStr = searchItem.building.name
                }
                return CellData(searchItem: searchItem,
                                isAvailable: isAvailable,
                                unAvailableReason: unAvailableReason,
                                state: status,
                                calendarID: searchItem.meetingRoom.calendarID,
                                location: locationStr,
                                shouldShowApprovalTag: scene != .subscribe)
            }.filter { cellData in
                if !rxHideUnavailable.value {
                    return true
                }
                return cellData.isAvailable
            }
    }

}

extension MeetingRoomSearchViewModel {
    struct CellData: MeetingRoomSearchDataType {
        var searchItem: SearchItem
        var isAvailable: Bool
        var unAvailableReason: String?
        var state: SubscribeStatus
        var calendarID: String
        var name: String {
            if canUseResourceNameWithLevelInfo {
                return searchItem.meetingRoom.resourceNameWithLevelInfo[0]
            } else if !searchItem.meetingRoom.floorName.isEmpty {
                return "\(searchItem.meetingRoom.floorName)-\(searchItem.meetingRoom.name)"
            } else {
                return searchItem.meetingRoom.name
            }
        }
        var needsApproval: Bool {
            shouldShowApprovalTag && searchItem.meetingRoom.needsApproval
        }
        var capacityDesc: String { "\(searchItem.meetingRoom.capacity)" }
        var location: String
        var isSelected: SelectType? { return nil }
        var shouldShowApprovalTag: Bool
        var isHierarchical: Bool {
            searchItem.meetingRoom.displayType == .hierarchical
        }
        var pathName: String {
            canUseResourceNameWithLevelInfo ? searchItem.meetingRoom.resourceNameWithLevelInfo[1] : ""
        }

        var canUseResourceNameWithLevelInfo: Bool {
            isHierarchical && searchItem.meetingRoom.resourceNameWithLevelInfo.count == 2
        }
    }

    func numberOfRows() -> Int {
        return cellDataArray.count
    }

    func cellData(at index: Int) -> CellData? {
        guard index >= 0 && index < cellDataArray.count else {
            return nil
        }
        return cellDataArray[index]
    }

    func meetingRoom(at row: Int) -> CalendarMeetingRoom? {
        guard row >= 0 && row < cellDataArray.count else {
            assertionFailure()
            return nil
        }
        let searchItem = cellDataArray[row].searchItem
        return CalendarMeetingRoom.makeMeetingRoom(
            fromResource: searchItem.meetingRoom,
            buildingName: searchItem.building.name,
            tenantId: tenantId
        )
    }

}

// MARK: Subscribe
extension MeetingRoomSearchViewModel {
    func changeSubscribeState(at index: Int) {
        guard let cellData = cellData(at: index) else {
            assertionFailure()
            return
        }
        /// 点击订阅/退订埋点
        if cellData.state == .subscribed || cellData.state == .noSubscribe {
            CalendarTracerV2.CalendarSubscribe.traceClick {
                let subscribed = (cellData.state == .subscribed)
                $0
                    .click(subscribed ? "unsubscribe_resource_cal" : "subscribe_resource_cal")
                    .target("none")
                $0.calendar_id = cellData.calendarID
            }
        }
        let nextStatues = cellData.state.nextStatus()
        if nextStatues == .subscribing {
            changeSubscribeState(at: index, state: nextStatues)
            meetingRoomApi?
                .subscribeCalendar(with: cellData.calendarID)
                .delay(.milliseconds(330), scheduler: MainScheduler.instance)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_) in
                    guard let self = self else { return }
                    self.changeSubscribeState(at: index, state: nextStatues.nextStatus())
                    self.onSubscribeSuccess?(BundleI18n.Calendar.Calendar_SubscribeCalendar_OperationSucceeded)
                }, onError: { [weak self] (error) in
                    self?.changeSubscribeState(at: index, state: nextStatues.preStatus())
                    switch error.errorType() {
                    case .subscribeCalendarExceedTheUpperLimitErr:
                        self?.onSubscribeError?(BundleI18n.Calendar.Calendar_SubscribeCalendar_NumLimit)
                    case .exceedMaxVisibleCalNum:
                        self?.onSubscribeError?(BundleI18n.Calendar.Calendar_Detail_TooMuchViewReduce)
                    default:
                        self?.onSubscribeError?(BundleI18n.Calendar.Calendar_SubscribeCalendar_OperationFailed)
                    }
                }).disposed(by: disposeBag)
        } else if nextStatues == .unSubscribing {
            changeSubscribeState(at: index, state: nextStatues)
            meetingRoomApi?.unsubscribeCalendar(with: cellData.calendarID)
                .delay(.milliseconds(330), scheduler: MainScheduler.instance)
                .observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] response in
                    guard let self = self else { return }
                    if response.code != 0 {
                        self.changeSubscribeState(at: index, state: nextStatues.preStatus())
                        self.rxAlert.accept((response.alertTitle, response.alertContent))
                        CalendarTracerV2.CalendarNoUnsubscribe.traceView {
                            $0.calendar_id = cellData.calendarID
                        }
                        return
                    }
                    self.changeSubscribeState(at: index, state: nextStatues.nextStatus())
                    self.onSubscribeSuccess?(BundleI18n.Calendar.Calendar_SubscribeCalendar_OperationSucceeded)
                }, onError: { [weak self] (_) in
                    self?.changeSubscribeState(at: index, state: nextStatues.preStatus())
                    self?.onSubscribeError?(BundleI18n.Calendar.Calendar_SubscribeCalendar_OperationFailed)
                }).disposed(by: disposeBag)
        }
    }

    private func changeSubscribeState(at index: Int, state: SubscribeStatus) {
        guard var cellData = cellData(at: index) else {
            assertionFailure()
            return
        }

        cellData.state = state
        cellDataArray.replaceSubrange(index..<index + 1, with: [cellData])
        onAllCellDataUpdate?()
    }
}
