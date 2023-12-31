//
//  MeetingRoomFoldViewModel.swift
//  Calendar
//
//  Created by 朱衡 on 2021/1/20.
//

import EventKit
import RxSwift
import RxCocoa
import RxRelay
import LarkContainer
import LKCommonsLogging

// 会议室查询：
//          日程添加会议室: 限定起止时间 & rrule
//          搜索会议室: 不限定起止时间 & rrule
//          订阅会议室: 不限定起止时间 & rrule
// DataFlow:
//          rxMinCapacity        -> reloadAllUnfoldBulidings
//          rxNeedEquipments     -> reloadAllUnfoldBulidings
//          rxBuildings          -> onAllCellDataUpdate
//          reloadMeetingRoom    -> onAllCellDataUpdate
//          changeSubscribeState -> onAllCellDataUpdate

typealias MeetingRoomCellDataType = EventMeetingRoomCellDataType & SubscribeMeetingRoomCellDataType
typealias BuildingID = String
typealias MeetingRoomID = String
typealias SelectStateDiff = (resultBuildingMap: [BuildingID: SelectType], resultRoomMap: [MeetingRoomID: SelectType])

enum TrackerFromType {
    case eventEdit
    case subscribeCalendar
    case `default`
}

final class MeetingRoomFoldViewModel: UserResolverWrapper {
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    let logger = Logger.log(MeetingRoomFoldViewModel.self, category: "Calendar.MeetingRoom")

    let userResolver: UserResolver
    var onAllCellDataUpdate: (() -> Void)?
    var onSubscribeSuccess: ((_ toastInfo: String) -> Void)?
    var onSubscribeError: ((_ toastInfo: String) -> Void)?

    let rxAlert = PublishRelay<(String, String)>()

    // 会议室多选
    let rxMultiSelect = BehaviorRelay<Bool>(value: false)
    let rxBuildingSelectedMap: BehaviorRelay<[BuildingID: SelectType]>?
    let rxMeetingRoomSelectedMap: BehaviorRelay<[MeetingRoomID: SelectType]>?
    let rxAllMeetingRooms: BehaviorRelay<[Building]>?
    let rxSelectAll: BehaviorRelay<SelectType>?
    let reloadAllUnfoldBulidingsSuject = PublishSubject<Void>()
    var multiSelectBuildingCellDataList: [BuildingRoomCellData] = []  // 所有会议室数据，和单选会议室数据隔离
    let rxIsBuildingsEmpty: BehaviorRelay<Bool> = .init(value: false)

    private let rxBuildings: BehaviorRelay<[Rust.Building]>
    private var singleSelectBuildingCellDataList: [BuildingRoomCellData] = []
    private let meetingRoomApi: CalendarRustAPI?
    private var lastBuildingLoadingDisposable: Disposable?

    let disposeBag: DisposeBag = DisposeBag()
    let rrule: EventRecurrenceRule?
    let eventConditions: (approveDisabled: Bool, formDisabled: Bool)
    let meetingRoomWithFormDisableReason: String
    private let startDate: Date
    let endDate: Date
    let timezone: TimeZone?
    private let tenantId: String
    private let hideUnavailable: Bool
    private let rxNeedEquipments: BehaviorRelay<[String]>
    private let rxMinCapacity: BehaviorRelay<Int>
    var eventParam: CommonParamData?
    var endDateEditable: Bool?

