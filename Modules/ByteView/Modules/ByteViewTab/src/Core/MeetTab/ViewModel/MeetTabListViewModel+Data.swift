//
//  MeetTabListViewModel+Data.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import RxSwift
import ByteViewCommon
import ByteViewNetwork

extension MeetTabListViewModel {

    var historySectionItem: MeetTabSectionViewModel {
        return MeetTabSectionViewModel(title: I18n.View_MV_HistoryRecords,
//                                       icon: .videoOffFilled,
                                       textColor: UIColor.ud.textTitle,
                                       iconColor: UIColor.ud.iconN3,
                                       showSeparator: false,
                                       loadStatus: .loading,
                                       loadAction: loadMoreHistoryAction)
    }

    var ongoingSectionItem: MeetTabSectionViewModel {
        return MeetTabSectionViewModel(title: I18n.View_MV_OngoingNow,
                                       textColor: UIColor.ud.functionSuccessContentDefault,
                                       animationPath: Bundle.localResources.path(forResource: "light", ofType: "json", inDirectory: "group_meeting")!)
    }

    var historySectionObservable: Observable<([MeetTabHistorySectionViewModel], Bool)> {
        return historyDataSource.result.map { [weak self] result -> ([MeetTabHistorySectionViewModel], Bool) in
            guard var sectionItem = self?.historySectionItem else { return ([], false) }
            let historyItems: [MeetTabHistoryCellViewModel]
            var shouldRefresh = false
            switch result {
            case let .eventResults(items):
                historyItems = items.compactMap { $0 as? MeetTabHistoryCellViewModel }
                sectionItem.loadStatus = .result
                shouldRefresh = true
            case let .loadError(items, _):
                historyItems = items.compactMap { $0 as? MeetTabHistoryCellViewModel }
                sectionItem.loadStatus = .loadError
                shouldRefresh = true
            case let .loadResults(items, hasMore):
                historyItems = items.compactMap { $0 as? MeetTabHistoryCellViewModel }
                sectionItem.loadStatus = hasMore ? .loading : .result
                shouldRefresh = true
            case let .loadingResults(items):
                historyItems = items.compactMap { $0 as? MeetTabHistoryCellViewModel }
                shouldRefresh = false
            }
            guard !historyItems.isEmpty else { return ([], shouldRefresh) }
            return ([MeetTabHistorySectionViewModel(sectionItem: sectionItem, items: historyItems)], shouldRefresh)
        }
    }

    var ongoingSectionObservable: Observable<([MeetTabHistorySectionViewModel], Bool)> {
        // 同步请求会中设备信息，避免不同步刷新导致视图闪动。请求走的是Rust缓存，所以速度理论上很快
        return historyDataSource.result.flatMap { [weak self] result in
            RxTransform.single { [weak self] in
                self?.httpClient.getResponse(GetJoinedDeviceInfoRequest(), completion: $0)
            }.map { (result, $0.devices) }
            .catchError({ _ in
                return .just((result, []))
            })
        }
        .map { [weak self] (result, joinedDevices) -> ([MeetTabHistorySectionViewModel], Bool) in
            guard let sectionItem = self?.ongoingSectionItem else { return ([], false) }
            let ongoingItems: [MeetTabOngoingCellViewModel]
            var shouldRefresh = false
            switch result {
            case let .eventResults(items):
                ongoingItems = items.compactMap { $0 as? MeetTabOngoingCellViewModel }
                shouldRefresh = true
            case let .loadError(items, _):
                ongoingItems = items.compactMap { $0 as? MeetTabOngoingCellViewModel }
                shouldRefresh = true
            case let .loadResults(items, _):
                ongoingItems = items.compactMap { $0 as? MeetTabOngoingCellViewModel }
                shouldRefresh = true
            case let .loadingResults(items):
                ongoingItems = items.compactMap { $0 as? MeetTabOngoingCellViewModel }
                shouldRefresh = false
            }
            guard !ongoingItems.isEmpty else { return ([], shouldRefresh) }

            if !joinedDevices.isEmpty {
                ongoingItems.forEach { viewModel in
                    // 本端已入会则无需展示设备信息
                    if !viewModel.isJoined && !viewModel.isInLobby {
                        viewModel.joinedDeviceNames = joinedDevices.filter { $0.meetingID == viewModel.meetingID }
                            .sorted(by: { $0.joinTime < $1.joinTime })
                            .map { $0.defaultDeviceName }
                        Self.logger.info("getJoinedDevices success, meetingID:\(viewModel.meetingID), total:\(joinedDevices.count), currentMeeting:\(viewModel.joinedDeviceNames.count)")
                    }
                }
            }
            return ([MeetTabHistorySectionViewModel(sectionItem: sectionItem, items: ongoingItems)], shouldRefresh)
        }
    }

    static func addParticipantInfo(grootCell: TabListGrootCell, httpClient: HttpClient) -> Observable<(TabListGrootCell, [ParticipantUserInfo])> {
        let items = (grootCell.insertTopItems + grootCell.updateItems).filter { $0.meetingType == .call && ![.outsideEnterprisePhone, .insideEnterprisePhone].contains($0.phoneType) }
        guard !items.isEmpty else { return .just((grootCell, [])) }
        let pids = items.map { (ParticipantId(id: $0.historyAbbrInfo.interacterUserID, type: $0.historyAbbrInfo.interacterUserType), $0.meetingID) }
        let users = Single.zip(pids.map {
            httpClient.participantService.participantByIdUsingCache($0.0, meetingId: $0.1)
        }).map { res in res.compactMap { $0 } }.asObservable()
        return Observable.zip(Observable.from(optional: grootCell), users)
    }

