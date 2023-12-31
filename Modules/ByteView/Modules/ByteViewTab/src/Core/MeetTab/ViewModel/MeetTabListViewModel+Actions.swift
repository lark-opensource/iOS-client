//
//  MeetTabListViewModel+Actions.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/4.
//

import Foundation
import Action
import RxSwift
import ByteViewCommon
import ByteViewNetwork

extension MeetTabListViewModel {

    func historyActionMaker() -> MeetTabLoadAction {
        return MeetTabLoadAction { [weak self] last -> Observable<([MeetTabCellViewModel], Bool)> in
            guard let self = self else { return .just(([], false)) }
            let tabViewModel = self.tabViewModel
            let historyId = last?.matchKey
            let maxNum = Self.loadHistoryCount
            let httpClient = self.httpClient
            return RxTransform.single {
                let request = GetTabHistoryListRequest(historyId: historyId, maxNum: maxNum, supportCal: true)
                httpClient.getResponse(request, completion: $0)
            }.asObservable().do(onNext: { response in
                tabViewModel.openGrootChannel(type: .vcTabListChannel, channelID: nil, downVersion: response.downVersion)
            }).flatMapLatest({ response -> Single<GetTabHistoryListResponse> in
                return Single<GetTabHistoryListResponse>.create { single -> Disposable in
                    var r = response
                    r.items = response.items.filter({ MeetTabListViewModel.compareVersion($0.showVersion, "5.21.0") <= 0 })
                    single(.success(r))
                    return Disposables.create()
                }
            }).flatMapLatest({ response -> Single<(GetTabHistoryListResponse, [ParticipantUserInfo])> in
                let ids = response.items
                    .filter { $0.meetingType == .call && ![.outsideEnterprisePhone, .insideEnterprisePhone].contains($0.phoneType) }
                    .map { (ParticipantId(id: $0.historyAbbrInfo.interacterUserID, type: $0.historyAbbrInfo.interacterUserType), $0.meetingID) }
                let larkIds = ids.filter { $0.0.type == .larkUser }
                let otherIds = ids.filter { $0.0.type != .larkUser }
                let s1: Single<[ParticipantUserInfo]> = httpClient.participantService.participantsByIdsUsingCache(larkIds.map { $0.0 }, meetingId: "")
                let s2: Single<[ParticipantUserInfo]> = Single.zip(otherIds.map {
                    httpClient.participantService.participantByIdUsingCache($0.0, meetingId: $0.1)
                }).map { res in res.compactMap { $0 } }
                return Single.zip(s1, s2).map { $0 + $1 }.map { (response, $0) }
            }).flatMapLatest({ (response, users) -> Observable<(GetTabHistoryListResponse, [ParticipantUserInfo])> in
                let o1: Observable<(GetTabHistoryListResponse, [ParticipantUserInfo])> = .just((response, users))
                let minutesIDs = response.items.filter { $0.contentLogos.contains(.larkMinutes) }.map { $0.meetingID }
                let recordIDs = response.items.filter { $0.contentLogos.contains(.record) && !$0.contentLogos.contains(.larkMinutes) }.map { $0.meetingID }

                let o2 = RxTransform.single { (completion: @escaping (Result<GetRecordInfoResponse, Error>) -> Void) in
                    let request = GetRecordInfoRequest(recordMeetingIDs: recordIDs, minutesMeetingIDs: minutesIDs)
                    httpClient.getResponse(request, completion: completion)
                }.asObservable().map { $0.recordInfo }.map { recordMap -> (GetTabHistoryListResponse, [ParticipantUserInfo]) in
                    var r = response
                    r.items = response.items.map {
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
            }).map { (response, users) -> ([MeetTabCellViewModel], Bool) in
                let array = self.historyToAll(response.items, users: users)
                return (array, response.hasMore)
            }
        }
    }

    var historyAllLoadAction: MeetTabLoadAction {
        return historyActionMaker()
    }

    func upcomingActionMaker() -> MeetTabLoadAction {
        return MeetTabLoadAction { [weak self] _ -> Observable<([MeetTabCellViewModel], Bool)> in
            guard let self = self else { return .just(([], false)) }
            let startTime = Int64(Date().timeIntervalSince1970.rounded() * 1000)
            let maxNum = Self.loadUpcomingCount
            let httpClient = self.httpClient
            return RxTransform.single(action: {
                let request = GetTabUpcomingInstancesRequest(startTime: startTime, number: maxNum + 1)
                httpClient.getResponse(request, completion: $0)
            }).asObservable().map { response -> ([MeetTabCellViewModel], Bool) in
                    let array: [MeetTabCellViewModel] = Array(self.upcomingToAll(response.instances).prefix(Int(MeetTabListViewModel.loadUpcomingCount)))
                    let hasMore: Bool = response.instances.count > maxNum
                    return (array, hasMore)
                }
        }
    }

    var upcomingAllLoadAction: MeetTabLoadAction {
        return upcomingActionMaker()
    }

    var preloadAction: MeetTabLoadAction {
        return MeetTabLoadAction { _ -> Observable<([MeetTabCellViewModel], Bool)> in
            return .just(([], false))
        }
    }

    var loadMoreHistoryAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            MeetTabTracks.trackMeetTabOperation(.clickListLoadFailed)
            self?.historyDataSource.loadMore()
            return .empty()
        })
    }

    var scheduleMeetingAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            MeetTabTracks.trackMeetTabOperation(.clickSchedule)
            if let host = self?.hostViewController {
                self?.router?.gotoCreateCalendarEvent(title: nil,
                                                     startDate: Date(),
                                                     endDate: nil,
                                                     isAllDay: false,
                                                     timeZone: TimeZone.current,
                                                     from: host)
            }
            return .empty()
        })
    }

    var webinarScheduleMeetingAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            MeetTabTracks.trackMeetTabOperation(.clickWebinarSchedule)
            if let host = self?.hostViewController {
                self?.router?.gotoCreateWebinarCalendarEvent(title: nil,
                                                  startDate: Date(),
                                                  endDate: nil,
                                                  isAllDay: false,
                                                  timeZone: TimeZone.current,
                                                  from: host)
            }
            return .empty()
        })
    }

    var gotoCalendarAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            MeetTabTracks.trackMeetTabOperation(.clickUpcomingMore)
            if let host = self?.hostViewController {
                self?.router?.gotoCalendarTab(from: host)
            }
            return .empty()
        })
    }

    // header
    func getNewMeetingAction(from: UIViewController) -> CocoaAction {
        return CocoaAction(workFactory: { [weak self, weak from] _ in
            guard let self = self, let from = from else { return .empty() }
            MeetTabTracks.trackMeetTabOperation(.clickNewMeeting)
            self.router?.startNewMeeting(from: from)
            return .empty()
        })
    }

    func getJoinMeetingAction(from: UIViewController) -> CocoaAction {
        return CocoaAction(workFactory: { [weak self, weak from] _ in
            guard let self = self, let from = from else { return .empty() }
            MeetTabTracks.trackMeetTabOperation(.clickJoinMeeting)
            self.router?.joinMeetingByNumber(from: from)
            return .empty()
        })
    }

    func getLocalShareAction(from: UIViewController) -> CocoaAction {
        return CocoaAction(workFactory: { [weak self, weak from] _ in
            guard let self = self, let from = from else { return .empty() }
            MeetTabTracks.trackMeetTabOperation(.clickShareScreen)
            self.router?.startShareContent(from: from)
            return .empty()
        })
    }
}