    init(userResolver: UserResolver,
         meetingRoomApi: CalendarRustAPI?,
         startDate: Date = Date(timeIntervalSince1970: 0),
         endDate: Date = Date(timeIntervalSince1970: 0),
         timezone: TimeZone? = nil,
         tenantId: String,
         hideUnavailable: Bool,
         rrule: EventRecurrenceRule? = nil,
         eventConditions: (approveDisabled: Bool, formDisabled: Bool) = (false, false),
         meetingRoomWithFormDisableReason: String = "",
         rxNeedEquipments: BehaviorRelay<[String]>,
         rxMinCapacity: BehaviorRelay<Int>,
         rxBuildings: BehaviorRelay<[Rust.Building]>,
         rxQuery: BehaviorRelay<String>? = nil,
         rxMultiSelectTrigger: Observable<Bool>? = nil,
         rxBuildingSelectedMap: BehaviorRelay<[BuildingID: SelectType]>? = nil,
         rxMeetingRoomSelectedMap: BehaviorRelay<[MeetingRoomID: SelectType]>? = nil,
         rxAllMeetingRooms: BehaviorRelay<[Building]>? = nil,
         rxSelectAll: BehaviorRelay<SelectType>? = nil) {
        self.userResolver = userResolver
        self.meetingRoomApi = meetingRoomApi
        self.startDate = startDate
        self.endDate = endDate
        self.hideUnavailable = hideUnavailable
        self.tenantId = tenantId
        self.rrule = rrule
        self.timezone = timezone
        self.eventConditions = eventConditions
        self.meetingRoomWithFormDisableReason = meetingRoomWithFormDisableReason
        self.rxNeedEquipments = rxNeedEquipments
        self.rxMinCapacity = rxMinCapacity
        self.rxBuildings = rxBuildings
        self.rxBuildingSelectedMap = rxBuildingSelectedMap
        self.rxMeetingRoomSelectedMap = rxMeetingRoomSelectedMap
        self.rxAllMeetingRooms = rxAllMeetingRooms
        self.rxSelectAll = rxSelectAll

        rxNeedEquipments.debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .skip(1)
            .whenNot(rxMultiSelect)
            .distinctUntilChanged()
            .bind { [weak self] (_) in
                self?.reloadAllUnfoldBulidings()
            }.disposed(by: disposeBag)

        rxMinCapacity.debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .skip(1)
            .whenNot(rxMultiSelect)
            .distinctUntilChanged()
            .bind { [weak self] (_) in
                self?.reloadAllUnfoldBulidings()
            }.disposed(by: disposeBag)

        rxBuildings.bind { [weak self] (buildings) in
            // 建筑物更改全量刷新
            guard let self = self else { return }
            self.buildingCellDataList = buildings.map { BuildingRoomCellData(building: Selectable($0, isSelected: self.rxMultiSelect.value ? .nonSelected : nil)) } ?? []
            self.onAllCellDataUpdate?()
        }.disposed(by: disposeBag)
        
        reloadAllUnfoldBulidingsSuject.debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .bind { [weak self] in
                self?.reloadAllUnfoldBulidings()
            }.disposed(by: disposeBag)

        rxBuildings.map { $0.isEmpty }
            .bind(to: rxIsBuildingsEmpty)
            .disposed(by: disposeBag)

        observeMultiSelect()

        // 搜索完成后重新刷新，避免搜索页订阅后不同步的问题
        rxQuery?.debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .skip(1)
            .whenNot(rxMultiSelect)
            .distinctUntilChanged()
            .bind { [weak self] (query) in
                if query.isEmpty {
                    self?.reloadAllUnfoldBulidings()
                }
            }.disposed(by: disposeBag)

        rxMultiSelectTrigger?.bind(to: rxMultiSelect)
    }

    private func reloadAllUnfoldBulidings() {
        for i in 0..<self.buildingCellDataList.count {
            if case .uninitialized = self.buildingCellDataList[i].state {
                continue
            }
            self.reloadMeetingRoom(at: i, from: .default, needTrack: false)
        }
    }

    var buildingCellDataList: [BuildingRoomCellData] {
        get {
            rxMultiSelect.value ? multiSelectBuildingCellDataList : singleSelectBuildingCellDataList
        }
        set {
            rxMultiSelect.value ? (multiSelectBuildingCellDataList = newValue) : (singleSelectBuildingCellDataList = newValue)
        }
    }

    var isMultiSelecting: Bool {
        return rxMultiSelect.value
    }
}

// MARK: Data inputs
extension MeetingRoomFoldViewModel {
    func dropMeetingRoom(at buildingIndex: Int) {
        guard var building = buildingCellDataList[safeIndex: buildingIndex] else { return }
        building.disposeBag = DisposeBag()

        if rxMultiSelect.value == true {
            // 多选直接收起
            if case let .loaded(data, fold) = building.state {
                building = BuildingRoomCellData(building: building.building,
                                                           state: .loaded(data, !fold))
            }
        } else {
            building.state = .uninitialized
        }

        buildingCellDataList.replaceSubrange(buildingIndex..<buildingIndex + 1, with: [building])
        onAllCellDataUpdate?()
    }

