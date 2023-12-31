//
//  MeetingRoomContainerViewModel.swift
//  Calendar
//
//  Created by zhuheng on 2021/1/22.
//

import Foundation
import RxSwift
import RxRelay
import LarkContainer

// [日程添加会议室、大搜-搜索会议室、订阅会议室] 复用
// DataFlow:
//         getResourceEquipments    -> rxEquipmentListViewData
//                                  -> rxMeetingRoomFilterViewData
//         getMeetingRoomBuildings  -> rxBuildings
//         updateNeededEquipments     -> rxMinCapacity
//         updateMiniCapacity       -> rxNeedEquipments
//         resetFilter              -> rxMeetingRoomFilterViewData
//                                  -> onFilterReset
final class MeetingRoomContainerViewModel: UserResolverWrapper {
    private struct FilterViewData: MeetingRoomFilterViewDataType {
        var equipment: String?
        var capacity: String?
        var showAvailableRooms: Bool?
    }

    private struct EquipmentViewData: EquipmentSelectorViewDataType {
        var equipmentInfos: [(equipment: String, isSelected: Bool)]
    }

    enum ViewState {
        case loading      // 加载中
        case buildingData // 建筑物数据
        case failed       // 加载失败
    }

    enum NavigationViewState: Equatable {
        /// 无多选
        case normal
        /// 支持多选
        case normalMultiSelect
        /// 支持多选 - 处于多选状态
        case multiSelecting(_ selectCount: Int)

        var isMultiSelecting: Bool {
            if case .multiSelecting = self {
                return true
            }
            return false
        }
    }

    enum LoadingItem {
        case none
        case loading(String)
        case failed(String)
    }

    let rxViewState = BehaviorRelay<ViewState>(value: .loading)
    let rxBuildings = BehaviorRelay<[Rust.Building]>(value: [])
    let rxNeedEquipments = BehaviorRelay<[String]>(value: [])
    let rxMinCapacity = BehaviorRelay<Int>(value: 0)
    // 仅供灵活层级 filter 使用
    let rxAvailableRoomsOnly = BehaviorRelay<Bool>(value: true)
    let rxEquipmentListViewData = BehaviorRelay<EquipmentSelectorViewDataType?>(value: nil)
    let rxMeetingRoomFilterViewData = BehaviorRelay<MeetingRoomFilterViewDataType?>(value: nil)
    let rxNavigationState = BehaviorRelay<NavigationViewState>(value: .normal)
    let rxLoading = BehaviorRelay<LoadingItem>(value: .none)
    let rxMultiSelectConfirm = PublishRelay<[CalendarMeetingRoom]>()

    // 会议室多层级
    let rxMultiLevelSelectedMeetingRooms = PublishRelay<[Rust.MeetingRoom]>()
    let rxMultiLevelSelectionConfirmed = PublishSubject<Void>()

    var onFilterReset: (() -> Void)?
    let actionSource: MeetingRoomActionSource // 区分业务场景，可用于走不通的埋点&业务逻辑
    let rrule: EventRecurrenceRule?
    let eventConditions: (approveDisabled: Bool, formDisabled: Bool)
    let meetingRoomWithFormUnAvailableReason: String
    let startDate: Date?
    let endDate: Date?
    let timezone: TimeZone?
    let tenantID: String
    let multiLevelResources: Bool
    let enableMultiSelect: Bool
    private let disposeBag = DisposeBag()
    private var equipments: [Rust.EquipmentExpand] = []
    private(set) var buildings: [Rust.Building] = []
    private var lastBuildingLoadingDisposable: Disposable?
    private var lastEquipmentLoadingDisposable: Disposable?

    // 会议室多选数据 控制子页面数据联动（可用+所有）
    let rxIsMultiSelect: Observable<Bool>
    let rxBuildingSelectedMap = BehaviorRelay<[BuildingID: SelectType]>(value: [:])
    let rxMeetingRoomSelectedMap = BehaviorRelay<[MeetingRoomID: SelectType]>(value: [:])
    let rxAllBuildings = BehaviorRelay<[Building]>(value: [])
    let rxSelectAll = BehaviorRelay<SelectType>(value: .nonSelected)
    private let rxRawAllBuildings = BehaviorRelay<[Building]>(value: []) /// 未筛选的原始所有会议室信息
    let userResolver: UserResolver
    @ScopedInjectedLazy
    var meetingRoomApi: CalendarRustAPI?

    /// 灵活层级埋点
    var eventParam: CommonParamData?
    // endDate是否可编辑
    let endDateEditable: Bool?

