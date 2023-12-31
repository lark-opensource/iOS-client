//
//  MeetingRoomHomeViewModel.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/5/7.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import RustPB
import LarkAccountInterface

final class MeetingRoomHomeViewModel: UserResolverWrapper {
    @ScopedInjectedLazy private var rustAPI: CalendarRustAPI?
    @ScopedInjectedLazy private var meetingRoomHomeTracer: MeetingRoomHomeTracer?
    @ScopedInjectedLazy var localRefreshService: LocalRefreshService?
    @ScopedInjectedLazy var userService: PassportUserService?

    let userResolver: UserResolver
    private var instancesCache = [Rust.MeetingRoom: MeetingRoomInstances]()

    // 小月历选中的日期
    var selectedDateRelay = BehaviorRelay<Date>(value: Date())
    private let loadingMeetingRoomsRelay = BehaviorRelay<[Rust.MeetingRoom]>(value: [])

    // 当前的时间
    var currentTimeRelay = BehaviorRelay<Date>(value: Date())

    let meetingRoomCountUpperLimit: Int = 500

    private let filterRelay =
        BehaviorRelay<Rust.MeetingRoomViewFilterResult>(value: Rust.MeetingRoomViewFilterResult(filterConfig: Rust.RoomViewFilterConfig(),
                                                                                                meetingRooms: [:],
                                                                                                buildings: [:]))
    private(set) lazy var filterDriver = filterRelay.map { [weak self] result in
        var filter = Filter()
        filter._multiLevelresources = self?.multiLevelResources ?? false
        filter._capacity = Int(result.filterConfig.meetingRoomFilter.minCapacity)
        filter._equipments = result.filterConfig.meetingRoomFilter.needEquipments.compactMap { id in
            self?.allEquipments.first(where: { $0.id == id })?.equipment.i18NName
        }
        filter._allEquipmentCount = self?.allEquipments.count ?? 0
        if let buildingID = result.filterConfig.neededBuildingFloors.first?.buildingID,
           let building = result.buildings[buildingID] {
            if let floors = result.filterConfig.neededBuildingFloors.first?.neededFloors, !floors.isEmpty {
                filter._buildingAndFloors = (building, .specifics(floors))
            } else {
                filter._buildingAndFloors = (building, .all)
            }
        }
        return filter
    }
    .asDriver(onErrorJustReturn: Filter())

    private(set) lazy var meetingRoomsDriver: Driver<[MeetingRoomInstances]> = filterRelay
        .observeOn(MainScheduler.instance)
        .map { [weak self] result in
            guard let self = self else { return [] }
            if self.multiLevelResources {
                return result.meetingRooms
                    .map { $0 }
                    .sorted { lhs, rhs in
                        (Int(lhs.key) ?? 0) < (Int(rhs.key) ?? 0)
                    }
                    .map(\.value)
                    .map { self.instancesCache[$0] ?? MeetingRoomInstances(meetingRoom: $0) }
            } else {
                return Array(result.meetingRooms.values)
                    .sorted { $0.weight > $1.weight }
                    .map { self.instancesCache[$0] ?? MeetingRoomInstances(meetingRoom: $0) }
            }
        }
        .asDriver(onErrorJustReturn: [])

    private(set) lazy var meetingRoomInstanceUpdateRelay = PublishRelay<[MeetingRoomInstances]>()
    private(set) lazy var meetingRoomInstanceUpdateFailedRelay = PublishRelay<Void>()

    private(set) var allBuildings = [Rust.Building]()
    private var allEquipments = [Rust.EquipmentExpand]()

    var equipmentsWithSelection: [(Rust.EquipmentExpand, Bool)] {
        return allEquipments.map {
            return ($0,
             filterRelay.value.filterConfig.meetingRoomFilter.needEquipments.contains($0.equipment.id))
        }
    }

    var selectedBuildingAndFloors: (Rust.Building, Filter.Floor)?

    var paginator: MeetingRoomHomeListPaginator?
    var rxHasMore: BehaviorRelay<Bool> = .init(value: false)

    private(set) var rootLevel: MLLevel?
    // changing rootLevel
    private(set) var rootLevelInjected: MLLevel?

    private(set) var multiLevelResources: Bool

    private let bag = DisposeBag()

    var selectedLevelIds: [String] {
        return self.filterRelay.value.selectedLevelIds
    }