    static func addRecordInfo(grootCell: TabListGrootCell, users: [ParticipantUserInfo], httpClient: HttpClient) -> Observable<(TabListGrootCell, [ParticipantUserInfo])> {
        let items: [TabListItem] = (grootCell.insertTopItems + grootCell.updateItems)
        let o1: Observable<(TabListGrootCell, [ParticipantUserInfo])> = .just((grootCell, users))
        let minutesIDs = items.filter { $0.contentLogos.contains(.larkMinutes) }.map { $0.meetingID }
        let recordIDs = items.filter { $0.contentLogos.contains(.record) && !$0.contentLogos.contains(.larkMinutes) }.map { $0.meetingID }
        let o2 = RxTransform.single { (completion: @escaping (Result<GetRecordInfoResponse, Error>) -> Void) in
            let request = GetRecordInfoRequest(recordMeetingIDs: recordIDs, minutesMeetingIDs: minutesIDs)
            httpClient.getResponse(request, completion: completion)
        }.asObservable().map { $0.recordInfo }.map { recordMap -> (TabListGrootCell, [ParticipantUserInfo]) in
            var r = grootCell
            r.insertTopItems = grootCell.insertTopItems.map {
                var item = $0
                if let recordInfo = recordMap[item.meetingID] {
                    item.recordInfo = recordInfo
                    item.hasRecordInfo = true
                }
                return item
            }
            r.updateItems = grootCell.updateItems.map {
                var item = $0
                if let recordInfo = recordMap[item.meetingID] {
                    item.recordInfo = recordInfo
                    item.hasRecordInfo = true
                }
                return item
            }
            return (r, users)
        }.catchError({ _ in .empty() })
        return Observable.merge(o1, o2)
    }

    // 增量数据
    // 将一个数组流打平成多个事件流
    // [[1, 2], [3, 4], [5, 6]] -> 1, 2, 3, 4, 5, 6
    var historyEventsObservable: Observable<MeetTabUpdateEvent> {
        let httpClient = self.httpClient
        return tabViewModel.listGrootSubject.asObservable()
            .flatMapLatest { Observable.from($0) }
            .flatMapLatest { Self.addParticipantInfo(grootCell: $0, httpClient: httpClient) }
            .flatMapLatest { Self.addRecordInfo(grootCell: $0.0, users: $0.1, httpClient: httpClient) }
            .flatMapLatest { [weak self] (group) -> Observable<MeetTabUpdateEvent> in
                guard let self = self else { return .empty() }
                let items = group.0
                let users = group.1
                var obs: [Observable<MeetTabUpdateEvent>] = []
                if !items.insertTopItems.isEmpty {
                    obs.append(.just(.add(self.historyToAll(items.insertTopItems, users: users))))
                }
                if !items.updateItems.isEmpty {
                    obs.append(.just(.update(self.historyToAll(items.updateItems, users: users))))
                }
                if !items.deletedHistoryIds.isEmpty {
                    obs.append(.just(.remove(items.deletedHistoryIds)))
                }
                return Observable.merge(obs)
            }
    }

    var recordEventsObservable: Observable<MeetTabUpdateEvent> {
        recordCompletedInfoRelay.asObservable().compactMap { [weak self] recordCompletedInfo -> MeetTabUpdateEvent? in
            guard let self = self,
                  let item = self.historyDataSource.current.first(where: { $0.meetingID == recordCompletedInfo.meetingID }) as? MeetTabMeetCellViewModel else { return nil }
            var vcInfo = item.vcInfo
            vcInfo.recordInfo = recordCompletedInfo.recordInfo
            return .update([MeetTabHistoryCellViewModel(viewModel: self.tabViewModel, vcInfo: vcInfo, user: item.user)])
        }
    }

    var historyAllEventsObservable: Observable<MeetTabUpdateEvent> {
        Observable.merge(historyEventsObservable, recordEventsObservable)
    }
}

extension MeetTabListViewModel {

    var upcomingSectionItem: MeetTabSectionViewModel {
        return MeetTabSectionViewModel(title: I18n.View_MV_AboutToStart,
//                                       icon: .videoOffFilled,
                                       textColor: UIColor.ud.textTitle,
                                       iconColor: UIColor.ud.primaryContentDefault,
                                       isLoadMore: false,
                                       moreAction: gotoCalendarAction)
    }

    var upcomingSectionObservable: Observable<([MeetTabHistorySectionViewModel], Bool)> {
        return upcomingDataSource.result.map { [weak self] result -> ([MeetTabHistorySectionViewModel], Bool) in
            guard var sectionItem = self?.upcomingSectionItem else { return ([], false) }
            let upcomingItems: [MeetTabUpcomingCellViewModel]
            var shouldRefresh = false
            switch result {
            case let .eventResults(items):
                upcomingItems = items.compactMap { $0 as? MeetTabUpcomingCellViewModel }
                shouldRefresh = true
            case let .loadError(items, _):
                upcomingItems = items.compactMap { $0 as? MeetTabUpcomingCellViewModel }
                shouldRefresh = true
            case let .loadResults(items, hasMore):
                sectionItem.isLoadMore = hasMore
                upcomingItems = items.compactMap { $0 as? MeetTabUpcomingCellViewModel }
                shouldRefresh = true
            case let .loadingResults(items):
                upcomingItems = items.compactMap { $0 as? MeetTabUpcomingCellViewModel }
                shouldRefresh = false
            }
            guard !upcomingItems.isEmpty else { return ([], shouldRefresh) }
            return ([MeetTabHistorySectionViewModel(sectionItem: sectionItem, items: upcomingItems)], shouldRefresh)
        }
    }

    var upcomingAllEventsObservable: Observable<MeetTabUpdateEvent> {
        return .empty()
    }
}