    init(userResolver: UserResolver,
         tenantID: String,
         rrule: EventRecurrenceRule? = nil,
         eventConditions: (approveDisabled: Bool, formDisabled: Bool) = (false, false),
         meetingRoomWithFormUnAvailableReason: String = "",
         startDate: Date? = nil,
         endDate: Date? = nil,
         timezone: TimeZone? = nil,
         multiLevelResources: Bool = false,
         enableMultiSelectMeetingRoom: Bool = false,
         actionSource: MeetingRoomActionSource,
         endDateEditable: Bool? = nil) {
        self.userResolver = userResolver
        self.tenantID = tenantID
        self.timezone = timezone
        self.rrule = rrule
        self.endDateEditable = endDateEditable
        self.eventConditions = eventConditions
        self.meetingRoomWithFormUnAvailableReason = meetingRoomWithFormUnAvailableReason
        self.startDate = startDate
        self.endDate = endDate
        self.multiLevelResources = multiLevelResources
        self.enableMultiSelect = enableMultiSelectMeetingRoom
        self.actionSource = actionSource

        rxIsMultiSelect = rxNavigationState.map { $0.isMultiSelecting }

        /// 导航栏已选数字
        rxMeetingRoomSelectedMap.bind { [weak self] map in
            guard let self = self else { return }
            let selectCount = map.values.filter { $0 == .selected }.count
            if self.rxNavigationState.value.isMultiSelecting {
                self.rxNavigationState.accept(.multiSelecting(selectCount))
            }
        }.disposed(by: disposeBag)

        /// 筛选条件变更，或源数据变更，直接重置所有数据
        Observable.combineLatest(rxMinCapacity, rxNeedEquipments, rxAvailableRoomsOnly, rxRawAllBuildings)
            .filter { [weak self] _ in self?.rxNavigationState.value.isMultiSelecting ?? false }
            .bind { [weak self] (capacity, _, _, rawAllBuildings) in
                guard let self = self else { return }
                let filterBuildings = rawAllBuildings.map { building in
                    Building(building: building.building,
                             rooms:
                                building.rooms.filter { room -> Bool in
                                    let roomEquipments = room.equipments.map { r in return r.id }
                                    return room.capacity >= capacity &&
                                        Set(roomEquipments).isSuperset(of: self.rxNeedEquipments.value)
                                }
                    )
                }
                self.rxBuildingSelectedMap.accept([:])
                self.rxMeetingRoomSelectedMap.accept([:])
                self.rxAllBuildings.accept(filterBuildings)
            }.disposed(by: disposeBag)

        loadNaviState()
    }

    func loadEquipment() {
        guard (rxEquipmentListViewData.value?.equipmentInfos) == nil else { return }
        lastEquipmentLoadingDisposable = meetingRoomApi?.getResourceEquipments()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] equipments in
                guard let self = self else { return }
                let equipmentInfos = equipments.map { (equipment: $0.equipment.i18NName, isSelected: false) }
                self.equipments = equipments
                self.updateNeededEquipments(with: [])

                self.rxEquipmentListViewData.accept(EquipmentViewData(equipmentInfos: equipmentInfos))
            })
    }

    func updateNeededEquipments(with indexs: [Int]) {
        guard !equipments.isEmpty else { return }

        var IDs = [String]()
        var names = [String]()
        indexs.forEach { (index) in
            if let equipment = equipments[safeIndex: index] {
                IDs.append(equipment.id)
                names.append(equipment.equipment.i18NName)
            }
        }

        rxNeedEquipments.accept(IDs)
        let oldFilterViewData = rxMeetingRoomFilterViewData.value
        var newFilterViewData = FilterViewData()
        newFilterViewData.equipment = names.joined(separator: " · ")
        newFilterViewData.capacity = oldFilterViewData?.capacity
        newFilterViewData.showAvailableRooms = oldFilterViewData?.showAvailableRooms
        rxMeetingRoomFilterViewData.accept(newFilterViewData)

        CalendarTracer.shared.calMeetingRoomFilterSaved(actionSource: actionSource.rawValue,
                                                        chooseInfo: equipmentChooseInfo(),
                                                        smallTargetValue: rxMinCapacity.value)
    }

    func updateMiniCapacity(with count: Int) {
        let oldFilterViewData = rxMeetingRoomFilterViewData.value
        var newFilterViewData = FilterViewData()
        newFilterViewData.equipment = oldFilterViewData?.equipment
        // swiftlint:disable empty_count
        newFilterViewData.capacity = count == 0 ? nil : String(count)
        // swiftlint:enable empty_count
        newFilterViewData.showAvailableRooms = oldFilterViewData?.showAvailableRooms
        rxMeetingRoomFilterViewData.accept(newFilterViewData)

        rxMinCapacity.accept(count)

        CalendarTracer.shared.calMeetingRoomFilterSaved(actionSource: actionSource.rawValue,
                                                        chooseInfo: equipmentChooseInfo(),
                                                        smallTargetValue: rxMinCapacity.value)
    }

    func toggleAvailableRoomsOnly() {
        rxAvailableRoomsOnly.toggle()
        let oldFilterViewData = rxMeetingRoomFilterViewData.value
        var newFilterViewData = FilterViewData()
        newFilterViewData.equipment = oldFilterViewData?.equipment
        newFilterViewData.capacity = oldFilterViewData?.capacity
        newFilterViewData.showAvailableRooms = rxAvailableRoomsOnly.value
        rxMeetingRoomFilterViewData.accept(newFilterViewData)
        if FG.supportLevelPinTop {
            let clickParam = rxAvailableRoomsOnly.value ? "available_resource" : "all_resource"
            CalendarTracerV2.EventAddResource.traceClick {
                $0.click(clickParam)
                $0.mergeEventCommonParams(commonParam: eventParam ?? .init())
            }
        }
    }

    func equipmentChooseInfo() -> [String: String] {
        var equipmentChooseInfo: [String: String] = [:]
        equipments.forEach { (equipment) in
            if rxNeedEquipments.value.contains(equipment.id) {
                equipmentChooseInfo[equipment.equipment.equipmentType] = "yes"
            } else {
                equipmentChooseInfo[equipment.equipment.equipmentType] = "no"
            }
        }
        return equipmentChooseInfo
    }

    func resetFilter() {
        var filterViewData = FilterViewData()
        filterViewData.equipment = equipments.isEmpty ? nil : ""
        filterViewData.showAvailableRooms = multiLevelResources && actionSource == .fullEventEditor ? false : nil
        rxMeetingRoomFilterViewData.accept(filterViewData)
        rxAvailableRoomsOnly.accept(false)
        rxMinCapacity.accept(0)
        rxNeedEquipments.accept([])
        onFilterReset?()
    }

    func loadBuilding() {
        lastBuildingLoadingDisposable?.dispose()
        rxViewState.accept(.loading)
        lastBuildingLoadingDisposable = meetingRoomApi?.getMeetingRoomBuildings()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] pbBuildings in
                    guard let self = self else { return }
                    let locale = Locale(identifier: "zh")
                    let buildings = pbBuildings
                        .sorted(by: {
                            if $0.weight != $1.weight {
                                return $0.weight > $1.weight
                            }
                            return $0.name.compare($1.name, locale: locale) == .orderedAscending
                        })
                    self.buildings = buildings
                    self.rxBuildings.accept(self.buildings)
                    self.rxViewState.accept(.buildingData)
                    if !self.multiLevelResources {
                        SlaMonitor.traceSuccess(.EventAddMeetingRoom, action: "load_building", source: "meeting")
                    }
                },
                onError: { [weak self] error in
                    guard let self = self else { return }
                    self.rxViewState.accept(.failed)
                    if !self.multiLevelResources {
                        SlaMonitor.traceFailure(.EventAddMeetingRoom, error: error, action: "load_building", source: "meeting")
                    }
                }
            )
        if multiLevelResources {
            rxMeetingRoomFilterViewData.accept(FilterViewData(showAvailableRooms: rxAvailableRoomsOnly.value))
        }
    }
}

