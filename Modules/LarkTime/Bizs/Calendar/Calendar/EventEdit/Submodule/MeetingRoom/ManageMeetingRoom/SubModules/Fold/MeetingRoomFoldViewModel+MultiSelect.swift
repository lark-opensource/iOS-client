//
//  MeetingRoomFoldViewModel+MultiSelect.swift
//  Calendar
//
//  Created by Rico on 2021/5/18.
//

import Foundation
import RxSwift

/// 多选会议的逻辑单独拆出来，避免数据和逻辑混在一起
extension MeetingRoomFoldViewModel {

    func observeMultiSelect() {
        // 多选态
        if let building = rxBuildingSelectedMap,
           let room = rxMeetingRoomSelectedMap,
           let selectAll = rxSelectAll {
            Observable.combineLatest(building, room)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] buildingSelectMap, meetingRoomSelectMap in
                    guard let self = self else { return }
                    self.reformCellData(with: (buildingSelectMap, meetingRoomSelectMap))
                    self.onAllCellDataUpdate?()
                }).disposed(by: disposeBag)

            // 建筑物状态 反向联动 全选按钮的状态
            building.map { [weak self] buildingMap -> SelectType in
                guard let self = self else { return .disabled }
                /// 过滤disabled建筑物
                let availableBuildings = buildingMap.values.filter { b in b != .disabled }

                if availableBuildings.isEmpty {
                    return .disabled
                }

                if availableBuildings.allSatisfy { b in b == .selected } {
                    return .selected
                }

                if availableBuildings.contains { b in (b == .selected || b == .halfSelected) } {
                    return .halfSelected
                }

                if !availableBuildings.isEmpty {
                    return .nonSelected
                }

                return .disabled
            }
            .bind(to: selectAll)
            .disposed(by: disposeBag)
        }

        // 多选开关
        rxMultiSelect
            .distinctUntilChanged()
            .bind { [weak self] multiSelect in
                guard let self = self else { return }
                if multiSelect {
                    /// 现有建筑物及下属会议室信息全部刷新成未选择态
                    let reduceDiffs = self.buildingCellDataList.reduce(([:], [:])) { (result, buildingCellData) -> SelectStateDiff in
                        let diff = self.initState(at: buildingCellData)
                        return (
                            result.0.merging(diff.resultBuildingMap) { $1 },
                            result.1.merging(diff.resultRoomMap) { $1 }
                        )
                    }
                    self.triggerReloadWithSelectDiff(reduceDiffs)
                } else {
                    self.rxBuildingSelectedMap?.accept([:])
                    self.rxMeetingRoomSelectedMap?.accept([:])
                }
            }
            .disposed(by: disposeBag)

        // 所有会议室信息更改（筛选）
        rxAllMeetingRooms?.subscribe(onNext: { [weak self] buildings in
            guard let self = self else { return }
            self.reloadAllMeetingRoomCellData(buildings)
            let reduceDiffs = self.buildingCellDataList.reduce(([:], [:])) { (result, buildingCellData) -> SelectStateDiff in
                let diff = self.initState(at: buildingCellData)
                return (
                    result.0.merging(diff.resultBuildingMap) { $1 },
                    result.1.merging(diff.resultRoomMap) { $1 }
                )
            }
            self.triggerReloadWithSelectDiff(reduceDiffs)
        })
        .disposed(by: disposeBag)

        // 全选状态改变
        rxSelectAll?
            .distinctUntilChanged()
            .subscribe(onNext: {[weak self] selectType in
                guard let self = self else { return }

                guard selectType == .selected || selectType == .nonSelected else {
                    return
                }

                let reduceDiffs = self.buildingCellDataList.reduce(([:], [:])) { (result, buildingCellData) -> SelectStateDiff in
                    let diff = self.updateBuildingSelect(buildingCellData, selectType)
                    return (
                        result.0.merging(diff.resultBuildingMap) { $1 },
                        result.1.merging(diff.resultRoomMap) { $1 }
                    )
                }
                self.triggerReloadWithSelectDiff(reduceDiffs)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Action
extension MeetingRoomFoldViewModel {
    func toggleBuildingSelectTapped(at index: Int) {
        toggleBuildingSelect(at: index)
    }

    func toggleMeetingRoomSelectTapped(at indexPath: IndexPath) {
        toggleMeetingRoomSelect(at: indexPath)
    }
}

// MARK: - Data Operation
extension MeetingRoomFoldViewModel {

    private func reloadAllMeetingRoomCellData(_ buildings: [Building]) {
        multiSelectBuildingCellDataList = buildings.map { building -> BuildingRoomCellData in
            var buildingCellData = BuildingRoomCellData(building: Selectable(building.building, isSelected: .nonSelected))
            let roomsCellData = building.rooms
                .reform(reformMeetingRoom)
                .map { room -> MeetingRoomCellData in
                    var isAvailable = room.status == .free
                    var unAvailableReason: String?
                    if room.schemaExtraData.cd.resourceCustomization != nil, eventConditions.formDisabled {
                        isAvailable = false
                        unAvailableReason = meetingRoomWithFormDisableReason
                    }
                    if room.needsApproval, rrule != nil {
                        isAvailable = false
                        unAvailableReason = I18n.Calendar_Approval_RecurToast
                    }
                    return MeetingRoomCellData(meetingRoom: Selectable(room, isSelected: .nonSelected),
                                               buildingName: building.building.name,
                                               isAvailable: isAvailable,
                                               unAvailableReason: unAvailableReason,
                                               state: .noSubscribe)
                }
            buildingCellData.state = .loaded(roomsCellData, true)
            return buildingCellData
        }
    }

}

// MARK: - SelectMap State Change
extension MeetingRoomFoldViewModel {
    private func toggleBuildingSelect(at index: Int) {

        refreshBuildingSelect(at: index, toggle: true)
    }

    private func refreshBuildingSelect(at index: Int, toggle: Bool = false) {
        guard
            var buildingCellData = buildingCellDataList[safeIndex: index],
            let currentSelect = rxBuildingSelectedMap?.value[buildingCellData.building.raw.id],
            currentSelect != .disabled else {
            return
        }

        let upcomingSelect = currentSelect.toggle()

        // 如果点击建筑物的全选的话，会触发展开
        if case let .loaded(data, fold) = buildingCellData.state,
           upcomingSelect == .selected {
            buildingCellData = BuildingRoomCellData(building: buildingCellData.building,
                                                       state: .loaded(data, false),
                                                       disposeBag: DisposeBag())
        }
        buildingCellDataList.replaceSubrange(index..<index + 1, with: [buildingCellData])

        let diffs = updateBuildingSelect(buildingCellData, toggle ? upcomingSelect : currentSelect)
        triggerReloadWithSelectDiff(diffs)
    }

    private func toggleMeetingRoomSelect(at indexPath: IndexPath) {
        guard
            let buildingCellData = buildingCellDataList[safeIndex: indexPath.section],
            let meetingRoom = meetingRoomCellData(at: indexPath),
            let currentSelect = rxMeetingRoomSelectedMap?.value[meetingRoom.meetingRoom.raw.id],
            currentSelect != .disabled else {
            return
        }

        let diffs = updateMeetingRoomSelect(buildingCellData, meetingRoom, currentSelect.toggle())
        triggerReloadWithSelectDiff(diffs)
    }

    /// 更改建筑物状态，联动下属会议室状态
    /// - Parameters:
    ///   - building: 建筑物（包含下属会议室）
    ///   - selected: 最新选择状态
    /// - Returns: 此次改动造成的状态变化
    private func updateBuildingSelect(_ building: BuildingRoomCellData, _ selected: SelectType) -> SelectStateDiff {

        // disabled不能变更状态
        guard rxBuildingSelectedMap?.value[building.building.raw.id] != .disabled else {
            return ([:], [:])
        }

        var resultBuildingMap: [BuildingID: SelectType] = [:]
        var resultRoomMap: [MeetingRoomID: SelectType] = [:]

        resultBuildingMap[building.building.raw.id] = selected

        if case let .loaded(data, _) = building.state {
            /// 建筑物下属会议室状态更改 （不可用状态不能更改）
            for room in data where rxMeetingRoomSelectedMap?.value[room.meetingRoom.raw.id] != .disabled {
                resultRoomMap[room.meetingRoom.raw.id] = selected
            }
        }

        return (resultBuildingMap, resultRoomMap)
    }

    /// 更改会议室状态，联动建筑物状态
    /// - Parameters:
    ///   - building: 建筑物（包含下属会议室）
    ///   - selected: 最新选择状态
    /// - Returns: 此次改动造成的状态变化
    private func updateMeetingRoomSelect(_ building: BuildingRoomCellData, _ meetingRoom: MeetingRoomCellData, _ selected: SelectType) -> SelectStateDiff {

        // disabled不能变更状态
        guard rxMeetingRoomSelectedMap?.value[meetingRoom.meetingRoom.raw.id] != .disabled else {
            return ([:], [:])
        }

        var resultBuildingMap: [BuildingID: SelectType] = [:]
        var resultRoomMap: [MeetingRoomID: SelectType] = [:]
        let currentRoomMap = rxMeetingRoomSelectedMap?.value

        resultRoomMap[meetingRoom.meetingRoom.raw.id] = selected

        if case let .loaded(data, _) = building.state {

            func upcomingState(_ roomId: MeetingRoomID) -> SelectType? {
                if roomId == meetingRoom.meetingRoom.raw.id {
                    return selected
                } else {
                    return currentRoomMap?[roomId]
                }
            }

            let buildingSelected: SelectType

            let allRoomState = data
                .map { upcomingState($0.meetingRoom.raw.id) }
                .filter { $0 != .disabled }
            if allRoomState.allSatisfy { $0 == .selected } {
                buildingSelected = .selected
            } else if allRoomState.contains { $0 == .selected } {
                buildingSelected = .halfSelected
            } else {
                buildingSelected = .nonSelected
            }

            resultBuildingMap[building.building.raw.id] = buildingSelected
        }

        return (resultBuildingMap, resultRoomMap)
    }

    /// 初始化建筑物以及下属会议室的状态
    /// - Parameter building: 建筑物
    /// - Returns: 此次改动造成的状态变化
    private func initState(at building: BuildingRoomCellData) -> SelectStateDiff {
        var resultBuildingMap: [BuildingID: SelectType] = [:]
        var resultRoomMap: [MeetingRoomID: SelectType] = [:]

        resultBuildingMap[building.building.raw.id] = .disabled

        if case let .loaded(data, _) = building.state {
            for room in data {
                resultRoomMap[room.meetingRoom.raw.id] = room.isAvailable ? .nonSelected : .disabled
            }
            if data.contains { $0.isAvailable } { resultBuildingMap[building.building.raw.id] = .nonSelected }
        }

        return (resultBuildingMap, resultRoomMap)
    }

    private func triggerReloadWithSelectDiff(_ diffs: SelectStateDiff) {
        guard var buildingMap = rxBuildingSelectedMap?.value,
              var roomMap = rxMeetingRoomSelectedMap?.value else {
            return
        }

        buildingMap.merge(diffs.resultBuildingMap) { $1 }
        roomMap.merge(diffs.resultRoomMap) { $1 }

        rxBuildingSelectedMap?.accept(buildingMap)
        rxMeetingRoomSelectedMap?.accept(roomMap)
    }

    private func reformCellData(with selectMap: ([BuildingID: SelectType], [MeetingRoomID: SelectType])) {
        self.buildingCellDataList = self.buildingCellDataList.map({ (buildingCellData) -> BuildingRoomCellData in
            if case let .loaded(data, _) = buildingCellData.state {
                let updatedMeetingRooms = data.map { (meetingRoomCellData) -> MeetingRoomCellData in
                    return MeetingRoomCellData(meetingRoom: Selectable(meetingRoomCellData.meetingRoom.raw, isSelected: selectMap.1[meetingRoomCellData.meetingRoom.raw.id]), buildingName: meetingRoomCellData.buildingName, isAvailable: meetingRoomCellData.isAvailable, unAvailableReason: meetingRoomCellData.unAvailableReason, state: meetingRoomCellData.state)
                }

                var building = BuildingRoomCellData(building: Selectable(buildingCellData.building.raw,
                                                                         isSelected: selectMap.0[buildingCellData.building.raw.id]))
                building.state = .loaded(updatedMeetingRooms, !buildingCellData.isUnFold)
                return building
            }
            let building = BuildingRoomCellData(building: Selectable(buildingCellData.building.raw,
                                                                     isSelected: selectMap.0[buildingCellData.building.raw.id]))
            return building
        })
    }
}