    func reloadMeetingRoom(at buildingIndex: Int, from: TrackerFromType, needTrack: Bool) {
        guard var building = buildingCellDataList[safeIndex: buildingIndex] else { return }
        building.disposeBag = DisposeBag()

        func produceBuildingData(at index: Int = buildingIndex, with building: BuildingRoomCellData) {
            buildingCellDataList.replaceSubrange(index..<index + 1, with: [building])
            onAllCellDataUpdate?()
        }

        if rxMultiSelect.value == true {
            // 多选直接展开
            if case let .loaded(data, fold) = building.state {
                let toggledBuilding = BuildingRoomCellData(building: building.building,
                                                           state: .loaded(data, !fold))

                produceBuildingData(with: toggledBuilding)
            }
            return
        }

        building.state = .loading
        if needTrack {
            CalendarMonitorUtil.startTrackExpandBuildingSectionTime(from: from)
        }
        produceBuildingData(with: building)
        // 对于含有重复性规则的日程，审批类会议室不可用
        let isAvailableForMeetingRoomThatNeedsApproval = (rrule == nil)
        let isDisableForMeetingRoomThatHasForm = eventConditions.formDisabled
        let meetingRoomWithFormunAvailableReason = meetingRoomWithFormDisableReason
        let userCalendarIDs: [String] = calendarManager?.allCalendars.map { $0.serverId } ?? []
        meetingRoomApi?.getMeetingRooms(inBuilding: building.building.raw.id,
                                       tenantId: tenantId,
                                       startDate: startDate,
                                       endDate: endDate,
                                       rruleStr: rrule?.iCalendarString(),
                                       needDisabledResource: false,
                                       minCapacity: Int32(rxMinCapacity.value),
                                       needEquipments: rxNeedEquipments.value)
            .delay(.milliseconds(200), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (meetingRooms, adjustTimeInfo) in
                guard let self = self else { return }
                let meetingRooms = meetingRooms
                    .reform(self.reformMeetingRoom)
                    .map { (meetingRoom) -> MeetingRoomCellData in
                        var isAvailable = meetingRoom.status == .free
                        var unAvailableReason: String?
                        if meetingRoom.schemaExtraData.cd.resourceCustomization != nil, isDisableForMeetingRoomThatHasForm {
                            // 编辑前置下，编辑此次和编辑后续不可以选择表单会议室
                            isAvailable = false
                            unAvailableReason = meetingRoomWithFormunAvailableReason
                        }
                        if meetingRoom.needsApproval, !isAvailableForMeetingRoomThatNeedsApproval {
                            // 全量审批和重复性互斥
                            isAvailable = false
                            unAvailableReason = I18n.Calendar_Approval_RecurToast
                        }

                        if !isAvailableForMeetingRoomThatNeedsApproval,
                           meetingRoom.shouldTriggerApproval(duration: Int64(self.endDate.timeIntervalSince(self.startDate))),
                           let trigger = meetingRoom.schemaExtraData.cd.conditionalApprovalTriggerDuration {
                            // 触发了条件审批的会议室 和 rrule 互斥
                            let duration = Double(trigger) / 3600.0
                            isAvailable = false
                            unAvailableReason = I18n.Calendar_Rooms_CantReserveOverTime(num: String(format: "%g", duration))
                        }

                        let status: SubscribeStatus = userCalendarIDs.contains(meetingRoom.calendarID) ? .subscribed : .noSubscribe

                        return MeetingRoomCellData(meetingRoom: Selectable(meetingRoom, isSelected: nil), buildingName: building.building.raw.name, isAvailable: isAvailable, unAvailableReason: unAvailableReason, state: status)
                    }
                if needTrack {
                    CalendarMonitorUtil.endTrackExpandBuildingSectionTime()
                    SlaMonitor.traceSuccess(.EventAddMeetingRoom, action: "expand_meeting", source: "meeting")
                }
                building.state = .success(meetingRooms, info: adjustTimeInfo[building.building.raw.id])
                produceBuildingData(with: building)
            }, onError: { error in
                building.state = .error
                produceBuildingData(with: building)
                SlaMonitor.traceFailure(.EventAddMeetingRoom, error: error, action: "expand_meeting", source: "meeting")
            }).disposed(by: building.disposeBag)
    }

    // 先排序、再过滤
    func reformMeetingRoom(_ rooms: [Rust.MeetingRoom]) -> [Rust.MeetingRoom] {
        // 对于含有重复性规则的日程，审批类会议室不可用
        let isAvailableForMeetingRoomThatNeedsApproval = (rrule == nil)
        let hideUnavailable = self.hideUnavailable
        let locale = Locale(identifier: "zh")
        return rooms
            .sorted(by: {
            if $0.weight != $1.weight {
                return $0.weight > $1.weight
            }
            return $0.name.compare($1.name, locale: locale) == .orderedAscending
        })
        .filter { meetingRoom in
            if !hideUnavailable {
                return true
            }
            guard meetingRoom.status == .free else { return false }
            guard !meetingRoom.needsApproval || isAvailableForMeetingRoomThatNeedsApproval else {
                return false
            }
            guard meetingRoom.schemaExtraData.cd.resourceCustomization == nil || !eventConditions.formDisabled else {
                return false
            }
            return true
        }
    }
}