// MARK: - Navibar
extension MeetingRoomContainerViewModel {

    enum NavibarAction {
        /// 切换为多选
        case multiSelect
        /// 多选确定
        case multiSelectConfirm
        /// 切换回单选
        case multiSelectCancel
    }

    func tapAction(_ action: NavibarAction) {
        switch action {
        case .multiSelect: tapMultiSelect()
        case .multiSelectConfirm: tapMultiSelectConfirm()
        case .multiSelectCancel: tapMultiSelectCancel()
        }
    }

    func toggleSelectAll() {
        rxSelectAll.accept(rxSelectAll.value.toggle())
    }

    private func loadNaviState() {
        let enableMultiSelect = enableMultiSelect && actionSource == .fullEventEditor && rrule == nil
        if enableMultiSelect {
            rxNavigationState.accept(.normalMultiSelect)
        } else {
            rxNavigationState.accept(.normal)
        }
    }

    private func tapMultiSelect() {
        if multiLevelResources {
            rxNavigationState.accept(.multiSelecting(0))
        } else {
            rxLoading.accept(.loading(BundleI18n.Calendar.Calendar_Edit_MoreMeetingRooms))
            triggerMultiSelect().subscribeForUI { [weak self] (buildings) in
                guard let self = self else { return }
                self.rxLoading.accept(.none)
                self.rxNavigationState.accept(.multiSelecting(0))
                self.rxRawAllBuildings.accept(buildings)
            } onError: { [weak self] _ in
                guard let self = self else { return }
                self.rxLoading.accept(.failed(BundleI18n.Calendar.Calendar_Toast_FailedToLoad))
            }.disposed(by: disposeBag)
        }
    }

    private func tapMultiSelectConfirm() {
        if multiLevelResources {
            rxMultiLevelSelectionConfirmed.onNext(())
        } else {
            let buildingIdToNameDic = rxAllBuildings.value
                .reduce(into: [String: String]()) { dic, buildingAndRooms in
                    dic[buildingAndRooms.building.id] = buildingAndRooms.building.name
                }

            let selectMeetingIDs = rxMeetingRoomSelectedMap.value
                .filter { $0.value == .selected }
                .keys

            let selectRooms = rxAllBuildings.value
                .map { $0.rooms }
                .flatMap { $0 }
                .filter { selectMeetingIDs.contains($0.id) }
                .map {
                    return CalendarMeetingRoom.makeMeetingRoom(
                        fromResource: $0,
                        buildingName: buildingIdToNameDic[$0.buildingID] ?? "",
                        tenantId: tenantID
                    )
                }

            rxMultiSelectConfirm.accept(selectRooms)
        }
    }

    private func tapMultiSelectCancel() {
        rxNavigationState.accept(.normalMultiSelect)
    }
}