    init(multiLevelResources: Bool, userResolver: UserResolver) {
        self.multiLevelResources = multiLevelResources
        self.userResolver = userResolver

        if multiLevelResources {
            self.getHierarchicalMeetingRoomModel()
        } else {
            self.getMeetingRoomModel()
        }

        self.bindViewData()
    }

    private func bindViewData() {

        guard let rustAPI = self.rustAPI else {
            EventEdit.logger.error("bindViewData failed, can not get rustapi from larkcontainer")
            return
        }

        selectedDateRelay.asDriver()
            .drive(onNext: { [weak self] _ in
                self?.instancesCache.removeAll()
            })
            .disposed(by: bag)

        let debouncedLoadingMeetingRoomsRelay = loadingMeetingRoomsRelay
            .filter { !$0.isEmpty }
            .debounce(.milliseconds(200), scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
        Observable.combineLatest(debouncedLoadingMeetingRoomsRelay, selectedDateRelay)
            .flatMap { [weak self] (meetingRooms, date) -> Observable<[Rust.MeetingRoom: [RoomViewInstance]]> in
                guard let self = self else { return .empty() }
                return rustAPI.getMeetingRoomInstances(meetingRooms: meetingRooms,
                                                            startTime: date.dayStart(),
                                                            endTime: date.dayEnd())
                    .do(onNext: { [weak self] _ in
                        guard let self = self else { return }
                        self.meetingRoomHomeTracer?.loadInstanceSuccess()
                        SlaMonitor.traceSuccess(.MeetingRoomViewAddEvent,
                                                action: "load_instance",
                                                source: self.multiLevelResources ? "level" : "meeting")
                    }, onError: { [weak self] error in
                        guard let self = self else { return }
                        self.loadingMeetingRoomsRelay.accept([])
                        self.meetingRoomInstanceUpdateFailedRelay.accept(())
                        SlaMonitor.traceFailure(.MeetingRoomViewAddEvent,
                                                error: error,
                                                action: "load_instance",
                                                source: self.multiLevelResources ? "level" : "meeting")
                    })
                    .catchErrorJustReturn([:])
            }
            .subscribeForUI(onNext: { [weak self] meetingRoomAndInstances in
                guard let self = self else { return }

                var waitToLoad = self.loadingMeetingRoomsRelay.value
                waitToLoad.lf_removeObjectsInArray(Array(meetingRoomAndInstances.keys))
                self.loadingMeetingRoomsRelay.accept(waitToLoad)

                var instances = [MeetingRoomInstances]()
                meetingRoomAndInstances.forEach {
                    let instance = MeetingRoomInstances(meetingRoom: $0.key, instances: .some($0.value))
                    self.instancesCache[$0.key] = instance
                    instances.append(instance)
                }

                self.meetingRoomInstanceUpdateRelay.accept(instances)
            })
            .disposed(by: bag)

        localRefreshService?.rxMainViewNeedRefresh
            .map { _ in Date() }
            .bind(to: currentTimeRelay)
            .disposed(by: bag)

    }

    // 超过5个小时进入会议室视图时调用一次sdk update接口
    private var lastAppearTime = Date()
    func updateSDKFilterIfNeededOnAppear() -> Observable<Rust.MeetingRoomViewFilterResult>? {
        guard let rustAPI = self.rustAPI else {
            EventEdit.logger.error("updateSDKFilterIfNeededOnAppear failed, can not get rustapi from larkcontainer")
            return nil
        }

        let fiveHours: TimeInterval = 5 * 60 * 60
        if Date().timeIntervalSince(lastAppearTime) > fiveHours {
            lastAppearTime = Date()
            return rustAPI.updateMeetingRoomViewFilter(filter: self.filterRelay.value.filterConfig)
        }
        return nil
    }

    func loadInstances(meetingRoomID: Rust.MeetingRoom, ignoreCache: Bool = false) {
        var value = loadingMeetingRoomsRelay.value
        // 待加载队列中已有
        if !value.contains(meetingRoomID) {
            value.append(meetingRoomID)
        }
        // 选择不忽略缓存且缓存中已有
        if !ignoreCache && instancesCache[meetingRoomID] != nil { return }
        // 加入队列
        loadingMeetingRoomsRelay.accept(value.suffix(10))
    }
}

extension MeetingRoomHomeViewModel {
    struct MeetingRoomInstances {
        enum Instances {
            case loading
            case some([RoomViewInstance])
        }
        let meetingRoom: Rust.MeetingRoom