// MARK: ViewData
extension MeetingRoomFoldViewModel {
    enum CellDataType {
        case meetingRoom(MeetingRoomCellDataType)
        case loading
        case retry
        case empty
        // 一键调整的cell
        case autoJustTime(info: Rust.LevelAdjustTimeInfo?)
        case none
    }

    struct MeetingRoomCellData: MeetingRoomCellDataType {
        var meetingRoom: Selectable<Rust.MeetingRoom>
        var buildingName: String
        var isAvailable: Bool
        var unAvailableReason: String?
        var state: SubscribeStatus
        var name: String {
            if !meetingRoom.raw.floorName.isEmpty {
                return "\(meetingRoom.raw.floorName)-\(meetingRoom.raw.name)"
            } else {
                return meetingRoom.raw.name
            }
        }
        var needsApproval: Bool { meetingRoom.raw.needsApproval }
        var capacityDesc: String { String(meetingRoom.raw.capacity) }
        var location: String { buildingName }
        var isSelected: SelectType? { return meetingRoom.isSelected }
        var pathName: String {
            ""
        }
    }

    struct BuildingRoomCellData: FoldingBuildingCellDataType {
        enum StateEnum {
            case uninitialized
            case loading
            case success([MeetingRoomCellData], info: Rust.LevelAdjustTimeInfo?)
            case error
            // 多选会议室，一次性数据
            case loaded([MeetingRoomCellData], Bool)
        }

        var building: Selectable<Rust.Building>
        var state: StateEnum = .uninitialized
        var disposeBag: DisposeBag = DisposeBag()

        // FoldingBuildingCellDataType
        var isUnFold: Bool {
            if case .uninitialized = state {
                return false
            }
            if case let .loaded(_, fold) = state {
                return !fold
            }
            return true
        }
        var title: String { return building.raw.name }
        var isSelected: SelectType? { return building.isSelected }
    }

    func numberOfBuildings() -> Int {
        return buildingCellDataList.count
    }

    func numberOfRowsInSection(_ section: Int) -> Int {
        guard let building = buildingCellDataList[safeIndex: section] else { return 1 }

        switch building.state {
        case let .success(cellDatas, _):
            if cellDatas.count > 1 {
                return cellDatas.count
            }
            return 1
        case let .loaded(cellDatas, fold):
            if cellDatas.count > 1 && !fold {
                return cellDatas.count
            }
            return 1
        case .error, .loading:
            return 1
        case .uninitialized:
            return 1
        }
        return 1
    }

    func buildingCellData(at index: Int) -> FoldingBuildingCellDataType? {
        guard let building = buildingCellDataList[safeIndex: index] else { return nil }
        return building
    }

    func meetingRoomCellData(in indexPath: IndexPath) -> CellDataType? {
        guard let building = buildingCellDataList[safeIndex: indexPath.section] else { return nil }

        switch building.state {
        case .loading:
            return .loading
        case .error:
            return .retry
        case .uninitialized:
            return nil
        case .success(let cellDatas, let info):
            guard indexPath.row < cellDatas.count else {
                logger.info("meetingRoomCellData, needAdjustTime = \(info?.needAdjustTime ?? false), fg = \(FG.calendarRoomsReservationTime), endDateEditable = \(self.endDateEditable == true) ")
                if let info = info,
                   info.needAdjustTime == true,
                   FG.calendarRoomsReservationTime,
                   self.endDateEditable == true {
                    return .autoJustTime(info: info)
                }
                return .empty
            }
            let data = cellDatas[indexPath.row]
            return .meetingRoom(data)
        case let .loaded(datas, folded):
            if folded {
                return nil
            }
            guard indexPath.row < datas.count else {
                return .empty
            }
            let data = datas[indexPath.row]
            return .meetingRoom(data)
        }
    }

}

// MARK: ViewAction
extension MeetingRoomFoldViewModel {

    func meetingRoomCellData(at indexPath: IndexPath) -> MeetingRoomCellData? {
        if let building = buildingCellDataList[safeIndex: indexPath.section] {
            switch building.state {
            case let .success(data, _),
                 let .loaded(data, _):
                return data[safeIndex: indexPath.row]
            default:
                return nil
            }
        }
        return nil
    }

