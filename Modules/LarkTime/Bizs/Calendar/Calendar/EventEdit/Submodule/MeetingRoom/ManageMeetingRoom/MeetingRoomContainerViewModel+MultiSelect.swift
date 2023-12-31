//
//  MeetingRoomContainerViewModel+MultiSelect.swift
//  Calendar
//
//  Created by Rico on 2021/5/14.
//

import Foundation
import RxSwift

/// 多选会议室目前逻辑不同，需要全部会议室加载到本地，之后不做网络请求。 逻辑单独拆出来
extension MeetingRoomContainerViewModel {

    func triggerMultiSelect() -> Observable<[Building]> {
        return loadAllMeetingRoom()
    }

    private func loadAllMeetingRoom() -> Observable<[Building]> {
        guard let start = startDate, let end = endDate else {
            return .empty()
        }
        return meetingRoomApi?
            .getAllMeetingRooms(startTime: start, endTime: end)
            .flatMap { [weak self] (rooms) -> Observable<[Building]> in
                guard let self = self else {
                    return .just([])
                }
                return self.reformMeetingRooms(rooms)
            } ?? .empty()
    }

    /// 根据拉到的所有会议室 匹配现有的建筑物
    private func reformMeetingRooms(_ rooms: [Rust.MeetingRoom]) -> Observable<[Building]> {
        return Observable.create { [weak self] (observer) -> Disposable in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            let hasContentBuildings = Dictionary(grouping: rooms) { $0.buildingID }
            let reformBuildings = self.rxBuildings.value.map { building -> Building in
                return Building(building: building, rooms: hasContentBuildings[building.id] ?? [])
            }

            observer.onNext(reformBuildings)
            observer.onCompleted()
            return Disposables.create()
        }
    }
}

struct Building {
    let building: Rust.Building
    let rooms: [Rust.MeetingRoom]
}

extension MeetingRoomContainerViewModel {

}