        var instances = Instances.loading
    }

    struct Filter: MeetingRoomHomeFilterViewData {
        enum Floor: CustomStringConvertible {
            case all
            case specifics([String])

            var description: String {
                switch self {
                case .all:
                    return ""
                case .specifics(let names):
                    return names.joined(separator: "/")
                }
            }
        }

        var building: String? {
            guard !_multiLevelresources else {
                return BundleI18n.Calendar.Calendar_G_SelectLayerButton
            }
            return _buildingAndFloors.map {
                switch $0.1 {
                case .all:
                    return "\($0.0.name)·\(BundleI18n.Calendar.Calendar_Common_All)"
                case .specifics:
                    return "\($0.0.name)·\($0.1)"
                }
            }
        }
        var equipment: String? {
            _equipments.isEmpty ? (_allEquipmentCount > 0 ? "" : nil) : _equipments.joined(separator: "·")
        }
        var capacity: String? {
            _capacity > 0 ? "\(_capacity)" : nil
        }

        fileprivate var _capacity: Int = 0
        fileprivate(set) var _equipments = [String]()
        fileprivate(set) var _allEquipmentCount = 0
        fileprivate(set) var _multiLevelresources = false

        // 暂时只支持一个建筑的多个楼层
        fileprivate var _buildingAndFloors: (Rust.Building, Floor)?
    }
}

// MARK: 多层级
extension MeetingRoomHomeViewModel {
    private func getHierarchicalMeetingRoomModel() {
        guard let rustAPI = self.rustAPI,
              let userService = self.userService else {
            EventEdit.logger.error("getHierarchicalMeetingRoomModel failed, can not get rustapi from larkcontainer")
            return
        }

        Observable.zip(rustAPI.getLocalHierarchicalRoomViewResourceConfig(),
                       rustAPI.getResourceEquipments())
            .flatMap { [weak self] configResponse, equipmentsResponse -> Observable<(Rust.HierarchicalRoomViewFilterConfigs, Bool)> in
                // 校验 selectedLevelIds 的准确性，以及 设备 的存在性
                var config = configResponse.hierarchicalRoomViewFilterConfigs
                self?.allEquipments = equipmentsResponse
                config.meetingRoomFilter.needEquipments.removeAll { needEquipmentId in
                    !(self?.allEquipments.contains(where: { $0.equipment.id == needEquipmentId }) ?? false)
                }
                guard let rustAPI = self?.rustAPI else { return .just((config, false)) }
                return rustAPI.pullLevelPathRequest(levelIds: config.selectedLevelIds)
                    .map({ (levelPaths: [String: [String]]) in
                        config.selectedLevelIds.removeAll(where: { !levelPaths.keys.contains($0) })
                        let showTenantName = levelPaths.values.first?.contains(MLLevel.RequestRootLevelInfo.id) ?? false
                        return (config, showTenantName)
                    })
            }
            .flatMap({ [weak self ] (config, showTenantName) -> Observable<(Rust.HierarchicalRoomViewFilterConfigs, Bool)> in
                var config = config
                guard let self = self else { return .just((config, false)) }
                if config.selectedLevelIds.isEmpty {
                    // 如果 selectedLevelIds 为空，则用 根层级下第一个子层级/根层级 进行兜底
                    return rustAPI.getHierarchicalRoomViewSubLevelInfo(levelIds: [MLLevel.RequestRootLevelInfo.id], needTopLevelInfo: true).map { levelInfos in
                        config.selectedLevelIds = [levelInfos[MLLevel.RequestRootLevelInfo.id]?.sonLevelInfos.first?.levelID ?? MLLevel.RequestRootLevelInfo.id]
                        return (config, showTenantName)
                    }
                } else {
                    return .just((config, showTenantName))
                }
            })
            .subscribe(onNext: { [weak self] (config, showTenantName) in
                // 初始化会议室列表数据
                guard let self = self else { return }
                self.initHierarchicalRoomView(config: config)

                // 构建层级选择页面需要的根层级树，不涉及子节点
                let rootLevelConfig = MLLevel.MLLevelConfig(showLevelsOnly: true)
                let rootLevel = MLLevel(name: MLLevel.RequestRootLevelInfo.name, id: MLLevel.RequestRootLevelInfo.id, config: rootLevelConfig)
                let tenantName = self.userService?.userTenant.tenantName ?? ""
                if !tenantName.isEmpty && showTenantName {
                    let tenantLevel = MLLevel(name: tenantName, id: MLLevel.RequestRootLevelInfo.id, config: rootLevelConfig)
                    rootLevel.subLevels = [tenantLevel]
                    rootLevel.hasChild = true
                    tenantLevel.superLevel = rootLevel
                }
                self.rootLevel = rootLevel
            })
            .disposed(by: bag)
    }