    func meetingRoom(at indexPath: IndexPath) -> CalendarMeetingRoom? {
        guard indexPath.section < buildingCellDataList.count else {
            assertionFailure()
            return nil
        }

        let building = buildingCellDataList[indexPath.section]
        switch building.state {
        case let .success(data, _),
             let .loaded(data, _):
            if let pbResource = data[safeIndex: indexPath.row]?.meetingRoom {
                return CalendarMeetingRoom.makeMeetingRoom(
                    fromResource: pbResource.raw,
                    buildingName: building.building.raw.name,
                    tenantId: tenantId
                )
            }
        default:
            assertionFailure()
            return nil
        }
        return nil
    }

}

// MARK: Subscibe
extension MeetingRoomFoldViewModel {
    func changeSubscribeState(at indexPath: IndexPath) {
           guard indexPath.section < buildingCellDataList.count else {
               assertionFailure()
               return
           }

           let building = buildingCellDataList[indexPath.section]
            if case .success(let cellDatas, _) = building.state,
              let cellData = cellDatas[safeIndex: indexPath.row] {
               let data = cellData
                /// 点击订阅/退订埋点
                if data.state == .subscribed || data.state == .noSubscribe {
                    CalendarTracerV2.CalendarSubscribe.traceClick {
                        let subscribed = (data.state == .subscribed)
                        $0
                            .click(subscribed ? "unsubscribe_resource_cal" : "subscribe_resource_cal")
                            .target("none")
                        $0.calendar_id = data.meetingRoom.raw.calendarID
                    }
                }
               let nextStatues = data.state.nextStatus()
               if nextStatues == .subscribing {
                   changeSubscribeState(at: indexPath, state: nextStatues)
                   meetingRoomApi?
                    .subscribeCalendar(with: data.meetingRoom.raw.calendarID)
                       .delay(.milliseconds(330), scheduler: MainScheduler.instance)
                       .observeOn(MainScheduler.instance)
                       .subscribe(onNext: { [weak self] (_) in
                           guard let self = self else { return }
                           self.changeSubscribeState(at: indexPath, state: nextStatues.nextStatus())
                           self.onSubscribeSuccess?(BundleI18n.Calendar.Calendar_SubscribeCalendar_OperationSucceeded)
                       }, onError: { [weak self] (error) in
                           self?.changeSubscribeState(at: indexPath, state: nextStatues.preStatus())
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
                   changeSubscribeState(at: indexPath, state: nextStatues)
                meetingRoomApi?.unsubscribeCalendar(with: data.meetingRoom.raw.calendarID)
                       .delay(.milliseconds(330), scheduler: MainScheduler.instance)
                       .observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] response in
                           guard let self = self else { return }
                           if response.code != 0 {
                               self.rxAlert.accept((response.alertTitle, response.alertContent))
                               CalendarTracerV2.CalendarNoUnsubscribe.traceView {
                                   $0.calendar_id = data.meetingRoom.raw.calendarID
                               }
                               return
                           }
                           self.changeSubscribeState(at: indexPath, state: nextStatues.nextStatus())
                           self.onSubscribeSuccess?(BundleI18n.Calendar.Calendar_SubscribeCalendar_OperationSucceeded)
                       }, onError: { [weak self] (_) in
                           self?.changeSubscribeState(at: indexPath, state: nextStatues.preStatus())
                           self?.onSubscribeError?(BundleI18n.Calendar.Calendar_SubscribeCalendar_OperationFailed)
                       }).disposed(by: disposeBag)
               }
           }
       }

       private func changeSubscribeState(at indexPath: IndexPath, state: SubscribeStatus) {
           guard indexPath.section < buildingCellDataList.count else {
               assertionFailure()
               return
           }

           var building = buildingCellDataList[indexPath.section]
           if case .success(var cellDatas, let info) = building.state,
              var cellData = cellDatas[safeIndex: indexPath.row] {
               cellData.state = state
               cellDatas.replaceSubrange(indexPath.row..<indexPath.row + 1, with: [cellData])
               building.state = .success(cellDatas, info: info)
               buildingCellDataList.replaceSubrange(indexPath.section..<indexPath.section + 1, with: [building])
               onAllCellDataUpdate?()
           }
       }
    
    func changeRRuleEndDate(_ date: Date) {
        self.rrule?.recurrenceEnd = EventRecurrenceEnd(end: date)
    }
}

extension Array where Element == Rust.MeetingRoom {
    func reform(_ transform: ((Self) -> Self)) -> Self {
        return transform(self)
    }
}