    private func initHierarchicalRoomView(config: Rust.HierarchicalRoomViewFilterConfigs) {
        paginator = MeetingRoomHomeListPaginator(config: config, userResolver: self.userResolver)
        pullHierarchicalRoomViewResourceList()
            .subscribe(onNext: { [weak self] resources in
                guard let self = self else { return }
                var filterResult = self.filterRelay.value
                filterResult.meetingRooms = resources
                filterResult.selectedLevelIds = config.selectedLevelIds
                filterResult.filterConfig.meetingRoomFilter = config.meetingRoomFilter
                self.filterRelay.accept(filterResult)
            }).disposed(by: bag)
    }

    private func multiLevelChangeFilter(equipments: [String]) {
        var result = filterRelay.value
        result.filterConfig.meetingRoomFilter.needEquipments = equipments
        paginator?.updateConfig(config: result.transformToHierarchicalRoomViewFilterConfig())
        pullHierarchicalRoomViewResourceList()
            .subscribe(onNext: { [weak self] resources in
                result.meetingRooms = resources
                self?.filterRelay.accept(result)
            })
            .disposed(by: self.bag)
    }

    private func multiLevelChangeFilter(capacity: Int) {
        var result = filterRelay.value
        result.filterConfig.meetingRoomFilter.minCapacity = Int32(capacity)
        paginator?.updateConfig(config: result.transformToHierarchicalRoomViewFilterConfig())
        pullHierarchicalRoomViewResourceList()
            .subscribe(onNext: { [weak self] resources in
                result.meetingRooms = resources
                self?.filterRelay.accept(result)
            })
            .disposed(by: self.bag)
    }

    func multiLevelChangeFilter(selectedLevelIds: [String]) {
        var result = filterRelay.value
        result.selectedLevelIds = selectedLevelIds
        paginator?.updateConfig(config: result.transformToHierarchicalRoomViewFilterConfig())
        pullHierarchicalRoomViewResourceList()
            .subscribe(onNext: { [weak self] resources in
                result.meetingRooms = resources
                self?.filterRelay.accept(result)
            })
            .disposed(by: self.bag)
    }

    func pullHierarchicalRoomViewResourceList() -> Observable<[String: Rust.MeetingRoom]> {
        guard let paginator = paginator else {
            return  .just([:])
        }
        return paginator.pullHierarchicalRoomViewResourceList()
            .map({ [weak self] pageResult in
                guard let self = self else { return [:]}
                self.rxHasMore.accept(pageResult.hasMore)
                let kv = pageResult.resources.enumerated().map { ($0.offset.description, $0.element) }
                let pageResultResourceDic = [String: Rust.MeetingRoom](uniqueKeysWithValues: kv)
                return pageResultResourceDic
            })
            .collectSlaInfo(.MeetingRoomViewAddEvent, action: "load_meeting", source: "level")

    }

    func loadMoreHierarchicalRoomViewResourceList() {
        let distance: Int = meetingRoomCountUpperLimit - self.filterRelay.value.meetingRooms.count
        let needLoadCount = distance > 50 ? 50 : distance
        paginator?.loadMoreHierarchicalRoomViewResourceList(count: Int32(needLoadCount))
            .subscribe(onNext: { [weak self] pageResult in
                guard let self = self,
                      let pageResult = pageResult else { return }
                var filter = self.filterRelay.value
                let count = filter.meetingRooms.count
                let kv = pageResult.resources.enumerated().map { ((count + $0.offset).description, $0.element) }
                let pageResultResourceDic = [String: Rust.MeetingRoom](uniqueKeysWithValues: kv)
                filter.meetingRooms.merge(pageResultResourceDic) { $1 }
                if filter.meetingRooms.count >= self.meetingRoomCountUpperLimit {
                    self.rxHasMore.accept(false)
                } else {
                    self.rxHasMore.accept(pageResult.hasMore)
                }
                self.filterRelay.accept(filter)
            })
            .disposed(by: self.bag)
    }

    func resetInjectedRootLevel() {
        rootLevelInjected = rootLevel?.deepCopy()
    }

}

// MARK: 固定层级
extension MeetingRoomHomeViewModel {

    private func getMeetingRoomModel() {
        guard let rustAPI = self.rustAPI else {
            EventEdit.logger.error("getMeetingRoomModel failed, can not get rustapi from larkcontainer")
            return
        }

        rustAPI.getResourceEquipments()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.allEquipments = $0
            })
            .disposed(by: bag)

        rustAPI.getMeetingRoomBuildings()
            .collectSlaInfo(.MeetingRoomViewAddEvent, action: "load_building", source: "meeting")
            .subscribe(onNext: { [weak self] buildings in
                guard let self = self else { return }
                self.meetingRoomHomeTracer?.loadBuildingSuccess(with: .building_like, count: buildings.count)
                self.allBuildings = buildings.sorted(by: { $0.weight > $1.weight })
                // 客户端在拉取 buildings 后校验，如果已选不合法，则更新 filter
                if let selectedBuildingAndFloors = self.selectedBuildingAndFloors {
                    let buildingInvalid = !buildings.contains(selectedBuildingAndFloors.0)
                    var floorsInvalid = false
                    if case .specifics(let selectedFloors) = selectedBuildingAndFloors.1 {
                        floorsInvalid = !selectedFloors.allSatisfy(selectedBuildingAndFloors.0.floors.contains)
                    }
                    if buildingInvalid || floorsInvalid {
                        self.changeFilter(building: self.allBuildings.first, floors: .all)
                    }
                    EventEdit.logger.info("buildingInvalid \(buildingInvalid), floorsInvalid \(floorsInvalid)")
                }
            })
            .disposed(by: bag)

        rustAPI.getLocalMeetingRoomViewFilter()
            .do(onNext: { [weak self] filter in
                if let buildingID = filter.filterConfig.neededBuildingFloors.first?.buildingID,
                   let building = filter.buildings[buildingID] {
                    if let floors = filter.filterConfig.neededBuildingFloors.first?.neededFloors, !floors.isEmpty {
                        self?.selectedBuildingAndFloors = (building, .specifics(floors))
                    } else {
                        self?.selectedBuildingAndFloors = (building, .all)
                    }
                }
                self?.updateSDKFilterConfig(filter: filter.filterConfig)
            })
            .bind(to: filterRelay)
            .disposed(by: bag)
    }
    
    private func updateSDKFilterConfig(filter: Rust.RoomViewFilterConfig) {
        guard let rustAPI = self.rustAPI else {
            EventEdit.logger.error("updateSDKFilterConfig failed, can not get rustapi from larkcontainer")
            return
        }
        Observable.just(filter)
            .flatMapLatest {
                rustAPI.updateMeetingRoomViewFilter(filter: $0)
                    .collectSlaInfo(.MeetingRoomViewAddEvent, action: "load_meeting", source: "meeting")
            }
            .bind(to: filterRelay)
            .disposed(by: bag)
    }

    func changeFilter(building: Rust.Building?, floors: Filter.Floor?) {
        var filterConfig = filterRelay.value.filterConfig
        if let building = building, let floors = floors {
            var buildingFloorFilter = Calendar_V1_BuildingFloorFilter()
            buildingFloorFilter.buildingID = building.id
            if case let .specifics(names) = floors {
                buildingFloorFilter.neededFloors = names
            } else {
                buildingFloorFilter.neededFloors = []
            }
            filterConfig.neededBuildingFloors = [buildingFloorFilter]
            selectedBuildingAndFloors = (building, floors)
        } else {
            filterConfig.neededBuildingFloors = []
            selectedBuildingAndFloors = nil
        }

        self.loadingMeetingRoomsRelay.accept([])

        updateSDKFilterConfig(filter: filterConfig)
    }

    func changeFilter(equipments: [String]) {
        if self.multiLevelResources {
            multiLevelChangeFilter(equipments: equipments)
        } else {
            var filterConfig = filterRelay.value.filterConfig

            filterConfig.meetingRoomFilter.needEquipments = equipments

            updateSDKFilterConfig(filter: filterConfig)
        }
    }

    func changeFilter(capacity: Int) {
        if self.multiLevelResources {
            multiLevelChangeFilter(capacity: capacity)
        } else {
            var filterConfig = filterRelay.value.filterConfig

            filterConfig.meetingRoomFilter.minCapacity = Int32(capacity)

            updateSDKFilterConfig(filter: filterConfig)
        }
    }
}
